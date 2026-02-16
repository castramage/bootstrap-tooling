locals {
  project_files = fileset("${path.module}/projects", "*.yaml")

  github_projects = {
    for f in local.project_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/projects/${f}"))
  }
}

module "github_bootstrap" {
  source   = "./modules/github_bootstrap"
  for_each = local.github_projects

  repositories           = each.value.repositories
  repo_collaborators     = try(each.value.repo_collaborators, {})
  teams                  = try(each.value.teams, {})
  manage_team_membership = try(each.value.manage_team_membership, true)
  team_members           = try(each.value.team_members, {})
  team_repo_permissions  = try(each.value.team_repo_permissions, {})
}

output "repo_urls_by_project" {
  value = {
    for project, m in module.github_bootstrap :
    project => m.repo_urls
  }
}

output "team_ids_by_project" {
  value = {
    for project, m in module.github_bootstrap :
    project => m.team_ids
  }
}

# Existing org team that must be admin on everything
data "github_team" "red" {
  slug = "red"
}

# Flatten all repos created by all projects into a single map
locals {
  all_repo_names = toset(flatten([
    for _, cfg in local.github_projects : keys(cfg.repositories)
  ]))
}

# Grant team "red" admin on all repos
resource "github_team_repository" "red_admin_all" {
  for_each = local.all_repo_names

  team_id    = data.github_team.red.id
  repository = each.key
  permission = "admin"

  # Make sure repos exist before attaching permissions
  depends_on = [module.github_bootstrap]
}

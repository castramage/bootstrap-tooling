locals {
  repos = {
    for name, cfg in var.repositories :
    name => merge({
      description            = ""
      visibility             = "private"
      has_issues             = true
      has_projects           = false
      has_wiki               = false
      allow_merge_commit     = true
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      auto_init              = true
      topics                 = []
      archived               = false
    }, cfg)
  }

  collaborators_flat = merge([
    for repo_name, users in var.repo_collaborators : {
      for username, perm in users :
      "${repo_name}:${username}" => {
        repo       = repo_name
        username   = username
        permission = perm
      }
    }
  ]...)

  team_members_flat = merge([
    for team_name, users in var.team_members : {
      for username, role in users :
      "${team_name}:${username}" => {
        team     = team_name
        username = username
        role     = role
      }
    }
  ]...)

  team_repo_flat = merge([
    for repo_name, teams in var.team_repo_permissions : {
      for team_name, perm in teams :
      "${repo_name}:${team_name}" => {
        repo       = repo_name
        team       = team_name
        permission = perm
      }
    }
  ]...)
}

# -----------------------
# Repositories
# -----------------------
resource "github_repository" "repo" {
  for_each = local.repos

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki

  allow_merge_commit     = each.value.allow_merge_commit
  allow_squash_merge     = each.value.allow_squash_merge
  allow_rebase_merge     = each.value.allow_rebase_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge

  auto_init          = each.value.auto_init
  gitignore_template = try(each.value.gitignore_template, null)
  license_template   = try(each.value.license_template, null)
  topics             = each.value.topics

  archived = each.value.archived

  lifecycle {
    precondition {
      condition     = contains(local.allowed_visibility, each.value.visibility)
      error_message = "Invalid visibility for repo '${each.key}'. Allowed: private|public|internal."
    }
  }
}

# -----------------------
# Teams (safe nesting: root + child)
# -----------------------
resource "github_team" "team_root" {
  for_each = {
    for k, v in var.teams : k => v
    if try(v.parent_team, null) == null
  }

  name        = each.key
  description = try(each.value.description, "")
  privacy     = try(each.value.privacy, "closed")

  lifecycle {
    precondition {
      condition     = contains(local.allowed_team_privacy, try(each.value.privacy, "closed"))
      error_message = "Invalid team privacy for '${each.key}'. Allowed: closed|secret."
    }
  }
}

resource "github_team" "team_child" {
  for_each = {
    for k, v in var.teams : k => v
    if try(v.parent_team, null) != null
  }

  name        = each.key
  description = try(each.value.description, "")
  privacy     = try(each.value.privacy, "closed")

  parent_team_id = github_team.team_root[each.value.parent_team].id

  lifecycle {
    precondition {
      condition     = contains(local.allowed_team_privacy, try(each.value.privacy, "closed"))
      error_message = "Invalid team privacy for '${each.key}'. Allowed: closed|secret."
    }
    precondition {
      condition     = contains(keys(github_team.team_root), each.value.parent_team)
      error_message = "Team '${each.key}' parent_team '${each.value.parent_team}' must refer to a root team (team without parent_team)."
    }
  }
}

locals {
  team_id_by_name = merge(
    { for k, t in github_team.team_root  : k => t.id },
    { for k, t in github_team.team_child : k => t.id }
  )
}

# -----------------------
# Team membership (optional)
# -----------------------
resource "github_team_membership" "member" {
  for_each = var.manage_team_membership ? local.team_members_flat : {}

  team_id  = local.team_id_by_name[each.value.team]
  username = each.value.username
  role     = each.value.role

  lifecycle {
    precondition {
      condition     = contains(local.allowed_team_member_role, each.value.role)
      error_message = "Invalid team member role for '${each.value.team}:${each.value.username}'. Allowed: member|maintainer."
    }
  }

  depends_on = [github_team.team_root, github_team.team_child]
}

# -----------------------
# Team -> repo permissions
# -----------------------
resource "github_team_repository" "team_access" {
  for_each = local.team_repo_flat

  team_id    = local.team_id_by_name[each.value.team]
  repository = github_repository.repo[each.value.repo].name
  permission = each.value.permission

  lifecycle {
    precondition {
      condition     = contains(local.allowed_repo_perm, each.value.permission)
      error_message = "Invalid permission for team '${each.value.team}' on repo '${each.value.repo}'. Allowed: pull|triage|push|maintain|admin."
    }
  }

  depends_on = [github_team.team_root, github_team.team_child]
}

# -----------------------
# Direct collaborators (optional exceptions)
# -----------------------
resource "github_repository_collaborator" "collab" {
  for_each = local.collaborators_flat

  repository = github_repository.repo[each.value.repo].name
  username   = each.value.username
  permission = each.value.permission

  lifecycle {
    precondition {
      condition     = contains(local.allowed_repo_perm, each.value.permission)
      error_message = "Invalid collaborator permission for '${each.value.repo}:${each.value.username}'. Allowed: pull|triage|push|maintain|admin."
    }
  }
}

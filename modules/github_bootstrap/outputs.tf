output "repo_urls" {
  description = "Map of repo name -> HTML URL."
  value = {
    for name, r in github_repository.repo :
    name => r.html_url
  }
}

output "team_ids" {
  description = "Map of team name -> team id (root and child teams)."
  value       = local.team_id_by_name
}

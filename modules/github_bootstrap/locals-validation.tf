locals {
  allowed_repo_perm        = toset(["pull", "triage", "push", "maintain", "admin"])
  allowed_team_privacy     = toset(["closed", "secret"])
  allowed_team_member_role = toset(["member", "maintainer"])
  allowed_visibility       = toset(["private", "public", "internal"])
}

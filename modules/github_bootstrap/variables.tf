variable "repositories" {
  description = "Repositories to create/manage."
  type = map(object({
    description             = optional(string, "")
    visibility              = optional(string, "private") # private | public | internal
    has_issues              = optional(bool, true)
    has_projects            = optional(bool, false)
    has_wiki                = optional(bool, false)
    allow_merge_commit      = optional(bool, true)
    allow_squash_merge      = optional(bool, true)
    allow_rebase_merge      = optional(bool, false)
    delete_branch_on_merge  = optional(bool, true)

    auto_init               = optional(bool, true)
    gitignore_template      = optional(string) # e.g. "Terraform", "Go", "Python"
    license_template        = optional(string) # e.g. "mit", "apache-2.0"
    topics                  = optional(list(string), [])
    archived                = optional(bool, false)
  }))
  default = {}
}

variable "repo_collaborators" {
  description = "Map of repo_name -> map(username -> permission). permission: pull|triage|push|maintain|admin"
  type        = map(map(string))
  default     = {}
}

variable "teams" {
  description = "Teams to create in the org. privacy: closed|secret. parent_team: optional team name in this same map."
  type = map(object({
    description = optional(string, "")
    privacy     = optional(string, "closed") # closed | secret
    parent_team = optional(string)           # parent team key from this map (optional)
  }))
  default = {}
}

variable "manage_team_membership" {
  description = "If false, Terraform will NOT manage team membership (useful with SCIM / Entra ID sync)."
  type        = bool
  default     = true
}

variable "team_members" {
  description = "Map of team_name -> map(username -> role). role: member|maintainer"
  type        = map(map(string))
  default     = {}
}

variable "team_repo_permissions" {
  description = "Map of repo_name -> map(team_name -> permission). permission: pull|triage|push|maintain|admin"
  type        = map(map(string))
  default     = {}
}

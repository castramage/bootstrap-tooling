variable "github_owner" {
  type = string
}

variable "github_app_id" {
  type = number
}

variable "github_app_installation_id" {
  type = number
}

variable "github_app_pem_file_path" {
  type      = string
  sensitive = true
}

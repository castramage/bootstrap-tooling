# GitHub Bootstrap (Option A - projects folder)

## How it works
- Put one YAML file per project in `projects/`
- Terraform auto-discovers all `*.yaml` files and applies the bootstrap module for each project.

## Run
1. Put your GitHub App PEM next to this root folder (or change `github_app_pem_file_path` in `terraform.tfvars`).
2. Edit `terraform.tfvars` with your org/app ids.
3. Run:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Add a new project
Create `projects/projectC.yaml` (same schema as projectA/projectB). That's it.

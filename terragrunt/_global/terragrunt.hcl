# Root terragrunt settings - common locals and provider generation
# Adjust `remote_state` bucket values in env-level configs or via env variables.

locals {
  project = "devsecops7"
  common_tags = {
    Project = local.project
    Owner   = "devsecops"
  }
}

generate "provider" {
  path      = "terragrunt_generated_provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}

# Example of including this file from child terragrunt.hcl with find_in_parent_folders()

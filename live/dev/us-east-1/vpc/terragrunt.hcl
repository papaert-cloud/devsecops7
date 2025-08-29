# Child terragrunt.hcl for a VPC module (live tree).
# This file inherits root settings via include() and points terraform to a module.

include {
  path = find_in_parent_folders()  # inherit remote_state, locals
}

locals {
  account = "dev"
  aws_region = "us-east-1"
}

terraform {
  # Use a local modules directory; in production prefer module registry or git ref
  source = "../../../modules/vpc"  # relative path to modules for local dev
  # Example for remote module:
  # source = "git::ssh://git@github.com/yourorg/infra-modules.git//vpc?ref=main"
}

inputs = {
  # Inputs passed into the Terraform module
  name       = "vpc-${local.account}-${local.aws_region}"
  cidr_block = "10.10.0.0/16"
  region     = local.aws_region
  tags = {
    Owner       = "papaert-cloud"
    Environment = local.account
    Project     = "terragrunt-bootstrap"
  }
}
# Root terragrunt.hcl providing shared settings and remote state config.
# Children will `include` this file with find_in_parent_folders()

locals {
  # Default region; children can override via inputs or their own locals
  default_region = "us-east-1"
  # prefix for S3 bucket used for remote state (bootstrap creates bucket with this prefix + region + account)
  state_bucket_prefix = "papaert-cloud-terragrunt" # <- change via bootstrap CLI arg, NOT a secret
  dynamodb_table_name = "terragrunt-locks"         # single table for locking
  # path structure for state keys: <account>/<region>/<module>/terraform.tfstate
  state_key_format = "%s/%s/%s/terraform.tfstate"  # account, region, path_relative_to_include()
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.state_bucket_prefix}-${local.default_region}"               # created by bootstrap
    key            = format(local.state_key_format, get_env("TF_VAR_account","unknown"), local.default_region, path_relative_to_include())
    region         = local.default_region
    encrypt        = true
    dynamodb_table = local.dynamodb_table_name
    # optional: kms_key_id = "alias/terragrunt-remote-state"  # use KMS if you want customer-managed keys
  }
}

# recommended terraform version pinning
terraform {
  extra_arguments "required_version" {
    commands = get_terraform_commands_that_need_vars()
    arguments = [
      "-var=terraform_version=1.7.0" # example -- keep in sync with GH workflow
    ]
  }
}
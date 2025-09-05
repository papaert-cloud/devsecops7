# Terragrunt config for dev/us-east-1/stackset_root
# Wires to the Terraform root in infra/stackset_root and inherits globals from terragrunt/_global

terraform {
  # relative path from this file to the terraform root (repo layout has a top-level `infra/`)
  source = "../../../../infra/stackset_root"
}

include {
  path = find_in_parent_folders()
}

# Inputs specific to this stackset instance in the dev environment.
# Update values (ou_ids, account_ids, stack_set_name, etc.) before apply.
inputs = {
  # region is provided by the global include (local.aws_region) but set here explicitly if you prefer
  region = "us-east-1"

  # StackSet configuration
  stack_set_name   = "dev-stackset"
  permission_model = "SERVICE_MANAGED"
  call_as          = "SELF"
  capabilities     = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  # targeting
  stack_set_instance_region = "us-east-1"
  ou_ids                    = []    # e.g. ["ou-abcde-12345"]
  account_ids               = []    # e.g. ["111122223333"]

  # auto-deployment and retention
  auto_deployment_enabled          = false
  retain_stacks_on_account_removal = false

  # rollout controls
  failure_tolerance_percentage = 0
  max_concurrent_percentage    = 100
  region_concurrency_type      = "PARALLEL"

  # timeouts (module-level)
  timeout_create = "30m"
  timeout_update = "30m"
  timeout_delete = "30m"

  # tags (merged with global default_tags)
  tags = {
    Project = "devsecops7"
    Env     = "dev"
    Owner   = "your-team"
  }
}

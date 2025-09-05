# Terragrunt config for dev/us-east-1/stackset_root
# Wires to the Terraform root in infra/stackset_root and inherits globals from terragrunt/_global

terraform {
  # relative path from this file to the terraform root (repo layout has a top-level `infra/`)
  source = "../../../../infra/stackset_root"
}

include {
  path = "../../../_global/terragrunt.hcl"
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

  # Path to the CFN template (resolve relative to the repo via terragrunt dir)
  template_path = "${get_terragrunt_dir()}/../../../../infra/stackset_root/iam_user_group.yml"

  # CFN template parameters required by iam_user_group.yml
  parameters = {
    GroupName = "dev-group"
    UserName  = "dev-user"
  }

  # targeting
  stack_set_instance_region = "us-east-1"
  # Target OU(s) for SERVICE_MANAGED deployments. Replace with your OU IDs.
  # Note: SERVICE_MANAGED + auto_deployment will auto-deploy to new accounts joining the OU.
  # To ensure existing accounts are covered, the module creates a StackSet instance targeting these OUs.
  ou_ids                    = ["ou-im88-1fmr1yt9"]    # e.g. ["ou-abcde-12345"]
  # account_ids               = []    # e.g. ["111122223333"]

  # auto-deployment and retention
  # Enable automatic deployment to accounts in the OU (new accounts will be auto-deployed).
  auto_deployment_enabled          = true
  retain_stacks_on_account_removal = false

  # rollout controls
  failure_tolerance_percentage = 100
  max_concurrent_percentage    = 75
  region_concurrency_type      = "PARALLEL"

  # timeouts (module-level)
  timeout_create = "45m"
  timeout_update = "45m"
  timeout_delete = "45m"

  # tags (merged with global default_tags)
  tags = {
    Project = "devsecops7"
    Env     = "dev"
  Owner   = "Alpha_Team_Hoorah"
  }
}

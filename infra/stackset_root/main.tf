# main.tf (module wiring only)

locals {
  tpl_path = abspath("${path.module}/iam_user_group.yml") # you confirmed this exists
}

module "stackset" {
  source = "../modules/stackset_cfn"

  # identity / where
  # provider credentials/region are configured in the root provider (see provider.tf)

  # StackSet core
  stack_set_name   = var.stack_set_name
  permission_model = var.permission_model # "SERVICE_MANAGED"
  call_as          = var.call_as          # "SELF"
  capabilities     = var.capabilities     # ["CAPABILITY_IAM","CAPABILITY_NAMED_IAM"]

  # CFN template & parameters
  template_path = local.tpl_path
  parameters    = var.parameters
  tags          = var.tags

  # Auto-deployment for new accounts joining the OU
  auto_deployment_enabled          = var.auto_deployment_enabled
  retain_stacks_on_account_removal = var.retain_stacks_on_account_removal

  # Targeting (SERVICE_MANAGED via OUs)
  ou_ids                    = var.ou_ids # ["ou-im88-1fmr1yt9"]
  stack_set_instance_region = var.stack_set_instance_region

  # Rollout controls
  failure_tolerance_percentage = var.failure_tolerance_percentage
  max_concurrent_percentage    = var.max_concurrent_percentage
  region_concurrency_type      = var.region_concurrency_type

  # Timeouts (applied on instance resource inside module)
  timeout_create = var.timeout_create
  timeout_update = var.timeout_update
  timeout_delete = var.timeout_delete

  # For SERVICE_MANAGED keep empty, but variable may exist
  account_ids = try(var.account_ids, [])
}

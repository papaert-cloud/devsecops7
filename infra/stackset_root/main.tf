// main.tf (module wiring only) - restored from terragrunt cache

locals {
  tpl_path = abspath("${path.module}/iam_user_group.yml")
}

module "stackset" {
  source = "./modules/stackset_cfn"

  # StackSet core
  stack_set_name   = var.stack_set_name
  permission_model = var.permission_model
  call_as          = var.call_as
  capabilities     = var.capabilities

  # CFN template & parameters
  template_path = local.tpl_path
  parameters    = var.parameters
  tags          = var.tags

  # Auto-deployment for new accounts joining the OU
  auto_deployment_enabled          = var.auto_deployment_enabled
  retain_stacks_on_account_removal = var.retain_stacks_on_account_removal

  # Targeting (SERVICE_MANAGED via OUs)
  ou_ids                    = var.ou_ids
  stack_set_instance_region = var.stack_set_instance_region

  # Rollout controls
  failure_tolerance_percentage = var.failure_tolerance_percentage
  max_concurrent_percentage    = var.max_concurrent_percentage
  region_concurrency_type      = var.region_concurrency_type

  # Timeouts
  timeout_create = var.timeout_create
  timeout_update = var.timeout_update
  timeout_delete = var.timeout_delete

  account_ids = try(var.account_ids, [])
}

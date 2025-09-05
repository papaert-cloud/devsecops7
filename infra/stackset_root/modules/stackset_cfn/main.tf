resource "aws_cloudformation_stack_set" "this" {
  name             = var.stack_set_name
  description      = "Reusable StackSet"
  permission_model = var.permission_model
  call_as          = var.call_as
  capabilities     = var.capabilities

  template_body = file(var.template_path)

  parameters = var.parameters
  tags       = var.tags

  dynamic "auto_deployment" {
    for_each = var.permission_model == "SERVICE_MANAGED" ? [1] : []
    content {
      enabled                          = var.auto_deployment_enabled
      retain_stacks_on_account_removal = var.retain_stacks_on_account_removal
    }
  }
}

resource "aws_cloudformation_stack_set_instance" "service_managed" {
  count                     = length(var.ou_ids) > 0 ? 1 : 0
  stack_set_name            = aws_cloudformation_stack_set.this.name
  stack_set_instance_region = var.stack_set_instance_region
  call_as                   = var.call_as

  deployment_targets {
    organizational_unit_ids = var.ou_ids
  }

  operation_preferences {
    failure_tolerance_percentage = var.failure_tolerance_percentage
    max_concurrent_percentage    = var.max_concurrent_percentage
    region_concurrency_type      = var.region_concurrency_type
  }

  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }
}

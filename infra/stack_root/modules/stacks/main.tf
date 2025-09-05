// ...copied from infra/modules/stacks/main.tf
resource "aws_cloudformation_stack" "this" {
  name          = var.stack_name
  region        = var.region
  capabilities  = var.capabilities
  template_body = file(var.template_path)
  parameters    = var.parameters
  tags          = var.tags

  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }
}

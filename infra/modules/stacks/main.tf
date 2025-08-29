# Reusable CFN stack
resource "aws_cloudformation_stack" "this" {
  name          = var.stack_name
  region        = var.region
  capabilities  = var.capabilities
  template_body = file(var.template_path)     # # Load the YAML from disk
  parameters    = var.parameters              # # Pass the parameter map through to CFN
  tags          = var.tags

  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }
}

# Inputs to wire to the module
variable "stack_name" { type = string }
variable "template_path" { type = string }
variable "capabilities" { type = list(string) }
variable "parameters" { type = map(string) }
variable "tags" { type = map(string) }
variable "timeout_create" { type = string }
variable "timeout_update" { type = string }
variable "timeout_delete" { type = string }

module "stack" {
  source = "./modules/stacks"

  stack_name    = var.stack_name
  region        = var.region
  template_path = var.template_path
  capabilities  = var.capabilities
  parameters    = var.parameters
  tags          = var.tags

  timeout_create = var.timeout_create
  timeout_update = var.timeout_update
  timeout_delete = var.timeout_delete
}

output "stack_name" { value = module.stack.stack_name }
output "stack_id" { value = module.stack.stack_id }

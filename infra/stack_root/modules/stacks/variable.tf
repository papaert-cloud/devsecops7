// ...copied from infra/modules/stacks/variable.tf
variable "stack_name"      { type = string }
variable "region"          { type = string }
variable "template_path"   { type = string }
variable "capabilities"    { type = list(string) }
variable "parameters"      { type = map(string) }
variable "tags"            { type = map(string) }
variable "timeout_create"  { type = string }
variable "timeout_update"  { type = string }
variable "timeout_delete"  { type = string }

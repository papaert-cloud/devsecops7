# All inputs are provided by tfvars (no hardcoding)

variable "stack_name"      { type = string }
variable "region"          { type = string }
variable "template_path"   { type = string }           # absolute or root-relative
variable "capabilities"    { type = list(string) }     # e.g. ["CAPABILITY_IAM","CAPABILITY_NAMED_IAM"]
variable "parameters"      { type = map(string) }      # must match YAML Parameters keys
variable "tags"            { type = map(string) }      # arbitrary tags

# Timeouts (strings like "45m")
variable "timeout_create"  { type = string }
variable "timeout_update"  { type = string }
variable "timeout_delete"  { type = string }

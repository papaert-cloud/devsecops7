variable "region"  { type = string }
variable "profile" { type = string,   default = null }

variable "stack_set_name"   { type = string }
variable "permission_model" { type = string, default = "SERVICE_MANAGED" }
variable "call_as"          { type = string, default = "SELF" }
variable "capabilities"     { type = list(string), default = ["CAPABILITY_IAM","CAPABILITY_NAMED_IAM"] }

variable "template_path" { type = string }                  # absolute or relative path to YAML
variable "parameters"    { type = map(string) }
variable "tags"          { type = map(string), default = {} }

variable "auto_deployment_enabled"          { type = bool,   default = true }
variable "retain_stacks_on_account_removal" { type = bool,   default = false }

# SERVICE_MANAGED: use OU IDs
variable "ou_ids"                    { type = list(string), default = [] }
variable "stack_set_instance_region" { type = string }

# (optionally used for SELF_MANAGED)
variable "account_ids" { type = list(string), default = [] }

# Operation preferences
variable "failure_tolerance_percentage" { type = number, default = 100 }
variable "max_concurrent_percentage"    { type = number, default = 100 }
variable "region_concurrency_type"      { type = string, default = "SEQUENTIAL" }

# Timeouts
variable "timeout_create" { type = string, default = "45m" }
variable "timeout_update" { type = string, default = "45m" }
variable "timeout_delete" { type = string, default = "45m" }
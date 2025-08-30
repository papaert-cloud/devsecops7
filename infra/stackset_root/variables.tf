variable "region" {
  type        = string
  description = "AWS region to operate in"
}

variable "profile" {
  type        = string
  description = "AWS CLI profile name (optional)"
  default     = ""
}

variable "stack_set_name" {
  type = string
}


variable "capabilities" {
  type    = list(string)
  default = []
}

variable "parameters" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "permission_model" {
  type = string
}

variable "call_as" {
  type    = string
  default = "SELF"
}

variable "stack_set_instance_region" {
  type    = string
  default = ""
}

variable "ou_ids" {
  type    = list(string)
  default = []
}

variable "account_ids" {
  type    = list(string)
  default = []
}

variable "auto_deployment_enabled" {
  type    = bool
  default = false
}

variable "retain_stacks_on_account_removal" {
  type    = bool
  default = false
}

variable "failure_tolerance_percentage" {
  type    = number
  default = 0
}

variable "max_concurrent_percentage" {
  type    = number
  default = 100
}

variable "region_concurrency_type" {
  type    = string
  default = "PARALLEL"
}

variable "timeout_create" {
  type    = string
  default = "30m"
}

variable "timeout_update" {
  type    = string
  default = "30m"
}

variable "timeout_delete" {
  type    = string
  default = "30m"
}

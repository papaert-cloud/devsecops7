variable "template_path" {
  type        = string
  description = "Absolute path to the CFN template file"
  validation {
    condition     = fileexists(var.template_path)
    error_message = "template_path does not point to a readable file."
  }
}

variable "stack_set_name" {
  type        = string
  description = "Name of the CloudFormation StackSet"
}

variable "permission_model" {
  type        = string
  description = "Permission model for the StackSet (e.g. SERVICE_MANAGED or SELF_MANAGED)"
}

variable "call_as" {
  type        = string
  description = "Who is calling the StackSet API (SELF or DELEGATED_ADMIN)"
  default     = "SELF"
}

variable "capabilities" {
  type        = list(string)
  description = "Capabilities for the CloudFormation template"
  default     = []
}

variable "parameters" {
  type        = map(string)
  description = "Parameters to pass to the CloudFormation template"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the StackSet"
  default     = {}
}

variable "auto_deployment_enabled" {
  type        = bool
  description = "Enable automatic deployment to accounts in OUs when SERVICE_MANAGED"
  default     = false
}

variable "retain_stacks_on_account_removal" {
  type        = bool
  description = "Whether to retain stacks when an account is removed from an OU"
  default     = false
}

variable "ou_ids" {
  type        = list(string)
  description = "List of OU ids for SERVICE_MANAGED deployment targets"
  default     = []
}

variable "stack_set_instance_region" {
  type        = string
  description = "Region for stack set instances"
  default     = ""
}

variable "failure_tolerance_percentage" {
  type        = number
  description = "Failure tolerance percentage for operation preferences"
  default     = 0
}

variable "max_concurrent_percentage" {
  type        = number
  description = "Max concurrent percentage for operation preferences"
  default     = 100
}

variable "region_concurrency_type" {
  type        = string
  description = "Region concurrency type (PARALLEL or SEQUENTIAL)"
  default     = "PARALLEL"
}

variable "timeout_create" {
  type        = string
  description = "Create timeout for stack set instance"
  default     = "30m"
}

variable "timeout_update" {
  type        = string
  description = "Update timeout for stack set instance"
  default     = "30m"
}

variable "timeout_delete" {
  type        = string
  description = "Delete timeout for stack set instance"
  default     = "30m"
}

variable "account_ids" {
  type        = list(string)
  description = "Account ids for SELF_MANAGED targets (not used for SERVICE_MANAGED)"
  default     = []
}

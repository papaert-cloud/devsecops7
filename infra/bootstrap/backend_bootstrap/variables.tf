variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  type        = string
}

variable "region" {
  description = "AWS region to create the lock table in"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

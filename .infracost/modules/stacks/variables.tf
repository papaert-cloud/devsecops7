variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
  default     = "infracost-test-bucket"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}

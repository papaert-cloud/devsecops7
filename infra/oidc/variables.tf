variable "role_name" {
  description = "IAM role name to create for GitHub Actions"
  type        = string
  default     = "github-actions-oidc-role"
}

variable "allowed_subjects" {
  description = "List of token.subject patterns allowed (StringLike). Example: \"repo:papaert-cloud/devsecops7:ref:refs/heads/main\""
  type        = list(string)
  # Tighten default to main branch only for safer defaults in this repo.
  default     = ["repo:papaert-cloud/devsecops7:ref:refs/heads/main"]
}

variable "thumbprint" {
  description = "OIDC provider CA thumbprint. GitHub's CA thumbprint historically: 6938fd4d98bab03faadb97b34396831e3780aea1"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "attach_example_policy" {
  description = "When true attach a small example policy (S3 read-only) to the role. You should replace with least-privilege policies."
  type    = bool
  default = true
}

variable "example_bucket_arn" {
  description = "Bucket ARN used by the example policy (replace before prod)."
  type        = string
  default     = "arn:aws:s3:::my-bucket"
}

# Optional: one-time module to create the S3 bucket + DynamoDB table used for remote state locking.
# This file intentionally left as a placeholder — implement via module or manual steps to bootstrap remote state.

# Example usage: run Terragrunt in this folder once with proper AWS credentials to create the backend resources.

# terraform {
#   source = "git::ssh://git@github.com/your-org/terraform-modules.git//s3-backend?ref=main"
# }

# inputs = {
#   bucket_name = "my-tfstate-bucket"
# }

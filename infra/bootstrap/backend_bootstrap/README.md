Bootstrap module to create a DynamoDB table for Terraform state locking used with an existing S3 backend.

Usage (run this separately before initializing your main Terraform that uses the S3 backend):

1. cd infra/bootstrap/backend_bootstrap
2. create a small `terraform.tfvars` or pass variables on the CLI:
   - `dynamodb_table_name = "cs-dev-tfstate-lock"`
   - `region = "us-east-1"` (default)
3. terraform init && terraform apply

The module creates an on-demand DynamoDB table with primary key `LockID` and server-side encryption enabled.

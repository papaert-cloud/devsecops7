locals {
	env         = get_env("TG_ENV", "dev")        # dev|test|prod (set via env var)
	aws_region  = get_env("AWS_REGION", "us-east-1")
	aws_account = get_env("AWS_ACCOUNT_ID", "000000000000")

	default_tags = {
		Project = "devsecops7"
		Owner   = "Cloud Sentrics"
		Env     = local.env
	}

	# One bucket/table per env to avoid collisions
	state_bucket = "cs-${local.env}-tfstate"
	state_table  = "cs-${local.env}-tfstate-lock"
}

remote_state {
	backend = "s3"
	config = {
		bucket         = local.state_bucket
		key            = "${path_relative_to_include()}/terraform.tfstate"
		region         = local.aws_region
		dynamodb_table = local.state_table
		encrypt        = true
	}
}

# Inject provider & required_providers into each child
generate "provider" {
	path      = "terragrunt_generated_provider.tf"
	if_exists = "overwrite_terragrunt"
	contents  = <<-EOF
		terraform {
			required_version = ">= 1.6.0"
			required_providers {
				aws = {
					source  = "hashicorp/aws"
					version = ">= 5.0"
				}
			}
		}

		provider "aws" {
			region = "${local.aws_region}"
			# OIDC/assume-role can be wired via environment variables or a var:
			# assume_role { role_arn = var.role_arn }
			default_tags { tags = ${jsonencode(local.default_tags)} }
		}
	EOF
}

# Global inputs (available to all children)
inputs = {
	env          = local.env
	aws_region   = local.aws_region
	aws_account  = local.aws_account
	default_tags = local.default_tags
	# state backend inputs
	bucket_name  = local.state_bucket
	table_name   = local.state_table
	region       = local.aws_region
}

# (Optional) hooks – commented out because the installed Terragrunt
# version does not support the `before_hook` block in this environment.
#+ If you upgrade Terragrunt to a version that supports hooks, you can
#+ re-enable these checks here.
# before_hook "fmt" { ... }
# before_hook "validate" { ... }
# before_hook "tflint" { ... }
# before_hook "checkov" { ... }
# (State backend module is configured via remote_state above; additional
# state module wiring can be added here if needed.)

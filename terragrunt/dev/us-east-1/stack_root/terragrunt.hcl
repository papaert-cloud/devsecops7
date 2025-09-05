terraform {
  source = "../../../../infra/stack_root"
}

include {
  path = "../../../_global/terragrunt.hcl"
}

inputs = {
  region = "us-east-1"

  # stack module inputs
  stack_name    = "dev-simple-stack"
  template_path = "${get_terragrunt_dir()}/../../../../infra/stackset_root/iam_user_group.yml"
  # CloudFormation capability(s) required for IAM resources
  capabilities  = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  parameters    = { GroupName = "dev-group", UserName = "dev-user" }
  tags          = { Project = "devsecops7", Env = "dev" }

  # optional AWS CLI profile (kept empty to use environment AWS_PROFILE if set)
  profile = ""

  timeout_create = "15m"
  timeout_update = "15m"
  timeout_delete = "15m"
}

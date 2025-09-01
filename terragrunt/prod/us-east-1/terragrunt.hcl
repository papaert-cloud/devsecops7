terraform {
  source = "${get_repo_root()}/modules/stacks"
}

inputs = {
  env        = "prod"
  aws_region = "us-east-1"
}

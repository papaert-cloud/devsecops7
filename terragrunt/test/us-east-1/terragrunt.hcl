terraform {
  # Template: point to your stacks module or specific module
  source = "${get_repo_root()}/modules/stacks"
}

inputs = {
  env        = "test"
  aws_region = "us-east-1"
}

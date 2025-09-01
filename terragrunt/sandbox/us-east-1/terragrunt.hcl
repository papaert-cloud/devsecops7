terraform {
  source = "${get_repo_root()}/modules/stacks"
}

inputs = {
  env        = "sandbox"
  aws_region = "us-east-1"
}

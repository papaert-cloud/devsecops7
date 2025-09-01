plugin "aws" {
  enabled = true
  version = "0.35.0"
}
rule "aws_instance_invalid_type" { enabled = true }
rule "terraform_required_version" { enabled = true }

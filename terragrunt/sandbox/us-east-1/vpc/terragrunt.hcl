include {
  path = find_in_parent_folders()
}

locals {
  env = "sandbox"
  region = "us-east-1"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "REPLACE_ME_TFSTATE_BUCKET"
    key            = "${local.env}/${local.region}/vpc/terraform.tfstate"
    region         = local.region
    dynamodb_table = "REPLACE_ME_TFSTATE_LOCK_TABLE"
    encrypt        = true
  }
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  env  = local.env
  region = local.region
  tags = local.common_tags
}

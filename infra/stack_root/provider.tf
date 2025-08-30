variable "region" { type = string }  # # from tfvars
variable "profile" { type = string } # # from tfvars

provider "aws" {
  region  = var.region
  profile = var.profile
}

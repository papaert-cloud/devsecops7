provider "aws" {
  region  = var.region
  profile = try(var.profile, null)
}

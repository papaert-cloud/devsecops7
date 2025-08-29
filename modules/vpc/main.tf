# Minimal example Terraform module for VPC (AWS).
# NOTE: No provider block here — providers are configured by Terragrunt/parent.

variable "name"     { type = string }
variable "cidr_block" { type = string }
variable "region"   { type = string }
variable "tags"     { type = map(string) }

provider "aws" {
  # provider can be configured by Terragrunt via CLI or wrapper; module avoids hardcoding region
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags       = merge(var.tags, { Name = var.name })
  enable_dns_hostnames = true
  enable_dns_support   = true
}

output "vpc_id" {
  value = aws_vpc.this.id
}
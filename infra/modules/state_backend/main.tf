terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "bucket_name" { type = string }
variable "table_name"  { type = string }
variable "region"      { type = string }

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tf" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "v" {
  bucket = aws_s3_bucket.tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enc" {
  bucket = aws_s3_bucket.tf.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "lock" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

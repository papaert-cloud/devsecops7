resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  acl    = "private"

  tags = merge({
    Project = "devsecops7"
  }, var.tags)
}

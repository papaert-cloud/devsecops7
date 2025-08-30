locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = local.github_oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.thumbprint]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "example_s3_read" {
  count = var.attach_example_policy ? 1 : 0

  name        = "github-actions-example-s3-read"
  description = "Example: limited S3 read access used for demos — replace in production"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject","s3:ListBucket"],
        Resource = [var.example_bucket_arn, "${var.example_bucket_arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_example" {
  count      = var.attach_example_policy ? 1 : 0
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.example_s3_read[0].arn
}

output "role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the role to set as GitHub secret"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "ARN of the OIDC provider (one-time per account)"
}

Create an AWS OIDC provider and an IAM role for GitHub Actions OIDC federation.

Usage (from this folder):

1. Initialize and apply with your AWS credentials configured:

```bash
terraform init
terraform apply -auto-approve
```

2. After apply, copy the `role_arn` output and add it as a GitHub repository secret (e.g. `AWS_OIDC_ROLE_ARN`).

Example GitHub Actions snippet (OIDC):

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials from OIDC
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_OIDC_ROLE_ARN }}
          aws-region: us-east-1
```

Notes:
- The module creates an OIDC provider for `token.actions.githubusercontent.com` and an IAM role which allows `sts:AssumeRoleWithWebIdentity`.
- Tighten `allowed_subjects` to specific ref patterns for production (e.g. `repo:papaert-cloud/devsecops7:ref:refs/heads/main`).
- Replace the example policy with least-privilege policies for your workflows.

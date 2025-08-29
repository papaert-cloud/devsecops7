# Terragrunt bootstrap (WSL-ready)

Overview:
- Terragrunt wrapper around Terraform for DRY infra.
- Remote state: S3 + DynamoDB locking, encryption, versioning.
- Bootstrap creates S3 bucket + DynamoDB via CloudFormation.
- CI uses OIDC (recommended) or GitHub secrets for AWS creds.

Quickstart (WSL):
1) Configure AWS CLI (use profile or OIDC for CI):
   - Local dev: `aws configure --profile terragrunt-dev` (do not store long-lived creds in repo)
   - CI: use GitHub Actions OIDC (see .github/workflows/ci.yml)
2) Create remote-state resources (in bootstrap account):
   WSL:
   ./scripts/bootstrap-remote-state.sh \
     --bucket-prefix papaert-cloud-terragrunt \
     --region us-east-1 \
     --profile terragrunt-dev
3) Update `live/*/terragrunt.hcl` inputs with account/region and data from bootstrap output.
4) Validate & test:
   - terragrunt run-all validate
   - terragrunt run-all plan

Files added:
- terragrunt.hcl (root)
- live/dev/us-east-1/vpc/terragrunt.hcl (example)
- modules/vpc/main.tf (example module)
- scripts/bootstrap-remote-state.sh (CloudFormation bootstrap)
- cfn/remote-state.yml (CFN template)
- .github/workflows/ci.yml (CI + OIDC guidance)

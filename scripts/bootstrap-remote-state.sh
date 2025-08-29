#!/usr/bin/env bash
# WSL-ready bootstrap script to create S3 bucket + DynamoDB table (CloudFormation).
# Usage:
# ./scripts/bootstrap-remote-state.sh --bucket-prefix my-prefix --region us-east-1 --profile my-aws-profile
set -euo pipefail

# Defaults
REGION="us-east-1"
PROFILE=""
BUCKET_PREFIX=""
STACK_NAME="terragrunt-remote-state-stack"
CFN_TEMPLATE="cfn/remote-state.yml"

while [[ $# -gt 0 ]]; do
  case $1 in
    --bucket-prefix) BUCKET_PREFIX="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --profile) PROFILE="--profile $2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

if [[ -z "$BUCKET_PREFIX" ]]; then
  echo "Error: --bucket-prefix is required (e.g. papaert-cloud-terragrunt)"
  exit 1
fi

# Derived values
BUCKET_NAME="${BUCKET_PREFIX}-${REGION}"
echo "# Bootstrapping remote state: bucket=${BUCKET_NAME} region=${REGION}"

# Validate CFN template exists
if [[ ! -f "$CFN_TEMPLATE" ]]; then
  echo "CloudFormation template not found at ${CFN_TEMPLATE}"
  exit 1
fi

# Create or update stack (idempotent)
set +e
aws $PROFILE cloudformation describe-stacks --region "$REGION" --stack-name "$STACK_NAME" >/dev/null 2>&1
STACK_EXISTS=$?
set -e

if [[ $STACK_EXISTS -eq 0 ]]; then
  echo "# Updating CloudFormation stack ${STACK_NAME}"
  aws $PROFILE cloudformation deploy --region "$REGION" --stack-name "$STACK_NAME" --template-file "$CFN_TEMPLATE" --capabilities CAPABILITY_NAMED_IAM
else
  echo "# Creating CloudFormation stack ${STACK_NAME}"
  aws $PROFILE cloudformation deploy --region "$REGION" --stack-name "$STACK_NAME" --template-file "$CFN_TEMPLATE" --capabilities CAPABILITY_NAMED_IAM
fi

# Output useful variables (do not print secrets)
echo "# Bootstrap complete. Set TF_VAR_account for terragrunt or update terragrunt.hcl as needed."
echo "S3 bucket: ${BUCKET_NAME}"
echo "DynamoDB table: terragrunt-locks"
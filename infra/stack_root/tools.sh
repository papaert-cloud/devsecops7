#!/usr/bin/env bash
set -euo pipefail

# # Usage: ./tools.sh <stack-name> <region>
aws cloudformation describe-stacks \
  --stack-name "${1:?stack-name required}" \
  --region "${2:?region required}" \
  --output table

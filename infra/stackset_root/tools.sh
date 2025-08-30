#!/usr/bin/env bash
set -euo pipefail

cmd=${1:-}
varfile=${2:-../env/stackset.dev.tfvars}

# Ensure output is written next to this script regardless of the current working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTFILE="$SCRIPT_DIR/last_output.txt"

# Capture CloudTrail lookups into a single logfile, disable AWS_PAGER to avoid interactive pager
AWS_PAGER="" aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteStackSet \
  --max-results 50 > "$OUTFILE" 2>&1

AWS_PAGER="" aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteStack \
  --max-results 50 >> "$OUTFILE" 2>&1

echo "wrote $OUTFILE"


# # Parse simple key="value" from tfvars for status helpers
get_var () {
  awk -v k="$1" '
    $1 ~ "^"k"\\s*=\\s*" {
      sub(/^[^=]*=\s*/, "", $0);
      gsub(/^[ \t"]+|[ \t"]+$/, "", $0);
      gsub(/^"|"$/, "", $0);
      print $0; exit
    }' "$varfile"
}

stack_set_name=$(get_var stack_set_name)
region=$(get_var region)

case "$cmd" in
  status)
    echo "== StackSet: $stack_set_name  Region: $region =="
    aws cloudformation describe-stack-set \
      --stack-set-name "$stack_set_name" \
      --region "$region" --output table || true

    echo
    echo "== Recent operations =="
    aws cloudformation list-stack-set-operations \
      --stack-set-name "$stack_set_name" \
      --region "$region" --max-items 10 --output table || true

    echo
    echo "== Instances =="
    aws cloudformation list-stack-instances \
      --stack-set-name "$stack_set_name" \
      --region "$region" --output table || true
    ;;
  ops)
    op_id=$(aws cloudformation list-stack-set-operations \
      --stack-set-name "$stack_set_name" \
      --region "$region" \
      --query 'Summaries[0].OperationId' --output text 2>/dev/null || true)
    [[ -z "$op_id" || "$op_id" == "None" ]] && { echo "No recent operations."; exit 0; }
    aws cloudformation list-stack-set-operation-results \
      --stack-set-name "$stack_set_name" \
      --operation-id "$op_id" \
      --region "$region" --output table
    ;;
  *)
    echo "Usage: $0 {status|ops} [varfile]"
    exit 1 ;;
esac

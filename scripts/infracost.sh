#!/usr/bin/env bash
set -euo pipefail

# Run Infracost across Terraform & Terragrunt directories in the repo.
# Outputs per-project JSON reports under .infracost/

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT_DIR/.infracost"

usage(){
  cat <<EOF
Usage: $(basename "$0") [--ci]

Options:
  --ci    Run in CI mode (fail on missing INFRACOST_API_KEY)
  -h      Show this help
EOF
}

CI_MODE=0
for arg in "$@"; do
  case "$arg" in
    --ci) CI_MODE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) ;;
  esac
done

if ! command -v infracost >/dev/null 2>&1; then
  echo "infracost CLI not found in PATH. Install it first: https://www.infracost.io/docs/installation/"
  exit 2
fi

if [ "$CI_MODE" -eq 1 ] && [ -z "${INFRACOST_API_KEY:-}" ]; then
  echo "CI mode requires INFRACOST_API_KEY to be set (secret)."
  exit 3
fi

if [ "$CI_MODE" -eq 0 ] && [ -z "${INFRACOST_API_KEY:-}" ]; then
  cat <<EOF
Warning: INFRACOST_API_KEY is not set. The Infracost CLI requires an API key to fetch pricing.
You can set it via environment variable:

  export INFRACOST_API_KEY=your_api_key_here

Or create a credentials file at ~/.config/infracost/credentials.yml
See https://www.infracost.io/docs/ for details.

Skipping run. Re-run the script after setting the API key.
EOF
  exit 0
fi

echo "Scanning repository for Terraform & Terragrunt projects..."
mapfile -t DIRS < <(
  find . -type f \( -name "*.tf" -o -name "terragrunt.hcl" \) \
    -not -path "./.diagnosis/*" -not -path "./.git/*" -printf '%h\n' | sort -u
)

if [ ${#DIRS[@]} -eq 0 ]; then
  echo "No Terraform or Terragrunt files found."
  exit 0
fi

EXIT_CODE=0
for d in "${DIRS[@]}"; do
  # Normalize dir
  dir="$(realpath -s "$d")"
  reldir="${dir#$ROOT_DIR/}"
  reldir=${reldir:-.}
  outdir="$ROOT_DIR/.infracost/$(echo "$reldir" | sed 's|/|-|g' | sed 's|^\.-||')"
  mkdir -p "$outdir"

  echo "\n---- Processing: $reldir ----"

  # Detect terragrunt
  if [ -f "$dir/terragrunt.hcl" ]; then
    echo "Detected Terragrunt project."
    if command -v terragrunt >/dev/null 2>&1; then
      echo "Found terragrunt binary; creating a plan and running Infracost against the plan JSON"
      tmpplan="$outdir/tfplan.binary"
      planjson="$outdir/plan.json"
      (cd "$dir" && terragrunt plan -out "$tmpplan") || { echo "terragrunt plan failed for $reldir"; EXIT_CODE=4; continue; }
      if terragrunt show -json "$tmpplan" > "$planjson" 2>/dev/null; then
        if ! infracost breakdown --path "$planjson" --format json --out-file "$outdir/report.json"; then
          echo "infracost failed for $reldir"
          EXIT_CODE=4
        fi
      else
        echo "terragrunt show failed for $reldir"
        EXIT_CODE=4
      fi
    else
      echo "Terragrunt detected but 'terragrunt' CLI not found in PATH. Skipping $reldir."
      echo "Install terragrunt or run Infracost manually for this directory after installing terragrunt."
      # do not mark as hard failure; continue scanning other projects
      continue
    fi
  else
    # Normal Terraform
    if ! infracost breakdown --path "$dir" --format json --out-file "$outdir/report.json"; then
      echo "infracost failed for $reldir"
      EXIT_CODE=4
    fi
  fi
done

echo "All done. Reports written to .infracost/"
exit $EXIT_CODE

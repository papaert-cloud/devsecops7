#!/usr/bin/env bash
# Helper to set Infracost API key locally and show CI snippet
set -euo pipefail

read -r -p "Enter your Infracost API key (or leave empty to exit): " KEY
if [ -z "$KEY" ]; then
  echo "No key provided. Exiting without writing any file."; exit 0
fi

mkdir -p "$HOME"
cat > ~/.infracost.env <<EOF
export INFRACOST_API_KEY="$KEY"
export INFRACOST_PRICING_API_ENDPOINT="https://pricing.api.infracost.io"
EOF

echo "Wrote ~/.infracost.env. Add to your shell profile to load automatically:"
echo "  source ~/.infracost.env"

echo "CI snippet (GitHub Actions):"
cat <<'YAML'
- name: Set Infracost API key
  run: echo "INFRACOST_API_KEY=${{ secrets.INFRACOST_API_KEY }}" >> $GITHUB_ENV
  # Add INFRACOST_PRICING_API_ENDPOINT similarly if using custom endpoint
YAML

echo "Done."

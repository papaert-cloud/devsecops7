# Infracost setup for this repository

This repo includes a small automation to run Infracost across all Terraform and Terragrunt directories.

Files added:
- `scripts/infracost.sh` — scans the repository and writes JSON reports to `.infracost/`.
- `.github/workflows/infracost.yml` — GitHub Actions to run on PRs and pushes to `main`.
- `.infracost/config.yml` — minimal Infracost config.

Quick start (local):

1. Install Infracost CLI: https://www.infracost.io/docs/installation/
2. From repo root run:

```bash
bash ./scripts/infracost.sh
```

CI / GitHub Actions:

1. Add `INFRACOST_API_KEY` as a secret in the repo settings.
2. On PRs and pushes the workflow will run and produce `.infracost` reports.

Notes:
- The script detects `terragrunt.hcl` files and runs Infracost with `--terragrunt` when present.
- Reports are written as JSON per-project into `.infracost/`.

# Repo Diagnosis Toolkit

This folder contains **collect_diag.sh**, a focused diagnostics script for Terraform/Terragrunt repos. 

# Diagnostics Outputs — What to Expect

The diagnostics toolkit (`.diagnosis/collect_diag.sh`) produces multiple artifacts, each designed for different levels of review: developer deep-dive, team discussion, or CI/CD automation.

---

## 1. **Text Report** (`diag-report.txt`)

The primary, human-readable report. It contains:

- **Repo Architecture (execution-relevant only)**  
  Trimmed project tree showing only IaC-critical files (`*.tf`, `*.tfvars`, `*.hcl`, `terragrunt.hcl`, `*.yaml`, `*.json`, `*.sh`, `Makefile`).  
  → Quickly reveals where root modules, reusable modules, and env configs live.

- **Environment / Tooling Context**  
  OS info, Terraform/Terragrunt versions, AWS CLI, Git, and helper tools (`jq`, `tflint`, `checkov`, `infracost`).  
  → Explains discrepancies if validation fails due to version drift.

- **Misconfigurations & Syntax Errors**  
  Parsed from `terraform validate -json` where possible, with file:line and a one-line summary.  
  → Highlights real coding issues, not just missing inputs.

- **Out-of-Sync Module Paths**  
  Detects modules that declare variables but never receive inputs, or use deprecated patterns.  
  → Helps prevent “module drift.”

- **Cleanup Candidates**  
  Lists `*.tfstate`, `*.plan`, `.bak`, `last_output.txt`, etc.  
  → Review and delete to reduce repo noise and prevent accidental commits.

- **Restructure & Optimization Hints**  
  Upgrade nudges (e.g., “Terraform v1.6.x → recommend v1.13+”), backend hygiene (move to remote state), provider pinning, or tfvars alignment.  
  → Concrete, prioritized steps to keep the repo healthy.
- A **visual TF map** that flags problem areas:
  - `[E]` = error (syntax/type/etc.)
  - `[V]` = needs tfvars (required variables missing)
  - `[OK]` = valid
- An optional **Markdown summary** (`diag-summary.md`) for PRs.
- An optional **JSON summary** (`--json`) for CI.

All outputs are written to `.diagnosis/diag-YYYYmmdd-HHMMSS/` and an optional `diag-*.tar.gz` bundle.

---

## Requirements

- **Terraform** (≥ 1.6.x recommended)
- **AWS CLI** (optional; enables backend reachability checks)
- **jq** (optional; enables JSON parsing for `terraform validate`)
- **tree** (optional; prettier repo snapshot)
- **GNU parallel** (optional; enables `--parallel N`)
- **Terragrunt** (optional; enables Terragrunt checks)
- **tflint**, **checkov** (optional; used if `--lint` is passed)
- **Infracost** (optional; auto-detected; shows cost breakdowns if available)

> If a tool is missing, the script continues and notes what was skipped.

---

## Quick Start

From repo root:

```bash
chmod +x .diagnosis/collect_diag.sh

# Fastest scan (validate-only, no copying or bundle), with JSON for CI
bash .diagnosis/collect_diag.sh --s0 --json > .diagnosis/last-summary.json

# Fuller pass (no plans), with file copy & bundle
bash .diagnosis/collect_diag.sh --no-plan --max-dirs 60

# Lint & policy checks (if tflint/checkov installed)
bash .diagnosis/collect_diag.sh --no-plan --lint

# Run validations in parallel
bash .diagnosis/collect_diag.sh --s0 --parallel 4

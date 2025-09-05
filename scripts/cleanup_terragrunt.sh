#!/usr/bin/env bash
set -euo pipefail

# cleanup_terragrunt.sh
# Safe, one-shot cleanup for Terragrunt/Terraform generated caches and plan artifacts.
# Default: dry-run (shows what would be removed). Use --yes to actually delete.
# By default preserves terraform state files; use --force-state to remove tfstate files (dangerous).

DRY_RUN=true
PRESERVE_STATE=true
FORCE_STATE=false
VERBOSE=true

usage() {
  cat <<EOF
Usage: $0 [--yes] [--force-state] [--quiet]

--yes         Actually perform deletions. Without it the script runs in dry-run mode.
--force-state Remove terraform.tfstate and backup files as well (dangerous).
--quiet       Minimal output.

This script safely removes:
 - .terragrunt-cache directories
 - generated .terraform directories
 - *.tfplan and plan.tfplan files

It excludes .git, .diagnosis, and keeps .infracost module sources intact.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --yes) DRY_RUN=false ;; 
    --force-state) FORCE_STATE=true ; PRESERVE_STATE=false ;; 
    --quiet) VERBOSE=false ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 2 ;;
  esac
done

log() { if [ "$VERBOSE" = true ]; then echo "$@"; fi }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Build find expressions
EXCLUDE_PATHS=( -path './.git' -o -path './.diagnosis' -o -path './.infracost/modules/*' )

# Helper to produce a -not path expression string
not_paths() {
  local expr=()
  for p in "${EXCLUDE_PATHS[@]}"; do
    expr+=( -not "$p" )
  done
  echo "${expr[@]}"
}

log "Dry run: $DRY_RUN | Preserve state: $PRESERVE_STATE"

# 1) Find .terragrunt-cache directories
mapfile -t TG_CACHE_DIRS < <(find . -type d -name '.terragrunt-cache' $(not_paths) 2>/dev/null | sort -u)
# 2) Find generated .terraform directories (skip some module dirs)
mapfile -t TF_DIRS < <(find . -type d -name '.terraform' $(not_paths) 2>/dev/null | sort -u)
# 3) Find plan files
mapfile -t PLAN_FILES < <(find . -type f \( -name '*.tfplan' -o -name 'plan.tfplan' \) $(not_paths) 2>/dev/null | sort -u)
# 4) Optionally find tfstate files (only if force)
if [ "$FORCE_STATE" = true ]; then
  mapfile -t TFSTATE_FILES < <(find . -type f \( -name 'terraform.tfstate' -o -name 'terraform.tfstate.backup' \) $(not_paths) 2>/dev/null | sort -u)
else
  TFSTATE_FILES=()
fi

# Summarize
if [ ${#TG_CACHE_DIRS[@]} -eq 0 ] && [ ${#TF_DIRS[@]} -eq 0 ] && [ ${#PLAN_FILES[@]} -eq 0 ] && [ ${#TFSTATE_FILES[@]} -eq 0 ]; then
  log "Nothing to remove. Repository appears clean of generated Terragrunt/Terraform caches and plans."
  exit 0
fi

log "Candidates to remove (dry-run=$DRY_RUN):"
if [ ${#TG_CACHE_DIRS[@]} -gt 0 ]; then
  log "  .terragrunt-cache dirs:"
  for d in "${TG_CACHE_DIRS[@]}"; do echo "    $d"; done
fi
if [ ${#TF_DIRS[@]} -gt 0 ]; then
  log "  .terraform dirs:"
  for d in "${TF_DIRS[@]}"; do echo "    $d"; done
fi
if [ ${#PLAN_FILES[@]} -gt 0 ]; then
  log "  plan files:"
  for f in "${PLAN_FILES[@]}"; do echo "    $f"; done
fi
if [ ${#TFSTATE_FILES[@]} -gt 0 ]; then
  log "  terraform state files (will remove because --force-state given):"
  for f in "${TFSTATE_FILES[@]}"; do echo "    $f"; done
fi

if [ "$DRY_RUN" = true ]; then
  log "Dry-run complete. Re-run with --yes to delete the above items."
  exit 0
fi

# Delete phase
remove_list() {
  local arr=("$@")
  for p in "${arr[@]}"; do
    if [ -e "$p" ]; then
      log "Removing: $p"
      rm -rf -- "$p"
    fi
  done
}

remove_list "${TG_CACHE_DIRS[@]}"
remove_list "${TF_DIRS[@]}"
remove_list "${PLAN_FILES[@]}"
if [ ${#TFSTATE_FILES[@]} -gt 0 ]; then
  remove_list "${TFSTATE_FILES[@]}"
fi

log "Cleanup finished. You may want to run 'git status' and commit deletions if desired."
exit 0

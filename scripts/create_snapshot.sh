#!/usr/bin/env bash
# Create a clean, minimal orphan branch containing only terragrunt/, modules/ and env/ (no .terraform or state)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BRANCH_NAME="terragrunt-clean-snapshot"

# Confirm working tree is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean - please commit or stash changes before running"
  exit 1
fi

git checkout --orphan "$BRANCH_NAME"
# remove index and working tree files
git reset --hard
# remove everything except what we want to keep
# copy desired paths to /tmp and restore
TMPDIR=$(mktemp -d)
cp -a modules "$TMPDIR/" 2>/dev/null || true
cp -a terragrunt "$TMPDIR/" 2>/dev/null || true
cp -a env "$TMPDIR/" 2>/dev/null || true
cp -a README.md "$TMPDIR/" 2>/dev/null || true

# clean workspace, restore minimal files
git rm -rf . > /dev/null 2>&1 || true
rm -rf * .[^.]* 2>/dev/null || true || true
cp -a "$TMPDIR"/* .

git add .
if git diff --cached --quiet; then
  echo "No files to commit"
else
  git commit -m "snapshot: terragrunt live tree + modules"
fi

echo "Created orphan branch $BRANCH_NAME with terragrunt + modules + env. Push with:
  git push --set-upstream origin $BRANCH_NAME"

#!/usr/bin/env bash
# collect_diag.sh — Repo diagnostics for Terraform/Terragrunt, writing into .diagnosis/
# Features:
# - Execution-focused scan (excludes docs/images/builds/states/etc.)
# - Visual TF map with flags [E]=error [V]=needs tfvars [OK]=valid
# - JSON-based validate parsing (if jq available) with file:line diagnostics
# - Provider lock summary, backend checks, AWS backend reachability
# - Terragrunt awareness (hclfmt), optional lint/policy (tflint/checkov)
# - Optional Infracost breakdowns
# - Plan risk heuristic (destroy detection in captured outputs)
# - Parallel validation (--parallel N)
# - Stronger redaction for secrets
# - Markdown summary & optional JSON summary
set -euo pipefail

# ---------- repo roots & out paths ----------
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTBASE="${REPO_ROOT}/.diagnosis"; mkdir -p "${OUTBASE}"

# ---------- defaults ----------
TARGET="${REPO_ROOT}"
FAILED_CMD="(not provided)"
NO_TREE=false
NO_COPY=false
NO_PLAN=false
CREATE_BUNDLE=true
MAX_DIRS=60
EXTRA_EXCLUDES=()
DIAGIGNORE_FILE=""
LIST_ONLY=false
JSON=false
LINT=false
PARALLEL="${PARALLEL:-1}" # default sequential; override with --parallel N

# ---------- usage ----------
print_help(){ cat <<'EOF'
Usage: .diagnosis/collect_diag.sh [flags]
  --s0|--fast         Fastest (validate-only, no tree/copy/plan/bundle)
  --target PATH       Limit scan to PATH (default: repo root)
  --cmd "..."         Record a failing cmd in report (context only)
  --no-tree           Skip big tree snapshot (map still prints)
  --no-copy           Do not copy files into .diagnosis (report-only)
  --no-plan           Skip provider scan & offline plans
  --no-bundle         Do not create tar.gz bundle
  --max-dirs N        Cap TF directories scanned (default 60)
  --add-exclude GLOB  Add extra exclude (repeatable)
  --diagignore FILE   Load excludes from file (one glob per line)
  --list-excludes     Print effective excludes and exit
  --lint              Run tflint & checkov (if installed)
  --parallel N        Run validation in parallel (default 1)
  --json              Emit JSON summary (CI)
  -h|--help           Help
EOF
}

# ---------- args ----------
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --s0|--fast) NO_TREE=true; NO_COPY=true; NO_PLAN=true; CREATE_BUNDLE=false; shift ;;
    --target) TARGET="${2:-$REPO_ROOT}"; shift 2 ;;
    --cmd) FAILED_CMD="${2:-"(not provided)"}"; shift 2 ;;
    --no-tree) NO_TREE=true; shift ;;
    --no-copy) NO_COPY=true; shift ;;
    --no-plan) NO_PLAN=true; shift ;;
    --no-bundle) CREATE_BUNDLE=false; shift ;;
    --max-dirs) MAX_DIRS="${2:-60}"; shift 2 ;;
    --add-exclude) EXTRA_EXCLUDES+=("${2:-}"); shift 2 ;;
    --diagignore) DIAGIGNORE_FILE="${2:-}"; shift 2 ;;
    --list-excludes) LIST_ONLY=true; shift ;;
    --lint) LINT=true; shift ;;
    --parallel) PARALLEL="${2:-1}"; shift 2 ;;
    --json) JSON=true; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
if [[ ${#ARGS[@]} -ge 1 ]]; then TARGET="${ARGS[0]}"; fi
command -v realpath >/dev/null 2>&1 && TARGET="$(realpath "$TARGET" 2>/dev/null || echo "$TARGET")"

TS="$(date +%Y%m%d-%H%M%S)"
OUTDIR="${OUTBASE}/diag-${TS}"
REPORT="${OUTDIR}/diag-report.txt"
BUNDLE="${OUTBASE}/diag-${TS}.tar.gz"
MD="${OUTDIR}/diag-summary.md"
mkdir -p "${OUTDIR}"

say(){ printf "%b\n" "$*" >&2; }
relpath(){ local p="$1"; p="${p#${REPO_ROOT}/}"; echo "$p"; }
indent_for(){ local p="$1"; awk -v s="$(grep -o "/" <<<"$p" | wc -l)" 'BEGIN{for(i=0;i<s;i++)printf "  "}' ; }

# ---------- excludes (execution-only) ----------
EXCLUDES_DEFAULT=(
  "*/.git/*" "*/.terraform/*" "*/node_modules/*" "*/__pycache__/*"
  "*/.vscode/*" "*/.idea/*" "*/.venv/*" "*/dist/*" "*/build/*" "*/target/*"
  "*/.github/*" "*/prompts/*" "*/diagrams/*" "*/docs/*" "*/documentation/*"
  "*/images/*" "*/img/*" "*/art/*" "*/assets/*"
  "*/...QUICK_REF/*" "*/...Quick_Ref/*" "*/...Git_IaC_Cheatsheet/*"
  "*/testdata/*" "*/examples/*" "*/example/*"
  "*/.diagnosis/*"
  # files
  "*/terraform.tfstate*" "*.zip" "*.tar.gz" "*.tgz" "*.gz" "*.7z"
  "*.png" "*.jpg" "*.jpeg" "*.gif" "*.svg" "*.pdf" "*.doc*" "*.ppt*" "*.xls*"
  "*last_output.txt" "*tfplan" "*nul" "*environment-snapshot.txt"
)
if [[ -n "${DIAGIGNORE_FILE}" && -f "${DIAGIGNORE_FILE}" ]]; then
  mapfile -t IGN_LINES < <(grep -vE '^\s*(#|$)' "${DIAGIGNORE_FILE}" || true)
  EXCLUDES_DEFAULT+=("${IGN_LINES[@]}")
fi
EXCLUDES_DEFAULT+=("${EXTRA_EXCLUDES[@]:-}")
if [[ "${LIST_ONLY}" == true ]]; then printf '  - %s\n' "${EXCLUDES_DEFAULT[@]}"; exit 0; fi
TREE_SIMPLE_IGNORE=".git|node_modules|__pycache__|.terraform|.vscode|.idea|docs|images|prompts|diagrams|dist|build|target|...QUICK_REF|.diagnosis"

# ---------- helpers ----------
copy_rel(){
  local src="$1" dest="$2"; mkdir -p "${dest}"
  rsync -a --prune-empty-dirs \
    --include='*/' \
    --include='*.tf' --include='*.tf.json' \
    --include='*.tfvars' --include='*.hcl' --include='terragrunt.hcl' \
    --include='*.yaml' --include='*.yml' --include='*.json' \
    --include='*.sh' --include='Makefile' \
    $(printf -- "--exclude=%s " "${EXCLUDES_DEFAULT[@]}") \
    "$src"/ "$dest"/ 2>/dev/null || true
}
redact_in_place(){
  sed -i -E \
    -e 's/AKIA[0-9A-Z]{16}/AKIA****************/g' \
    -e 's/(ASIA[0-9A-Z]{16})/ASIA****************/g' \
    -e 's/("access_key"\s*=\s*")[^"]+/\1[REDACTED]/g' \
    -e 's/("secret_key"\s*=\s*")[^"]+/\1[REDACTED]/g' \
    -e 's/(password\s*=\s*")[^"]+/\1[REDACTED]/g' \
    -e 's/(xox[baprs]-[A-Za-z0-9-]+)/[REDACTED_SLACK]/g' \
    -e 's/(ghp_[A-Za-z0-9]{36})/[REDACTED_GITHUB]/g' \
    -e 's/(AIza[0-9A-Za-z\-_]{35})/[REDACTED_GCP]/g' \
    -e 's/([0-9]{12})/[ACCOUNT_ID]/g' \
    "$@" 2>/dev/null || true
}

# JSON validate helper (returns raw JSON or empty)
json_validate(){
  local d="$1" out
  out="$(cd "$d" && terraform validate -json 2>/dev/null || true)"
  printf '%s' "$out"
}

# ---------- header ----------
{
  echo "=== PROJECT STRUCTURE (execution files only, trimmed) ==="
  if ! $NO_TREE; then
    if ! command -v tree >/dev/null 2>&1; then sudo apt-get update >/dev/null 2>&1 || true; sudo apt-get install -y tree >/dev/null 2>&1 || true; fi
    ( cd "$REPO_ROOT" && (tree -a -I "$TREE_SIMPLE_IGNORE" 2>/dev/null || tree -a 2>/dev/null) ) || true
    echo; echo "(Note: non-execution directories/files are excluded from copy/bundle even if shown here.)"
  else
    echo "(skipped by --no-tree / --s0)"
  fi
  echo
  echo "=== SYSTEM & TOOL VERSIONS ==="
  uname -a || true
  lsb_release -a 2>/dev/null || cat /etc/os-release 2>/dev/null || true
  echo; echo "Terraform:"; terraform version 2>&1 || echo "terraform not found"
  echo; echo "Terragrunt:"; terragrunt --version 2>&1 || echo "terragrunt not found"
  echo; echo "AWS CLI:"; aws --version 2>&1 || echo "aws cli not found"
  echo; echo "Git:"; git --version 2>&1 || echo "git not found"
  echo
  echo "=== REPO ROOT ==="; echo "${REPO_ROOT}"
  echo; echo "=== TARGET PATH ==="; echo "${TARGET}"
  echo; echo "=== FAILED COMMAND (as reported) ==="; echo "${FAILED_CMD}"
} > "${REPORT}"

# ---------- discover TF dirs ----------
mapfile -t TF_DIRS < <(
  find "$TARGET" \
    \( -type d \( -name .git -o -name .terraform -o -name node_modules -o -name __pycache__ -o -name .vscode -o -name .idea -o -name .venv -o -name dist -o -name build -o -name target -o -name docs -o -name images -o -name prompts -o -name diagrams -o -name ...QUICK_REF -o -name .diagnosis \) -prune \) -o \
    \( -type f -name '*.tf' -print \) \
  | xargs -r -n1 dirname | sort -u | head -n "$MAX_DIRS"
)

# ---------- optional copy ----------
if ! $NO_COPY; then
  copy_rel "${TARGET}" "${OUTDIR}/scan"
  [[ "$TARGET" != "$REPO_ROOT" ]] && copy_rel "${REPO_ROOT}" "${OUTDIR}/repo-root"
fi

# ---------- validate (parallel aware) ----------
declare -a OK_DIRS=() VAR_DIRS=() ERR_DIRS=()
declare -A DIR_SUMMARY=() DIR_LOG=()

validate_dir(){
  local d="$1"
  local o=""
  ( cd "$d" && terraform init -backend=false -input=false -lock=false >/dev/null 2>&1 || true )
  if command -v jq >/dev/null 2>&1; then
    local vj; vj="$(json_validate "$d")"
    if [[ -n "$vj" ]]; then
      # print actionable diagnostics
      echo "$vj" | jq -r '
        if .valid == true then
          "VALID"
        else
          (.diagnostics[]? |
            ( "[" + (.severity|ascii_upcase) + "] " +
              (.range.filename // "unknown") + ":" + ((.range.start.line // 0)|tostring) +
              " - " + (.summary // "") + " :: " + (.detail // "")) )
        end
      ' || true
      # return a simple classification token
      if echo "$vj" | jq -e '.valid == true' >/dev/null; then
        echo "__CLASS__OK"
      elif echo "$vj" | jq -e '.diagnostics[]? | select(.severity=="error")' >/dev/null; then
        echo "__CLASS__ERR"
      else
        echo "__CLASS__VAR"
      fi
      return 0
    fi
  fi
  # fallback: text validate
  o="$(cd "$d" && terraform validate -no-color 2>&1 || true)"
  echo "$o"
  if grep -q "Error:" <<<"$o"; then
    if grep -qi "No value for required variable" <<<"$o"; then
      echo "__CLASS__VAR"
    else
      echo "__CLASS__ERR"
    fi
  else
    echo "__CLASS__OK"
  fi
}

{
  echo
  echo "=== VALIDATION (backend=false) — scanned ${#TF_DIRS[@]}/$MAX_DIRS dirs ==="
  if [[ ${#TF_DIRS[@]} -eq 0 ]]; then
    echo "No Terraform files found under ${TARGET} (after excludes)"
  else
    if [[ "$PARALLEL" -gt 1 ]]; then
      export -f json_validate validate_dir
      export REPO_ROOT
      printf "%s\n" "${TF_DIRS[@]}" | xargs -n1 -P "$PARALLEL" -I{} bash -lc '
        d="{}"; echo "--- $d ---"; validate_dir "$d"
      '
    else
      for d in "${TF_DIRS[@]}"; do
        echo "--- $d ---"
        validate_dir "$d"
      done
    fi
  fi
} >> "${REPORT}"

# classify by scanning lines we just wrote for each dir
# (simple second pass to avoid complex IPC)
current=""
while IFS= read -r line; do
  if [[ "$line" == ---* ]]; then current="${line#--- }"; continue; fi
  [[ -z "$current" ]] && continue
  if [[ "$line" == "__CLASS__OK" ]]; then DIR_SUMMARY["$current"]="ok"; OK_DIRS+=("$current")
  elif [[ "$line" == "__CLASS__ERR" ]]; then DIR_SUMMARY["$current"]="error"; ERR_DIRS+=("$current")
  elif [[ "$line" == "__CLASS__VAR" ]]; then DIR_SUMMARY["$current"]="needs tfvars"; VAR_DIRS+=("$current")
  fi
done < <(awk '/^=== VALIDATION/{p=1;next} /^=== /{p=0} p' "${REPORT}")

# ---------- providers scan (optional) ----------
{
  echo
  echo "=== PROVIDERS SCAN + OFFLINE PLAN (sample) ==="
  if $NO_PLAN; then
    echo "(skipped by --no-plan / --s0)"
  else
    for d in "${TF_DIRS[@]}"; do
      [[ -f "$d/main.tf" ]] || continue
      echo "--- $d ---"
      ( cd "$d" && terraform providers 2>&1 || true )
      ( cd "$d" && terraform plan -refresh=false -lock=false -input=false -no-color 2>&1 || true )
      echo
    done
  fi
} >> "${REPORT}"

# ---------- provider lock summary ----------
{
  echo
  echo "=== PROVIDER LOCK SUMMARY ==="
  for d in "${TF_DIRS[@]}"; do
    [[ -f "$d/.terraform.lock.hcl" ]] || continue
    echo "--- $d ---"
    awk 'BEGIN{RS="";FS="\n"} /provider "registry\.terraform\.io/ {gsub(/\r/,""); print $0 "\n"}' "$d/.terraform.lock.hcl" || true
  done
} >> "${REPORT}"

# ---------- backend checks ----------
{
  echo
  echo "=== BACKEND CHECKS ==="
  for d in "${TF_DIRS[@]}"; do
    btype="$(grep -RhoP 'backend\s+"(\w+)"' "$d" 2>/dev/null | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')"
    [[ -z "$btype" ]] && btype="(none)"
    echo "--- $d --- backend: $btype"
  done
} >> "${REPORT}"

# ---------- AWS backend reachability ----------
if command -v aws >/dev/null 2>&1; then
  {
    echo
    echo "=== AWS BACKEND REACHABILITY (best-effort) ==="
    for d in "${TF_DIRS[@]}"; do
      s3b=$(grep -RhoP 'bucket\s*=\s*"?([A-Za-z0-9\.\-]+)' "$d" 2>/dev/null | head -n1 | awk -F'"' '{print $2}')
      ddb=$(grep -RhoP 'dynamodb_table\s*=\s*"?([A-Za-z0-9\.\-]+)' "$d" 2>/dev/null | head -n1 | awk -F'"' '{print $2}')
      [[ -z "$s3b" && -z "$ddb" ]] && continue
      echo "--- $d ---"
      if [[ -n "$s3b" ]]; then
        aws s3api head-bucket --bucket "$s3b" >/dev/null 2>&1 \
          && echo "S3 bucket ok: $s3b" || echo "S3 bucket NOT reachable: $s3b"
      fi
      if [[ -n "$ddb" ]]; then
        aws dynamodb describe-table --table-name "$ddb" >/dev/null 2>&1 \
          && echo "DynamoDB table ok: $ddb" || echo "DynamoDB table NOT reachable: $ddb"
      fi
    done
  } >> "${REPORT}"
fi

# ---------- Terragrunt checks ----------
{
  echo
  echo "=== TERRAGRUNT CHECKS ==="
  mapfile -t TG_DIRS < <(find "$TARGET" -name 'terragrunt.hcl' -not -path '*/.diagnosis/*' -printf '%h\n' 2>/dev/null | sort -u)
  if [[ ${#TG_DIRS[@]} -eq 0 ]]; then
    echo "(no terragrunt.hcl found)"
  else
    if command -v terragrunt >/dev/null 2>&1; then
      for tgd in "${TG_DIRS[@]}"; do
        echo "--- $tgd ---"
        (cd "$tgd" && terragrunt hclfmt >/dev/null 2>&1 && echo "hclfmt OK" || echo "hclfmt ERR") || true
      done
    else
      echo "terragrunt not installed"
    fi
  fi
} >> "${REPORT}"

# ---------- Visual TF Map ----------
{
  echo
  echo "=== VISUAL TF MAP (execution-relevant & flagged) ==="
  echo "Legend: [E]=error  [V]=needs tfvars  [OK]=valid"
  if [[ ${#TF_DIRS[@]} -eq 0 ]]; then
    echo "(no terraform directories)"
  else
    for d in "${TF_DIRS[@]}"; do
      rel="$(relpath "$d")"; ind="$(indent_for "$rel")"
      badge="[OK]"
      [[ "${DIR_SUMMARY[$d]:-}" == "error" ]] && badge="[E]"
      [[ "${DIR_SUMMARY[$d]:-}" == "needs tfvars" ]] && badge="[V]"
      printf "%s%s %s\n" "$ind" "$badge" "$rel"
    done
  fi
} >> "${REPORT}"

# ---------- Variables summary ----------
{
  echo
  echo "=== VARIABLE DEFINITIONS (parsed) ==="
  SEARCH_BASE="$TARGET"; $NO_COPY || SEARCH_BASE="${OUTDIR}/scan"
  find "$SEARCH_BASE" \
    \( -type d \( -name .git -o -name .terraform -o -name node_modules -o -name __pycache__ -o -name .vscode -o -name .idea -o -name .venv -o -name .diagnosis \) -prune \) -o \
    \( -type f \( -name 'variable.tf' -o -name 'variables.tf' \) -print \) \
  | while read -r f; do
      echo "---- ${f} ----"
      awk '/^variable *\"/{flag=1} flag; /\}/{print; flag=0}' "$f" || true
      echo
    done
} >> "${REPORT}"

# ---------- Lint & Policy (optional) ----------
if $LINT; then
  {
    echo
    echo "=== LINT & POLICY (tflint/checkov) ==="
    for d in "${TF_DIRS[@]}"; do
      echo "--- $d ---"
      if command -v tflint >/dev/null 2>&1; then (cd "$d" && tflint --no-color 2>&1 || true); else echo "tflint not installed"; fi
      if command -v checkov >/dev/null 2>&1; then (cd "$d" && checkov -q -d . 2>&1 || true); else echo "checkov not installed"; fi
      echo
    done
  } >> "${REPORT}"
fi

# ---------- Infracost (optional) ----------
if command -v infracost >/dev/null 2>&1; then
  {
    echo
    echo "=== INFRACOST (rough) ==="
    for d in "${TF_DIRS[@]}"; do
      [[ -f "$d/main.tf" ]] || continue
      echo "--- $d ---"
      (cd "$d" && infracost breakdown --path . --format table || true)
    done
  } >> "${REPORT}"
fi

# ---------- Cleanup candidates ----------
CLEANUP_MATCHES="$OUTDIR/cleanup.txt"
{
  find "$TARGET" -type f \( -name 'terraform.tfstate*' -o -name '*tfplan' -o -name 'last_output.txt' -o -name '*.bak' -o -name '*.backup' \) \
    -not -path "*/.terraform/*" -not -path "*/.git/*" -not -path "*/.diagnosis/*" 2>/dev/null || true
} > "$CLEANUP_MATCHES"

{
  echo
  echo "=== CANDIDATES FOR CLEANUP (review before deleting) ==="
  if [[ -s "$CLEANUP_MATCHES" ]]; then cat "$CLEANUP_MATCHES"; else echo "(none detected)"; fi
} >> "${REPORT}"

# ---------- Plan risk scan (heuristic) ----------
{
  echo
  echo "=== PLAN RISK SCAN (heuristic) ==="
  grep -RniE '^-.*will be destroyed|Plan:\s+[0-9]+\s+to destroy' "${OUTDIR}" 2>/dev/null || echo "(no destroy hints found in captured output)"
} >> "${REPORT}"

# ---------- Optimization hints ----------
{
  echo
  echo "=== RESTRUCTURE / OPTIMIZATION HINTS ==="
  tv="$(terraform version 2>/dev/null | head -n1 | awk '{print $2}' | tr -d 'v' || true)"
  if [[ -n "$tv" ]]; then
    case "$tv" in
      0.*|1.0*|1.1*|1.2*|1.3*|1.4*|1.5*|1.6*) echo "- Consider upgrading Terraform (detected v$tv) for newer language/provider features.";;
    esac
  fi
  command -v terragrunt >/dev/null 2>&1 || echo "- Terragrunt not found: if desired, add run-all validate to CI pipelines."
  if grep -q 'terraform.tfstate' "$CLEANUP_MATCHES" 2>/dev/null; then
    echo "- State files present: move to remote backend (S3 + DynamoDB) and ignore '*.tfstate*' in git."
  fi
  [[ ${#VAR_DIRS[@]} -gt 0 ]] && echo "- Some roots/modules need tfvars: pass -var-file=infra/env/*.tfvars during plan/apply."
  if ! grep -R "required_providers" -n "$TARGET" 2>/dev/null | grep -q "aws"; then
    echo "- Pin AWS provider with required_providers + version in each root."
  fi
  if ! grep -R "required_version" -n "$TARGET" 2>/dev/null | grep -q "required_version"; then
    echo "- Set terraform { required_version = \">= 1.6.0\" } in each root."
  fi
  echo "- Keep env tfvars in infra/env/, avoid committing tfplan/last_output.txt, and prune old templates/modules."
} >> "${REPORT}"

# ---------- redact ----------
redact_in_place "${REPORT}" || true
if ! $NO_COPY; then
  find "${OUTDIR}" -type f \( -name "*.tf" -o -name "*.tfvars" -o -name "*.hcl" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.sh" -o -name "diag-report.txt" \) -print0 \
    | xargs -0 -r bash -c 'sed -i -E -e "s/AKIA[0-9A-Z]{16}/AKIA****************/g" -e "s/(ASIA[0-9A-Z]{16})/ASIA****************/g" -e "s/([0-9]{12})/[ACCOUNT_ID]/g" "$@"' --
fi

# ---------- bundle ----------
if $CREATE_BUNDLE; then
  tar -czf "${BUNDLE}" -C "${OUTBASE}" "diag-${TS}"
  echo "Created bundle: ${BUNDLE}"
else
  echo "Bundle creation skipped (--no-bundle / --s0)"
fi

echo "Report: ${REPORT}"

# ---------- Markdown summary ----------
{
  echo "# Repo Diagnostics — ${TS}"
  echo
  echo "## Summary"
  echo "- Scanned TF dirs: ${#TF_DIRS[@]}"
  echo "- OK: ${#OK_DIRS[@]}  | Needs tfvars: ${#VAR_DIRS[@]}  | Errors: ${#ERR_DIRS[@]}"
  echo
  echo "## Visual Map"
  echo '```'
  awk '/^=== VISUAL TF MAP/{p=1;next} /^=== /{p=0} p' "${REPORT}"
  echo '```'
  echo
  echo "## Cleanup Candidates"
  echo '```'
  if [[ -s "$CLEANUP_MATCHES" ]]; then cat "$CLEANUP_MATCHES"; else echo "(none)"; fi
  echo '```'
} > "${MD}"
echo "Markdown summary: ${MD}"

# ---------- JSON summary ----------
if $JSON; then
  tf_dirs_json=$(printf '"%s",' "${TF_DIRS[@]}" | sed 's/,$//'); [[ -n "$tf_dirs_json" ]] || tf_dirs_json=""
  ok_json=$(printf '"%s",' "${OK_DIRS[@]}" | sed 's/,$//'); [[ -n "$ok_json" ]] || ok_json=""
  var_json=$(printf '"%s",' "${VAR_DIRS[@]}" | sed 's/,$//'); [[ -n "$var_json" ]] || var_json=""
  err_json=$(printf '"%s",' "${ERR_DIRS[@]}" | sed 's/,$//'); [[ -n "$err_json" ]] || err_json=""
  if $CREATE_BUNDLE; then BUNDLE_JSON="\"${BUNDLE}\""; else BUNDLE_JSON="null"; fi
  printf '{'
  printf '"repo_root":"%s",' "$REPO_ROOT"
  printf '"target":"%s",' "$TARGET"
  printf '"report":"%s",' "$REPORT"
  printf '"bundle":%s,' "$BUNDLE_JSON"
  printf '"tf_dir_count":%d,' "${#TF_DIRS[@]}"
  printf '"ok_count":%d,' "${#OK_DIRS[@]}"
  printf '"needs_tfvars_count":%d,' "${#VAR_DIRS[@]}"
  printf '"error_count":%d,' "${#ERR_DIRS[@]}"
  printf '"scanned_dirs":[%s],' "$tf_dirs_json"
  printf '"ok_dirs":[%s],' "$ok_json"
  printf '"needs_tfvars_dirs":[%s],' "$var_json"
  printf '"error_dirs":[%s]' "$err_json"
  printf '}\n'
fi

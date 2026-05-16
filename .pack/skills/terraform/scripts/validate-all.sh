#!/usr/bin/env bash
set -euo pipefail

# validate-all.sh
# Runs terraform fmt -check, terraform validate, and tflint
# across every directory containing Terraform files.
#
# Usage:
#   ./scripts/validate-all.sh          # validate all directories
#   ./scripts/validate-all.sh ./envs   # validate under a specific path
#   SKIP_TFLINT=1 ./scripts/validate-all.sh

ROOT="${1:-.}"
SKIP_TFLINT="${SKIP_TFLINT:-0}"

# Find directories with at least one *.tf file (excluding .terraform)
mapfile -t dirs < <(find "$ROOT" -type d -name '.terraform' -prune -o -type f -name '*.tf' -print | sed 's|/[^/]*$||' | sort -u)

if [[ ${#dirs[@]} -eq 0 ]]; then
  echo "No Terraform directories found under $ROOT"
  exit 0
fi

fmt_errors=0
validate_errors=0
tflint_errors=0
declare -a failed_dirs

for dir in "${dirs[@]}"; do
  pushd "$dir" > /dev/null

  if [[ ! -f .terraform.lock.hcl ]]; then
    echo "  -> Skipping $dir (not initialized)"
    popd > /dev/null
    continue
  fi

  echo "==> $dir"

  # terraform fmt -check
  if ! terraform fmt -check -recursive -diff > /tmp/tf_fmt.log 2>&1; then
    ((fmt_errors++))
    failed_dirs+=("$dir")
    if [[ -s /tmp/tf_fmt.log ]]; then
      sed 's/^/    /' /tmp/tf_fmt.log
    fi
  fi

  # terraform validate
  if ! terraform validate > /tmp/tf_validate.log 2>&1; then
    ((validate_errors++))
    failed_dirs+=("$dir")
    if [[ -s /tmp/tf_validate.log ]]; then
      sed 's/^/    /' /tmp/tf_validate.log
    fi
  fi

  # tflint
  if [[ "$SKIP_TFLINT" -eq 0 ]] && command -v tflint &> /dev/null; then
    if ! tflint > /tmp/tf_tflint.log 2>&1; then
      ((tflint_errors++))
      failed_dirs+=("$dir")
      if [[ -s /tmp/tf_tflint.log ]]; then
        sed 's/^/    /' /tmp/tf_tflint.log
      fi
    fi
  fi

  popd > /dev/null
done

echo ""
echo "========================"
echo "Summary"
echo "========================"
echo "Directories checked: ${#dirs[@]}"
echo "Format errors:       $fmt_errors"
echo "Validate errors:     $validate_errors"
echo "TFLint errors:       $tflint_errors"

unique_fails=($(printf "%s\n" "${failed_dirs[@]}" | sort -u))
if [[ ${#unique_fails[@]} -gt 0 ]]; then
  echo "Failed directories:"
  for d in "${unique_fails[@]}"; do
    echo "  - $d"
  done
fi

if [[ ${#unique_fails[@]} -gt 0 ]]; then
  exit 1
fi

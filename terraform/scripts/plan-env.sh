#!/usr/bin/env bash
set -euo pipefail

# plan-env.sh
# Runs terraform plan for a specific environment directory,
# automatically resolving var files and backend configuration.
#
# Usage:
#   ./scripts/plan-env.sh dev          # envs/dev/terraform.tfvars
#   ./scripts/plan-env.sh prod         # envs/prod/terraform.tfvars
#   ENVS_DIR=environments ./scripts/plan-env.sh staging
#   EXTRA_VARS="-var=instance_count=2" ./scripts/plan-env.sh dev
#   DESTROY=1 ./scripts/plan-env.sh dev  # plan a destroy

ENV_NAME="${1:?Usage: plan-env.sh <environment>}"
ENVS_DIR="${ENVS_DIR:-envs}"
ENV_DIR="$ENVS_DIR/$ENV_NAME"

if [[ ! -d "$ENV_DIR" ]]; then
  echo "ERROR: Environment directory not found: $ENV_DIR"
  echo ""
  echo "Expected structure:"
  echo "  $ENVS_DIR/"
  echo "    ├── dev/"
  echo "    │   ├── main.tf"
  echo "    │   ├── backend.tf"
  echo "    │   └── terraform.tfvars"
  echo "    └── prod/"
  echo "        └── ..."
  exit 1
fi

pushd "$ENV_DIR" > /dev/null

# Auto-detect var files in order of precedence
var_files=()
for vf in "$ENV_DIR/terraform.tfvars" "$ENV_DIR/terraform.$ENV_NAME.tfvars"; do
  if [[ -f "$vf" ]]; then
    var_files+=("-var-file=$vf")
  fi
done

# Auto-detect .auto.tfvars (applied automatically by Terraform anyway,
# but we include explicitly for visibility)
for vf in "$ENV_DIR"/*.auto.tfvars "$ENV_DIR"/*.auto.tfvars.json; do
  [[ -f "$vf" ]] && var_files+=("-var-file=$vf")
done

echo "==> Environment: $ENV_NAME"
echo "==> Directory:   $ENV_DIR"
echo "==> Var files:   ${var_files[*]:-(none)}"
echo ""

terraform init -upgrade=false -reconfigure

plan_opts=("-out=$ENV_NAME.tfplan" "-detailed-exitcode")

[[ -n "${var_files[*]}" ]] && plan_opts+=("${var_files[@]}")
[[ -n "${EXTRA_VARS:-}" ]] && plan_opts+=($EXTRA_VARS)
[[ "${DESTROY:-0}" == "1" ]] && plan_opts+=("-destroy")

set +e
terraform plan "${plan_opts[@]}"
exit_code=$?
set -e

echo ""
case $exit_code in
  0) echo "No changes. Infrastructure is up to date." ;;
  1) echo "Plan failed with an error." ; exit 1 ;;
  2) echo "Changes detected. Plan saved to: $ENV_DIR/$ENV_NAME.tfplan" ;;
esac

popd > /dev/null

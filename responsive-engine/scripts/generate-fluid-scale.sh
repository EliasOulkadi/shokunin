#!/usr/bin/env bash
# generate-fluid-scale.sh
# Generate CSS clamp() values for typography and spacing.
#
# Usage:
#   ./generate-fluid-scale.sh [options]
#
# Options:
#   --min-viewport <px>    Minimum viewport width (default: 375)
#   --max-viewport <px>    Maximum viewport width (default: 1440)
#   --min-value <px>       Minimum property value (required)
#   --max-value <px>       Maximum property value (required)
#   --unit <string>        Output unit (rem or px, default: rem)
#   --precision <int>      Decimal places (default: 4)
#   --property <string>    CSS property name for output comment
#   --css-var <string>     CSS custom property name to wrap in var()
#   --base-font <px>       Root font size for px-to-rem (default: 16)
#   --json                 Output as JSON array
#   --range                Output min/max as a range comment
#   -h, --help             Show this help
#
# Examples:
#   ./generate-fluid-scale.sh --min-value 16 --max-value 24
#   ./generate-fluid-scale.sh --min-value 16 --max-value 24 --unit px
#   ./generate-fluid-scale.sh --min-value 16 --max-value 24 --css-var --font-size
#   ./generate-fluid-scale.sh --min-value 48 --max-value 80 --property --space-xl --json

set -euo pipefail

# Defaults
MIN_VIEWPORT=375
MAX_VIEWPORT=1440
MIN_VALUE=
MAX_VALUE=
UNIT="rem"
PRECISION=4
PROPERTY=""
CSS_VAR=""
BASE_FONT=16
JSON_MODE=false
RANGE=false

usage() {
  sed -n '3,/^$/s/^# //p' "$0"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-viewport)  MIN_VIEWPORT="$2";  shift 2 ;;
    --max-viewport)  MAX_VIEWPORT="$2";  shift 2 ;;
    --min-value)     MIN_VALUE="$2";     shift 2 ;;
    --max-value)     MAX_VALUE="$2";     shift 2 ;;
    --unit)          UNIT="$2";          shift 2 ;;
    --precision)     PRECISION="$2";     shift 2 ;;
    --property)      PROPERTY="$2";      shift 2 ;;
    --css-var)       CSS_VAR="$2";       shift 2 ;;
    --base-font)     BASE_FONT="$2";     shift 2 ;;
    --json)          JSON_MODE=true;     shift ;;
    --range)         RANGE=true;         shift ;;
    -h|--help)       usage              ;;
    *)               echo "Unknown: $1"; usage ;;
  esac
done

if [[ -z "$MIN_VALUE" || -z "$MAX_VALUE" ]]; then
  echo "Error: --min-value and --max-value are required" >&2
  usage
fi

# Validate numeric
for v in MIN_VIEWPORT MAX_VIEWPORT MIN_VALUE MAX_VALUE PRECISION BASE_FONT; do
  if ! [[ "${!v}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: $v must be numeric, got '${!v}'" >&2
    exit 1
  fi
done

# Convert px values to target unit
to_unit() {
  local px_val="$1"
  if [[ "$UNIT" == "rem" ]]; then
    awk "BEGIN { printf \"%.${PRECISION}f\", $px_val / $BASE_FONT }"
  else
    awk "BEGIN { printf \"%.${PRECISION}f\", $px_val }"
  fi
}

# Build clamp(): clamp(min, preferred, max)
# Formula: preferred = min_value + (max_value - min_value) * (viewport - min_viewport) / (max_viewport - min_viewport)
# Rewritten as: preferred = m * viewport + b
# where m = (max_val - min_val) / (max_vp - min_vp)
#       b = min_val - m * min_vp

generate_clamp() {
  local min_val="$1"
  local max_val="$2"

  local slope
  slope=$(awk "BEGIN { printf \"%.10f\", ($max_val - $min_val) / ($MAX_VIEWPORT - $MIN_VIEWPORT) }")

  local intercept
  intercept=$(awk "BEGIN { printf \"%.10f\", $min_val - $slope * $MIN_VIEWPORT }")

  # slope gives px/viewport-width. Convert to vw: same numeric value * 100
  local slope_vw
  slope_vw=$(awk "BEGIN { printf \"%.${PRECISION}f\", $slope * 100 }")

  local intercept_unit
  intercept_unit=$(to_unit "$intercept")

  local min_unit
  min_unit=$(to_unit "$min_val")

  local max_unit
  max_unit=$(to_unit "$max_val")

  # Clamp the intercept so the result never goes below min or above max
  # The clamp() function handles this natively
  echo "clamp(${min_unit}${UNIT}, ${slope_vw}vw + ${intercept_unit}${UNIT}, ${max_unit}${UNIT})"
}

CLAMP=$(generate_clamp "$MIN_VALUE" "$MAX_VALUE")
MIN_UNIT=$(to_unit "$MIN_VALUE")
MAX_UNIT=$(to_unit "$MAX_VALUE")

# Output
if $JSON_MODE; then
  awk "BEGIN { printf \"{\\\"clamp\\\":\\\"%s\\\",\\\"min\\\":\\\"%s\\\",\\\"max\\\":\\\"%s\\\"}\n\", \"$CLAMP\", \"${MIN_UNIT}${UNIT}\", \"${MAX_UNIT}${UNIT}\" }"
else
  if [[ -n "$PROPERTY" ]]; then
    echo "/* $PROPERTY: ${MIN_UNIT}${UNIT} → ${MAX_UNIT}${UNIT} (${MIN_VIEWPORT}px → ${MAX_VIEWPORT}px) */"
  fi

  if $RANGE; then
    echo "/* Range: ${MIN_UNIT}${UNIT} to ${MAX_UNIT}${UNIT} */"
  fi

  if [[ -n "$CSS_VAR" ]]; then
    echo "${PROPERTY:+$PROPERTY: }var($CSS_VAR, $CLAMP);"
  else
    echo "${PROPERTY:+$PROPERTY: }$CLAMP;"
  fi
fi

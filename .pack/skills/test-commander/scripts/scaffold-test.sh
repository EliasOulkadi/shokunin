#!/usr/bin/env bash
set -euo pipefail

# scaffold-test.sh — Generate test files for a component
# Usage: scaffold-test.sh <path> [framework]
#   path:       Path to component file or directory
#   framework:  vitest | jest (default: vitest)
#
# Examples:
#   scaffold-test.sh src/components/UserProfile.tsx
#   scaffold-test.sh src/lib/api.ts jest
#   scaffold-test.sh src/utils/format.ts vitest

# ── Parse args ──────────────────────────────────────────────────────────────
TARGET="${1:?Missing path to component}"
FRAMEWORK="${2:-vitest}"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPTS_DIR/../assets" && pwd)"

if [[ ! -f "$TARGET" && ! -d "$TARGET" ]]; then
  echo "Error: '$TARGET' not found" >&2
  exit 1
fi

# ── Determine target info ──────────────────────────────────────────────────
if [[ -f "$TARGET" ]]; then
  FILE_NAME="$(basename "$TARGET")"
  FILE_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
  NAME="${FILE_NAME%.*}"
  EXT="${FILE_NAME##*.}"
else
  FILE_DIR="$(cd "$TARGET" && pwd)"
  NAME="$(basename "$FILE_DIR")"
  EXT="tsx"
fi

# ── Determine test directory (__tests__ or sidecar) ────────────────────────
# Convention: sidecar *.test.ts next to source
# Override to __tests__/ if flag is set
TEST_DIR="$FILE_DIR"
SIDECAR=true

for arg in "$@"; do
  if [[ "$arg" == "--dir" ]]; then
    SIDECAR=false
    break
  fi
done

if [[ "$SIDECAR" == false ]]; then
  TEST_DIR="$FILE_DIR/__tests__"
  mkdir -p "$TEST_DIR"
fi

# ── Map extension to test template ─────────────────────────────────────────
declare -A TEST_TEMPLATES
TEST_TEMPLATES[tsx]="test-component-template.tsx"
TEST_TEMPLATES[ts]="test-api-template.ts"
TEST_TEMPLATES[js]="test-component-template.tsx"
TEST_TEMPLATES[jsx]="test-component-template.tsx"

TEMPLATE_FILE="${TEST_TEMPLATES[$EXT]:-test-component-template.tsx}"
TEMPLATE_PATH="$ASSETS_DIR/$TEMPLATE_FILE"

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "Warning: No template for .$EXT, falling back to component template" >&2
  TEMPLATE_PATH="$ASSETS_DIR/test-component-template.tsx"
fi

# ── Infer component category ──────────────────────────────────────────────
# Check for API-related keywords in filename or imports
is_api() {
  local name
  name="$(basename "${TARGET,,}")"
  [[ "$name" == *api* || "$name" == *hook* || "$name" == *service* ]]
}

# ── Generate test file ─────────────────────────────────────────────────────
generate_test() {
  local test_file
  local import_path
  local template

  if [[ "$SIDECAR" == true ]]; then
    test_file="$TEST_DIR/$NAME.test.$EXT"
  else
    test_file="$TEST_DIR/$NAME.test.$EXT"
  fi

  # Compute relative import path from test -> source
  if [[ -f "$TARGET" ]]; then
    import_path="$(realpath --relative-to="$TEST_DIR" "$TARGET")"
    import_path="${import_path%.*}"
    # Remove leading ../
    import_path="${import_path#../}"
  else
    import_path="./$NAME"
  fi

  template=$(<"$TEMPLATE_PATH")
  template="${template//{{componentName}}/$NAME}"
  template="${template//{{importPath}}/$import_path}"
  template="${template//{{framework}}/$FRAMEWORK}"

  # Capitalize first letter for component name
  COMPONENT_CAP="$(echo "${NAME:0:1}" | tr '[:lower:]' '[:upper:]')${NAME:1}"
  template="${template//{{ComponentName}}/$COMPONENT_CAP}"

  echo "$template" > "$test_file"
  echo "Created: $test_file"
}

# ── Generate complementary test files for barrel exports ──────────────────
generate_index_test() {
  local index_file="$FILE_DIR/index.test.ts"
  if [[ ! -f "$index_file" && -f "$FILE_DIR/index.ts" ]]; then
    cat > "$index_file" <<- 'EOF'
import { describe, it, expect } from 'vitest'

describe('barrel exports', () => {
  it('re-exports all public API', async () => {
    const mod = await import('./index')
    expect(Object.keys(mod).length).toBeGreaterThan(0)
    Object.values(mod).forEach((exp) => {
      expect(exp).toBeDefined()
    })
  })
})
EOF
    echo "Created: $index_file"
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────
generate_test

if [[ "$SIDECAR" == true && -f "$TARGET" ]]; then
  generate_index_test
fi

# ── Print runner hint ──────────────────────────────────────────────────────
case "$FRAMEWORK" in
  vitest) RUNNER="npx vitest run" ;;
  jest)   RUNNER="npx jest" ;;
  *)      RUNNER="npx vitest run" ;;
esac

echo "Done. Run: $RUNNER"

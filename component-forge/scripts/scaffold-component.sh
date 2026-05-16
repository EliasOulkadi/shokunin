#!/usr/bin/env bash
set -euo pipefail

# scaffold-component.sh — Generate a component directory with files
# Usage: ./scaffold-component.sh <ComponentName> <framework>
#   framework: react | vue | svelte

COMPONENT_NAME="${1:-}"
FRAMEWORK="${2:-}"

if [[ -z "$COMPONENT_NAME" ]]; then
  echo "Usage: $0 <ComponentName> <framework>"
  echo "  framework: react | vue | svelte"
  exit 1
fi

if [[ ! "$COMPONENT_NAME" =~ ^[A-Z] ]]; then
  echo "Error: ComponentName must start with uppercase letter (PascalCase)"
  exit 1
fi

case "$FRAMEWORK" in
  react|vue|svelte) ;;
  *)
    echo "Error: framework must be 'react', 'vue', or 'svelte'"
    exit 1
    ;;
esac

DIR="$COMPONENT_NAME"
mkdir -p "$DIR"

# ─── React component ──────────────────────────────────────────────
if [[ "$FRAMEWORK" == "react" ]]; then

  cat > "$DIR/$COMPONENT_NAME.types.ts" <<- TYPESEOF
export interface ${COMPONENT_NAME}Props {
  /** Child content */
  children?: React.ReactNode
  /** Additional CSS classes */
  className?: string
  /** Disabled state */
  disabled?: boolean
  /** Loading state */
  loading?: boolean
  /** Called when component is interacted with */
  onChange?: (value: string) => void
}
TYPESEOF

  cat > "$DIR/$COMPONENT_NAME.tsx" <<- COMPEOF
import { type ${COMPONENT_NAME}Props } from './$COMPONENT_NAME.types'

export function $COMPONENT_NAME({
  children,
  className = '',
  disabled = false,
  loading = false,
  onChange,
}: ${COMPONENT_NAME}Props) {
  return (
    <div
      className={className}
      aria-busy={loading}
      aria-disabled={disabled}
    >
      {loading ? <span>Loading...</span> : children}
    </div>
  )
}
COMPEOF

  cat > "$DIR/$COMPONENT_NAME.test.tsx" <<- TESTOF
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { $COMPONENT_NAME } from './$COMPONENT_NAME'

describe('$COMPONENT_NAME', () => {
  it('renders children', () => {
    render(<$COMPONENT_NAME>Hello</$COMPONENT_NAME>)
    expect(screen.getByText('Hello')).toBeInTheDocument()
  })

  it('shows loading state', () => {
    render(<$COMPONENT_NAME loading>Content</$COMPONENT_NAME>)
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })
})
TESTOF

  cat > "$DIR/index.ts" <<- INDEXEOF
export { $COMPONENT_NAME } from './$COMPONENT_NAME'
export type { ${COMPONENT_NAME}Props } from './$COMPONENT_NAME.types'
INDEXEOF

# ─── Vue component ────────────────────────────────────────────────
elif [[ "$FRAMEWORK" == "vue" ]]; then

  cat > "$DIR/$COMPONENT_NAME.vue" <<- VUEEOF
<script setup lang="ts">
export interface ${COMPONENT_NAME}Props {
  label?: string
  disabled?: boolean
  loading?: boolean
}

const props = withDefaults(defineProps<${COMPONENT_NAME}Props>(), {
  label: '',
  disabled: false,
  loading: false,
})

const emit = defineEmits<{
  change: [value: string]
}>()

function handleChange(value: string) {
  emit('change', value)
}
</script>

<template>
  <div
    :aria-busy="loading"
    :aria-disabled="disabled"
  >
    <span v-if="loading">Loading...</span>
    <slot v-else />
  </div>
</template>
VUEEOF

  cat > "$DIR/$COMPONENT_NAME.test.ts" <<- VUTEOF
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import $COMPONENT_NAME from './$COMPONENT_NAME.vue'

describe('$COMPONENT_NAME', () => {
  it('renders slot content', () => {
    const wrapper = mount($COMPONENT_NAME, {
      slots: { default: 'Hello' },
    })
    expect(wrapper.text()).toContain('Hello')
  })

  it('shows loading state', () => {
    const wrapper = mount($COMPONENT_NAME, {
      props: { loading: true },
    })
    expect(wrapper.text()).toContain('Loading...')
  })
})
VUTEOF

  cat > "$DIR/index.ts" <<- VUIEOF
export { default as $COMPONENT_NAME } from './$COMPONENT_NAME.vue'
export type { ${COMPONENT_NAME}Props } from './$COMPONENT_NAME.vue'
VUIEOF

# ─── Svelte component ─────────────────────────────────────────────
elif [[ "$FRAMEWORK" == "svelte" ]]; then

  cat > "$DIR/$COMPONENT_NAME.svelte" <<- SVEOF
<script lang="ts">
  import type { Snippet } from 'svelte'

  interface Props {
    children?: Snippet
    disabled?: boolean
    loading?: boolean
    onchange?: (value: string) => void
  }

  let {
    children,
    disabled = false,
    loading = false,
    onchange,
  }: Props = \$props()
</script>

<div aria-busy={loading} aria-disabled={disabled}>
  {#if loading}
    <span>Loading...</span>
  {:else}
    {@render children?.()}
  {/if}
</div>
SVEOF

  cat > "$DIR/$COMPONENT_NAME.test.ts" <<- SVTEOF
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/svelte'
import $COMPONENT_NAME from './$COMPONENT_NAME.svelte'

describe('$COMPONENT_NAME', () => {
  it('renders content', () => {
    render($COMPONENT_NAME, { props: { children: 'Hello' } })
    expect(screen.getByText('Hello')).toBeInTheDocument()
  })

  it('shows loading state', () => {
    render($COMPONENT_NAME, { props: { loading: true } })
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })
})
SVTEOF

  cat > "$DIR/index.ts" <<- SVIEOF
export { default as $COMPONENT_NAME } from './$COMPONENT_NAME.svelte'
SVIEOF

fi

echo "✓ Scaffolded $COMPONENT_NAME ($FRAMEWORK) in ./$DIR/"
ls -la "$DIR/"

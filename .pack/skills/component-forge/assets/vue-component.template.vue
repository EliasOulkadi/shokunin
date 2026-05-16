<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

// ─── Types ────────────────────────────────────────────────────────

type State<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: T }

// ─── Props & Emits ────────────────────────────────────────────────

const props = withDefaults(
  defineProps<{
    /** Accessible label for the component */
    ariaLabel?: string
    /** Additional CSS class */
    class?: string
    /** Async fetch function */
    fetchFn?: () => Promise<unknown[]>
    /** Custom empty message */
    emptyMessage?: string
    /** Auto-load on mount */
    immediate?: boolean
  }>(),
  {
    ariaLabel: '',
    class: '',
    emptyMessage: 'No items found.',
    immediate: false,
  }
)

const emit = defineEmits<{
  /** Emitted when an item is selected */
  select: [item: unknown]
  /** Emitted when loading starts */
  loading: []
  /** Emitted on error */
  error: [err: Error]
  /** Emitted on successful load */
  loaded: [data: unknown[]]
}>()

// ─── Slots ────────────────────────────────────────────────────────

defineSlots<{
  /** Custom loading indicator */
  loading?: (props: object) => unknown
  /** Custom empty state */
  empty?: (props: object) => unknown
  /** Custom error state with retry function */
  error?: (props: { error: Error; retry: () => void }) => unknown
  /** Default content once data is loaded */
  default?: (props: { items: unknown[] }) => unknown
}>()

// ─── State ────────────────────────────────────────────────────────

const state = ref<State<unknown[]>>({ status: 'idle' })
const selectedIndex = ref(-1)
const containerRef = ref<HTMLElement | null>(null)
let abortController: AbortController | null = null

// ─── Computed ─────────────────────────────────────────────────────

const isLoading = computed(() => state.value.status === 'loading')
const isEmpty = computed(() => state.value.status === 'empty')
const hasError = computed(() => state.value.status === 'error')
const items = computed(() =>
  state.value.status === 'success' ? state.value.data : []
)

const componentClasses = computed(() => {
  const base = 'async-component'
  return [base, props.class, `${base}--${state.value.status}`]
    .filter(Boolean)
    .join(' ')
})

// ─── Methods ──────────────────────────────────────────────────────

async function load(): Promise<void> {
  if (!props.fetchFn) return

  abortController?.abort()
  abortController = new AbortController()
  const signal = abortController.signal

  state.value = { status: 'loading' }
  emit('loading')

  try {
    const data = await props.fetchFn()

    if (signal.aborted) return

    if (!data || data.length === 0) {
      state.value = { status: 'empty' }
    } else {
      state.value = { status: 'success', data }
      emit('loaded', data)
    }
  } catch (err) {
    if (signal.aborted) return
    const error = err instanceof Error ? err : new Error(String(err))
    state.value = { status: 'error', error }
    emit('error', error)
  }
}

function retry(): void {
  state.value = { status: 'idle' }
}

function selectItem(item: unknown): void {
  selectedIndex.value = items.value.indexOf(item)
  emit('select', item)
}

// ─── Keyboard Navigation (Roving Tabindex) ────────────────────────

function handleKeyDown(event: KeyboardEvent): void {
  const list = items.value
  if (list.length === 0) return

  let nextIndex = selectedIndex.value

  switch (event.key) {
    case 'ArrowDown':
    case 'ArrowRight':
      event.preventDefault()
      nextIndex = (selectedIndex.value + 1) % list.length
      break
    case 'ArrowUp':
    case 'ArrowLeft':
      event.preventDefault()
      nextIndex = (selectedIndex.value - 1 + list.length) % list.length
      break
    case 'Home':
      event.preventDefault()
      nextIndex = 0
      break
    case 'End':
      event.preventDefault()
      nextIndex = list.length - 1
      break
    case 'Enter':
    case ' ':
      event.preventDefault()
      if (selectedIndex.value >= 0) {
        selectItem(list[selectedIndex.value])
      }
      return
    default:
      return
  }

  selectedIndex.value = nextIndex
  focusItem(nextIndex)
}

function focusItem(index: number): void {
  const items_elements = containerRef.value?.querySelectorAll<HTMLElement>(
    '[role="option"]'
  )
  if (items_elements && items_elements[index]) {
    items_elements[index].focus()
  }
}

// ─── Lifecycle ────────────────────────────────────────────────────

watch(
  () => props.immediate,
  (val) => {
    if (val) load()
  },
  { immediate: true }
)

onMounted(() => {
  if (props.immediate) load()
})

onUnmounted(() => {
  abortController?.abort()
})
</script>

<template>
  <div
    :class="componentClasses"
    :aria-label="ariaLabel || undefined"
    :aria-busy="isLoading"
  >
    <!-- Loading -->
    <div
      v-if="isLoading"
      role="status"
      aria-live="polite"
      class="async-component__loading"
    >
      <slot name="loading">
        <span class="async-component__spinner" aria-hidden="true" />
        <span class="async-component__sr-only">Loading content...</span>
      </slot>
    </div>

    <!-- Empty -->
    <div
      v-else-if="isEmpty"
      role="status"
      class="async-component__empty"
    >
      <slot name="empty">
        <p>{{ emptyMessage }}</p>
      </slot>
    </div>

    <!-- Error -->
    <div
      v-else-if="hasError"
      role="alert"
      class="async-component__error"
    >
      <slot
        name="error"
        :error="(state as { status: 'error'; error: Error }).error"
        :retry="retry"
      >
        <p>{{ (state as { status: 'error'; error: Error }).error.message }}</p>
        <button
          type="button"
          :aria-label="'Retry: ' + ariaLabel"
          @click="retry"
        >
          Try again
        </button>
      </slot>
    </div>

    <!-- Success -->
    <div
      v-else-if="state.status === 'success'"
      ref="containerRef"
      role="listbox"
      :aria-label="ariaLabel || 'Results'"
      class="async-component__list"
      @keydown="handleKeyDown"
    >
      <slot :items="items">
        <div
          v-for="(item, index) in items"
          :key="index"
          role="option"
          tabindex="0"
          :aria-selected="index === selectedIndex"
          :aria-posinset="index + 1"
          :aria-setsize="items.length"
          class="async-component__item"
          @click="selectItem(item)"
        >
          {{ item }}
        </div>
      </slot>
    </div>
  </div>
</template>

<style scoped>
.async-component__spinner {
  display: inline-block;
  width: 1.25rem;
  height: 1.25rem;
  border: 2px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: async-spin 0.6s linear infinite;
}

.async-component__sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
}

@keyframes async-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>

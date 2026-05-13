'use client'

import {
  useState,
  useEffect,
  useCallback,
  useRef,
  forwardRef,
  type ReactNode,
  type KeyboardEvent,
  type FocusEvent,
} from 'react'

// ─── Types ────────────────────────────────────────────────────────

export type DataState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: T }

export interface AsyncComponentProps<T> {
  /** Accessible label for the component */
  'aria-label'?: string
  /** Additional CSS classes */
  className?: string
  /** Function to fetch or load data */
  fetchFn?: () => Promise<T[]>
  /** Custom empty state message */
  emptyMessage?: string
  /** Called when an item is selected */
  onSelect?: (item: T) => void
  /** Children renderer once data is loaded */
  children?: (items: T[]) => ReactNode
}

export interface AsyncComponentHandle {
  /** Programmatically trigger a reload */
  reload: () => void
  /** Current state */
  state: DataState<unknown>
}

// ─── Constants ────────────────────────────────────────────────────

const DEFAULT_EMPTY_MESSAGE = 'No items found.'
const LOADING_DELAY_MS = 300

// ─── Component ────────────────────────────────────────────────────

function AsyncComponentInner<T>(
  {
    'aria-label': ariaLabel,
    className = '',
    fetchFn,
    emptyMessage = DEFAULT_EMPTY_MESSAGE,
    onSelect,
    children,
  }: AsyncComponentProps<T>,
  ref: React.Ref<AsyncComponentHandle>
) {
  const [state, setState] = useState<DataState<T[]>>({ status: 'idle' })
  const mountedRef = useRef(true)
  const abortRef = useRef<AbortController | null>(null)

  const load = useCallback(async () => {
    if (!fetchFn) return

    abortRef.current?.abort()
    abortRef.current = new AbortController()
    const signal = abortRef.current.signal

    setState({ status: 'loading' })

    try {
      const data = await fetchFn()

      if (signal.aborted) return

      if (!data || data.length === 0) {
        setState({ status: 'empty' })
      } else {
        setState({ status: 'success', data })
      }
    } catch (err) {
      if (signal.aborted) return
      const error = err instanceof Error ? err : new Error(String(err))
      setState({ status: 'error', error })
    }
  }, [fetchFn])

  useEffect(() => {
    if (state.status === 'idle') {
      const timer = setTimeout(() => load(), LOADING_DELAY_MS)
      return () => {
        clearTimeout(timer)
        abortRef.current?.abort()
      }
    }
  }, [state.status, load])

  useEffect(() => {
    return () => {
      mountedRef.current = false
      abortRef.current?.abort()
    }
  }, [])

  // Forward imperative handle
  const handleReload = useCallback(() => {
    setState({ status: 'idle' })
  }, [])

  useImperativeHandle(
    ref,
    () => ({
      reload: handleReload,
      get state() {
        return state as DataState<unknown>
      },
    }),
    [handleReload, state]
  )

  // ─── Keyboard handlers ─────────────────────────────────────────

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLDivElement>, item: T) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        onSelect?.(item)
      }
    },
    [onSelect]
  )

  // ─── Render by state ───────────────────────────────────────────

  const renderContent = (): ReactNode => {
    switch (state.status) {
      case 'idle':
      case 'loading': {
        return (
          <div
            role="status"
            aria-live="polite"
            aria-busy="true"
            className="async-component__loading"
          >
            <span className="async-component__spinner" aria-hidden="true" />
            <span className="async-component__sr-only">Loading content...</span>
          </div>
        )
      }

      case 'empty': {
        return (
          <div
            role="status"
            className="async-component__empty"
          >
            <p>{emptyMessage}</p>
          </div>
        )
      }

      case 'error': {
        return (
          <div
            role="alert"
            className="async-component__error"
          >
            <p>{state.error.message}</p>
            <button
              type="button"
              onClick={handleReload}
              aria-label="Retry loading content"
            >
              Try again
            </button>
          </div>
        )
      }

      case 'success': {
        return (
          <div
            role="listbox"
            aria-label={ariaLabel ?? 'Results'}
            className="async-component__list"
          >
            {children?.(state.data) ??
              state.data.map((item, index) => (
                <div
                  key={index}
                  role="option"
                  tabIndex={0}
                  aria-selected={false}
                  className="async-component__item"
                  onClick={() => onSelect?.(item)}
                  onKeyDown={(e) => handleKeyDown(e, item)}
                >
                  {String(item)}
                </div>
              ))}
          </div>
        )
      }
    }
  }

  return (
    <div
      className={`async-component ${className}`.trim()}
      aria-label={ariaLabel}
    >
      {renderContent()}
    </div>
  )
}

const AsyncComponent = forwardRef(AsyncComponentInner) as <T>(
  props: AsyncComponentProps<T> & { ref?: React.Ref<AsyncComponentHandle> }
) => React.ReactElement

AsyncComponent.displayName = 'AsyncComponent'

export { AsyncComponent }

// ─── Error Boundary (companion component) ────────────────────────

interface ErrorBoundaryProps {
  children: ReactNode
  fallback?: ReactNode
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void
}

interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

export class ComponentErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    this.props.onError?.(error, errorInfo)
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null })
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback
      return (
        <div role="alert" className="async-component__error-boundary">
          <p>Something went wrong while rendering this component.</p>
          <button type="button" onClick={this.handleReset}>
            Reset
          </button>
        </div>
      )
    }
    return this.props.children
  }
}

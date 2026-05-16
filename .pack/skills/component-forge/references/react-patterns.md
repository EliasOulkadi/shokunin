# Advanced React Component Patterns

## Compound Components with Context

Share state implicitly between parent and children via React Context.

```tsx
import { createContext, useContext, useState, type ReactNode } from 'react'

interface AccordionContextValue {
  openIndex: number | null
  setOpenIndex: (index: number | null) => void
}

const AccordionContext = createContext<AccordionContextValue | null>(null)

function useAccordionContext() {
  const ctx = useContext(AccordionContext)
  if (!ctx) throw new Error('Accordion.* components must be used within <Accordion>')
  return ctx
}

// ─── Parent ──────────────────────────────────────────────────────
function Accordion({ children }: { children: ReactNode }) {
  const [openIndex, setOpenIndex] = useState<number | null>(null)
  return (
    <AccordionContext.Provider value={{ openIndex, setOpenIndex }}>
      <div role="region">{children}</div>
    </AccordionContext.Provider>
  )
}

// ─── Children ─────────────────────────────────────────────────────
Accordion.Item = function Item({ index, children }: { index: number; children: ReactNode }) {
  const { openIndex, setOpenIndex } = useAccordionContext()
  const isOpen = openIndex === index
  return (
    <div>
      <button
        aria-expanded={isOpen}
        onClick={() => setOpenIndex(isOpen ? null : index)}
      >
        {children}
      </button>
    </div>
  )
}

Accordion.Panel = function Panel({ index, children }: { index: number; children: ReactNode }) {
  const { openIndex } = useAccordionContext()
  if (openIndex !== index) return null
  return <div role="region">{children}</div>
}

// Usage:
// <Accordion>
//   <Accordion.Item index={0}>Trigger</Accordion.Item>
//   <Accordion.Panel index={0}>Content</Accordion.Panel>
// </Accordion>
```

### When to use compound components

| Use case | Example |
|----------|---------|
| Parent needs to coordinate children state | Accordion, Tabs, RadioGroup |
| Children are optional or reorderable | Menu (Menu.Item, Menu.Divider) |
| User composes the markup, not a config object | DataTable.Column |

## Render Props vs Hooks

Both extract reusable behavior. Hooks are preferred unless you need the rendering to be controlled externally.

```tsx
// ─── Render prop pattern ─────────────────────────────────────────
function MouseTracker({
  render,
}: {
  render: (position: { x: number; y: number }) => ReactNode
}) {
  const [position, setPosition] = useState({ x: 0, y: 0 })

  useEffect(() => {
    const handler = (e: MouseEvent) => setPosition({ x: e.clientX, y: e.clientY })
    addEventListener('mousemove', handler)
    return () => removeEventListener('mousemove', handler)
  }, [])

  return render(position)
}

// Usage:
// <MouseTracker render={({ x, y }) => <span>{x}, {y}</span>} />

// ─── Equivalent hook pattern (preferred) ─────────────────────────
function useMousePosition() {
  const [position, setPosition] = useState({ x: 0, y: 0 })

  useEffect(() => {
    const handler = (e: MouseEvent) => setPosition({ x: e.clientX, y: e.clientY })
    addEventListener('mousemove', handler)
    return () => removeEventListener('mousemove', handler)
  }, [])

  return position
}

// Usage:
// const { x, y } = useMousePosition()
```

| Pattern | Good for | Avoid when |
|---------|----------|------------|
| Render prop | Dynamic rendering controlled by parent | The behavior is always the same |
| Hook | Reusing behavior logic | The render tree depends on context from the provider |

## Server Components vs Client Components

```tsx
// ProductList.server.tsx — runs on the server, zero JS sent to client
async function ProductList({ category }: { category: string }) {
  const products = await db.product.findMany({ where: { category } })

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>
          <span>{p.name}</span>
          <AddToCart productId={p.id} />
        </li>
      ))}
    </ul>
  )
}

// AddToCart.client.tsx — interactive leaf, minimal JS boundary
'use client'

function AddToCart({ productId }: { productId: string }) {
  const [added, setAdded] = useState(false)

  return (
    <button
      aria-label={`Add product ${productId} to cart`}
      onClick={() => {
        setAdded(true)
        addToCart(productId)
      }}
    >
      {added ? '✓ Added' : 'Add to Cart'}
    </button>
  )
}
```

### Rules of thumb

- **Server by default** — components that don't need state, effects, or browser APIs stay on the server
- **Push 'use client' to the leaves** — only interactive wrappers need the client boundary
- **Server components can pass props to client components** — serializable data only (no functions, no Date)
- **Server Components can fetch directly** — no useEffect, no SWR/React Query needed for initial data

### What can't cross the server/client boundary

| Can cross | Cannot cross |
|-----------|-------------|
| Strings, numbers, booleans | Functions, class instances |
| Plain objects and arrays | Map, Set, Date (without serialization) |
| React elements (RSC payload) | Promises |
| `ReactNode` (serialized) | Component references |

## Error Boundaries

Class components that catch rendering errors and show a fallback UI. Server Components render errors via `error.tsx`.

```tsx
'use client'

import { Component, type ErrorInfo, type ReactNode } from 'react'

interface ErrorBoundaryProps {
  children: ReactNode
  fallback?: ReactNode | ((error: Error, reset: () => void) => ReactNode)
  onError?: (error: Error, info: ErrorInfo) => void
}

interface ErrorBoundaryState {
  error: Error | null
}

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { error: null }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    this.props.onError?.(error, info)
  }

  handleReset = () => {
    this.setState({ error: null })
  }

  render() {
    if (this.state.error) {
      if (typeof this.props.fallback === 'function') {
        return this.props.fallback(this.state.error, this.handleReset)
      }
      return this.props.fallback ?? <div>Something went wrong.</div>
    }
    return this.props.children
  }
}
```

### Next.js App Router error handling

| File | What it catches |
|------|----------------|
| `error.tsx` | Client component errors in that segment |
| `global-error.tsx` | Errors in the root layout itself |
| `not-found.tsx` | `notFound()` calls + 404s |

## Suspense Boundaries

Wrap data-fetching or lazy-loaded components to show fallback UI while they resolve.

```tsx
import { Suspense, lazy } from 'react'

const HeavyChart = lazy(() => import('./HeavyChart'))

function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Lazy loading */}
      <Suspense fallback={<ChartSkeleton />}>
        <HeavyChart />
      </Suspense>

      {/* Streaming SSR */}
      <Suspense fallback={<p>Loading comments...</p>}>
        <CommentList />
      </Suspense>
    </div>
  )
}
```

### Suspense patterns

```tsx
// Nested Suspense — each boundary is independent
function Page() {
  return (
    <Suspense fallback={<PageSkeleton />}>
      <Header />
      <Suspense fallback={<SidebarSkeleton />}>
        <Sidebar />
      </Suspense>
      <Suspense fallback={<MainSkeleton />}>
        <MainContent />
      </Suspense>
    </Suspense>
  )
}

// Sequential waterfalls — avoid deeply nesting
function Bad() {
  return (
    <Suspense fallback={<A />}>
      <ComponentA />
      <Suspense fallback={<B />}>
        <ComponentB />
        {/* B won't render until A resolves */}
      </Suspense>
    </Suspense>
  )
}
```

## Controlled vs Uncontrolled Components

```tsx
'use client'

import { useState, useRef, type ChangeEvent } from 'react'

// ─── Uncontrolled — state lives in the DOM ───────────────────────
function UncontrolledInput({ defaultValue = '' }: { defaultValue?: string }) {
  const ref = useRef<HTMLInputElement>(null)

  function handleSubmit() {
    console.log(ref.current?.value)
  }

  return <input ref={ref} type="text" defaultValue={defaultValue} />
}

// ─── Controlled — state lives in React ────────────────────────────
function ControlledInput({ value, onChange }: {
  value: string
  onChange: (value: string) => void
}) {
  return (
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  )
}

// ─── Hybrid — uncontrolled by default, controlled when value is passed
function Input({
  value: controlledValue,
  defaultValue = '',
  onChange,
}: {
  value?: string
  defaultValue?: string
  onChange?: (value: string) => void
}) {
  const isControlled = controlledValue !== undefined
  const [internalValue, setInternalValue] = useState(defaultValue)

  const value = isControlled ? controlledValue : internalValue

  function handleChange(e: ChangeEvent<HTMLInputElement>) {
    if (!isControlled) setInternalValue(e.target.value)
    onChange?.(e.target.value)
  }

  return <input type="text" value={value} onChange={handleChange} />
}
```

| Approach | When to use |
|----------|-------------|
| Uncontrolled | Simple forms, library inputs (e.g. react-select) |
| Controlled | Real-time validation, conditional rendering based on value |
| Hybrid | Reusable components that work in both modes |

## Forwarding Refs

Use `forwardRef` when a component needs to expose its DOM node to parent refs.

```tsx
'use client'

import { forwardRef, type ComponentPropsWithRef } from 'react'

type ButtonProps = ComponentPropsWithRef<'button'> & {
  variant?: 'primary' | 'secondary'
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  function Button({ variant = 'primary', className = '', ...props }, ref) {
    return (
      <button
        ref={ref}
        className={`btn btn--${variant} ${className}`}
        {...props}
      />
    )
  }
)
```

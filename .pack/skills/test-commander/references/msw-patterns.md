# MSW Patterns

Advanced Mock Service Worker (MSW) v2+ patterns for integration testing and prototyping.

---

## Setup

### Basic server (Node)

```ts
import { setupServer } from 'msw/node'

export const server = setupServer()

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Browser worker (dev / Storybook)

```ts
import { setupWorker } from 'msw/browser'

export const worker = setupWorker()

// main.tsx
async function enableMocking() {
  if (import.meta.env.DEV) {
    const { worker } = await import('./mocks/browser')
    return worker.start({ onUnhandledRequest: 'bypass' })
  }
}
await enableMocking()
```

### Strict vs permissive mode

| Mode | Behavior | Use case |
|------|----------|----------|
| `'error'` | Throws on unhandled | CI / strict test suite |
| `'warn'` | Console warning | Local dev / lenient env |
| `'bypass'` | Passes through to real network | Storybook / partial mocking |

---

## Handler Patterns

### Standard REST handlers

```ts
import { http, HttpResponse } from 'msw'

// GET with query params
http.get('/api/users', ({ request }) => {
  const url = new URL(request.url)
  const page = Number(url.searchParams.get('page')) || 1
  const search = url.searchParams.get('q') || ''

  return HttpResponse.json({
    data: filteredUsers,
    meta: { page, total: filteredUsers.length },
  })
})

// POST with body
http.post('/api/users', async ({ request }) => {
  const body = await request.json()
  return HttpResponse.json({ data: { id: crypto.randomUUID(), ...body } }, { status: 201 })
})

// URL params
http.get('/api/users/:id', ({ params }) => {
  return HttpResponse.json({ data: { id: params.id, name: 'Alice' } })
})
```

### Response variations

```ts
// Empty response
http.get('/api/users', () => HttpResponse.json({ data: [] }))

// No content
http.delete('/api/users/:id', () => new HttpResponse(null, { status: 204 }))

// Binary / blob
http.get('/api/avatar/:id', () => {
  const image = fs.readFileSync('test/fixtures/avatar.png')
  return new HttpResponse(image, {
    headers: { 'Content-Type': 'image/png' },
  })
})

// Stream (SSE)
http.get('/api/events', ({ request }) => {
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(new TextEncoder().encode('data: {"type":"ping"}\n\n'))
      const interval = setInterval(() => {
        controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify({ type: 'update' })}\n\n`))
      }, 1000)
      request.signal.addEventListener('abort', () => clearInterval(interval))
    },
  })
  return new HttpResponse(stream, {
    headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' },
  })
})
```

---

## Error Simulation

```ts
// Network error (DNS / connection failure)
http.get('/api/fragile', () => HttpResponse.error())

// HTTP errors
http.get('/api/users/:id', ({ params }) => {
  const errors: Record<string, [number, string]> = {
    '400': [400, 'Bad Request'],
    '401': [401, 'Unauthorized'],
    '403': [403, 'Forbidden'],
    '404': [404, 'Not Found'],
    '409': [409, 'Conflict'],
    '422': [422, 'Unprocessable Entity'],
    '429': [429, 'Too Many Requests'],
    '500': [500, 'Internal Server Error'],
    '502': [502, 'Bad Gateway'],
    '503': [503, 'Service Unavailable'],
  }

  const errCode = params.id as keyof typeof errors
  if (errors[errCode]) {
    const [status, message] = errors[errCode]
    return HttpResponse.json({ error: message, code: errCode }, { status })
  }
  return HttpResponse.json({ data: { id: params.id, name: 'Alice' } })
})

// Conditional error — flaky endpoint
http.get('/api/flaky', () => {
  if (Math.random() < 0.3) {
    return HttpResponse.json({ error: 'Temporary failure' }, { status: 502 })
  }
  return HttpResponse.json({ data: 'ok' })
})

// Validation error payload
http.post('/api/users', async ({ request }) => {
  const body = await request.json() as Record<string, unknown>

  const errors: Record<string, string[]> = {}
  if (!body.email) errors.email = ['Email is required']
  if (!body.name) errors.name = ['Name is required']
  if (body.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email as string)) {
    errors.email = ['Invalid email format']
  }

  if (Object.keys(errors).length) {
    return HttpResponse.json({ errors, message: 'Validation failed' }, { status: 422 })
  }
  return HttpResponse.json({ data: { id: crypto.randomUUID(), ...body } }, { status: 201 })
})
```

---

## Network Delay

```ts
import { delay } from 'msw'

// Fixed delay
http.get('/api/slow', async () => {
  await delay(2000)
  return HttpResponse.json({ data: 'eventually' })
})

// Random realistic delay (100–500ms)
http.get('/api/realistic', async () => {
  await delay({ min: 100, max: 500 })
  return HttpResponse.json({ data: 'realistic timing' })
})

// Per-test override pattern
const withDelay = <T>(ms: number, resolver: () => T) => async () => {
  await delay(ms)
  return resolver()
}

export function simulateLatency(ms = 1000) {
  server.use(
    http.get('/api/users', withDelay(ms, () => HttpResponse.json({ data: [] })))
  )
}

// Usage in test:
it('shows loading spinner during slow response', async () => {
  simulateLatency(3000)
  render(<UserList />)
  expect(screen.getByRole('status')).toBeInTheDocument()
})

// Timeout simulation
http.get('/api/timeout', async () => {
  await delay(30_000) // never resolves within test timeout
  return HttpResponse.json({ data: 'too late' })
})
```

---

## Pagination

```ts
const allData = Array.from({ length: 87 }, (_, i) => ({
  id: `item_${i + 1}`,
  title: `Item ${i + 1}`,
}))

http.get('/api/items', ({ request }) => {
  const url = new URL(request.url)
  const page = Math.max(1, Number(url.searchParams.get('page')) || 1)
  const pageSize = Math.min(100, Number(url.searchParams.get('pageSize')) || 10)
  const sort = url.searchParams.get('sort') || 'title:asc'

  let result = [...allData]

  // Sort
  const [field, dir] = sort.split(':')
  result.sort((a, b) => {
    const cmp = a[field as keyof typeof a].localeCompare(b[field as keyof typeof b])
    return dir === 'desc' ? -cmp : cmp
  })

  // Paginate
  const start = (page - 1) * pageSize
  const paginated = result.slice(start, start + pageSize)

  return HttpResponse.json({
    data: paginated,
    meta: {
      page,
      pageSize,
      total: result.length,
      totalPages: Math.ceil(result.length / pageSize),
      hasNext: start + pageSize < result.length,
      hasPrev: page > 1,
    },
  })
})

// Cursor-based pagination
http.get('/api/items/cursor', ({ request }) => {
  const url = new URL(request.url)
  const cursor = url.searchParams.get('cursor')
  const limit = Number(url.searchParams.get('limit')) || 10

  const startIndex = cursor ? allData.findIndex(i => i.id === cursor) + 1 : 0
  const page = allData.slice(startIndex, startIndex + limit)
  const nextCursor = page.length === limit ? page[page.length - 1].id : null

  return HttpResponse.json({
    data: page,
    nextCursor,
  })
})

// Infinite scroll / load-more
it('loads more items on scroll', async () => {
  render(<InfiniteList />)

  const items = await screen.findAllByRole('listitem')
  expect(items).toHaveLength(10)

  await userEvent.click(screen.getByText(/load more/i))

  await waitFor(() => {
    expect(screen.getAllByRole('listitem')).toHaveLength(20)
  })
})
```

---

## GraphQL

```ts
import { graphql, HttpResponse } from 'msw'

// Typed response
export const handlers = [
  graphql.query('GetUser', ({ variables }) => {
    const { id } = variables as { id: string }

    return HttpResponse.json({
      data: {
        user: {
          __typename: 'User',
          id,
          name: 'Alice',
          email: 'alice@example.com',
          posts: [
            { __typename: 'Post', id: 'post_1', title: 'Hello World' },
          ],
        },
      },
    })
  }),

  graphql.mutation('UpdateUser', async ({ variables }) => {
    const { id, name } = variables as { id: string; name: string }
    return HttpResponse.json({
      data: {
        updateUser: {
          __typename: 'User',
          id,
          name,
          email: 'updated@example.com',
        },
      },
    })
  }),
]

// GraphQL error
graphql.query('GetUser', () =>
  HttpResponse.json({
    errors: [
      { message: 'User not found', extensions: { code: 'NOT_FOUND' } },
    ],
  })
)

// GraphQL with real data
export const gqlServer = setupServer(...handlers)
```

---

## Conditional Logic

### Request authentication

```ts
function getAuthUser(request: Request): { id: string; role: string } | null {
  const token = request.headers.get('Authorization')?.replace('Bearer ', '')
  if (!token) return null

  // Simulate token verification
  const tokens: Record<string, { id: string; role: string }> = {
    'admin-token': { id: 'user_admin', role: 'admin' },
    'user-token': { id: 'user_1', role: 'user' },
  }
  return tokens[token] ?? null
}

http.get('/api/admin', ({ request }) => {
  const user = getAuthUser(request)
  if (!user) return HttpResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (user.role !== 'admin') return HttpResponse.json({ error: 'Forbidden' }, { status: 403 })

  return HttpResponse.json({ data: { secret: 'admin-only data' } })
})
```

### Per-test overrides

```ts
// Helper to temporarily override a handler
function mockResponse(
  method: 'get' | 'post' | 'put' | 'patch' | 'delete',
  path: string,
  resolver: Parameters<typeof http.get>[1]
) {
  const methodMap = { get: http.get, post: http.post, put: http.put, patch: http.patch, delete: http.delete }
  server.use(methodMap[method](path, resolver))
}

it('handles 500 error', async () => {
  mockResponse('get', '/api/users', () =>
    HttpResponse.json({ error: 'Server error' }, { status: 500 })
  )

  render(<UserList />)
  await waitFor(() => {
    expect(screen.getByRole('alert')).toHaveTextContent(/server error/i)
  })
})
```

### Stateful handler (counter)

```ts
// Handler that tracks state across invocations
const requestCount = new Map<string, number>()

http.get('/api/users/:id', ({ params }) => {
  const id = params.id as string
  const count = (requestCount.get(id) ?? 0) + 1
  requestCount.set(id, count)

  if (count <= 2) {
    return HttpResponse.json({ error: 'Not ready' }, { status: 202 })
  }
  return HttpResponse.json({ data: { id, name: 'Ready after retry' } })
})

afterEach(() => requestCount.clear())
```

---

## Lifecycle & Lifecycle Events

```ts
// Lifecycle listeners
server.events.on('request:start', ({ request }) => {
  console.log(`[MSW] → ${request.method} ${request.url}`)
})

server.events.on('response:mocked', ({ response }) => {
  console.log(`[MSW] ← ${response.status}`)
})

server.events.on('request:unhandled', ({ request }) => {
  console.warn(`[MSW] Unhandled: ${request.method} ${request.url}`)
})
```

---

## Bypassing MSW

```ts
// Skip MSW for specific requests (e.g. CDN assets)
worker.start({
  onUnhandledRequest(request) {
    if (request.url.includes('cdn.example.com')) return
    console.warn(`Unhandled: ${request.url}`)
  },
})

// Passthrough to real endpoint (Node only)
http.get('https://real-api.com/health', () => {
  // Return undefined = passthrough to real network
  return
})
```

---

## File Structure

```
src/mocks/
├── browser.ts          # setupWorker
├── server.ts           # setupServer
├── handlers/
│   ├── index.ts        # merge all handlers
│   ├── users.ts
│   ├── posts.ts
│   └── errors.ts       # error-simulation handlers
├── fixtures/
│   ├── users.ts        # realistic data factories
│   └── posts.ts
└── test-utils.ts       # server setup, mockResponse helper, etc.
```

---

## Sources

- [MSW Docs](https://mswjs.io/docs/)
- [MSW v2 Migration Guide](https://mswjs.io/docs/migrations/1.x-to-2.x)

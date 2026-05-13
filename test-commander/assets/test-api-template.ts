import { describe, it, expect, vi, beforeAll, afterEach, afterAll } from '{{framework}}'
import { http, HttpResponse, delay } from 'msw'
import { setupServer } from 'msw/node'
import { faker } from '@faker-js/faker'

import { api } from '{{importPath}}'

// ── Types ───────────────────────────────────────────────────────────────────

interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'user'
  createdAt: string
}

interface ApiResponse<T> {
  data: T
  meta?: {
    total: number
    page: number
    pageSize: number
    totalPages: number
  }
  error?: string
}

// ── Fixtures ────────────────────────────────────────────────────────────────

const buildUser = (overrides: Partial<User> = {}): User => ({
  id: `user_${faker.string.uuid()}`,
  email: faker.internet.email(),
  name: faker.person.fullName(),
  role: 'user',
  createdAt: faker.date.recent().toISOString(),
  ...overrides,
})

// ── Server setup ───────────────────────────────────────────────────────────

const BASE_URL = 'https://api.example.com/v1'

const handlers = [
  // GET list
  http.get(`${BASE_URL}/users`, async ({ request }) => {
    const url = new URL(request.url)
    const page = Number(url.searchParams.get('page')) || 1
    const pageSize = Number(url.searchParams.get('pageSize')) || 10
    const allUsers = Array.from({ length: 50 }, () => buildUser())

    return HttpResponse.json<ApiResponse<User[]>>({
      data: allUsers.slice((page - 1) * pageSize, page * pageSize),
      meta: { total: 50, page, pageSize, totalPages: Math.ceil(50 / pageSize) },
    })
  }),

  // GET single
  http.get(`${BASE_URL}/users/:id`, async ({ params }) => {
    return HttpResponse.json<ApiResponse<User>>({
      data: buildUser({ id: params.id as string }),
    })
  }),

  // POST create
  http.post(`${BASE_URL}/users`, async ({ request }) => {
    const body = (await request.json()) as Partial<User>
    return HttpResponse.json<ApiResponse<User>>(
      { data: buildUser({ ...body, id: `user_${faker.string.uuid()}` }) },
      { status: 201 }
    )
  }),

  // PUT update
  http.put(`${BASE_URL}/users/:id`, async ({ params, request }) => {
    const body = (await request.json()) as Partial<User>
    return HttpResponse.json<ApiResponse<User>>({
      data: buildUser({ ...body, id: params.id as string }),
    })
  }),

  // DELETE
  http.delete(`${BASE_URL}/users/:id`, () => {
    return new HttpResponse(null, { status: 204 })
  }),
]

const server = setupServer(...handlers)

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

// ── Helpers ─────────────────────────────────────────────────────────────────

const overrideHandler = (
  method: 'get' | 'post' | 'put' | 'patch' | 'delete',
  path: string,
  resolver: Parameters<typeof http.get>[1]
) => {
  const methodMap = { get: http.get, post: http.post, put: http.put, patch: http.patch, delete: http.delete }
  server.use(methodMap[method](path, resolver))
}

// ── CRUD: Read ──────────────────────────────────────────────────────────────

describe('GET /users', () => {
  it('fetches a paginated list of users', async () => {
    const response = await api.getUsers({ page: 1, pageSize: 5 })

    expect(response.data).toHaveLength(5)
    expect(response.meta?.total).toBe(50)
    expect(response.meta?.page).toBe(1)
  })

  it('returns different results for different pages', async () => {
    const page1 = await api.getUsers({ page: 1, pageSize: 2 })
    const page2 = await api.getUsers({ page: 2, pageSize: 2 })

    expect(page1.data[0].id).not.toBe(page2.data[0].id)
  })

  it('returns an empty array for an out-of-range page', async () => {
    const response = await api.getUsers({ page: 100, pageSize: 10 })

    expect(response.data).toHaveLength(0)
  })

  it('sends correct query parameters', async () => {
    const spy = vi.fn()
    overrideHandler('get', `${BASE_URL}/users`, ({ request }) => {
      spy(request.url)
      return HttpResponse.json({ data: [] })
    })

    await api.getUsers({ page: 2, pageSize: 20, sort: 'name:asc' })

    expect(spy).toHaveBeenCalledWith(expect.stringContaining('page=2'))
    expect(spy).toHaveBeenCalledWith(expect.stringContaining('pageSize=20'))
    expect(spy).toHaveBeenCalledWith(expect.stringContaining('sort=name%3Aasc'))
  })
})

describe('GET /users/:id', () => {
  it('fetches a single user by ID', async () => {
    const user = await api.getUser('user_abc123')

    expect(user.id).toBe('user_abc123')
    expect(user.email).toBeDefined()
  })

  it('throws on non-existent user', async () => {
    overrideHandler('get', `${BASE_URL}/users/:id`, () =>
      HttpResponse.json({ error: 'Not found' }, { status: 404 })
    )

    await expect(api.getUser('user_nonexistent')).rejects.toThrow()
  })
})

// ── CRUD: Create ────────────────────────────────────────────────────────────

describe('POST /users', () => {
  it('creates a new user', async () => {
    const input = { email: 'new@example.com', name: 'New User' }
    const user = await api.createUser(input)

    expect(user.id).toMatch(/^user_/)
    expect(user.email).toBe('new@example.com')
    expect(user.name).toBe('New User')
  })

  it('rejects invalid payload with validation error', async () => {
    overrideHandler('post', `${BASE_URL}/users`, async ({ request }) => {
      const body = await request.json()
      if (!body || !(body as Record<string, unknown>).email) {
        return HttpResponse.json({ error: 'Email is required' }, { status: 422 })
      }
      return HttpResponse.json({ data: buildUser() }, { status: 201 })
    })

    await expect(api.createUser({ name: 'No Email' })).rejects.toThrow(/email/i)
  })
})

// ── CRUD: Update ────────────────────────────────────────────────────────────

describe('PUT /users/:id', () => {
  it('updates an existing user', async () => {
    const user = await api.updateUser('user_abc123', { name: 'Updated Name' })

    expect(user.name).toBe('Updated Name')
  })

  it('rejects concurrent updates with conflict', async () => {
    overrideHandler('put', `${BASE_URL}/users/:id`, () =>
      HttpResponse.json({ error: 'Version conflict' }, { status: 409 })
    )

    await expect(api.updateUser('user_abc123', { name: 'Conflict' })).rejects.toThrow(/conflict/i)
  })
})

// ── CRUD: Delete ────────────────────────────────────────────────────────────

describe('DELETE /users/:id', () => {
  it('deletes a user and returns no content', async () => {
    await expect(api.deleteUser('user_abc123')).resolves.toBeUndefined()
  })

  it('throws on deleting non-existent user', async () => {
    overrideHandler('delete', `${BASE_URL}/users/:id`, () =>
      HttpResponse.json({ error: 'Not found' }, { status: 404 })
    )

    await expect(api.deleteUser('user_nonexistent')).rejects.toThrow()
  })
})

// ── Network conditions ──────────────────────────────────────────────────────

describe('network resilience', () => {
  it('handles a slow network without timeout', async () => {
    overrideHandler('get', `${BASE_URL}/users/:id`, async () => {
      await delay(500)
      return HttpResponse.json({ data: buildUser() })
    })

    const result = await api.getUser('user_slow')
    expect(result).toBeDefined()
  }, 10_000)

  it('handles network failure gracefully', async () => {
    overrideHandler('get', `${BASE_URL}/users`, () => HttpResponse.error())

    await expect(api.getUsers({ page: 1 })).rejects.toThrow()
  })

  it('handles malformed JSON response', async () => {
    overrideHandler('get', `${BASE_URL}/users/:id`, () =>
      new HttpResponse('not json', { status: 200, headers: { 'Content-Type': 'application/json' } })
    )

    await expect(api.getUser('user_bad')).rejects.toThrow()
  })

  it('retries on transient failure', async () => {
    const attempt = vi.fn()
    let callCount = 0

    overrideHandler('get', `${BASE_URL}/users/:id`, () => {
      attempt()
      callCount++
      if (callCount < 3) return HttpResponse.error()
      return HttpResponse.json({ data: buildUser() })
    })

    const user = await api.getUser('user_retry', { retries: 3 })
    expect(user).toBeDefined()
    expect(attempt).toHaveBeenCalledTimes(3)
  })
})

// ── Authentication ──────────────────────────────────────────────────────────

describe('authentication', () => {
  it('sends auth token in headers', async () => {
    const spy = vi.fn()
    overrideHandler('get', `${BASE_URL}/users`, ({ request }) => {
      spy(request.headers.get('Authorization'))
      return HttpResponse.json({ data: [] })
    })

    await api.getUsers({ page: 1 }, { token: 'Bearer valid_token' })

    expect(spy).toHaveBeenCalledWith('Bearer valid_token')
  })

  it('throws 401 on invalid token', async () => {
    overrideHandler('get', `${BASE_URL}/users`, ({ request }) => {
      const auth = request.headers.get('Authorization')
      if (!auth || !auth.startsWith('Bearer ')) {
        return HttpResponse.json({ error: 'Unauthorized' }, { status: 401 })
      }
      return HttpResponse.json({ data: [] })
    })

    await expect(api.getUsers({ page: 1 }, { token: 'invalid' })).rejects.toThrow(/unauthorized/i)
  })

  it('throws 403 on insufficient permissions', async () => {
    overrideHandler('get', `${BASE_URL}/users`, () =>
      HttpResponse.json({ error: 'Forbidden' }, { status: 403 })
    )

    await expect(api.getUsers({ page: 1 }, { token: 'Bearer readonly' })).rejects.toThrow(/forbidden/i)
  })
})

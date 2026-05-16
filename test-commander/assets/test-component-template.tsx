import { describe, it, expect, vi, beforeEach } from '{{framework}}'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { faker } from '@faker-js/faker'
import {{ComponentName}} from '{{importPath}}'

// ── Fixtures ────────────────────────────────────────────────────────────────

const buildProps = (overrides: Partial<React.ComponentProps<typeof {{ComponentName}}>> = {}) => ({
  id: faker.string.uuid(),
  ...overrides,
})

const buildData = () => ({
  id: faker.string.uuid(),
  title: faker.lorem.sentence(),
  description: faker.lorem.paragraph(),
  createdAt: faker.date.recent().toISOString(),
})

// ── Loading state ───────────────────────────────────────────────────────────

describe('loading state', () => {
  it('renders a spinner while data is being fetched', () => {
    render(<{{ComponentName}} {...buildProps()} isLoading />)

    expect(screen.getByRole('status')).toBeInTheDocument()
    expect(screen.getByLabelText(/loading/i)).toBeInTheDocument()
  })

  it('does not render content while loading', () => {
    render(<{{ComponentName}} {...buildProps()} isLoading data={null} />)

    expect(screen.queryByRole('heading')).not.toBeInTheDocument()
  })

  it('shows a skeleton placeholder when loading with no previous data', () => {
    const { container } = render(<{{ComponentName}} {...buildProps()} isLoading skeleton />)

    expect(container.querySelector('[data-testid="skeleton"]')).toBeInTheDocument()
  })

  it('shows previous data during background refresh', () => {
    const data = buildData()
    render(<{{ComponentName}} {...buildProps()} isLoading data={data} />)

    expect(screen.getByText(data.title)).toBeInTheDocument()
    expect(screen.getByRole('status')).toBeInTheDocument()
  })
})

// ── Empty state ─────────────────────────────────────────────────────────────

describe('empty state', () => {
  it('shows a empty state message when there is no data', () => {
    render(<{{ComponentName}} {...buildProps()} data={[]} />)

    expect(screen.getByText(/no .+ found/i)).toBeInTheDocument()
    expect(screen.getByRole('img', { name: /empty/i })).toBeInTheDocument()
  })

  it('renders a call-to-action when the list is empty', () => {
    const onAction = vi.fn()
    render(<{{ComponentName}} {...buildProps()} data={[]} onCreate={onAction} />)

    const cta = screen.getByRole('button', { name: /create/i })
    expect(cta).toBeInTheDocument()
  })

  it('fires onCreate callback when CTA is clicked', async () => {
    const onAction = vi.fn()
    render(<{{ComponentName}} {...buildProps()} data={[]} onCreate={onAction} />)

    await userEvent.click(screen.getByRole('button', { name: /create/i }))
    expect(onAction).toHaveBeenCalledTimes(1)
  })

  it('does not show empty state when data is loading', () => {
    render(<{{ComponentName}} {...buildProps()} data={[]} isLoading />)

    expect(screen.queryByText(/no .+ found/i)).not.toBeInTheDocument()
  })
})

// ── Error state ─────────────────────────────────────────────────────────────

describe('error state', () => {
  it('displays an error message', () => {
    const error = new Error('Network request failed')
    render(<{{ComponentName}} {...buildProps()} error={error} />)

    expect(screen.getByRole('alert')).toBeInTheDocument()
    expect(screen.getByText(/network request failed/i)).toBeInTheDocument()
  })

  it('renders a retry button', () => {
    const onRetry = vi.fn()
    render(<{{ComponentName}} {...buildProps()} error={new Error('fail')} onRetry={onRetry} />)

    expect(screen.getByRole('button', { name: /retry|try again/i })).toBeInTheDocument()
  })

  it('fires onRetry when the retry button is clicked', async () => {
    const onRetry = vi.fn()
    render(<{{ComponentName}} {...buildProps()} error={new Error('fail')} onRetry={onRetry} />)

    await userEvent.click(screen.getByRole('button', { name: /retry|try again/i }))
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('does not show error when there is data', () => {
    render(<{{ComponentName}} {...buildProps()} error={new Error('fail')} data={buildData()} />)

    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('renders error boundaries gracefully', () => {
    vi.spyOn(console, 'error').mockImplementation(() => {})
    const Thrower = () => { throw new Error('crash') }

    expect(() => render(<Thrower />)).toThrow()
  })
})

// ── Success state ───────────────────────────────────────────────────────────

describe('success state', () => {
  it('renders the data', () => {
    const data = buildData()
    render(<{{ComponentName}} {...buildProps()} data={data} />)

    expect(screen.getByText(data.title)).toBeInTheDocument()
    expect(screen.getByText(data.description)).toBeInTheDocument()
  })

  it('renders all items when data is an array', () => {
    const data = faker.helpers.multiple(buildData, { count: 5 })
    render(<{{ComponentName}} {...buildProps()} data={data} />)

    expect(screen.getAllByRole('listitem')).toHaveLength(5)
  })

  it('handles user interaction correctly', async () => {
    const onSelect = vi.fn()
    const data = buildData()
    render(<{{ComponentName}} {...buildProps()} data={data} onSelect={onSelect} />)

    await userEvent.click(screen.getByText(data.title))
    expect(onSelect).toHaveBeenCalledWith(data.id)
  })

  it('updates optimistically before API confirms', async () => {
    const data = buildData()
    const onUpdate = vi.fn().mockResolvedValue({ ...data, title: 'updated' })

    render(<{{ComponentName}} {...buildProps()} data={data} onUpdate={onUpdate} />)
    await userEvent.click(screen.getByRole('button', { name: /edit/i }))
    await userEvent.clear(screen.getByRole('textbox'))
    await userEvent.type(screen.getByRole('textbox'), 'updated')
    await userEvent.click(screen.getByRole('button', { name: /save/i }))

    expect(screen.getByText('updated')).toBeInTheDocument()
  })

  it('renders with correct accessibility attributes', () => {
    const data = buildData()
    render(<{{ComponentName}} {...buildProps()} data={data} />)

    expect(screen.getByRole('region')).toHaveAttribute('aria-label')
  })
})

// ── Integration: state transitions ──────────────────────────────────────────

describe('state transitions', () => {
  it('moves from loading to success', async () => {
    const { rerender } = render(<{{ComponentName}} {...buildProps()} isLoading data={undefined} />)

    expect(screen.getByRole('status')).toBeInTheDocument()

    const data = buildData()
    rerender(<{{ComponentName}} {...buildProps()} isLoading={false} data={data} />)

    await waitFor(() => {
      expect(screen.getByText(data.title)).toBeInTheDocument()
    })
    expect(screen.queryByRole('status')).not.toBeInTheDocument()
  })

  it('moves from loading to error on failure', async () => {
    const { rerender } = render(<{{ComponentName}} {...buildProps()} isLoading />)
    expect(screen.getByRole('status')).toBeInTheDocument()

    rerender(<{{ComponentName}} {...buildProps()} isLoading={false} error={new Error('fail')} />)

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument()
    })
  })

  it('recovers from error to success on retry', async () => {
    const onRetry = vi.fn()
    const { rerender } = render(
      <{{ComponentName}} {...buildProps()} error={new Error('fail')} onRetry={onRetry} />
    )

    await userEvent.click(screen.getByRole('button', { name: /retry/i }))
    expect(onRetry).toHaveBeenCalled()

    const data = buildData()
    rerender(<{{ComponentName}} {...buildProps()} data={data} />)

    await waitFor(() => {
      expect(screen.getByText(data.title)).toBeInTheDocument()
    })
  })
})

// ── Edge cases ──────────────────────────────────────────────────────────────

describe('edge cases', () => {
  it('handles missing optional props without crashing', () => {
    render(<{{ComponentName}} />)
    expect(screen.getByRole('region')).toBeInTheDocument()
  })

  it('handles very long text without breaking layout', () => {
    const data = buildData()
    data.title = 'A'.repeat(1000)
    render(<{{ComponentName}} {...buildProps()} data={data} />)

    expect(screen.getByText(data.title)).toBeInTheDocument()
  })

  it('handles special characters in data', () => {
    const data = buildData()
    data.title = '<script>alert("xss")</script> & "quotes"'
    render(<{{ComponentName}} {...buildProps()} data={data} />)

    expect(screen.getByText(data.title)).toBeInTheDocument()
  })

  it('does not render if data is null', () => {
    render(<{{ComponentName}} {...buildProps()} data={null} />)

    expect(screen.queryByRole('listitem')).not.toBeInTheDocument()
  })
})

// ─────────────────────────────────────────────────────────────
// Production Express Error Middleware
// Features: OTEL integration, error classification,
//           structured logging, status code mapping
// ─────────────────────────────────────────────────────────────

import { Request, Response, NextFunction } from 'express'
import { trace, SpanStatusCode, Span } from '@opentelemetry/api'
import { SemanticAttributes } from '@opentelemetry/semantic-conventions'
import crypto from 'node:crypto'

// ── Error Classes ────────────────────────────────────────────

export class AppError extends Error {
  public readonly statusCode: number
  public readonly errorCode: string
  public readonly isOperational: boolean
  public readonly details?: Record<string, unknown>
  public readonly retryable: boolean

  constructor(
    message: string,
    statusCode: number,
    errorCode: string,
    options?: {
      isOperational?: boolean
      details?: Record<string, unknown>
      retryable?: boolean
    }
  ) {
    super(message)
    this.name = this.constructor.name
    this.statusCode = statusCode
    this.errorCode = errorCode
    this.isOperational = options?.isOperational ?? true
    this.details = options?.details
    this.retryable = options?.retryable ?? false
    Error.captureStackTrace(this, this.constructor)
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(message, 400, 'VALIDATION_ERROR', {
      isOperational: true,
      details,
      retryable: false,
    })
  }
}

export class AuthenticationError extends AppError {
  constructor(message = 'Authentication required') {
    super(message, 401, 'UNAUTHORIZED', {
      isOperational: true,
      retryable: false,
    })
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Insufficient permissions') {
    super(message, 403, 'FORBIDDEN', {
      isOperational: true,
      retryable: false,
    })
  }
}

export class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404, 'NOT_FOUND', {
      isOperational: true,
      retryable: false,
    })
  }
}

export class ConflictError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(message, 409, 'CONFLICT', {
      isOperational: true,
      details,
      retryable: false,
    })
  }
}

export class RateLimitError extends AppError {
  constructor(message = 'Too many requests') {
    super(message, 429, 'RATE_LIMITED', {
      isOperational: true,
      retryable: true,
    })
  }
}

export class DownstreamError extends AppError {
  public readonly upstreamService: string
  public readonly upstreamStatusCode?: number

  constructor(
    message: string,
    upstreamService: string,
    options?: { upstreamStatusCode?: number; retryable?: boolean }
  ) {
    super(message, 502, 'DOWNSTREAM_ERROR', {
      isOperational: true,
      retryable: options?.retryable ?? true,
      details: { upstreamService, upstreamStatusCode: options?.upstreamStatusCode },
    })
    this.upstreamService = upstreamService
    this.upstreamStatusCode = options?.upstreamStatusCode
  }
}

// ── Status code mapping ──────────────────────────────────────

function isHttpError(statusCode: number): boolean {
  return statusCode >= 400 && statusCode < 600
}

function defaultErrorCode(statusCode: number): string {
  const map: Record<number, string> = {
    400: 'VALIDATION_ERROR',
    401: 'UNAUTHORIZED',
    403: 'FORBIDDEN',
    404: 'NOT_FOUND',
    405: 'METHOD_NOT_ALLOWED',
    409: 'CONFLICT',
    422: 'UNPROCESSABLE_ENTITY',
    429: 'RATE_LIMITED',
    500: 'INTERNAL_ERROR',
    502: 'DOWNSTREAM_ERROR',
    503: 'SERVICE_UNAVAILABLE',
    504: 'GATEWAY_TIMEOUT',
  }
  return map[statusCode] || 'UNKNOWN_ERROR'
}

// ── Logger interface ─────────────────────────────────────────

interface ErrorLogEntry {
  timestamp: string
  level: string
  message: string
  service: string
  trace_id?: string
  span_id?: string
  error: {
    type: string
    code: string
    message: string
    stack?: string
  }
  context: {
    method: string
    path: string
    route?: string
    query?: string
    request_id: string
    user_id?: string
  }
  duration_ms?: number
}

interface Logger {
  error(entry: ErrorLogEntry): void
  warn(entry: Partial<ErrorLogEntry>): void
  debug(entry: Partial<ErrorLogEntry>): void
}

// ── Middleware factory ────────────────────────────────────────

interface ErrorMiddlewareOptions {
  serviceName: string
  logger: Logger
  exposeStackTraces?: boolean
  sensitivePaths?: RegExp[]
  onError?: (err: Error, req: Request, span?: Span) => void
}

const SENSITIVE_FIELDS = ['password', 'secret', 'token', 'authorization', 'credit_card', 'ssn']

function sanitizeHeaders(headers: Record<string, unknown>): Record<string, unknown> {
  const sanitized = { ...headers }
  for (const field of SENSITIVE_FIELDS) {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]'
    }
    const lower = field.toLowerCase()
    if (sanitized[lower]) {
      sanitized[lower] = '[REDACTED]'
    }
  }
  return sanitized
}

export function createErrorMiddleware(options: ErrorMiddlewareOptions) {
  const {
    serviceName,
    logger,
    exposeStackTraces = process.env.NODE_ENV !== 'production',
    sensitivePaths = [/\/secrets/, /\/tokens/, /\/internal\/debug/],
    onError,
  } = options

  return function errorMiddleware(
    err: Error,
    req: Request,
    res: Response,
    _next: NextFunction
  ): void {
    // ── Skip sensitive paths ─────────────────────────────
    for (const pattern of sensitivePaths) {
      if (pattern.test(req.path)) {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Not found' } })
        return
      }
    }

    // ── Request ID ────────────────────────────────────────
    const requestId = (req.headers['x-request-id'] as string) || crypto.randomUUID()
    const startTime = (req as any)._startTime ?? Date.now()
    const durationMs = Date.now() - startTime

    // ── Active span ───────────────────────────────────────
    const activeSpan = trace.getActiveSpan()

    if (activeSpan) {
      activeSpan.recordException(err)
      activeSpan.setStatus({
        code: SpanStatusCode.ERROR,
        message: err.message,
      })
      activeSpan.setAttribute(SemanticAttributes.HTTP_STATUS_CODE, res.statusCode)
      activeSpan.setAttribute('error.code', getErrorCode(err))
      activeSpan.setAttribute('error.type', err.constructor.name)
      activeSpan.setAttribute('request_id', requestId)
    }

    // ── Determine error properties ────────────────────────
    let statusCode = 500
    let errorCode = 'INTERNAL_ERROR'
    let details: Record<string, unknown> | undefined
    let isOperational = false
    let isRetryable = false

    if (err instanceof AppError) {
      statusCode = err.statusCode
      errorCode = err.errorCode
      details = err.details
      isOperational = err.isOperational
      isRetryable = err.retryable
    } else if (isHttpError((err as any).statusCode)) {
      statusCode = (err as any).statusCode
      errorCode = defaultErrorCode(statusCode)
      isOperational = true
    } else if (err.name === 'SyntaxError') {
      // JSON parse errors from body-parser
      statusCode = 400
      errorCode = 'VALIDATION_ERROR'
      isOperational = true
    } else if (err.name === 'TimeoutError' || (err as any).code === 'ETIMEDOUT') {
      statusCode = 504
      errorCode = 'GATEWAY_TIMEOUT'
      isOperational = true
      isRetryable = true
    }

    // ── Structured log entry ──────────────────────────────
    const logEntry: ErrorLogEntry = {
      timestamp: new Date().toISOString(),
      level: statusCode >= 500 ? 'error' : 'warn',
      message: err.message,
      service: serviceName,
      trace_id: activeSpan?.spanContext().traceId,
      span_id: activeSpan?.spanContext().spanId,
      error: {
        type: err.constructor.name,
        code: errorCode,
        message: err.message,
        stack: exposeStackTraces ? err.stack ?? '' : undefined,
      },
      context: {
        method: req.method,
        path: req.path,
        route: (req as any).route?.path,
        query: req.path.includes('?') ? '[REDACTED]' : undefined,
        request_id: requestId,
        user_id: (req as any).user?.id,
      },
      duration_ms: durationMs,
    }

    if (statusCode >= 500) {
      logger.error(logEntry)
    } else {
      logger.warn(logEntry)
    }

    // ── Callback hook ─────────────────────────────────────
    onError?.(err, req, activeSpan ?? undefined)

    // ── Response ──────────────────────────────────────────
    const body: Record<string, unknown> = {
      error: {
        code: errorCode,
        message: isOperational ? err.message : 'An unexpected error occurred',
        request_id: requestId,
      },
    }

    if (details && isOperational) {
      body.error['details'] = details
    }

    // Set retry-after for rate limits
    if (statusCode === 429) {
      res.setHeader('Retry-After', Math.ceil(60).toString())
    }

    res.status(statusCode).json(body)
  }
}

// ── Utility ──────────────────────────────────────────────────

function getErrorCode(err: Error): string {
  if (err instanceof AppError) return err.errorCode
  if ((err as any).code) return String((err as any).code)
  return 'UNKNOWN'
}

// ── 404 catch-all ────────────────────────────────────────────

export function notFoundHandler(req: Request, _res: Response, next: NextFunction): void {
  next(new NotFoundError(req.path))
}

// ── Async handler wrapper ────────────────────────────────────

import { RequestHandler } from 'express'

export function asyncHandler(fn: RequestHandler): RequestHandler {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next)
  }
}

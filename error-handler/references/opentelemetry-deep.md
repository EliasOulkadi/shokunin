# OpenTelemetry Deep Reference

## Context Propagation

### W3C TraceContext

OpenTelemetry uses the [W3C TraceContext](https://www.w3.org/TR/trace-context/) standard to propagate trace context across service boundaries. Two headers are injected into HTTP requests:

```
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
tracestate: vendor=specific-data
```

**traceparent format:** `{version}-{trace_id}-{parent_span_id}-{trace_flags}`

| Field | Size | Description |
|-------|------|-------------|
| version | 1 byte (`00`) | Protocol version |
| trace_id | 16 bytes (hex) | Globally unique trace ID |
| parent_span_id | 8 bytes (hex) | Span ID of the caller |
| trace_flags | 1 byte (`01` = sampled, `00` = not) | Sampling decision bit |

### Manual context propagation

```typescript
import { context, propagation, trace, Span } from '@opentelemetry/api'

// Inject context into outbound headers
const headers: Record<string, string> = {}
propagation.inject(context.active(), headers)

// Output: { traceparent: '00-...', tracestate: '...' }

// Extract context from inbound headers
const extractedCtx = propagation.extract(context.active(), headers)
const ctxWithSpan = trace.setSpan(extractedCtx, span)
```

### Propagating through message queues

```typescript
// Producer — inject into message metadata
async function publishMessage(payload: any) {
  const carrier: Record<string, string> = {}
  propagation.inject(context.active(), carrier)
  await queue.send({
    payload,
    meta: { traceContext: carrier },
  })
}

// Consumer — extract before processing
async function handleMessage(msg: any) {
  const parentCtx = propagation.extract(
    context.active(),
    msg.meta.traceContext
  )
  await context.with(parentCtx, async () => {
    // Span created here inherits the trace
    return tracer.startActiveSpan('process-message', async (span) => {
      // ...
      span.end()
    })
  })
}
```

## Sampling Strategies

### Head-based sampling (decision at trace root)

| Strategy | Sampler | Use case |
|----------|---------|----------|
| Always on | `AlwaysOnSampler` | Dev, CI, low-volume critical paths |
| Always off | `AlwaysOffSampler` | Disabling tracing |
| Ratio | `TraceIdRatioBased` | Random % of all traces |
| Parent-based | `ParentBased` | Respect upstream sampling decision |
| Custom | Implement `Sampler` | Priority-based, endpoint-based |

```typescript
// Via environment (recommended for config)
// OTEL_TRACES_SAMPLER=traceidratio
// OTEL_TRACES_SAMPLER_ARG=0.1

// Via SDK
import { TraceIdRatioBasedSampler, ParentBasedSampler } from '@opentelemetry/sdk-trace-node'

const sdk = new NodeSDK({
  sampler: new ParentBasedSampler({
    root: new TraceIdRatioBasedSampler(0.1),
  }),
})
```

**Priority sampling** – keep traces that contain errors, high-value endpoints, or slow operations:

```typescript
import { Sampler, SamplingResult, SamplingDecision } from '@opentelemetry/sdk-trace-node'
import { SpanKind, Attributes } from '@opentelemetry/api'

class PrioritySampler implements Sampler {
  shouldSample(
    _ctx: unknown,
    _traceId: string,
    spanName: string,
    spanKind: SpanKind,
    attributes: Attributes
  ): SamplingResult {
    // Always sample critical endpoints
    if (['POST /payments', 'POST /checkout', 'POST /auth/login'].includes(spanName)) {
      return { decision: SamplingDecision.RECORD_AND_SAMPLED }
    }
    // Always sample errors
    if (attributes?.error) {
      return { decision: SamplingDecision.RECORD_AND_SAMPLED }
    }
    // 10% sampling for everything else
    return {
      decision: SamplingDecision.RECORD_AND_SAMPLED, // actually use ratio
    }
  }

  toString(): string {
    return 'PrioritySampler'
  }
}
```

### Tail-based sampling (decision after trace complete)

More accurate because you decide based on the full trace (including errors). Requires a collector such as the OpenTelemetry Collector with the **tailsampling processor**.

```yaml
# collector-config.yaml
processors:
  tailsampling:
    decision_wait: 30s          # buffer time to collect all spans
    num_traces: 10000           # max traces in memory
    expected_new_traces_per_sec: 100
    policies:
      - name: error-policy
        type: status_code
        status_code:
          statuses: [ERROR]
      - name: slow-policy
        type: latency
        latency:
          threshold_ms: 1000
      - name: probabilistic-policy
        type: probabilistic
        probabilistic:
          sampling_percentage: 10
```

**Comparison:**

| Aspect | Head-based | Tail-based |
|--------|-----------|------------|
| Overhead | Low — decision early | Higher — buffering spans |
| Accuracy | Misses errors in dropped traces | Captures all relevant traces |
| Complexity | Simple, SDK-native | Requires collector + storage |
| Cost | Lower volume | Potentially higher buffer, less egress |

## Span Attributes — Semantic Conventions

### HTTP spans

```typescript
import { SemanticAttributes } from '@opentelemetry/semantic-conventions'

span.setAttributes({
  [SemanticAttributes.HTTP_METHOD]: 'POST',
  [SemanticAttributes.HTTP_URL]: '/api/payments',
  [SemanticAttributes.HTTP_STATUS_CODE]: 200,
  [SemanticAttributes.HTTP_REQUEST_CONTENT_LENGTH]: 1024,
  [SemanticAttributes.HTTP_RESPONSE_CONTENT_LENGTH]: 256,
  [SemanticAttributes.HTTP_ROUTE]: '/api/payments/:id',
  [SemanticAttributes.HTTP_CLIENT_IP]: '10.0.0.1',
  [SemanticAttributes.USER_AGENT_ORIGINAL]: 'axios/1.2.0',
  [SemanticAttributes.NET_PEER_NAME]: 'api.stripe.com',
  [SemanticAttributes.NET_PEER_PORT]: 443,
})
```

### Database spans

```typescript
span.setAttributes({
  [SemanticAttributes.DB_SYSTEM]: 'postgresql',
  [SemanticAttributes.DB_CONNECTION_STRING]: 'host=...',  // caution: strip credentials
  [SemanticAttributes.DB_USER]: 'app_user',
  [SemanticAttributes.DB_NAME]: 'payments_prod',
  [SemanticAttributes.DB_STATEMENT]: 'SELECT * FROM orders WHERE id = $1',
  [SemanticAttributes.DB_OPERATION]: 'SELECT',
  [SemanticAttributes.DB_SQL_TABLE]: 'orders',
})
```

### Messaging spans

```typescript
span.setAttributes({
  [SemanticAttributes.MESSAGING_SYSTEM]: 'rabbitmq',
  [SemanticAttributes.MESSAGING_DESTINATION]: 'order.created',
  [SemanticAttributes.MESSAGING_DESTINATION_KIND]: 'queue',
  [SemanticAttributes.MESSAGING_OPERATION]: 'process',
  [SemanticAttributes.MESSAGING_MESSAGE_ID]: 'msg_abc123',
  [SemanticAttributes.MESSAGING_CONVERSATION_ID]: 'conv_456',
})
```

### RPC spans

```typescript
span.setAttributes({
  [SemanticAttributes.RPC_SYSTEM]: 'grpc',
  [SemanticAttributes.RPC_SERVICE]: 'PaymentService',
  [SemanticAttributes.RPC_METHOD]: 'ChargeCard',
  [SemanticAttributes.RPC_GRPC_STATUS_CODE]: 0,
})
```

### Custom business attributes

```typescript
span.setAttributes({
  'payment.id': 'pay_abc123',
  'payment.amount': 2999,
  'payment.currency': 'USD',
  'payment.provider': 'stripe',
  'order.id': 'ord_456',
  'customer.tier': 'premium',
  'checkout.ab_test': 'variant_b',
})
```

## Metrics Types

### Counter

Monotonic, additive — only increases or resets. Use for things that count occurrences.

```typescript
import { metrics } from '@opentelemetry/api'

const meter = metrics.getMeter('payment-service')
const requestCounter = meter.createCounter('http.requests.total', {
  description: 'Total HTTP requests received',
  unit: '1',
})

// Record an increment
requestCounter.add(1, {
  [SemanticAttributes.HTTP_METHOD]: 'POST',
  [SemanticAttributes.HTTP_STATUS_CODE]: '200',
  [SemanticAttributes.HTTP_ROUTE]: '/api/payments',
})
```

**Good for:** request count, error count, items processed, jobs enqueued.

### UpDown Counter

Non-monotonic — can increase or decrease. Use for values that go up and down.

```typescript
const activeConnections = meter.createUpDownCounter('db.connections.active', {
  description: 'Number of active database connections',
  unit: '1',
})

activeConnections.add(1)   // connection opened
activeConnections.add(-1)  // connection closed
```

**Good for:** queue depth, active connections, concurrent requests, pool utilization.

### Histogram

Samples observations and provides statistical distribution (count, sum, min, max, percentiles).

```typescript
const latencyHistogram = meter.createHistogram('http.request.duration_ms', {
  description: 'HTTP request duration in milliseconds',
  unit: 'ms',
  boundaries: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000],
})

const start = Date.now()
await handler(req, res)
latencyHistogram.record(Date.now() - start, {
  [SemanticAttributes.HTTP_METHOD]: req.method,
  [SemanticAttributes.HTTP_ROUTE]: req.route?.path || 'unknown',
})
```

**Explicit bucket boundaries** ensure your P99 calculation is accurate in the ranges you care about. For payment API: `[5, 10, 25, 50, 100, 200, 500, 1000, 3000]`.

**Good for:** latency, payload size, batch processing time, DB query time.

### Gauge (Async)

Snapshot of a value at a point in time. In OpenTelemetry JS, gauges are **asynchronous** (callback-based).

```typescript
import { ValueType } from '@opentelemetry/api'

const memoryGauge = meter.createObservableGauge('process.memory.usage_bytes', {
  description: 'Process memory usage',
  unit: 'By',
  valueType: ValueType.INT,
})

memoryGauge.addCallback((observableResult) => {
  const mem = process.memoryUsage()
  observableResult.observe(mem.heapUsed, { type: 'heap' })
  observableResult.observe(mem.rss, { type: 'rss' })
})
```

**Good for:** memory usage, CPU load, pool utilization %, cache hit ratio, disk space.

### Metric naming conventions

| Convention | Example |
|------------|---------|
| `domain.name.unit` | `http.request.duration_ms` |
| `domain.name.total` | `http.requests.total` |
| `domain.active` | `db.connections.active` |
| `domain.errors` | `http.requests.errors` |
| `domain.*` | `payments.processed.total`, `payments.failed.total` |

Always include relevant attributes (method, status, route, service) for dimensional analysis.

## Log Correlation

### Bridge OpenTelemetry with structured logging

**Pino + OpenTelemetry:**

```typescript
import pino from 'pino'
import { context, trace, isSpanContextValid } from '@opentelemetry/api'

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  mixin() {
    const spanCtx = trace.getSpan(context.active())?.spanContext()
    if (spanCtx && isSpanContextValid(spanCtx)) {
      return {
        trace_id: spanCtx.traceId,
        span_id: spanCtx.spanId,
        trace_flags: spanCtx.traceFlags.toString(),
      }
    }
    return {}
  },
  formatters: {
    level(label) {
      return { level: label }
    },
  },
  serializers: {
    err: pino.stdSerializers.err,
    error: pino.stdSerializers.err,
  },
})
```

**Winston + OpenTelemetry:**

```typescript
import winston from 'winston'
import { context, trace } from '@opentelemetry/api'

const otelFormat = winston.format((info) => {
  const spanCtx = trace.getSpan(context.active())?.spanContext()
  if (spanCtx) {
    info.trace_id = spanCtx.traceId
    info.span_id = spanCtx.spanId
  }
  return info
})

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    otelFormat(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()],
})
```

### OpenTelemetry Logs SDK (direct log export)

```typescript
import { logs } from '@opentelemetry/api-logs'
import { LoggerProvider } from '@opentelemetry/sdk-logs'

// Severity: TRACE(1) DEBUG(5) INFO(9) WARN(13) ERROR(17) FATAL(21)
const logRecord = logger.emit({
  body: 'Payment processing failed',
  severityNumber: 17,
  severityText: 'ERROR',
  attributes: {
    'payment.id': 'pay_abc123',
    'payment.amount': 2999,
    'error.type': 'StripeAPIError',
    'error.code': 'card_declined',
  },
})
```

**Log correlation rules:**

| Rule | Reason |
|------|--------|
| Always emit `trace_id` and `span_id` | Enables link from log → trace |
| Match `severityNumber` to log levels | Consistent filtering |
| Include `error.type` and `error.code` | Faster triage without trace lookup |
| Never emit PII or secrets | Compliance + security |
| Use consistent attribute names | Cross-service querying |

### Common log attribute names

| Attribute | Example | Purpose |
|-----------|---------|---------|
| `trace_id` | `0af7651916cd43dd8448eb211c80319c` | Link to trace |
| `span_id` | `b7ad6b7169203331` | Link to span |
| `error.type` | `ValidationError` | Error class |
| `error.code` | `INVALID_EMAIL` | Business error code |
| `error.message` | `Email address is invalid` | Human-readable |
| `error.stack` | `Error: ...` | Stack trace (only on high severity) |
| `http.status_code` | `400` | Response status |
| `http.method` | `POST` | HTTP method |
| `http.route` | `/api/users` | Route pattern |
| `db.statement` | `SELECT * FROM ...` | DB query |
| `service.name` | `payment-api` | Source service |
| `service.version` | `1.2.3` | Source version |
| `deployment.environment` | `production` | Environment |

## Exporters Comparison

| Exporter | Protocol | Use case |
|----------|----------|----------|
| `OTLPTraceExporter` (http/protobuf) | HTTP | Most backends (OTEL Collector, Grafana Tempo, Datadog, etc.) |
| `OTLPTraceExporter` (grpc) | gRPC | Higher throughput, lower latency |
| `ConsoleSpanExporter` | stdout | Debugging, dev |
| `JaegerExporter` | Jaeger thrift | Legacy Jaeger backends |
| `ZipkinExporter` | Zipkin JSON | Legacy Zipkin backends |

**Prefer OTLP/http/protobuf** for new setups — every major backend supports it. Run the OpenTelemetry Collector as a gateway/proxy for multi-backend shipping.

## Collector Pipeline

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert
  tailsampling:
    decision_wait: 30s
    num_traces: 10000
    policies:
      - name: errors
        type: status_code
        status_code: { statuses: [ERROR] }
      - name: slow
        type: latency
        latency: { threshold_ms: 1000 }
      - name: sample-10pct
        type: probabilistic
        probabilistic: { sampling_percentage: 10 }

exporters:
  otlp:
    endpoint: your-backend:4317
    tls:
      insecure: false

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes, tailsampling]
      exporters: [otlp]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [otlp]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [otlp]
```

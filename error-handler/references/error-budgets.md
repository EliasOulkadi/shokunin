# Error Budgets Deep Reference

## SLO Calculation

### Core formula

```
SLI (Service Level Indicator) = good_events / total_events
SLO (Service Level Objective) = target SLI over a window
Error Budget = 1 - SLO (as a percentage of total events)
```

| SLO Target | Allowed error/month (30d) | Allowed error/week (7d) | Allowed error/day |
|------------|--------------------------|------------------------|-------------------|
| 99.999%    | 26 seconds               | 6 seconds              | < 1 second        |
| 99.99%     | 4.3 minutes              | 60 seconds             | 8.6 seconds       |
| 99.9%      | 43 minutes               | 10 minutes             | 1.44 minutes      |
| 99.5%      | 3.6 hours                | 50 minutes             | 7.2 minutes       |
| 99.0%      | 7.2 hours                | 1.68 hours             | 14.4 minutes      |
| 95.0%      | 36 hours                 | 8.4 hours              | 1.2 hours         |

### Multiple SLOs per service

```yaml
service: checkout-api
slo_definitions:
  - name: availability
    sli: (http_requests_total - http_requests_5xx) / http_requests_total
    target: 99.95%
    window: 28d
    description: "All successful HTTP requests / total HTTP requests"

  - name: latency
    sli: http_request_duration_ms_bucket{le="500"} / http_request_duration_ms_count
    target: 99.0%
    window: 28d
    description: "Requests under 500ms / total requests"

  - name: freshness
    sli: cache_hit_count / (cache_hit_count + cache_miss_count)
    target: 95.0%
    window: 7d
    description: "Cache hit ratio for product catalog"

  - name: throughput
    sli: jobs_completed_total / jobs_enqueued_total
    target: 99.9%
    window: 7d
    description: "Async job completion rate within SLA window"
```

### Implementing SLIs with OpenTelemetry

```typescript
import { metrics } from '@opentelemetry/api'
import { SemanticAttributes } from '@opentelemetry/semantic-conventions'

const meter = metrics.getMeter('checkout-api')

// Counter for ALL requests
const totalRequests = meter.createCounter('http.requests.total', {
  description: 'Total HTTP requests',
})

// Counter for GOOD requests (non-5xx)
const goodRequests = meter.createCounter('http.requests.good', {
  description: 'Successful (non-5xx) HTTP requests',
})

// Recording latency for SLI
const requestDuration = meter.createHistogram('http.request.duration_ms', {
  description: 'Request duration in ms',
  boundaries: [5, 10, 25, 50, 100, 200, 500, 1000, 3000, 5000],
})

function recordRequest(req: Request, res: Response, durationMs: number) {
  const attrs = {
    [SemanticAttributes.HTTP_METHOD]: req.method,
    [SemanticAttributes.HTTP_ROUTE]: req.route?.path || 'unknown',
    [SemanticAttributes.HTTP_STATUS_CODE]: res.statusCode,
    'slo.name': 'availability',
  }

  totalRequests.add(1, attrs)

  if (res.statusCode < 500) {
    goodRequests.add(1, { ...attrs, 'slo.name': 'availability' })
  }

  requestDuration.record(durationMs, {
    ...attrs,
    'slo.name': 'latency',
  })
}
```


## Burn Rate Alerts

### Theory

**Burn rate** = how fast you're consuming the error budget relative to the SLO window.

```
burn_rate = (1 - actual_sli) / (1 - slo_target)

Example:
  SLO target = 99.9%
  Actual SLI over 1 hour = 99.0%
  Error budget consumed = 1.0% (actual errors) vs 0.1% (allowed)
  burn_rate = 1.0% / 0.1% = 10x
```

| Burn Rate | Time to exhaust budget (30d window) | Severity |
|-----------|-------------------------------------|----------|
| 1x        | 30 days (exhaust exactly at end)    | Info     |
| 2x        | 15 days                             | Warning  |
| 6x        | 5 days                              | Critical |
| 12x       | 2.5 days                            | Critical |
| 30x       | 1 day                               | Fire     |
| 720x      | 1 hour                              | Fire     |

### Simple burn rate alert

```yaml
# Prometheus-style alert rule
groups:
  - name: error-budget
    rules:
      - alert: HighErrorBudgetBurnRate
        expr: |
          (
            1 - (
              sum(rate(http_requests_good_total[5m]))
              / sum(rate(http_requests_total[5m]))
            )
          ) / (1 - 0.999)
          > 6
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error budget burn rate is {{ $value }}x"
          description: >
            Consuming error budget at {{ $value }}x rate.
            Will exhaust 30d budget in
            {{ printf "%.1f" (div 43200 $value) }} hours.
```

## Multi-Window Multi-Burn-Rate Alerts

### Problem

Short windows (5m) catch fast burn but produce false positives from brief spikes. Long windows (1h) are accurate but slow to alert on fast burning.

### Solution: two windows, two thresholds

From the Google SRE Workbook — alert when a **short window** (5m, 1h) shows high burn AND a **long window** (30m, 6h) shows sustained burn.

```yaml
groups:
  - name: error-budget-multi-window
    rules:
      # ── Critical: 6x burn rate ─────────────────────────
      - alert: MWMBR_Critical
        expr: |
          (
            sum(rate(http_requests_good_total[1h]))
            / sum(rate(http_requests_total[1h]))
          ) < 0.994
          and on ()
          (
            sum(rate(http_requests_good_total[5m]))
            / sum(rate(http_requests_total[5m]))
          ) < 0.97
        labels:
          severity: critical
        annotations:
          summary: "Critical error budget burn (6x+)"
          description: >
            SLO: 99.9%. 1h SLI: {{ $value | humanizePercentage }}.
            Burn rate exceeds 6x sustained.

      # ── Warning: 3x burn rate ─────────────────────────
      - alert: MWMBR_Warning
        expr: |
          (
            sum(rate(http_requests_good_total[6h]))
            / sum(rate(http_requests_total[6h]))
          ) < 0.997
          and on ()
          (
            sum(rate(http_requests_good_total[30m]))
            / sum(rate(http_requests_total[30m]))
          ) < 0.985
        labels:
          severity: warning
        annotations:
          summary: "Warning error budget burn (3x+)"
          description: >
            SLO: 99.9%. 6h SLI: {{ $value | humanizePercentage }}.
            Burn rate exceeds 3x sustained.
```

### Alert thresholds by SLO target

| SLO | Critical (6x) short | Critical (6x) long | Warning (3x) short | Warning (3x) long |
|-----|--------------------|--------------------|--------------------|--------------------|
| 99.99% | 5m ≥ 99.94% error | 1h ≥ 99.64% | 30m ≥ 99.85% | 6h ≥ 99.91% |
| 99.9% | 5m ≥ 99.4% | 1h ≥ 99.4% | 30m ≥ 98.5% | 6h ≥ 99.7% |
| 99.5% | 5m ≥ 97.0% | 1h ≥ 97.0% | 30m ≥ 93.5% | 6h ≥ 98.5% |
| 99.0% | 5m ≥ 94.0% | 1h ≥ 94.0% | 30m ≥ 87.0% | 6h ≥ 97.0% |

**Multi-window multi-burn-rate (MWMBR) rules:**

| Condition | Burn Rate | Windows | Alert |
|-----------|-----------|---------|-------|
| Short high burn + Long any burn | ≥14x short | 5m + 1h | Page |
| Short high burn + Long high burn | ≥6x both | 5m + 1h | Page |
| Short medium burn + Long medium burn | ≥3x both | 30m + 6h | Ticket |
| Short low burn + Long low burn | <3x both | — | No alert |

## Error Budget Policy Examples

### Policy: Standard production service

```yaml
policy:
  service_tier: standard
  slo_target: 99.9%
  window: 28d

  error_budget_policy:
    # Exhaust budget -> feature freeze
    exhausted:
      action: freeze
      duration: entire next window
      rules:
        - No deployments without CTO approval
        - All hands on deck for reliability improvements
        - Daily standup on error budget recovery plan

    # >50% consumed -> warning
    warning_at: 50%
    warning_actions:
      - Create incident review ticket
      - Assign reliability engineer to investigate
      - Halt non-critical feature work

    # >75% consumed -> critical
    critical_at: 75%
    critical_actions:
      - Freeze all deployments
      - Page on-call engineering team
      - Begin incident review process
```

### Policy: Critical path service

```yaml
policy:
  service_tier: critical
  slo_target: 99.99%
  window: 28d

  error_budget_policy:
    exhausted:
      action: freeze
      duration: 2 windows (56 days)

    warning_at: 30%
    warning_actions:
      - Immediately page SRE team
      - Enable full trace sampling for this service
      - Prepare rollback candidates
      - Notify engineering manager

    critical_at: 50%
    critical_actions:
      - Freeze all deployments immediately
      - Auto-rollback last deployment if error budget was healthy before
      - Auto-escalate to VP of Engineering
      - Mandatory postmortem within 24 hours
```

### Policy: Experimental/internal service

```yaml
policy:
  service_tier: experimental
  slo_target: 95.0%
  window: 7d

  error_budget_policy:
    exhausted:
      action: notify_team
      duration: none

    warning_at: 80%
    warning_actions:
      - Slack notification to team channel

    critical_at: 95%
    critical_actions:
      - Create low-priority ticket
      - Add to weekly team review agenda
```

## Budget Tracking Dashboard Design

### Dashboard structure (JSON model)

```json
{
  "dashboard": {
    "title": "Error Budget Overview — {service}",
    "refresh": "30s",
    "time": { "default": "7d" },
    "panels": [
      {
        "title": "SLO Compliance",
        "type": "stat",
        "span": 4,
        "targets": [
          {
            "expr": "slo:compliance:ratio{service=\"checkout-api\", slo=\"availability\"}",
            "legend": "Availability SLO"
          }
        ]
      },
      {
        "title": "Error Budget Remaining",
        "type": "gauge",
        "span": 4,
        "unit": "percent",
        "thresholds": [
          { "from": 0, "to": 25, "color": "red" },
          { "from": 25, "to": 50, "color": "yellow" },
          { "from": 50, "to": 100, "color": "green" }
        ],
        "targets": [
          {
            "expr": "slo:error_budget_remaining{service=\"checkout-api\"}"
          }
        ]
      },
      {
        "title": "Burn Rate (Current)",
        "type": "stat",
        "span": 4,
        "unit": "none",
        "thresholds": [
          { "from": 0, "to": 3, "color": "green" },
          { "from": 3, "to": 6, "color": "yellow" },
          { "from": 6, "to": 999, "color": "red" }
        ],
        "targets": [
          {
            "expr": "slo:burn_rate{service=\"checkout-api\"}"
          }
        ]
      },
      {
        "title": "Good / Bad Requests (5m rate)",
        "type": "timeseries",
        "span": 12,
        "targets": [
          {
            "expr": "sum(rate(http_requests_good_total{service=\"checkout-api\"}[5m]))",
            "legend": "Good"
          },
          {
            "expr": "sum(rate(http_requests_bad_total{service=\"checkout-api\"}[5m]))",
            "legend": "Bad"
          }
        ]
      },
      {
        "title": "Error Budget Consumption (28d window)",
        "type": "timeseries",
        "span": 12,
        "unit": "percent",
        "targets": [
          {
            "expr": "slo:error_budget_consumed{service=\"checkout-api\"}",
            "legend": "Consumed"
          },
          {
            "expr": "100",
            "legend": "Budget Limit",
            "dash": "dash"
          },
          {
            "expr": "50",
            "legend": "Warning Threshold",
            "dash": "dash",
            "opacity": 0.3
          }
        ]
      },
      {
        "title": "Burn Rate History",
        "type": "timeseries",
        "span": 12,
        "targets": [
          {
            "expr": "slo:burn_rate{service=\"checkout-api\"}",
            "legend": "Burn Rate"
          },
          {
            "expr": "3",
            "legend": "Warning (3x)",
            "dash": "dash"
          },
          {
            "expr": "6",
            "legend": "Critical (6x)",
            "dash": "dash"
          }
        ]
      },
      {
        "title": "SLO by Endpoint (Latency P99)",
        "type": "table",
        "span": 6,
        "targets": [
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_ms_bucket{service=\"checkout-api\"}[5m])) by (le, route))",
            "legend": "P99"
          }
        ]
      },
      {
        "title": "SLO by Endpoint (Error Rate)",
        "type": "table",
        "span": 6,
        "targets": [
          {
            "expr": "sum(rate(http_requests_bad_total{service=\"checkout-api\"}[5m])) by (route) / sum(rate(http_requests_total{service=\"checkout-api\"}[5m])) by (route) * 100",
            "legend": "Error %"
          }
        ]
      }
    ]
  }
}
```

### Prometheus recording rules for SLO metrics

```yaml
groups:
  - name: slo-recording-rules
    interval: 30s
    rules:
      # Raw SLI (good / total)
      - record: slo:good_ratio:rate_5m
        expr: |
          sum(rate(http_requests_good_total[5m]))
          /
          sum(rate(http_requests_total[5m]))

      # Error budget remaining percentage
      - record: slo:error_budget_remaining
        expr: |
          100 * (
            1 - (
              (1 - slo:good_ratio:rate_5m) / (1 - 0.999)
            )
          )

      # Burn rate
      - record: slo:burn_rate
        expr: |
          (1 - slo:good_ratio:rate_5m) / (1 - 0.999)

      # Long window ratio for MWMBR
      - record: slo:good_ratio:rate_1h
        expr: |
          sum(rate(http_requests_good_total[1h]))
          /
          sum(rate(http_requests_total[1h]))

      - record: slo:good_ratio:rate_6h
        expr: |
          sum(rate(http_requests_good_total[6h]))
          /
          sum(rate(http_requests_total[6h]))
```

## Dashboard Design Principles

| Principle | Practice |
|-----------|----------|
| **Single pane of glass** | All SLOs for a service visible on one dashboard |
| **Color-coded urgency** | Green (>50% remaining), Yellow (25-50%), Red (<25%) |
| **Time-aligned** | Default view matches SLO window (7d or 28d) |
| **Multiple windows** | Show 1h, 6h, 24h, and full window views |
| **Breakdown by dimension** | Route, status code, deployment version, region |
| **Alert correlation** | Show active alerts on the same timeline |
| **Error budget trend** | Line chart of remaining budget over time (not just current %) |
| **Burn rate indicator** | Current burn rate with thresholds clearly marked |
| **SLO compliance stat** | Big number: current SLO value vs target (99.92% / 99.9%) |
| **Deployment annotations** | Mark deployments on timeline to correlate with budget consumption |

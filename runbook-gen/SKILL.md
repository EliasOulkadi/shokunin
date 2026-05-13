---
name: runbook-gen
description: Generate operations runbooks and post-mortems for incident response — severity matrix, decision trees, escalation paths, war room setup (Slack/Zoom), status page updates, customer comms templates, and blameless post-mortems with action items. Use when user asks to create a runbook, incident response plan, on-call guide, SRE procedure, escalation path, outage playbook, or post-mortem. Do NOT use for general documentation (use documentation), error handling patterns (use error-handler), or monitoring/alerting configuration (vendor-specific).
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: sre
  version: "2.0"
---

# Runbook Generator

Operation runbooks that on-call engineers can follow under pressure. Based on Google SRE practices, PagerDuty incident response, and post-mortem culture.

## Required Discovery

1. **Service/System**: What is the runbook about? (API, database, cache, queue)
2. **Incident types**: What can go wrong? (down, degraded, slow, data loss)
3. **Environment**: Production, staging, or both?
4. **Team structure**: Primary, secondary, escalation contacts
5. **Existing monitoring**: Alerts, dashboards, runbooks

## Severity Matrix

| Severity | Definition | Response SLA |
|----------|------------|--------------|
| Sev1 | Service down, users impacted | Respond within 15 min |
| Sev2 | Degraded performance, partial impact | Respond within 1 hour |
| Sev3 | Minor issue, no user impact | Next business day |
| Sev4 | Internal tooling, non-critical | Per team schedule |

## Runbook Template

```
## Runbook: [Incident Type]

### Detection
How this incident is typically discovered:
- Alert: [Prometheus/Grafana/Datadog alert]
- User symptom: [what users see or report]
- Automated detection: [auto-remediation]

### Initial Response (first 5 min)
1. Acknowledge alert (PagerDuty/Opsgenie). Time: < 2 min
2. Determine severity. Time: < 1 min
3. Assign owner. Create incident channel (#inc-sev1). Time: < 2 min
4. Post initial status:
   "Investigating [issue] affecting [scope]. Will update in 15 min."
5. Start diagnosis timer. Time: < 1 min

### Diagnosis (decision tree)
1. Check [primary dashboard]: expected [X], current [Y]
2. Check logs: `kubectl logs -n [ns] -l app=[service] --tail 200`
3. Check database health: `SELECT count(*) FROM pg_stat_activity`
4. Check cache/queue latency: `redis-cli --latency`
5. IF [error in logs] → Runbook A
6. IF [latency > threshold] → Runbook B
7. IF unknown → Escalate

### Resolution Procedures
Each time-boxed with exact commands and verification:

#### Runbook A: [Name] (10 min)
```bash
# Step 1 (2 min)
kubectl rollout restart deployment/[service]

# Verify (1 min)
kubectl rollout status deployment/[service]
```

#### Runbook B: [Alternative]

### Verification Checklist
- [ ] Service health endpoint returns 200
- [ ] Alert resolved (dashboard green)
- [ ] Error rate back to baseline (< 0.1%)
- [ ] Latency p99 < [threshold]

### Escalation
| Timebox | Action | Contact |
|---------|--------|---------|
| 0-15 min | Primary on-call | @name / phone |
| 15-30 min | Secondary on-call | @name / phone |
| 30-60 min | Engineering manager | @name |
| 60+ min | VP Engineering | @name |

### Post-Incident Recovery
- [ ] Data integrity check
- [ ] Deploy fix to production
- [ ] Monitor for 30 min post-fix
- [ ] Update runbook with lessons learned
```

## War Room Setup

### Communications
- **Slack channel**: `#inc-sev1-[incident-name]`
- **Zoom bridge**: [link] (permanent war room)
- **Shared doc**: Google Doc or Notion page for live notes
- **Status page**: Update immediately on detection
- **Customer comms**: Template below

### Status Page Updates

```
Investigating: We're aware of [issue] affecting [scope]. Investigating root cause.

Monitoring: Deployed fix for [root cause]. Monitoring closely.

Resolved: [Issue] has been resolved. All systems operational.
```

### Customer Communication

```
Subject: [Service] incident — [date]

We experienced [description] from [start] to [end] ([duration]).

Root cause: [one sentence]

Impact: [specific metrics]

What we're doing:
1. [Fix deployed]
2. [Monitoring improvements]
3. [Process changes]

We apologize for the disruption.
```

## Post-Mortem Template

```
## Post-Mortem: [Date] — [Title]

Severity: Sev[1-4]
Duration: [detection] → [resolution] ([total])
Impact: [users/customers] for [time]

### Timeline (UTC)
- [Time]: [What happened]
- [Time]: [Detection]
- [Time]: [Response started]
- [Time]: [Resolution]
- [Time]: [All-clear]

### Root Cause
One paragraph. System-focused, not person-focused.

### Contributing Factors
- Monitoring gaps
- Process gaps
- Knowledge gaps

### Action Items
| Action | Owner | Due | Type |
|--------|-------|-----|------|
| [action] | @name | Date | prevent/detect/respond |

### What Went Well
### What Went Wrong
### What We'll Do Differently
```

## Runbook Quality Checklist

- [ ] Every command copy-paste ready with no placeholders
- [ ] Every step has time estimates
- [ ] Multiple resolution paths for common failure modes
- [ ] One runbook per incident type
- [ ] Verification step for every resolution
- [ ] Escalation contacts include backup (Slack + phone)
- [ ] Decision tree is shallow (3-4 levels max)
- [ ] Runbook tested in a drill within the last quarter

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Steps that say "fix the issue" | Tell HOW, not what |
| Commands with unsubstituted variables | Copy-paste ready |
| No verification step | How to know fix worked |
| Outdated runbooks (>6 months) | Commands rot, trust erodes |
| Runbooks nobody tested | First test is during the actual incident |
| Too many steps (>15) | Split or simplify |
| No time-boxes | Engineer doesn't know when to escalate |

## Sources

- Google SRE Book: "Monitoring Distributed Systems"
- Google SRE Workbook: Incident Response
- PagerDuty incident response documentation
- Atlassian post-mortem best practices
- Microsoft SRE practices
- AWS Well-Architected Framework: Operational Excellence

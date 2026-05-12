---
name: runbook-gen
description: Generate operations runbooks for incident response and post-mortems. Use when user asks to create a runbook, incident response guide, on-call playbook, SRE procedure, escalation path, outage playbook, or post-mortem. Triggers on "write a runbook", "create an incident response plan", "on-call guide", "SOP for [service]", "post-mortem template". Do NOT use for general documentation, architecture docs, or user-facing guides. Based on Google SRE practices, PagerDuty incident response, and post-mortem culture.
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: sre
---

Generate operations runbooks that on-call engineers can follow under pressure.

## Required Discovery

Before writing, determine:

1. **Service/System**: What is the runbook about? (API, database, cache, queue, etc.)
2. **Incident types**: What can go wrong? (down, degraded, slow, data loss)
3. **Environment**: Production, staging, both?
4. **Team structure**: Who is primary, secondary, escalation?
5. **Existing monitoring**: What alerts exist? What dashboards?

## Runbook Template

```
## Runbook: [Incident Type]

### Severity
Use this rubric:
- Sev1: Service down, users impacted. Respond within 15 min.
- Sev2: Degraded performance, partial impact. Respond within 1 hour.
- Sev3: Minor issue, no user impact. Next business day.
- Sev4: Internal tooling, non-critical. Timeline varies.

### Detection
How this incident is typically discovered:

- Alert source and name: [Prometheus/Grafana/Datadog alert]
- User-facing symptom: [what users see or report]
- Automated detection: [any auto-remediation that fires]

### Initial Response (first 5 minutes)
Time-boxed steps:
1. Acknowledge alert (PagerDuty/Opsgenie). Time: < 2 min
2. Determine severity using rubric above. Time: < 1 min
3. Assign owner. Create incident channel (#inc-sev1). Time: < 2 min
4. Post initial assessment to status page:
   ```
   Investigating [issue] affecting [scope]. Will update in 15 min.
   ```
5. Start diagnosis timer. Time: < 1 min

### Diagnosis
Decision tree, in order:

1. Check [primary dashboard]: expected [X], current [Y]
2. Check logs:
   ```bash
   kubectl logs -n [namespace] -l app=[service] --tail 200
   ```
3. Check database health:
   ```sql
   SELECT count(*) FROM pg_stat_activity WHERE state = 'active';
   ```
4. Check cache/queue latency:
   ```bash
   redis-cli --latency
   ```
5. IF [specific error in logs] → Runbook A (below)
6. IF [latency > threshold] → Runbook B (below)
7. IF unknown → Escalate

### Resolution Procedures
Each procedure must be time-boxed with exact commands and verification.

#### Runbook A: [Procedure Name] (10 min)
```bash
# Step 1 (2 min)
kubectl rollout restart deployment/[service]

# Verify (1 min)
kubectl rollout status deployment/[service]

# If failed (5 min):
kubectl describe pod [pod-name] --tail=50
```
Verification: `curl -f https://[service]/health`

#### Runbook B: [Alternative Procedure]
```bash
# Step 1 (5 min)
# ...
```

### Verification Checklist
- [ ] Service health endpoint returns 200:
  ```bash
  curl -f http://localhost:8080/health
  ```
- [ ] Alert resolved (check dashboard, should be green)
- [ ] Error rate back to baseline (< 0.1%)
- [ ] Latency back to p99 < [threshold]

### Escalation
| Timebox | Action | Contact |
|---------|--------|---------|
| 0-15 min | Primary on-call | @[name] / [phone] |
| 15-30 min | Secondary on-call | @[name] / [phone] |
| 30-60 min | Engineering manager | @[name] |
| 60+ min | VP Engineering | @[name] |

### Post-Incident Recovery
- [ ] Data integrity check (verify no data loss)
- [ ] Deploy fix to production
- [ ] Monitor for 30 min post-fix
- [ ] Update runbook with lessons learned
```

## Post-Mortem Template

```
## Post-Mortem: [Date] - [Incident Title]

Severity: Sev[1-4]
Duration: [detection] to [resolution] ([total minutes])
Impact: [users/customers affected] for [duration]

### Timeline (UTC)
- [Time]: [What happened]
- [Time]: [Detection]
- [Time]: [Response started]
- [Time]: [Resolution]
- [Time]: [All-clear declared]

### Root Cause
One paragraph. System-focused, not person-focused.

### Contributing Factors
- Monitoring gaps (what we didn't see)
- Process gaps (what we didn't do)
- Knowledge gaps (what we didn't know)

### Action Items
| Action | Owner | Due | Type |
|--------|-------|-----|------|
| [action] | @name | Date | prevent / detect / respond |

### What Went Well
[Honest assessment]

### What Went Wrong
[Honest assessment — no blame. Focus on system and process.]

### What We'll Do Differently
[Process, monitoring, or code changes]
```

## Runbook Quality Checklist

- [ ] Every command is copy-paste ready with no placeholders
- [ ] Every step has time estimates
- [ ] Multiple resolution paths for common failure modes
- [ ] One runbook per incident type (not per component)
- [ ] Verification step exists for every resolution
- [ ] Escalation contacts include backup method (Slack + phone)
- [ ] Decision tree is shallow (3-4 levels max)
- [ ] Runbook tested in a drill within the last quarter

## Anti-Patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| Steps that say "fix the issue" without telling how | On-call engineer under pressure guesses, wastes time |
| Commands with unsubstituted variables | Copy-paste fails, stress increases |
| No verification step | Engineer doesn't know if fix actually worked |
| Outdated runbooks (>6 months old) | Commands rot, endpoints change, trust erodes |
| Runbooks nobody has tested | First test is during the actual incident — worst time |
| Too many steps (>15) | Engineer gets lost; simplify or split |
| No time-boxes | Engineer doesn't know when to escalate |

## Sources
- Google SRE Book: "Monitoring Distributed Systems"
- PagerDuty incident response documentation
- Atlassian post-mortem best practices
- Microsoft SRE practices
- AWS Well-Architected Framework: Operational Excellence

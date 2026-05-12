---
name: runbook-gen
description: Create operations runbooks for incidents
---


# Runbook Gen

Generates operations runbooks that on-call engineers can follow under pressure. Based on Google SRE practices, incident response frameworks, and post-mortem culture.

## Document Structure

```
## Runbook: [Incident Type]

### Severity
Sev1: Service down, users impacted
Sev2: Degraded performance, partial impact
Sev3: Minor issue, no user impact
Sev4: Internal tooling, non-critical

### Detection
How this incident is typically discovered:
- Alert: [prometheus/grafana/datadog alert name]
- Symptom: [what users report]
- Automated: [any automated detection]

### Initial Response
1. Confirm alert
2. Determine severity
3. Assign owner
4. Notify team channel: #incidents
5. Create incident ticket from template

### Diagnosis Steps
1. Check [metric/dashboard]: expected value [X], current [Y]
2. Check logs: `kubectl logs -n [namespace] [pod] --tail 100`
3. Check [database/redis/cache]: `redis-cli ping`
4. If [condition], go to Runbook A
5. If [other condition], go to Runbook B

### Resolution Procedure
Step-by-step, time-boxed:

1. [Action] (expected: 2 min)
   Command: [exact command to run]
   Verify: [how to know it worked]
   If failed: [alternative step]

2. [Action] (expected: 5 min)
   Command: [exact command]
   Verify: [verification step]

### Verification
- [ ] Service responding: `curl /health`
- [ ] Alert resolved: check dashboard
- [ ] Users confirmed: check support channel

### Escalation
If not resolved in [timeframe], escalate to [team/on-call]:

Primary: @name (slack/phone)
Secondary: @name (slack/phone)
Engineering manager: @name

### Post-Mortem
After resolution, create post-mortem with:

1. Timeline (detection, response, resolution, total duration)
2. Root cause (what broke and why)
3. Contributing factors (monitoring gaps, late detection)
4. Action items (prevent recurrence)
5. Blameless â€” focus on system, not people
```

## Runbook Guidelines

- Every command must be copy-paste ready (no placeholders)
- Time estimates for each step (so on-call knows when to escalate)
- Multiple resolution paths for common failure modes
- One runbook per incident type (not per component)
- Test each runbook quarterly with a drill

## Post-Mortem Template

```
## Post-Mortem: [Date] â€” [Incident Title]

Severity: Sev[1-4]
Duration: [detection] to [resolution] ([total time])
Impact: [users affected] for [duration]

### Timeline
- [Time]: [Event]
- [Time]: [Event]
- [Time]: [Resolution]

### Root Cause
[One paragraph, system-focused]

### Action Items
| Item | Owner | Due |
|------|-------|-----|
| [Action] | @name | Date |
| [Action] | @name | Date |

### What Went Well
[honest assessment]

### What Went Wrong
[honest assessment â€” no blame]

### What We'll Do Differently
[changes to process, monitoring, or code]
```

## Runbook Anti-Patterns

- Steps that say "fix the issue" without telling how
- Commands with unsubstituted variables
- No verification step after resolution
- Outdated runbooks (last reviewed >6 months ago)
- Runbooks nobody tested (test them in drills)
## Sources

- Google SRE Book "Monitoring Distributed Systems"
- PagerDuty incident response documentation
- Atlassian post-mortem best practices
- Microsoft SRE practices








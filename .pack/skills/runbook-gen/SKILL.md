---
name: runbook-gen
description: Generate operations runbooks and post-mortems for incident response — severity matrix, decision trees, escalation paths, war room setup (Slack/Zoom), status page updates, customer comms templates, and blameless post-mortems with action items.
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: sre
  version: "3.0.0"
triggers:
  - "create a runbook"
  - "incident response plan"
  - "on-call guide"
  - "SRE procedure"
  - "escalation path"
  - "outage playbook"
  - "post-mortem"
  - "war room"
  - "sev1 procedure"
negatives:
  - "Use **documentation** for general project docs, READMEs, API docs"
  - "Use **error-handler** for error handling patterns, retry logic, circuit breakers"
  - "Use **error-handler** for logging and tracing configuration"
  - "Use **ci-cd** for deployment pipeline runbooks"
  - "Use **db-sculptor** for database-specific recovery procedures"
---


# Runbook Generator

Operation runbooks that on-call engineers can follow under pressure. Based on Google SRE practices, PagerDuty incident response, and post-mortem culture.

## Workflow

Follow these steps in order when generating a runbook:

1. **Discover** — Ask the 5 Required Discovery questions (below) to scope the runbook
2. **Classify** — Map the incident to the Severity Matrix; if unclear start at Sev2
3. **Template** — Instantiate the Runbook Template with service-specific commands, time-boxes, and contacts
4. **War Room** — Configure Slack channel, Zoom bridge, shared doc, status page, and customer comms
5. **Verify** — Run through the Production Checklist before marking complete
6. **Archive** — Store the runbook in the team's on-call repo, test in a drill within the quarter

When the ask is a post-mortem (not a runbook), skip steps 3-4 and use the Post-Mortem Template instead.

## 2. Required Discovery

1. **Service/System**: What is the runbook about? (API, database, cache, queue)
2. **Incident types**: What can go wrong? (down, degraded, slow, data loss)
3. **Environment**: Production, staging, or both?
4. **Team structure**: Primary, secondary, escalation contacts
5. **Existing monitoring**: Alerts, dashboards, runbooks

## 3. Severity Matrix

| Severity | Definition | Response SLA |
|----------|------------|--------------|
| Sev1 | Service down, users impacted | Respond within 15 min |
| Sev2 | Degraded performance, partial impact | Respond within 1 hour |
| Sev3 | Minor issue, no user impact | Next business day |
| Sev4 | Internal tooling, non-critical | Per team schedule |

## 4. Runbook Template

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

## 5. War Room Setup

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

## 6. Post-Mortem Template

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

## Error Handling

| Scenario | Behaviour | Guidance |
|----------|-----------|----------|
| User doesn't know the service/platform | Ask clarifying questions one at a time (not a list) | Start with "what service is this for?" |
| User says "just give me a template" | Output a blank Runbook Template with placeholder brackets | Skip Discovery, fill later |
| User asks for both runbook + post-mortem at once | Generate runbook first, then offer post-mortem | "I'll write the runbook now. Do you have an incident in mind for the post-mortem?" |
| Service has no existing monitoring | Flag the gap, offer to add basic health-check instructions | Note alerts must be configured separately |
| Runbook for a third-party/SaaS dependency | Include vendor status page check; mark resolution as "vendor fixes" | Focus on detection + escalation, not resolution |
| User says "I don't know the escalation contacts" | Use generic roles (Primary on-call, Secondary, EM, VP Eng) | Leave bracketed placeholders |
| Multiple teams involved | Add a RACI section to the runbook | Clarify who decides vs who executes |
| Runbook already exists, user wants update | Treat as revision: read current, diff, propose changes | Flag deprecations, test outdated commands |

## 8. Production Checklist

Before marking a runbook complete, verify every item:

- [ ] **Commands are copy-paste ready** — no unsubstituted variables (`[ns]` only in section headers/notes, never in commands)
- [ ] **Every step has a time-box** — engineer knows when to escalate
- [ ] **Decision tree is shallow** — max 3-4 levels; deeper means split into sub-runbooks
- [ ] **Multiple resolution paths** — at least 2 common failure modes covered
- [ ] **One runbook per incident type** — don't combine "DB failover" and "deployment rollback"
- [ ] **Verification step after every resolution** — how to confirm the fix worked
- [ ] **Escalation contacts listed** — primary + backup, both Slack and phone
- [ ] **Status page templates included** — Investigating / Monitoring / Resolved
- [ ] **Runbook tested in a drill** — within the current quarter, not when incident strikes
- [ ] **README section added** — link to runbook from team's on-call repo
- [ ] **Secrets checked** — no passwords, API keys, or tokens in commands; use env vars
- [ ] **Reviewed by secondary on-call** — fresh eyes catch assumptions

## Anti-Patterns

| Anti-pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Steps that say "fix the issue" | Too vague under pressure | Tell HOW, not what — exact commands |
| Commands with unsubstituted variables | Copy-paste fails, engineer wastes time retyping | Every command must run as-is |
| No verification step | Fix might not work, but nobody knows | Add check after every resolution |
| Runbooks >6 months stale | Commands rot, trust erodes, people ignore them | Schedule quarterly review in team calendar |
| Runbooks nobody tested | First test happens during the actual incident | Require one drill per quarter per runbook |
| Too many steps (>15) | Cognitive overload during Sev1 | Split into sub-runbooks, keep shallow |
| No time-boxes | Engineer doesn't know when to escalate | Every diagnosis/resolution step has a max time |
| Single resolution path | Assumes first idea works | Always have Plan B in the same runbook |
| Post-mortem blames people | Blame culture kills incident reporting | "What broke the system?" not "Who broke it?" |
| Skipping customer comms | Stakeholders hear "we're down" from social media | Draft customer email as part of template |

## Incident Timeline Template

```
[HH:MM] Alert triggered: <alert name> from <monitoring system>
[HH:MM] On-call acknowledged: <name>
[HH:MM] War room opened: <Slack channel/Zoom link>
[HH:MM] Initial diagnosis: <symptoms observed>
[HH:MM] Impact confirmed: <users affected, services degraded>
[HH:MM] Mitigation applied: <action taken>
[HH:MM] Monitoring confirms recovery
[HH:MM] All-clear declared
[HH:MM+1] Post-mortem scheduled: <date>
```

## Post-Mortem Template

```
# Incident Post-Mortem: <title>
Date: YYYY-MM-DD | Duration: Xh Ym | Severity: Sev1/2/3

## Timeline
[HH:MM] ...

## Root Cause
What system/process failure caused this.

## Impact
Users affected, data loss, revenue impact.

## Detection
How was this found? (alert, user report, manual)

## Resolution
What fixed it.

## Action Items
| # | Action | Owner | Due |
|---|--------|-------|-----|

## Lessons Learned
What would prevent this next time.
```

## Sources

- Google SRE Book: "Monitoring Distributed Systems"
- Google SRE Workbook: Incident Response
- PagerDuty incident response documentation
- Atlassian post-mortem best practices
- Microsoft SRE practices
- AWS Well-Architected Framework: Operational Excellence

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources

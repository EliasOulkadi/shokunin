---
name: ci-cd
description: Design CI/CD pipelines for GitHub Actions, GitLab CI, and CircleCI with matrix builds, test sharding, caching, Docker layer caching, OIDC auth, deployment strategies (rolling, blue-green, canary), auto-rollback, self-hosted runners, and environment protection with manual approvals. Use when user asks to set up CI/CD, write a pipeline, configure GitHub Actions/GitLab CI/CircleCI, automate deployments, or set up build/test/deploy workflows. Do NOT use for Dockerfile authoring (use docker), K8s manifests (use kubernetes), or Terraform config (use terraform).
triggers:
  - "CI/CD pipeline"
  - "GitHub Actions"
  - "GitLab CI"
  - "CircleCI"
  - "continuous integration"
  - "continuous deployment"
  - "build pipeline"
  - "deploy pipeline"
  - "automate build"
  - "automate deploy"
  - "test pipeline"
  - "CI workflow"
negatives:
  - "Dockerfile"
  - "Terraform"
  - "Kubernetes manifest"
  - "infrastructure provisioning"
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "3.0.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---


# CI/CD Architect

Design fast, reliable, and secure CI/CD pipelines across GitHub Actions, GitLab CI, and CircleCI. Follows Google's DevOps capabilities and DORA metrics.

## Decision Framework

Before building a CI/CD pipeline, answer:
- Where is the code hosted? → If GitHub, start with GitHub Actions. If GitLab, use GitLab CI. On-prem? Consider self-hosted.
- What's the deployment target? → Cloud (use OIDC), on-prem (use self-hosted runner), multi-cloud (use environment-specific jobs)
- Is the team size 1-3? → Simple single-workflow. 10+? → Separate build, test, deploy workflows with artifact passing.
- Do you need matrix builds (multiple OS/versions)? → Yes for libraries, no for single-platform apps.
- Is the deploy target production? → Require manual approval gates. Non-prod: automatic on merge.

## Workflow

### Step 1: Choose platform

| Platform | Best for | Config location |
|----------|----------|----------------|
| GitHub Actions | OSS, GitHub ecosystem | `.github/workflows/*.yml` |
| GitLab CI | Self-hosted, monorepos | `.gitlab-ci.yml` |
| CircleCI | Performance, Docker | `.circleci/config.yml` |

**Decision**: If the project is on GitHub.com, use GitHub Actions. If self-hosted GitLab, use GitLab CI. If maximum performance needed, use CircleCI.

### Step 2: Generate pipeline

Use the scaffold script with your platform and stack:
```bash
scripts/generate-pipeline.sh --platform github --language node --e2e --docker
scripts/generate-pipeline.sh --platform gitlab --language python --docker
scripts/generate-pipeline.sh --platform circle --language go --e2e
```

This generates a production-ready pipeline with:
- Lint → typecheck → test (sharded) → build → docker → deploy
- Caching (npm/pip/go, Docker layers)
- OIDC auth (no static secrets)
- Environment gates (staging → production)

### Step 3: Configure caching

| Cache type | GitHub Actions | GitLab CI | CircleCI |
|-----------|---------------|-----------|----------|
| npm/pip/go | `actions/cache` with lockfile hash | `cache:key:` with lockfile hash | `save_cache` / `restore_cache` |
| Docker layers | `docker/build-push-action` GHA cache | Docker layer caching on self-hosted | Remote Docker engine cache |
| Playwright browsers | `npx playwright install chromium` | `before_script` cache | Custom Docker image with browsers |
| Build artifacts | `upload-artifact` / `download-artifact` | `artifacts:` section | `persist_to_workspace` |

**If the build is consistently >15 min**: add more shards or parallelize independent jobs.

#### Test sharding

```yaml
# GitHub Actions: split tests across N parallel runners
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx vitest --shard=${{ matrix.shard }}/${{ strategy.job-total }}
```

In GitLab CI, use the `parallel:` key: `parallel: 4` and `CI_NODE_INDEX` / `CI_NODE_TOTAL` env vars.

**Decision**: Use sharding when test suite >5 min. Start with 2 shards, increase until each shard runs in <3 min. For Playwright, shard by spec file weight with `playwright test --shard=$CI_NODE_INDEX/$CI_NODE_TOTAL`.

#### Monorepo strategies

| Pattern | Trigger rule | Cache key |
|---------|-------------|-----------|
| Path-based | `paths: ['packages/web/**']` (GHA) / `rules:changes:` (GitLab) | `${{ hashFiles('packages/web/package-lock.json') }}` |
| Label-based | `if: contains(github.event.pull_request.labels.*.name, 'web')` | Per-package cache restore |
| Full rebuild | Monorepo tools (Nx, Turborepo) use their own remote caching | N/A — tool-managed |

For large monorepos, use **Nx** or **Turborepo** for task orchestration. Let the tool handle `--since`, affected projects, and remote cache. Reference the tool's CI recipe — don't hand-roll matrix logic when the tool already solves it.

#### Environment protection rules

```yaml
# GitHub Actions — manual approval gate before production
deploy-prod:
  needs: [deploy-staging]
  environment:
    name: production
    # Enforces: required reviewers, wait timer, restricted branches, deployment history
  steps: [...]
```

- **Required reviewers**: Minimum 2 for production, 1 for staging
- **Wait timer**: Force 5-minute buffer before deploy (catch last-minute reverts)
- **Deployment branches**: Only `main` or `release/*` can trigger production
- **Auto-inactive**: Mark deployments inactive after 30 days, prevent stale environment clutter
- **GitLab equivalent**: `environment: production` with `deploy: free` or protected environments
- **CircleCI equivalent**: `approval` job type with restricted contexts

#### Secret rotation

Never store long-lived secrets in CI/CD. Prefer:

1. **OIDC (preferred)**: No secrets at all — federated identity with short-lived tokens
2. **Short-lived credentials**: Clouds offer 1-hour max tokens via OIDC
3. **Secret rotation schedule**: Rotate all static secrets every 90 days, documented in playbook
4. **CI/CD secret scanning**: Enable GitHub secret scanning push protection or GitLab secret detection

For legacy systems requiring static secrets, store them only in the CI/CD platform's encrypted variables (not in repo), audit access via audit logs, and set expiration reminders via automation.

### Step 4: Set up OIDC (no static secrets)

```yaml
# GitHub Actions
permissions:
  id-token: write
  contents: read
steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456:role/github-actions
      aws-region: us-east-1
```

### Step 5: Configure deployment strategy

See [references/deployment-strategies.md](references/deployment-strategies.md) for full details.

| Strategy | Rollback | Use when |
|----------|----------|----------|
| Rolling update | Manual (undo) | Stateless apps |
| Blue-green | Instant (LB switch) | Zero-downtime required |
| Canary | Gradual (traffic % adjust) | High-risk, gradual rollout |

**Always implement healthcheck verification after deploy:**
```yaml
- name: Healthcheck
  run: |
    for i in {1..30}; do
      STATUS=$(curl -so /dev/null -w '%{http_code}' https://app.example.com/health)
      if [ "$STATUS" = "200" ]; then exit 0; fi
      sleep 2
    done
    echo "Healthcheck failed, rolling back..."
    kubectl rollout undo deployment/app
    exit 1
```

### Step 6: Set up self-hosted runners (if needed)

See [references/self-hosted-runners.md](references/self-hosted-runners.md) for K8s runners, autoscaling, caching, and security configurations.

**Decision**: Use GitHub-hosted runners for standard builds. Self-hosted if you need:
- Custom hardware (GPU, large memory)
- Docker-in-Docker performance
- Private network access

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `Resource not accessible by integration` | Missing `permissions:` block in GHA workflow | Add `permissions: contents: read, id-token: write` at job or workflow level |
| `fatal: unable to access ... The requested URL returned error: 403` | Expired or missing git credentials | Use `actions/checkout` with `token: ${{ secrets.GITHUB_TOKEN }}` or deploy key |
| `Error response from daemon: manifest for ... not found` | Docker image tag doesn't exist in registry | Verify tag was built and pushed; check registry path matches exactly |
| `Job failed: runner disconnected` | Self-hosted runner crashed or network flaked | Add `timeout-minutes` per job, configure runner auto-restart, use spot instance rebalancing |
| `No space left on device` | Build artifacts filling runner disk | Add cleanup step: `rm -rf /tmp/*` or use `actions/upload-artifact` with retention; reduce Docker image size |
| `deploy job requires a unique deployment_id` | Concurrent deploys to same environment | Add `concurrency: group: ${{ github.workflow }}-${{ github.ref }}` to prevent race conditions |
| `Cache not found` (restore) / `Cache already exists` (save) | Cache key mismatch or cache hit on locked key | Use `restore-keys` fallback for partial matches; include `hashFiles('lockfile')` in primary key |
| OIDC token fetch failed | Missing `id-token: write` permission or IAM trust relationship misconfigured | Verify IAM trust policy allows `token.actions.githubusercontent.com` + correct repo/subject claim |

## Production Checklist

- [ ] Lint + typecheck before tests
- [ ] Tests parallelized (matrix/sharding)
- [ ] Build artifacts cached or uploaded
- [ ] Docker build uses layer caching
- [ ] Plan/apply separation for IaC
- [ ] Production deployment requires manual approval
- [ ] Concurrency prevents simultaneous deploys
- [ ] OIDC auth (no static cloud keys)
- [ ] Rollback tested and documented
- [ ] Notifications on failure (Slack/Discord/email)
- [ ] Build time under 15 min

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| `terraform apply` from laptop | CI/CD with plan/apply separation |
| Deploying from `latest` tag | Use commit SHA or semver |
| No cache | Cache deps, Docker layers, artifacts |
| Sequential tests | Parallel matrix or sharding |
| Static cloud creds in secrets | OIDC or short-lived tokens |
| Secrets in pipeline YAML | CI/CD secret variables |
| Monolithic job | Split: lint → test → build → deploy |
| No healthcheck after deploy | Auto-rollback on failure |
| Deploy on every main push | Gated approval + environment protection |

## Pipeline Review Format (Required)

When reviewing CI/CD pipelines, use Before | After | Why format:

| Before | After | Why |
|--------|-------|-----|
| Static cloud credentials in secrets | OIDC with `id-token: write` permission | Static credentials never expire. OIDC issues short-lived tokens per workflow run. |
| Sequential test jobs | Matrix build + test sharding (`strategy: matrix: shard: [1/4, 2/4, 3/4, 4/4]`) | Sequential tests bottleneck the pipeline. Sharding parallelizes across runners. |
| `terraform apply` from laptop | CI plan → manual approval → CI apply | Laptop applies bypass audit trail and state locking. CI enforces process. |
| No cache on dependencies | `actions/cache` for `node_modules/`, `pip cache`, `go mod cache` | Uncached dependencies add 2-5 minutes per run. Caching cuts this to seconds. |

## Matrix Build Optimization

```yaml
# GitHub Actions: parallel test shards
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx vitest --shard=${{ matrix.shard }}/${{ strategy.job-total }}

# Parallel OS/version testing
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20, 22]
```

## Canary Deployment with Flagger

```yaml
# Canary resource (Flagger CRD)
apiVersion: flagger.app/v1beta1
kind: Canary
spec:
  service: myapp
  analysis:
    interval: 30s; threshold: 5; maxWeight: 50; stepWeight: 10
    metrics:
    - name: request-success-rate; threshold: 99
    - name: request-duration; threshold: 500
```

Flow: deploy canary (10% traffic) → analyze metrics → if healthy, increase to 20%, 30%, 50% → promote to 100%.

## Pipeline Approval Gates

```yaml
# GitHub Environments with protection rules
deploy-prod:
  needs: deploy-staging
  environment: production
  steps: [ - run: ./deploy.sh ]

# Environment settings (GitHub UI):
# - Required reviewers: 2
# - Wait timer: 0 minutes
# - Deployment branches: main only
```

## Sources

- GitHub Actions docs (docs.github.com/actions)
- GitLab CI docs (docs.gitlab.com/ee/ci)
- CircleCI docs (circleci.com/docs)
- DORA metrics (Google Cloud DevOps)
- Docker BuildKit cache type
- AWS IAM OIDC identity providers
- Flagger documentation (flagger.app)

## Pre-Deploy Checklist

Before merging to production:

- [ ] All tests pass (unit, integration, E2E)
- [ ] Security scan passes (no HIGH/CRITICAL vulnerabilities)
- [ ] Lint and type checks pass with zero errors
- [ ] Build artifact produced and validated
- [ ] Deploy plan reviewed (IaC plan output, migration plan)
- [ ] Rollback plan documented and tested
- [ ] Environment protection rules active (require approvals for production)
- [ ] Concurrency control enabled (prevent simultaneous deploys)
- [ ] Healthcheck endpoint verified post-deploy
- [ ] Monitoring alerts configured for the new version
- [ ] Database migrations tested with a copy of production data

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources

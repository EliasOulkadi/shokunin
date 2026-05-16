---
name: ci-cd
description: Design CI/CD pipelines for GitHub Actions, GitLab CI, and CircleCI with matrix builds, test sharding, caching, Docker layer caching, OIDC auth, deployment strategies (rolling, blue-green, canary), auto-rollback, self-hosted runners, and environment protection with manual approvals. Use when user asks to set up CI/CD, write a pipeline, configure GitHub Actions/GitLab CI/CircleCI, automate deployments, or set up build/test/deploy workflows. Do NOT use for Dockerfile authoring (use docker), K8s manifests (use kubernetes), or Terraform config (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---

# CI/CD Architect

Design fast, reliable, and secure CI/CD pipelines across GitHub Actions, GitLab CI, and CircleCI. Follows Google's DevOps capabilities and DORA metrics.

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

## Sources

- GitHub Actions docs (docs.github.com/actions)
- GitLab CI docs (docs.gitlab.com/ee/ci)
- CircleCI docs (circleci.com/docs)
- DORA metrics (Google Cloud DevOps)
- Docker BuildKit cache type
- AWS IAM OIDC identity providers
- Flagger documentation (flagger.app)

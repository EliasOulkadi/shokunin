---
name: ci-cd
description: Design CI/CD pipelines for build, test, and deploy. Covers GitHub Actions, GitLab CI, pipeline patterns (plan/apply separation, matrix builds, sharding, environments, approvals), Docker build optimization, parallel jobs, caching strategies, artifact management, and deployment strategies (rolling, blue-green, canary). Use when user asks to set up CI/CD, write a pipeline, configure GitHub Actions, GitLab CI, automate deployments, or set up build/test/deploy workflows. Triggers on "CI/CD", "pipeline", "GitHub Actions", "GitLab CI", "continuous deployment", "automated build", "deploy", "workflow", "runner". Do NOT use for Dockerfiles, Kubernetes manifests, or Terraform config — those have their own skills.
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: developers
---

Design CI/CD pipelines for build, test, and deploy across GitHub Actions and GitLab CI.

## Workflow

### Step 1: Determine the platform

| Platform | Config file | Runner |
|----------|-------------|--------|
| GitHub Actions | `.github/workflows/*.yml` | GitHub-hosted or self-hosted |
| GitLab CI | `.gitlab-ci.yml` | GitLab shared runners or self-managed |

### Step 2: Define the pipeline stages

Standard stages: `lint → build → test → deploy`

### Step 3: Security

- No secrets in pipeline config — use CI secrets/variables
- Plan/apply separation (plan on PR, apply on merge to main)
- Required reviews before production deployment
- No `latest` tags in deployment

## GitHub Actions

### Standard CI pipeline
```yaml
name: CI
on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: 22
  REGISTRY: ghcr.io/${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "${{ env.NODE_VERSION }}" }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    needs: [lint]
    strategy:
      matrix:
        shard: [1/3, 2/3, 3/3]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "${{ env.NODE_VERSION }}" }
      - run: npm ci
      - run: npx playwright install chromium
      - run: npm test -- --shard=${{ matrix.shard }}
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-results-${{ matrix.shard }}
          path: test-results/

  build:
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/

  docker:
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with: { registry: ${{ env.REGISTRY }} }
      - run: |
          docker buildx build \
            --cache-from=type=gha \
            --cache-to=type=gha,mode=max \
            --tag $REGISTRY/app:${{ github.sha }} \
            --tag $REGISTRY/app:latest \
            --push .
```

### Deployment with environment protection
```yaml
deploy-staging:
  runs-on: ubuntu-latest
  needs: [docker]
  environment: staging
  steps:
    - run: |
        echo "Deploying ${{ github.sha }} to staging"
        # kubectl set image, helm upgrade, etc.

deploy-production:
  runs-on: ubuntu-latest
  needs: [deploy-staging]
  environment:
    name: production
    url: https://app.example.com
  steps:
    - run: |
        echo "Deploying ${{ github.sha }} to production"
```

### Concurrency control (prevent simultaneous applies)
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## GitLab CI

```yaml
image: node:22-slim

stages: [lint, test, build, deploy]

cache:
  key: $CI_COMMIT_REF_SLUG
  paths: [node_modules/]

lint:
  stage: lint
  script:
    - npm ci
    - npm run lint
    - npm run typecheck

test:
  stage: test
  parallel: 3
  script:
    - npm ci
    - npx playwright install chromium
    - npm test -- --shard=$CI_NODE_INDEX/$CI_NODE_TOTAL

build:
  stage: build
  script:
    - npm ci
    - npm run build
  artifacts:
    paths: [dist/]
    expire_in: 1 hour

deploy-staging:
  stage: deploy
  script: ./deploy.sh staging
  environment: { name: staging }
  only: [main]

deploy-production:
  stage: deploy
  script: ./deploy.sh production
  environment:
    name: production
    url: https://app.example.com
  when: manual
  only: [main]
```

## Cache Strategies

| Cache type | GitHub Actions | GitLab CI |
|-----------|---------------|-----------|
| npm/yarn | `actions/cache` with hash of package-lock | `cache:key: $CI_COMMIT_REF_SLUG` |
| Docker layers | `docker/build-push-action` with `cache-from=type=gha` | Docker layer caching on self-hosted runners |
| Playwright browsers | Store in cache or `npx playwright install chromium` | Same, included in CI image |
| Build artifacts | `actions/upload-artifact` / `download-artifact` | `artifacts:` section |

## Deployment Strategies

| Strategy | Uptime | Rollback | Complexity |
|----------|--------|----------|------------|
| Rolling update | ✅ | Manual | Low |
| Blue-green | ✅ | Instant | Medium |
| Canary | ✅ | Gradual | High |

### Blue-green (conceptual)
```
# Deploy version 2 alongside version 1
# Both receive traffic after smoke tests pass
# Switch load balancer from green to blue
# If issues, switch back (instant rollback)
```

## Docker Build Optimization in CI

```yaml
- uses: docker/setup-buildx-action@v3
- run: |
    docker buildx build \
      --cache-from=type=gha \
      --cache-to=type=gha,mode=max \
      --tag app:${{ github.sha }} \
      --push .
```

## Production Checklist

- [ ] Lint + typecheck run before tests
- [ ] Tests run in parallel (matrix/sharding)
- [ ] Build artifacts cached or uploaded
- [ ] Docker build uses layer caching (GitHub Actions `cache-from=type=gha`)
- [ ] Plan/apply separation (plan on PR, apply on merge)
- [ ] Production deployment requires manual approval
- [ ] Concurrency prevents simultaneous deployments
- [ ] Secrets stored in CI variables, never in code
- [ ] Rollback documented and tested
- [ ] Notifications on failure (Slack, Discord, email)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Running `terraform apply` from a laptop | CI/CD with saved plan files |
| Deploying from `latest` tag | Use commit SHA or semantic version |
| No cache | Cache npm, Docker layers, build artifacts |
| Sequential test execution | Parallel matrix or sharding |
| No environment protection | Required reviewers for production |
| Secrets hardcoded in pipeline | CI/CD secret variables |
| Monolithic pipeline (one job for everything) | Split into stages: lint → test → build → deploy |

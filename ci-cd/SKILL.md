---
name: ci-cd
description: Design CI/CD pipelines for GitHub Actions, GitLab CI, and CircleCI with caching, matrix builds, sharding, environments, approvals, rollback automation, and deployment strategies (rolling, blue-green, canary). Use when user asks to set up CI/CD, write a pipeline, configure GitHub Actions, GitLab CI, CircleCI, automate deployments, or set up build/test/deploy workflows. Do NOT use for Dockerfiles (use docker), Kubernetes manifests (use kubernetes), or Terraform config (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "2.0"
---

# CI/CD Architect

Design pipelines that are fast, reliable, and secure across GitHub Actions, GitLab CI, and CircleCI.

## Workflow

### Step 1: Choose platform

| Platform | Best for | Config file | Secrets |
|----------|----------|-------------|---------|
| GitHub Actions | Open-source, GitHub-centric | `.github/workflows/*.yml` | Settings → Secrets → Actions |
| GitLab CI | Self-hosted, monorepos | `.gitlab-ci.yml` | Settings → CI/CD → Variables |
| CircleCI | Performance, parallelism | `.circleci/config.yml` | Project Settings → Environment Variables |

### Step 2: Define pipeline stages

Standard: `lint → build → test → docker → deploy`

### Step 3: Write pipeline

## GitHub Actions

### Standard CI

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
    - run: echo "Deploying ${{ github.sha }} to staging"

deploy-production:
  runs-on: ubuntu-latest
  needs: [deploy-staging]
  environment:
    name: production
    url: https://app.example.com
  steps:
    - run: echo "Deploying ${{ github.sha }} to production"
```

### Auto-rollback on healthcheck failure

```yaml
deploy-production:
  runs-on: ubuntu-latest
  environment: production
  steps:
    - run: |
        kubectl set image deployment/app app=$REGISTRY/app:${{ github.sha }}
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

### Concurrency control

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### OIDC for cloud auth (no static secrets)

```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456:role/github-actions
          aws-region: us-east-1
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
  environment: { name: production, url: https://app.example.com }
  when: manual
  only: [main]
```

## CircleCI

```yaml
version: 2.1
orbs:
  node: circleci/node@7
  docker: circleci/docker@3

workflows:
  ci:
    jobs:
      - lint
      - test:
          matrix:
            parameters:
              shard: [1/3, 2/3, 3/3]
      - build:
          requires: [lint, test]
      - deploy-staging:
          requires: [build]
          filters: { branches: { only: [main] } }
      - deploy-production:
          type: approval
          requires: [deploy-staging]
          filters: { branches: { only: [main] } }

jobs:
  lint:
    docker: [{ image: cimg/node:22.0 }]
    steps:
      - checkout
      - node/install-packages
      - run: npm run lint
      - run: npm run typecheck

  test:
    docker: [{ image: cimg/node:22.0 }]
    parameters:
      shard: string
    steps:
      - checkout
      - node/install-packages
      - run: npx playwright install chromium
      - run: npm test -- --shard=<< parameters.shard >>

  build:
    docker: [{ image: cimg/node:22.0 }]
    steps:
      - checkout
      - node/install-packages
      - run: npm run build
      - persist_to_workspace: { root: ., paths: [dist/] }

  deploy-staging:
    docker: [{ image: cimg/node:22.0 }]
    steps:
      - attach_workspace: { at: . }
      - run: ./deploy.sh staging
```

## Runners

| Type | Use when | Cost | Maintenance |
|------|----------|------|-------------|
| GitHub-hosted | Standard builds, open-source | Included | None |
| Self-hosted (Linux) | Custom hardware, caching | Infrastructure | Medium |
| Self-hosted (Kubernetes) | Dynamic scaling, multi-arch | Infrastructure | High |
| GitLab shared | GitLab users | Included | None |
| CircleCI Docker | Standard builds | Compute credits | None |

### Self-hosted runner setup (GitHub Actions)

```yaml
runs-on: [self-hosted, linux, x64]
```

Add labels for routing:
```yaml
runs-on: [self-hosted, gpu, large]
```

## Cache Strategies

| Cache type | GitHub Actions | GitLab CI | CircleCI |
|-----------|---------------|-----------|----------|
| npm/yarn | `actions/cache` with lockfile hash | `cache:key:` with lockfile hash | `save_cache` / `restore_cache` |
| Docker layers | `docker/build-push-action` with GHA cache | Docker layer caching on self-hosted | Docker layer caching on remote Docker |
| Build artifacts | `upload-artifact` / `download-artifact` | `artifacts:` section | `persist_to_workspace` |
| Playwright browsers | Cache or `npx playwright install` | `before_script` cache | Custom Docker image with browsers |

## Deployment Strategies

| Strategy | Uptime | Rollback | Complexity | Use case |
|----------|--------|----------|------------|----------|
| Rolling update | ✅ | Manual | Low | Stateless apps, simple |
| Blue-green | ✅ | Instant (switch LB) | Medium | Critical services, zero-downtime required |
| Canary | ✅ | Gradual (traffic % adjust) | High | High-risk changes, gradual rollout |

### Blue-green deployment

```
1. Deploy v2 alongside v1 (different target group/ASG)
2. Run smoke tests against v2
3. Switch load balancer target from v1 to v2
4. Monitor for 15 min
5. If issues: switch back to v1 (instant rollback)
6. If healthy: terminate v1
```

### Canary release

```
1. Deploy v2 (5% traffic)
2. Monitor errors + latency for 10 min
3. Increase to 25% traffic
4. Monitor again
5. Increase to 50%
6. If healthy: 100%. If issues: route remaining to v1.
```

## Production Checklist

- [ ] Lint + typecheck before tests
- [ ] Tests run in parallel (matrix/sharding)
- [ ] Build artifacts cached or uploaded
- [ ] Docker build uses layer caching
- [ ] Plan/apply separation (plan on PR, apply on merge)
- [ ] Production deployment requires manual approval
- [ ] Concurrency prevents simultaneous deployments
- [ ] Secrets in CI variables, never in code
- [ ] OIDC for cloud auth (not static keys)
- [ ] Rollback tested and documented
- [ ] Notifications on failure (Slack, Discord, email)
- [ ] Build time under 15 min (split if exceeding)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Running `terraform apply` from laptop | CI/CD with saved plan files |
| Deploying from `latest` tag | Use commit SHA or semantic version |
| No cache | Cache npm, Docker layers, build artifacts |
| Sequential tests | Parallel matrix or sharding |
| Static cloud credentials | OIDC or short-lived tokens |
| Secrets hardcoded in pipeline | CI/CD secret variables |
| Monolithic job | Split into stages: lint → test → build → deploy |
| No healthcheck after deploy | Auto-rollback on failed healthcheck |
| Deploy on every push to main | Gated approval + environment protection |

## Sources

- GitHub Actions Documentation (docs.github.com/actions)
- GitLab CI Documentation (docs.gitlab.com/ee/ci)
- CircleCI Documentation (circleci.com/docs)
- Docker Build Cache — GitHub Actions cache type
- AWS IAM OIDC Identity Providers
- Kubernetes Deployment Strategies
- Twelve-Factor App — Build, release, run

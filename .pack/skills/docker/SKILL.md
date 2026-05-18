---
name: docker
description: Optimize Docker images with multi-stage builds, distroless bases, BuildKit cache mounts, multi-arch builds, compose watch, security hardening (non-root, seccomp, capabilities drop), and vulnerability scanning via docker scout/trivy. Use when user asks to write a Dockerfile, optimize image size, set up docker-compose, debug containers, harden container security, or scan for CVEs. Do NOT use for Kubernetes deployments (use kubernetes), CI/CD pipeline design (use ci-cd), or Terraform (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write
---

# Docker Architect

Production-grade Dockerfiles, multi-stage builds, cache optimization, security scanning, and local development. Applies Google's distroless philosophy and Docker BuildKit best practices.

## Decision Framework

Before containerizing, answer:
- Does the app need process isolation? → Docker
- Will it deploy to Kubernetes? → Docker + distroless + non-root
- Is it a monolith with simple deployment? → Docker Compose
- Is it a static site? → Consider nginx:alpine single-stage
- Is the team already using Docker Compose in dev? → Start there, add K8s when needed
- Is the app latency-sensitive (sub-ms)? → Bare metal or VM; container overhead matters at extreme scale

## Workflow

### Quick start: `docker init`

For new projects, run `docker init` in the project root. It auto-detects the language/framework and generates a Dockerfile, `.dockerignore`, and `compose.yaml` with best-practice defaults. Always review and harden the output — the generated files are a starting point, not production-ready.

### Step 1: Identify stack and choose template

| Stack | Base image | Build stage | Runtime |
|-------|-----------|-------------|---------|
| Node.js | node:22-slim | Full SDK | gcr.io/distroless/nodejs |
| Go | golang:1.23-alpine | Full SDK | scratch |
| Python | python:3.12-slim | Full SDK | python:3.12-slim |
| Rust | rust:1.78-slim | Full SDK | gcr.io/distroless/cc |

**Decision**: If the stack is listed above, use the corresponding production Dockerfile below. If not, apply the golden template in Step 2.

### Step 2: Apply golden template

Use multi-stage with this exact structure:
```
Stage 1 (deps):   COPY lock files → install production deps (--mount=type=cache)
Stage 2 (build):  COPY source → compile
Stage 3 (runtime): minimal base → COPY artifacts from stages 1-2 → USER nonroot → HEALTHCHECK
```

**If the project is a Go binary**, skip Stage 1 (Go has no runtime deps) and go straight to Stage 2.

**If the project has native dependencies** (node-gyp, C extensions), use `apt-get` in the builder stage, NOT the runtime stage.

### Step 3: Apply BuildKit optimizations

```dockerfile
# syntax=docker/dockerfile:1.4
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY src ./src
RUN npm run build

FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
EXPOSE 3000
USER nonroot
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["node", "-e", "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1))"]
CMD ["dist/index.js"]
```

Run `scripts/optimize-dockerfile.sh` on any existing Dockerfile to receive optimization suggestions.

### Step 4: Configure compose for local dev

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    develop:
      watch:
        - action: sync+restart
          path: ./src
          target: /app/src
    depends_on: [db]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  db:
    image: postgres:16-alpine
    volumes: ["pgdata:/var/lib/postgresql/data"]
volumes: { pgdata: }
```

Run `docker compose watch` for hot-reload.

See [assets/docker-compose.template.yml](assets/docker-compose.template.yml) for the full template with all services.

### Step 5: Build for multiple platforms

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from=type=gha \
  --cache-to=type=gha,mode=max \
  --tag registry/app:latest \
  --push .
```

See [references/multi-arch.md](references/multi-arch.md) for QEMU setup and platform-specific optimizations.

### Step 6: Scan for vulnerabilities

```bash
# Using the provided script
scripts/scan-image.sh registry/app:latest

# Or manually:
docker scout cves registry/app:latest
trivy image registry/app:latest
```

**If critical CVEs are found**: either switch base image (e.g., distroless), or add apt-get to install patched deps in builder stage.

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `failed to solve with frontend dockerfile.v0` | Missing syntax directive | Add `# syntax=docker/dockerfile:1.4` as first line |
| `exec /usr/bin/node: exec format error` | Wrong platform | Build with `--platform linux/amd64` matching the target |
| `permission denied` at runtime | Missing `USER nonroot` or wrong file permissions | Add `USER nonroot` and `COPY --chown=nonroot:nonroot` |
| Layer cache miss every build | Changing files copied before lock files | Always `COPY package.json` BEFORE source code |
| `docker compose watch` not working | Docker Engine < 24 | Upgrade Docker Engine or use `docker compose up --watch` |

## Pre-Flight Checklist

Before deploying a Docker image:

- [ ] `.dockerignore` exists and excludes `node_modules/`, `.git/`, `.env*`, `Dockerfile*`, `*.log`
- [ ] Multi-stage build with separate build and runtime stages
- [ ] Runtime stage uses distroless or minimal base (`node:22.14-slim`, not `node:22`)
- [ ] `USER nonroot` (or equivalent) — never runs as root
- [ ] `HEALTHCHECK` defined with appropriate interval
- [ ] Secrets use `--mount=type=secret`, never `ENV` or `ARG`
- [ ] `npm ci --omit=dev` (or language equivalent) for production dependencies
- [ ] `docker scout quickview` or `trivy image` scan passes with zero HIGH/CRITICAL CVEs
- [ ] Image size verified: `docker images --format "{{.Size}}"` — should be <200MB for most apps
- [ ] `docker compose watch` tested in development (sync+restart for code changes)
- [ ] Container starts and passes healthcheck within 30 seconds
- [ ] Logs go to stdout/stderr (no log files inside container)
- [ ] `docker compose down` and `docker compose up` successfully recreates from scratch

## Anti-Patterns

| Pattern | Problem | Fix | Because |
|---------|---------|-----|---------|
| Single-stage build | Final image contains build tools, SDKs, source code — 5x larger | Multi-stage: build stage → distroless runtime | Every tool in the image is an attack surface. Minimize blast radius. |
| `COPY . .` before `npm install` | Cache miss on every code change, full rebuild | Copy package files first, install deps, then copy source | Docker caches by layer. Source changes should invalidate only the last COPY. |
| `latest` tag | Image changes silently on pull | Pin full version tag (`22.14-slim`, not `22-slim`) | `latest` means "whatever was pushed last". A patch update can break your app. |
| Root user in container | Compromised process = host root access | `USER nonroot` with distroless or `RUN useradd` | Container escape bugs exist. Non-root limits damage to the container. |
| Secrets in build args | `docker history` reveals them. BuildKit `--secret` exists for this | `RUN --mount=type=secret` in BuildKit | Build args are stored in image metadata. Anyone with image access can extract them. |
| No `.dockerignore` | Copies `.env`, `.git/`, `node_modules/` into build context | Add `.dockerignore` with common exclusions | 200MB of node_modules in build context = slow builds + potential secret leaks. |
| No healthcheck | Orchestrator can't detect app failures | `HEALTHCHECK --interval=30s CMD curl -f http://localhost/health` | Without healthcheck, Swarm/K8s only detects process crashes, not app hangs. |
| `npm install` in production | Installs devDependencies (testing frameworks, linters, TypeScript) | `npm ci --omit=dev` or `npm ci --production` | Dev deps add 100-200MB to the image. They also increase CVEs from unused packages. |
| Pinning only major version (`22-slim`) | Can auto-update to a new minor version that breaks your app | Pin to exact version (`22.14-slim`) or use digest pinning | Reproducibility: the same Dockerfile should produce the same image every time. |
| Multi-stage with wrong base | Runtime stage uses node instead of distroless | Use `gcr.io/distroless/nodejs22-debian12` or `node:22.14-slim` | Distroless removes shells, package managers, and utilities — nothing for an attacker to exploit. |

## Review Format (Required)

When reviewing Dockerfiles, use Before | After | Why format:

| Before | After | Why |
|--------|-------|-----|
| `FROM node:22-slim` | `FROM node:22.14-slim@sha256:abc...` | Floating tags (`22-slim`) auto-update. Pin to immutable digest for reproducibility. |
| `COPY . .` before `npm ci` | `COPY package*.json ./` then `npm ci` then `COPY . .` | Docker caches each COPY layer. Copying source before deps invalidates cache on every code change. |
| `CMD ["npm", "start"]` | Use `node server.js` directly | Avoids npm overhead in production. Use process manager (dumb-init, tini) for signal forwarding. |
| No `.dockerignore` | `.dockerignore` with `node_modules/`, `.git/`, `*.log`, `Dockerfile*` | Reduces build context size by 60-90%. Prevents leaking secrets from local `.env`. |

## Sources

- Dockerfile best practices (docs.docker.com)
- BuildKit documentation
- Google distroless images
- Trivy vulnerability scanner
- Docker Scout documentation
- SLSA framework (slsa.dev)

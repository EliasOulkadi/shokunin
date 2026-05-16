# Multi-Architecture Builds with Docker Buildx

Build images for `linux/amd64`, `linux/arm64`, `linux/arm/v7`, and `windows/amd64` from a single Dockerfile.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Docker | 24+ | Includes buildx by default |
| QEMU | binfmt\_support | User-mode emulation for cross-arch builds |
| buildx | bundled | `docker buildx` plugin |

## Setup

### 1. Install QEMU (once per host)

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

Verify emulators are registered:

```bash
ls /proc/sys/fs/binfmt_misc/qemu-*
docker buildx ls
# Look for "linux/arm64", "linux/arm/v7" under your builder
```

### 2. Create a buildx builder

```bash
# Create with default driver (supports all platforms)
docker buildx create --name multiarch --driver docker-container --use

# Bootstrap (pulls buildkit image, starts QEMU)
docker buildx inspect --bootstrap

# Verify
docker buildx ls
```

### 3. Optional: Append nodes for native builds

Speed tip — use a remote amd64 node + local arm64 node instead of emulation:

```bash
docker buildx create --name hybrid --use
docker buildx append --name hybrid --node remote-amd64 --driver docker-container ssh://user@amd64-builder
docker buildx append --name hybrid --node local-arm64 --driver docker-container unix:///var/run/docker.sock
```

## Building

### Single manifest, multiple platforms

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag registry.example.com/app:latest \
  --push .
```

Flags explained:

| Flag | Purpose |
|------|---------|
| `--platform` | Comma-separated target platforms |
| `--tag` | Image tag (can repeat for multiple tags) |
| `--push` | Push manifest + blobs to registry |
| `--load` | Load single-platform image to local (only 1 platform) |

### Load locally (single platform)

```bash
docker buildx build --platform linux/arm64 --load --tag app:arm64 .
```

### With provenance attestations (SLSA)

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --attest type=provenance,mode=max \
  --attest type=sbom \
  --tag registry.example.com/app:latest \
  --push .
```

## Platform-Specific Optimizations

### Conditional RUN instructions

Use `TARGETPLATFORM` / `TARGETARCH` / `TARGETVARIANT` build args (automatically set by buildx):

```dockerfile
ARG TARGETARCH

RUN case "$TARGETARCH" in \
    amd64) echo "x86_64-unknown-linux-gnu" > /arch ;; \
    arm64) echo "aarch64-unknown-linux-gnu" > /arch ;; \
    arm)   echo "armv7-unknown-linux-gnueabihf" > /arch ;; \
    esac
```

### Architecture-specific deps

```dockerfile
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    $([ "$TARGETARCH" = "arm64" ] && echo "libarmadillo" || echo "libopenblas-dev")
```

### Go cross-compilation (built-in)

```dockerfile
FROM golang:1.23-alpine AS builder
ARG TARGETOS TARGETARCH
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /app/server .
```

### Node.js (no cross-compile needed)

```dockerfile
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

# Runtime - architecture handled by node base image
FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY dist ./dist
USER nonroot
CMD ["dist/index.js"]
```

### Python native extensions

Pre-build wheels or use `--platform` with pip:

```dockerfile
FROM python:3.12-slim AS builder
ARG TARGETARCH
WORKDIR /app
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user \
    --only-binary=:all: \
    -r requirements.txt
```

## Performance Considerations

### Emulation vs native

| Architecture | Emulation | Native | Speed penalty |
|-------------|-----------|--------|--------------|
| amd64 → arm64 | QEMU user | Apple Silicon, Graviton | ~2–3× slower |
| arm64 → amd64 | QEMU user | Intel/AMD EPYC | ~2× slower |
| arm/v7 | QEMU user | Raspberry Pi 4/5 | ~3–5× slower |

**Recommendation:** Use native builders in CI (GitHub Actions matrix, GitLab runner tags, etc.).

### BuildKit cache across platforms

Cache mounts are **per-platform** — each platform gets its own cache directory:

```bash
# buildx automatically scopes caches per platform
docker buildx build --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=registry.example.com/app:cache \
  --cache-to type=registry,ref=registry.example.com/app:cache,mode=max \
  --push .
```

### Parallel builds

BuildKit builds all platforms in parallel by default. Control concurrency:

```bash
# Limit to 2 concurrent platform builds
docker buildx build --platform linux/amd64,linux/arm64 \
  --set *.platform-timeout=30m \
  --provenance=true \
  .
```

## CI/CD Integration

### GitHub Actions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          platforms: linux/amd64,linux/arm64
          tags: ghcr.io/${{ github.repository }}:latest
          push: true
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### GitLab CI

```yaml
build-multiarch:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  before_script:
    - docker run --privileged --rm tonistiigi/binfmt --install all
    - docker buildx create --name multiarch --use
    - docker buildx inspect --bootstrap
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker buildx build
        --platform linux/amd64,linux/arm64
        --tag $CI_REGISTRY_IMAGE:latest
        --push .
```

## Inspecting Images

```bash
# Show manifest details
docker buildx imagetools inspect registry.example.com/app:latest

# List platforms in a multi-arch image
docker buildx imagetools inspect --raw registry.example.com/app:latest | jq '.manifests[].platform'

# Pull for specific architecture
docker pull --platform linux/arm64 registry.example.com/app:latest

# Run with specific architecture
docker run --platform linux/arm64 --rm registry.example.com/app:latest uname -m
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `exec format error` | Wrong arch for host | Set `--platform` explicitly or rebuild |
| `binfmt_misc` not registered | QEMU not installed | Run `tonistiigi/binfmt --install all` |
| Build hangs on emulated step | QEMU slow + large compile | Use native builder or add `--set *.timeout=60m` |
| `no matching manifest` | Image doesn't exist for platform | Check `docker buildx imagetools inspect` |
| Layer cache miss every build | Cross-platform builds invalidate cache | Use registry cache with `mode=max` |

## References

- [Docker Buildx Docs](https://docs.docker.com/build/buildx/)
- [Multi-platform images](https://docs.docker.com/build/building/multi-platform/)
- [QEMU binfmt](https://www.qemu.org/docs/master/system/invocation.html#hxtool-5)
- [BuildKit cache mounts](https://docs.docker.com/build/cache/)
- [SLSA Provenance](https://slsa.dev/)

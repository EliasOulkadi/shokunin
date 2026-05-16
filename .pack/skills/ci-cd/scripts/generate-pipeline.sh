#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --platform <github|gitlab|circle> --language <lang> [options]

Options:
  --platform    CI/CD platform (github, gitlab, circle)
  --language    Language/framework (node, python, go, rust, docker)
  --node-ver    Node.js version (default: 22)
  --py-ver      Python version (default: 3.12)
  --go-ver      Go version (default: 1.22)
  --registry    Container registry URL (default: ghcr.io/\${{ github.repository }})
  --test-cmd    Test command (default: npm test / pytest / go test / cargo test)
  --build-cmd   Build command (default: npm run build / poetry build / go build / cargo build)
  --lint-cmd    Lint command (default: npm run lint / ruff check / golangci-lint / cargo clippy)
  --deploy      Include deploy stage (default: false)
  --output      Output file (default: stdout)
  --help        Show this help

Examples:
  $(basename "$0") --platform github --language node --deploy
  $(basename "$0") --platform gitlab --language python --py-ver 3.11
  $(basename "$0") --platform circle --language go --deploy
EOF
  exit 0
}

# Defaults
PLATFORM=""
LANGUAGE=""
NODE_VER="22"
PY_VER="3.12"
GO_VER="1.22"
REGISTRY="ghcr.io/\${{ github.repository }}"
TEST_CMD=""
BUILD_CMD=""
LINT_CMD=""
DEPLOY=false
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)    PLATFORM="$2"; shift 2 ;;
    --language)    LANGUAGE="$2"; shift 2 ;;
    --node-ver)    NODE_VER="$2"; shift 2 ;;
    --py-ver)      PY_VER="$2"; shift 2 ;;
    --go-ver)      GO_VER="$2"; shift 2 ;;
    --registry)    REGISTRY="$2"; shift 2 ;;
    --test-cmd)    TEST_CMD="$2"; shift 2 ;;
    --build-cmd)   BUILD_CMD="$2"; shift 2 ;;
    --lint-cmd)    LINT_CMD="$2"; shift 2 ;;
    --deploy)      DEPLOY=true; shift ;;
    --output)      OUTPUT="$2"; shift 2 ;;
    --help)        usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$PLATFORM" || -z "$LANGUAGE" ]]; then
  echo "Error: --platform and --language are required"
  usage
fi

# Language-specific defaults
case "$LANGUAGE" in
  node)
    TEST_CMD="${TEST_CMD:-npm test}"
    BUILD_CMD="${BUILD_CMD:-npm run build}"
    LINT_CMD="${LINT_CMD:-npm run lint}"
    CACHE_PATH="node_modules/"
    CACHE_KEY="npm"
    SETUP_STEPS="steps_setup_node"
    IMAGE="node:${NODE_VER}-slim"
    ;;
  python)
    TEST_CMD="${TEST_CMD:-pytest}"
    BUILD_CMD="${BUILD_CMD:-poetry build}"
    LINT_CMD="${LINT_CMD:-ruff check .}"
    CACHE_PATH=".venv/"
    CACHE_KEY="pip"
    SETUP_STEPS="steps_setup_python"
    IMAGE="python:${PY_VER}-slim"
    ;;
  go)
    TEST_CMD="${TEST_CMD:-go test ./...}"
    BUILD_CMD="${BUILD_CMD:-go build -o bin/app .}"
    LINT_CMD="${LINT_CMD:-golangci-lint run}"
    CACHE_PATH="~/.cache/go-build"
    CACHE_KEY="go"
    SETUP_STEPS="steps_setup_go"
    IMAGE="golang:${GO_VER}-alpine"
    ;;
  rust)
    TEST_CMD="${TEST_CMD:-cargo test}"
    BUILD_CMD="${BUILD_CMD:-cargo build --release}"
    LINT_CMD="${LINT_CMD:-cargo clippy -- -D warnings}"
    CACHE_PATH="target/"
    CACHE_KEY="cargo"
    SETUP_STEPS="steps_setup_rust"
    IMAGE="rust:latest"
    ;;
  docker)
    TEST_CMD="${TEST_CMD:-echo 'No tests defined'}"
    BUILD_CMD="${BUILD_CMD:-docker build -t app:ci .}"
    LINT_CMD="${LINT_CMD:-hadolint Dockerfile}"
    CACHE_PATH=""
    CACHE_KEY="docker"
    SETUP_STEPS="steps_setup_docker"
    IMAGE="docker:latest"
    ;;
  *)
    echo "Error: Unsupported language '$LANGUAGE'. Supported: node, python, go, rust, docker"
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# GitHub Actions
# ---------------------------------------------------------------------------
generate_github() {
  cat <<YAML
name: CI

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

env:
  REGISTRY: ${REGISTRY}

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        uses: actions/setup-node@v4
        with:
          node-version: ${NODE_VER}
          cache: npm
      - run: npm ci
      - run: ${LINT_CMD}

  test:
    runs-on: ubuntu-latest
    needs: [lint]
    strategy:
      matrix:
        shard: [1/3, 2/3, 3/3]
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        uses: actions/setup-node@v4
        with:
          node-version: ${NODE_VER}
          cache: npm
      - run: npm ci
      - run: ${TEST_CMD} -- --shard=\${{ matrix.shard }}
      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-results-\${{ matrix.shard }}
          path: test-results/

  build:
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        uses: actions/setup-node@v4
        with:
          node-version: ${NODE_VER}
          cache: npm
      - run: npm ci
      - run: ${BUILD_CMD}
      - uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/

  docker:
    runs-on: ubuntu-latest
    needs: [build]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - name: Login to registry
        uses: docker/login-action@v3
        with:
          registry: \${{ env.REGISTRY }}
          username: \${{ github.actor }}
          password: \${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          cache-from: type=gha
          cache-to: type=gha,mode=max
          tags: |
            \${{ env.REGISTRY }}/app:\${{ github.sha }}
            \${{ env.REGISTRY }}/app:latest
          push: true
YAML

  if $DEPLOY; then
    cat <<YAML

  deploy-staging:
    runs-on: ubuntu-latest
    needs: [docker]
    environment: staging
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying \${{ github.sha }} to staging"
          # kubectl set image deployment/app app=\${{ env.REGISTRY }}/app:\${{ github.sha }}

  deploy-production:
    runs-on: ubuntu-latest
    needs: [deploy-staging]
    environment:
      name: production
      url: https://app.example.com
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying \${{ github.sha }} to production"
YAML
  fi
}

# ---------------------------------------------------------------------------
# GitLab CI
# ---------------------------------------------------------------------------
generate_gitlab() {
  cat <<YAML
image: ${IMAGE}

stages:
  - lint
  - test
  - build
  - deploy

cache:
  key: \$CI_COMMIT_REF_SLUG
  paths:
    - ${CACHE_PATH}
  policy: pull-push

lint:
  stage: lint
  script:
    - ${LINT_CMD}

test:
  stage: test
  parallel: 3
  script:
    - ${TEST_CMD} -- --shard=\$CI_NODE_INDEX/\$CI_NODE_TOTAL
  artifacts:
    when: on_failure
    paths:
      - test-results/
    expire_in: 1 day

build:
  stage: build
  script:
    - ${BUILD_CMD}
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  rules:
    - if: \$CI_COMMIT_BRANCH == "main"
  script:
    - apk add --no-cache docker-cli
    - docker build
        --cache-from type=gha
        --cache-to type=gha,mode=max
        --tag \$CI_REGISTRY_IMAGE:\$CI_COMMIT_SHA
        --tag \$CI_REGISTRY_IMAGE:latest
        --push .
YAML

  if $DEPLOY; then
    cat <<YAML

deploy-staging:
  stage: deploy
  script:
    - echo "Deploying \$CI_COMMIT_SHA to staging"
  environment:
    name: staging
  rules:
    - if: \$CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy
  script:
    - echo "Deploying \$CI_COMMIT_SHA to production"
  environment:
    name: production
    url: https://app.example.com
  rules:
    - if: \$CI_COMMIT_BRANCH == "main"
  when: manual
  needs:
    - deploy-staging
YAML
  fi
}

# ---------------------------------------------------------------------------
# CircleCI
# ---------------------------------------------------------------------------
generate_circle() {
  cat <<YAML
version: 2.1

orbs:
  node: circleci/node@6
  docker: circleci/docker@4

executors:
  default:
    docker:
      - image: ${IMAGE}
    resource_class: medium

commands:
  restore_cache_cmd:
    steps:
      - restore_cache:
          keys:
            - ${CACHE_KEY}-\${{ checksum "package-lock.json" }}
            - ${CACHE_KEY}-
  save_cache_cmd:
    steps:
      - save_cache:
          key: ${CACHE_KEY}-\${{ checksum "package-lock.json" }}
          paths:
            - ${CACHE_PATH}

jobs:
  lint:
    executor: default
    steps:
      - checkout
      - restore_cache_cmd
      - run: npm ci
      - run: ${LINT_CMD}
      - save_cache_cmd

  test:
    executor: default
    parallelism: 3
    steps:
      - checkout
      - restore_cache_cmd
      - run: npm ci
      - run: |
          TEST_FILES=\$(circleci tests glob "src/**/*.test.*" | circleci tests split --split-by=timings)
          ${TEST_CMD} -- --shard=\${{ CIRCLE_NODE_INDEX }}/\${{ CIRCLE_NODE_TOTAL }}
      - save_cache_cmd
      - store_test_results:
          path: test-results/

  build:
    executor: default
    steps:
      - checkout
      - restore_cache_cmd
      - run: npm ci
      - run: ${BUILD_CMD}
      - save_cache_cmd
      - persist_to_workspace:
          root: .
          paths:
            - dist/

  docker:
    executor:
      name: docker/docker
    steps:
      - setup_remote_docker
      - checkout
      - docker/check:
          registry: \$REGISTRY
      - docker/build:
          cache_from:
            - type=gha
          cache_to:
            - type=gha,mode=max
          tags: |
            \$REGISTRY/app:\$CIRCLE_SHA1
            \$REGISTRY/app:latest

workflows:
  ci:
    jobs:
      - lint
      - test:
          requires: [lint]
      - build:
          requires: [test]
      - docker:
          requires: [build]
          filters:
            branches:
              only: main
YAML

  if $DEPLOY; then
    cat <<YAML
      - deploy-staging:
          requires: [docker]
          filters:
            branches:
              only: main
      - deploy-production:
          type: approval
          requires: [deploy-staging]
          filters:
            branches:
              only: main

  deploy-staging:
    executor: default
    steps:
      - run: echo "Deploying \$CIRCLE_SHA1 to staging"

  deploy-production:
    executor: default
    steps:
      - run: echo "Deploying \$CIRCLE_SHA1 to production"
YAML
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
generate() {
  case "$PLATFORM" in
    github) generate_github ;;
    gitlab) generate_gitlab ;;
    circle) generate_circle ;;
    *) echo "Error: Unsupported platform '$PLATFORM'. Supported: github, gitlab, circle"; exit 1 ;;
  esac
}

if [[ -n "$OUTPUT" ]]; then
  generate > "$OUTPUT"
  echo "Pipeline written to $OUTPUT"
else
  generate
fi

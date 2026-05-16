# Self-Hosted Runners on Kubernetes

## Why Self-Hosted

| Pro | Con |
|-----|-----|
| No job duration limits | Maintenance overhead |
| Custom hardware (GPU, ARM) | Security surface area |
| Docker-in-Docker (DinD) support | Cluster resource consumption |
| Local network access | Scaling configuration required |
| Cost-effective at scale | Ephemeral vs persistent tradeoffs |
| Cache persistence | Secret management |

---

## GitHub Actions — actions-runner-controller

### Installation

```bash
# Install cert-manager (required)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# Install actions-runner-controller
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm upgrade --install arc actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --create-namespace

# Create a PAT token with repo scope
# Register via Kubernetes Secret or GitHub App
```

### RunnerDeployment (ephemeral, auto-scaling)

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: app-runner
spec:
  replicas: 2
  template:
    spec:
      repository: org/app
      image: summerwind/actions-runner:latest
      dockerdWithinRunnerContainer: true
      securityContext:
        capabilities:
          add: ["SYS_PTRACE"]
      resources:
        limits:
          cpu: 2
          memory: 4Gi
        requests:
          cpu: 1
          memory: 2Gi
```

### HorizontalRunnerAutoscaler

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: app-runner-autoscaler
spec:
  scaleTargetRef:
    name: app-runner
  minReplicas: 1
  maxReplicas: 10
  scaleUpTriggers:
    - githubEvent:
        workflowJob: build
      duration: "30m"
    - githubEvent:
        workflowJob: test
      duration: "30m"
    - githubEvent:
        workflowJob: deploy
      duration: "60m"
  metrics:
    - type: TotalJobQueue
      repositoryNames:
        - org/app
```

### RunnerGroup (shared across repos)

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerGroup
metadata:
  name: org-runners
spec:
  organization: my-org
  config:
    image: summerwind/actions-runner:latest
    dockerdWithinRunnerContainer: true
    resources:
      requests:
        cpu: 2
        memory: 4Gi
```

### Cache with actions/cache via proxy

```yaml
# ${{ github.workspace }}/.github/actions/arc-cache/action.yml
name: ARC Cache
description: "Cache using ARC's built-in cache proxy"
runs:
  using: "composite"
  steps:
    - uses: actions/cache@v4
      with:
        path: ${{ inputs.path }}
        key: ${{ inputs.key }}
        restore-keys: ${{ inputs.restore-keys }}
```

Alternatively, deploy a self-hosted `actions/cache` proxy:

```bash
helm upgrade --install actions-cache-proxy \
  actions-runner-controller/actions-cache-proxy \
  --namespace actions-runner-system
```

---

## GitLab Runner — Helm Chart

### Installation

```bash
helm repo add gitlab https://charts.gitlab.io
helm upgrade --install gitlab-runner gitlab/gitlab-runner \
  --namespace gitlab-runner \
  --create-namespace \
  --set gitlabUrl=https://gitlab.com \
  --set runnerRegistrationToken=<token> \
  --set rbac.create=true
```

### values.yaml (production)

```yaml
gitlabUrl: https://gitlab.com
runnerRegistrationToken: ""  # Use --set or existingSecret

rbac:
  create: true
  clusterWideAccess: false

runners:
  config: |
    [[runners]]
      name = "Kubernetes Runner"
      executor = "kubernetes"
      [runners.cache]
        Type = "s3"
        Path = "gitlab-runner-cache"
        Shared = true
        [runners.cache.s3]
          ServerAddress = "minio.example.com:9000"
          AccessKey = "minio"
          SecretKey = "minio123"
          BucketName = "runner-cache"
          Insecure = true
      [runners.kubernetes]
        namespace = "gitlab-runner"
        image = "ubuntu:22.04"
        helper_image = "gitlab/gitlab-runner-helper:x86_64-latest"
        poll_timeout = 600
        poll_interval = 3
        cpu_limit = "4"
        memory_limit = "8Gi"
        cpu_request = "2"
        memory_request = "4Gi"
        service_cpu_limit = "2"
        service_memory_limit = "4Gi"
        helper_cpu_limit = "1"
        helper_memory_limit = "2Gi"
        [runners.kubernetes.volumes]
          [[runners.kubernetes.volumes.host_path]]
            name = "docker-socket"
            mount_path = "/var/run/docker.sock"
            host_path = "/var/run/docker.sock"

# Autoscaling via k8s HPA
metrics:
  enabled: true

service:
  metrics:
    port: 9252
```

### Autoscaling

Apply a HorizontalPodAutoscaler to the runner deployment:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gitlab-runner
  namespace: gitlab-runner
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gitlab-runner
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

> **Note**: GitLab Runner does not auto-scale runner pods per job queue — each runner handles 1 job. For queue-based autoscaling, consider separate runner manager deployments or `gitlab-runner` autoscaling with `concurrent` setting.

---

## CircleCI — Machine Executors on Self-Hosted

CircleCI uses `circleci-agent` running directly on VMs or bare metal. For Kubernetes, run `circleci-runner` as a pod.

### Runner Installation

```bash
# Create a namespace
kubectl create ns circleci-runners

# Create the runner token secret
kubectl create secret generic circleci-runner-token \
  --from-literal=token=<runner-token> \
  -n circleci-runners
```

### Runner Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: circleci-runner
  namespace: circleci-runners
spec:
  replicas: 2
  selector:
    matchLabels:
      app: circleci-runner
  template:
    metadata:
      labels:
        app: circleci-runner
    spec:
      serviceAccountName: circleci-runner
      containers:
        - name: runner
          image: circleci/runner:latest
          env:
            - name: CIRCLE_RUNNER_TOKEN
              valueFrom:
                secretKeyRef:
                  name: circleci-runner-token
                  key: token
            - name: CIRCLE_RUNNER_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: CIRCLE_RUNNER_WORKING_DIRECTORY
              value: /home/circleci
            - name: CIRCLE_RUNNER_API_URL
              value: https://circleci.com/api/v2
            - name: CIRCLE_RUNNER_MAX_CONCURRENT_TASKS
              value: "4"
          volumeMounts:
            - name: docker-socket
              mountPath: /var/run/docker.sock
            - name: workspace
              mountPath: /home/circleci
          resources:
            requests:
              cpu: 2
              memory: 4Gi
            limits:
              cpu: 8
              memory: 16Gi
      volumes:
        - name: docker-socket
          hostPath:
            path: /var/run/docker.sock
        - name: workspace
          emptyDir: {}
```

### Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: circleci-runner
  namespace: circleci-runners
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: circleci-runner
  minReplicas: 1
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Resource Classes

Configure `.circleci/config.yml` to target self-hosted runners via runner resource class:

```yaml
version: 2.1
jobs:
  build:
    machine: true
    resource_class: org/app-runner
    steps:
      - checkout
      - run: docker build -t app:ci .
```

---

## Caching Strategies

### Docker Layer Caching (DLC)

| Method | How | Persistence |
|--------|-----|-------------|
| **Host path volume** | Mount `/var/lib/docker` as hostPath across pods | Ephemeral — lost on node drain |
| **Registry cache** | `--cache-from/--cache-to type=registry` | Persistent — registry-backed |
| **S3/GCS cache** | `--cache-from/--cache-to type=s3/gcs` | Persistent — object store |
| **BuildKit daemon** | Shared BuildKit daemon per node | Requires careful cleanup |

Recommended: registry cache with inline or `mode=max`:

```yaml
- name: Build and push
  uses: docker/build-push-action@v6
  with:
    cache-from: type=registry,ref=registry.example.com/cache:app
    cache-to: type=registry,ref=registry.example.com/cache:app,mode=max
```

### Job-level caching with persistent volume

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: runner-cache-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: efs-sc  # or nfs, longhorn, etc.
```

Mount into runner pods to preserve npm/go/pip caches across jobs.

---

## Security Hardening

### Pod Security

```yaml
# Pod Security Admission (PSA) labels
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted

# Or explicit security context
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: runner
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
        readOnlyRootFilesystem: true
```

### RBAC

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: runner
  namespace: ci-runners
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: runner
  namespace: ci-runners
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: runner
  namespace: ci-runners
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: runner
subjects:
  - kind: ServiceAccount
    name: runner
```

### Workload Identity (OIDC)

| Platform | Method |
|----------|--------|
| GitHub Actions | `AssumeRoleWithWebIdentity` — OIDC token from `actions/configure-aws-credentials` |
| GitLab CI | `id_tokens` in CI/CD → AWS/GCP/Azure workload identity federation |
| CircleCI | `AWS_WEB_IDENTITY_TOKEN_FILE` — OIDC via `aws/configure-aws-credentials` orb |

```yaml
# GitHub Actions with OIDC
# AWS role trust policy trusts "repo:org/app:ref:refs/heads/main"
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: [self-hosted]
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/deploy-role
          aws-region: us-east-1
      - run: aws sts get-caller-identity
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: runner-egress
  namespace: ci-runners
spec:
  podSelector:
    matchLabels:
      app: runner
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8   # Block internal network
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - port: 443
          protocol: TCP
        - port: 80
          protocol: TCP
    - to:
        - namespaceSelector:
            matchNames:
              - kube-system
      ports:
        - port: 53
          protocol: UDP
```

---

## Maintenance

### Node Affinity

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: node-type
                operator: In
                values:
                  - ci-runner
    tolerations:
      - key: ci-runner
        operator: Exists
        effect: NoSchedule
```

### Preemption and Cleanup

```yaml
spec:
  terminationGracePeriodSeconds: 300  # Allow job to finish
  activeDeadlineSeconds: 3600         # Max job runtime
  ttlSecondsAfterFinished: 300        # Cleanup completed pods
```

### Monitoring

| Metric | Source | What to Watch |
|--------|--------|---------------|
| Job queue depth | Platform API | > 10 queued → scale up |
| Pod utilization | k8s metrics-server | CPU > 70% → scale up |
| OOM kills | kube-state-metrics | Increase memory limits |
| Pending jobs | CI platform webhook | Alert if pending > 5min |
| Cache hit rate | CI job logs | < 50% → review cache keys |
| Pod startup time | k8s events | > 30s → check image pull |

### Image Optimization

```dockerfile
# Dockerfile for runner image with pre-installed tools
FROM summerwind/actions-runner:latest

RUN sudo apt-get update && sudo apt-get install -y \
  docker-compose \
  kubectl \
  helm \
  && sudo rm -rf /var/lib/apt/lists/*

# Pre-warm Docker images
RUN sudo docker pull node:22-slim \
  && sudo docker pull python:3.12-slim \
  && sudo docker pull golang:1.22-alpine
```

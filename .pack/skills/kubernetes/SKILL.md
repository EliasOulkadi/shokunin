---
name: kubernetes
description: Deploy, manage, and debug Kubernetes in production — Deployments, Services, Gateway API, Service Mesh (Istio/Linkerd/Cilium), eBPF observability (Cilium Hubble), security hardening (Pod Security Standards, OPA/Kyverno, seccomp, runtime security with Falco/Tetragon), Helm, HPA, PDB, topology spread, and debugging. Use when user asks to write K8s manifests, deploy to a cluster, debug pods, set up Gateway API, configure autoscaling, or harden cluster security. Do NOT use for Dockerfiles (use docker), CI/CD pipeline design (use ci-cd), or Terraform infrastructure (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "3.0.0"
  author: shokunin
allowed-tools: Read Bash Write Grep Glob
triggers:
  - k8s
  - kubernetes
  - deploy
  - pod
  - cluster
  - helm
  - kustomize
  - kubectl
  - service mesh
  - istio
  - linkerd
  - cilium
  - gateway api
  - hpa
  - network policy
  - statefulset
  - daemonset
negatives:
  - "Dockerfile"
  - "Docker"
  - "docker-compose"
  - "CI/CD pipeline"
  - "Terraform"
---


# Kubernetes Architect

Production-grade Kubernetes: deployments, Gateway API, zero-trust networking, service mesh, eBPF observability, and debugging. Follows NSA/CISA hardening guidelines.

## Decision Framework

Before deploying to Kubernetes, answer:
- Does the app need horizontal scaling (3+ replicas)? → Kubernetes
- Is it a single-instance app with simple needs? → Docker Compose or VPS
- Is the team already familiar with Kubernetes? → Proceed. If not, consider managed (EKS, GKE, AKS)
- Does the app need advanced networking (service mesh, ingress routing)? → Kubernetes + Gateway API
- Is the infrastructure budget tight? → Single-node k3s or Docker Compose for dev
- Multiple services with different scaling profiles? → Kubernetes (HPA per service)

## Workflow

### Step 1: Determine deployment type

| Type | Kind | Use case |
|------|------|----------|
| Stateless | Deployment | Web APIs, workers |
| Stateful | StatefulSet | Databases, queues (use with caution) |
| Batch | Job/CronJob | Migrations, periodic tasks |
| Daemon | DaemonSet | Logging, monitoring agents |

If uncertain, start with a Deployment. See [assets/deployment-template.yaml](assets/deployment-template.yaml) for the full production template.

### Step 2: Generate manifest

Use the scaffold script:
```bash
scripts/generate-manifest.sh -n api -i myregistry.com/api:1.0.0 -p 3000 -r 3 -o manifests/
```

This creates: `deployment.yaml`, `service.yaml`, `hpa.yaml`, `pdb.yaml` with all security contexts, probes, resource requests/limits, and topology spread constraints pre-configured.

**If the service expects HTTP traffic**, also create a Gateway API HTTPRoute.

### Template alternatives: Helm and Kustomize

The scaffold script above generates raw manifests. For more complex deployments, consider:

| Tool | Best for | Pattern |
|------|----------|---------|
| **Helm** (`helm create`) | Packaging reusable apps, versioned releases, templating | `values.yaml` → Go templates → rendered manifests. Use `helm lint` and `helm template` for validation. |
| **Kustomize** (`kubectl kustomize`) | Environment-specific overlays, patching base manifests | `base/` + `overlays/{dev,staging,prod}/` with strategic merge patches. Native in `kubectl`. |
| **Raw manifests** | Simple services, fast iteration, no templating overhead | Plain YAML in `manifests/`. Use with the scaffold script. |

Use Helm for distributing apps (charts), Kustomize for environment variants (overlays), and raw manifests for speed. The scaffold script handles the raw manifest path — for Helm/Kustomize, create the chart or overlay manually following the same security constraints.

### Step 3: Configure networking

#### Gateway API (replaces Ingress)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: api-gateway
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  gatewayClassName: istio
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: api.example.com
      tls:
        mode: Terminate
        certificateRefs: [{ name: api-tls }]
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-route
spec:
  parentRefs: [{ name: api-gateway }]
  hostnames: ["api.example.com"]
  rules:
    - matches:
        - path: { type: PathPrefix, value: /api }
      backendRefs:
        - name: api
          port: 80
```

See [references/gateway-api.md](references/gateway-api.md) for HTTPRoute, GRPCRoute, TLSRoute, and cross-namespace patterns.

#### Zero-trust networking

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny-all }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-api-ingress }
spec:
  podSelector: { matchLabels: { app: api } }
  ingress:
    - from:
        - namespaceSelector: { matchLabels: { name: gateway-system } }
      ports: [{ port: 3000 }]
```

**Always start with a default-deny policy.** Then add explicit allow rules.

### Step 4: Add service mesh (if needed)

See [references/service-mesh.md](references/service-mesh.md) for the complete comparison and setup guide.

**Decision matrix:**
| Need | Recommendation |
|------|---------------|
| mTLS + observability | Istio (full-featured) |
| Simple mTLS + lightweight | Linkerd (low resource overhead) |
| eBPF-native networking + security | Cilium (no sidecar needed) |

### Step 5: Configure autoscaling and resilience

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: api-hpa }
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: { type: Utilization, averageUtilization: 70 }
    - type: Resource
      resource:
        name: memory
        target: { type: Utilization, averageUtilization: 80 }
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: { name: api-pdb }
spec:
  minAvailable: 2
  selector:
    matchLabels: { app: api }
```

### Step 6: Debug issues

See the debugging script:
```bash
scripts/debug-pod.sh api-7d8f9c-abc  # describes pod, shows logs, checks events, diagnoses
```

**Common diagnoses the script detects:**
| Symptom | Likely cause |
|---------|-------------|
| `CrashLoopBackOff` with OOMKill | Out of memory — increase `resources.limits.memory` |
| `CrashLoopBackOff` with ImagePullBackOff | Wrong image name, tag, or registry credentials |
| `Pending` with no node | Insufficient resources or PVC pending |
| `ImagePullBackOff` | Image tag doesn't exist, registry unreachable, or `imagePullSecrets` missing | Verify image exists: `docker pull <image>`. Check `imagePullSecrets` in namespace. |
| `CreateContainerConfigError` | ConfigMap or Secret referenced but not mounted | `kubectl describe pod` lists missing config keys. Verify ConfigMap/Secret exists in same namespace. |
| `Running` but not ready | Readiness probe failing — check `/ready` endpoint |

## Error Handling

| Scenario | Diagnosis | Fix |
|----------|-----------|-----|
| Pod stuck in Pending | `kubectl describe pod` → events | Check node resources, PVC status |
| Pod crash looping | `kubectl logs --previous` | Check app errors, OOMKill status |
| Service unreachable | `kubectl port-forward svc/api 8080:80` | Check selector matches pod labels |
| DNS not resolving | `kubectl exec -it dnsutils -- nslookup api` | Check CoreDNS pods and Service entries |
| TLS cert invalid | `kubectl describe certificate` | Check cert-manager issuer and DNS |
| PVC stuck in Pending | `kubectl describe pvc` → no matching PV, storage class wrong | Check StorageClass exists. Verify PV capacity >= PVC request. Check `volumeMode` matches. |
| ConfigMap not mounted | `kubectl describe pod` → "MountVolume.SetUp failed" | Verify ConfigMap name matches. Use `subPath` for single-file mounts. Check namespace — ConfigMaps are namespace-scoped. |
| RBAC denied | `kubectl auth can-i <verb> <resource> --as <user>` returns no | Check Role/RoleBinding or ClusterRole/ClusterRoleBinding. Verify `subjects` match service account. Use `kubectl auth reconcile -f rbac.yaml` to sync.

## Production Checklist

- [ ] Resource requests + limits on every container
- [ ] Liveness + readiness probes
- [ ] Pod Security Standards: `restricted` enforced
- [ ] NetworkPolicy: default-deny + explicit allow
- [ ] Containers run as non-root
- [ ] Read-only root filesystem
- [ ] Secrets via external provider (Vault, External Secrets, CSI)
- [ ] HPA with CPU + memory metrics
- [ ] PDB >= 1 for critical services
- [ ] Image pinned by digest (not tag)
- [ ] PodDisruptionBudget for HA
- [ ] mTLS between all services
- [ ] Audit logging shipped
- [ ] RBAC: least privilege, no cluster-admin
- [ ] Falco or Tetragon for runtime security
- [ ] Gateway API (not legacy Ingress)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| `imagePullPolicy: Always` | Pin digest, use `IfNotPresent` |
| No resource limits | Always set requests + limits |
| Running as root | `securityContext.runAsNonRoot: true` |
| `latest` tag | Pin by digest |
| Single replica | Always >= 2 for HA |
| No probes | Liveness + readiness mandatory |
| Hardcoded config in image | ConfigMap + Secret |
| No NetworkPolicy | Default-deny per namespace |
| Legacy Ingress resource | Migrate to Gateway API |

## Review Format (Required)

When reviewing Kubernetes manifests, use Before | After | Why format:

| Before | After | Why |
|--------|-------|-----|
| `image: myapp:latest` | `image: myapp@sha256:abc...` | `latest` is a floating tag. Digest pinning ensures the same image every deploy. |
| No `resources` block | `resources: { requests: { cpu: "100m", memory: "128Mi" }, limits: { cpu: "500m", memory: "256Mi" } }` | Without requests, the scheduler can't place pods. Without limits, one pod can starve others. |
| `imagePullPolicy: Always` | `imagePullPolicy: IfNotPresent` (with digest tag) or `Always` (with floating tag only if intentional) | `Always` forces a registry pull on every start, adding latency. Use with digest tags only for rolling updates. |
| Legacy Ingress | Gateway API `Gateway` + `HTTPRoute` | Ingress is deprecated. Gateway API supports traffic splitting, header matching, and multi-tenancy. |

## Helm Charts

```bash
# Create chart
helm create myapp
# Chart structure: Chart.yaml, values.yaml, templates/deployment.yaml, templates/service.yaml, templates/hpa.yaml

# Install
helm install myapp ./myapp -f values-prod.yaml --namespace production

# Template values: {{ .Values.replicaCount }}, {{ .Values.image.tag }}
# Conditional blocks: {{- if .Values.ingress.enabled }}
# Loops: {{- range .Values.env }}
```

## Kustomize Overlays

```yaml
# base/kustomization.yaml
resources: [deployment.yaml, service.yaml]

# overlays/prod/kustomization.yaml
bases: [../../base]
patchesStrategicMerge: [replicas-patch.yaml]
images: [{ name: myapp, newTag: "v1.2.3" }]
```

Apply: `kubectl apply -k overlays/prod/`

## Pod Hardening (NSA/CISA)

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
containers:
- name: app
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities: { drop: [ALL] }
    seccompProfile: { type: RuntimeDefault }
```

Rule: every production pod must pass all 6 checks above.

## Sources

- Kubernetes docs (kubernetes.io/docs)
- Gateway API (gateway-api.sigs.k8s.io)
- Istio (istio.io), Linkerd (linkerd.io), Cilium (docs.cilium.io)
- Helm (helm.sh)
- NSA/CISA Kubernetes Hardening Guide
- OWASP Kubernetes Security

## Hardening Checklist

Before deploying to production:

- [ ] All containers run as non-root (`securityContext: { runAsNonRoot: true, readOnlyRootFilesystem: true }`)
- [ ] Pod Security Standard `restricted` applied to all namespaces
- [ ] NetworkPolicy `default-deny-all` with explicit allow rules for each service
- [ ] Image pinned by digest, not tag (`image: myapp@sha256:...`)
- [ ] Resource requests AND limits set on every container
- [ ] `readinessProbe` AND `livenessProbe` configured with different thresholds
- [ ] `PodDisruptionBudget` set with `minAvailable: 1` (or higher for multi-replica services)
- [ ] Secrets stored in external manager (Vault, Sealed Secrets, External Secrets), not plain K8s secrets
- [ ] `automountServiceAccountToken: false` unless the pod genuinely needs API access
- [ ] `allowPrivilegeEscalation: false` on all containers
- [ ] TLS enabled on ingress with cert-manager auto-renewal
- [ ] Audit logging enabled on API server and critical namespaces

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources

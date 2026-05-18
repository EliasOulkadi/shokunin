---
name: kubernetes
description: Deploy, manage, and debug Kubernetes in production — Deployments, Services, Gateway API, Service Mesh (Istio/Linkerd/Cilium), eBPF observability (Cilium Hubble), security hardening (Pod Security Standards, OPA/Kyverno, seccomp, runtime security with Falco/Tetragon), Helm, HPA, PDB, topology spread, and debugging. Use when user asks to write K8s manifests, deploy to a cluster, debug pods, set up Gateway API, configure autoscaling, or harden cluster security. Do NOT use for Dockerfiles (use docker), CI/CD pipeline design (use ci-cd), or Terraform infrastructure (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "3.0"
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
---

# Kubernetes Architect

Production-grade Kubernetes: deployments, Gateway API, zero-trust networking, service mesh, eBPF observability, and debugging. Follows NSA/CISA hardening guidelines.

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

## Sources

- Kubernetes docs (kubernetes.io/docs)
- Gateway API (gateway-api.sigs.k8s.io)
- Istio (istio.io), Linkerd (linkerd.io), Cilium (docs.cilium.io)
- Helm (helm.sh)
- NSA/CISA Kubernetes Hardening Guide
- OWASP Kubernetes Security

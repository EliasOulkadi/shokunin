---
name: kubernetes
description: Deploy and manage Kubernetes in production — Deployments, Services, Gateway API, Service Mesh (Istio/Linkerd), eBPF observability (Cilium), security hardening (Pod Security Standards, OPA/Kyverno, seccomp), Helm, HPA, PDB, and debugging. Use when user asks to write K8s manifests, deploy to a cluster, debug pods, set up ingress/gateway, configure autoscaling, or harden cluster security. Do NOT use for Docker containers (use docker), CI/CD pipelines (use ci-cd), or Terraform infrastructure (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "2.0"
---

# Kubernetes Architect

Production-grade Kubernetes: deployments, networking, security, observability, and service mesh.

## Core Resources

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels: { app: api, env: prod }
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxUnavailable: 1, maxSurge: 1 }
  selector:
    matchLabels: { app: api }
  template:
    metadata:
      labels: { app: api }
    spec:
      containers:
        - name: api
          image: myregistry.com/api:1.0.0
          ports: [{ containerPort: 3000, protocol: TCP }]
          envFrom:
            - configMapRef: { name: api-config }
            - secretRef: { name: api-secrets }
          resources:
            requests: { cpu: "250m", memory: "256Mi" }
            limits: { cpu: "500m", memory: "512Mi" }
          livenessProbe:
            httpGet: { path: /health, port: 3000 }
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet: { path: /ready, port: 3000 }
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:
            runAsNonRoot: true
            runAsUser: 1001
            readOnlyRootFilesystem: true
            capabilities: { drop: ["ALL"] }
      automountServiceAccountToken: false
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
  labels: { app: api }
spec:
  selector: { app: api }
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
  type: ClusterIP
```

### Gateway API (replaces Ingress)

Gateway API is the successor to Ingress, supporting HTTPRoute, GRPCRoute, TCPRoute.

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

### NetworkPolicy (zero-trust)

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
        - namespaceSelector: { matchLabels: { name: ingress-nginx } }
      ports: [{ port: 3000 }]
```

### HorizontalPodAutoscaler

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
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### PodDisruptionBudget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: { name: api-pdb }
spec:
  minAvailable: 2
  selector:
    matchLabels: { app: api }
```

## Critical Security Rules

| Rule | Implementation |
|------|---------------|
| No containers as root | `securityContext.runAsNonRoot: true` |
| Drop all capabilities | `capabilities.drop: ["ALL"]` |
| Read-only filesystem | `readOnlyRootFilesystem: true` |
| No SA token by default | `automountServiceAccountToken: false` |
| Default-deny NetworkPolicy per namespace | First policy in namespace |
| Pod Security Standards | `pod-security.kubernetes.io/enforce: restricted` |
| Image by digest, not tag | `image: repo/app@sha256:abc...` |
| Resource limits on every container | `resources.limits.cpu/memory` |

## Service Mesh (Istio)

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: { name: default, namespace: istio-system }
spec:
  mtls:
    mode: STRICT  # All traffic must be mTLS
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata: { name: api-canary }
spec:
  hosts: [api]
  http:
    - route:
        - destination: { host: api, subset: stable }
          weight: 90
        - destination: { host: api, subset: canary }
          weight: 10
```

## eBPF Observability (Cilium)

```yaml
# Install Cilium
# cilium install

# Hubble for network observability
# cilium hubble enable
# cilium hubble ui

# Network policies with Cilium (L7-aware)
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata: { name: allow-api-http }
spec:
  endpointSelector: { matchLabels: { app: api } }
  ingress:
    - fromEndpoints: [{ matchLabels: { app: frontend } }]
      toPorts:
        - ports: [{ port: "3000", protocol: TCP }]
          rules:
            http:
              - method: "GET"
                path: "/api/public/*"
```

## Helm Chart Structure

```
chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── _helpers.tpl
│   └── tests/
└── charts/
```

## Advanced Scheduling

```yaml
# Topology spread constraints
spec:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector: { matchLabels: { app: api } }

# Node affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: node-type
                operator: In
                values: [spot]
```

## Debugging Cheatsheet

| Problem | Command |
|---------|---------|
| Pod stuck in Pending | `kubectl describe pod <pod>` |
| Pod crashing | `kubectl logs <pod> --previous` |
| Pod not ready | `kubectl get events --sort-by=.metadata.creationTimestamp` |
| Service not reachable | `kubectl port-forward svc/<name> 8080:80` |
| DNS resolution | `kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 -- sleep 3600` |
| Debug pod | `kubectl debug -it <pod> --image=ubuntu -- /bin/bash` |
| Resource usage | `kubectl top pod` |
| Watch events | `kubectl get events -w` |

## Production Checklist

- [ ] Resource requests + limits on every container
- [ ] Liveness + readiness probes
- [ ] Pod Security Standards (restricted)
- [ ] NetworkPolicy: default-deny + explicit allow
- [ ] Containers run as non-root
- [ ] Read-only root filesystem
- [ ] Secrets via external provider (Vault, AWS Secrets Manager, CSI)
- [ ] HPA configured for CPU + memory
- [ ] PDB >= 1 for critical services
- [ ] Helm chart with versioned releases
- [ ] Image with digest (not tag)
- [ ] mTLS between all services (service mesh)
- [ ] Audit logging enabled
- [ ] RBAC: least privilege, no cluster-admin
- [ ] Falco or Tetragon for runtime security

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| `imagePullPolicy: Always` on prod | Pin digest, use `IfNotPresent` |
| No resource limits | Always set requests + limits |
| Running as root | `securityContext.runAsNonRoot: true` |
| `latest` tag | Pin version or digest |
| Single replica | Always >= 2 for production |
| No probes | Liveness + readiness mandatory |
| Hardcoded config in image | ConfigMap + Secret |
| No NetworkPolicy | Default-deny per namespace |

## Sources

- Kubernetes Documentation (kubernetes.io/docs)
- Gateway API (gateway-api.sigs.k8s.io)
- Istio Documentation (istio.io)
- Cilium Documentation (docs.cilium.io)
- Helm Documentation (helm.sh)
- OWASP Kubernetes Security
- NSA/CISA Kubernetes Hardening Guide

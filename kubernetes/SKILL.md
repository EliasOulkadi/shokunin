---
name: kubernetes
description: Deploy, manage, and debug applications on Kubernetes. Covers Deployments, Services, Ingress, NetworkPolicies, ConfigMaps, Secrets, RBAC, Helm, probes, HPA, StatefulSets, and security hardening (Pod Security Standards, OPA/Kyverno, seccomp). Use when user asks to write K8s manifests, deploy to a cluster, debug a broken pod, set up ingress, configure autoscaling, or harden cluster security. Triggers on "kubernetes", "k8s", "deployment", "pod", "service", "ingress", "helm", "kubectl", "cluster", "container orchestration". Do NOT use for Docker containers, Terraform infrastructure, or CI/CD pipelines.
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
---

Expert Kubernetes knowledge for production-grade deployments, networking, security, and debugging.

## Core Resources

### Deployment (stateless apps)
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

### Service (stable network endpoint)
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

### Ingress (external HTTP traffic)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts: [api.example.com]
      secretName: api-tls
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80
```

### ConfigMap & Secret
```yaml
apiVersion: v1
kind: ConfigMap
metadata: { name: api-config }
data:
  NODE_ENV: production
  LOG_LEVEL: info

apiVersion: v1
kind: Secret
metadata: { name: api-secrets }
type: Opaque
stringData:
  DATABASE_URL: postgres://user:pass@host:5432/db
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
```

## Critical Security Rules

| Rule | Implementation |
|------|---------------|
| No containers as root | `securityContext.runAsNonRoot: true` |
| Drop all capabilities | `capabilities.drop: ["ALL"]` |
| Read-only filesystem | `readOnlyRootFilesystem: true` |
| No service account token by default | `automountServiceAccountToken: false` |
| Default-deny NetworkPolicy per namespace | See NetworkPolicy above |
| Pod Security Standards | `pod-security.kubernetes.io/enforce: restricted` |
| Image with digest, not tag | `image: repo/app@sha256:abc...` |
| Resource limits on every container | `resources.limits.cpu/memory` |

## Helm Chart Structure

```
chart/
├── Chart.yaml          # metadata: name, version, dependencies
├── values.yaml         # default values
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── _helpers.tpl    # named templates
│   └── tests/
└── charts/             # subcharts
```

## Debugging Cheatsheet

| Problem | Command |
|---------|---------|
| Pod stuck in Pending | `kubectl describe pod <pod>` |
| Pod crashing | `kubectl logs <pod> --previous` |
| Pod not ready | `kubectl get events --sort-by=.metadata.creationTimestamp` |
| Service not reachable | `kubectl port-forward svc/<name> 8080:80` |
| DNS resolution | `kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 -- sleep 3600` |
| Start ephemeral debug container | `kubectl debug -it <pod> --image=ubuntu -- /bin/bash` |
| Resource usage | `kubectl top pod` |
| Watch events | `kubectl get events -w` |

## Production Checklist

- [ ] Resource requests + limits on every container
- [ ] Liveness + readiness probes configured
- [ ] Pod Security Standards enforced per namespace
- [ ] NetworkPolicy: default-deny + explicit allow
- [ ] No privileged containers
- [ ] Containers run as non-root
- [ ] Read-only root filesystem
- [ ] Secrets via external provider (Vault, AWS Secrets Manager, CSI driver)
- [ ] HorizontalPodAutoscaler configured
- [ ] PodDisruptionBudget for >= 1
- [ ] Helm chart with versioned releases
- [ ] container image with digest (not tag)
- [ ] Audit logging enabled and shipped
- [ ] RBAC: least privilege, no cluster-admin bindings
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

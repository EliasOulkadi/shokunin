# Service Mesh Comparison & Setup Guide

> Istio vs Linkerd vs Cilium — mTLS, traffic splitting, observability.

---

## Quick Comparison

| Feature | Istio | Linkerd | Cilium |
|---------|-------|---------|--------|
| **Data plane** | Envoy (sidecar) | micro-proxy (linkerd2-proxy, Rust) | eBPF (kernel-level, no sidecar) |
| **Control plane** | istiod (Go) | destination + identity + proxy-injector | cilium-agent + hubble-relay |
| **mTLS** | Mutual TLS via Envoy | Mutual TLS via native proxy | Mutual TLS via eBPF + key management |
| **Traffic split** | VirtualService + DestinationRule | ServiceProfile + TrafficSplit | CiliumEnvoyConfig + ClusterMesh |
| **L7 aware** | HTTP/gRPC/TCP/Redis/MongoDB | HTTP/gRPC/TCP | HTTP/gRPC/TCP (via Envoy sidecar for L7) |
| **Performance** | ~2-5% latency overhead | ~1-2% latency overhead | ~0-5% (eBPF native) |
| **Resource usage** | ~100-200MB per sidecar | ~10-20MB per sidecar | ~0MB (kernel-level) |
| **Complexity** | High | Low | Medium |
| **Multi-cluster** | Yes (primary-remote, multi-primary) | Yes (via ServiceMirror + multicluster) | Yes (ClusterMesh) |
| **Gateway API** | Full support | Limited | Full support |
| **Egress control** | Yes (ServiceEntry) | Via operator | CiliumEgressGateway |
| **Ingress** | Istio Gateway | NGINX / self-managed | Gateway API / envoy |
| **TLS origination** | Via DestinationRule | Via ServiceProfile | CiliumEnvoyConfig |

---

## mTLS Comparison

### Istio — STRICT mTLS

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: per-workload
  namespace: prod
spec:
  selector:
    matchLabels:
      app: payment
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: DestinationRule
metadata:
  name: default
  namespace: istio-system
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
```

| Mode | Behavior |
|------|----------|
| `UNSET` | Inherit parent (default from mesh config) |
| `DISABLE` | Plaintext — for legacy workloads |
| `PERMISSIVE` | Accept both mTLS and plaintext (migration mode) |
| `STRICT` | Reject non-mTLS traffic |

### Linkerd — Automatic mTLS

```yaml
apiVersion: linkerd.io/v1alpha2
kind: ServerAuthorization
metadata:
  name: all-authenticated
  namespace: prod
spec:
  server:
    name: all-servers
  client:
    unauthenticated: false
---
# Authorize specific service
apiVersion: linkerd.io/v1alpha2
kind: ServerAuthorization
metadata:
  name: payment-only
  namespace: prod
spec:
  server:
    name: payment-grpc
  client:
    meshedTLS:
      serviceAccounts:
        - name: payment
          namespace: prod
```

Linkerd enables mTLS by default with automatic certificate rotation. No configuration needed for basic mTLS — every meshed pod gets it automatically.

### Cilium — mTLS via eBPF

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: mtls-policy
spec:
  endpointSelector:
    matchLabels:
      app: payment
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: api
      toPorts:
        - ports:
            - port: "9000"
              protocol: TCP
---
# Enable mTLS in Cilium agent
# cilium install --set mesh.enabled=true
# cilium config set mesh-auth-enabled true
# cilium config set mesh-auth-verdict "allow"
```

Cilium mTLS uses the **Spiffe** identity framework. Certificates are managed by the Cilium agent via CertificateSigningRequest.

---

## Traffic Splitting / Canary Deployments

### Istio

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: api
spec:
  host: api
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 60s
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: api-canary
spec:
  hosts:
    - api
  http:
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: api
            subset: canary
    - route:
        - destination:
            host: api
            subset: stable
          weight: 90
        - destination:
            host: api
            subset: canary
          weight: 10
```

### Linkerd

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: split.smi-spec.io/v1alpha4
kind: TrafficSplit
metadata:
  name: api-canary
spec:
  service: api
  backends:
    - service: api-stable
      weight: 900m
    - service: api-canary
      weight: 100m
```

Linkerd follows the **SMI TrafficSplit** spec. Deploy canary via separate Deployment + Service, then adjust weights.

### Cilium

```yaml
apiVersion: cilium.io/v2
kind: CiliumEnvoyConfig
metadata:
  name: api-canary
spec:
  services:
    - name: api
      namespace: default
  resources:
    - "@type": type.googleapis.com/envoy.config.route.v3.RouteConfiguration
      name: api-routes
      virtual_hosts:
        - name: api
          domains:
            - "*"
          routes:
            - match:
                prefix: "/"
              route:
                weighted_clusters:
                  clusters:
                    - name: default/api-stable
                      weight: 90
                    - name: default/api-canary
                      weight: 10
```

Cilium traffic splitting uses ClusterMesh and `CiliumEnvoyConfig`. For simpler setups, Cilium can also leverage Gateway API HTTPRoute weights.

---

## Observability

### Istio — Kiali + Prometheus + Grafana

```bash
# Install Kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml

# Enable request logging
istioctl install --set meshConfig.accessLogFile=/dev/stdout

# Default dashboards
istioctl dashboard kiali    # Topology, traffic graphs
istioctl dashboard grafana  # Istio service/workload metrics
istioctl dashboard jaeger   # Distributed tracing
```

**Key metrics:**
- `istio_requests_total` — request count by source/destination/response_code
- `istio_request_duration_milliseconds` — latency (p50/p90/p99)
- `istio_tcp_received_bytes_total` — TCP throughput

### Linkerd — Viz

```bash
# Install viz extension
linkerd viz install | kubectl apply -f -

# Dashboards
linkerd viz dashboard          # Topology + live metrics
linkerd viz top deploy -n prod # Live request stream
linkerd viz stat deployments   # Success rate, latency, RPS
linkerd viz tap deploy/api     # Live request/response inspection
```

**Key metrics:**
- `REQUEST_RATE` — requests per second
- `SUCCESS_RATE` — percentage of non-5xx responses
- `LATENCY_P50/P95/P99` — latency percentiles

### Cilium — Hubble

```bash
# Enable Hubble
cilium hubble enable
cilium hubble ui

# CLI Observability
hubble observe --from-pod api-xxx --to-pod payment-xxx
hubble observe --verdict DROPPED  # Show dropped packets
hubble observe --protocol http    # HTTP-aware filtering

# Service map
cilium connectivity measure --two-clusters
```

**Key metrics:**
- `hubble_flows_processed_total` — all network flows
- `hubble_drop_total{reason="policy_denied"}` — dropped by policy
- `hubble_tcp_flags` — TCP handshake/fin/reset tracking

---

## Installation Comparison

### Istio

```bash
# Download istioctl (latest: 1.24+)
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-*/bin:$PATH

# Install with default profile
istioctl install --set profile=default -y

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled

# Minimal production profile
istioctl install --set profile=production \
  --set meshConfig.accessLogFile=/dev/stdout \
  --set values.global.proxy.resources.requests.cpu=50m \
  --set values.global.proxy.resources.requests.memory=64Mi \
  --set meshConfig.defaultConfig.tracing.zipkin.address=jaeger-collector:9411
```

**Profiles:**

| Profile | Use Case |
|---------|----------|
| `default` | General purpose with Ingress gateway |
| `demo` | Feature-rich for testing |
| `minimal` | Only control plane (no ingress) |
| `production` | Production-hardened with HPA, resources |
| `ambient` | Ambient mesh (no sidecar, beta) |

### Linkerd

```bash
# Install CLI
curl -sL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin

# Pre-flight check
linkerd check --pre

# Install control plane
linkerd install | kubectl apply -f -

# Install viz extension
linkerd viz install | kubectl apply -f -

# Enable sidecar injection
kubectl annotate namespace default linkerd.io/inject=enabled

# Verify
linkerd check
linkerd viz stat namespaces
```

### Cilium

```bash
# Install via Helm
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium \
  --namespace kube-system \
  --set mesh.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set l7Proxy=true \
  --set securityContext.capabilities=CHOWN,KILL,NET_ADMIN,SYS_ADMIN,SYS_RESOURCE \
  --set ipam.mode=kubernetes

# Verify
cilium status
cilium connectivity test
cilium hubble port-forward&

# Enable Hubble UI
cilium hubble ui
```

---

## Migration Strategy

### Layer 1 (Start here — high trust, low effort)

1. Install service mesh with `PERMISSIVE` mTLS
2. Annotate non-critical namespace for injection
3. Validate with mesh dashboard
4. Add `TrafficSplit` / `VirtualService` for one service

### Layer 2 (Medium trust)

5. Move to `STRICT` mTLS
6. Implement fine-grained `ServerAuthorization` / `PeerAuthentication` / `CiliumNetworkPolicy`
7. Enable distributed tracing

### Layer 3 (Full mesh)

8. Multi-cluster federation
9. Egress control + external service governance
10. Circuit breaking, retries, timeouts on all services

---

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Running mesh on dev but not prod | Same config everywhere or mesh everywhere |
| No mTLS in permissive mode forever | Move to STRICT after migration window |
| Istio VirtualService without DestinationRule | Always pair them for subset routing |
| Linkerd without viz extension | Observability requires viz |
| Cilium with `l7Proxy=false` | Required for HTTP-aware policies |
| Not configuring sidecar resources | Envoy default resources are high — tune them |
| Mixing mesh gateways with Ingress | Use Gateway API as the unified front |
| Sidecar injection on DaemonSets | Usually unnecessary — use `sidecar.istio.io/inject: "false"` |

---

## Performance Tuning

### Istio sidecar resources

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/proxyCPU: "100m"
        sidecar.istio.io/proxyMemory: "128Mi"
        sidecar.istio.io/proxyCPULimit: "500m"
        sidecar.istio.io/proxyMemoryLimit: "256Mi"
```

### Linkerd proxy resources

```bash
kubectl annotate namespace default \
  linkerd.io/proxy-cpu-request=100m \
  linkerd.io/proxy-memory-request=64Mi \
  linkerd.io/proxy-cpu-limit=200m \
  linkerd.io/proxy-memory-limit=128Mi
```

### General tips

- Pin sidecar resources — don't rely on defaults
- Use `concurrency: 2` for Istio on multi-core nodes
- Cilium has no sidecar overhead — best for performance-critical paths
- For high throughput (>10k req/s), prefer Cilium or ambient Istio
- Set `holdApplicationUntilProxyStarts: true` for race condition prevention

---

## Decision Matrix

| Priority | Recommendation |
|----------|---------------|
| Lowest latency | Cilium (eBPF, no sidecar) |
| Fastest setup | Linkerd (5 min install, auto-mTLS) |
| Most features | Istio (routing, auth, fault injection, WASM) |
| Best observability | Istio + Kiali / Linkerd + Viz |
| Low resource budget | Linkerd (~15MB/proxy) or Cilium (0MB) |
| Multi-cluster | Cilium ClusterMesh (native) |
| Gateway API native | Istio or Cilium |
| Legacy integration | Istio (PERMISSIVE mode) |
| Kubernetes-native simplicity | Linkerd |

---

## Sources

- [Istio Docs](https://istio.io/latest/docs/)
- [Linkerd Docs](https://linkerd.io/2.15/overview/)
- [Cilium Service Mesh](https://docs.cilium.io/en/stable/network/servicemesh/)
- [SMI TrafficSplit Spec](https://github.com/servicemeshinterface/smi-spec/blob/main/apis/traffic-split/v1alpha4/traffic-split.md)
- [CNCF Service Mesh Landscape](https://landscape.cncf.io/guide#service-mesh)

# Gateway API Reference

> Successor to Ingress — standard Kubernetes API for L4/L7 routing.
> v1.2+ stable (GA since v1.0) — `gateway.networking.k8s.io/v1`

---

## Core Concepts

| Term | Description |
|------|-------------|
| **GatewayClass** | Cluster-scoped template — defines the controller/implementation (istio, nginx, contour, etc.) |
| **Gateway** | Instantiation of a GatewayClass — listens on ports, terminates TLS, delegates routing |
| **Route** | Protocol-specific routing rules — HTTPRoute, GRPCRoute, TLSRoute, TCPRoute, UDPRoute |
| **ReferenceGrant** | Allows cross-namespace references between routes and backends |

### Architecture

```
GatewayClass (cluster) → Gateway (namespace) → Route (namespace) → Service (any ns via ReferenceGrant)
```

---

## GatewayClass

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
  parametersRef:
    group: istio.io/v1alpha1
    kind: IstioGatewayConfig
    name: my-config
```

| Controller | `controllerName` |
|------------|-----------------|
| Istio | `istio.io/gateway-controller` |
| NGINX | `nginx.org/gateway-controller` |
| Contour | `projectcontour.io/gateway-controller` |
| Cilium | `io.cilium/gateway-controller` |
| Envoy Gateway | `gateway.envoyproxy.io/gatewayclass` |

---

## Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: external-http
spec:
  gatewayClassName: istio
  addresses:
    - type: Hostname
      value: lb.example.com
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https-api
      protocol: HTTPS
      port: 443
      hostname: api.example.com
      tls:
        mode: Terminate
        certificateRefs:
          - name: api-tls
            group: ""
            kind: Secret
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              gateway: external
```

### Listener fields

| Field | Purpose |
|-------|---------|
| `hostname` | SNI match — only routes with this hostname are eligible |
| `tls.mode` | `Terminate` (TLS at gateway), `Passthrough` (SNI-only, TLS to backend), or unset |
| `tls.certificateRefs` | References to Secrets containing TLS certs |
| `allowedRoutes` | Controls which routes can bind to this listener (namespace/selector) |

---

## HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-routes
  labels:
    app: api
spec:
  parentRefs:
    - name: external-http
      sectionName: https-api
  hostnames:
    - api.example.com
    - api.staging.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/v1
          method: GET
          headers:
            - name: X-Version
              value: v2
        - path:
            type: Exact
            value: /healthz
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            set:
              - name: X-Forwarded-Proto
                value: https
      backendRefs:
        - name: api-v2
          port: 80
          weight: 90
        - name: api-v1
          port: 80
          weight: 10

    - matches:
        - path:
            type: PathPrefix
            value: /static
      filters:
        - type: ResponseHeaderModifier
          responseHeaderModifier:
            set:
              - name: Cache-Control
                value: public, max-age=31536000
      backendRefs:
        - name: cdn-cache
          port: 80
```

### Match types

| Type | Example | Match Semantics |
|------|---------|----------------|
| `Exact` | `/healthz` | Exact path match |
| `PathPrefix` | `/api/` | Path prefix (not regex) |
| `RegularExpression` | `^/v[0-9]/.*` | Regex (implementation-specific, avoid for portability) |

### Filters

| Filter | Purpose |
|--------|---------|
| `RequestHeaderModifier` | Add/remove/set request headers |
| `ResponseHeaderModifier` | Add/remove/set response headers |
| `RequestRedirect` | HTTP → HTTPS, path redirects |
| `URLRewrite` | Rewrite path or hostname before forwarding |
| `RequestMirror` | Mirror traffic to a backend for testing |
| `ExtensionRef` | Implementation-specific filters (Istio `WasmPlugin`, etc.) |

### RequestRedirect

```yaml
filters:
  - type: RequestRedirect
    requestRedirect:
      scheme: https
      statusCode: 301
```

### URLRewrite

```yaml
filters:
  - type: URLRewrite
    urlRewrite:
      path:
        type: ReplacePrefixMatch
        replacePrefixMatch: /v2
```

---

## GRPCRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: grpc-routes
spec:
  parentRefs:
    - name: internal-gateway
  hostnames:
    - grpc.internal.example.com
  rules:
    - matches:
        - method:
            type: Exact
            service: com.example.payments.PaymentService
            method: ProcessPayment
      filters:
        - type: RequestMirror
          requestMirror:
            backendRef:
              name: payment-mirror
              port: 50051
      backendRefs:
        - name: payment-service
          port: 50051

    - matches:
        - method:
            type: ServicePrefix
            service: com.example.users
      backendRefs:
        - name: user-service
          port: 50051
```

### GRPCRoute match types

| Type | Required Fields | Example |
|------|----------------|---------|
| `Exact` | service + method | `service: UserService`, `method: GetUser` |
| `ServicePrefix` | service (prefix) | `service: com.example.users` |
| `MethodPrefix` | service.method (prefix) | not widely supported |

---

## TLSRoute

For non-HTTP TLS traffic (TCP over TLS):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: TLSRoute
metadata:
  name: database-tls
spec:
  parentRefs:
    - name: internal-gateway
  hostnames:
    - db.internal.example.com
  rules:
    - backendRefs:
        - name: postgres-primary
          port: 5432
```

> NOTE: TLSRoute uses `Passthrough` mode — the gateway does not terminate TLS, it SNI-routes the raw TLS connection.

---

## TCPRoute / UDPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: TCPRoute
metadata:
  name: redis-tcp
spec:
  parentRefs:
    - name: internal-gateway
  rules:
    - backendRefs:
        - name: redis
          port: 6379
---
apiVersion: gateway.networking.k8s.io/v1
kind: UDPRoute
metadata:
  name: dns-udp
spec:
  parentRefs:
    - name: dns-gateway
  rules:
    - backendRefs:
        - name: dns-server
          port: 53
```

---

## ReferenceGrant (Cross-Namespace Routing)

By default, routes can only reference backends in the **same namespace**. `ReferenceGrant` opens cross-namespace access.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata:
  name: allow-gateway-routes
  namespace: backend-team
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: gateway-team
  to:
    - group: ""
      kind: Service
```

This allows `HTTPRoute` objects in namespace `gateway-team` to reference `Service` objects in namespace `backend-team`.

### TLS Certificate cross-namespace reference

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata:
  name: allow-tls
  namespace: cert-manager
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: Gateway
      namespace: gateway-team
  to:
    - group: ""
      kind: Secret
```

---

## Cross-Namespace Routing Pattern

```
Gateway (infra-ns)
  ↓ listener.allowedRoutes.namespaces.from: Selector
  ↓ listener.allowedRoutes.namespaces.selector.matchLabels: { team: api }
HTTPRoute (api-ns)
  ↓ needs ReferenceGrant in backend-ns
Service (backend-ns)
```

### Gateway config

```yaml
kind: Gateway
spec:
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              team: api
```

### Route (different namespace from Gateway)

```yaml
kind: HTTPRoute
metadata:
  namespace: api-team
spec:
  parentRefs:
    - name: shared-gateway
      namespace: infra
  backendRefs:
    - name: api-service
      namespace: backend
      port: 80
```

### ReferenceGrant (in backend namespace)

```yaml
kind: ReferenceGrant
metadata:
  namespace: backend
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: api-team
  to:
    - group: ""
      kind: Service
```

---

## Gateway API with Service Mesh

### Mesh gateways (Istio)

Gateway API can also configure **service mesh** traffic (east-west) — not just ingress:

```yaml
kind: Gateway
metadata:
  name: mesh
spec:
  gatewayClassName: istio-mesh
  listeners:
    - name: mtls
      port: 15008
      protocol: HBONE
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mesh-routing
spec:
  parentRefs:
    - name: mesh
  hostnames: ["api.default.svc.cluster.local"]
  rules:
    - backendRefs:
        - name: api
          port: 80
```

---

## Production Checklist

- [ ] GatewayClass has `parametersRef` for implementation-specific tuning
- [ ] Listeners set `allowedRoutes` to restrict route binding (avoid `from: All` in production)
- [ ] TLS certs in same namespace as Gateway or use `ReferenceGrant`
- [ ] Routes use `backendRef.weight` for canary deployments
- [ ] Cross-namespace refs have matching `ReferenceGrant` in the target namespace
- [ ] `hostnames` on routes match the Gateway listener's `hostname` or are a wildcard match
- [ ] `GRPCRoute` uses `ServicePrefix` for broad matches, `Exact` for specific methods
- [ ] Rate limiting, retries, and timeouts use `ExtensionRef` or implementation annotations
- [ ] Route matches ordered from most specific → least specific
- [ ] Prefer `PathPrefix` over regex matches for performance and portability

---

## Migration from Ingress

| Ingress | Gateway API Equivalent |
|---------|----------------------|
| `Ingress` | `Gateway` + `HTTPRoute` |
| `IngressClassName` | `GatewayClass` |
| `tls.hosts` | `Gateway.listener[].hostname` + TLS config |
| `rules.host` | `HTTPRoute.spec.hostnames[]` |
| `rules.http.paths` | `HTTPRoute.spec.rules[].matches[]` |
| `rules.http.paths.backend.service` | `backendRefs[].name` |
| `rules.http.paths.path` | `path.type` + `path.value` |
| cross-namespace (not supported) | `ReferenceGrant` |

### Migration helper commands

```bash
# List all Ingress resources as migration candidates
kubectl get ingress --all-namespaces -o json | jq -r '
  .items[] | "\(.metadata.namespace)/\(.metadata.name): \(.spec.rules[].http.paths | length) paths"'

# Check if Gateway API CRDs are installed
kubectl get crd | grep gateway.networking.k8s.io
```

---

## Implementation-Specific Notes

### Istio

- Recommended `gatewayClassName: istio`
- Supports `ExtensionRef` for WasmPlugin, RequestAuthentication, etc.
- Mesh gateways via `istio-mesh` gateway class
- Canary via `backendRefs[].weight`

### NGINX Gateway

- Recommended `gatewayClassName: nginx`
- Supports `filters.type: ExtensionRef → Policy` for rate limiting
- `listener.tls.mode: Terminate` only (no Passthrough)

### Contour

- Recommended `gatewayClassName: contour`
- Supports HTTPRoute and TLSRoute
- Full Envoy feature parity

### Cilium

- Recommended `gatewayClassName: cilium`
- Native eBPF performance
- L7 network policies integrate with Gateway API routes

---

## Troubleshooting

```bash
# Check Gateway status
kubectl describe gateway <name>

# Check route acceptance
kubectl get httproute <name> -o jsonpath='{.status.parents[*].conditions[*].reason}'

# Common issues:
# - "NoResources" → GatewayClass controller not installed
# - "NotAccepted" → listener hostname/namespace mismatch
# - route in Pending → missing ReferenceGrant
# - 404 on route → parentRefs doesn't match any listener

# Watch Gateway API resources
kubectl get gateway,httproute,grpcroute,tlsroute,referencegrant --all-namespaces -w
```

---

## Sources

- [Gateway API Docs](https://gateway-api.sigs.k8s.io)
- [Gateway API v1.2 Spec](https://gateway-api.sigs.k8s.io/reference/spec/)
- [Istio Gateway API](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/)
- [NGINX Gateway Fabric](https://github.com/nginxinc/nginx-gateway-fabric)
- [Cilium Gateway API](https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/)
- [Migration from Ingress](https://gateway-api.sigs.k8s.io/guides/migrating-from-ingress/)

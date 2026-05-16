#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") -n <name> -i <image> [-p <port>] [-r <replicas>] [-o <dir>] [-h]

Required:
  -n <name>    Service/deployment name (e.g. api, frontend)
  -i <image>   Container image (e.g. myregistry.com/app:1.0)

Optional:
  -p <port>    Container port (default: 8080)
  -r <count>   Replicas (default: 3)
  -o <dir>     Output directory (default: ./manifests)
  -h           Show this help

Generates: deployment.yaml, service.yaml, hpa.yaml, pdb.yaml
EOF
  exit 0
}

NAME=""
IMAGE=""
PORT=8080
REPLICAS=3
OUTDIR="./manifests"

while getopts "n:i:p:r:o:h" opt; do
  case "$opt" in
    n) NAME="$OPTARG" ;;
    i) IMAGE="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    r) REPLICAS="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ -z "$NAME" ] || [ -z "$IMAGE" ]; then
  echo "ERROR: -n and -i are required"
  usage
fi

mkdir -p "$OUTDIR"

# ── deployment.yaml ───────────────────────────────────────────────────────
cat > "$OUTDIR/deployment.yaml" <<DEPLOY
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${NAME}
  labels:
    app: ${NAME}
    env: prod
spec:
  replicas: ${REPLICAS}
  revisionHistoryLimit: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: ${NAME}
  template:
    metadata:
      labels:
        app: ${NAME}
        version: stable
    spec:
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 60
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: ${NAME}
          image: ${IMAGE}
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: ${PORT}
              protocol: TCP
              name: http
          env:
            - name: PORT
              value: "${PORT}"
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          livenessProbe:
            httpGet:
              path: /health
              port: ${PORT}
            initialDelaySeconds: 10
            periodSeconds: 15
            timeoutSeconds: 3
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: ${PORT}
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 2
          startupProbe:
            httpGet:
              path: /health
              port: ${PORT}
            initialDelaySeconds: 3
            periodSeconds: 5
            failureThreshold: 30
          securityContext:
            runAsNonRoot: true
            runAsUser: 10001
            runAsGroup: 10001
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
DEPLOY

# ── service.yaml ──────────────────────────────────────────────────────────
cat > "$OUTDIR/service.yaml" <<SVC
apiVersion: v1
kind: Service
metadata:
  name: ${NAME}
  labels:
    app: ${NAME}
    env: prod
spec:
  type: ClusterIP
  selector:
    app: ${NAME}
  ports:
    - port: 80
      targetPort: ${PORT}
      protocol: TCP
      name: http
SVC

# ── hpa.yaml ──────────────────────────────────────────────────────────────
cat > "$OUTDIR/hpa.yaml" <<HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${NAME}-hpa
  labels:
    app: ${NAME}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${NAME}
  minReplicas: ${REPLICAS}
  maxReplicas: $((REPLICAS * 5))
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
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 60
        - type: Pods
          value: 4
          periodSeconds: 60
      selectPolicy: Max
HPA

# ── pdb.yaml ──────────────────────────────────────────────────────────────
if [ "$REPLICAS" -gt 1 ]; then
  MIN_AVAILABLE=$(( REPLICAS > 2 ? REPLICAS - 1 : 1 ))
  cat > "$OUTDIR/pdb.yaml" <<PDB
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ${NAME}-pdb
  labels:
    app: ${NAME}
spec:
  minAvailable: ${MIN_AVAILABLE}
  selector:
    matchLabels:
      app: ${NAME}
PDB
fi

echo ""
echo "Generated manifests in ${OUTDIR}/ for '${NAME}':"
echo "  deployment.yaml  (${IMAGE}, ${REPLICAS} replicas, port ${PORT})"
echo "  service.yaml     (ClusterIP :80 -> :${PORT})"
echo "  hpa.yaml         (${REPLICAS}–$((REPLICAS * 5)) pods, CPU 70% / mem 80%)"
if [ "$REPLICAS" -gt 1 ]; then
  echo "  pdb.yaml         (minAvailable: ${MIN_AVAILABLE})"
fi
echo ""
echo "Apply with:  kubectl apply -f ${OUTDIR}/ -n <namespace>"

# python-dev-environment

A secure, non-root Python development environment for VS Code, designed for Talos Linux Kubernetes clusters and deployed via ArgoCD. This Helm chart deploys a persistent development container (based on the official Microsoft devcontainers Python image) with workspace storage, networking, and security hardening.

## Features

- **Non-root security**: Runs the development container as a non-root user (UID/GID 1000) with privilege escalation disabled and all Linux capabilities dropped.
- **Persistent workspace**: PVC-backed storage mounted at `/workspace` survives pod restarts.
- **VS Code ready**: Designed for use with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension via `kubectl` port-forward or ingress.
- **ArgoCD friendly**: Includes recommended ArgoCD annotations and sync-wave support.
- **Configurable networking**: Optional Ingress (Traefik/cert-manager), NetworkPolicy, and Service annotations.
- **Production hardening**: PodDisruptionBudget support, resource limits, liveness probes, and pod anti-affinity topology spread constraints.
- **Extensible**: Supports extra volumes, volume mounts, environment variables, and secret/configmap references.

## Prerequisites

- Kubernetes cluster (tested on Talos Linux)
- Helm 3.x
- (Optional) ArgoCD for GitOps deployment
- (Optional) Traefik or other Ingress controller for external access
- (Optional) cert-manager for TLS certificate management

## Installation

### Via Helm CLI

```bash
# Add the repository (if published)
helm repo add python-dev https://charts.bryanjbelanger.dev
helm repo update

# Install the chart
helm install python-dev python-dev/python-dev-environment

# Or install from local source
helm install python-dev ./python-dev-chart
```

### Via ArgoCD

Create an ArgoCD Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: python-dev-environment
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/bryanjbelanger/python-dev-environment.git
    targetRevision: HEAD
    path: python-dev-chart
  destination:
    server: https://kubernetes.default.svc
    namespace: python-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Configuration

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of pod replicas | `1` |
| `nameOverride` | Override the resource name prefix | `""` |
| `fullnameOverride` | Override the full resource name | `""` |

### Image

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `mcr.microsoft.com/devcontainers/python` |
| `image.tag` | Image tag (Python version) | `3.12` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Storage

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.size` | PVC size for the workspace | `5Gi` |
| `storage.accessMode` | PVC access mode | `ReadWriteOnce` |
| `storage.storageClassName` | StorageClass name (optional) | `""` |

### Security

| Parameter | Description | Default |
|-----------|-------------|---------|
| `securityContext.runAsNonRoot` | Enforce non-root execution | `true` |
| `securityContext.runAsUser` | Container user ID | `1000` |
| `securityContext.runAsGroup` | Container group ID | `1000` |
| `securityContext.fsGroup` | Filesystem group ID | `1000` |
| `containerSecurityContext.allowPrivilegeEscalation` | Disallow privilege escalation | `false` |
| `containerSecurityContext.privileged` | Run in privileged mode | `false` |

### Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable the Kubernetes Service | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container target port | `8080` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.hosts[0].host` | Ingress hostname | `python-dev.home` |

### Probes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `probes.liveness.enabled` | Enable liveness probe | `true` |
| `probes.liveness.initialDelaySeconds` | Initial delay before first probe | `30` |
| `probes.readiness.enabled` | Enable readiness probe | `false` |
| `probes.startup.enabled` | Enable startup probe | `false` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `2` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `512Mi` |

### Advanced

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env` | Environment variables | `[{name: TZ, value: Etc/UTC}]` |
| `envFrom` | References to secrets/configmaps | `[]` |
| `extraVolumes` | Additional pod volumes | `[]` |
| `extraVolumeMounts` | Additional container volume mounts | `[]` |
| `podLabels` | Custom pod labels | `{}` |
| `podAnnotations` | Custom pod annotations | `{}` |
| `nodeSelector` | Node selector constraints | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity/anti-affinity rules | `{}` |
| `topologySpreadConstraints` | Topology spread constraints | `[]` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `false` |
| `priorityClassName` | Priority class name | `""` |
| `terminationGracePeriodSeconds` | Termination grace period | `30` |

## Connecting to the Development Environment

### Port-Forwarding (no Ingress)

```bash
# Forward local port 8080 to the container's target port
kubectl port-forward pod/python-dev-environment-0 8080:8080

# Then connect using VS Code Dev Containers:
# - Cmd+Shift+P → "Dev Containers: Attach to Running Container..."
# - Select the pod
```

### Via Ingress

If Ingress is enabled with proper DNS and TLS configuration:

```
https://python-dev.home
```

## Security Considerations

- **Non-root execution**: The container runs as UID 1000 with `runAsNonRoot: true`.
- **Capabilities**: All Linux capabilities are dropped at the container level.
- **Privilege escalation**: Explicitly disabled (`allowPrivilegeEscalation: false`).
- **Network isolation**: Optional NetworkPolicy restricts ingress/egress traffic.
- **Pod security**: PodSecurityContext sets `fsGroup` for proper filesystem permissions on the mounted PVC.

> **Note**: The `readOnlyRootFilesystem` is set to `false` by default because the devcontainer image writes temporary files to the root filesystem during operation. If you enable it, you may need to mount additional `emptyDir` volumes for `/tmp` and other writable paths.

## Development

### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) 3.x
- `helm-docs` (optional, for generating documentation)

### Linting

```bash
helm lint .
```

### Template Rendering

```bash
# Render templates with default values
helm template python-dev .

# Render with custom values
helm template python-dev -f my-values.yaml .
```

### Testing

```bash
helm install python-dev ./ --dry-run --debug
```

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.

## Maintainers

- **Bryan Belanger** - [bryanbelanger@hotmail.com](mailto:bryanbelanger@hotmail.com) - [GitHub](https://github.com/bryanjbelanger)
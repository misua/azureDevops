# Azure DevOps GitOps CI/CD Workflow

A complete GitOps implementation for Kubernetes deployments using Azure DevOps, Azure Container Registry, and ArgoCD.

## Overview

This project implements a dual-repository GitOps pattern:
- **Application Repository** (`app-repo/`): Source code, Dockerfile, Helm charts
- **Configuration Repository** (`config-repo/`): Environment-specific Kubernetes configurations

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   App Repo  │─────▶│  CI Pipeline │─────▶│     ACR     │
└─────────────┘      └──────────────┘      └─────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │ Config Repo  │
                     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐      ┌─────────────┐
                     │GitOps Operator│─────▶│ AKS Cluster │
                     └──────────────┘      └─────────────┘
```

## Quick Start

### Prerequisites

- Azure subscription
- Azure DevOps organization
- AKS cluster or Arc-enabled Kubernetes
- Azure Container Registry
- kubectl, helm, argocd CLI

### 1. Setup Azure Resources

```bash
# Create resource group
az group create --name rg-gitops --location eastus

# Create AKS cluster
az aks create \
  --resource-group rg-gitops \
  --name aks-cluster \
  --node-count 2 \
  --enable-managed-identity \
  --generate-ssh-keys

# Create Azure Container Registry
az acr create \
  --resource-group rg-gitops \
  --name myacr \
  --sku Standard

# Attach ACR to AKS
az aks update \
  --resource-group rg-gitops \
  --name aks-cluster \
  --attach-acr myacr
```

### 2. Setup Azure DevOps Repositories

1. Create two repositories in Azure DevOps:
   - `app-repo` - Import from `./app-repo/`
   - `config-repo` - Import from `./config-repo/`

2. Create service connections:
   - Azure Container Registry connection
   - Azure Resource Manager connection

3. Create Personal Access Token (PAT) with Code (Read & Write) permissions

### 3. Configure Pipelines

**Application Pipeline:**
```bash
cd app-repo
# Create pipeline from .azure-pipelines/ci-pipeline.yml
# Update variables:
#   - containerRegistry
#   - dockerRegistryServiceConnection
```

**Configuration Pipeline:**
```bash
cd config-repo
# Create pipeline from .azure-pipelines/validation-pipeline.yml
```

### 4. Deploy GitOps Operator

```bash
cd gitops-operator/argocd
./install-argocd.sh aks-cluster rg-gitops

# Create repository secret
kubectl apply -f repository-secret.yaml

# Deploy application
kubectl apply -f application.yaml
```

### 5. Verify Deployment

```bash
# Check GitOps sync status
argocd app get sample-app-dev

# Check application pods
kubectl get pods -l app=sample-app

# Test application
kubectl port-forward svc/sample-app 8080:80
curl http://localhost:8080
```

## Repository Structure

```
.
├── app-repo/                    # Application repository
│   ├── src/                     # Application source code
│   ├── Dockerfile               # Container image definition
│   ├── k8s/helm/sample-app/     # Helm chart
│   └── .azure-pipelines/        # CI pipeline
├── config-repo/                 # Configuration repository
│   ├── environments/            # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── .azure-pipelines/        # Validation pipeline
├── gitops-operator/             # GitOps operator configurations
│   ├── argocd/                  # ArgoCD setup
│   └── monitoring/              # Monitoring configs
└── docs/                        # Documentation
    ├── ARCHITECTURE.md
    ├── RUNBOOK.md
    └── TROUBLESHOOTING.md
```

## Workflow

### Development Flow

1. Developer pushes code to `app-repo`
2. CI pipeline builds, tests, and containerizes application
3. Pipeline pushes image to ACR with commit SHA tag
4. Pipeline updates `config-repo` with new image tag
5. GitOps operator detects change and deploys to cluster

### Promotion Flow

1. Test in dev environment
2. Update staging environment values
3. Create PR for production
4. Require manual approvals
5. Merge triggers automated production deployment

## Environment Configuration

| Environment | Replicas | Resources | Auto-scaling | Service Type |
|-------------|----------|-----------|--------------|--------------|
| Dev         | 1        | Low       | Disabled     | ClusterIP    |
| Staging     | 2        | Medium    | Enabled      | ClusterIP    |
| Production  | 3        | High      | Enabled      | LoadBalancer |

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Operations Runbook](docs/RUNBOOK.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## Security Considerations

- Use managed identities where possible
- Rotate PATs regularly (90 days)
- Enable branch protection on config repo
- Implement RBAC for GitOps operator
- Scan container images for vulnerabilities
- Use Azure Key Vault for secrets

## Monitoring

- Prometheus metrics from ArgoCD
- Azure Monitor for AKS cluster
- Application Insights for application telemetry
- Alert on sync failures and drift detection

## Support

For issues and questions:
1. Check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Review pipeline logs in Azure DevOps
3. Check GitOps operator logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`
4. Contact DevOps team

## License

MIT

# GitOps Architecture Overview

## Repository Structure

### Application Repository (`app-repo`)
Contains application source code and base Kubernetes manifests.

```
app-repo/
├── src/                    # Application source code
├── Dockerfile              # Container image definition
├── k8s/helm/sample-app/    # Helm chart templates
└── .azure-pipelines/       # CI pipeline
```

**Pipeline Flow:**
1. Code push triggers CI pipeline
2. Build and test application
3. Build and push Docker image to ACR
4. Update config repo with new image tag

### Configuration Repository (`config-repo`)
Single source of truth for deployment state.

```
config-repo/
├── environments/
│   ├── dev/values.yaml      # Dev environment config
│   ├── staging/values.yaml  # Staging environment config
│   └── prod/values.yaml     # Production environment config
└── .azure-pipelines/        # Validation pipeline
```

**Pipeline Flow:**
1. Config changes trigger validation
2. YAML lint and Kubernetes schema validation
3. Security policy checks
4. Manual approval for production changes

## GitOps Operator

### ArgoCD
- Rich UI for visualization and monitoring
- RBAC and multi-tenancy support
- Manual and automated sync modes
- Pull-based reconciliation with configurable intervals
- Automatic drift detection and self-healing
- Built-in rollback capabilities

## Data Flow

```
Developer → App Repo → CI Pipeline → Container Registry
                                    ↓
                              Config Repo → GitOps Operator → Kubernetes Cluster
```

## Security

- Service Principal authentication for ACR
- PAT-based authentication for Azure DevOps repos
- RBAC for GitOps operator
- Branch protection on config repo
- Manifest validation before deployment

## MODIFIED Requirements

### Requirement: Operator Deployment
The GitOps operator SHALL be deployed to the target AKS or Azure Arc-enabled Kubernetes cluster with appropriate RBAC permissions using ArgoCD.

#### Scenario: ArgoCD installation on AKS
- **WHEN** deploying ArgoCD as the GitOps operator
- **THEN** install ArgoCD with the installation script and configure repository connection using Azure DevOps credentials

#### Scenario: ArgoCD installation on Arc cluster
- **WHEN** deploying ArgoCD on Azure Arc-enabled Kubernetes
- **THEN** install ArgoCD with Azure Arc integration and configure repository connection using service principal credentials

### Requirement: Health Monitoring
The GitOps operator SHALL report synchronization status, health checks, and deployment errors through ArgoCD metrics and logs.

#### Scenario: Successful sync status
- **WHEN** manifests are successfully applied to the cluster
- **THEN** ArgoCD reports sync status as "Synced" with timestamp and commit SHA

#### Scenario: Deployment failure notification
- **WHEN** manifest application fails (e.g., resource quota exceeded)
- **THEN** ArgoCD reports the failure with error details and maintains the previous working state

#### Scenario: Metrics exposure
- **WHEN** monitoring the GitOps operator
- **THEN** ArgoCD exposes Prometheus metrics for sync status, reconciliation duration, and error rates

## REMOVED Requirements

### Requirement: Operator Deployment - Flux Installation
**Reason**: Standardizing on ArgoCD only
**Migration**: Use ArgoCD installation script instead of Flux bootstrap

#### Scenario: Flux installation on AKS
- **WHEN** deploying Flux as the GitOps operator
- **THEN** install Flux controllers with `flux bootstrap` connected to the Azure DevOps config repository

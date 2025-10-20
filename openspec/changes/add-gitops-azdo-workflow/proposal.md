## Why
Implement a GitOps-based CI/CD workflow using Azure DevOps to manage Kubernetes deployments with a dual-repository pattern (application code + configuration) and automated reconciliation via a GitOps operator.

## What Changes
- Application pipeline: Build, test, containerize app code and push manifests to config repo
- Configuration pipeline: Validate and manage environment-specific Kubernetes manifests
- GitOps operator integration: Enable automated deployment reconciliation from config repo to AKS/Arc clusters
- Staged rollout: Implement in phases (app pipeline → config pipeline → operator integration)

## Impact
- Affected specs: `app-pipeline`, `config-pipeline`, `gitops-operator` (new capabilities)
- Affected code: Azure DevOps pipeline YAML files, Kubernetes manifests, Helm charts
- Infrastructure: Azure Repos (2 repositories), Azure Container Registry, AKS/Arc-enabled Kubernetes

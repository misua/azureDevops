# Configuration Repository

This repository contains the desired state for Kubernetes deployments managed via GitOps.

## Repository Structure

```
config-repo/
├── environments/
│   ├── dev/          # Development environment configurations
│   ├── staging/      # Staging environment configurations
│   └── prod/         # Production environment configurations
├── .azure-pipelines/ # Validation pipelines
└── base/             # Base configurations (optional)
```

## Environment-Specific Configurations

Each environment directory contains:
- `values.yaml` - Helm values override for the environment

## Branch Protection Rules

### Production Branch (`prod`)
- Requires pull request with 2 approvals
- Requires validation pipeline to pass
- No direct commits allowed
- Requires linear history

### Staging Branch (`staging`)
- Requires pull request with 1 approval
- Requires validation pipeline to pass

### Main Branch (`main`)
- Requires validation pipeline to pass
- Used for development environment

## Workflow

1. Application pipeline updates image tags in environment-specific `values.yaml`
2. Changes trigger validation pipeline
3. For production, manual approval required
4. GitOps operator syncs approved changes to cluster

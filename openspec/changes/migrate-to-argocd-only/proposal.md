## Why
Simplify the GitOps implementation by standardizing on ArgoCD as the sole GitOps operator, removing Flux references and configurations to reduce complexity and maintenance overhead.

## What Changes
- Remove all Flux-related files and directories
- Update documentation to reference only ArgoCD
- Modify monitoring configurations to use ArgoCD metrics
- Update installation scripts and guides to ArgoCD-only workflow
- Revise spec requirements to reflect ArgoCD as the standard operator

## Impact
- Affected specs: `gitops-operator` (modified)
- Affected code: Documentation files, monitoring configs, installation scripts
- Removed: `gitops-operator/flux/` directory and all Flux references
- Updated: README.md, ARCHITECTURE.md, RUNBOOK.md, TROUBLESHOOTING.md

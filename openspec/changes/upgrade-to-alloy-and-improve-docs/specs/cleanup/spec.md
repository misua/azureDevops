## ADDED Requirements

### Requirement: Azure Resource Cleanup
The system SHALL provide scripts to cleanly remove all Azure resources created during setup.

#### Scenario: Complete Azure cleanup
- **WHEN** user runs Azure cleanup script
- **THEN** script removes Resource Group, AKS cluster, ACR, Storage Account, and all associated resources

#### Scenario: Selective resource cleanup
- **WHEN** user wants to keep some resources
- **THEN** script provides options to selectively delete resources (e.g., keep ACR but delete AKS)

#### Scenario: Cleanup verification
- **WHEN** cleanup script completes
- **THEN** script verifies all resources are deleted and reports any remaining resources

### Requirement: Kubernetes Resource Cleanup
The system SHALL provide scripts to remove all Kubernetes deployments and configurations.

#### Scenario: Observability stack cleanup
- **WHEN** user runs observability cleanup script
- **THEN** script removes Loki, Tempo, Pyroscope, Alloy, Grafana, and all PVCs

#### Scenario: Application cleanup
- **WHEN** user runs application cleanup script
- **THEN** script removes all application deployments, services, and config maps

#### Scenario: ArgoCD cleanup
- **WHEN** user runs ArgoCD cleanup script
- **THEN** script removes ArgoCD applications, notifications, and ArgoCD installation

### Requirement: Cleanup Documentation
The system SHALL document cleanup procedures and provide warnings about data loss.

#### Scenario: Cleanup warnings
- **WHEN** user views cleanup documentation
- **THEN** documentation clearly warns about permanent data deletion and recommends backups

#### Scenario: Cleanup order
- **WHEN** user follows cleanup guide
- **THEN** documentation specifies correct order: Applications → Observability → ArgoCD → Kubernetes → Azure

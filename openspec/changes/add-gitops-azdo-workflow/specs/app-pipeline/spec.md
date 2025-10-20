## ADDED Requirements

### Requirement: Application Build and Containerization
The application pipeline SHALL build source code, run tests, and create container images tagged with commit SHA and semantic version.

#### Scenario: Successful build and push
- **WHEN** code is pushed to the main branch
- **THEN** the pipeline builds the application, runs unit tests, creates a Docker image, and pushes it to Azure Container Registry with tags `<commit-sha>` and `<version>`

#### Scenario: Build failure stops pipeline
- **WHEN** unit tests fail during the build
- **THEN** the pipeline stops execution and reports failure without creating or pushing container images

### Requirement: Manifest Generation
The application pipeline SHALL generate or update Kubernetes manifests with the new container image tag and commit them to the configuration repository.

#### Scenario: Helm chart values update
- **WHEN** a new container image is successfully pushed
- **THEN** the pipeline updates the Helm values file in the config repo with the new image tag and commits the change with a descriptive message

#### Scenario: Kustomize overlay update
- **WHEN** using Kustomize for manifest management
- **THEN** the pipeline updates the kustomization.yaml with the new image tag using `kustomize edit set image`

### Requirement: Config Repository Integration
The application pipeline SHALL authenticate to the configuration repository and push manifest updates using a service principal or PAT with minimal required permissions.

#### Scenario: Automated commit to config repo
- **WHEN** manifest updates are generated
- **THEN** the pipeline commits changes to the config repo's environment-specific branch (e.g., `dev`, `staging`, `prod`) with commit message format: `chore: update <app-name> to <version> (<commit-sha>)`

#### Scenario: Authentication failure handling
- **WHEN** authentication to the config repo fails
- **THEN** the pipeline fails with a clear error message and does not proceed with deployment

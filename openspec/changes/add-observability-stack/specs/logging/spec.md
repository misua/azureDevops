## ADDED Requirements

### Requirement: Centralized Log Aggregation
The system SHALL aggregate logs from all application pods, pipelines, and infrastructure components into Grafana Loki for centralized querying and analysis.

#### Scenario: Application logs collected
- **WHEN** an application pod emits logs
- **THEN** Promtail collects the logs and forwards them to Loki with pod metadata (namespace, pod name, container)

#### Scenario: Pipeline logs ingested
- **WHEN** Azure DevOps pipeline executes
- **THEN** pipeline logs are sent to Loki with build metadata (pipeline name, build ID, commit SHA)

#### Scenario: Log retention policy
- **WHEN** logs are stored in Loki
- **THEN** logs are retained for 30 days in Azure Blob Storage with automatic cleanup

### Requirement: Structured Logging
The application SHALL emit structured logs in JSON format with consistent fields for correlation and filtering.

#### Scenario: Structured log format
- **WHEN** application logs an event
- **THEN** log entry includes timestamp, level, message, correlation ID, trace ID, and span ID

#### Scenario: Log levels enforced
- **WHEN** application runs in production
- **THEN** log level is set to INFO or higher, with DEBUG available via configuration

### Requirement: Log Querying
The system SHALL provide LogQL query interface through Grafana for searching and filtering logs across all sources.

#### Scenario: Query logs by correlation ID
- **WHEN** user searches for a specific correlation ID
- **THEN** all related logs across services and pipelines are returned in chronological order

#### Scenario: Filter logs by environment
- **WHEN** user filters by environment label
- **THEN** only logs from the specified environment (dev/staging/prod) are displayed

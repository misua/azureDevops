## MODIFIED Requirements

### Requirement: Centralized Log Aggregation
The system SHALL aggregate logs from all application pods, pipelines, and infrastructure components into Grafana Loki using Grafana Alloy as the collection agent.

#### Scenario: Application logs collected via Alloy
- **WHEN** an application pod emits logs
- **THEN** Grafana Alloy collects the logs and forwards them to Loki with pod metadata (namespace, pod name, container, labels)

#### Scenario: Alloy processes structured logs
- **WHEN** logs are in JSON format
- **THEN** Alloy parses JSON fields and extracts trace_id, span_id, and correlation_id for correlation

#### Scenario: Alloy handles multiple outputs
- **WHEN** Alloy receives telemetry data
- **THEN** logs are sent to Loki, metrics to Prometheus, and traces to Tempo from a single agent

## REMOVED Requirements

### Requirement: Promtail-based Log Collection
**Reason**: Replaced by Grafana Alloy for unified telemetry collection
**Migration**: Deploy Alloy DaemonSet instead of Promtail

#### Scenario: Promtail log collection
- **WHEN** Promtail runs on each node
- **THEN** it collects container logs and sends to Loki

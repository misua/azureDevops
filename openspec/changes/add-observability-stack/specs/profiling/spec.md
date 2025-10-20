## ADDED Requirements

### Requirement: Continuous Profiling
The system SHALL continuously profile application performance using Pyroscope to identify CPU, memory, and allocation hotspots.

#### Scenario: CPU profiling enabled
- **WHEN** application runs in any environment
- **THEN** Pyroscope collects CPU profiles every 10 seconds with minimal overhead (<2%)

#### Scenario: Memory profiling enabled
- **WHEN** application allocates memory
- **THEN** Pyroscope tracks memory allocations and heap usage

#### Scenario: Profile data retention
- **WHEN** profiles are collected
- **THEN** profile data is retained for 7 days with aggregation for long-term trends

### Requirement: Profile Visualization
The system SHALL provide flame graphs and comparison views in Grafana for analyzing performance profiles.

#### Scenario: Flame graph display
- **WHEN** user views CPU profile
- **THEN** flame graph shows call stack hierarchy with time spent in each function

#### Scenario: Profile comparison
- **WHEN** user compares two time periods
- **THEN** diff flame graph highlights performance regressions or improvements

### Requirement: Profile Correlation
The system SHALL correlate profiles with traces and logs using trace ID for root cause analysis.

#### Scenario: Profile linked to trace
- **WHEN** viewing a slow trace span
- **THEN** corresponding CPU profile is available for that time range

#### Scenario: Profile triggered by alert
- **WHEN** performance alert fires
- **THEN** profile snapshot is automatically captured for analysis

### Requirement: Profile Labeling
The system SHALL tag profiles with environment, version, and deployment metadata for filtering and comparison.

#### Scenario: Profile filtering by version
- **WHEN** user filters profiles by application version
- **THEN** only profiles from that specific deployment are displayed

#### Scenario: Environment comparison
- **WHEN** comparing dev vs prod profiles
- **THEN** side-by-side flame graphs show performance differences

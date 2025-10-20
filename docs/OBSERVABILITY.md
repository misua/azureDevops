# Observability Architecture

## Overview

Comprehensive observability stack providing end-to-end visibility from code commit to production deployment using the three pillars of observability: **Logs**, **Traces**, and **Profiles**.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   App Pods  │────▶│   Promtail   │────▶│    Loki     │
└─────────────┘     └──────────────┘     └─────────────┘
                                                 │
┌─────────────┐     ┌──────────────┐            │
│   App Code  │────▶│ OpenTelemetry│────▶┌──────▼──────┐
└─────────────┘     │   (OTLP)     │     │   Grafana   │
                    └──────────────┘     │  (Unified)  │
                           │              └──────▲──────┘
                           ▼                     │
                    ┌──────────────┐            │
                    │    Tempo     │────────────┘
                    └──────────────┘            │
                                                 │
┌─────────────┐     ┌──────────────┐            │
│ Application │────▶│  Pyroscope   │────────────┘
└─────────────┘     └──────────────┘
```

## Components

### 1. Grafana Loki (Logging)
**Purpose**: Centralized log aggregation and querying

**Features**:
- Structured JSON logs with correlation IDs
- 30-day retention in Azure Blob Storage
- LogQL query language
- Automatic correlation with traces via trace_id

**Data Sources**:
- Application pods (via Promtail)
- Azure DevOps pipelines
- Infrastructure components

**Configuration**:
```bash
# Deploy Loki
kubectl apply -f observability/loki/loki-deployment.yaml

# Deploy Promtail (log collector)
kubectl apply -f observability/promtail/promtail-daemonset.yaml
```

### 2. Grafana Tempo (Tracing)
**Purpose**: Distributed tracing across services and pipelines

**Features**:
- OpenTelemetry Protocol (OTLP) ingestion
- 14-day trace retention
- TraceQL query language
- Automatic correlation with logs and metrics

**Sampling**:
- Production: 10% sampling
- Dev/Staging: 100% sampling

**Configuration**:
```bash
# Deploy Tempo
kubectl apply -f observability/tempo/tempo-deployment.yaml

# Traces sent via OTLP to: http://tempo.observability.svc.cluster.local:4317
```

### 3. Pyroscope (Profiling)
**Purpose**: Continuous performance profiling

**Features**:
- CPU profiling (<2% overhead)
- Memory allocation tracking
- 7-day profile retention
- Flame graph visualization

**Configuration**:
```bash
# Deploy Pyroscope
kubectl apply -f observability/pyroscope/pyroscope-deployment.yaml

# Profiles sent to: http://pyroscope.observability.svc.cluster.local:4040
```

### 4. Grafana (Unified Visualization)
**Purpose**: Single pane of glass for all observability data

**Data Sources**:
- Prometheus (metrics)
- Loki (logs)
- Tempo (traces)
- Pyroscope (profiles)

**Dashboards**:
- **Deployment Timeline**: Track all deployments across environments
- **Application Performance**: Logs + Traces + Profiles correlation
- **Pipeline Observability**: CI/CD pipeline execution traces

**Configuration**:
```bash
# Deploy Grafana with data sources
kubectl apply -f observability/grafana/grafana-datasources.yaml

# Access: http://<grafana-external-ip>:3000
# Default credentials: admin/admin
```

## Application Instrumentation

### Structured Logging (Serilog)
```csharp
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "SampleApp")
    .WriteTo.Console(new CompactJsonFormatter())
    .CreateLogger();
```

**Log Format**:
```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "Information",
  "message": "Request processed",
  "trace_id": "abc123...",
  "span_id": "def456...",
  "correlation_id": "xyz789..."
}
```

### Distributed Tracing (OpenTelemetry)
```csharp
builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddOtlpExporter(options =>
            {
                options.Endpoint = new Uri("http://tempo:4317");
            });
    });
```

### Continuous Profiling (Pyroscope)
```csharp
Pyroscope.Profiler.Profiler.Start(
    applicationName: "sample-app",
    serverAddress: "http://pyroscope:4040",
    tags: new Dictionary<string, string>
    {
        ["environment"] = "production",
        ["version"] = "1.0.0"
    }
);
```

## Deployment Notifications

### ArgoCD Notifications
Automatic notifications for all deployment events:

**Channels**:
- **Production**: #prod-deployments (Slack) + ops@example.com
- **Staging**: #staging-deployments (Slack) + qa@example.com
- **Dev**: #dev-deployments (Slack)

**Events**:
- ✅ Deployment successful
- ❌ Deployment failed
- 🔄 Deployment in progress

**Configuration**:
```bash
# Deploy ArgoCD notifications
kubectl apply -f gitops-operator/argocd/argocd-notifications.yaml

# Update secrets with Slack token and email credentials
kubectl edit secret argocd-notifications-secret -n argocd
```

## Alerting

### Alert Rules

**High Error Rate**:
- Trigger: >5% error rate for 5 minutes
- Action: Slack alert with link to error logs and traces

**Slow Traces**:
- Trigger: P95 latency >2s for 10 minutes
- Action: Slack alert with link to slow traces and CPU profiles

**Memory Leak**:
- Trigger: 20% memory increase over 1 hour
- Action: Slack alert with link to memory profiles

**Deployment Failed**:
- Trigger: ArgoCD sync failure
- Action: Critical Slack + email alert with error details

## Query Examples

### Logs (LogQL)

**Find all errors for a specific trace**:
```logql
{app="sample-app"} | json | trace_id="abc123..."
```

**Error rate by environment**:
```logql
sum by (environment) (rate({app="sample-app", level="error"}[5m]))
```

### Traces (TraceQL)

**Find slow requests**:
```traceql
{service.name="sample-app"} && duration > 2s
```

**Find traces with errors**:
```traceql
{service.name="sample-app" && status=error}
```

### Profiles

**CPU hotspots**:
- Navigate to Pyroscope datasource
- Select: `process_cpu:cpu:nanoseconds`
- Filter: `{service_name="sample-app"}`
- View flame graph

**Memory allocations**:
- Select: `memory:alloc_objects:count`
- Compare time ranges to identify leaks

## Storage & Retention

| Component | Backend | Retention | Storage |
|-----------|---------|-----------|---------|
| Loki | Azure Blob | 30 days | ~10GB/day |
| Tempo | Azure Blob | 14 days | ~5GB/day |
| Pyroscope | Local PV | 7 days | ~2GB/day |
| Grafana | EmptyDir | N/A | <1GB |

## Cost Optimization

- **Trace Sampling**: 10% in production reduces storage by 90%
- **Log Filtering**: Promtail filters debug logs in production
- **Profile Aggregation**: Pyroscope aggregates old profiles
- **Azure Blob Storage**: Cost-effective long-term storage

## Troubleshooting

See [OBSERVABILITY-TROUBLESHOOTING.md](./OBSERVABILITY-TROUBLESHOOTING.md) for common issues and solutions.

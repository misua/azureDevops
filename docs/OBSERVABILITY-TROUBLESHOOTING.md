# Observability Troubleshooting Guide

## Common Issues

### Loki Not Receiving Logs

**Symptoms**: No logs appearing in Grafana

**Diagnosis**:
```bash
# Check Promtail pods
kubectl get pods -n observability -l app=promtail

# Check Promtail logs
kubectl logs -n observability -l app=promtail --tail=100

# Check Loki logs
kubectl logs -n observability -l app=loki --tail=100
```

**Solutions**:
1. **Promtail not running**: Check DaemonSet status
   ```bash
   kubectl describe daemonset promtail -n observability
   ```

2. **Loki endpoint unreachable**: Verify service
   ```bash
   kubectl get svc loki -n observability
   curl http://loki.observability.svc.cluster.local:3100/ready
   ```

3. **Azure Blob Storage auth failure**: Check secret
   ```bash
   kubectl get secret loki-azure-secret -n observability -o yaml
   ```

### Traces Not Appearing in Tempo

**Symptoms**: No traces in Grafana Tempo datasource

**Diagnosis**:
```bash
# Check Tempo pod
kubectl get pods -n observability -l app=tempo

# Check Tempo logs
kubectl logs -n observability -l app=tempo --tail=100

# Test OTLP endpoint
curl http://tempo.observability.svc.cluster.local:4317
```

**Solutions**:
1. **Application not sending traces**: Check env vars
   ```bash
   kubectl get pod <app-pod> -o jsonpath='{.spec.containers[0].env}'
   ```

2. **OTLP endpoint wrong**: Verify in application logs
   ```bash
   kubectl logs <app-pod> | grep -i "otlp\|telemetry"
   ```

3. **Tempo storage issues**: Check Azure Blob access
   ```bash
   kubectl logs -n observability -l app=tempo | grep -i "azure\|storage"
   ```

### Pyroscope Not Collecting Profiles

**Symptoms**: No profiles in Pyroscope datasource

**Diagnosis**:
```bash
# Check Pyroscope pod
kubectl get pods -n observability -l app=pyroscope

# Check Pyroscope logs
kubectl logs -n observability -l app=pyroscope --tail=100

# Test Pyroscope API
curl http://pyroscope.observability.svc.cluster.local:4040/api/apps
```

**Solutions**:
1. **Profiler not initialized**: Check application startup logs
   ```bash
   kubectl logs <app-pod> | grep -i "pyroscope"
   ```

2. **Network connectivity**: Test from application pod
   ```bash
   kubectl exec <app-pod> -- curl http://pyroscope.observability.svc.cluster.local:4040
   ```

3. **Profiler overhead too high**: Adjust sampling rate in code

### ArgoCD Notifications Not Sending

**Symptoms**: No Slack/email notifications for deployments

**Diagnosis**:
```bash
# Check notifications controller
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-notifications-controller

# Check notifications logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller

# Check notification config
kubectl get cm argocd-notifications-cm -n argocd -o yaml
```

**Solutions**:
1. **Slack token invalid**: Update secret
   ```bash
   kubectl edit secret argocd-notifications-secret -n argocd
   ```

2. **Email SMTP failure**: Check SMTP settings
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller | grep -i "smtp\|email"
   ```

3. **Subscription not matching**: Verify label selectors
   ```bash
   kubectl get app -n argocd -o jsonpath='{.items[*].metadata.labels}'
   ```

### Grafana Dashboards Not Loading

**Symptoms**: Dashboards show "No data" or errors

**Diagnosis**:
```bash
# Check Grafana pod
kubectl get pods -n observability -l app=grafana

# Check Grafana logs
kubectl logs -n observability -l app=grafana --tail=100

# Test datasources
curl http://grafana.observability.svc.cluster.local:3000/api/datasources
```

**Solutions**:
1. **Datasource not configured**: Check ConfigMap
   ```bash
   kubectl get cm grafana-datasources -n observability -o yaml
   ```

2. **Datasource unreachable**: Test connectivity
   ```bash
   kubectl exec -n observability <grafana-pod> -- curl http://loki:3100/ready
   kubectl exec -n observability <grafana-pod> -- curl http://tempo:3200/ready
   kubectl exec -n observability <grafana-pod> -- curl http://pyroscope:4040/healthz
   ```

3. **Plugin not installed**: Check Grafana env vars
   ```bash
   kubectl get pod -n observability <grafana-pod> -o jsonpath='{.spec.containers[0].env}'
   ```

## Performance Issues

### High Loki Memory Usage

**Symptoms**: Loki pod OOMKilled or slow queries

**Solutions**:
1. Increase memory limits:
   ```yaml
   resources:
     limits:
       memory: 4Gi
   ```

2. Reduce retention period in config

3. Add more replicas for horizontal scaling

### Tempo Ingestion Lag

**Symptoms**: Traces delayed or dropped

**Solutions**:
1. Increase ingester resources
2. Adjust sampling rate in application
3. Scale Tempo horizontally

### Pyroscope Storage Full

**Symptoms**: Profiles not being stored

**Solutions**:
1. Increase PVC size:
   ```bash
   kubectl edit pvc storage-pyroscope-0 -n observability
   ```

2. Reduce retention period in config

3. Enable profile aggregation

## Debugging Queries

### Check Log Ingestion Rate
```logql
sum(rate({namespace="observability"}[1m])) by (app)
```

### Find Missing Traces
```traceql
{service.name="sample-app"} | select(span.status_code == "error")
```

### Profile Comparison
Compare CPU profiles between two time ranges to identify regressions.

## Support

For additional help:
1. Check Grafana Explore for raw data
2. Review component logs in observability namespace
3. Verify Azure Blob Storage connectivity
4. Contact DevOps team with trace/correlation IDs

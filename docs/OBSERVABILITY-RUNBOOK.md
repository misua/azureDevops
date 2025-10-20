# Observability Operations Runbook

## Common Queries

### Investigate Slow Request

1. **Find slow traces in Tempo**:
   ```traceql
   {service.name="sample-app"} && duration > 2s
   ```

2. **Get trace ID from results**

3. **Find related logs in Loki**:
   ```logql
   {app="sample-app"} | json | trace_id="<trace-id>"
   ```

4. **View CPU profile for that time range**:
   - Navigate to Pyroscope
   - Select time range matching trace
   - View flame graph for hotspots

### Debug Deployment Failure

1. **Check ArgoCD application status**:
   ```bash
   argocd app get sample-app-dev
   ```

2. **View deployment logs**:
   ```logql
   {namespace="argocd", app="argocd-application-controller"} |= "sample-app"
   ```

3. **Check application pod logs**:
   ```logql
   {namespace="default", app="sample-app"} | json | level="error"
   ```

4. **View deployment trace** (if available):
   ```traceql
   {service.name="azure-devops-pipeline", pipeline.name="sample-app-ci"}
   ```

### Investigate High Error Rate

1. **Query error logs**:
   ```logql
   {app="sample-app", level="error"} | json
   ```

2. **Find error traces**:
   ```traceql
   {service.name="sample-app" && status=error}
   ```

3. **Check error rate metric**:
   ```promql
   rate(http_requests_total{status=~"5.."}[5m])
   ```

4. **View CPU profile during error spike**:
   - Select time range with high errors
   - Compare with baseline profile

### Track Deployment Across Environments

1. **View deployment timeline dashboard**

2. **Query deployment events**:
   ```logql
   {namespace="argocd"} |= "sync" | json | app="sample-app"
   ```

3. **Check deployment notifications** in Slack channels:
   - #dev-deployments
   - #staging-deployments
   - #prod-deployments

### Analyze Memory Leak

1. **Check memory trend**:
   ```promql
   process_resident_memory_bytes{app="sample-app"}
   ```

2. **View memory profile**:
   - Pyroscope → `memory:alloc_objects:count`
   - Compare profiles over time

3. **Find allocation hotspots** in flame graph

4. **Correlate with traces** to identify problematic requests

## Maintenance Tasks

### Rotate Azure Blob Storage Keys

1. **Generate new storage key** in Azure Portal

2. **Update Loki secret**:
   ```bash
   kubectl edit secret loki-azure-secret -n observability
   # Update AZURE_STORAGE_KEY
   ```

3. **Update Tempo secret** (uses same secret)

4. **Restart pods**:
   ```bash
   kubectl rollout restart statefulset loki -n observability
   kubectl rollout restart statefulset tempo -n observability
   ```

### Clean Up Old Data

**Loki**:
- Automatic cleanup via retention policy (30 days)
- Manual: Delete old chunks in Azure Blob Storage

**Tempo**:
- Automatic cleanup via compactor (14 days)
- Manual: Delete old blocks in Azure Blob Storage

**Pyroscope**:
- Automatic cleanup via retention policy (7 days)
- Manual: Delete PVC data if needed

### Update Grafana Dashboards

1. **Export dashboard JSON** from Grafana UI

2. **Update dashboard file**:
   ```bash
   vim observability/grafana/dashboards/<dashboard-name>.json
   ```

3. **Import updated dashboard** via Grafana UI or API

### Scale Observability Stack

**Loki**:
```bash
kubectl scale statefulset loki -n observability --replicas=3
```

**Tempo**:
```bash
kubectl scale statefulset tempo -n observability --replicas=2
```

**Pyroscope**:
```bash
kubectl scale statefulset pyroscope -n observability --replicas=2
```

## Alert Response

### High Error Rate Alert

1. **Check alert details** in Slack notification
2. **Click "View Error Logs" link**
3. **Identify error pattern**
4. **Check recent deployments** for correlation
5. **Rollback if needed**:
   ```bash
   argocd app rollback sample-app-prod
   ```

### Slow Trace Alert

1. **Click "View Traces" link** in alert
2. **Identify slow spans**
3. **Check CPU profile** for that time range
4. **Identify performance bottleneck**
5. **Create issue** for optimization

### Memory Leak Alert

1. **Click "View Profiles" link** in alert
2. **Compare memory profiles** over time
3. **Identify allocation hotspot**
4. **Check for resource leaks** in code
5. **Deploy fix** and monitor

### Deployment Failed Alert

1. **Check ArgoCD UI** link in alert
2. **Review sync error message**
3. **Check application logs**
4. **Fix manifest issue** in config repo
5. **Trigger manual sync**:
   ```bash
   argocd app sync sample-app-prod
   ```

## Backup & Recovery

### Backup Grafana Dashboards

```bash
# Export all dashboards
for uid in $(curl -s http://grafana:3000/api/search | jq -r '.[].uid'); do
  curl -s http://grafana:3000/api/dashboards/uid/$uid | jq '.dashboard' > dashboard-$uid.json
done
```

### Restore Grafana Dashboards

```bash
# Import dashboard
curl -X POST http://grafana:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboard-<uid>.json
```

### Backup Observability Data

- **Loki/Tempo**: Data in Azure Blob Storage (automatic backup)
- **Pyroscope**: Backup PVC data
  ```bash
  kubectl exec -n observability pyroscope-0 -- tar czf /tmp/backup.tar.gz /var/lib/pyroscope
  kubectl cp observability/pyroscope-0:/tmp/backup.tar.gz ./pyroscope-backup.tar.gz
  ```

## Performance Tuning

### Optimize Loki Queries

- Use label filters before line filters
- Limit time range for large queries
- Use `| json` parser for structured logs

### Optimize Tempo Queries

- Use specific service names
- Filter by duration or status
- Limit time range

### Optimize Pyroscope

- Adjust sampling rate if overhead too high
- Use profile comparison for targeted analysis
- Enable profile aggregation for long-term trends

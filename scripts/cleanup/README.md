# Cleanup Scripts

Scripts to safely tear down GitOps infrastructure and resources.

## ⚠️ Important Warnings

- **Data Loss**: All cleanup scripts will permanently delete data
- **No Undo**: Deleted resources cannot be recovered
- **Backup First**: Export any important data before running cleanup
- **Cost Savings**: Cleanup prevents ongoing Azure charges

## Scripts Overview

| Script | What It Deletes | When to Use |
|--------|-----------------|-------------|
| `cleanup-observability.sh` | Loki, Tempo, Pyroscope, Alloy, Grafana | Remove monitoring, keep apps |
| `cleanup-kubernetes.sh` | All K8s resources (apps + observability) | Clean cluster, keep Azure |
| `cleanup-azure.sh` | Entire resource group (AKS, ACR, Storage) | Complete teardown |

## Recommended Cleanup Order

For complete teardown, run scripts in this order:

```bash
# 1. Delete applications and observability
./scripts/cleanup/cleanup-kubernetes.sh

# 2. Delete Azure resources
./scripts/cleanup/cleanup-azure.sh --resource-group rg-gitops
```

## Script Details

### 1. Observability Stack Cleanup

**Deletes:**
- Grafana Loki (logs)
- Grafana Tempo (traces)
- Pyroscope (profiles)
- Grafana Alloy (collector)
- Grafana (dashboards)
- All PVCs and data

**Keeps:**
- Applications
- ArgoCD
- AKS cluster

**Usage:**
```bash
# Interactive (with confirmation)
./scripts/cleanup/cleanup-observability.sh

# Non-interactive
./scripts/cleanup/cleanup-observability.sh --yes
```

### 2. Kubernetes Resources Cleanup

**Deletes:**
- All applications in default namespace
- Observability stack
- ArgoCD and all applications
- All PVCs

**Keeps:**
- AKS cluster
- Azure Container Registry
- Azure Storage Account

**Usage:**
```bash
# Interactive
./scripts/cleanup/cleanup-kubernetes.sh

# Non-interactive
./scripts/cleanup/cleanup-kubernetes.sh --yes
```

### 3. Azure Resources Cleanup

**Deletes:**
- Entire resource group
- AKS cluster
- Azure Container Registry
- Azure Storage Account
- All associated resources

**Usage:**
```bash
# Interactive (default resource group: rg-gitops)
./scripts/cleanup/cleanup-azure.sh

# Specify resource group
./scripts/cleanup/cleanup-azure.sh --resource-group my-rg

# Non-interactive
./scripts/cleanup/cleanup-azure.sh --yes

# Custom resource group, non-interactive
./scripts/cleanup/cleanup-azure.sh --resource-group my-rg --yes
```

**Check deletion status:**
```bash
# Check if resource group still exists
az group show --name rg-gitops

# Wait for deletion to complete
az group wait --name rg-gitops --deleted
```

## Partial Cleanup Scenarios

### Scenario 1: Remove Monitoring, Keep Apps

```bash
./scripts/cleanup/cleanup-observability.sh
```

### Scenario 2: Clean Cluster, Keep Azure Infrastructure

```bash
./scripts/cleanup/cleanup-kubernetes.sh
```

### Scenario 3: Complete Teardown

```bash
./scripts/cleanup/cleanup-kubernetes.sh --yes
./scripts/cleanup/cleanup-azure.sh --yes
```

## Backup Before Cleanup

### Export Grafana Dashboards

```bash
# Export all dashboards
kubectl port-forward -n observability svc/grafana 3000:3000 &
for uid in $(curl -s http://localhost:3000/api/search | jq -r '.[].uid'); do
  curl -s http://localhost:3000/api/dashboards/uid/$uid | jq '.dashboard' > dashboard-$uid.json
done
```

### Export Loki Logs

```bash
# Export logs for specific app
kubectl port-forward -n observability svc/loki 3100:3100 &
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={app="sample-app"}' \
  --data-urlencode 'start=1h' > logs-export.json
```

### Export ArgoCD Applications

```bash
# Export all applications
argocd app list -o yaml > argocd-apps-backup.yaml
```

## Verification After Cleanup

### Verify Kubernetes Cleanup

```bash
# Check namespaces
kubectl get namespace

# Check resources in default
kubectl get all -n default

# Check PVCs
kubectl get pvc --all-namespaces
```

### Verify Azure Cleanup

```bash
# List resource groups
az group list -o table

# List resources in group (should fail if deleted)
az resource list --resource-group rg-gitops
```

## Troubleshooting

### Namespace Stuck in "Terminating"

```bash
# Force delete namespace
kubectl get namespace observability -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/observability/finalize" -f -
```

### PVC Not Deleting

```bash
# Remove finalizers
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'
```

### Azure Resource Group Won't Delete

```bash
# Check for locks
az lock list --resource-group rg-gitops

# Delete locks
az lock delete --name <lock-name> --resource-group rg-gitops
```

## Cost Estimation

Running the full stack incurs these approximate costs (per day):

- AKS cluster (2 nodes): ~$3-5/day
- Azure Storage (Loki/Tempo): ~$0.50/day
- ACR: ~$0.17/day
- **Total**: ~$4-6/day

**Cleanup saves**: ~$120-180/month

## Support

For issues with cleanup scripts:
1. Check script output for specific errors
2. Verify Azure CLI and kubectl are working
3. Check Azure Portal for resource status
4. Review troubleshooting section above

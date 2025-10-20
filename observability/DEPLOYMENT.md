# Observability Stack Deployment Guide

## Prerequisites

- Kubernetes cluster (AKS or Arc-enabled)
- kubectl configured
- Azure Storage Account for Loki and Tempo
- Slack workspace (for notifications)
- Email SMTP credentials (for notifications)

## Step 1: Create Azure Storage

```bash
# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group rg-gitops \
  --location eastus \
  --sku Standard_LRS

# Create containers
az storage container create --name loki-chunks --account-name mystorageaccount
az storage container create --name tempo-traces --account-name mystorageaccount

# Get storage key
STORAGE_KEY=$(az storage account keys list \
  --account-name mystorageaccount \
  --query '[0].value' -o tsv)

echo "Storage Key: $STORAGE_KEY"
```

## Step 2: Deploy Observability Backend

```bash
# Create namespace
kubectl create namespace observability

# Update Azure Storage credentials
kubectl create secret generic loki-azure-secret \
  --from-literal=AZURE_STORAGE_ACCOUNT=mystorageaccount \
  --from-literal=AZURE_STORAGE_KEY=$STORAGE_KEY \
  -n observability

# Deploy Loki
kubectl apply -f observability/loki/loki-deployment.yaml

# Deploy Tempo
kubectl apply -f observability/tempo/tempo-deployment.yaml

# Deploy Pyroscope
kubectl apply -f observability/pyroscope/pyroscope-deployment.yaml

# Deploy Promtail
kubectl apply -f observability/promtail/promtail-daemonset.yaml

# Deploy Grafana
kubectl apply -f observability/grafana/grafana-datasources.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=loki -n observability --timeout=300s
kubectl wait --for=condition=ready pod -l app=tempo -n observability --timeout=300s
kubectl wait --for=condition=ready pod -l app=pyroscope -n observability --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n observability --timeout=300s
```

## Step 3: Configure ArgoCD Notifications

```bash
# Create Slack bot token secret
kubectl create secret generic argocd-notifications-secret \
  --from-literal=slack-token=<your-slack-bot-token> \
  --from-literal=email-username=<your-email> \
  --from-literal=email-password=<your-app-password> \
  -n argocd

# Deploy notifications configuration
kubectl apply -f gitops-operator/argocd/argocd-notifications.yaml

# Restart ArgoCD notifications controller
kubectl rollout restart deployment argocd-notifications-controller -n argocd
```

## Step 4: Deploy Application with Instrumentation

```bash
# Build and push instrumented application
cd app-repo
docker build -t myacr.azurecr.io/sample-app:v1.0.0 .
docker push myacr.azurecr.io/sample-app:v1.0.0

# Update Helm values with observability env vars (already configured)
# Deploy via ArgoCD or Helm
helm upgrade --install sample-app k8s/helm/sample-app \
  --set image.tag=v1.0.0 \
  --set environment=dev \
  -n default
```

## Step 5: Import Grafana Dashboards

```bash
# Get Grafana URL
GRAFANA_URL=$(kubectl get svc grafana -n observability -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Grafana URL: http://$GRAFANA_URL:3000"

# Login with admin/admin and change password

# Import dashboards via UI:
# 1. Go to Dashboards → Import
# 2. Upload JSON files from observability/grafana/dashboards/
#    - deployment-timeline.json
#    - application-performance.json
#    - pipeline-observability.json
```

## Step 6: Configure Alerting

```bash
# Deploy alerting rules
kubectl apply -f observability/grafana/alerting-rules.yaml

# Configure alert notifications in Grafana UI:
# 1. Go to Alerting → Contact points
# 2. Add Slack contact point
# 3. Add Email contact point
# 4. Create notification policies
```

## Step 7: Verify End-to-End

```bash
# Generate test traffic
kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl http://sample-app.default.svc.cluster.local

# Check logs in Grafana
# 1. Go to Explore
# 2. Select Loki datasource
# 3. Query: {app="sample-app"}

# Check traces in Grafana
# 1. Go to Explore
# 2. Select Tempo datasource
# 3. Query: {service.name="sample-app"}

# Check profiles in Grafana
# 1. Go to Explore
# 2. Select Pyroscope datasource
# 3. Select profile type and service

# Trigger deployment to test notifications
argocd app sync sample-app-dev
# Check Slack for deployment notification
```

## Troubleshooting

If components are not working, check:

```bash
# Check all pods
kubectl get pods -n observability

# Check logs
kubectl logs -n observability -l app=loki --tail=50
kubectl logs -n observability -l app=tempo --tail=50
kubectl logs -n observability -l app=pyroscope --tail=50
kubectl logs -n observability -l app=grafana --tail=50

# Test connectivity
kubectl run test --image=curlimages/curl -i --rm --restart=Never -- \
  curl http://loki.observability.svc.cluster.local:3100/ready

kubectl run test --image=curlimages/curl -i --rm --restart=Never -- \
  curl http://tempo.observability.svc.cluster.local:3200/ready

kubectl run test --image=curlimages/curl -i --rm --restart=Never -- \
  curl http://pyroscope.observability.svc.cluster.local:4040/healthz
```

## Next Steps

1. Review [OBSERVABILITY.md](../docs/OBSERVABILITY.md) for architecture details
2. Check [OBSERVABILITY-RUNBOOK.md](../docs/OBSERVABILITY-RUNBOOK.md) for common queries
3. See [OBSERVABILITY-TROUBLESHOOTING.md](../docs/OBSERVABILITY-TROUBLESHOOTING.md) for issues
4. Configure additional alert rules based on your SLOs
5. Create custom dashboards for your specific needs

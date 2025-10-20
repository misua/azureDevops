# Load Generator

Generates realistic traffic patterns to demonstrate observability features.

## Features

- **Normal Traffic** (70%): Regular user behavior - browsing products, creating orders
- **Traffic Spikes** (20%): Sudden bursts of activity
- **Error Traffic** (10%): Intentional errors to trigger alerts

## Traffic Patterns

### Normal Traffic
- Health checks
- Product browsing and search
- Order creation
- User management

### Spike Traffic
- Rapid consecutive requests
- Simulates flash sales or viral events

### Error Traffic
- Calls `/api/error` endpoint
- Creates invalid orders (insufficient stock)
- Triggers 4xx and 5xx responses

## Build and Deploy

### Build Docker Image

```bash
# Build load generator image
cd app-repo/load-generator
docker build -t <ACR_NAME>.azurecr.io/load-generator:latest .

# Push to ACR
docker push <ACR_NAME>.azurecr.io/load-generator:latest
```

### Deploy to Kubernetes

```bash
# Update deployment.yaml with your ACR name
sed -i "s/<ACR_NAME>/your-acr-name/g" deployment.yaml

# Deploy
kubectl apply -f deployment.yaml

# Check logs
kubectl logs -f deployment/load-generator
```

## Configuration

Environment variables:

- `APP_URL`: Target application URL (default: `http://sample-app.default.svc.cluster.local`)
- `DURATION_SECONDS`: How long to run (default: `3600` = 1 hour)

## Observability

The load generator creates:

- **Logs**: All requests logged with correlation IDs
- **Traces**: Distributed traces across all API calls
- **Metrics**: Request counts, error rates, latencies
- **Profiles**: CPU and memory usage patterns

### View in Grafana

1. **Logs**: Explore → Loki → `{app="sample-app"}`
2. **Traces**: Explore → Tempo → `{service.name="sample-app"}`
3. **Profiles**: Explore → Pyroscope → Select `sample-app`

### Expected Behavior

- ~70% successful requests
- ~2-5% error rate (intentional)
- ~1-2% slow requests (>2s)
- Traffic spikes every few minutes

## Stopping

```bash
# Delete deployment
kubectl delete deployment load-generator
```

## Local Testing

```bash
# Run locally (requires sample app running)
export APP_URL="http://localhost:8080"
export DURATION_SECONDS="60"
python load-generator.py
```

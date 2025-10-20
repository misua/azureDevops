# Troubleshooting Guide

## Pipeline Failures

### CI Pipeline Fails at Build Stage

**Symptoms:** Build errors, compilation failures

**Diagnosis:**
```bash
# Check pipeline logs in Azure DevOps
# Review build output for specific errors
```

**Solutions:**
- Verify dependencies in `.csproj` file
- Check .NET SDK version compatibility
- Ensure all source files are committed
- Review recent code changes for syntax errors

### CI Pipeline Fails at Test Stage

**Symptoms:** Unit tests fail, test timeout

**Diagnosis:**
```bash
# Review test output in pipeline logs
dotnet test --logger "console;verbosity=detailed"
```

**Solutions:**
- Run tests locally: `dotnet test`
- Check for environment-specific test failures
- Verify test data and mocks are correct
- Increase test timeout if needed

### Docker Build Fails

**Symptoms:** Image build errors, layer failures

**Diagnosis:**
```bash
# Check Dockerfile syntax
docker build -t test-image .
```

**Solutions:**
- Verify base image availability
- Check COPY paths are correct
- Ensure all dependencies are available
- Review Dockerfile for syntax errors

### Config Repo Push Fails

**Symptoms:** Authentication errors, push rejected

**Diagnosis:**
```bash
# Check PAT permissions
# Verify service connection in Azure DevOps
```

**Solutions:**
- Regenerate Azure DevOps PAT with correct scopes (Code: Read & Write)
- Update service connection credentials
- Check branch protection rules
- Verify repository URL is correct

## Validation Pipeline Issues

### YAML Lint Failures

**Symptoms:** Syntax errors in manifests

**Diagnosis:**
```bash
yamllint -c .yamllint environments/
```

**Solutions:**
- Fix indentation (use 2 spaces)
- Remove trailing whitespace
- Ensure proper YAML structure
- Validate with online YAML validator

### Kubernetes Schema Validation Fails

**Symptoms:** Invalid resource definitions

**Diagnosis:**
```bash
helm template sample-app ../app-repo/k8s/helm/sample-app \
  -f environments/dev/values.yaml | kubeconform -strict -summary
```

**Solutions:**
- Check API version compatibility
- Verify resource field names
- Ensure required fields are present
- Review Kubernetes version compatibility

## GitOps Operator Issues

### ArgoCD Sync Failures

**Symptoms:** Application out of sync, sync errors

**Diagnosis:**
```bash
argocd app get sample-app-dev
argocd app diff sample-app-dev
```

**Solutions:**
1. **Check repository connection**
   ```bash
   argocd repo list
   argocd repo get https://dev.azure.com/myorg/myproject/_git/config-repo
   ```

2. **Verify application health**
   ```bash
   argocd app get sample-app-dev --refresh
   ```

3. **Force sync**
   ```bash
   argocd app sync sample-app-dev --force --prune
   ```

### Drift Detected

**Symptoms:** Cluster state differs from Git

**Diagnosis:**
```bash
argocd app diff sample-app-dev
```

**Solutions:**
1. **Identify manual changes**
   ```bash
   kubectl get deployment sample-app -o yaml
   ```

2. **Reconcile to Git state**
   ```bash
   argocd app sync sample-app-dev --prune
   ```

3. **Update Git if change is intentional**
   ```bash
   # Export current state and update config repo
   kubectl get deployment sample-app -o yaml > temp.yaml
   # Review and update config repo accordingly
   ```

## Deployment Issues

### Pods Not Starting

**Symptoms:** CrashLoopBackOff, ImagePullBackOff

**Diagnosis:**
```bash
kubectl get pods -l app=sample-app
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Solutions:**
- **ImagePullBackOff:** Verify image exists in ACR, check imagePullSecrets
- **CrashLoopBackOff:** Check application logs, verify environment variables
- **Pending:** Check resource quotas, node capacity

### Service Not Accessible

**Symptoms:** Cannot reach application endpoint

**Diagnosis:**
```bash
kubectl get svc sample-app
kubectl get endpoints sample-app
kubectl port-forward svc/sample-app 8080:80
```

**Solutions:**
- Verify service selector matches pod labels
- Check service type (ClusterIP, LoadBalancer)
- Ensure pods are ready and healthy
- Review network policies

## Monitoring & Alerts

### Check Prometheus Metrics

```bash
kubectl port-forward -n argocd svc/argocd-metrics 8082:8082
curl http://localhost:8082/metrics | grep argocd_app
```

### View Alert Status

```bash
kubectl get prometheusrules -n argocd
kubectl describe prometheusrule argocd-alerts -n argocd
```

## Useful Commands Reference

```bash
# ArgoCD
argocd login <server>               # Login to ArgoCD
argocd app list                     # List applications
argocd app history <app>            # View deployment history
argocd app rollback <app> <id>      # Rollback to specific revision

# Kubernetes
kubectl get events --sort-by='.lastTimestamp'
kubectl describe <resource> <name>
kubectl logs -f <pod-name>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
```

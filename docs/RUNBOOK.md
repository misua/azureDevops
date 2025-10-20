# GitOps Operations Runbook

## Common Operations

### Deploy New Application Version

1. **Push code to app repository**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin main
   ```

2. **Monitor CI pipeline**
   - Navigate to Azure DevOps → Pipelines
   - Verify build, test, and containerization stages pass
   - Confirm image pushed to ACR with correct tag

3. **Verify config repo update**
   ```bash
   cd config-repo
   git pull
   git log -1  # Check latest commit from pipeline
   ```

4. **Monitor GitOps sync**
   ```bash
   argocd app get sample-app-dev
   argocd app sync sample-app-dev --prune
   ```

### Rollback Deployment

**Method 1: Git Revert (Recommended)**
```bash
cd config-repo
git log --oneline  # Find commit to revert
git revert <commit-hash>
git push origin main
```

**Method 2: Manual Image Tag Update**
```bash
cd config-repo/environments/dev
# Edit values.yaml to previous image tag
git add values.yaml
git commit -m "rollback: revert to previous version"
git push origin main
```

**Method 3: Operator-based (ArgoCD)**
```bash
argocd app rollback sample-app-dev
```

### Promote to Production

1. **Update staging first**
   ```bash
   cd config-repo
   git checkout staging
   # Update environments/staging/values.yaml with tested image tag
   git add environments/staging/values.yaml
   git commit -m "chore: promote to staging"
   git push origin staging
   ```

2. **Create PR for production**
   ```bash
   git checkout -b promote-to-prod
   # Update environments/prod/values.yaml
   git add environments/prod/values.yaml
   git commit -m "chore: promote to production"
   git push origin promote-to-prod
   ```

3. **Request approvals** via Azure DevOps PR interface

4. **Merge after approval** - GitOps operator will auto-deploy

### Check Sync Status

```bash
argocd app list
argocd app get sample-app-dev
```

### Force Reconciliation

```bash
argocd app sync sample-app-dev --force
```

### View Deployment Logs

```bash
# Application logs
kubectl logs -l app=sample-app -f

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

## Emergency Procedures

### Suspend Automated Sync

```bash
argocd app set sample-app-dev --sync-policy none
```

### Resume Automated Sync

```bash
argocd app set sample-app-dev --sync-policy automated
```

### Manual Deployment (Break Glass)

```bash
kubectl apply -f <manifest-file>
# Note: GitOps operator will revert this on next sync
```

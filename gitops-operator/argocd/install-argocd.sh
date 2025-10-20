#!/bin/bash
set -e

# ArgoCD installation script for AKS/Arc-enabled Kubernetes
CLUSTER_NAME="${1:-aks-cluster}"
RESOURCE_GROUP="${2:-rg-gitops}"

echo "Installing ArgoCD on cluster: $CLUSTER_NAME"

# Get AKS credentials
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME"

# Create ArgoCD namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD installed successfully"
echo "Admin password: $ARGOCD_PASSWORD"
echo "Access ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"

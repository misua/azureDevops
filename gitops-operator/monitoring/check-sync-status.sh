#!/bin/bash
# Script to check GitOps sync status

echo "=== ArgoCD Application Status ==="
argocd app list
argocd app get sample-app-dev

echo ""
echo "=== Recent Reconciliation Events ==="
kubectl get events -n argocd --sort-by='.lastTimestamp' | tail -20

echo ""
echo "=== Drift Detection ==="
argocd app diff sample-app-dev

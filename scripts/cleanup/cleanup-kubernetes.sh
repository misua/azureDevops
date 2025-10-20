#!/bin/bash
# Kubernetes Resources Cleanup Script
# WARNING: This will delete all GitOps and observability resources

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yes)
      INTERACTIVE=false
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --yes     Skip confirmation prompts"
      echo "  --help    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║       Kubernetes Resources Cleanup Script                 ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Run: kubectl config get-contexts"
    exit 1
fi

CLUSTER=$(kubectl config current-context)
echo -e "${GREEN}Current cluster:${NC} $CLUSTER"
echo ""

# List resources to be deleted
echo -e "${YELLOW}Resources to be deleted:${NC}"
echo ""
echo "Namespaces:"
kubectl get namespace observability argocd default --no-headers 2>/dev/null | awk '{print "  - " $1}' || true
echo ""
echo "Applications in default namespace:"
kubectl get deploy,svc,cm -n default -l app=sample-app --no-headers 2>/dev/null | awk '{print "  - " $1}' || true
echo ""

# Confirmation
if [ "$INTERACTIVE" = true ]; then
    echo -e "${RED}⚠️  WARNING: This will delete:${NC}"
    echo -e "${RED}  - All applications in default namespace${NC}"
    echo -e "${RED}  - Observability stack (Loki, Tempo, Pyroscope, Alloy, Grafana)${NC}"
    echo -e "${RED}  - ArgoCD and all applications${NC}"
    echo -e "${RED}  - All associated PVCs and data${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${GREEN}Starting cleanup...${NC}"

# Delete applications first
echo -e "${YELLOW}[1/4] Deleting applications...${NC}"
kubectl delete deploy,svc,cm -n default -l app=sample-app --ignore-not-found=true
echo -e "${GREEN}✓ Applications deleted${NC}"

# Delete observability stack
echo -e "${YELLOW}[2/4] Deleting observability stack...${NC}"
kubectl delete namespace observability --ignore-not-found=true
echo -e "${GREEN}✓ Observability namespace deleted${NC}"

# Delete ArgoCD
echo -e "${YELLOW}[3/4] Deleting ArgoCD...${NC}"
kubectl delete namespace argocd --ignore-not-found=true
echo -e "${GREEN}✓ ArgoCD namespace deleted${NC}"

# Clean up any remaining resources
echo -e "${YELLOW}[4/4] Cleaning up remaining resources...${NC}"
kubectl delete pvc --all -n default --ignore-not-found=true
echo -e "${GREEN}✓ PVCs deleted${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Cleanup completed successfully!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Note: Namespace deletion may take a few minutes to complete"
echo ""
echo "To verify cleanup:"
echo "  kubectl get namespace"
echo "  kubectl get all -n default"

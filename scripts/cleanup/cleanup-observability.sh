#!/bin/bash
# Observability Stack Cleanup Script
# Removes only observability components, keeps applications

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
echo -e "${YELLOW}║         Observability Stack Cleanup Script                ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# List observability resources
echo -e "${YELLOW}Observability components to be deleted:${NC}"
kubectl get all -n observability --no-headers 2>/dev/null | awk '{print "  - " $1}' || echo "  (none found)"
echo ""

# Confirmation
if [ "$INTERACTIVE" = true ]; then
    echo -e "${RED}⚠️  WARNING: This will delete:${NC}"
    echo -e "${RED}  - Grafana Loki (logs will be lost)${NC}"
    echo -e "${RED}  - Grafana Tempo (traces will be lost)${NC}"
    echo -e "${RED}  - Pyroscope (profiles will be lost)${NC}"
    echo -e "${RED}  - Grafana Alloy${NC}"
    echo -e "${RED}  - Grafana dashboards${NC}"
    echo -e "${RED}  - All PVCs and stored data${NC}"
    echo ""
    echo -e "${YELLOW}Note: Applications and ArgoCD will NOT be affected${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${GREEN}Starting observability cleanup...${NC}"

# Delete observability namespace
echo -e "${YELLOW}Deleting observability namespace...${NC}"
kubectl delete namespace observability --ignore-not-found=true

echo ""
echo -e "${GREEN}✓ Observability stack deleted${NC}"
echo ""
echo "Note: Namespace deletion may take a few minutes"
echo ""
echo "To verify:"
echo "  kubectl get namespace observability"

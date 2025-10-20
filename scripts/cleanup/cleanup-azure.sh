#!/bin/bash
# Azure Resource Cleanup Script
# WARNING: This will permanently delete Azure resources and all data

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="rg-gitops"
INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --yes)
      INTERACTIVE=false
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --resource-group NAME    Resource group to delete (default: rg-gitops)"
      echo "  --yes                    Skip confirmation prompts"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║         Azure GitOps Resource Cleanup Script              ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure${NC}"
    echo "Run: az login"
    exit 1
fi

# Show current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}Current subscription:${NC} $SUBSCRIPTION"
echo ""

# Check if resource group exists
if ! az group exists --name "$RESOURCE_GROUP" | grep -q "true"; then
    echo -e "${YELLOW}Resource group '$RESOURCE_GROUP' does not exist${NC}"
    exit 0
fi

# List resources in the group
echo -e "${YELLOW}Resources to be deleted:${NC}"
az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type}" -o table
echo ""

# Confirmation
if [ "$INTERACTIVE" = true ]; then
    echo -e "${RED}⚠️  WARNING: This will permanently delete all resources in '$RESOURCE_GROUP'${NC}"
    echo -e "${RED}⚠️  This action cannot be undone!${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${GREEN}Starting cleanup...${NC}"

# Delete resource group
echo -e "${YELLOW}Deleting resource group: $RESOURCE_GROUP${NC}"
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo ""
echo -e "${GREEN}✓ Resource group deletion initiated${NC}"
echo -e "${YELLOW}Note: Deletion is running in the background and may take several minutes${NC}"
echo ""
echo "To check deletion status:"
echo "  az group show --name $RESOURCE_GROUP"
echo ""
echo "To wait for completion:"
echo "  az group wait --name $RESOURCE_GROUP --deleted"

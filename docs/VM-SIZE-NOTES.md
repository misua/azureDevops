# VM Size Configuration Notes

## Current Configuration

**VM Size:** `Standard_DC2s_v3`  
**Specifications:**
- vCPUs: 2
- Memory: 8 GB RAM
- Type: Confidential Computing VM
- Disk: Premium SSD supported

## Why Standard_DC2s_v3?

The project originally specified `Standard_D2s_v3`, but many Azure subscriptions (especially free tier or trial subscriptions) restrict access to general-purpose D-series VMs in certain regions.

`Standard_DC2s_v3` was chosen because:
1. ✅ Available in most Azure subscriptions (including free tier)
2. ✅ Similar specifications (2 vCPUs, 8GB RAM)
3. ✅ Sufficient for GitOps demo and observability stack
4. ✅ Confidential computing features (bonus security)

## Alternative VM Sizes

If you encounter issues with `Standard_DC2s_v3`, try these alternatives:

### Check Available Sizes
```bash
# List all available VM sizes in your region
az vm list-skus --location eastus --output table | grep Standard_DC

# Check specific size availability
az vm list-skus --location eastus --size Standard_DC2s_v3 --output table
```

### Recommended Alternatives

1. **Standard_DC4s_v3** (4 vCPUs, 16GB RAM)
   - More resources, higher cost
   - Better for production workloads

2. **Standard_DC2as_v5** (2 vCPUs, 8GB RAM)
   - Newer generation
   - AMD-based processors

3. **Standard_B2s** (2 vCPUs, 4GB RAM)
   - Burstable performance
   - Lower cost
   - May struggle with full observability stack

## Cost Comparison

Approximate costs (per month, eastus region):

| VM Size | vCPUs | RAM | Monthly Cost (2 nodes) |
|---------|-------|-----|------------------------|
| Standard_DC2s_v3 | 2 | 8GB | ~$150-200 |
| Standard_DC4s_v3 | 4 | 16GB | ~$300-400 |
| Standard_DC2as_v5 | 2 | 8GB | ~$140-180 |
| Standard_B2s | 2 | 4GB | ~$60-80 |

> **Note:** Costs vary by region and Azure subscription type. Free tier includes $200 credit.

## Changing VM Size

To use a different VM size:

1. **Before cluster creation:**
   ```bash
   az aks create \
     --resource-group rg-gitops \
     --name aks-gitops-cluster \
     --node-count 2 \
     --node-vm-size <YOUR_VM_SIZE> \
     --enable-managed-identity \
     --generate-ssh-keys \
     --network-plugin azure
   ```

2. **After cluster creation:**
   ```bash
   # Add new node pool with different size
   az aks nodepool add \
     --resource-group rg-gitops \
     --cluster-name aks-gitops-cluster \
     --name newpool \
     --node-count 2 \
     --node-vm-size <NEW_VM_SIZE>
   
   # Delete old node pool
   az aks nodepool delete \
     --resource-group rg-gitops \
     --cluster-name aks-gitops-cluster \
     --name nodepool1
   ```

## Resource Requirements

For the full GitOps + Observability stack:

**Minimum (Demo/Testing):**
- 2 nodes × Standard_DC2s_v3 (2 vCPU, 8GB RAM each)
- Total: 4 vCPUs, 16GB RAM

**Recommended (Development):**
- 3 nodes × Standard_DC4s_v3 (4 vCPU, 16GB RAM each)
- Total: 12 vCPUs, 48GB RAM

**Production:**
- 5+ nodes × Standard_D4s_v3 or larger
- Separate node pools for apps vs observability
- Auto-scaling enabled

## Troubleshooting

### Error: VM size not allowed

```bash
# Check which sizes are available in your subscription
az vm list-skus --location eastus --output table | grep -i standard

# Try a different region
az account list-locations --output table
az vm list-skus --location westus2 --size Standard_DC --output table
```

### Error: Quota exceeded

```bash
# Check current quota
az vm list-usage --location eastus --output table

# Request quota increase (requires support ticket)
# Azure Portal → Help + Support → New Support Request
```

## References

- [Azure VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)
- [AKS Node Pool Management](https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

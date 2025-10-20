## Why
Upgrade from Promtail to Grafana Alloy for better performance and unified telemetry collection, add cleanup scripts for easy environment teardown, and enhance README with comprehensive step-by-step setup instructions for users unfamiliar with Azure.

## What Changes
- **Grafana Alloy Migration**: Replace Promtail with Grafana Alloy for unified logs, metrics, and traces collection
- **Cleanup Scripts**: Add scripts to tear down all Azure resources and Kubernetes deployments
- **Enhanced README**: Comprehensive beginner-friendly setup guide with complete Azure instructions
- **Updated Architecture Diagrams**: Include observability stack in main architecture documentation

## Impact
- Affected specs: `logging` (modified), `documentation` (new), `cleanup` (new)
- Affected code: Observability manifests, README.md, new cleanup scripts
- Infrastructure: Replace Promtail DaemonSet with Alloy DaemonSet
- Benefits: Better performance, unified agent, easier maintenance, clearer onboarding

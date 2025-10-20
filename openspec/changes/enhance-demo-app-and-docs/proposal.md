## Why
Replace ASCII architecture diagrams with Mermaid for better visualization, simplify README by removing Windows instructions (focus on macOS/Linux), and enhance the demo application with realistic endpoints and traffic generation to showcase observability features.

## What Changes
- **Mermaid Diagrams**: Convert all ASCII architecture diagrams to Mermaid format
- **Simplified README**: Remove Windows-specific instructions, focus on macOS/Linux
- **Enhanced Demo App**: Add multiple realistic endpoints (health, users, orders, products)
- **Traffic Generator**: Add load-generator container to create realistic traffic patterns
- **Better Observability**: Demonstrate logs, traces, and profiles with real activity

## Impact
- Affected specs: `application` (new), `documentation` (modified)
- Affected code: README.md, sample app endpoints, new traffic generator
- Infrastructure: New load-generator deployment
- Benefits: Better visualization, simpler setup, realistic observability demo

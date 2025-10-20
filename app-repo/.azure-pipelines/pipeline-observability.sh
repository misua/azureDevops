#!/bin/bash
# Pipeline observability helper script

set -e

TRACE_ID=$(uuidgen | tr -d '-')
SPAN_ID=$(openssl rand -hex 8)
PIPELINE_NAME="${BUILD_DEFINITIONNAME:-unknown}"
BUILD_ID="${BUILD_BUILDID:-unknown}"
COMMIT_SHA="${BUILD_SOURCEVERSION:-unknown}"

export TRACE_ID
export SPAN_ID

echo "##[section]Starting pipeline observability"
echo "Trace ID: $TRACE_ID"
echo "Span ID: $SPAN_ID"

# Send pipeline start trace to Tempo
send_trace_start() {
    local stage_name=$1
    local start_time=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    cat <<EOF > /tmp/trace-${stage_name}.json
{
  "resourceSpans": [{
    "resource": {
      "attributes": [
        {"key": "service.name", "value": {"stringValue": "azure-devops-pipeline"}},
        {"key": "pipeline.name", "value": {"stringValue": "$PIPELINE_NAME"}},
        {"key": "build.id", "value": {"stringValue": "$BUILD_ID"}},
        {"key": "commit.sha", "value": {"stringValue": "$COMMIT_SHA"}}
      ]
    },
    "scopeSpans": [{
      "spans": [{
        "traceId": "$TRACE_ID",
        "spanId": "$SPAN_ID",
        "name": "$stage_name",
        "kind": 1,
        "startTimeUnixNano": "$(date +%s%N)",
        "attributes": [
          {"key": "stage", "value": {"stringValue": "$stage_name"}}
        ]
      }]
    }]
  }]
}
EOF
    
    # Send to Tempo (would need to be configured with actual endpoint)
    echo "Trace data prepared for stage: $stage_name"
}

# Send logs to Loki
send_logs_to_loki() {
    local message=$1
    local level=${2:-info}
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    cat <<EOF
{
  "timestamp": "$timestamp",
  "level": "$level",
  "message": "$message",
  "trace_id": "$TRACE_ID",
  "span_id": "$SPAN_ID",
  "pipeline": "$PIPELINE_NAME",
  "build_id": "$BUILD_ID",
  "commit_sha": "$COMMIT_SHA"
}
EOF
}

# Export functions
export -f send_trace_start
export -f send_logs_to_loki

echo "Pipeline observability initialized"

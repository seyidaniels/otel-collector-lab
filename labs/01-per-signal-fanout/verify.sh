#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/verify.sh"
LAB_NUM=01
OUT="$(dirname "$0")/out"
echo "Lab 01: per-signal fan-out"

# Traces: Jaeger has every trace, complete.
jaeger_count()    { eq "$(jaeger_traces lab01 | jq length)" 20; }
jaeger_complete() { eq "$(jaeger_traces lab01 | jq '[.[] | select((.spans | length) != 2)] | length')" 0; }
# Fan-out: at least two trace exporters each sent all 40 spans (names don't matter).
fanout()          { ge "$(curl -sf localhost:8888/metrics | grep -c '^otelcol_exporter_sent_spans{.*} 40$')" 2; }
# Metrics: telemetrygen's "gen" gauge is queryable in Prometheus, labelled by service.
prom_series()     { ge "$(promq 'count(gen{job="lab01"})')" 1; }
metrics_sent()    { eq "$(selfmetric otelcol_exporter_sent_metric_points)" 20; }
# Logs: written as OTLP JSON lines to out/logs.jsonl (container path /out/logs.jsonl).
log_records()     { eq "$(cat "$OUT"/logs.jsonl 2>/dev/null | jq -s '[.[].resourceLogs[].scopeLogs[].logRecords[]] | length')" 20; }
# Signals stay in their lane: no spans or metric points written to the logs file.
logs_only()       { eq "$(cat "$OUT"/logs.jsonl 2>/dev/null | jq -s '[.[] | select(.resourceSpans or .resourceMetrics)] | length')" 0; }

eventually 15 "Jaeger has 20 lab01 traces"                         jaeger_count
check         "every trace in Jaeger has both spans"               jaeger_complete
eventually 10 "traces fanned out to ≥2 exporters (40 spans each)"  fanout
eventually 15 "Prometheus has gen{job=\"lab01\"}"                  prom_series
check         "20 metric points exported"                          metrics_sent
eventually 10 "out/logs.jsonl holds 20 log records"                log_records
check         "out/logs.jsonl holds only logs"                     logs_only
summary

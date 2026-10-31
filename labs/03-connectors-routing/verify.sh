#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/verify.sh"
LAB_NUM=03
OUT="$(dirname "$0")/out"
echo "Lab 03: connectors & routing"

globex_services() {
  cat "$OUT"/globex.jsonl 2>/dev/null | jq -s -r '.[].resourceSpans[]
    | (.resource.attributes[] | select(.key == "service.name") | .value.stringValue) as $s
    | .scopeSpans[].spans[] | $s'
}
calls() { promq "sum(traces_span_metrics_calls_total{job=\"$1\"})"; }

acme_in_jaeger()   { eq "$(jaeger_traces acme-shop | jq length)" 30; }
only_acme()        { ! jaeger_services | grep -qE '^(globex|legacy)-shop$'; }
globex_in_file()   { eq "$(globex_services | grep -c '^globex-shop$')" 40; }
only_globex()      { eq "$(globex_services | grep -vc '^globex-shop$')" 0; }
unrouted_debug()   { eq "$(selfmetric otelcol_exporter_sent_spans 'exporter="debug')" 20; }
red_acme()         { eq "$(calls acme-shop)" 60; }
red_globex()       { eq "$(calls globex-shop)" 40; }
red_legacy()       { eq "$(calls legacy-shop)" 20; }
red_latency()      { ge "$(promq 'count(traces_span_metrics_duration_milliseconds_bucket)')" 1; }
red_tenant_label() { eq "$(promq 'sum(traces_span_metrics_calls_total{tenant="acme"})')" 60; }

eventually 15 "acme traces (30) are in Jaeger"                       acme_in_jaeger
check         "Jaeger holds no globex or untenanted traces"          only_acme
eventually 10 "globex spans (40) are in out/globex.jsonl"            globex_in_file
check         "out/globex.jsonl holds only globex-shop"              only_globex
eventually 10 "untenanted spans (20) went to a debug exporter"       unrouted_debug
eventually 30 "spanmetrics: 60 calls for acme-shop in Prometheus"    red_acme
eventually 10 "spanmetrics: 40 calls for globex-shop"                red_globex
eventually 10 "spanmetrics: 20 calls for legacy-shop (unrouted too)" red_legacy
check         "spanmetrics duration histogram exported"              red_latency
check         "tenant resource attribute survives as a label"        red_tenant_label
summary

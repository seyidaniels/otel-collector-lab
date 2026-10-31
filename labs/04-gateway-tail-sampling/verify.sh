#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/verify.sh"
LAB_NUM=04
echo "Lab 04: agent → gateway + tail sampling"

# gateway.id values seen per trace (from the resource processor on each gateway).
gateways_per_trace() {
  jaeger_traces "$1" | jq -c '[.[] | [.processes[].tags[] | select(.key == "gateway.id") | .value] | unique]'
}

errors_kept()   { eq "$(jaeger_traces payments | jq length)" 50; }
slow_kept()     { eq "$(jaeger_traces search | jq length)" 50; }
baseline()      { between "$(jaeger_traces catalog | jq length)" 20 100; }
complete()      { eq "$(for s in payments search catalog; do jaeger_traces $s; done | jq -s '[.[][] | select((.spans | length) != 2)] | length')" 0; }
stamped()       { eq "$(for s in payments search catalog; do gateways_per_trace $s; done | jq -s '[.[][] | select(length == 0)] | length')" 0; }
affinity()      { eq "$(for s in payments search catalog; do gateways_per_trace $s; done | jq -s '[.[][] | select(length > 1)] | length')" 0; }
spread()        { ge "$(gateways_per_trace catalog | jq 'flatten | unique | length')" 2; }
agent_no_drop() { eq "$(selfmetric otelcol_exporter_sent_spans)" 1200; }
gateways_up()   { eq "$(promq 'count(otelcol_receiver_accepted_spans{role="gateway"} > 0)')" 3; }

eventually 60 "all 50 error traces kept (payments)"                     errors_kept
eventually 30 "all 50 slow traces kept (search)"                        slow_kept
eventually 30 "~10% of 500 healthy traces kept (catalog: 20–100)"       baseline
check         "every kept trace has both spans"                         complete
check         "every span carries gateway.id (resource processor)"      stamped
check         "trace affinity: each trace handled by exactly 1 gateway" affinity
check         "load spread: catalog traces hit ≥2 gateways"             spread
check         "agent forwarded all 1200 spans (sampling is the gateway's job)" agent_no_drop
eventually 20 "Prometheus scrapes 3 gateways that each received spans"  gateways_up
summary

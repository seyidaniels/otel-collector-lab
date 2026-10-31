#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/verify.sh"
LAB_NUM=05
OUT="$(dirname "$0")/out"
echo "Lab 05: resilience & self-monitoring"

no_loss()      { eq "$(jaeger_traces orders | jq length)" 200; }
complete()     { eq "$(jaeger_traces orders | jq '[.[] | select((.spans | length) != 2)] | length')" 0; }
drained()      { eq "$(selfmetric otelcol_exporter_queue_size)" 0; }
persisted()    { [[ -n "$(ls -A "$OUT"/queue 2>/dev/null)" ]]; }
backpressure() { ge "$(cat "$OUT"/queue-during-outage.txt 2>/dev/null)" 1; }

eventually 30 "all 200 orders traces reached Jaeger despite outage + restart" no_loss
check         "every trace has both spans"                                    complete
eventually 30 "exporter queue drained to 0"                                   drained
check         "queue was persisted to disk (out/queue is not empty)"          persisted
check         "exporter queued data during the outage (instead of dropping)"  backpressure
summary

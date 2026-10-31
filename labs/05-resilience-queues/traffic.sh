#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/traffic.sh"

queue() { curl -sf localhost:8888/metrics | awk '/^otelcol_exporter_queue_size/ {s += $NF} END {print s + 0}'; }
# Always end with Jaeger running, even if this script is interrupted.
trap 'docker unpause jaeger >/dev/null 2>&1 || true' EXIT

say "phase 1: 50 orders traces while Jaeger is healthy"
tg traces --service orders --traces 50 --rate 100

say "phase 2: OUTAGE — pausing Jaeger, sending 150 more traces"
docker pause jaeger >/dev/null
tg traces --service orders --traces 150 --rate 100
sleep 3
echo "exporter queue size during outage: $(queue)"
queue > "$(dirname "$0")/out/queue-during-outage.txt"

say "phase 3: collector restarts mid-outage (deploy, OOM kill, node drain...)"
docker restart lab-05-otelcol-1 >/dev/null
for _ in $(seq 1 30); do curl -sf localhost:8888/metrics >/dev/null && break; sleep 1; done
echo "exporter queue size after restart: $(queue)"

say "phase 4: Jaeger recovers"
docker unpause jaeger >/dev/null
for _ in $(seq 1 30); do [[ $(queue) == 0 ]] && break; sleep 1; done
echo "exporter queue size after recovery: $(queue)"

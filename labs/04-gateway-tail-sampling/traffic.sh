#!/usr/bin/env bash
OTLP_TARGET=agent:4317
source "$(dirname "$0")/../../lib/traffic.sh"

# The agent's DNS resolver finds gateways on its own schedule. Traffic sent
# before it has any backends is dropped ("couldn't find the exporter for the
# endpoint"), so wait until the loadbalancing exporter reports them.
say "waiting for the agent to discover gateways"
for _ in $(seq 1 30); do
  n=$(curl -sf localhost:8888/metrics | awk '/^otelcol_loadbalancer_num_backends/ {print $NF}')
  [[ ${n:-0} -ge 1 ]] && break
  sleep 1
done
echo "agent sees ${n:-0} gateway(s)"

# --batch=false: one export request per span, like a real app flushing spans
# as they end. That way a trace's spans reach the agent in separate requests.
TG_OPTS=(--batch=false --workers 5)

say "payments: 50 traces with status=Error (keep all)"
tg traces --service payments --traces 10 --rate 50 "${TG_OPTS[@]}" --status-code Error &
say "search: 50 traces taking 800ms (keep all)"
tg traces --service search   --traces 10 --rate 50 "${TG_OPTS[@]}" --span-duration 800ms &
say "catalog: 500 fast, healthy traces (keep ~10%)"
tg traces --service catalog  --traces 100 --rate 100 "${TG_OPTS[@]}" &
wait
echo "sent. tail sampling decides ~decision_wait after each trace's first span arrives."

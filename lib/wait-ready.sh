#!/usr/bin/env bash
# Wait for a lab's collector to serve self-metrics on :8888. On failure show
# the logs, which is where config errors (bad YAML, unknown component) appear.
set -uo pipefail
lab_dir=$1
dc() { docker compose --env-file .env --project-directory "$lab_dir" -f "$lab_dir/compose.yml" "$@"; }
for _ in $(seq 1 30); do
  if curl -sf localhost:8888/metrics >/dev/null; then
    echo "collector ready: http://localhost:8888/metrics"
    exit 0
  fi
  # A bad config makes the collector exit immediately; no point waiting.
  if dc ps -a --format '{{.State}}' | grep -q exited; then break; fi
  sleep 1
done
echo "collector is not running. Last logs:" >&2
dc logs --tail=40 >&2
exit 1

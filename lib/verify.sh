# Sourced by labs/*/verify.sh. Small assertion helpers over the three places
# telemetry ends up: collector self-metrics, Jaeger and Prometheus.
set -uo pipefail
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0
PASSES=0

# selfmetric <name> [label-regex] [url]: sum of a collector self-metric.
selfmetric() {
  local name=$1 labels=${2:-} url=${3:-http://localhost:8888/metrics}
  curl -sf "$url" | awk -v n="$name" -v l="$labels" '
    $1 ~ "^"n"({|$)" && (l == "" || $1 ~ l) { s += $NF } END { printf "%d\n", s }'
}

# jaeger_traces <service>: JSON array of traces for a service.
jaeger_traces() {
  curl -sf "http://localhost:16686/api/traces?service=$1&limit=10000&lookback=1h" | jq '.data // []'
}

# jaeger_services: one service name per line.
jaeger_services() {
  curl -sf http://localhost:16686/api/services | jq -r '.data // [] | .[]'
}

# promq <promql>: first sample value of an instant query, or empty.
promq() {
  curl -sf --get http://localhost:9090/api/v1/query --data-urlencode "query=$1" \
    | jq -r '.data.result[0].value[1] // empty'
}

# check <description> <command...>: record pass/fail of a command's exit code.
check() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then
    printf '  \033[32m✔\033[0m %s\n' "$desc"; PASSES=$((PASSES + 1))
  else
    printf '  \033[31m✘\033[0m %s\n' "$desc"; FAILS=$((FAILS + 1))
  fi
}

# eventually <seconds> <description> <command...>: like check, but retries
# for pipelines that flush on a timer (batch, spanmetrics, tail sampling).
# Pass a function name, not "$(...)": arguments are evaluated only once.
eventually() {
  local timeout=$1 desc=$2; shift 2
  local deadline=$((SECONDS + timeout))
  until "$@" >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then check "$desc" false; return; fi
    sleep 2
  done
  check "$desc" true
}

# eq / ge / between: numeric comparisons usable as check commands. The values
# are echoed so a failure can be debugged by rerunning with VERBOSE=1.
eq()      { [[ ${VERBOSE:-0} == 1 ]] && echo "eq $1 $2" >&2; [[ $1 =~ ^[0-9]+$ && $1 -eq $2 ]]; }
ge()      { [[ ${VERBOSE:-0} == 1 ]] && echo "ge $1 $2" >&2; [[ $1 =~ ^[0-9]+$ && $1 -ge $2 ]]; }
between() { [[ ${VERBOSE:-0} == 1 ]] && echo "between $1 $2 $3" >&2; [[ $1 =~ ^[0-9]+$ && $1 -ge $2 && $1 -le $3 ]]; }

summary() {
  echo
  if (( FAILS == 0 )); then
    printf '\033[32mPASS\033[0m  %d/%d checks\n' "$PASSES" "$PASSES"
  else
    printf '\033[31mFAIL\033[0m  %d of %d checks failed\n' "$FAILS" $((PASSES + FAILS))
    echo "Tips: make logs LAB=$LAB_NUM · http://localhost:8888/metrics · Jaeger :16686 · Prometheus :9090"
  fi
  (( FAILS == 0 ))
}

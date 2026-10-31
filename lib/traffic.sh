# Sourced by labs/*/traffic.sh. Wraps telemetrygen so every lab sends traffic
# the same way: from a container on the otel-lab network, over OTLP gRPC.
set -euo pipefail
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$LAB_ROOT/.env"

# Where telemetrygen sends. Labs with an agent tier override this.
OTLP_TARGET=${OTLP_TARGET:-otelcol:4317}

# tg <traces|metrics|logs> [telemetrygen flags...]
tg() {
  local signal=$1; shift
  docker run --rm --network otel-lab "$TELEMETRYGEN_IMAGE" "$signal" \
    --otlp-endpoint "$OTLP_TARGET" --otlp-insecure "$@" 2>&1 \
    | grep -E $'\t(ERROR|FATAL)\t' || true
}

say() { printf '\n\033[1m▶ %s\033[0m\n' "$*"; }

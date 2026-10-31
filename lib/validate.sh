#!/usr/bin/env bash
# Run `otelcol-contrib validate` on every collector config in a lab directory.
# Configs still marked "# STUB" are reported as not attempted; set
# SKIP_STUBS=1 (as CI does) to treat those as passing.
set -uo pipefail
cd "$(dirname "$0")/.."
source .env
lab_dir=$1
rc=0
for cfg in "$lab_dir"/collector.yaml "$lab_dir"/agent.yaml "$lab_dir"/gateway.yaml; do
  [[ -f $cfg ]] || continue
  if grep -q '^# STUB' "$cfg"; then
    echo "-  $cfg: stub, not attempted yet"
    [[ ${SKIP_STUBS:-0} == 1 ]] || rc=1
    continue
  fi
  if out=$(docker run --rm -e HOSTNAME=validate -v "$PWD/$cfg:/cfg.yaml:ro" "$OTELCOL_IMAGE" validate --config=/cfg.yaml 2>&1); then
    echo "✔  $cfg"
  else
    echo "✘  $cfg"; echo "$out" | sed 's/^/     /'; rc=1
  fi
done
exit $rc

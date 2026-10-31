#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/traffic.sh"

say "20 health-check traces from checkout (url.path=/healthz) — should be dropped"
tg traces --service checkout --traces 20 --rate 50 \
  --telemetry-attributes 'url.path="/healthz"'

say "30 payment traces from checkout carrying PII and an old semconv attribute"
tg traces --service checkout --traces 30 --rate 50 \
  --telemetry-attributes 'url.path="/api/pay"' \
  --telemetry-attributes 'user.email="alice@example.com"' \
  --telemetry-attributes 'http.status_code=200'

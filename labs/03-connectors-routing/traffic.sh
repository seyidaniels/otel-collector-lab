#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/traffic.sh"

say "tenant acme: 30 traces from acme-shop"
tg traces --service acme-shop   --traces 30 --rate 50 --otlp-attributes 'tenant="acme"'
say "tenant globex: 20 traces from globex-shop"
tg traces --service globex-shop --traces 20 --rate 50 --otlp-attributes 'tenant="globex"'
say "no tenant: 10 traces from legacy-shop"
tg traces --service legacy-shop --traces 10 --rate 50

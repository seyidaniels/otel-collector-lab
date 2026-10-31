#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/traffic.sh"

say "10 traces (2 spans each), 10 metric points, 10 log records from service lab00"
tg traces  --service lab00 --traces 10  --rate 50
tg metrics --service lab00 --metrics 10 --rate 50
tg logs    --service lab00 --logs 10    --rate 50

#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/traffic.sh"

say "20 traces, 20 metric points, 20 log records from service lab01"
tg traces  --service lab01 --traces 20  --rate 50
tg metrics --service lab01 --metrics 20 --rate 50
tg logs    --service lab01 --logs 20    --rate 50

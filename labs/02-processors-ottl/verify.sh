#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/verify.sh"
LAB_NUM=02
echo "Lab 02: processors & OTTL"

spans() { jaeger_traces checkout | jq '[.[].spans[]]'; }
count_spans() { spans | jq "[.[] | select($1)] | length"; }
tag() { echo "(.tags[] | select(.key == \"$1\") | .value)"; }

payment_traces() { eq "$(jaeger_traces checkout | jq length)" 30; }
no_healthz()     { eq "$(count_spans "$(tag url.path) == \"/healthz\"")" 0; }
email_hashed()   { eq "$(count_spans "($(tag user.email) | test(\"^[0-9a-f]{64}\$\")) | not")" 0; }
no_raw_email()   { eq "$(spans | jq '[.[].tags[] | select(.value | tostring | contains("@"))] | length')" 0; }
old_attr_gone()  { eq "$(count_spans "any(.tags[]; .key == \"http.status_code\")")" 0; }
new_attr_set()   { eq "$(count_spans "$(tag http.response.status_code) == 200")" 60; }
env_stamped()    { eq "$(jaeger_traces checkout | jq '[.[].processes[] | select(any(.tags[]; .key == "deployment.environment.name" and .value == "lab") | not)] | length')" 0; }
# Self-metrics show processor order: whatever transforms should only see the 60 surviving spans.
drop_early()     { eq "$(selfmetric otelcol_processor_incoming_items 'processor="transform')" 60; }
limiter_first()  { eq "$(selfmetric otelcol_processor_incoming_items 'processor="memory_limiter')" 100; }

eventually 15 "Jaeger has the 30 payment traces (and nothing else)"      payment_traces
check         "no /healthz spans reached Jaeger"                         no_healthz
check         "user.email is a SHA-256 hex digest on every span"         email_hashed
check         "no raw email address anywhere in span attributes"         no_raw_email
check         "deprecated http.status_code removed"                      old_attr_gone
check         "http.response.status_code=200 on all 60 spans"            new_attr_set
check         "resource has deployment.environment.name=lab"             env_stamped
check         "filter runs before transform (transform saw 60 spans)"    drop_early
check         "memory_limiter sees all 100 spans (it's first)"           limiter_first
summary

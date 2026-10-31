# Lab 03: Connectors & routing

**Goal:** use **connectors**, components that are an exporter for one pipeline and a receiver for another. You'll route tenants to different destinations and generate RED metrics (rate, errors, duration) from spans, so apps don't have to emit them.

```
                                   ┌─ tenant=acme   ─▶ traces/acme   ─▶ [Jaeger]
[otlp] ─▶ traces/in ─▶ (routing) ──┼─ tenant=globex ─▶ traces/globex ─▶ [file /out/globex.jsonl]
                   │               └─ default       ─▶ traces/other  ─▶ [debug]
                   └─▶ (spanmetrics) ─▶ metrics/red ─▶ [Prometheus]
```

## What `traffic.sh` sends
| service | resource attr `tenant` | traces |
|---|---|---|
| `acme-shop` | `acme` | 30 |
| `globex-shop` | `globex` | 20 |
| `legacy-shop` | *(none)* | 10 |

## Requirements (checked by `verify.sh`)
1. Route on the **resource** attribute `tenant`:
   - `acme` → Jaeger. Only acme traces may appear there.
   - `globex` → file exporter at `/out/globex.jsonl` (all 40 spans, nothing else).
   - anything else → an exporter whose ID starts with `debug` (20 spans).
2. Generate span metrics for **all** traffic, including unrouted traffic, and push them to Prometheus (OTLP endpoint from lab 01). The grader expects `sum(traces_span_metrics_calls_total{job="<service>"})` of 60 / 40 / 20, plus a duration histogram.
3. The `tenant` label must appear on those metrics. Prometheus is configured to promote it from resource attributes; you just mustn't lose it.

## Run
```bash
make run LAB=03
cat labs/03-connectors-routing/out/globex.jsonl | jq .
```

## Hints
- [routing connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/routingconnector) · [spanmetrics connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/spanmetricsconnector) · [count connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/countconnector) (bonus)
- A connector is listed under `connectors:`, used in `exporters: [...]` of one pipeline and in `receivers: [...]` of another.
- Look at the routing connector's `table`, `context` and `default_pipelines`.
- spanmetrics flushes on `metrics_flush_interval` (default 60s). Lower it, or the grader will time out.

## Break it
- Put `spanmetrics` *after* routing, only on the acme pipeline. Which check fails? Where should RED metrics be computed in a two-tier setup, and why does sampling matter? (See lab 04.)
- Add a high-cardinality span attribute (e.g. `user.id`) to spanmetrics `dimensions`. What happens to the Prometheus series count? This is how teams blow up their metrics bill.
- Remove `default_pipelines`. Where does legacy-shop's data go now?

## Interview questions this answers
- What is a connector, and how is it different from a processor?
- How would you do multi-tenant routing, or send one team's data to a different backend?
- How do you get RED metrics for services that only emit traces? Why compute them **before** tail sampling?

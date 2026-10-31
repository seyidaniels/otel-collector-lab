# Lab 01: Per-signal fan-out

**Goal:** send each signal to the backend built for it, and fan traces out to two exporters at once. This is the "one OTLP endpoint for apps, many backends behind it" pattern.

```
                         ┌─▶ [otlp → Jaeger]
traces  ─▶ [otlp] ─▶ …  ─┤
                         └─▶ [debug]
metrics ─▶ [otlp] ─▶ …  ───▶ [otlphttp → Prometheus OTLP endpoint]
logs    ─▶ [otlp] ─▶ …  ───▶ [file → /out/logs.jsonl]
```

## What `traffic.sh` sends
20 traces (2 spans each), 20 metric points (telemetrygen's `gen` gauge) and 20 log records, all from `service.name=lab01`.

## Requirements (checked by `verify.sh`)
1. Traces go to **Jaeger** (`jaeger:4317`, OTLP gRPC, no TLS) **and** to a second exporter (`debug` is fine). Each exporter must send all 40 spans.
2. Metrics go to **Prometheus** over OTLP/HTTP: `http://prometheus:9090/api/v1/otlp/v1/metrics`. The grader queries `gen{job="lab01"}`.
3. Logs go to a **file exporter** at `/out/logs.jsonl`. That path is mounted to `labs/01-per-signal-fanout/out/` so you can `cat` it. The file must contain only logs.
4. `memory_limiter` and `batch` in every pipeline, as in lab 00.

## Run
```bash
make run LAB=01
open http://localhost:16686   # Jaeger, service "lab01"
open http://localhost:9090    # Prometheus, query: gen{job="lab01"}
```

## Hints
- [otlp exporter](https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/otlpexporter) · [otlphttp exporter](https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/otlphttpexporter) · [file exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/fileexporter)
- Two exporters of the same type need distinct IDs: `type/name`, e.g. `otlp/jaeger`.
- `otlphttp` has `endpoint` (it appends `/v1/metrics` itself) and per-signal overrides like `metrics_endpoint`.
- Prometheus turns `service.name` into the `job` label.

## Break it
- Point the Jaeger exporter at `jaeger:4318`, the HTTP port. What appears in `make logs`, and which self-metric goes up?
- Put the same exporter in two pipelines of different signal types. That's allowed. Why?
- Stop Prometheus (`docker stop prometheus`) during traffic. Do traces still reach Jaeger? Fan-out is per exporter: each exporter has its own queue, so one slow backend doesn't block the others.

## Interview questions this answers
- Why put a Collector between apps and backends instead of having apps export directly?
- How does fan-out work, and what happens to the other exporters when one backend is down?
- OTLP gRPC vs OTLP HTTP: when would you choose each?

# Lab 00: Hello pipeline

**Goal:** the smallest useful collector. You'll learn the config shape (receivers → processors → exporters, wired in `service.pipelines`) and how to tell from the collector's own metrics that data went through.

```
telemetrygen ──OTLP gRPC──▶ [otlp] ─▶ memory_limiter ─▶ batch ─▶ [debug]   (× traces, metrics, logs)
```

## What `traffic.sh` sends
10 traces (2 spans each), 10 metric points and 10 log records, all from `service.name=lab00`, sent to `otelcol:4317`.

## Requirements (checked by `verify.sh`)
1. An `otlp` receiver listening on gRPC `0.0.0.0:4317` (and HTTP `0.0.0.0:4318`).
2. Three pipelines (traces, metrics, logs), each ending in a `debug` exporter.
3. Each pipeline runs `memory_limiter` first and `batch` last.
4. Keep the `service.telemetry` block exactly as given, because the grader reads `:8888/metrics`.

## Run
```bash
# remove the "# STUB" line from collector.yaml first
make validate LAB=00     # parse + type-check the config without starting it
make run LAB=00          # up + traffic + verify
make logs LAB=00         # debug exporter output appears here
```

## Hints
- [otlp receiver](https://github.com/open-telemetry/opentelemetry-collector/tree/main/receiver/otlpreceiver) · [memory_limiter](https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor) · [batch](https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/batchprocessor) · [debug exporter](https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/debugexporter)
- Paste your config into [OTelBin](https://www.otelbin.io/) to see the pipeline graph.
- Components are not added to pipelines automatically. Define each receiver, processor and exporter, then list it in `service.pipelines`; component defaults only apply after the component is configured.
- A component that is defined but not used in any pipeline is ignored without warning. A component used in a pipeline but never defined is a startup error.

## Break it
- Bind the receiver to `localhost:4317` instead of `0.0.0.0:4317`. Why does telemetrygen, which runs in another container, now fail?
- Set `debug.verbosity: detailed` and look at the logs. What is a Resource vs a Scope vs a Span?
- Remove `batch` and compare `otelcol_exporter_sent_spans` against the number of export requests.

## Interview questions this answers
- What are the building blocks of a Collector config, and how does `service.pipelines` tie them together?
- Why does `memory_limiter` go first and `batch` last?
- How do you know a collector is actually receiving and exporting? (`otelcol_receiver_accepted_*`, `otelcol_exporter_sent_*`, `send_failed_*`)

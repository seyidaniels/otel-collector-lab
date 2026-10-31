# Research: existing Collector learning material

What exists already (searched October 2026), and how this repo uses it.

## Traffic generation
- **telemetrygen** ([contrib `cmd/telemetrygen`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/telemetrygen), image `ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen`): the standard OTLP load generator for traces, metrics and logs. Flags for rate, workers, duration, status code, span duration, and resource/span attributes. Every lab's `traffic.sh` uses it.
  - Guides: [pipeline validation with telemetrygen](https://oneuptime.com/blog/post/2026-02-06-telemetrygen-test-traces-pipeline-validation/view) · [benchmarking a collector](https://oneuptime.com/blog/post/2026-02-06-benchmark-collector-telemetrygen/view)

## Deployment patterns & tutorials
- [jpkrohling/opentelemetry-collector-deployment-patterns](https://github.com/jpkrohling/opentelemetry-collector-deployment-patterns): 8 patterns (basic, normalizer, Kubernetes, load-balancing, multi-cluster, multitenant, per-signal, Kafka). The configs target v0.33, so labs 01/03/04/06 rebuild these patterns on a current version.
- pavolloffay's KubeCon tutorials, the best Kubernetes/Operator exercises (linked from lab 08):
  [EU 2023 Kubernetes](https://github.com/pavolloffay/kubecon-eu-2023-opentelemetry-kubernetes-tutorial) ·
  [NA 2023 metrics](https://github.com/pavolloffay/kubecon-na-2023-opentelemetry-kubernetes-metrics-tutorial) ·
  [EU 2024 tracing + OTTL](https://github.com/pavolloffay/kubecon-eu-2024-opentelemetry-kubernetes-tracing-tutorial)
- [OpenTelemetry Astronomy Shop demo](https://github.com/open-telemetry/opentelemetry-demo): a full microservice app with a realistic collector config to read.

## Official docs used by the labs
- [Gateway deployment](https://opentelemetry.io/docs/collector/deployment/gateway/): two-tier loadbalancing → tail_sampling (lab 04)
- [Extend the Collector / OCB](https://opentelemetry.io/docs/collector/extend/) (lab 07)
- Component READMEs in [opentelemetry-collector](https://github.com/open-telemetry/opentelemetry-collector) and [opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) are the real reference for every config key.

## Tools
- [OTelBin](https://www.otelbin.io/) ([source](https://github.com/dash0hq/otelbin)): visual editor and validator for collector configs.
- [OTTL Playground](https://ottl.run) (Elastic): run OTTL statements against sample telemetry.

## Self-monitoring
- Collector self-metrics on `:8888`: `otelcol_exporter_queue_size / otelcol_exporter_queue_capacity` for queue utilisation, plus `send_failed_*`, `enqueue_failed_*` and `receiver_refused_*`. Guides: [queue depth & backpressure](https://oneuptime.com/blog/post/2026-02-06-monitor-collector-queue-depth-backpressure/view) · [pipeline health dashboard](https://oneuptime.com/blog/post/2026-02-06-otel-collector-pipeline-health-dashboard-grafana/markdown)

## Gotchas found while building these labs (collector 0.163.2)
- Self-metrics bind to localhost by default. Set `service.telemetry.metrics.readers[].pull.exporter.prometheus.host: 0.0.0.0` to scrape them from another container.
- The loadbalancing exporter drops data sent before its DNS resolver has found any backends (`couldn't find the exporter for the endpoint ""`). Watch `otelcol_loadbalancer_num_backends`.
- telemetrygen batches a trace's spans into one request by default, so a round-robin "load balancer" looks correct. Use `--batch=false` to reproduce real split traces.
- `${env:VAR}` inside a YAML flow map (`{ ... }`) breaks parsing. Use block style.
- The filter processor's drop counter is exported to Prometheus with a dot: `{"otelcol_processor_filter_spans.filtered"}`.
- Jaeger v2 traces its own query API, so a `jaeger` service appears in its service list.

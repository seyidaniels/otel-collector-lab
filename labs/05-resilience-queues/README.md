# Lab 05: Resilience & self-monitoring

**Goal:** lose no data when the backend goes down **and** the collector restarts during the outage. You'll configure exporter queues, retries and a disk-backed queue, then watch backpressure on the collector-health dashboard.

```
[otlp] ─▶ memory_limiter ─▶ batch ─▶ [otlp → Jaeger]
                                        │ sending_queue  ── storage: file_storage ─▶ /var/lib/otelcol/queue
                                        └ retry_on_failure
```

## What `traffic.sh` does
1. Sends 50 `orders` traces while Jaeger is healthy.
2. **Pauses Jaeger** (`docker pause jaeger`) and sends 150 more.
3. **Restarts the collector** while Jaeger is still down, as a deploy, OOM kill or node drain would.
4. Unpauses Jaeger and waits for the queue to drain.

## Requirements (checked by `verify.sh`)
1. All **200** traces reach Jaeger, each with both spans.
2. The exporter queue holds data during the outage, then drains to 0.
3. The queue lives on disk at `/var/lib/otelcol/queue`, which is mounted to `labs/05-resilience-queues/out/queue/`. The grader checks that it isn't empty.

## Run
```bash
make run LAB=05
open http://localhost:3000   # Grafana → OTel Lab → Collector health (queue + failed-send panels)
```

## Hints
- [exporterhelper (queue + retry settings)](https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/exporterhelper) · [file_storage extension](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/storage/filestorage)
- Extensions must be defined under `extensions:` **and** enabled in `service.extensions`.
- `retry_on_failure.max_elapsed_time` decides when retrying gives up and the data is dropped. How long can your outages last?
- A short exporter `timeout` makes a paused, unresponsive backend fail fast instead of hanging.

## Break it
- Remove `storage:` so the queue is in memory. The restart now loses data. Count how many traces made it.
- Set `queue_size: 2` with the in-memory queue. Watch `otelcol_exporter_enqueue_failed_spans` and `otelcol_receiver_refused_spans`. Where does backpressure go: back to the client, or dropped?
- Set `max_elapsed_time: 5s` and pause Jaeger for 30s.
- Lower `memory_limiter` to `limit_mib: 30` and blast traffic (`--rate 0 --workers 20`). What does the client see?

## Interview questions this answers
- A collector is dropping spans under load. What do you check? (refused vs enqueue_failed vs send_failed, queue size vs capacity, memory_limiter, backend latency)
- In-memory vs persistent queue: trade-offs (disk I/O, ordering, at-least-once delivery, duplicates on replay).
- What would you alert on for a collector fleet? (queue utilisation > 80%, send_failed rate > 0, refused rate > 0)
- Where would you add Kafka, and what does it buy you over a persistent queue? (See lab 06.)

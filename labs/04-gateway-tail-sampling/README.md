# Lab 04: Agent → gateway + tail sampling

**Goal:** build the standard two-tier deployment. Tail sampling decides whether to keep a trace only after seeing **all** of its spans, so every span of a trace has to reach the **same** gateway. That's the job of the `loadbalancing` exporter.

```
                                      ┌──▶ gateway-1 ┐
telemetrygen ─▶ agent ─(loadbalancing ┼──▶ gateway-2 ┼─ tail_sampling ─▶ [Jaeger]
               (no sampling) traceID) └──▶ gateway-3 ┘
```
You write **two** configs: `agent.yaml` (tier 1, 1 instance) and `gateway.yaml` (tier 2, 3 replicas behind the DNS name `gateway`).

## What `traffic.sh` sends (to `agent:4317`)
Spans are sent unbatched (one export request per span), the way a real app flushes spans as they end.
| service | traces | shape | expected outcome |
|---|---|---|---|
| `payments` | 50 | status `Error` | keep **all** |
| `search` | 50 | 800 ms spans | keep **all** |
| `catalog` | 500 | fast, OK | keep **~10%** |

## Requirements (checked by `verify.sh`)
**agent.yaml**
1. OTLP receiver; export with `loadbalancing`, routed by **trace ID**, resolving gateways through **DNS** at `gateway:4317`.
2. No sampling here. The grader checks that the agent forwarded all 1200 spans.

**gateway.yaml**
3. A `resource` processor that upserts `gateway.id` = `${env:HOSTNAME}`. The grader uses it to see which gateway handled each span.
4. `tail_sampling` with three policies: errors, latency > 500 ms, and probabilistic 10%. Keep `decision_wait` short (about 5s) so the grader doesn't wait forever.
5. Export to Jaeger.

**Both:** keep the `service.telemetry` block. Prometheus scrapes all three gateways, and the grader checks that each one received spans.

## Run
```bash
make run LAB=04
make logs LAB=04
open http://localhost:3000   # Grafana → OTel Lab → Collector health
```

## Hints
- [loadbalancing exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/loadbalancingexporter) · [tail_sampling processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor) · [gateway deployment docs](https://opentelemetry.io/docs/collector/deployment/gateway/)
- In YAML, a `${env:...}` value must be in block style, not inside `{ ... }`.
- The agent's `otelcol_loadbalancer_num_backends` tells you how many gateways it has found. `traffic.sh` waits for it to be ≥1.
- Policies are OR'ed: a trace is kept if **any** policy says sample.

## Break it (do at least the first one)
- **Replace `loadbalancing` with a plain `otlp` exporter** to `dns:///gateway:4317` with `balancer_name: round_robin`. The trace-affinity check fails: spans of one trace now land on different gateways, each of which samples its half of the trace without seeing the rest. This is the most common tail-sampling bug in production.
- Set `routing_key: service`. Affinity still passes, but the spread check fails. Why is that bad at scale?
- Scale gateways to 5 mid-run (`docker compose -p lab-04 up -d --scale gateway=5 --no-recreate`). The hash ring changes. What happens to traces in flight?
- Set `decision_wait: 1s` with the 800 ms spans. Watch `otelcol_processor_tail_sampling_sampling_trace_dropped_too_early`.

## Interview questions this answers
- Head vs tail sampling: trade-offs, cost, and where each runs.
- Why does tail sampling need a load-balancing tier? What breaks when you scale the gateways?
- Agent vs gateway: what runs where, and why?
- How much memory does tail sampling need? (`num_traces` × trace size × `decision_wait`)

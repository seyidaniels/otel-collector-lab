# Lab 06: Kafka buffer (optional, no grader yet)

**Goal:** put Kafka between the agent tier and the gateway tier, so a gateway outage or redeploy never pushes back on the apps, and so you can replay data.

```
telemetrygen ─▶ agent ─▶ [kafka exporter] ─▶ topic otlp_spans ─▶ [kafka receiver] ─▶ gateway ─▶ Jaeger
```

## Build it yourself
1. Add a single-node Kafka to this lab's `compose.yml` (`apache/kafka` in KRaft mode needs no ZooKeeper).
2. `agent.yaml`: OTLP in → [kafka exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/kafkaexporter) (`encoding: otlp_proto`, topic `otlp_spans`).
3. `gateway.yaml`: [kafka receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/kafkareceiver) (same topic and encoding, a consumer `group_id`) → Jaeger.
4. Copy `traffic.sh` from lab 01 and set `OTLP_TARGET=agent:4317`. Write a `verify.sh` that checks the span count end to end. Use lab 01's grader as a template.

## Experiments
- Stop the gateway for 60s while traffic runs, then start it again. Watch consumer lag catch up.
- Run 3 gateways in the same consumer group. How are spans divided among them? (By partition, and the partition key decides it.) Which partition key would make tail sampling work here, without a loadbalancing exporter?

## Interview questions
- Kafka vs persistent queue (lab 05): durability, replay, fan-in from many agents, operational cost.
- What does at-least-once delivery mean for traces (duplicates), and does it matter?

Reference: pattern 8 in [jpkrohling/opentelemetry-collector-deployment-patterns](https://github.com/jpkrohling/opentelemetry-collector-deployment-patterns).

# otel-collector-lab

Hands-on labs for the **OpenTelemetry Collector**. Each lab gives you fake traffic and a spec; you write the collector config, and a grader tells you whether it works.

Everything runs locally in Docker. Traffic comes from [`telemetrygen`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/telemetrygen), and the backends are Jaeger, Prometheus and Grafana.

## Quick start
```bash
make backends             # Jaeger :16686 · Prometheus :9090 · Grafana :3000
cd labs/00-hello-pipeline && cat README.md && cd -
$EDITOR labs/00-hello-pipeline/collector.yaml   # delete the "# STUB" line, build the pipeline
make validate LAB=00      # does it parse and type-check?
make run LAB=00           # up → traffic → verify
```

| command | does |
|---|---|
| `make up LAB=NN` | start lab NN (stops any other lab, wipes Jaeger so results are this run's only) |
| `make traffic LAB=NN` | run the lab's `traffic.sh` |
| `make verify LAB=NN` | run the grader (`verify.sh`). Exits non-zero on failure |
| `make run LAB=NN` | all three |
| `make logs LAB=NN` | collector logs, where config errors and the debug exporter show up |
| `make validate LAB=NN` / `validate-all` | `otelcol-contrib validate` without starting anything |
| `make down LAB=NN` / `backends-down` | stop |

Requires Docker (with Compose v2), `make`, `curl` and `jq`.

## Labs
| # | Lab | You learn | Grader |
|---|---|---|---|
| 00 | [Hello pipeline](labs/00-hello-pipeline) | config anatomy, OTLP receiver, memory_limiter/batch, self-metrics | ✔ |
| 01 | [Per-signal fan-out](labs/01-per-signal-fanout) | traces→Jaeger+debug, metrics→Prometheus (OTLP), logs→file | ✔ |
| 02 | [Processors & OTTL](labs/02-processors-ottl) | resource enrich, filter, transform/OTTL, PII scrubbing, processor order | ✔ |
| 03 | [Connectors & routing](labs/03-connectors-routing) | routing connector (multi-tenant), spanmetrics (RED metrics) | ✔ |
| 04 | [Agent → gateway + tail sampling](labs/04-gateway-tail-sampling) | loadbalancing exporter, trace affinity, tail_sampling policies | ✔ |
| 05 | [Resilience & self-monitoring](labs/05-resilience-queues) | sending_queue, retry, persistent queue, backpressure dashboard | ✔ |
| 06 | [Kafka buffer](labs/06-kafka-buffer) | Kafka between tiers | build your own |
| 07 | [Custom distro (OCB)](labs/07-custom-distro-ocb) | collector builder, minimal distributions | — |
| 08 | [Kubernetes](labs/08-kubernetes) | links to the best KubeCon tutorials + concept map | — |

Every lab README ends with **"Break it"** experiments and **interview questions**. The failure stories from "Break it" are the useful part.

## Branches
- **`main`**: specs, traffic, graders, and *stub* configs for you to fill in.
- **`solutions`**: reference configs for labs 00–02. Compare with yours: `git diff main solutions -- labs/01-per-signal-fanout`. Commit your own solutions for 03+ there once they pass.

## Layout
```
compose.backends.yml   shared Jaeger / Prometheus (OTLP receiver on) / Grafana, network "otel-lab"
prometheus/            scrape config: collector self-metrics via DNS SD (otelcol, agent, gateway)
grafana/               provisioned datasources + "Collector health" dashboard
lib/                   traffic.sh (telemetrygen wrapper), verify.sh (assertions), validate, wait-ready
labs/NN-*/             README.md (spec) · collector.yaml (yours) · compose.yml · traffic.sh · verify.sh
```

## How the graders check your work
They never parse your YAML. They check **behaviour**:
- collector self-metrics on `:8888` (`otelcol_receiver_accepted_*`, `otelcol_exporter_sent_*`, per-processor `incoming/outgoing_items`, queue size)
- Jaeger's query API (`/api/traces`), so they see exactly what arrived, with which attributes
- Prometheus queries, and files written by the file exporter to `labs/NN/out/`

So any config that does the right thing passes, whatever you name your components.

## Tooling worth having open
- [OTelBin](https://www.otelbin.io/): paste a config, see the pipeline graph and validation errors.
- [OTTL Playground](https://ottl.run): test transform/filter statements against sample data.
- See [RESEARCH.md](RESEARCH.md) for the projects and docs these labs are based on.

Versions are pinned in [.env](.env) (collector-contrib 0.163.2).

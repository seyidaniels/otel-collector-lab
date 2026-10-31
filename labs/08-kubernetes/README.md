# Lab 08: Kubernetes (pointers)

Labs 00–05 cover collector config. On Kubernetes the new questions are **how collectors are deployed and discovered**. The best existing hands-on material is from the KubeCon tutorials below. Do them instead of re-creating them here.

| Tutorial | What you'll practise |
|---|---|
| [KubeCon EU 2023: OTel on Kubernetes](https://github.com/pavolloffay/kubecon-eu-2023-opentelemetry-kubernetes-tutorial) | Operator, `OpenTelemetryCollector` CR, auto-instrumentation, metrics, logs |
| [KubeCon NA 2023: metrics](https://github.com/pavolloffay/kubecon-na-2023-opentelemetry-kubernetes-metrics-tutorial) | Prometheus receiver + target allocator, kubelet/cluster metrics |
| [KubeCon EU 2024: tracing](https://github.com/pavolloffay/kubecon-eu-2024-opentelemetry-kubernetes-tracing-tutorial) | end-to-end tracing, OTTL transforms, sampling |
| [Deployment patterns](https://github.com/jpkrohling/opentelemetry-collector-deployment-patterns) | 8 topologies (configs are old, v0.33, but the patterns still apply) |

## Map lab concepts to Kubernetes
| Lab | On Kubernetes |
|---|---|
| 04 agent | DaemonSet (one per node), or a sidecar |
| 04 gateway | Deployment + **headless** Service; loadbalancing resolver `k8s` or `dns` |
| 05 persistent queue | StatefulSet + PVC, or Kafka |
| self-monitoring | ServiceMonitor / PodMonitor on `:8888` |
| enrichment | `k8sattributes` processor (pod, namespace, node metadata) |

## Interview questions
- DaemonSet vs sidecar vs Deployment for collectors: what does each one cost and what does it give you?
- Why does the loadbalancing exporter need a headless Service?
- How does the target allocator stop multiple collectors scraping the same Prometheus target?

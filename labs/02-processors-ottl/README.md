# Lab 02: Processors & OTTL

**Goal:** change telemetry in flight: enrich it, drop noise, scrub PII and migrate attribute names. This is most of what platform teams actually do with collectors.

```
[otlp] ─▶ memory_limiter ─▶ resource ─▶ filter ─▶ transform ─▶ batch ─▶ [otlp → Jaeger]
                            (+env)     (drop      (hash email,
                                       /healthz)  rename attr)
```

## What `traffic.sh` sends (all `service.name=checkout`)
- 20 traces with span attribute `url.path=/healthz`. These are noise.
- 30 traces with `url.path=/api/pay`, `user.email=alice@example.com` and `http.status_code=200` (the deprecated semconv name).

## Requirements (checked by `verify.sh`)
1. **Enrich:** add resource attribute `deployment.environment.name=lab` to everything.
2. **Drop:** no span with `url.path == "/healthz"` reaches Jaeger, so exactly 30 traces arrive.
3. **Scrub:** `user.email` becomes its SHA-256 hex digest. No raw `@` address may appear in any attribute.
4. **Migrate:** copy `http.status_code` to `http.response.status_code`, then delete the old key.
5. **Order:** drop before you transform. The grader checks that your transform processor only saw the 60 surviving spans. `memory_limiter` stays first.
6. Export to Jaeger as in lab 01.

## Run
```bash
make run LAB=02
```
Try your OTTL statements in the [OTTL Playground](https://ottl.run) before you restart the collector.

## Hints
- [resource processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourceprocessor) · [filter processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/filterprocessor) · [transform processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/transformprocessor) · [OTTL functions](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/pkg/ottl/ottlfuncs)
- filter: a span is **dropped** when a condition is **true**.
- transform: `set(...)`, `delete_key(...)` and the `SHA256(...)` converter. Guard statements with `where ... != nil`.
- Use `error_mode: ignore` on both processors. Think about what `propagate` would do to a whole batch if one statement errors.
- `otelcol_processor_incoming_items` / `outgoing_items{processor=...}` show what each processor did.

## Break it
- Swap the order to transform → filter. Which grader check fails, and what does it cost at 100k spans/s?
- Write a filter condition with a typo in the attribute name. Nothing is dropped and nothing errors. How would you catch that in CI?
- Hash with `SHA256` and think about whether that's really anonymisation for emails. (Hint: dictionary attacks.)

## Interview questions this answers
- Name the processors you'd run in a production pipeline, and their order.
- What is OTTL, and what are its contexts (resource, scope, span, spanevent, metric, datapoint, log)?
- How would you stop PII from reaching a vendor backend?
- `attributes` vs `resource` vs `transform` processor: when would you use each?

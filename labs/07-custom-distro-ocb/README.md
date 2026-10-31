# Lab 07: Custom distribution with OCB (stretch, no grader yet)

**Goal:** build your own collector binary that contains only the components labs 00–05 use. This is what security-conscious companies ship instead of `otelcol-contrib`, which has hundreds of components and a large attack surface.

## Steps
1. Install the builder: `go install go.opentelemetry.io/collector/cmd/builder@v0.163.0` (match `.env`'s collector version).
2. Write `builder-config.yaml` listing receivers (`otlp`), processors (`memorylimiter`, `batch`, `resource`, `filter`, `transform`, `tailsampling`), exporters (`otlp`, `otlphttp`, `debug`, `file`, `loadbalancing`), connectors (`routing`, `spanmetrics`) and extensions (`filestorage`). Pin each one to the same version.
3. `builder --config builder-config.yaml`, then run the binary against lab 02's `collector.yaml`.
4. Bonus: put it in a distroless image and point lab 02's `compose.yml` at it. `make run LAB=02` should still pass.

## Things to notice
- Binary size vs `otelcol-contrib`.
- What error you get when a config uses a component the distro doesn't include. (Hint: `make validate` is your friend in CI.)
- Where you'd register your own custom processor (`components.go` in the generated sources).

Docs: [Building a custom collector](https://opentelemetry.io/docs/collector/extend/ocb/) · [Extend the Collector](https://opentelemetry.io/docs/collector/extend/)

# Contest Readiness

This page makes MoonNavKit's repository-level acceptance checks explicit and
reproducible.

## Required validation

Run these commands from the repository root:

```sh
moon check --target all
moon fmt --check
moon info
git diff --exit-code
moon test --target all
moon run cmd/main
moon run cmd/bench
```

The CI workflow runs the first five commands on Linux, macOS, and Windows, then
runs both deterministic commands on Linux.

## Why the format and metadata commands differ from older checklists

The supported Moon CLI does not accept `--deny-warn` for either `moon fmt` or
`moon info`; passing it makes the command fail before validation starts.
`moon fmt --check` is the supported non-mutating format gate. `moon info`
followed by `git diff --exit-code` is the supported API metadata gate. The
workflow intentionally uses these executable commands rather than unsupported
arguments.

## Library scope and evidence

MoonNavKit is a deterministic, dependency-free navigation library for weighted
four-direction grids and directed graphs. It covers one-shot search, reusable
many-agent flow fields, clearance-aware routing, route validation/compression,
and dynamic D* Lite repair for a moving agent with a fixed goal.

The public README includes runnable grid and dynamic replanning examples. The
benchmark command emits deterministic CSV rows for static grid/graph search,
many-agent flow fields, clearance constraints, compression, and dynamic repair.
The dynamic scenario verifies its D* Lite repair against a fresh Dijkstra route
after the same map update.

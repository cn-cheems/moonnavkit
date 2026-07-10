# Performance Benchmarking

MoonNavKit includes deterministic benchmark scenarios and a local performance
report script. The goal is to keep performance evidence reproducible across
MoonBit backends instead of relying on vague claims.

## Benchmark Command

```sh
moon run cmd/bench
```

The command reports correctness and workload counters:

- path found status
- path cost
- visited node count
- trace length
- raw or compressed path length

## Three-Backend Report

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\perf_report.ps1
```

The script emits:

- `reports/perf-report.csv`
- `reports/perf-report.md`

It runs `moon check`, wasm tests, wasm-gc tests, JS benchmark execution, and
native build when the host has a C compiler. It also records produced artifact
sizes for wasm, wasm-gc, JS, and native outputs.

## Hot Path Notes

Grid search no longer calls `neighbors4` inside the A*/Dijkstra/BFS expansion
loop. The public `neighbors4` API remains available, but the hot path now checks
the four candidate cells directly and avoids allocating a neighbor array for
every expanded node. This is a concrete step toward lower allocation pressure
and fewer GC interruptions during search-heavy workloads.

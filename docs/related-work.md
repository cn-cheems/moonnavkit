# Related Work and Project Boundary

Checked on 2026-07-06 against the public Mooncakes registry and linked source
repositories.

## Ecosystem Scan

- [`mizchi/terrain`](https://mooncakes.io/docs/mizchi/terrain) focuses on
  procedural terrain and dungeon generation. Some generators guarantee paths,
  but it is not a reusable weighted routing and search-observability library.
- [`zhuguiyuan/eda-router`](https://mooncakes.io/assets/zhuguiyuan/eda-router/congestion_aware_router.mbt.html)
  contains application-specific EDA routing with bend and via penalties.
  MoonNavKit instead offers domain-neutral grid and graph APIs, deterministic
  traces, and reusable many-goal routing fields.
- [`moonbitlang/core`](https://mooncakes.io/docs/moonbitlang/core/) provides
  generic queues and collections. MoonNavKit builds path-planning semantics,
  correctness rules, result models, and visualization exports on top.

The registry search did not identify a published MoonBit package combining
weighted grid and graph BFS/Dijkstra/A*, admissibility-safe arbitrary-graph A*,
multi-goal flow fields, deterministic traces, and SVG/HTML/DOT export.

## Deliberate Scope

MoonNavKit is not a navigation mesh, physics engine, terrain generator, or EDA
router. It is a backend-neutral algorithm layer that applications can use
without browser, filesystem, GUI, or native-only dependencies.

Its differentiators are:

1. Correctness-first weighted routing with explicit unreachable behavior.
2. One-build, many-query flow fields for multi-agent workloads.
3. Search traces and portable exports for debugging and teaching.
4. Identical core API across native, JavaScript, WebAssembly, and Wasm-GC.
5. Seeded scenarios and public benchmark output that reviewers can reproduce.

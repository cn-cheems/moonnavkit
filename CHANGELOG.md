# Changelog

All notable changes to MoonNavKit are recorded here so contest reviewers and
future users can trace the project history without reading every commit.

## Unreleased

### Changed

- Graph searches now iterate an internal adjacency table instead of scanning
  every edge for each expanded node. The existing `edges` and `neighbors` APIs
  remain available for inspection and export.

### Added

- Added frame-budgeted `DynamicGridPlanner::replan_step` and
  `DynamicReplanStatus` for game and simulation update loops.
- Added deterministic D* Lite repair traces with JSON export through the shared
  `SearchTrace` API.
- Added `DynamicGridPlanner`, a stateful D* Lite planner for incrementally
  repairing four-direction weighted grid routes after obstacle and cost updates.
- Added deterministic dynamic-replanning tests, benchmark output, API guide,
  and runnable example that compare repaired routes with fresh Dijkstra runs.
- Added a standard GitHub-facing `README.md` with installation, feature, and
  navigation guidance.

### Fixed

- Removed per-expansion neighbor-array allocation from the grid search hot path.
- Replaced the CI workflow with the official MoonBit community template style
  and removed unsupported `--deny-warn` command arguments from the review path.
- Removed the local self-import left by package verification.

### Added

- Added open trait interfaces for map-like inputs, solver strategy values, and
  path smoothing strategy values.
- Added a PowerShell performance report script for wasm, wasm-gc, JS, native
  build availability, command timings, and artifact sizes.
- Added line-of-sight checks and waypoint compression for turning raw
  cell-by-cell search paths into executable route waypoints.
- Added path post-processing tests and a deterministic compression benchmark
  scenario.
- Added clearance-aware routing for non-point agents, including
  `AgentProfile`, `ClearanceMap`, obstacle inflation, footprint checks, and
  `GridMap::find_path_for_agent`.
- Added a deterministic clearance benchmark scenario showing that large agents
  are rejected from one-cell corridors while point agents still route normally.
- Added `GridMap::analyze_path` for route legality, cost, step, and turn
  analysis on externally supplied or generated paths.
- Added weighted multi-goal flow fields with O(path length) route queries.
- Added cost, next-step, selected-goal, route, and JSON diagnostic APIs.
- Added many-agent benchmark evidence comparing one field build with repeated
  Dijkstra searches.
- Added `cmd/bench`, a deterministic benchmark-style command for comparing
  grid and graph search behavior across commits.
- Added benchmark scenario documentation with stable seeds and output fields.
- Added Graphviz DOT export for graph search results.

## 0.2.0 - 2026-06-03

### Added

- Added a stable `MinPriorityQueue` for open-set management.
- Added regression coverage for stale queue entries in graph Dijkstra search.
- Added issue templates for bug reports, feature requests, and performance work.
- Added a pull request template with verification and changelog checks.

### Changed

- Graph A* now derives an admissible scale from edge weights and node geometry;
  unsafe coordinate heuristics automatically degrade to Dijkstra behavior.
- CI now validates native, JavaScript, WebAssembly, and Wasm-GC backends.

### Fixed

- Fixed Graph A* returning a suboptimal route when geometric distance
  overestimated arbitrary graph edge costs.
- Grid search now uses the shared priority queue instead of a linear open-set scan.
- Graph search now uses the shared priority queue instead of a linear open-set scan.
- Updated performance notes and roadmap to reflect the priority queue optimization.

### Verified

- `moon check`
- `moon test` with 28 passing tests

## 0.1.0 - 2026-06-01

### Added

- Initialized the MoonBit package and GitHub CI.
- Added `Point`, `GridMap`, and weighted `Graph` models.
- Added BFS, Dijkstra, and A* for grid search.
- Added BFS, Dijkstra, and A* for graph search.
- Added `SearchTrace`, JSON export, SVG export, and standalone HTML export.
- Added deterministic random grid generation and grid statistics.
- Added README examples, roadmap, and performance notes.

### Verified

- `moon test` with 25 passing tests

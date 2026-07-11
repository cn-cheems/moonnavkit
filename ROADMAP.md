# MoonNavKit Roadmap

MoonNavKit is being developed as a reusable MoonBit path planning and search
visualization toolkit. This roadmap keeps the project scoped for the contest
while leaving room for stronger engineering work.

## Completed Foundation

- MoonBit project skeleton and CI.
- `Point`, `GridMap`, and weighted `Graph` models.
- BFS, Dijkstra, and A* for grid maps.
- BFS, Dijkstra, and A* for weighted graphs.
- Manhattan, Euclidean, and Octile heuristics.
- `PathResult`, `GraphPathResult`, and `SearchTrace`.
- `NavigationMap`, `PathSolver`, and `PathSmoother` extension traits.
- JSON export for path results and trace data.
- SVG export for grid visualizations.
- Standalone HTML replay export.
- Deterministic random grid generation.
- Grid statistics and performance notes.
- Stable min-priority queue for grid and graph open sets.
- Clearance-aware routing for non-point agents.
- Line-of-sight route validation and waypoint compression.
- Hot-path grid search avoids per-expansion neighbor-array allocation.
- D* Lite repair for fixed-endpoint routes on changing weighted grids.
- Deterministic dynamic-replanning benchmark and API guide.
- 54 passing tests.

## Near-Term Work

1. Navigable abstraction

   Define a public navigation trait so user-owned map structures can feed the
   same pathfinding algorithms without copying into `GridMap` or `Graph`.

2. More search variants

   Candidate algorithms:

   - Bidirectional BFS
   - Weighted A*
   - Greedy best-first search

3. Better visualization replay

   Extend generated HTML with lightweight controls:

   - Step-by-step replay
   - Expanded-node order display
   - Path and trace toggles
   - Embedded JSON payload inspection

4. Path post-processing

   Expand the current line-of-sight compression into optional smoothing modes
   and richer route-quality reports.

5. Agent-aware navigation

   Extend clearance routing with additional footprint models and benchmark
   cases for warehouse robots, tactical units, and evacuation simulations.

6. Benchmark command and records

   Extend reproducible scenarios with larger dynamic-update workloads and track
   path cost, visited nodes, trace length, and output size.

## Contest Deliverables

- Public GitHub repository.
- GitLink mirror.
- README with runnable examples.
- CI with `moon check`, `moon fmt --check`, `moon info`, and `moon test`.
- Development report.
- Proposal PDF.
- Final submission checklist.
- Demo SVG/HTML examples.

## Non-Goals For The First Contest Version

- Full game engine integration.
- 3D navigation meshes.
- Large-scale distributed graph processing.
- Heavy frontend framework dependency.
- Real robot control stack.

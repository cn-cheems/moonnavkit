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
- JSON export for path results and trace data.
- SVG export for grid visualizations.
- Standalone HTML replay export.
- Deterministic random grid generation.
- Grid statistics and performance notes.
- 25 passing tests.

## Near-Term Work

1. Priority queue optimization

   Replace the current linear next-node selection with a priority queue for
   Dijkstra and A*. This should improve larger grid and graph workloads while
   keeping behavior deterministic.

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

   Add optional path smoothing and path compression for grid results.

5. Benchmark command and records

   Add reproducible benchmark scenarios based on seeded grids and graph cases.
   Track path cost, visited nodes, trace length, and output size.

## Contest Deliverables

- Public GitHub repository.
- GitLink mirror.
- README with runnable examples.
- CI with `moon check` and `moon test`.
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

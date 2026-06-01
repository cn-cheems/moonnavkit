# Performance Notes

MoonNavKit currently favors clear, deterministic behavior over specialized data
structures. The implementation is intentionally simple in the early contest
stage so correctness, trace export, and visualization can be built on stable
ground.

## Current Complexity

Grid search and graph search both use a linear scan to select the next open
node. This keeps the implementation dependency-free and easy to inspect.

| Operation | Current complexity |
| --- | --- |
| BFS on grid | O(V^2 + E) with current selector |
| Dijkstra on grid/graph | O(V^2 + E) |
| A* on grid/graph | O(V^2 + E) |
| Trace export | O(number of expanded nodes) |
| SVG export | O(grid cells + expanded nodes + path length) |

`V` is the number of grid cells or graph nodes. `E` is the number of grid
neighbor transitions or graph edges.

## Deterministic Map Generation

Random maps are generated from `RandomGridConfig`. The generator is
deterministic: the same width, height, seed, blocked percentage, weighted
percentage, and max weight always produce the same map.

This makes performance notes and regression tests reproducible.

Suggested benchmark scenarios:

| Scenario | Config | Algorithm | Metric |
| --- | --- | --- | --- |
| Small grid | 16 x 16, seed 101, 10% blocked, 20% weighted | BFS, Dijkstra, A* | visited cells, path cost |
| Medium grid | 32 x 32, seed 202, 20% blocked, 25% weighted | Dijkstra, A* | visited cells, trace length |
| Dense grid | 40 x 40, seed 303, 35% blocked, 15% weighted | A* | reachable rate, visited cells |
| Weighted grid | 32 x 32, seed 404, 5% blocked, 60% weighted | Dijkstra, A* | final cost, route shape |
| Graph route | 100 nodes, sparse positive weights | Dijkstra, A* | path cost, expanded nodes |

## Current Engineering Direction

Near-term performance work should be done after the public API stabilizes:

- Replace linear next-node selection with a priority queue for Dijkstra and A*.
- Add deterministic benchmark commands.
- Add golden JSON/SVG output samples for important map seeds.
- Track visited node count, trace length, path cost, and output size in docs.
- Compare BFS, Dijkstra, and A* on the same seeded grids.

## Why This Matters

For the contest, deterministic workloads help reviewers reproduce behavior
quickly. They also make the project easier to maintain because correctness,
visual output, and performance changes can be compared across commits.

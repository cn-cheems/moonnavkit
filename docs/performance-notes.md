# Performance Notes

MoonNavKit keeps correctness and deterministic traces as the first priority, but
the core weighted searches now use an internal stable min-priority queue. This
keeps the implementation inspectable while avoiding a full open-set scan on
larger maps and graphs.

## Current Complexity

Grid search and graph search share `MinPriorityQueue` for the open set. Entries
are stable for equal priorities, and stale entries are skipped when a better
distance has already been recorded. Graphs maintain an adjacency table, so an
expansion visits only the current node's outgoing edges rather than rescanning
the full edge list.

| Operation | Current complexity |
| --- | --- |
| BFS on grid/graph | O((V + E) log V) with the shared open set |
| Dijkstra on grid/graph | O((V + E) log V) |
| A* on grid/graph | O((V + E) log V) |
| Build weighted flow field | O((V + E) log V) |
| Query a flow-field route | O(path length) |
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
| Many-agent routing | 32 x 32, seed 707, 64 starts | repeated Dijkstra, flow field | equal total cost, search expansions |

## Current Engineering Direction

Near-term performance work should focus on reproducible measurement:

- Add golden JSON/SVG output samples for important map seeds.
- Track visited node count, trace length, path cost, and output size in docs.
- Compare BFS, Dijkstra, and A* on the same seeded grids.
- Extend flow fields with incremental rebuilding for dynamic obstacles.

## Why This Matters

For the contest, deterministic workloads help reviewers reproduce behavior
quickly. They also make the project easier to maintain because correctness,
visual output, and performance changes can be compared across commits.

# Benchmark Scenarios

MoonNavKit includes a deterministic benchmark-style command for tracking search
behavior across commits. The command records algorithm outputs that are useful
for regression checks: whether a path was found, final cost, visited nodes,
trace length, and path length.

Run it from the repository root:

```sh
moon run cmd/bench
```

The output is CSV-like:

```text
scenario,algorithm,found,cost,visited,trace,path_length
open-16x16,bfs,true,30,256,256,31
```

## Included Scenarios

- `open-16x16`: compares BFS, Dijkstra, and A* on an empty grid.
- `weighted-32x32-seed404`: compares Dijkstra and A* on a seeded weighted grid.
- `dense-40x40-seed303`: checks A* behavior on a denser seeded grid.
- `graph-route-5`: compares Dijkstra and A* on a small weighted directed graph.
- `many-agent-32x32-seed707`: compares 64 repeated Dijkstra searches with one
  weighted flow-field build plus 64 route queries.
- `clearance-door-7x5`: compares point-agent BFS with radius-1 footprint
  routing on a one-cell doorway. Start and goal both have enough clearance; the
  only invalid part is the narrow doorway itself.
- `compression-detour-5x3`: compares a raw cell-by-cell BFS route with the
  compressed waypoint route after line-of-sight post-processing.

## How To Use The Results

- Keep the same seeds when comparing commits.
- Treat path cost and found status as correctness signals.
- Treat visited count and trace length as performance direction signals.
- Add a new row when a new algorithm, map type, or graph workload is introduced.

The many-agent scenario currently reports equal total route cost (`3212`) while
reducing search expansions from `47672` to `1024`. See
[Weighted Multi-Goal Flow Fields](flow-fields.md) for interpretation.

The clearance scenario is a correctness benchmark rather than a speed benchmark:
it proves that MoonNavKit can reject physically impossible routes while reusing
the same search algorithms.

The compression scenario tracks route executability: the search still reports
the original grid cost and visited count, while the compressed row reports how
many waypoints a downstream renderer or steering system would need to follow.


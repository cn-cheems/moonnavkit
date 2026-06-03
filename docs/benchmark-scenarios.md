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

## How To Use The Results

- Keep the same seeds when comparing commits.
- Treat path cost and found status as correctness signals.
- Treat visited count and trace length as performance direction signals.
- Add a new row when a new algorithm, map type, or graph workload is introduced.


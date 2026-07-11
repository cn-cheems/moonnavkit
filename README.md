# MoonNavKit

Weighted path planning, clearance-aware routing, flow fields, path compression,
and search visualization for [MoonBit](https://www.moonbitlang.com/).

MoonNavKit provides deterministic grid and graph navigation primitives for
games, simulations, teaching tools, and visualization systems.

## Highlights

- BFS, Dijkstra, and admissibility-safe A* for grids and directed graphs
- Weighted multi-goal flow fields for many agents sharing destinations
- Clearance-aware routes for agents with a square footprint
- Line-of-sight validation and waypoint compression
- Search traces plus JSON, SVG, HTML replay, and Graphviz DOT export
- Deterministic random-map generation and benchmark scenarios

## Install

Add the package to a MoonBit project:

```sh
moon add cn-cheems/moonnavkit
```

## Quick start

```mbt
import "cn-cheems/moonnavkit"

let grid = @moonnavkit.GridMap::new(5, 5)
  .set_blocked(@moonnavkit.Point::new(1, 0))
  .set_weight(@moonnavkit.Point::new(3, 2), 5)

let result = grid.astar(
  @moonnavkit.Point::new(0, 0),
  @moonnavkit.Point::new(4, 4),
  @moonnavkit.Heuristic::Manhattan,
)

assert_true(result.found)
```

## Choose an algorithm

| Need | Use |
| --- | --- |
| Fewest steps on an unweighted map | `bfs` |
| Lowest traversal cost | `dijkstra` |
| Lowest cost with a useful goal estimate | `astar` |
| Many starts sharing one or more goals | `flow_field` |
| Agents with non-point footprints | `find_path_for_agent` |

## Documentation

The MoonBit documentation source and complete runnable examples are in
[README.mbt.md](README.mbt.md). Additional guides cover the
[architecture](docs/architecture.md), [flow fields](docs/flow-fields.md),
[clearance routing](docs/clearance-routing.md),
[path post-processing](docs/path-post-processing.md), and
[benchmark scenarios](docs/benchmark-scenarios.md).

## Development

```sh
moon check --target all
moon test --target all
moon run cmd/main
moon run cmd/bench
```

Licensed under [Apache-2.0](LICENSE).

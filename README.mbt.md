# MoonNavKit

MoonNavKit is a backend-neutral MoonBit path planning, reusable flow-field, and
search visualization toolkit.

It provides reusable grid and graph pathfinding primitives for games,
simulation, teaching tools, and visualization systems.

## Status

This project is being prepared for the MoonBit open-source ecosystem
contribution contest.

Current foundation:

- Grid coordinates with `Point`
- Weighted rectangular `GridMap`
- Weighted directed/undirected `Graph`
- Four-direction neighbors
- BFS for unweighted shortest paths
- Dijkstra for weighted shortest paths
- A* with Manhattan, Euclidean, and Octile heuristics
- Weighted multi-goal flow fields for many-agent routing
- Incremental D* Lite repair for dynamic obstacles and traversal costs
- Clearance-aware routing for non-point agents and robot/unit footprints
- Line-of-sight checks and waypoint compression for executable routes
- Admissibility-safe A* on arbitrary weighted graphs
- Stable min-priority queue for open-set management
- Search trace recording
- JSON export for path results and trace data
- SVG export for visual inspection
- Graphviz DOT export for graph search results
- Standalone HTML replay export
- Deterministic random grid generation
- Grid statistics for benchmark notes

## Quick Example

```mbt nocheck
///|
test {
  let grid = GridMap::new(5, 5)
    .set_blocked(Point::new(1, 0))
    .set_blocked(Point::new(1, 1))
    .set_weight(Point::new(3, 2), 5)

  let result = grid.astar(
    Point::new(0, 0),
    Point::new(4, 4),
    Heuristic::Manhattan,
  )

  assert_true(result.found)
  let json = result.to_json()
  assert_true(json.length() > 0)
}
```

## Graph Example

MoonNavKit also supports general weighted graphs. Node positions are optional for
Dijkstra, but useful for A* heuristics and visualization-oriented exports.

```mbt nocheck
///|
test {
  let graph = Graph::new()
  let start = graph.add_node(Point::new(0, 0))
  let mid = graph.add_node(Point::new(1, 0))
  let goal = graph.add_node(Point::new(2, 0))

  graph.add_directed_edge(start, mid, 1) |> ignore
  graph.add_directed_edge(mid, goal, 1) |> ignore
  graph.add_directed_edge(start, goal, 5) |> ignore

  let result = graph.astar(start, goal, Heuristic::Manhattan)

  assert_true(result.found)
  assert_eq(result.cost, 2)
  assert_true(result.nodes == [start, mid, goal])
}
```

## Trait-Oriented Extension Points

MoonNavKit exposes open traits for the parts users usually want to swap:

- `NavigationMap` for map-like inputs
- `PathSolver` for algorithm strategy values
- `PathSmoother` for post-processing strategies

```mbt nocheck
///|
test {
  let solver = GridSolver::new(Algorithm::AStar(Heuristic::Manhattan))
  let grid = GridMap::new(4, 1)
  let result = solve_with(solver, grid, Point::new(0, 0), Point::new(3, 0))

  assert_true(result.found)
}
```

The default `GridMap` remains simple and efficient, while the trait layer gives
library users a path toward custom maps, custom solvers, and custom smoothing
without changing MoonNavKit's core algorithms.

## Dynamic Replanning

Static A* is not enough for a game or simulation where a door closes, a unit
occupies a cell, or a terrain cost changes after a route is planned.
`DynamicGridPlanner` retains D* Lite search state for a fixed start/goal pair,
then repairs only affected vertices after local updates.

```mbt nocheck
///|
test {
  let start = Point::new(0, 1)
  let goal = Point::new(4, 1)
  let planner = DynamicGridPlanner::new(GridMap::new(5, 3), start, goal)

  assert_eq(planner.replan().cost, 4)
  planner.set_blocked(Point::new(2, 1)) |> ignore
  let repaired = planner.replan()

  assert_true(repaired.found)
  assert_eq(repaired.cost, 6)
}
```

The planner is intentionally scoped to four-direction weighted grids with a
fixed start and goal. It is a stateful planning object rather than a replacement
for one-shot BFS, Dijkstra, or A*.

## Many-Agent Flow Fields

When many agents share destinations, repeatedly running A* wastes the same
search work. `flow_field` performs one reverse Dijkstra build, then reconstructs
each agent route in O(path length).

```mbt nocheck
///|
test {
  let grid = GridMap::new(8, 5)
    .set_weight(Point::new(3, 2), 8)
    .set_blocked(Point::new(4, 2))
  let loading_bay = Point::new(7, 2)
  let emergency_exit = Point::new(0, 4)
  let field = grid.flow_field([loading_bay, emergency_exit])

  let robot_route = field.path_from(Point::new(1, 0))
  assert_true(robot_route.found)
  assert_true(field.goal_for(Point::new(1, 0)) is Some(_))
}
```

This supports deterministic routing for warehouse robots, game units,
evacuation simulations, and repeated "nearest service point" queries. Invalid
or blocked goals are ignored, unreachable cells remain explicit, and the field
can be exported as JSON for inspection.

## Clearance-Aware Routing

Many demos treat every moving object as a point, but real game units, warehouse
robots, and simulated agents occupy space. MoonNavKit can derive a footprint-safe
grid before running BFS, Dijkstra, or A*.

```mbt nocheck
///|
test {
  let grid = GridMap::new(7, 5)
    .set_blocked(Point::new(3, 0))
    .set_blocked(Point::new(3, 1))
    .set_blocked(Point::new(3, 3))
    .set_blocked(Point::new(3, 4))

  let point_agent = grid.bfs(Point::new(1, 2), Point::new(5, 2))
  let large_agent = grid.find_path_for_agent(
    Point::new(1, 2),
    Point::new(5, 2),
    Algorithm::BFS,
    AgentProfile::new(1),
  )

  assert_true(point_agent.found)
  assert_false(large_agent.found)
}
```

`AgentProfile::new(1)` requires a 3x3 traversable footprint around each routed
cell. Positive weights are preserved for safe cells, and cells that cannot host
the footprint are treated as blocked in the derived routing grid.

## Waypoint Compression

Grid search returns a cell-by-cell route. For rendering, steering, or robot
commands, a smaller waypoint path is often more useful. MoonNavKit can compress
successful routes with line-of-sight checks while respecting blocked cells and
agent footprints.

```mbt nocheck
///|
test {
  let grid = GridMap::new(5, 3).set_blocked(Point::new(2, 1))
  let result = grid.bfs(Point::new(0, 1), Point::new(4, 1))
  let waypoints = result.compressed_path(grid, AgentProfile::point())

  assert_true(result.found)
  assert_true(waypoints.length() < result.path.length())
}
```

## Path Quality Analysis

Search results and externally supplied routes can be replayed against the grid.
This is useful for regression checks, teaching tools, and game/simulation code
that wants to validate a route before handing it to agents.

```mbt nocheck
///|
test {
  let grid = GridMap::new(4, 3)
    .set_weight(Point::new(1, 0), 5)
    .set_weight(Point::new(2, 1), 3)
  let result = grid.dijkstra(Point::new(0, 0), Point::new(3, 1))
  let metrics = grid.analyze_path(result.path)

  assert_true(metrics.valid)
  assert_eq(metrics.cost, result.cost)
  assert_true(metrics.turns >= 0)
}
```

Graph results can also be exported as Graphviz DOT:

```mbt nocheck
///|
test {
  let graph = Graph::new()
  let start = graph.add_node(Point::new(0, 0))
  let goal = graph.add_node(Point::new(1, 0))
  graph.add_directed_edge(start, goal, 2) |> ignore

  let result = graph.dijkstra(start, goal)
  let dot = graph.to_dot(result)

  assert_true(dot.contains("digraph MoonNavKit"))
  assert_true(dot.contains("cost=2"))
}
```

## Trace Export

Every search records expanded cells in order. This makes the core library useful
for debugging, teaching, and visualization replay.

```mbt nocheck
///|
test {
  let result = GridMap::new(3, 1).bfs(Point::new(0, 0), Point::new(2, 0))
  assert_eq(result.trace.length(), 3)
  assert_eq(
    result.trace.to_json(),
    "{\"steps\":[{\"order\":0,\"point\":{\"x\":0,\"y\":0},\"cost\":0,\"score\":0},{\"order\":1,\"point\":{\"x\":1,\"y\":0},\"cost\":1,\"score\":1},{\"order\":2,\"point\":{\"x\":2,\"y\":0},\"cost\":2,\"score\":2}]}",
  )
}
```

## Visualization Export

The same result can be exported as SVG or a standalone HTML replay page.

```mbt nocheck
///|
test {
  let grid = GridMap::new(4, 3)
    .set_blocked(Point::new(1, 0))
    .set_blocked(Point::new(1, 1))
    .set_weight(Point::new(2, 1), 4)

  let result = grid.astar(
    Point::new(0, 0),
    Point::new(3, 2),
    Heuristic::Manhattan,
  )

  let svg = grid.to_svg(result, 24)
  assert_true(svg.contains("<svg"))

  let html = grid.to_html(result, 24)
  assert_true(html.contains("MoonNavKit Replay"))
}
```

SVG uses consistent colors for the main states:

- Dark cells are blocked.
- Yellow cells have custom weights.
- Blue overlays are expanded search steps.
- Green lines are final paths.
- Green and red circles mark start and goal.

## Random Grid Generation

Seeded maps are deterministic, so examples, tests, and benchmark notes can be
reproduced exactly.

```mbt nocheck
///|
test {
  let start = Point::new(0, 0)
  let goal = Point::new(5, 5)
  let config = RandomGridConfig::new(6, 6, 11)
    .with_blocked_percent(5)
    .with_weighted_percent(30)
    .with_max_weight(7)

  let grid = GridMap::random_with_clear_points(config, [start, goal])
  let stats = grid.stats()
  let result = grid.astar(start, goal, Heuristic::Manhattan)

  assert_eq(stats.cells, 36)
  assert_true(result.trace.length() > 0)
}
```

## Roadmap

- More examples and benchmark notes
- Additional replay controls for generated HTML
- Benchmark notes for grid and graph search
- Route quality metrics for downstream simulation and validation tools
- Clearance maps and footprint-aware path planning for non-point agents
- Path compression and line-of-sight tools for executable routes

See [Roadmap](ROADMAP.md) for planned contest deliverables and non-goals.
See [Performance Notes](docs/performance-notes.md) for current complexity and
reproducible benchmark scenarios.
See [Performance Benchmarking](docs/performance-benchmarking.md) for the
three-backend report script and hot-path allocation notes.
See [Architecture](docs/architecture.md) for the trait-oriented extension
points and current hot-path design.
See [Benchmark Scenarios](docs/benchmark-scenarios.md) for the deterministic
`moon run cmd/bench` output used to track search behavior across commits.
See [Flow Fields](docs/flow-fields.md) for cost semantics, complexity, and
many-agent use cases.
See [Clearance Routing](docs/clearance-routing.md) for footprint-aware routing
semantics and benchmark evidence.
See [Path Post-Processing](docs/path-post-processing.md) for line-of-sight and
waypoint compression APIs.
See [Dynamic Replanning](docs/dynamic-replanning.md) for D* Lite semantics,
update rules, and benchmark interpretation.
See [Contest Readiness](docs/contest-readiness.md) for the exact CI validation
commands and their current Moon CLI compatibility notes.
See [Related Work](docs/related-work.md) for the project boundary within the
MoonBit ecosystem.

## Development Tracking

MoonNavKit uses issue templates, pull request templates, and `CHANGELOG.md` so
ongoing work can be reviewed through public repository history.

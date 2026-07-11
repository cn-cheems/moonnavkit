# MoonNavKit — dynamic navigation for MoonBit games and simulations

When a door closes, terrain cost changes, or a simulated unit blocks a route,
restarting A* for every update wastes work and can exceed a frame budget.
MoonNavKit is a dependency-free MoonBit navigation library that combines a
complete static-search toolkit with **incremental D* Lite repair** for changing
two-dimensional worlds.

It targets game AI, discrete simulation, visualization, and teaching tools.
One typed API builds for MoonBit's supported WebAssembly, JavaScript, and native
targets; the repository checks all targets in CI.

## Why D* Lite is the flagship

The deterministic `dynamic-32x32` benchmark plans across an open 32×32 grid,
blocks one cell on the route, then compares incremental repair with a fresh
Dijkstra run on the same changed map:

| Result after the update | D* Lite repair | Fresh Dijkstra |
| --- | ---: | ---: |
| Path found | true | true |
| Optimal cost | 33 | 33 |
| Expanded vertices | **97** | 799 |

This is an operation-count comparison rather than a machine-dependent timing
claim. Run `moon run cmd/bench` to reproduce it exactly.

## Capabilities

| Need | MoonNavKit API |
| --- | --- |
| Fewest steps on an unweighted map | `bfs` |
| Lowest traversal cost | `dijkstra` |
| Goal-directed static search | `astar` |
| Many starts sharing destinations | `flow_field` |
| Dynamic obstacle/cost updates with a fixed goal | `DynamicGridPlanner` |
| Frame-budgeted dynamic repair | `replan_step` |
| Agent footprints and narrow-corridor safety | `find_path_for_agent` |
| Inspectable routes and searches | JSON, SVG, HTML, DOT, `SearchTrace` |

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

## Dynamic replanning

For a game unit or simulator whose grid changes during a route, retain a
`DynamicGridPlanner` instead of restarting a search from scratch. Updates are
local; `replan` repairs the retained D* Lite state and returns an optimal route.

```mbt
import "cn-cheems/moonnavkit"

let start = @moonnavkit.Point::new(0, 1)
let goal = @moonnavkit.Point::new(4, 1)
let planner = @moonnavkit.DynamicGridPlanner::new(
  @moonnavkit.GridMap::new(5, 3), start, goal,
)

assert_eq(planner.replan().cost, 4)
planner.set_blocked(@moonnavkit.Point::new(2, 1)) |> ignore
let repaired = planner.replan()
assert_eq(repaired.cost, 6)
```

### Keep repair work inside a frame budget

Use `replan_step` to process a bounded number of vertices each frame. A
`Pending` result preserves the planner state; `Ready` returns the repaired
optimal route. `repair_trace` exposes the ordered local work for profiling,
visualization, or JSON export.

```mbt
let mut status = planner.replan_step(32)
match status {
  @moonnavkit.Pending(expanded) => println("repairing: \{expanded}")
  @moonnavkit.Ready(result) => assert_true(result.found)
}

let trace_json = planner.repair_trace().to_json()
```

`DynamicGridPlanner` deliberately has a narrow, verifiable contract: a
four-direction weighted grid with a fixed goal and a movable start. It does not
claim moving-goal support, NavMesh support, shared multi-agent state, or
incremental clearance updates.

```mbt
// The unit advances one cell; retain the repaired reverse-search state.
planner.move_start(@moonnavkit.Point::new(1, 1)) |> ignore
let next_route = planner.replan()
```

## MoonBit ecosystem value

MoonNavKit turns MoonBit's multi-target toolchain into a concrete reusable
navigation component: the same deterministic library API is checked for Wasm,
Wasm-GC, JavaScript, and native targets. It keeps the core dependency-free,
records search evidence as data, and offers reproducible command-line examples
instead of hiding behavior behind a framework or a game engine.

## Documentation

The MoonBit documentation source and complete runnable examples are in
[README.mbt.md](README.mbt.md). Additional guides cover the
[architecture](docs/architecture.md), [flow fields](docs/flow-fields.md),
[clearance routing](docs/clearance-routing.md),
[path post-processing](docs/path-post-processing.md), and
[benchmark scenarios](docs/benchmark-scenarios.md), and
[dynamic replanning](docs/dynamic-replanning.md).
See [dynamic replanning](docs/dynamic-replanning.md) for the D* Lite API,
frame-budget contract, trace semantics, and benchmark interpretation.
For the exact cross-platform checks used by CI, see
[contest readiness](docs/contest-readiness.md).

## Development

```sh
moon check --target all
moon test --target all
moon run cmd/main
moon run cmd/bench
```

Licensed under [Apache-2.0](LICENSE).

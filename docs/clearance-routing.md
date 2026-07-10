# Clearance-Aware Routing

MoonNavKit supports footprint-aware routing for agents that occupy more than one
grid cell. This turns the library from a point-path demo into a more realistic
navigation foundation for games, robotics simulations, warehouse planning, and
teaching tools.

## Why It Matters

Classic grid A* often treats every agent as a point. That works for small
examples, but it fails in real systems:

- a large game unit should not pass through a one-cell doorway;
- a warehouse robot needs clearance around shelves;
- simulation code needs deterministic small-agent and large-agent comparisons;
- planners need to explain why a route is invalid.

MoonNavKit solves this by deriving a footprint-safe grid before running the
existing BFS, Dijkstra, or A* implementation.

## API

```mbt
let agent = AgentProfile::new(1)
let result = grid.find_path_for_agent(
  Point::new(1, 2),
  Point::new(5, 2),
  Algorithm::AStar(Heuristic::Manhattan),
  agent,
)
```

Core helpers:

- `AgentProfile::new(radius_cells)` describes a square footprint.
- `GridMap::can_stand_at(point, agent)` checks a single cell.
- `GridMap::clearance_map(max_radius)` computes per-cell clearance.
- `GridMap::inflate_blocked(agent)` builds a derived routing grid.
- `GridMap::find_path_for_agent(start, goal, algorithm, agent)` runs the normal
  algorithms after clearance filtering.

## Semantics

A radius of `0` is the original point-agent behavior. A radius of `1` requires a
3x3 traversable footprint around the center cell. Weighted costs are preserved
on cells that remain traversable, while cells that cannot host the agent become
blocked in the derived grid.

This keeps the feature backend-neutral and deterministic: no browser APIs, no
engine-specific dependencies, and no hidden geometry state.

## Reproducible Evidence

Run:

```sh
moon run cmd/bench
```

The `clearance-door-7x5` rows compare point-agent and radius-1 routing on the
same one-cell doorway. The point agent can pass; the radius-1 agent is rejected
because its footprint would collide with the doorway walls, even though the
start and goal cells themselves have enough clearance.

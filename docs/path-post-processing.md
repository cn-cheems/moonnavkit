# Path Post-Processing

MoonNavKit separates path search from route execution. BFS, Dijkstra, A*, and
flow fields produce correct grid paths; post-processing turns those paths into
smaller waypoint routes that are easier for renderers, steering systems, and
simulation code to consume.

## Line Of Sight

`GridMap::has_line_of_sight(from, to, agent)` rasterizes the segment between two
points and checks every touched cell. It rejects blocked cells, out-of-bounds
endpoints, and cells that do not have enough clearance for the supplied
`AgentProfile`.

```mbt
let visible = grid.has_line_of_sight(
  Point::new(0, 1),
  Point::new(4, 1),
  AgentProfile::point(),
)
```

## Waypoint Compression

`GridMap::compress_path(path, agent)` greedily keeps the farthest visible next
waypoint. It preserves the original start and goal, but removes redundant
intermediate cells whenever the direct segment is executable.

```mbt
let result = grid.astar(start, goal, Heuristic::Manhattan)
let waypoints = result.compressed_path(grid, AgentProfile::point())
```

The method intentionally does not mutate `PathResult.cost` or
`PathResult.visited_count`: those fields describe the original grid search.
Compressed waypoints are a downstream execution artifact.

## Why It Matters

Cell-by-cell routes are correct, but often awkward to use directly. A route with
fewer waypoints is easier to visualize, transmit, test, and hand to a movement
controller. Combining compression with `AgentProfile` also keeps large-unit
routes honest: a shortcut is accepted only if the whole footprint has clearance.

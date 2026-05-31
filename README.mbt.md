# MoonNavKit

MoonNavKit is a MoonBit path planning and search visualization toolkit.

It provides reusable grid and graph pathfinding primitives for games,
simulation, teaching tools, and visualization systems.

## Status

This project is being prepared for the MoonBit open-source ecosystem
contribution contest.

Current foundation:

- Grid coordinates with `Point`
- Weighted rectangular `GridMap`
- Four-direction neighbors
- BFS for unweighted shortest paths
- Dijkstra for weighted shortest paths
- A* with Manhattan, Euclidean, and Octile heuristics

## Quick Example

```mbt
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
}
```

## Roadmap

- Search trace recording
- JSON export
- SVG/HTML visualization export
- General graph model
- More examples and benchmark notes

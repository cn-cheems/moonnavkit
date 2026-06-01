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
- Search trace recording
- JSON export for path results and trace data
- SVG export for visual inspection
- Standalone HTML replay export

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
  let json = result.to_json()
  assert_true(json.length() > 0)
}
```

## Trace Export

Every search records expanded cells in order. This makes the core library useful
for debugging, teaching, and visualization replay.

```mbt
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

```mbt
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

## Roadmap

- General graph model
- More examples and benchmark notes
- Additional replay controls for generated HTML

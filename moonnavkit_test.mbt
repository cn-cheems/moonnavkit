///|
test "point manhattan distance" {
  assert_eq(Point::new(0, 0).manhattan(Point::new(3, 4)), 7)
}

///|
test "grid contains valid cells only" {
  let grid = GridMap::new(3, 2)
  assert_true(grid.contains(Point::new(0, 0)))
  assert_true(grid.contains(Point::new(2, 1)))
  assert_false(grid.contains(Point::new(3, 1)))
  assert_false(grid.contains(Point::new(1, 2)))
  assert_false(grid.contains(Point::new(-1, 0)))
}

///|
test "blocked cells are not returned as neighbors" {
  let grid = GridMap::new(3, 3).set_blocked(Point::new(1, 0))
  let neighbors = grid.neighbors4(Point::new(0, 0))
  assert_true(neighbors == [Point::new(0, 1)])
}

///|
test "bfs finds shortest step path on an open grid" {
  let result = GridMap::new(3, 3).bfs(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.cost, 2)
  assert_true(
    result.path == [Point::new(0, 0), Point::new(1, 0), Point::new(2, 0)],
  )
}

///|
test "bfs routes around blocked cells" {
  let grid = GridMap::new(3, 3).set_blocked(Point::new(1, 0))
  let result = grid.bfs(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.cost, 4)
  assert_true(
    result.path == [
      Point::new(0, 0),
      Point::new(0, 1),
      Point::new(1, 1),
      Point::new(2, 1),
      Point::new(2, 0),
    ],
  )
}

///|
test "search reports unreachable goal" {
  let grid = GridMap::new(3, 3)
    .set_blocked(Point::new(1, 0))
    .set_blocked(Point::new(1, 1))
    .set_blocked(Point::new(1, 2))
  let result = grid.bfs(Point::new(0, 0), Point::new(2, 0))
  assert_false(result.found)
  assert_true(result.path == [])
  assert_eq(result.cost, -1)
}

///|
test "dijkstra prefers cheaper weighted route" {
  let grid = GridMap::new(3, 2).set_weight(Point::new(1, 0), 9)
  let result = grid.dijkstra(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.cost, 4)
  assert_true(
    result.path == [
      Point::new(0, 0),
      Point::new(0, 1),
      Point::new(1, 1),
      Point::new(2, 1),
      Point::new(2, 0),
    ],
  )
}

///|
test "astar finds path with manhattan heuristic" {
  let grid = GridMap::new(5, 3)
    .set_blocked(Point::new(1, 0))
    .set_blocked(Point::new(1, 1))
  let result = grid.astar(Point::new(0, 0), Point::new(4, 0), Heuristic::Manhattan)
  assert_true(result.found)
  assert_eq(result.cost, 8)
  assert_true(result.path[0] == Point::new(0, 0))
  assert_true(result.path[result.path.length() - 1] == Point::new(4, 0))
}

///|
test "find_path dispatches algorithms" {
  let grid = GridMap::new(4, 4)
  let bfs = grid.find_path(Point::new(0, 0), Point::new(3, 0), Algorithm::BFS)
  let astar = grid.find_path(
    Point::new(0, 0),
    Point::new(3, 0),
    Algorithm::AStar(Heuristic::Manhattan),
  )
  assert_true(bfs.found)
  assert_true(astar.found)
  assert_eq(bfs.cost, 3)
  assert_eq(astar.cost, 3)
}

///|
test "heuristic estimates" {
  let a = Point::new(0, 0)
  let b = Point::new(3, 4)
  assert_eq(Heuristic::Manhattan.estimate(a, b), 7)
  assert_eq(Heuristic::Euclidean.estimate(a, b), 5)
  assert_eq(Heuristic::Octile.estimate(a, b), 5)
}

///|
test "grid solver dispatches algorithm values" {
  let solver = GridSolver::new(Algorithm::AStar(Heuristic::Manhattan))
  let result = solve_with(
    solver,
    GridMap::new(4, 1),
    Point::new(0, 0),
    Point::new(3, 0),
  )
  assert_true(result.found)
  assert_eq(result.cost, 3)
}

///|
test "line of sight smoother works as strategy value" {
  let grid = GridMap::new(5, 3).set_blocked(Point::new(2, 1))
  let result = grid.bfs(Point::new(0, 1), Point::new(4, 1))
  let smoother = LineOfSightSmoother::new(AgentProfile::point())
  let compressed = smooth_with(smoother, grid, result.path)
  assert_true(result.found)
  assert_true(compressed.length() < result.path.length())
  assert_true(compressed[0] == Point::new(0, 1))
  assert_true(compressed[compressed.length() - 1] == Point::new(4, 1))
}

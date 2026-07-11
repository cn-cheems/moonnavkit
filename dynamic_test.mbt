///|
test "dynamic planner matches dijkstra before and after a blocked route changes" {
  let start = Point::new(0, 1)
  let goal = Point::new(4, 1)
  let grid = GridMap::new(5, 3)
  let planner = DynamicGridPlanner::new(grid, start, goal)

  let initial = planner.replan()
  let initial_expected = grid.dijkstra(start, goal)
  assert_true(initial.found)
  assert_eq(initial.cost, initial_expected.cost)

  planner.set_blocked(Point::new(2, 1)) |> ignore
  let repaired = planner.replan()
  let expected = planner.map().dijkstra(start, goal)
  assert_true(repaired.found)
  assert_eq(repaired.cost, expected.cost)
  assert_true(repaired.path != initial.path)
  assert_true(planner.last_replan_expanded_count() > 0)
}

///|
test "dynamic planner repairs a weighted route" {
  let start = Point::new(0, 0)
  let goal = Point::new(3, 0)
  let planner = DynamicGridPlanner::new(GridMap::new(4, 2), start, goal)
  let initial = planner.replan()
  assert_eq(initial.cost, 3)

  planner.set_weight(Point::new(1, 0), 9) |> ignore
  let repaired = planner.replan()
  let expected = planner.map().dijkstra(start, goal)
  assert_true(repaired.found)
  assert_eq(repaired.cost, expected.cost)
  assert_eq(repaired.cost, 5)
}

///|
test "dynamic planner reports no path when an update seals the map" {
  let start = Point::new(0, 0)
  let goal = Point::new(2, 0)
  let planner = DynamicGridPlanner::new(GridMap::new(3, 1), start, goal)
  assert_true(planner.replan().found)
  planner.set_blocked(Point::new(1, 0)) |> ignore
  let result = planner.replan()
  assert_false(result.found)
  assert_eq(result.cost, -1)
}

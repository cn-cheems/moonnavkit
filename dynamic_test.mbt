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

///|
test "dynamic planner can repair across deterministic frame budgets" {
  let start = Point::new(0, 1)
  let goal = Point::new(4, 1)
  let planner = DynamicGridPlanner::new(GridMap::new(5, 3), start, goal)
  let mut status = planner.replan_step(1)
  for _frame = 0; _frame < 16; _frame = _frame + 1 {
    match status {
      Pending(_) => status = planner.replan_step(1)
      Ready(_) => ()
    }
  }
  match status {
    Ready(result) => {
      assert_true(result.found)
      assert_eq(result.cost, 4)
      assert_eq(planner.repair_trace().length(), result.visited_count)
    }
    Pending(_) => assert_true(false)
  }
}

///|
test "dynamic repair trace records the local update work" {
  let start = Point::new(0, 1)
  let goal = Point::new(4, 1)
  let planner = DynamicGridPlanner::new(GridMap::new(5, 3), start, goal)
  ignore(planner.replan())
  planner.set_blocked(Point::new(2, 1)) |> ignore
  let repaired = planner.replan()
  let trace = planner.repair_trace()
  assert_true(repaired.found)
  assert_eq(trace.length(), repaired.visited_count)
  assert_true(trace.length() > 0)
  assert_eq(trace.steps[0].order, 0)
}

///|
test "dynamic planner repairs after the agent moves its start" {
  let planner = DynamicGridPlanner::new(
    GridMap::new(5, 3),
    Point::new(0, 1),
    Point::new(4, 1),
  )
  assert_eq(planner.replan().cost, 4)
  planner.move_start(Point::new(1, 1)) |> ignore
  let moved = planner.replan()
  let expected = planner.map().dijkstra(Point::new(1, 1), Point::new(4, 1))
  assert_true(moved.found)
  assert_eq(moved.cost, 3)
  assert_eq(moved.cost, expected.cost)
}

///|
test "key modifier reset rebuilds the queue without losing the route" {
  let planner = DynamicGridPlanner::new(
    GridMap::new(5, 3),
    Point::new(0, 1),
    Point::new(4, 1),
  )
  // Matches the library's private unreachable-cost sentinel minus one.
  planner.km = 999_999_999
  planner.move_start(Point::new(1, 1)) |> ignore
  let result = planner.replan()
  assert_eq(planner.queue_rebuild_count(), 1)
  assert_true(result.found)
  assert_eq(result.cost, 3)
}

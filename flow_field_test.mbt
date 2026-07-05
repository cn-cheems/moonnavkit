///|
test "flow field agrees with weighted Dijkstra" {
  let grid = GridMap::new(5, 3)
  ignore(grid.set_weight(Point::new(1, 1), 20))
  ignore(grid.set_weight(Point::new(2, 1), 20))
  ignore(grid.set_weight(Point::new(3, 1), 20))
  let start = Point::new(0, 1)
  let goal = Point::new(4, 1)
  let field = grid.flow_field([goal])
  let expected = grid.dijkstra(start, goal)
  let actual = field.path_from(start)
  assert_true(actual.found)
  assert_eq(actual.cost, expected.cost)
  assert_true(field.cost_from(start) == Some(expected.cost))
  assert_true(field.goal_for(start) == Some(goal))
  assert_true(actual.path.length() > 5)
}

///|
test "flow field reports blocked and unreachable cells" {
  let grid = GridMap::new(3, 3)
  ignore(grid.set_blocked(Point::new(1, 0)))
  ignore(grid.set_blocked(Point::new(1, 1)))
  ignore(grid.set_blocked(Point::new(1, 2)))
  let field = grid.flow_field([Point::new(2, 1)])
  assert_true(field.cost_from(Point::new(0, 1)) is None)
  assert_false(field.path_from(Point::new(0, 1)).found)
  assert_true(field.cost_from(Point::new(1, 1)) is None)
}

///|
test "flow field routes many starts to the nearest goal" {
  let grid = GridMap::new(7, 1)
  let left = Point::new(0, 0)
  let right = Point::new(6, 0)
  let field = grid.flow_field([left, right])
  assert_true(field.goal_for(Point::new(1, 0)) == Some(left))
  assert_true(field.goal_for(Point::new(5, 0)) == Some(right))
  assert_true(field.cost_from(Point::new(2, 0)) == Some(2))
  assert_true(field.cost_from(Point::new(4, 0)) == Some(2))
  assert_true(field.next_step(Point::new(1, 0)) == Some(left))
  assert_true(field.next_step(Point::new(5, 0)) == Some(right))
}

///|
test "flow field accepts each valid goal once" {
  let grid = GridMap::new(2, 2)
  let goal = Point::new(1, 1)
  ignore(grid.set_blocked(Point::new(0, 0)))
  let field = grid.flow_field([
    goal,
    goal,
    Point::new(-1, 0),
    Point::new(0, 0),
  ])
  assert_eq(field.goals.length(), 1)
  assert_eq(field.path_from(goal).cost, 0)
  assert_eq(field.path_from(goal).path.length(), 1)
  assert_true(field.next_step(goal) is None)
}

///|
test "flow field JSON contains portable diagnostics" {
  let field = GridMap::new(2, 1).flow_field([Point::new(1, 0)])
  let json = field.to_json()
  assert_true(json.contains("\"reachable_cells\":2"))
  assert_true(json.contains("\"goals\":[{\"x\":1,\"y\":0}]"))
  assert_true(json.contains("\"costs\":[1,0]"))
}

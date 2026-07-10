///|
test "point agent can stand on ordinary open cells" {
  let grid = GridMap::new(3, 3).set_blocked(Point::new(1, 1))
  assert_true(grid.can_stand_at(Point::new(0, 0), AgentProfile::point()))
  assert_false(grid.can_stand_at(Point::new(1, 1), AgentProfile::point()))
}

///|
test "radius agent needs full footprint clearance" {
  let grid = GridMap::new(5, 5).set_blocked(Point::new(2, 2))
  let large = AgentProfile::new(1)
  assert_false(grid.can_stand_at(Point::new(1, 1), large))
  assert_true(grid.can_stand_at(Point::new(3, 1), AgentProfile::point()))
}

///|
test "clearance map reports supported radius" {
  let grid = GridMap::new(5, 5).set_blocked(Point::new(0, 0))
  let clearance = grid.clearance_map(2)
  assert_true(clearance.radius_at(Point::new(2, 2)) == Some(1))
  assert_true(clearance.radius_at(Point::new(1, 1)) == Some(0))
  assert_true(clearance.radius_at(Point::new(0, 0)) == Some(-1))
  assert_true(clearance.can_host(Point::new(2, 2), AgentProfile::new(1)))
  assert_false(clearance.can_host(Point::new(1, 1), AgentProfile::new(1)))
}

///|
test "inflated grid closes narrow corridors for large agents" {
  let grid = GridMap::new(5, 5)
    .set_blocked(Point::new(2, 0))
    .set_blocked(Point::new(2, 1))
    .set_blocked(Point::new(2, 3))
    .set_blocked(Point::new(2, 4))
  let point_route = grid.bfs(Point::new(0, 2), Point::new(4, 2))
  let large_route = grid.find_path_for_agent(
    Point::new(0, 2),
    Point::new(4, 2),
    Algorithm::BFS,
    AgentProfile::new(1),
  )
  assert_true(point_route.found)
  assert_false(large_route.found)
}

///|
test "agent routing preserves weighted costs on safe cells" {
  let grid = GridMap::new(4, 1)
    .set_weight(Point::new(2, 0), 7)
    .set_weight(Point::new(3, 0), 4)
  let result = grid.find_path_for_agent(
    Point::new(1, 0),
    Point::new(3, 0),
    Algorithm::Dijkstra,
    AgentProfile::point(),
  )
  assert_true(result.found)
  assert_eq(result.cost, 11)
}

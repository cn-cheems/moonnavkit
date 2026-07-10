///|
test "line cells include endpoints" {
  let grid = GridMap::new(5, 5)
  let cells = grid.line_cells(Point::new(0, 0), Point::new(4, 2))
  assert_true(cells.length() >= 5)
  assert_true(cells[0] == Point::new(0, 0))
  assert_true(cells[cells.length() - 1] == Point::new(4, 2))
}

///|
test "line of sight rejects blocked cells" {
  let grid = GridMap::new(5, 1).set_blocked(Point::new(2, 0))
  assert_false(
    grid.has_line_of_sight(
      Point::new(0, 0),
      Point::new(4, 0),
      AgentProfile::point(),
    ),
  )
  assert_true(
    grid.has_line_of_sight(
      Point::new(0, 0),
      Point::new(1, 0),
      AgentProfile::point(),
    ),
  )
}

///|
test "line of sight rejects out of bounds endpoints" {
  let grid = GridMap::new(3, 3)
  assert_true(grid.line_cells(Point::new(-1, 0), Point::new(2, 0)) == [])
  assert_false(
    grid.has_line_of_sight(
      Point::new(-1, 0),
      Point::new(2, 0),
      AgentProfile::point(),
    ),
  )
}

///|
test "line of sight respects agent footprint" {
  let grid = GridMap::new(7, 5).set_blocked(Point::new(3, 1))
  assert_true(
    grid.has_line_of_sight(
      Point::new(1, 2),
      Point::new(5, 2),
      AgentProfile::point(),
    ),
  )
  assert_false(
    grid.has_line_of_sight(
      Point::new(1, 2),
      Point::new(5, 2),
      AgentProfile::new(1),
    ),
  )
}

///|
test "compress path removes redundant waypoints" {
  let grid = GridMap::new(6, 3)
  let path = [
    Point::new(0, 1),
    Point::new(1, 1),
    Point::new(2, 1),
    Point::new(3, 1),
    Point::new(4, 1),
    Point::new(5, 1),
  ]
  let compressed = grid.compress_path(path, AgentProfile::point())
  assert_true(compressed == [Point::new(0, 1), Point::new(5, 1)])
}

///|
test "compress path keeps waypoint around obstacle" {
  let grid = GridMap::new(5, 3).set_blocked(Point::new(2, 1))
  let result = grid.bfs(Point::new(0, 1), Point::new(4, 1))
  let compressed = result.compressed_path(grid, AgentProfile::point())
  assert_true(result.found)
  assert_true(compressed.length() < result.path.length())
  assert_true(compressed[0] == Point::new(0, 1))
  assert_true(compressed[compressed.length() - 1] == Point::new(4, 1))
  for i = 1; i < compressed.length(); i = i + 1 {
    assert_true(
      grid.has_line_of_sight(
        compressed[i - 1],
        compressed[i],
        AgentProfile::point(),
      ),
    )
  }
}

///|
test "path metrics replay a weighted route" {
  let grid = GridMap::new(4, 3)
    .set_weight(Point::new(1, 0), 5)
    .set_weight(Point::new(2, 1), 3)
  let path = [
    Point::new(0, 0),
    Point::new(1, 0),
    Point::new(1, 1),
    Point::new(2, 1),
    Point::new(3, 1),
  ]
  let metrics = grid.analyze_path(path)
  assert_true(metrics.valid)
  assert_eq(metrics.steps, 4)
  assert_eq(metrics.cost, 10)
  assert_eq(metrics.turns, 2)
  assert_true(metrics.invalid_at is None)
}

///|
test "path metrics reject jumps and blocked cells" {
  let grid = GridMap::new(3, 3).set_blocked(Point::new(1, 1))
  let jump = grid.analyze_path([Point::new(0, 0), Point::new(2, 0)])
  let blocked = grid.analyze_path([Point::new(0, 1), Point::new(1, 1)])
  assert_false(jump.valid)
  assert_eq(jump.cost, -1)
  assert_true(jump.invalid_at == Some(Point::new(2, 0)))
  assert_false(blocked.valid)
  assert_true(blocked.invalid_at == Some(Point::new(1, 1)))
}

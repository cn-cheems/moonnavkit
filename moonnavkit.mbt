///|
/// A grid coordinate used by all path planning APIs.
pub(all) struct Point {
  x : Int
  y : Int
} derive(Eq, Debug)

///|
pub fn Point::new(x : Int, y : Int) -> Point {
  { x, y }
}

///|
pub fn Point::manhattan(self : Point, other : Point) -> Int {
  abs_int(self.x - other.x) + abs_int(self.y - other.y)
}

///|
pub(all) enum Heuristic {
  Manhattan
  Euclidean
  Octile
} derive(Eq, Debug)

///|
pub(all) enum Algorithm {
  BFS
  Dijkstra
  AStar(Heuristic)
} derive(Eq, Debug)

///|
/// Result returned by path planning algorithms.
pub(all) struct PathResult {
  found : Bool
  path : Array[Point]
  cost : Int
  visited_count : Int
} derive(Eq, Debug)

///|
pub fn PathResult::not_found(visited_count : Int) -> PathResult {
  { found: false, path: [], cost: -1, visited_count }
}

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn isqrt(value : Int) -> Int {
  if value <= 0 {
    return 0
  }
  let mut root = 0
  while (root + 1) * (root + 1) <= value {
    root = root + 1
  }
  root
}

///|
pub fn Heuristic::estimate(self : Heuristic, from : Point, to : Point) -> Int {
  let dx = abs_int(from.x - to.x)
  let dy = abs_int(from.y - to.y)
  match self {
    Manhattan => dx + dy
    Euclidean => isqrt(dx * dx + dy * dy)
    Octile => max_int(dx, dy) + min_int(dx, dy) * 4 / 10
  }
}

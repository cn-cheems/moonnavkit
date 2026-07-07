///|
/// Summary returned when a route is replayed against a grid.
pub(all) struct PathMetrics {
  valid : Bool
  steps : Int
  cost : Int
  turns : Int
  invalid_at : Point?
} derive(Eq, Debug)

///|
fn PathMetrics::invalid(point : Point?) -> PathMetrics {
  { valid: false, steps: 0, cost: -1, turns: 0, invalid_at: point }
}

///|
/// Replays a path against the current grid and returns deterministic metrics.
///
/// The cost model matches `GridMap::dijkstra`: entering each next cell adds
/// that cell's positive weight, while the start cell itself has zero entry cost.
pub fn GridMap::analyze_path(
  self : GridMap,
  path : Array[Point],
) -> PathMetrics {
  guard path.length() > 0 else { return PathMetrics::invalid(None) }
  guard self.cost_at(path[0]) is Some(_) else {
    return PathMetrics::invalid(Some(path[0]))
  }

  let mut cost = 0
  let mut turns = 0
  for i = 1; i < path.length(); i = i + 1 {
    let prev = path[i - 1]
    let current = path[i]
    if !is_adjacent4(prev, current) {
      return PathMetrics::invalid(Some(current))
    }
    match self.cost_at(current) {
      Some(weight) => cost = cost + weight
      None => return PathMetrics::invalid(Some(current))
    }
    if i >= 2 && !same_direction(path[i - 2], prev, current) {
      turns = turns + 1
    }
  }
  { valid: true, steps: path.length() - 1, cost, turns, invalid_at: None }
}

///|
fn is_adjacent4(a : Point, b : Point) -> Bool {
  a.manhattan(b) == 1
}

///|
fn same_direction(a : Point, b : Point, c : Point) -> Bool {
  b.x - a.x == c.x - b.x && b.y - a.y == c.y - b.y
}

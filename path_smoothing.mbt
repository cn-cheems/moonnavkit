///|
fn sign_int(value : Int) -> Int {
  if value < 0 {
    -1
  } else if value > 0 {
    1
  } else {
    0
  }
}

///|
/// Returns the deterministic grid cells touched by a straight segment.
///
/// The result includes both endpoints and is useful for validation, debug
/// visualizations, and path post-processing.
pub fn GridMap::line_cells(
  self : GridMap,
  from : Point,
  to : Point,
) -> Array[Point] {
  guard self.contains(from) && self.contains(to) else { return [] }
  let cells : Array[Point] = []
  let mut x = from.x
  let mut y = from.y
  let dx = abs_int(to.x - from.x)
  let dy = -abs_int(to.y - from.y)
  let sx = sign_int(to.x - from.x)
  let sy = sign_int(to.y - from.y)
  let mut err = dx + dy
  let mut done = false

  while !done {
    cells.push(Point::new(x, y))
    if x == to.x && y == to.y {
      done = true
    } else {
      let e2 = err * 2
      if e2 >= dy {
        err = err + dy
        x = x + sx
      }
      if e2 <= dx {
        err = err + dx
        y = y + sy
      }
    }
  }
  cells
}

///|
/// Checks whether an agent can move between two waypoints without hitting
/// blocked cells or insufficient-clearance cells.
pub fn GridMap::has_line_of_sight(
  self : GridMap,
  from : Point,
  to : Point,
  agent : AgentProfile,
) -> Bool {
  let cells = self.line_cells(from, to)
  if cells.length() == 0 {
    return false
  }
  for i = 0; i < cells.length(); i = i + 1 {
    if !self.can_stand_at(cells[i], agent) {
      return false
    }
  }
  true
}

///|
/// Greedily compresses a grid path into executable waypoints.
///
/// The input path is usually produced by BFS, Dijkstra, A*, or a flow field.
/// The output keeps the same start and goal while removing intermediate points
/// whenever the agent has direct line-of-sight between remaining waypoints.
pub fn GridMap::compress_path(
  self : GridMap,
  path : Array[Point],
  agent : AgentProfile,
) -> Array[Point] {
  if path.length() <= 2 {
    return path
  }
  let waypoints : Array[Point] = [path[0]]
  let mut anchor = 0
  while anchor < path.length() - 1 {
    let mut best = anchor + 1
    let mut probe = anchor + 1
    while probe < path.length() &&
          self.has_line_of_sight(path[anchor], path[probe], agent) {
      best = probe
      probe = probe + 1
    }
    waypoints.push(path[best])
    anchor = best
  }
  waypoints
}

///|
/// Compresses a successful `PathResult` without changing its search statistics.
///
/// This is deliberately separated from search: algorithms remain optimal over
/// grid movement, while downstream consumers can request a smaller waypoint
/// route for rendering or steering.
pub fn PathResult::compressed_path(
  self : PathResult,
  grid : GridMap,
  agent : AgentProfile,
) -> Array[Point] {
  if self.found {
    grid.compress_path(self.path, agent)
  } else {
    []
  }
}

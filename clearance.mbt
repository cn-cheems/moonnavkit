///|
/// Agent footprint measured in grid cells.
///
/// A radius of 0 means point-agent routing. A radius of 1 requires the 3x3
/// area around the center cell to be traversable.
pub(all) struct AgentProfile {
  radius_cells : Int
} derive(Eq, Debug)

///|
pub fn AgentProfile::new(radius_cells : Int) -> AgentProfile {
  { radius_cells: max_int(0, radius_cells) }
}

///|
pub fn AgentProfile::point() -> AgentProfile {
  AgentProfile::new(0)
}

///|
/// Per-cell clearance radius. A cell with radius 2 can host an agent whose
/// square footprint extends two cells in each direction.
pub(all) struct ClearanceMap {
  width : Int
  height : Int
  radii : Array[Int]
} derive(Eq, Debug)

///|
fn ClearanceMap::index(self : ClearanceMap, point : Point) -> Int? {
  if point.x >= 0 &&
    point.y >= 0 &&
    point.x < self.width &&
    point.y < self.height {
    Some(point.y * self.width + point.x)
  } else {
    None
  }
}

///|
pub fn ClearanceMap::radius_at(self : ClearanceMap, point : Point) -> Int? {
  match self.index(point) {
    Some(index) => Some(self.radii[index])
    None => None
  }
}

///|
pub fn ClearanceMap::can_host(
  self : ClearanceMap,
  point : Point,
  agent : AgentProfile,
) -> Bool {
  match self.radius_at(point) {
    Some(radius) => radius >= agent.radius_cells
    None => false
  }
}

///|
fn GridMap::footprint_is_open(
  self : GridMap,
  center : Point,
  radius : Int,
) -> Bool {
  for y = center.y - radius; y <= center.y + radius; y = y + 1 {
    for x = center.x - radius; x <= center.x + radius; x = x + 1 {
      if self.cost_at(Point::new(x, y)) is None {
        return false
      }
    }
  }
  true
}

///|
/// Returns whether an agent can occupy a cell with its full footprint.
pub fn GridMap::can_stand_at(
  self : GridMap,
  point : Point,
  agent : AgentProfile,
) -> Bool {
  self.footprint_is_open(point, agent.radius_cells)
}

///|
fn GridMap::clearance_radius_at(
  self : GridMap,
  point : Point,
  max_radius : Int,
) -> Int {
  if self.cost_at(point) is None {
    return -1
  }
  let mut radius = 0
  while radius < max_radius && self.footprint_is_open(point, radius + 1) {
    radius = radius + 1
  }
  radius
}

///|
/// Computes the maximum square footprint radius supported by every grid cell.
pub fn GridMap::clearance_map(self : GridMap, max_radius : Int) -> ClearanceMap {
  let limit = max_int(0, max_radius)
  let radii = Array::make(self.cell_count(), -1)
  for index = 0; index < self.cell_count(); index = index + 1 {
    let point = self.point_at(index)
    radii[index] = self.clearance_radius_at(point, limit)
  }
  { width: self.width, height: self.height, radii }
}

///|
/// Builds a derived grid where cells too narrow for the agent are blocked.
///
/// Original positive weights are preserved for cells that can host the agent.
pub fn GridMap::inflate_blocked(
  self : GridMap,
  agent : AgentProfile,
) -> GridMap {
  let inflated = GridMap::new(self.width, self.height)
  for index = 0; index < self.cell_count(); index = index + 1 {
    let point = self.point_at(index)
    match self.cost_at(point) {
      Some(weight) =>
        if self.can_stand_at(point, agent) {
          inflated.set_weight(point, weight) |> ignore
        } else {
          inflated.set_blocked(point) |> ignore
        }
      None => inflated.set_blocked(point) |> ignore
    }
  }
  inflated
}

///|
/// Runs an existing grid algorithm after applying the agent footprint.
pub fn GridMap::find_path_for_agent(
  self : GridMap,
  start : Point,
  goal : Point,
  algorithm : Algorithm,
  agent : AgentProfile,
) -> PathResult {
  let inflated = self.inflate_blocked(agent)
  inflated.find_path(start, goal, algorithm)
}

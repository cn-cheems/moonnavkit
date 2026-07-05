///|
/// A reusable weighted routing field built from one or more destinations.
///
/// Building the field runs one reverse Dijkstra search. Each later path query
/// follows precomputed next steps and does not repeat graph search.
pub(all) struct FlowField {
  width : Int
  height : Int
  goals : Array[Point]
  costs : Array[Int]
  next : Array[Int]
  target : Array[Int]
  reachable_cells : Int
  build_visited_count : Int
} derive(Debug)

///|
/// Builds a deterministic multi-goal flow field over four-way grid movement.
///
/// Invalid, blocked, and duplicate goals are ignored. Cell-entry costs use the
/// same semantics as `GridMap::dijkstra`.
pub fn GridMap::flow_field(self : GridMap, goals : Array[Point]) -> FlowField {
  let total = self.cell_count()
  let accepted_goals : Array[Point] = []
  let costs = Array::make(total, unreachable_cost)
  let next = Array::make(total, -1)
  let target = Array::make(total, -1)
  let closed = Array::make(total, false)
  let open = MinPriorityQueue::new()

  for i = 0; i < goals.length(); i = i + 1 {
    let goal = goals[i]
    if self.contains(goal) && !self.is_blocked(goal) {
      let index = self.index(goal).unwrap()
      if costs[index] == unreachable_cost {
        let goal_index = accepted_goals.length()
        accepted_goals.push(goal)
        costs[index] = 0
        target[index] = goal_index
        open.push(index, 0)
      }
    }
  }

  let mut visited_count = 0
  while !open.is_empty() {
    let entry = open.pop().unwrap()
    let current = entry.item
    if !closed[current] && entry.priority == costs[current] {
      closed[current] = true
      visited_count = visited_count + 1
      let current_point = self.point_at(current)
      let enter_current_cost = self.cost_at(current_point).unwrap()
      let predecessors = self.neighbors4(current_point)
      for i = 0; i < predecessors.length(); i = i + 1 {
        let predecessor = self.index(predecessors[i]).unwrap()
        let candidate = costs[current] + enter_current_cost
        if !closed[predecessor] && candidate < costs[predecessor] {
          costs[predecessor] = candidate
          next[predecessor] = current
          target[predecessor] = target[current]
          open.push(predecessor, candidate)
        }
      }
    }
  }

  {
    width: self.width,
    height: self.height,
    goals: accepted_goals,
    costs,
    next,
    target,
    reachable_cells: visited_count,
    build_visited_count: visited_count,
  }
}

///|
fn FlowField::index(self : FlowField, point : Point) -> Int? {
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
fn FlowField::point_at(self : FlowField, index : Int) -> Point {
  Point::new(index % self.width, index / self.width)
}

///|
/// Returns the optimal remaining movement cost, or `None` when unreachable.
pub fn FlowField::cost_from(self : FlowField, start : Point) -> Int? {
  match self.index(start) {
    Some(index) =>
      if self.costs[index] < unreachable_cost {
        Some(self.costs[index])
      } else {
        None
      }
    None => None
  }
}

///|
/// Returns the next cell on an optimal route. Goals have no next step.
pub fn FlowField::next_step(self : FlowField, start : Point) -> Point? {
  match self.index(start) {
    Some(index) =>
      if self.next[index] >= 0 {
        Some(self.point_at(self.next[index]))
      } else {
        None
      }
    None => None
  }
}

///|
/// Returns the destination selected for a reachable cell.
pub fn FlowField::goal_for(self : FlowField, start : Point) -> Point? {
  match self.index(start) {
    Some(index) => {
      let selected = self.target[index]
      if selected >= 0 && selected < self.goals.length() {
        Some(self.goals[selected])
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// Reconstructs a route by following the field, in O(path length).
pub fn FlowField::path_from(self : FlowField, start : Point) -> PathResult {
  guard self.cost_from(start) is Some(cost) else {
    return PathResult::not_found(0)
  }
  let path : Array[Point] = [start]
  let trace = SearchTrace::new()
  let mut current = self.index(start).unwrap()
  let mut order = 0
  trace.push_step(order, start, self.costs[current], self.costs[current])
  while self.next[current] >= 0 && order < self.costs.length() {
    current = self.next[current]
    order = order + 1
    let point = self.point_at(current)
    path.push(point)
    trace.push_step(order, point, self.costs[current], self.costs[current])
  }
  {
    found: self.target[current] >= 0,
    path,
    cost,
    visited_count: path.length(),
    trace,
  }
}

///|
/// Exports compact metadata plus the cost raster for diagnostics and tooling.
pub fn FlowField::to_json(self : FlowField) -> String {
  let buf = StringBuilder(size_hint=128 + self.costs.length() * 8)
  buf.write_string(
    "{\"width\":\{self.width},\"height\":\{self.height},\"reachable_cells\":\{self.reachable_cells},\"build_visited_count\":\{self.build_visited_count},\"goals\":",
  )
  write_points_json(buf, self.goals)
  buf.write_string(",\"costs\":[")
  for i = 0; i < self.costs.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(",")
    }
    if self.costs[i] < unreachable_cost {
      buf.write_string(self.costs[i].to_string())
    } else {
      buf.write_string("null")
    }
  }
  buf.write_string("]}")
  buf.to_string()
}

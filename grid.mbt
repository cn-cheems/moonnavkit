///|
let unreachable_cost = 1_000_000_000

///|
/// A rectangular weighted grid. A cell cost below zero means blocked.
pub(all) struct GridMap {
  width : Int
  height : Int
  weights : Array[Int]
} derive(Eq, Debug)

///|
pub fn GridMap::new(width : Int, height : Int) -> GridMap {
  guard width > 0 && height > 0 else {
    return { width: 0, height: 0, weights: [] }
  }
  { width, height, weights: Array::make(width * height, 1) }
}

///|
pub fn GridMap::cell_count(self : GridMap) -> Int {
  self.width * self.height
}

///|
pub fn GridMap::contains(self : GridMap, point : Point) -> Bool {
  point.x >= 0 && point.y >= 0 && point.x < self.width && point.y < self.height
}

///|
pub fn GridMap::index(self : GridMap, point : Point) -> Int? {
  if self.contains(point) {
    Some(point.y * self.width + point.x)
  } else {
    None
  }
}

///|
pub fn GridMap::point_at(self : GridMap, index : Int) -> Point {
  Point::new(index % self.width, index / self.width)
}

///|
pub fn GridMap::set_blocked(self : GridMap, point : Point) -> GridMap {
  match self.index(point) {
    Some(index) => self.weights[index] = -1
    None => ()
  }
  self
}

///|
pub fn GridMap::set_weight(
  self : GridMap,
  point : Point,
  weight : Int,
) -> GridMap {
  match self.index(point) {
    Some(index) => if weight > 0 { self.weights[index] = weight }
    None => ()
  }
  self
}

///|
pub fn GridMap::is_blocked(self : GridMap, point : Point) -> Bool {
  match self.index(point) {
    Some(index) => self.weights[index] < 0
    None => true
  }
}

///|
pub fn GridMap::cost_at(self : GridMap, point : Point) -> Int? {
  match self.index(point) {
    Some(index) =>
      if self.weights[index] > 0 {
        Some(self.weights[index])
      } else {
        None
      }
    None => None
  }
}

///|
pub fn GridMap::neighbors4(self : GridMap, point : Point) -> Array[Point] {
  let result : Array[Point] = []
  let candidates = [
    Point::new(point.x + 1, point.y),
    Point::new(point.x - 1, point.y),
    Point::new(point.x, point.y + 1),
    Point::new(point.x, point.y - 1),
  ]
  for i = 0; i < candidates.length(); i = i + 1 {
    let next = candidates[i]
    if self.contains(next) && !self.is_blocked(next) {
      result.push(next)
    }
  }
  result
}

///|
pub fn GridMap::find_path(
  self : GridMap,
  start : Point,
  goal : Point,
  algorithm : Algorithm,
) -> PathResult {
  match algorithm {
    BFS => self.bfs(start, goal)
    Dijkstra => self.dijkstra(start, goal)
    AStar(heuristic) => self.astar(start, goal, heuristic)
  }
}

///|
pub fn GridMap::bfs(self : GridMap, start : Point, goal : Point) -> PathResult {
  self.search(start, goal, BFS)
}

///|
pub fn GridMap::dijkstra(
  self : GridMap,
  start : Point,
  goal : Point,
) -> PathResult {
  self.search(start, goal, Dijkstra)
}

///|
pub fn GridMap::astar(
  self : GridMap,
  start : Point,
  goal : Point,
  heuristic : Heuristic,
) -> PathResult {
  self.search(start, goal, AStar(heuristic))
}

///|
fn GridMap::search(
  self : GridMap,
  start : Point,
  goal : Point,
  algorithm : Algorithm,
) -> PathResult {
  guard self.contains(start) && self.contains(goal) else {
    return PathResult::not_found(0)
  }
  guard !self.is_blocked(start) && !self.is_blocked(goal) else {
    return PathResult::not_found(0)
  }
  let total = self.cell_count()
  let start_index = self.index(start).unwrap()
  let goal_index = self.index(goal).unwrap()
  let dist = Array::make(total, unreachable_cost)
  let parent = Array::make(total, -1)
  let closed = Array::make(total, false)
  let trace = SearchTrace::new()
  let open = MinPriorityQueue::new()
  dist[start_index] = 0
  open.push(start_index, self.score_for(start_index, dist, goal, algorithm))
  let mut visited_count = 0

  for _step = 0; _step < total; _step = _step + 1 {
    let current = self.take_next_open(open, dist, closed, goal, algorithm)
    if current == -1 {
      break
    }
    let current_point = self.point_at(current)
    trace.push_step(
      visited_count,
      current_point,
      dist[current],
      self.score_for(current, dist, goal, algorithm),
    )
    visited_count = visited_count + 1
    if current == goal_index {
      break
    }
    closed[current] = true
    self.relax_grid_neighbor(
      current,
      Point::new(current_point.x + 1, current_point.y),
      dist,
      parent,
      closed,
      open,
      goal,
      algorithm,
    )
    self.relax_grid_neighbor(
      current,
      Point::new(current_point.x - 1, current_point.y),
      dist,
      parent,
      closed,
      open,
      goal,
      algorithm,
    )
    self.relax_grid_neighbor(
      current,
      Point::new(current_point.x, current_point.y + 1),
      dist,
      parent,
      closed,
      open,
      goal,
      algorithm,
    )
    self.relax_grid_neighbor(
      current,
      Point::new(current_point.x, current_point.y - 1),
      dist,
      parent,
      closed,
      open,
      goal,
      algorithm,
    )
  }

  if start_index == goal_index {
    return { found: true, path: [start], cost: 0, visited_count, trace }
  }
  if parent[goal_index] == -1 {
    return { found: false, path: [], cost: -1, visited_count, trace }
  }
  {
    found: true,
    path: self.reconstruct_path(parent, goal_index),
    cost: dist[goal_index],
    visited_count,
    trace,
  }
}

///|
fn GridMap::relax_grid_neighbor(
  self : GridMap,
  current : Int,
  next : Point,
  dist : Array[Int],
  parent : Array[Int],
  closed : Array[Bool],
  open : MinPriorityQueue,
  goal : Point,
  algorithm : Algorithm,
) -> Unit {
  match self.index(next) {
    Some(next_index) =>
      if !closed[next_index] {
        match self.cost_at(next) {
          Some(weight) => {
            let step_cost = match algorithm {
              BFS => 1
              Dijkstra => weight
              AStar(_) => weight
            }
            let candidate = dist[current] + step_cost
            if candidate < dist[next_index] {
              dist[next_index] = candidate
              parent[next_index] = current
              open.push(
                next_index,
                self.score_for(next_index, dist, goal, algorithm),
              )
            }
          }
          None => ()
        }
      }
    None => ()
  }
}

///|
fn GridMap::take_next_open(
  self : GridMap,
  open : MinPriorityQueue,
  dist : Array[Int],
  closed : Array[Bool],
  goal : Point,
  algorithm : Algorithm,
) -> Int {
  let mut selected = -1
  let mut done = false
  while !done {
    match open.pop() {
      None => done = true
      Some(entry) =>
        if !closed[entry.item] &&
          entry.priority == self.score_for(entry.item, dist, goal, algorithm) {
          selected = entry.item
          done = true
        }
    }
  }
  selected
}

///|
fn GridMap::score_for(
  self : GridMap,
  index : Int,
  dist : Array[Int],
  goal : Point,
  algorithm : Algorithm,
) -> Int {
  let point = self.point_at(index)
  match algorithm {
    AStar(heuristic) => dist[index] + heuristic.estimate(point, goal)
    _ => dist[index]
  }
}

///|
fn GridMap::reconstruct_path(
  self : GridMap,
  parent : Array[Int],
  goal_index : Int,
) -> Array[Point] {
  let reversed : Array[Point] = []
  let mut current = goal_index
  while current != -1 {
    reversed.push(self.point_at(current))
    current = parent[current]
  }
  reversed.rev()
}

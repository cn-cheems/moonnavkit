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
  point.x >= 0 &&
  point.y >= 0 &&
  point.x < self.width &&
  point.y < self.height
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
pub fn GridMap::set_weight(self : GridMap, point : Point, weight : Int) -> GridMap {
  match self.index(point) {
    Some(index) =>
      if weight > 0 {
        self.weights[index] = weight
      }
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
  algorithm : Algorithm
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
pub fn GridMap::dijkstra(self : GridMap, start : Point, goal : Point) -> PathResult {
  self.search(start, goal, Dijkstra)
}

///|
pub fn GridMap::astar(
  self : GridMap,
  start : Point,
  goal : Point,
  heuristic : Heuristic
) -> PathResult {
  self.search(start, goal, AStar(heuristic))
}

///|
fn GridMap::search(
  self : GridMap,
  start : Point,
  goal : Point,
  algorithm : Algorithm
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
  dist[start_index] = 0
  let mut visited_count = 0

  for _step = 0; _step < total; _step = _step + 1 {
    let current = self.select_next(dist, closed, goal, algorithm)
    if current == -1 {
      break
    }
    if current == goal_index {
      break
    }
    closed[current] = true
    visited_count = visited_count + 1
    let current_point = self.point_at(current)
    let neighbors = self.neighbors4(current_point)
    for i = 0; i < neighbors.length(); i = i + 1 {
      let next = neighbors[i]
      let next_index = self.index(next).unwrap()
      if !closed[next_index] {
        let step_cost = match algorithm {
          BFS => 1
          Dijkstra => self.cost_at(next).unwrap()
          AStar(_) => self.cost_at(next).unwrap()
        }
        let candidate = dist[current] + step_cost
        if candidate < dist[next_index] {
          dist[next_index] = candidate
          parent[next_index] = current
        }
      }
    }
  }

  if start_index == goal_index {
    return { found: true, path: [start], cost: 0, visited_count: 1 }
  }
  if parent[goal_index] == -1 {
    return PathResult::not_found(visited_count)
  }
  {
    found: true,
    path: self.reconstruct_path(parent, goal_index),
    cost: dist[goal_index],
    visited_count,
  }
}

///|
fn GridMap::select_next(
  self : GridMap,
  dist : Array[Int],
  closed : Array[Bool],
  goal : Point,
  algorithm : Algorithm
) -> Int {
  let mut best = -1
  let mut best_score = unreachable_cost
  for i = 0; i < dist.length(); i = i + 1 {
    if !closed[i] && dist[i] < unreachable_cost {
      let point = self.point_at(i)
      let score = match algorithm {
        AStar(heuristic) => dist[i] + heuristic.estimate(point, goal)
        _ => dist[i]
      }
      if score < best_score {
        best = i
        best_score = score
      }
    }
  }
  best
}

///|
fn GridMap::reconstruct_path(
  self : GridMap,
  parent : Array[Int],
  goal_index : Int
) -> Array[Point] {
  let reversed : Array[Point] = []
  let mut current = goal_index
  while current != -1 {
    reversed.push(self.point_at(current))
    current = parent[current]
  }
  reversed.rev()
}

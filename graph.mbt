///|
/// A graph node with an integer id and a position for heuristic search/export.
pub(all) struct GraphNode {
  id : Int
  position : Point
} derive(Eq, Debug)

///|
/// A weighted directed graph edge. All search algorithms require positive weight.
pub(all) struct GraphEdge {
  from : Int
  to : Int
  weight : Int
} derive(Eq, Debug)

///|
/// A small mutable weighted graph optimized for clear APIs and deterministic tests.
pub(all) struct Graph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
} derive(Eq, Debug)

///|
pub fn Graph::new() -> Graph {
  { nodes: [], edges: [] }
}

///|
pub fn Graph::node_count(self : Graph) -> Int {
  self.nodes.length()
}

///|
pub fn Graph::edge_count(self : Graph) -> Int {
  self.edges.length()
}

///|
pub fn Graph::add_node(self : Graph, position : Point) -> Int {
  let id = self.nodes.length()
  self.nodes.push({ id, position })
  id
}

///|
pub fn Graph::is_valid_node(self : Graph, node : Int) -> Bool {
  node >= 0 && node < self.nodes.length()
}

///|
pub fn Graph::position(self : Graph, node : Int) -> Point? {
  if self.is_valid_node(node) {
    Some(self.nodes[node].position)
  } else {
    None
  }
}

///|
pub fn Graph::add_directed_edge(
  self : Graph,
  from : Int,
  to : Int,
  weight : Int
) -> Graph {
  if self.is_valid_node(from) && self.is_valid_node(to) && weight > 0 {
    self.edges.push({ from, to, weight })
  }
  self
}

///|
pub fn Graph::add_undirected_edge(
  self : Graph,
  a : Int,
  b : Int,
  weight : Int
) -> Graph {
  ignore(self.add_directed_edge(a, b, weight))
  ignore(self.add_directed_edge(b, a, weight))
  self
}

///|
pub fn Graph::neighbors(self : Graph, node : Int) -> Array[GraphEdge] {
  let result : Array[GraphEdge] = []
  for i = 0; i < self.edges.length(); i = i + 1 {
    if self.edges[i].from == node {
      result.push(self.edges[i])
    }
  }
  result
}

///|
pub(all) struct GraphPathResult {
  found : Bool
  nodes : Array[Int]
  points : Array[Point]
  cost : Int
  visited_count : Int
  trace : SearchTrace
} derive(Eq, Debug)

///|
pub fn GraphPathResult::not_found(visited_count : Int) -> GraphPathResult {
  {
    found: false,
    nodes: [],
    points: [],
    cost: -1,
    visited_count,
    trace: SearchTrace::new(),
  }
}

///|
pub fn Graph::find_path(
  self : Graph,
  start : Int,
  goal : Int,
  algorithm : Algorithm
) -> GraphPathResult {
  match algorithm {
    BFS => self.bfs(start, goal)
    Dijkstra => self.dijkstra(start, goal)
    AStar(heuristic) => self.astar(start, goal, heuristic)
  }
}

///|
pub fn Graph::bfs(self : Graph, start : Int, goal : Int) -> GraphPathResult {
  self.search(start, goal, BFS)
}

///|
pub fn Graph::dijkstra(self : Graph, start : Int, goal : Int) -> GraphPathResult {
  self.search(start, goal, Dijkstra)
}

///|
pub fn Graph::astar(
  self : Graph,
  start : Int,
  goal : Int,
  heuristic : Heuristic
) -> GraphPathResult {
  self.search(start, goal, AStar(heuristic))
}

///|
fn Graph::search(
  self : Graph,
  start : Int,
  goal : Int,
  algorithm : Algorithm
) -> GraphPathResult {
  guard self.is_valid_node(start) && self.is_valid_node(goal) else {
    return GraphPathResult::not_found(0)
  }
  let total = self.node_count()
  let dist = Array::make(total, unreachable_cost)
  let parent = Array::make(total, -1)
  let closed = Array::make(total, false)
  let trace = SearchTrace::new()
  dist[start] = 0
  let mut visited_count = 0

  for _step = 0; _step < total; _step = _step + 1 {
    let current = self.select_next(dist, closed, goal, algorithm)
    if current == -1 {
      break
    }
    let current_point = self.nodes[current].position
    trace.push_step(
      visited_count,
      current_point,
      dist[current],
      self.score_for(current, dist, goal, algorithm),
    )
    visited_count = visited_count + 1
    if current == goal {
      break
    }
    closed[current] = true
    let edges = self.neighbors(current)
    for i = 0; i < edges.length(); i = i + 1 {
      let edge = edges[i]
      if !closed[edge.to] {
        let step_cost = match algorithm {
          BFS => 1
          _ => edge.weight
        }
        let candidate = dist[current] + step_cost
        if candidate < dist[edge.to] {
          dist[edge.to] = candidate
          parent[edge.to] = current
        }
      }
    }
  }

  if start == goal {
    return {
      found: true,
      nodes: [start],
      points: [self.nodes[start].position],
      cost: 0,
      visited_count,
      trace,
    }
  }
  if parent[goal] == -1 {
    return { found: false, nodes: [], points: [], cost: -1, visited_count, trace }
  }
  let nodes = reconstruct_nodes(parent, goal)
  {
    found: true,
    points: self.nodes_to_points(nodes),
    nodes,
    cost: dist[goal],
    visited_count,
    trace,
  }
}

///|
fn Graph::select_next(
  self : Graph,
  dist : Array[Int],
  closed : Array[Bool],
  goal : Int,
  algorithm : Algorithm
) -> Int {
  let mut best = -1
  let mut best_score = unreachable_cost
  for i = 0; i < dist.length(); i = i + 1 {
    if !closed[i] && dist[i] < unreachable_cost {
      let score = self.score_for(i, dist, goal, algorithm)
      if score < best_score {
        best = i
        best_score = score
      }
    }
  }
  best
}

///|
fn Graph::score_for(
  self : Graph,
  node : Int,
  dist : Array[Int],
  goal : Int,
  algorithm : Algorithm
) -> Int {
  match algorithm {
    AStar(heuristic) =>
      dist[node] + heuristic.estimate(self.nodes[node].position, self.nodes[goal].position)
    _ => dist[node]
  }
}

///|
fn reconstruct_nodes(parent : Array[Int], goal : Int) -> Array[Int] {
  let reversed : Array[Int] = []
  let mut current = goal
  while current != -1 {
    reversed.push(current)
    current = parent[current]
  }
  reversed.rev()
}

///|
fn Graph::nodes_to_points(self : Graph, nodes : Array[Int]) -> Array[Point] {
  let points : Array[Point] = []
  for i = 0; i < nodes.length(); i = i + 1 {
    points.push(self.nodes[nodes[i]].position)
  }
  points
}

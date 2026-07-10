///|
/// Run with `moon run cmd/bench` from the project root.
fn main {
  println("scenario,algorithm,found,cost,visited,trace,path_length")
  run_open_grid()
  run_weighted_grid()
  run_dense_grid()
  run_graph_route()
  run_many_agent_flow()
  run_clearance_route()
}

///|
fn print_grid_result(
  scenario : String,
  algorithm : String,
  result : @nav.PathResult,
) -> Unit {
  println(
    "\{scenario},\{algorithm},\{result.found},\{result.cost},\{result.visited_count},\{result.trace.length()},\{result.path.length()}",
  )
}

///|
fn print_graph_result(
  scenario : String,
  algorithm : String,
  result : @nav.GraphPathResult,
) -> Unit {
  println(
    "\{scenario},\{algorithm},\{result.found},\{result.cost},\{result.visited_count},\{result.trace.length()},\{result.nodes.length()}",
  )
}

///|
fn run_open_grid() -> Unit {
  let start = @nav.Point::new(0, 0)
  let goal = @nav.Point::new(15, 15)
  let grid = @nav.GridMap::new(16, 16)
  print_grid_result("open-16x16", "bfs", grid.bfs(start, goal))
  print_grid_result("open-16x16", "dijkstra", grid.dijkstra(start, goal))
  print_grid_result(
    "open-16x16",
    "astar-manhattan",
    grid.astar(start, goal, @nav.Heuristic::Manhattan),
  )
}

///|
fn run_weighted_grid() -> Unit {
  let start = @nav.Point::new(0, 0)
  let goal = @nav.Point::new(31, 31)
  let config = @nav.RandomGridConfig::new(32, 32, 404)
    .with_blocked_percent(5)
    .with_weighted_percent(60)
    .with_max_weight(9)
  let grid = @nav.GridMap::random_with_clear_points(config, [start, goal])
  print_grid_result(
    "weighted-32x32-seed404",
    "dijkstra",
    grid.dijkstra(start, goal),
  )
  print_grid_result(
    "weighted-32x32-seed404",
    "astar-manhattan",
    grid.astar(start, goal, @nav.Heuristic::Manhattan),
  )
}

///|
fn run_dense_grid() -> Unit {
  let start = @nav.Point::new(0, 0)
  let goal = @nav.Point::new(39, 39)
  let config = @nav.RandomGridConfig::new(40, 40, 303)
    .with_blocked_percent(35)
    .with_weighted_percent(15)
    .with_max_weight(8)
  let grid = @nav.GridMap::random_with_clear_points(config, [start, goal])
  print_grid_result(
    "dense-40x40-seed303",
    "astar-manhattan",
    grid.astar(start, goal, @nav.Heuristic::Manhattan),
  )
}

///|
fn run_graph_route() -> Unit {
  let graph = @nav.Graph::new()
  let a = graph.add_node(@nav.Point::new(0, 0))
  let b = graph.add_node(@nav.Point::new(1, 0))
  let c = graph.add_node(@nav.Point::new(2, 0))
  let d = graph.add_node(@nav.Point::new(3, 0))
  let e = graph.add_node(@nav.Point::new(4, 0))
  graph.add_directed_edge(a, b, 1) |> ignore
  graph.add_directed_edge(b, e, 9) |> ignore
  graph.add_directed_edge(a, c, 3) |> ignore
  graph.add_directed_edge(c, d, 2) |> ignore
  graph.add_directed_edge(d, e, 2) |> ignore
  graph.add_directed_edge(b, d, 5) |> ignore
  print_graph_result("graph-route-5", "dijkstra", graph.dijkstra(a, e))
  print_graph_result(
    "graph-route-5",
    "astar-manhattan",
    graph.astar(a, e, @nav.Heuristic::Manhattan),
  )
}

///|
/// Compares repeated shortest-path searches with one reusable flow-field build.
fn run_many_agent_flow() -> Unit {
  let goal = @nav.Point::new(31, 31)
  let config = @nav.RandomGridConfig::new(32, 32, 707)
    .with_blocked_percent(0)
    .with_weighted_percent(45)
    .with_max_weight(9)
  let grid = @nav.GridMap::random_with_clear_points(config, [goal])
  let starts : Array[@nav.Point] = []
  for y = 0; y < 32; y = y + 4 {
    for x = 0; x < 32; x = x + 4 {
      starts.push(@nav.Point::new(x, y))
    }
  }

  let mut repeated_visited = 0
  let mut repeated_cost = 0
  for i = 0; i < starts.length(); i = i + 1 {
    let result = grid.dijkstra(starts[i], goal)
    repeated_visited = repeated_visited + result.visited_count
    repeated_cost = repeated_cost + result.cost
  }

  let field = grid.flow_field([goal])
  let mut query_steps = 0
  let mut flow_cost = 0
  for i = 0; i < starts.length(); i = i + 1 {
    let result = field.path_from(starts[i])
    query_steps = query_steps + result.visited_count
    flow_cost = flow_cost + result.cost
  }
  println(
    "many-agent-32x32-seed707,repeated-dijkstra,true,\{repeated_cost},\{repeated_visited},0,\{starts.length()}",
  )
  println(
    "many-agent-32x32-seed707,flow-field-build+queries,true,\{flow_cost},\{field.build_visited_count},\{query_steps},\{starts.length()}",
  )
}

///|
/// Shows how footprint-aware routing rejects corridors that are too narrow.
fn run_clearance_route() -> Unit {
  let start = @nav.Point::new(1, 2)
  let goal = @nav.Point::new(5, 2)
  let grid = @nav.GridMap::new(7, 5)
    .set_blocked(@nav.Point::new(3, 0))
    .set_blocked(@nav.Point::new(3, 1))
    .set_blocked(@nav.Point::new(3, 3))
    .set_blocked(@nav.Point::new(3, 4))
  print_grid_result("clearance-door-7x5", "point-bfs", grid.bfs(start, goal))
  print_grid_result(
    "clearance-door-7x5",
    "radius1-bfs",
    grid.find_path_for_agent(
      start,
      goal,
      @nav.Algorithm::BFS,
      @nav.AgentProfile::new(1),
    ),
  )
}

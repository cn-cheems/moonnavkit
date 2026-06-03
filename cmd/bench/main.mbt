///|
/// Run with `moon run cmd/bench` from the project root.
fn main {
  println("scenario,algorithm,found,cost,visited,trace,path_length")
  run_open_grid()
  run_weighted_grid()
  run_dense_grid()
  run_graph_route()
}

///|
fn print_grid_result(
  scenario : String,
  algorithm : String,
  result : @nav.PathResult
) -> Unit {
  println(
    "\{scenario},\{algorithm},\{result.found},\{result.cost},\{result.visited_count},\{result.trace.length()},\{result.path.length()}",
  )
}

///|
fn print_graph_result(
  scenario : String,
  algorithm : String,
  result : @nav.GraphPathResult
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
  print_grid_result("weighted-32x32-seed404", "dijkstra", grid.dijkstra(start, goal))
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


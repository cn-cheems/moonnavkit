///|
/// Run with `moon run cmd/main` from the project root.
fn main {
  let grid = @nav.GridMap::new(5, 5)
    .set_blocked(@nav.Point::new(1, 0))
    .set_blocked(@nav.Point::new(1, 1))
    .set_weight(@nav.Point::new(3, 2), 5)
  let result = grid.astar(
    @nav.Point::new(0, 0),
    @nav.Point::new(4, 4),
    @nav.Heuristic::Manhattan,
  )
  println("MoonNavKit demo")
  println("found: \{result.found}")
  println("cost: \{result.cost}")
  println("path length: \{result.path.length()}")
  println("visited cells: \{result.visited_count}")
  println("trace steps: \{result.trace.length()}")
  println("json chars: \{result.to_json().length()}")
  println("svg chars: \{grid.to_svg(result, 24).length()}")
  println("html chars: \{grid.to_html(result, 24).length()}")

  let graph = @nav.Graph::new()
  let start = graph.add_node(@nav.Point::new(0, 0))
  let mid = graph.add_node(@nav.Point::new(1, 0))
  let goal = graph.add_node(@nav.Point::new(2, 0))
  graph.add_directed_edge(start, mid, 1) |> ignore
  graph.add_directed_edge(mid, goal, 1) |> ignore
  graph.add_directed_edge(start, goal, 5) |> ignore
  let graph_result = graph.astar(start, goal, @nav.Heuristic::Manhattan)
  println("graph found: \{graph_result.found}")
  println("graph cost: \{graph_result.cost}")
  println("graph node count: \{graph_result.nodes.length()}")
}

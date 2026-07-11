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

  let random_start = @nav.Point::new(0, 0)
  let random_goal = @nav.Point::new(7, 7)
  let config = @nav.RandomGridConfig::new(8, 8, 2026)
    .with_blocked_percent(5)
    .with_weighted_percent(35)
    .with_max_weight(8)
  let random_grid = @nav.GridMap::random_with_clear_points(config, [
    random_start, random_goal,
  ])
  let stats = random_grid.stats()
  let random_result = random_grid.astar(
    random_start,
    random_goal,
    @nav.Heuristic::Manhattan,
  )
  println("random grid cells: \{stats.cells}")
  println("random blocked cells: \{stats.blocked_cells}")
  println("random weighted cells: \{stats.weighted_cells}")
  println("random path found: \{random_result.found}")
  println("random visited cells: \{random_result.visited_count}")

  let dynamic_start = @nav.Point::new(0, 1)
  let dynamic_goal = @nav.Point::new(4, 1)
  let planner = @nav.DynamicGridPlanner::new(
    @nav.GridMap::new(5, 3),
    dynamic_start,
    dynamic_goal,
  )
  let initial_dynamic = planner.replan()
  planner.set_blocked(@nav.Point::new(2, 1)) |> ignore
  let repaired_dynamic = planner.replan()
  println("dynamic initial cost: \{initial_dynamic.cost}")
  println("dynamic repaired cost: \{repaired_dynamic.cost}")
  println(
    "dynamic repair expanded cells: \{planner.last_replan_expanded_count()}",
  )
}

///|
test "point manhattan distance" {
  assert_eq(Point::new(0, 0).manhattan(Point::new(3, 4)), 7)
}

///|
test "grid contains valid cells only" {
  let grid = GridMap::new(3, 2)
  assert_true(grid.contains(Point::new(0, 0)))
  assert_true(grid.contains(Point::new(2, 1)))
  assert_false(grid.contains(Point::new(3, 1)))
  assert_false(grid.contains(Point::new(1, 2)))
  assert_false(grid.contains(Point::new(-1, 0)))
}

///|
test "blocked cells are not returned as neighbors" {
  let grid = GridMap::new(3, 3).set_blocked(Point::new(1, 0))
  let neighbors = grid.neighbors4(Point::new(0, 0))
  assert_true(neighbors == [Point::new(0, 1)])
}

///|
test "bfs finds shortest step path on an open grid" {
  let result = GridMap::new(3, 3).bfs(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.cost, 2)
  assert_true(
    result.path == [Point::new(0, 0), Point::new(1, 0), Point::new(2, 0)],
  )
}

///|
test "bfs routes around blocked cells" {
  let grid = GridMap::new(3, 3).set_blocked(Point::new(1, 0))
  let result = grid.bfs(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.cost, 4)
  assert_true(
    result.path == [
      Point::new(0, 0),
      Point::new(0, 1),
      Point::new(1, 1),
      Point::new(2, 1),
      Point::new(2, 0),
    ],
  )
}

///|
test "search reports unreachable goal" {
  let grid = GridMap::new(3, 3)
    .set_blocked(Point::new(1, 0))
    .set_blocked(Point::new(1, 1))
    .set_blocked(Point::new(1, 2))
  let result = grid.bfs(Point::new(0, 0), Point::new(2, 0))
  assert_false(result.found)
  assert_true(result.path == [])
  assert_eq(result.cost, -1)
}

///|
test "dijkstra prefers cheaper weighted route" {
  let grid = GridMap::new(3, 2).set_weight(Point::new(1, 0), 9)
  let result = grid.dijkstra(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.cost, 4)
  assert_true(
    result.path == [
      Point::new(0, 0),
      Point::new(0, 1),
      Point::new(1, 1),
      Point::new(2, 1),
      Point::new(2, 0),
    ],
  )
}

///|
test "astar finds path with manhattan heuristic" {
  let grid = GridMap::new(5, 3)
    .set_blocked(Point::new(1, 0))
    .set_blocked(Point::new(1, 1))
  let result = grid.astar(Point::new(0, 0), Point::new(4, 0), Heuristic::Manhattan)
  assert_true(result.found)
  assert_eq(result.cost, 8)
  assert_true(result.path[0] == Point::new(0, 0))
  assert_true(result.path[result.path.length() - 1] == Point::new(4, 0))
}

///|
test "find_path dispatches algorithms" {
  let grid = GridMap::new(4, 4)
  let bfs = grid.find_path(Point::new(0, 0), Point::new(3, 0), Algorithm::BFS)
  let astar = grid.find_path(
    Point::new(0, 0),
    Point::new(3, 0),
    Algorithm::AStar(Heuristic::Manhattan),
  )
  assert_true(bfs.found)
  assert_true(astar.found)
  assert_eq(bfs.cost, 3)
  assert_eq(astar.cost, 3)
}

///|
test "search trace records expanded cells" {
  let result = GridMap::new(3, 1).bfs(Point::new(0, 0), Point::new(2, 0))
  assert_true(result.found)
  assert_eq(result.visited_count, 3)
  assert_eq(result.trace.length(), 3)
  assert_true(result.trace.steps[0].point == Point::new(0, 0))
  assert_true(result.trace.steps[2].point == Point::new(2, 0))
}

///|
test "trace json includes ordered steps" {
  let result = GridMap::new(2, 1).bfs(Point::new(0, 0), Point::new(1, 0))
  assert_eq(
    result.trace.to_json(),
    "{\"steps\":[{\"order\":0,\"point\":{\"x\":0,\"y\":0},\"cost\":0,\"score\":0},{\"order\":1,\"point\":{\"x\":1,\"y\":0},\"cost\":1,\"score\":1}]}",
  )
}

///|
test "path result exports json" {
  let result = GridMap::new(2, 1).bfs(Point::new(0, 0), Point::new(1, 0))
  assert_eq(
    result.to_json(),
    "{\"found\":true,\"cost\":1,\"visited_count\":2,\"path\":[{\"x\":0,\"y\":0},{\"x\":1,\"y\":0}],\"trace\":{\"steps\":[{\"order\":0,\"point\":{\"x\":0,\"y\":0},\"cost\":0,\"score\":0},{\"order\":1,\"point\":{\"x\":1,\"y\":0},\"cost\":1,\"score\":1}]}}",
  )
}

///|
test "svg export renders grid trace and path" {
  let grid = GridMap::new(2, 1)
  let result = grid.bfs(Point::new(0, 0), Point::new(1, 0))
  let svg = grid.to_svg(result, 20)
  assert_true(svg.contains("<svg xmlns=\"http://www.w3.org/2000/svg\""))
  assert_true(svg.contains("width=\"40\""))
  assert_true(svg.contains("height=\"20\""))
  assert_true(svg.contains("<polyline"))
  assert_true(svg.contains("stroke=\"#16a34a\""))
  assert_true(svg.contains("fill=\"#22c55e\""))
  assert_true(svg.contains("fill=\"#ef4444\""))
}

///|
test "svg export marks blocked and weighted cells" {
  let grid = GridMap::new(3, 1)
    .set_blocked(Point::new(1, 0))
    .set_weight(Point::new(2, 0), 7)
  let result = grid.bfs(Point::new(0, 0), Point::new(0, 0))
  let svg = grid.to_svg(result, 16)
  assert_true(svg.contains("fill=\"#111827\""))
  assert_true(svg.contains("fill=\"#fde68a\""))
  assert_true(svg.contains(">7</text>"))
}

///|
test "html export embeds svg and json payload" {
  let grid = GridMap::new(2, 1)
  let result = grid.bfs(Point::new(0, 0), Point::new(1, 0))
  let html = grid.to_html(result, 20)
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("<title>MoonNavKit Replay</title>"))
  assert_true(html.contains("<svg"))
  assert_true(html.contains("id=\"moonnavkit-data\""))
  assert_true(html.contains("\"found\":true"))
}

///|
test "graph adds nodes and weighted edges" {
  let graph = Graph::new()
  let a = graph.add_node(Point::new(0, 0))
  let b = graph.add_node(Point::new(1, 0))
  graph.add_undirected_edge(a, b, 3) |> ignore
  assert_eq(graph.node_count(), 2)
  assert_eq(graph.edge_count(), 2)
  assert_eq(graph.neighbors(a).length(), 1)
  assert_eq(graph.neighbors(a)[0].weight, 3)
}

///|
test "graph dijkstra prefers cheaper weighted path" {
  let graph = Graph::new()
  let a = graph.add_node(Point::new(0, 0))
  let b = graph.add_node(Point::new(1, 0))
  let c = graph.add_node(Point::new(2, 0))
  graph.add_directed_edge(a, b, 10) |> ignore
  graph.add_directed_edge(a, c, 1) |> ignore
  graph.add_directed_edge(c, b, 1) |> ignore
  let result = graph.dijkstra(a, b)
  assert_true(result.found)
  assert_eq(result.cost, 2)
  assert_true(result.nodes == [a, c, b])
  assert_true(result.points == [Point::new(0, 0), Point::new(2, 0), Point::new(1, 0)])
}

///|
test "graph astar uses node positions" {
  let graph = Graph::new()
  let a = graph.add_node(Point::new(0, 0))
  let b = graph.add_node(Point::new(1, 0))
  let c = graph.add_node(Point::new(2, 0))
  graph.add_directed_edge(a, b, 1) |> ignore
  graph.add_directed_edge(b, c, 1) |> ignore
  graph.add_directed_edge(a, c, 5) |> ignore
  let result = graph.astar(a, c, Heuristic::Manhattan)
  assert_true(result.found)
  assert_eq(result.cost, 2)
  assert_true(result.nodes == [a, b, c])
  assert_eq(result.trace.length(), 3)
}

///|
test "graph reports unreachable target" {
  let graph = Graph::new()
  let a = graph.add_node(Point::new(0, 0))
  let b = graph.add_node(Point::new(1, 0))
  let result = graph.dijkstra(a, b)
  assert_false(result.found)
  assert_true(result.nodes == [])
  assert_eq(result.cost, -1)
}

///|
test "graph path result exports json" {
  let graph = Graph::new()
  let a = graph.add_node(Point::new(0, 0))
  let b = graph.add_node(Point::new(1, 0))
  graph.add_directed_edge(a, b, 2) |> ignore
  let result = graph.dijkstra(a, b)
  assert_true(result.to_json().contains("\"nodes\":[0,1]"))
  assert_true(result.to_json().contains("\"points\":[{\"x\":0,\"y\":0},{\"x\":1,\"y\":0}]"))
  assert_true(result.to_json().contains("\"cost\":2"))
}

///|
test "random grid generation is deterministic" {
  let config = RandomGridConfig::new(8, 6, 42)
    .with_blocked_percent(25)
    .with_weighted_percent(20)
    .with_max_weight(8)
  let first = GridMap::random(config)
  let second = GridMap::random(config)
  assert_true(first == second)
  assert_eq(first.cell_count(), 48)
}

///|
test "random grid can keep important cells open" {
  let start = Point::new(0, 0)
  let goal = Point::new(4, 4)
  let config = RandomGridConfig::new(5, 5, 7).with_blocked_percent(100)
  let grid = GridMap::random_with_clear_points(config, [start, goal])
  assert_false(grid.is_blocked(start))
  assert_false(grid.is_blocked(goal))
  assert_eq(grid.blocked_count(), 23)
}

///|
test "grid stats count blocked and weighted cells" {
  let grid = GridMap::new(3, 2)
    .set_blocked(Point::new(0, 0))
    .set_weight(Point::new(1, 0), 5)
    .set_weight(Point::new(2, 1), 3)
  let stats = grid.stats()
  assert_eq(stats.cells, 6)
  assert_eq(stats.open_cells, 5)
  assert_eq(stats.blocked_cells, 1)
  assert_eq(stats.weighted_cells, 2)
}

///|
test "random weighted grid can be searched" {
  let start = Point::new(0, 0)
  let goal = Point::new(5, 5)
  let config = RandomGridConfig::new(6, 6, 11)
    .with_blocked_percent(5)
    .with_weighted_percent(30)
    .with_max_weight(7)
  let grid = GridMap::random_with_clear_points(config, [start, goal])
  let result = grid.astar(start, goal, Heuristic::Manhattan)
  assert_true(result.visited_count > 0)
  assert_true(result.trace.length() > 0)
}

///|
test "heuristic estimates" {
  let a = Point::new(0, 0)
  let b = Point::new(3, 4)
  assert_eq(Heuristic::Manhattan.estimate(a, b), 7)
  assert_eq(Heuristic::Euclidean.estimate(a, b), 5)
  assert_eq(Heuristic::Octile.estimate(a, b), 5)
}

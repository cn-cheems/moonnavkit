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
}

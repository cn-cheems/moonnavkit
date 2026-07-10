///|
/// Open map interface for custom grid-like routing spaces.
///
/// `GridMap` implements this shape directly through its existing methods.
/// External map types can implement the same methods to become usable by
/// trait-oriented adapters without copying their storage into MoonNavKit.
pub(open) trait NavigationMap {
  fn contains(Self, Point) -> Bool
  fn cost_at(Self, Point) -> Int?
  fn neighbors4(Self, Point) -> Array[Point]
}

///|
/// A small solver object that lets users pass algorithms around as values.
pub(all) struct GridSolver {
  algorithm : Algorithm
} derive(Eq, Debug)

///|
pub fn GridSolver::new(algorithm : Algorithm) -> GridSolver {
  { algorithm, }
}

///|
pub(open) trait PathSolver {
  fn solve(Self, GridMap, Point, Point) -> PathResult
}

///|
pub impl PathSolver for GridSolver with fn solve(self, map, start, goal) {
  map.find_path(start, goal, self.algorithm)
}

///|
pub(all) struct LineOfSightSmoother {
  agent : AgentProfile
} derive(Eq, Debug)

///|
pub fn LineOfSightSmoother::new(agent : AgentProfile) -> LineOfSightSmoother {
  { agent, }
}

///|
pub(open) trait PathSmoother {
  fn smooth(Self, GridMap, Array[Point]) -> Array[Point]
}

///|
pub impl PathSmoother for LineOfSightSmoother with fn smooth(self, map, path) {
  map.compress_path(path, self.agent)
}

///|
pub fn solve_with(
  solver : GridSolver,
  map : GridMap,
  start : Point,
  goal : Point,
) -> PathResult {
  solver.solve(map, start, goal)
}

///|
pub fn smooth_with(
  smoother : LineOfSightSmoother,
  map : GridMap,
  path : Array[Point],
) -> Array[Point] {
  smoother.smooth(map, path)
}

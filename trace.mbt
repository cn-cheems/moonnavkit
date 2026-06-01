///|
/// One expansion event produced by a search algorithm.
pub(all) struct SearchStep {
  order : Int
  point : Point
  cost : Int
  score : Int
} derive(Eq, Debug)

///|
pub fn SearchStep::new(
  order : Int,
  point : Point,
  cost : Int,
  score : Int
) -> SearchStep {
  { order, point, cost, score }
}

///|
pub fn Point::to_json(self : Point) -> String {
  "{\"x\":\{self.x},\"y\":\{self.y}}"
}

///|
pub fn SearchStep::to_json(self : SearchStep) -> String {
  "{\"order\":\{self.order},\"point\":\{self.point.to_json()},\"cost\":\{self.cost},\"score\":\{self.score}}"
}

///|
/// Search trace is kept as data so it can feed JSON, SVG, HTML, or tests.
pub(all) struct SearchTrace {
  steps : Array[SearchStep]
} derive(Eq, Debug)

///|
pub fn SearchTrace::new() -> SearchTrace {
  { steps: [] }
}

///|
pub fn SearchTrace::length(self : SearchTrace) -> Int {
  self.steps.length()
}

///|
pub fn SearchTrace::push_step(
  self : SearchTrace,
  order : Int,
  point : Point,
  cost : Int,
  score : Int
) -> Unit {
  self.steps.push(SearchStep::new(order, point, cost, score))
}

///|
pub fn SearchTrace::to_json(self : SearchTrace) -> String {
  let buf = StringBuilder(size_hint=32 + self.steps.length() * 64)
  buf.write_string("{\"steps\":[")
  for i = 0; i < self.steps.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string(self.steps[i].to_json())
  }
  buf.write_string("]}")
  buf.to_string()
}

///|
fn write_points_json(buf : StringBuilder, points : Array[Point]) -> Unit {
  buf.write_string("[")
  for i = 0; i < points.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string(points[i].to_json())
  }
  buf.write_string("]")
}

///|
pub fn PathResult::to_json(self : PathResult) -> String {
  let buf = StringBuilder(size_hint=128 + self.path.length() * 24 + self.trace.length() * 64)
  buf.write_string("{\"found\":")
  buf.write_string(if self.found { "true" } else { "false" })
  buf.write_string(",\"cost\":\{self.cost},\"visited_count\":\{self.visited_count},\"path\":")
  write_points_json(buf, self.path)
  buf.write_string(",\"trace\":")
  buf.write_string(self.trace.to_json())
  buf.write_string("}")
  buf.to_string()
}

///|
fn write_ints_json(buf : StringBuilder, values : Array[Int]) -> Unit {
  buf.write_string("[")
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string(values[i].to_string())
  }
  buf.write_string("]")
}

///|
pub fn GraphPathResult::to_json(self : GraphPathResult) -> String {
  let buf = StringBuilder(size_hint=128 + self.points.length() * 24 + self.trace.length() * 64)
  buf.write_string("{\"found\":")
  buf.write_string(if self.found { "true" } else { "false" })
  buf.write_string(",\"cost\":\{self.cost},\"visited_count\":\{self.visited_count},\"nodes\":")
  write_ints_json(buf, self.nodes)
  buf.write_string(",\"points\":")
  write_points_json(buf, self.points)
  buf.write_string(",\"trace\":")
  buf.write_string(self.trace.to_json())
  buf.write_string("}")
  buf.to_string()
}

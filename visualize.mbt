///|
fn normalized_cell_size(cell_size : Int) -> Int {
  if cell_size < 8 {
    8
  } else {
    cell_size
  }
}

///|
fn point_center(point : Point, cell_size : Int) -> (Int, Int) {
  (
    point.x * cell_size + cell_size / 2,
    point.y * cell_size + cell_size / 2,
  )
}

///|
fn point_in_array(point : Point, points : Array[Point]) -> Bool {
  for i = 0; i < points.length(); i = i + 1 {
    if points[i] == point {
      return true
    }
  }
  false
}

///|
fn GridMap::cell_fill(self : GridMap, point : Point) -> String {
  match self.index(point) {
    Some(index) =>
      if self.weights[index] < 0 {
        "#111827"
      } else if self.weights[index] > 1 {
        "#fde68a"
      } else {
        "#f8fafc"
      }
    None => "#111827"
  }
}

///|
fn write_rect(
  buf : StringBuilder,
  x : Int,
  y : Int,
  size : Int,
  fill : String,
  stroke : String,
  opacity : String
) -> Unit {
  buf.write_string(
    "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{size}\" height=\"\{size}\" fill=\"\{fill}\" stroke=\"\{stroke}\" opacity=\"\{opacity}\"/>",
  )
}

///|
fn write_circle(
  buf : StringBuilder,
  point : Point,
  cell_size : Int,
  fill : String
) -> Unit {
  let (cx, cy) = point_center(point, cell_size)
  let radius = cell_size / 4
  buf.write_string(
    "<circle cx=\"\{cx}\" cy=\"\{cy}\" r=\"\{radius}\" fill=\"\{fill}\"/>",
  )
}

///|
fn write_path_polyline(
  buf : StringBuilder,
  path : Array[Point],
  cell_size : Int
) -> Unit {
  if path.length() <= 1 {
    return
  }
  buf.write_string(
    "<polyline fill=\"none\" stroke=\"#16a34a\" stroke-width=\"4\" stroke-linecap=\"round\" stroke-linejoin=\"round\" points=\"",
  )
  for i = 0; i < path.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(" ")
    }
    let (cx, cy) = point_center(path[i], cell_size)
    buf.write_string("\{cx},\{cy}")
  }
  buf.write_string("\"/>")
}

///|
fn GridMap::write_base_cells(
  self : GridMap,
  buf : StringBuilder,
  result : PathResult,
  cell_size : Int
) -> Unit {
  for y = 0; y < self.height; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      let point = Point::new(x, y)
      let px = x * cell_size
      let py = y * cell_size
      write_rect(buf, px, py, cell_size, self.cell_fill(point), "#cbd5e1", "1")
      match self.index(point) {
        Some(index) =>
          if self.weights[index] > 1 {
            buf.write_string(
              "<text x=\"\{px + cell_size / 2}\" y=\"\{py + cell_size / 2 + 4}\" text-anchor=\"middle\" font-size=\"10\" fill=\"#92400e\">\{self.weights[index]}</text>",
            )
          }
        None => ()
      }
      if point_in_array(point, result.path) {
        write_rect(buf, px + 2, py + 2, cell_size - 4, "#bbf7d0", "none", "0.75")
      }
    }
  }
}

///|
fn write_trace_cells(
  buf : StringBuilder,
  trace : SearchTrace,
  cell_size : Int
) -> Unit {
  let inset = cell_size / 5
  let trace_size = cell_size - inset * 2
  for i = 0; i < trace.steps.length(); i = i + 1 {
    let step = trace.steps[i]
    let x = step.point.x * cell_size + inset
    let y = step.point.y * cell_size + inset
    write_rect(buf, x, y, trace_size, "#bfdbfe", "none", "0.55")
  }
}

///|
/// Exports a grid pathfinding result as a standalone SVG string.
pub fn GridMap::to_svg(
  self : GridMap,
  result : PathResult,
  cell_size : Int
) -> String {
  let size = normalized_cell_size(cell_size)
  let width = self.width * size
  let height = self.height * size
  let buf = StringBuilder(size_hint=512 + self.cell_count() * 96)
  buf.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\" role=\"img\" aria-label=\"MoonNavKit path visualization\">",
  )
  buf.write_string("<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>")
  self.write_base_cells(buf, result, size)
  write_trace_cells(buf, result.trace, size)
  write_path_polyline(buf, result.path, size)
  if result.path.length() > 0 {
    write_circle(buf, result.path[0], size, "#22c55e")
    write_circle(buf, result.path[result.path.length() - 1], size, "#ef4444")
  }
  buf.write_string("</svg>")
  buf.to_string()
}

///|
/// Exports a pathfinding result as a minimal standalone HTML document.
pub fn GridMap::to_html(
  self : GridMap,
  result : PathResult,
  cell_size : Int
) -> String {
  let svg = self.to_svg(result, cell_size)
  let json = result.to_json()
  let buf = StringBuilder(size_hint=svg.length() + json.length() + 512)
  buf.write_string("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"/>")
  buf.write_string("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"/>")
  buf.write_string("<title>MoonNavKit Replay</title>")
  buf.write_string("<style>body{margin:0;font-family:system-ui,sans-serif;background:#f8fafc;color:#0f172a}main{padding:24px}svg{max-width:100%;height:auto;border:1px solid #cbd5e1;background:white}</style>")
  buf.write_string("</head><body><main><h1>MoonNavKit Replay</h1>")
  buf.write_string(svg)
  buf.write_string("<script type=\"application/json\" id=\"moonnavkit-data\">")
  buf.write_string(json)
  buf.write_string("</script></main></body></html>")
  buf.to_string()
}

///|
fn edge_in_node_path(from : Int, to : Int, nodes : Array[Int]) -> Bool {
  for i = 0; i + 1 < nodes.length(); i = i + 1 {
    if nodes[i] == from && nodes[i + 1] == to {
      return true
    }
  }
  false
}

///|
fn Graph::write_dot_nodes(self : Graph, buf : StringBuilder) -> Unit {
  for i = 0; i < self.nodes.length(); i = i + 1 {
    let node = self.nodes[i]
    buf.write_string(
      "  n\{node.id} [label=\"\{node.id} (\{node.position.x},\{node.position.y})\"];\n",
    )
  }
}

///|
fn Graph::write_dot_edges(
  self : Graph,
  buf : StringBuilder,
  result : GraphPathResult
) -> Unit {
  for i = 0; i < self.edges.length(); i = i + 1 {
    let edge = self.edges[i]
    let on_path = edge_in_node_path(edge.from, edge.to, result.nodes)
    buf.write_string("  n\{edge.from} -> n\{edge.to} [label=\"\{edge.weight}\"")
    if on_path {
      buf.write_string(", color=\"#16a34a\", penwidth=3")
    }
    buf.write_string("];\n")
  }
}

///|
/// Exports a graph pathfinding result as Graphviz DOT.
pub fn Graph::to_dot(self : Graph, result : GraphPathResult) -> String {
  let buf = StringBuilder(size_hint=256 + self.node_count() * 48 + self.edge_count() * 64)
  buf.write_string("digraph MoonNavKit {\n")
  buf.write_string("  graph [rankdir=LR];\n")
  buf.write_string("  node [shape=circle, style=filled, fillcolor=\"#f8fafc\"];\n")
  buf.write_string("  edge [color=\"#475569\"];\n")
  self.write_dot_nodes(buf)
  self.write_dot_edges(buf, result)
  if result.found {
    buf.write_string("  label=\"cost=\{result.cost}, visited=\{result.visited_count}\";\n")
  } else {
    buf.write_string("  label=\"path not found, visited=\{result.visited_count}\";\n")
  }
  buf.write_string("}\n")
  buf.to_string()
}

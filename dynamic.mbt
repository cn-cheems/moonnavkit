///|
/// A lexicographic priority used by D* Lite's incremental repair queue.
struct DynamicQueueEntry {
  item : Int
  first : Int
  second : Int
  revision : Int
  order : Int
} derive(Debug)

///|
struct DynamicPriorityQueue {
  entries : Array[DynamicQueueEntry]
  mut next_order : Int
} derive(Debug)

///|
fn DynamicPriorityQueue::new() -> DynamicPriorityQueue {
  { entries: [], next_order: 0 }
}

///|
fn DynamicPriorityQueue::peek(
  self : DynamicPriorityQueue,
) -> DynamicQueueEntry? {
  if self.entries.length() == 0 {
    None
  } else {
    Some(self.entries[0])
  }
}

///|
fn DynamicPriorityQueue::push(
  self : DynamicPriorityQueue,
  item : Int,
  first : Int,
  second : Int,
  revision : Int,
) -> Unit {
  self.entries.push({ item, first, second, revision, order: self.next_order })
  self.next_order = self.next_order + 1
  self.sift_up(self.entries.length() - 1)
}

///|
fn DynamicPriorityQueue::pop(self : DynamicPriorityQueue) -> DynamicQueueEntry? {
  if self.entries.length() == 0 {
    return None
  }
  let first = self.entries[0]
  let last = self.entries.unsafe_pop()
  if self.entries.length() > 0 {
    self.entries[0] = last
    self.sift_down(0)
  }
  Some(first)
}

///|
fn DynamicPriorityQueue::sift_up(
  self : DynamicPriorityQueue,
  start : Int,
) -> Unit {
  let mut child = start
  while child > 0 {
    let parent = (child - 1) / 2
    if self.less(child, parent) {
      self.swap(child, parent)
      child = parent
    } else {
      break
    }
  }
}

///|
fn DynamicPriorityQueue::sift_down(
  self : DynamicPriorityQueue,
  start : Int,
) -> Unit {
  let mut parent = start
  let mut done = false
  while !done {
    let left = parent * 2 + 1
    let right = left + 1
    let mut best = parent
    if left < self.entries.length() && self.less(left, best) {
      best = left
    }
    if right < self.entries.length() && self.less(right, best) {
      best = right
    }
    if best == parent {
      done = true
    } else {
      self.swap(parent, best)
      parent = best
    }
  }
}

///|
fn DynamicPriorityQueue::less(
  self : DynamicPriorityQueue,
  left : Int,
  right : Int,
) -> Bool {
  let a = self.entries[left]
  let b = self.entries[right]
  a.first < b.first ||
  (
    a.first == b.first &&
    (a.second < b.second || (a.second == b.second && a.order < b.order))
  )
}

///|
fn DynamicPriorityQueue::swap(
  self : DynamicPriorityQueue,
  left : Int,
  right : Int,
) -> Unit {
  let tmp = self.entries[left]
  self.entries[left] = self.entries[right]
  self.entries[right] = tmp
}

///|
/// Removes stale versioned entries, refreshes keys, and restores heap order in
/// linear time with Floyd's bottom-up heap construction.
fn DynamicPriorityQueue::rebuild_valid(
  self : DynamicPriorityQueue,
  revisions : Array[Int],
  map : GridMap,
  start : Point,
  g : Array[Int],
  rhs : Array[Int],
  km : Int,
) -> Unit {
  let mut valid_count = 0
  for read = 0; read < self.entries.length(); read = read + 1 {
    let entry = self.entries[read]
    if revisions[entry.item] == entry.revision {
      let value = min_int(g[entry.item], rhs[entry.item])
      let distance = start.manhattan(map.point_at(entry.item))
      self.entries[valid_count] = {
        item: entry.item,
        first: capped_add(value, capped_add(distance, km)),
        second: value,
        revision: entry.revision,
        order: entry.order,
      }
      valid_count = valid_count + 1
    }
  }
  while self.entries.length() > valid_count {
    ignore(self.entries.unsafe_pop())
  }
  let mut parent = valid_count / 2
  while parent > 0 {
    parent = parent - 1
    self.sift_down(parent)
  }
}

///|
/// Incremental D* Lite planner for a four-direction weighted `GridMap`.
///
/// Update a cell with `set_blocked`, `set_open`, or `set_weight`, then call
/// `replan`. The planner retains its previous search state and repairs only
/// affected vertices. It supports static start/goal pairs; create a new planner
/// when either endpoint changes.
pub(all) struct DynamicGridPlanner {
  map : GridMap
  mut start : Point
  goal : Point
  g : Array[Int]
  rhs : Array[Int]
  revisions : Array[Int]
  queue : DynamicPriorityQueue
  mut last_replan_expanded_count : Int
  mut repair_in_progress : Bool
  mut repair_trace : SearchTrace
  mut km : Int
  mut queue_rebuild_count : Int
} derive(Debug)

///|
/// Result of one frame-budgeted dynamic replanning step.
///
/// `Pending` contains the number of vertices repaired so far. `Ready` carries
/// the same optimal result returned by `replan`.
pub(all) enum DynamicReplanStatus {
  Pending(Int)
  Ready(PathResult)
} derive(Eq, Debug)

///|
pub fn DynamicGridPlanner::new(
  map : GridMap,
  start : Point,
  goal : Point,
) -> DynamicGridPlanner {
  let total = map.cell_count()
  let planner = {
    map,
    start,
    goal,
    g: Array::make(total, unreachable_cost),
    rhs: Array::make(total, unreachable_cost),
    revisions: Array::make(total, 0),
    queue: DynamicPriorityQueue::new(),
    last_replan_expanded_count: 0,
    repair_in_progress: false,
    repair_trace: SearchTrace::new(),
    km: 0,
    queue_rebuild_count: 0,
  }
  match planner.map.index(goal) {
    Some(goal_index) =>
      if planner.is_open_index(goal_index) {
        planner.rhs[goal_index] = 0
        planner.enqueue(goal_index)
      }
    None => ()
  }
  planner
}

///|
pub fn DynamicGridPlanner::map(self : DynamicGridPlanner) -> GridMap {
  self.map
}

///|
/// Returns how often the lazy priority queue was compacted after a key-modifier
/// reset. Normal game-sized maps should keep this at zero.
pub fn DynamicGridPlanner::queue_rebuild_count(
  self : DynamicGridPlanner,
) -> Int {
  self.queue_rebuild_count
}

///|
/// Moves the planner's start while preserving its D* Lite search state.
///
/// A valid, open point updates D* Lite's key modifier and is repaired by the
/// next `replan` or `replan_step`. Invalid or blocked points are ignored, so a
/// game loop can submit a candidate position without risking a panic. The goal
/// remains fixed; construct a new planner to change it.
pub fn DynamicGridPlanner::move_start(
  self : DynamicGridPlanner,
  next_start : Point,
) -> DynamicGridPlanner {
  if self.map.contains(next_start) && !self.map.is_blocked(next_start) {
    let movement = self.start.manhattan(next_start)
    self.start = next_start
    let reserve = self.map.width + self.map.height + movement + 1
    if self.km > unreachable_cost - reserve {
      // `km` is a uniform first-key offset. Resetting it preserves ordering
      // only after every live entry receives its new key.
      self.km = movement
      self.queue.rebuild_valid(
        self.revisions,
        self.map,
        self.start,
        self.g,
        self.rhs,
        self.km,
      )
      self.queue_rebuild_count = self.queue_rebuild_count + 1
    } else {
      self.km = self.km + movement
    }
    self.repair_in_progress = false
  }
  self
}

///|
pub fn DynamicGridPlanner::last_replan_expanded_count(
  self : DynamicGridPlanner,
) -> Int {
  self.last_replan_expanded_count
}

///|
/// Returns the ordered vertices processed during the current or most recently
/// completed repair. `cost` is the vertex's previous `g` value and `score` is
/// its current `rhs` value, which makes local repairs inspectable in JSON.
pub fn DynamicGridPlanner::repair_trace(
  self : DynamicGridPlanner,
) -> SearchTrace {
  self.repair_trace
}

///|
/// Marks a cell blocked and records the local change for incremental repair.
pub fn DynamicGridPlanner::set_blocked(
  self : DynamicGridPlanner,
  point : Point,
) -> DynamicGridPlanner {
  ignore(self.map.set_blocked(point))
  self.notify_cell_changed(point)
  self
}

///|
/// Opens a cell with unit traversal cost and records the local change.
pub fn DynamicGridPlanner::set_open(
  self : DynamicGridPlanner,
  point : Point,
) -> DynamicGridPlanner {
  ignore(self.map.set_open(point))
  self.notify_cell_changed(point)
  self
}

///|
/// Changes a cell's positive traversal cost and records the local change.
pub fn DynamicGridPlanner::set_weight(
  self : DynamicGridPlanner,
  point : Point,
  weight : Int,
) -> DynamicGridPlanner {
  ignore(self.map.set_weight(point, weight))
  self.notify_cell_changed(point)
  self
}

///|
/// Repairs the shortest-path state and returns an optimal route for the
/// planner's current map. `last_replan_expanded_count` reports this repair's
/// work, which can be compared with a fresh Dijkstra run in benchmarks.
pub fn DynamicGridPlanner::replan(self : DynamicGridPlanner) -> PathResult {
  guard self.begin_repair() else { return PathResult::not_found(0) }
  ignore(self.compute_shortest_path(unreachable_cost))
  self.repair_in_progress = false
  self.reconstruct_path()
}

///|
/// Performs at most `max_expansions` D* Lite vertex repairs.
///
/// Call this once per game or simulation frame until it returns `Ready`. A
/// non-positive budget does no repair and returns `Pending` when work remains.
pub fn DynamicGridPlanner::replan_step(
  self : DynamicGridPlanner,
  max_expansions : Int,
) -> DynamicReplanStatus {
  guard self.begin_repair() else { return Ready(PathResult::not_found(0)) }
  let budget = if max_expansions > 0 { max_expansions } else { 0 }
  if self.compute_shortest_path(budget) {
    self.repair_in_progress = false
    Ready(self.reconstruct_path())
  } else {
    Pending(self.last_replan_expanded_count)
  }
}

///|
fn DynamicGridPlanner::begin_repair(self : DynamicGridPlanner) -> Bool {
  if !self.map.contains(self.start) ||
    !self.map.contains(self.goal) ||
    self.map.is_blocked(self.start) ||
    self.map.is_blocked(self.goal) {
    self.repair_in_progress = false
    self.last_replan_expanded_count = 0
    self.repair_trace = SearchTrace::new()
    false
  } else {
    if !self.repair_in_progress {
      self.last_replan_expanded_count = 0
      self.repair_trace = SearchTrace::new()
      self.repair_in_progress = true
    }
    true
  }
}

///|
fn DynamicGridPlanner::notify_cell_changed(
  self : DynamicGridPlanner,
  point : Point,
) -> Unit {
  self.repair_in_progress = false
  match self.map.index(point) {
    Some(index) => {
      self.update_vertex(index)
      let neighbors = self.neighbor_indices(index)
      for i = 0; i < neighbors.length(); i = i + 1 {
        self.update_vertex(neighbors[i])
      }
    }
    None => ()
  }
}

///|
fn DynamicGridPlanner::compute_shortest_path(
  self : DynamicGridPlanner,
  max_expansions : Int,
) -> Bool {
  let start_index = self.map.index(self.start).unwrap()
  let mut expanded = 0
  while true {
    let start_key = self.key_for(start_index)
    match self.queue.peek() {
      None => return true
      Some(entry) => {
        let should_continue = key_less(
            entry.first,
            entry.second,
            start_key.0,
            start_key.1,
          ) ||
          self.rhs[start_index] != self.g[start_index]
        if !should_continue {
          return true
        } else if expanded >= max_expansions {
          return false
        } else {
          let current = self.queue.pop().unwrap()
          if self.revisions[current.item] == current.revision {
            self.repair_trace.push_step(
              self.last_replan_expanded_count,
              self.map.point_at(current.item),
              self.g[current.item],
              self.rhs[current.item],
            )
            let current_key = self.key_for(current.item)
            if key_less(
                current.first,
                current.second,
                current_key.0,
                current_key.1,
              ) {
              self.enqueue(current.item)
            } else if self.g[current.item] > self.rhs[current.item] {
              self.g[current.item] = self.rhs[current.item]
              self.revisions[current.item] = self.revisions[current.item] + 1
              self.update_predecessors(current.item)
            } else {
              self.g[current.item] = unreachable_cost
              self.update_vertex(current.item)
              self.update_predecessors(current.item)
            }
            self.last_replan_expanded_count = self.last_replan_expanded_count +
              1
            expanded = expanded + 1
          }
        }
      }
    }
  }
  false
}

///|
fn DynamicGridPlanner::update_predecessors(
  self : DynamicGridPlanner,
  index : Int,
) -> Unit {
  let neighbors = self.neighbor_indices(index)
  for i = 0; i < neighbors.length(); i = i + 1 {
    self.update_vertex(neighbors[i])
  }
}

///|
fn DynamicGridPlanner::update_vertex(
  self : DynamicGridPlanner,
  index : Int,
) -> Unit {
  let goal_index = self.map.index(self.goal).unwrap()
  if index == goal_index {
    self.rhs[index] = if self.is_open_index(index) {
      0
    } else {
      unreachable_cost
    }
  } else if !self.is_open_index(index) {
    self.rhs[index] = unreachable_cost
  } else {
    let neighbors = self.neighbor_indices(index)
    let mut best = unreachable_cost
    for i = 0; i < neighbors.length(); i = i + 1 {
      let next = neighbors[i]
      if self.is_open_index(next) {
        let step = self.map.weights[next]
        let candidate = capped_add(step, self.g[next])
        if candidate < best {
          best = candidate
        }
      }
    }
    self.rhs[index] = best
  }
  self.enqueue(index)
}

///|
fn DynamicGridPlanner::enqueue(self : DynamicGridPlanner, index : Int) -> Unit {
  self.revisions[index] = self.revisions[index] + 1
  if self.g[index] != self.rhs[index] {
    let key = self.key_for(index)
    self.queue.push(index, key.0, key.1, self.revisions[index])
  }
}

///|
fn DynamicGridPlanner::key_for(
  self : DynamicGridPlanner,
  index : Int,
) -> (Int, Int) {
  let value = min_int(self.g[index], self.rhs[index])
  let distance = self.start.manhattan(self.map.point_at(index))
  (capped_add(value, capped_add(distance, self.km)), value)
}

///|
fn DynamicGridPlanner::is_open_index(
  self : DynamicGridPlanner,
  index : Int,
) -> Bool {
  index >= 0 && index < self.map.cell_count() && self.map.weights[index] > 0
}

///|
fn DynamicGridPlanner::neighbor_indices(
  self : DynamicGridPlanner,
  index : Int,
) -> Array[Int] {
  let point = self.map.point_at(index)
  let result : Array[Int] = []
  self.push_index_if_present(result, Point::new(point.x + 1, point.y))
  self.push_index_if_present(result, Point::new(point.x - 1, point.y))
  self.push_index_if_present(result, Point::new(point.x, point.y + 1))
  self.push_index_if_present(result, Point::new(point.x, point.y - 1))
  result
}

///|
fn DynamicGridPlanner::push_index_if_present(
  self : DynamicGridPlanner,
  result : Array[Int],
  point : Point,
) -> Unit {
  match self.map.index(point) {
    Some(index) => result.push(index)
    None => ()
  }
}

///|
fn DynamicGridPlanner::reconstruct_path(
  self : DynamicGridPlanner,
) -> PathResult {
  let start_index = self.map.index(self.start).unwrap()
  let goal_index = self.map.index(self.goal).unwrap()
  if self.g[start_index] >= unreachable_cost {
    return PathResult::not_found(self.last_replan_expanded_count)
  }
  let path : Array[Point] = [self.start]
  let trace = SearchTrace::new()
  let mut current = start_index
  let mut order = 0
  trace.push_step(order, self.start, self.g[current], self.g[current])
  while current != goal_index && order < self.map.cell_count() {
    let neighbors = self.neighbor_indices(current)
    let mut best = -1
    let mut best_cost = unreachable_cost
    for i = 0; i < neighbors.length(); i = i + 1 {
      let next = neighbors[i]
      if self.is_open_index(next) {
        let candidate = capped_add(self.map.weights[next], self.g[next])
        if candidate < best_cost {
          best = next
          best_cost = candidate
        }
      }
    }
    if best == -1 || best_cost >= unreachable_cost {
      return PathResult::not_found(self.last_replan_expanded_count)
    }
    current = best
    order = order + 1
    let point = self.map.point_at(current)
    path.push(point)
    trace.push_step(order, point, self.g[current], self.g[current])
  }
  {
    found: current == goal_index,
    path,
    cost: self.g[start_index],
    visited_count: self.last_replan_expanded_count,
    trace,
  }
}

///|
fn key_less(
  a_first : Int,
  a_second : Int,
  b_first : Int,
  b_second : Int,
) -> Bool {
  a_first < b_first || (a_first == b_first && a_second < b_second)
}

///|
fn capped_add(left : Int, right : Int) -> Int {
  if left >= unreachable_cost ||
    right >= unreachable_cost ||
    left > unreachable_cost - right {
    unreachable_cost
  } else {
    left + right
  }
}

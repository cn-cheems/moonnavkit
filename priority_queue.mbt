///|
/// A node id or cell index with its current search priority.
pub(all) struct QueueEntry {
  item : Int
  priority : Int
  order : Int
} derive(Eq, Debug)

///|
/// Small stable min-priority queue used by shortest-path searches.
pub(all) struct MinPriorityQueue {
  entries : Array[QueueEntry]
  mut next_order : Int
} derive(Debug)

///|
pub fn MinPriorityQueue::new() -> MinPriorityQueue {
  { entries: [], next_order: 0 }
}

///|
pub fn MinPriorityQueue::length(self : MinPriorityQueue) -> Int {
  self.entries.length()
}

///|
pub fn MinPriorityQueue::is_empty(self : MinPriorityQueue) -> Bool {
  self.entries.length() == 0
}

///|
pub fn MinPriorityQueue::push(
  self : MinPriorityQueue,
  item : Int,
  priority : Int,
) -> Unit {
  self.entries.push({ item, priority, order: self.next_order })
  self.next_order = self.next_order + 1
  self.sift_up(self.entries.length() - 1)
}

///|
pub fn MinPriorityQueue::peek(self : MinPriorityQueue) -> QueueEntry? {
  if self.entries.length() == 0 {
    None
  } else {
    Some(self.entries[0])
  }
}

///|
pub fn MinPriorityQueue::pop(self : MinPriorityQueue) -> QueueEntry? {
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
fn MinPriorityQueue::sift_up(self : MinPriorityQueue, start : Int) -> Unit {
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
fn MinPriorityQueue::sift_down(self : MinPriorityQueue, start : Int) -> Unit {
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
fn MinPriorityQueue::less(
  self : MinPriorityQueue,
  left : Int,
  right : Int,
) -> Bool {
  let a = self.entries[left]
  let b = self.entries[right]
  a.priority < b.priority || (a.priority == b.priority && a.order < b.order)
}

///|
fn MinPriorityQueue::swap(
  self : MinPriorityQueue,
  left : Int,
  right : Int,
) -> Unit {
  let tmp = self.entries[left]
  self.entries[left] = self.entries[right]
  self.entries[right] = tmp
}

///|
fn clamp_percent(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn positive_mod(value : Int, modulo : Int) -> Int {
  let result = value % modulo
  if result < 0 {
    result + modulo
  } else {
    result
  }
}

///|
fn cell_roll(seed : Int, x : Int, y : Int, salt : Int, modulo : Int) -> Int {
  let seed_part = positive_mod(seed, 10_000)
  let mixed = seed_part + x * 73 + y * 997 + salt * 131
  positive_mod(mixed * 37 + 17, modulo)
}

///|
/// Configuration for deterministic random grid generation.
pub(all) struct RandomGridConfig {
  width : Int
  height : Int
  seed : Int
  blocked_percent : Int
  weighted_percent : Int
  max_weight : Int
} derive(Eq, Debug)

///|
pub fn RandomGridConfig::new(
  width : Int,
  height : Int,
  seed : Int
) -> RandomGridConfig {
  {
    width,
    height,
    seed,
    blocked_percent: 20,
    weighted_percent: 15,
    max_weight: 6,
  }
}

///|
pub fn RandomGridConfig::with_blocked_percent(
  self : RandomGridConfig,
  blocked_percent : Int
) -> RandomGridConfig {
  {
    width: self.width,
    height: self.height,
    seed: self.seed,
    blocked_percent: clamp_percent(blocked_percent),
    weighted_percent: self.weighted_percent,
    max_weight: self.max_weight,
  }
}

///|
pub fn RandomGridConfig::with_weighted_percent(
  self : RandomGridConfig,
  weighted_percent : Int
) -> RandomGridConfig {
  {
    width: self.width,
    height: self.height,
    seed: self.seed,
    blocked_percent: self.blocked_percent,
    weighted_percent: clamp_percent(weighted_percent),
    max_weight: self.max_weight,
  }
}

///|
pub fn RandomGridConfig::with_max_weight(
  self : RandomGridConfig,
  max_weight : Int
) -> RandomGridConfig {
  {
    width: self.width,
    height: self.height,
    seed: self.seed,
    blocked_percent: self.blocked_percent,
    weighted_percent: self.weighted_percent,
    max_weight: if max_weight < 2 { 2 } else { max_weight },
  }
}

///|
pub(all) struct GridStats {
  cells : Int
  open_cells : Int
  blocked_cells : Int
  weighted_cells : Int
} derive(Eq, Debug)

///|
pub fn GridMap::set_open(self : GridMap, point : Point) -> GridMap {
  match self.index(point) {
    Some(index) => self.weights[index] = 1
    None => ()
  }
  self
}

///|
pub fn GridMap::blocked_count(self : GridMap) -> Int {
  let mut count = 0
  for i = 0; i < self.weights.length(); i = i + 1 {
    if self.weights[i] < 0 {
      count = count + 1
    }
  }
  count
}

///|
pub fn GridMap::weighted_count(self : GridMap) -> Int {
  let mut count = 0
  for i = 0; i < self.weights.length(); i = i + 1 {
    if self.weights[i] > 1 {
      count = count + 1
    }
  }
  count
}

///|
pub fn GridMap::stats(self : GridMap) -> GridStats {
  let blocked = self.blocked_count()
  let weighted = self.weighted_count()
  {
    cells: self.cell_count(),
    open_cells: self.cell_count() - blocked,
    blocked_cells: blocked,
    weighted_cells: weighted,
  }
}

///|
/// Builds a deterministic pseudo-random grid from a seed.
pub fn GridMap::random(config : RandomGridConfig) -> GridMap {
  let grid = GridMap::new(config.width, config.height)
  for y = 0; y < config.height; y = y + 1 {
    for x = 0; x < config.width; x = x + 1 {
      let point = Point::new(x, y)
      let terrain_roll = cell_roll(config.seed, x, y, 1, 100)
      if terrain_roll < config.blocked_percent {
        grid.set_blocked(point) |> ignore
      } else {
        let weight_roll = cell_roll(config.seed, x, y, 2, 100)
        if weight_roll < config.weighted_percent {
          let weight = 2 + cell_roll(config.seed, x, y, 3, config.max_weight - 1)
          grid.set_weight(point, weight) |> ignore
        }
      }
    }
  }
  grid
}

///|
/// Builds a deterministic grid and guarantees important cells stay open.
pub fn GridMap::random_with_clear_points(
  config : RandomGridConfig,
  clear_points : Array[Point]
) -> GridMap {
  let grid = GridMap::random(config)
  for i = 0; i < clear_points.length(); i = i + 1 {
    grid.set_open(clear_points[i]) |> ignore
  }
  grid
}

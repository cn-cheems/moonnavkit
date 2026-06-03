# Changelog

All notable changes to MoonNavKit are recorded here so contest reviewers and
future users can trace the project history without reading every commit.

## 0.2.0 - 2026-06-03

### Added

- Added a stable `MinPriorityQueue` for open-set management.
- Added regression coverage for stale queue entries in graph Dijkstra search.
- Added issue templates for bug reports, feature requests, and performance work.
- Added a pull request template with verification and changelog checks.

### Changed

- Grid search now uses the shared priority queue instead of a linear open-set scan.
- Graph search now uses the shared priority queue instead of a linear open-set scan.
- Updated performance notes and roadmap to reflect the priority queue optimization.

### Verified

- `moon check`
- `moon test` with 28 passing tests

## 0.1.0 - 2026-06-01

### Added

- Initialized the MoonBit package and GitHub CI.
- Added `Point`, `GridMap`, and weighted `Graph` models.
- Added BFS, Dijkstra, and A* for grid search.
- Added BFS, Dijkstra, and A* for graph search.
- Added `SearchTrace`, JSON export, SVG export, and standalone HTML export.
- Added deterministic random grid generation and grid statistics.
- Added README examples, roadmap, and performance notes.

### Verified

- `moon test` with 25 passing tests


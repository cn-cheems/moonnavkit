# Architecture

MoonNavKit is organized as a small navigation stack rather than a single A*
function. The current design keeps the core backend-neutral while exposing
extension points for future MoonBit ecosystem users.

## Core Data Model

- `Point` is the shared coordinate type.
- `GridMap` is a weighted cost map. Positive weights are traversal costs; a
  negative value is blocked.
- `Graph` is a weighted directed graph with optional positions for heuristics
  and visualization.

## Strategy Interfaces

MoonNavKit exposes three open traits:

- `NavigationMap` documents the map-like contract that the next generic search
  layer will consume: containment, cost, and neighbor access.
- `PathSolver` describes solver strategy values.
- `PathSmoother` describes route post-processing strategy values.

The first implementations are intentionally conservative:

- `GridSolver` wraps `Algorithm` and delegates to `GridMap::find_path`.
- `LineOfSightSmoother` delegates to `GridMap::compress_path`.

This gives the public API a trait-oriented shape without destabilizing the
existing, tested grid and graph algorithms. Today `GridSolver` deliberately
accepts `GridMap`; using arbitrary `NavigationMap` implementations as direct
search inputs remains the next planned extraction rather than a capability the
current API claims to provide.

## Hot Path Design

The grid search hot path avoids `neighbors4` allocation. The public method still
exists for users and tests, but BFS, Dijkstra, and A* now relax the four
candidate cells directly inside the search loop. This removes one array
allocation per expanded cell and reduces GC pressure in pathfinding-heavy
workloads.

Graph search stores outgoing edges in an adjacency table as nodes and edges are
added. Public `Graph::neighbors` still returns a copy for inspection, while the
search loop reads the stored outgoing edges directly. This keeps the ergonomic
API while avoiding a full edge-list scan for every expanded graph node.

## Evidence Pipeline

The repository has three layers of evidence:

- unit tests for correctness;
- `moon run cmd/bench` for deterministic workload counters;
- `tools/perf_report.ps1` for command timings and backend artifact sizes.

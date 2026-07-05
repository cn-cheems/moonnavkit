# Weighted Multi-Goal Flow Fields

## Problem

Single-route A* is effective when one actor asks one question. It repeats work
when dozens of agents move toward the same warehouse station, game objective,
evacuation exit, or service point.

MoonNavKit builds a reusable field from several destinations with one reverse
Dijkstra search. Every reachable cell stores:

- optimal remaining cost;
- the next cell on an optimal route;
- the selected destination.

Each later route query follows stored next steps. Its cost is O(path length)
instead of another O(V log V + E) graph search.

## Cost Semantics

Moving from cell A into cell B pays B's positive weight. Blocked cells have no
cost and never enter the field. Reverse relaxation therefore adds the current
cell's entry cost when updating a predecessor. This matches `GridMap::dijkstra`
exactly and is checked by regression tests.

Invalid, blocked, and duplicate destinations are ignored. A blocked or
disconnected start returns `PathResult::not_found`.

## Determinism

The implementation uses MoonNavKit's stable minimum priority queue and a fixed
four-neighbor order. Equal-cost executions therefore produce reproducible
fields, paths, traces, and JSON on every supported backend.

## Reproducible Evidence

Run:

```sh
moon run cmd/bench
```

The `many-agent-32x32-seed707` rows compare 64 repeated Dijkstra searches with
one flow-field build followed by 64 route queries. Total route costs must agree.
The `visited` column exposes repeated search work versus field construction
work; `trace` records the total number of followed query steps.

Current deterministic output:

| Strategy | Total route cost | Search expansions | Query steps |
| --- | ---: | ---: | ---: |
| 64 repeated Dijkstra searches | 3212 | 47672 | n/a |
| One flow-field build + 64 queries | 3212 | 1024 | 2254 |

The field build performs about 46.6 times fewer search expansions for this
workload. Query steps are direct array-following operations, not priority-queue
search expansions.

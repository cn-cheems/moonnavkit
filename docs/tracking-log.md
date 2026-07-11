# Tracking Log

This file records public development links that are useful during contest
review. GitHub remains the source of truth for issues and pull requests.

## 2026-06-03

- Issue: [#1 - Add deterministic benchmark command](https://github.com/cn-cheems/moonnavkit/issues/1)
- Pull request: [#2 - Add deterministic benchmark command](https://github.com/cn-cheems/moonnavkit/pull/2)
- Branch: `feat/benchmark-command`
- Commit: `f435f29 Add deterministic benchmark command`
- Verification:
  - `moon check`
  - `moon test`
  - `moon run cmd/bench`

## 2026-06-09

- Issue: [#3 - Add Graph DOT export](https://github.com/cn-cheems/moonnavkit/issues/3)
- Pull request: [#4 - Add Graph DOT export](https://github.com/cn-cheems/moonnavkit/pull/4)
- Branch: `feat/graph-dot-export`
- Commit: `693f270 Add Graph DOT export`
- Scope:
  - Add Graphviz DOT export for graph search results.
  - Highlight final path edges in DOT output.
  - Update README and CHANGELOG.

## 2026-07-06 to 2026-07-11

- Correctness: made graph A* heuristic scaling admissible for arbitrary edge
  weights; added weighted multi-goal flow fields.
- Production routing: added clearance-aware routing, route compression, and
  public performance evidence.
- Dynamic navigation: added D* Lite repair, frame-budgeted repair steps,
  repair traces, moving starts, and linear-time stale-queue recovery.
- Verification: expanded the deterministic regression suite to 58 tests and
  kept cross-target check, format, metadata, test, demo, and benchmark gates in
  CI.

The corresponding commits remain individually reviewable in the public Git
history rather than being combined into a final import.

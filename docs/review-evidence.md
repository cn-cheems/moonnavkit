# Review Evidence

This page provides a short, reproducible evidence trail for maintainers and
contest reviewers.

## What the repository contains

- 26 MoonBit source and test files (about 3,774 non-generated source lines at
  the time of this update).
- 58 deterministic unit and regression tests, including static search,
  weighted graphs, flow fields, clearance routing, compression, D* Lite map
  updates, frame-budgeted repair, moving starts, and queue-rebuild recovery.
- Runnable commands: `moon run cmd/main` for a compact walkthrough and
  `moon run cmd/bench` for stable CSV-style comparison data.
- Cross-platform CI on Linux, macOS, and Windows. It checks all targets,
  formatting, generated API metadata, tests, and the deterministic commands.

## Reproduce the checks

```sh
moon check --target all
moon fmt --check
moon info
git diff --exit-code
moon test --target all
moon run cmd/main
moon run cmd/bench
```

Use `moon coverage analyze` to inspect uncovered branches. Coverage is treated
as a diagnostic tool: the tests assert concrete algorithmic outcomes rather
than relying on empty smoke tests or a percentage target alone.

## Scope and originality

MoonNavKit is an original MoonBit implementation, not a port of another
navigation project. Its public API, queue implementation, weighted-grid and
graph semantics, traces, exporters, flow fields, clearance layer, and dynamic
D* Lite integration are maintained in this repository under Apache-2.0.

The project does reference established algorithms such as BFS, Dijkstra, A*,
flow fields, and D* Lite. These are algorithmic techniques, not imported source
code. [Related Work](related-work.md) documents the ecosystem scan, comparable
MoonBit packages, and deliberate boundary.

## Development history

The Git history records the project foundation on 2026-06-01, public issue/PR
work for benchmarks and Graphviz export in June, algorithmic work in early
July, then clearance, compression, dynamic D* Lite, frame budgets, moving
starts, and queue recovery in separate commits. See
[tracking-log.md](tracking-log.md) and `git log --reverse --oneline`.

This chronology is intentionally preserved instead of squashing feature work
into one deadline commit.

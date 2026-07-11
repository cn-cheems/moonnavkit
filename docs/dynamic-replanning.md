# Dynamic Replanning

`DynamicGridPlanner` is MoonNavKit's stateful planner for a changing,
four-direction weighted `GridMap`. It implements D* Lite: the first `replan`
builds reverse shortest-path state from the goal, while later repairs reuse that
state after local map changes.

## Intended use

- Game agents reacting to doors, temporary obstacles, or terrain changes.
- Discrete simulations with a stable origin and destination.
- Teaching tools that compare incremental repair with restarting Dijkstra.

## API contract

1. Create one planner with a `GridMap`, initial `start`, and fixed `goal`.
2. Call `replan` to obtain the first optimal route.
3. Apply any number of `set_blocked`, `set_open`, or positive `set_weight`
   updates to the planner.
4. Call `replan` again; its `PathResult` is optimal for the current map.

When the agent advances, call `move_start(next_start)` before its next repair.
The planner updates D* Lite's key modifier and retains the reverse shortest-path
state. Invalid or blocked starts are ignored. Changing the goal still requires a
new planner.

For a frame-limited simulation, replace the final step with repeated
`replan_step(max_expansions)` calls. It returns `Pending(repaired_vertices)`
until the repair completes, then `Ready(PathResult)`. The planner retains state
between calls, so callers must not change the map while a repair is pending.

`repair_trace` records each processed vertex in deterministic order. Its JSON
representation lets a visualizer compare incremental work with a one-shot
search without adding a rendering dependency to the core library.

The planner owns mutable search state. It does not support moving the goal,
diagonal movement, negative costs, concurrent mutation, external
mutation of the returned `GridMap`, shared multi-agent repair state,
incremental clearance updates, or incremental path smoothing. Create a new
planner when an endpoint changes.

## Evidence

`moon run cmd/bench` includes `dynamic-32x32`. It records a first Dijkstra
route, the first D* Lite route, a D* Lite repair after blocking a cell on that
route, and a fresh Dijkstra result after the same update. The repaired and fresh
routes must have identical `found` and `cost` fields; `visited` makes their work
visible without claiming a timing result that varies across machines.

The unit tests cover an initial route, a blocked-route repair, a weight change,
and a no-path update. They compare every successful repair with a fresh
`GridMap::dijkstra` result.

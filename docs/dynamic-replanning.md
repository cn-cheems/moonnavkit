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

1. Create one planner with a `GridMap`, fixed `start`, and fixed `goal`.
2. Call `replan` to obtain the first optimal route.
3. Apply any number of `set_blocked`, `set_open`, or positive `set_weight`
   updates to the planner.
4. Call `replan` again; its `PathResult` is optimal for the current map.

The planner owns mutable search state. It does not support moving the start or
goal, diagonal movement, negative costs, concurrent mutation, or external
mutation of the returned `GridMap`. Create a new planner when an endpoint
changes.

## Evidence

`moon run cmd/bench` includes `dynamic-32x32`. It records a first Dijkstra
route, the first D* Lite route, a D* Lite repair after blocking a cell on that
route, and a fresh Dijkstra result after the same update. The repaired and fresh
routes must have identical `found` and `cost` fields; `visited` makes their work
visible without claiming a timing result that varies across machines.

The unit tests cover an initial route, a blocked-route repair, a weight change,
and a no-path update. They compare every successful repair with a fresh
`GridMap::dijkstra` result.

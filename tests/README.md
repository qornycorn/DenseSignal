# Dispatch regression tests

Run from the repository root using the pinned LuneBlox runtime:

```sh
luneblox run tests/dispatch.luneblox.luau native
luneblox run tests/dispatch.luneblox.luau interpreted
luneblox run tests/suite.luneblox.luau
luneblox run benchmarks/performance.luneblox.luau native
luneblox run benchmarks/benchmark.extended.luneblox.luau native smoke
```

Dispatch tests read `src/repstorage/DenseSignal/DenseSignal.luau` by default.
The suite regression checks loading from `ReplicatedStorage.shared.DenseSignal`
even when a stale benchmark-local copy exists, plus FastSignal.Immediate selection.

The regression suite fails immediately on an unmet expectation. Its 18 groups cover removal
of pending callbacks, clear/reconnect, nested Fire/Once, callback errors, suspended
dispatch, Wait payloads, transitions between small and protected dispatch, and
1,000 deterministic mutation scenarios with up to 40 initial listeners. The original
source in `DenseSignal.before.luau` is a frozen comparison fixture, not a second
supported implementation; it fails the first regression test.

## Behavior

- A disconnected listener is skipped if it has not run yet.
- Listeners added during Fire participate in the next Fire, including an explicit
  nested Fire, but not the dispatch already in progress.
- DisconnectAll removes pending listeners from existing dispatches. Connections
  created afterward remain usable by subsequent fires.
- Callback errors propagate synchronously and stop that Fire. Internal dispatch
  state is restored so the signal remains usable.
- A yielding callback suspends its Fire caller. Listener order is not a public
  guarantee: disconnection may reorder the dense array.

## Performance design and measured tradeoffs

Normal disconnect still uses O(1) swap-remove. During protected dispatch, removal
replaces a callback with a shared no-op and queues its slot in amortized O(1).
When the last protected dispatch returns, O(k) cleanup removes the k queued holes.
The protected hot loop still invokes callback functions directly; it does not
clone arrays, allocate a coroutine, or test connection state for every listener.

Zero/one listeners need no iteration bookkeeping. Two listeners use a local
snapshot plus a connection-identity check for the pending callback. Dispatches
with 3–12 slots snapshot pending connections into a bounded set of stack locals.
Each connection is checked before calling its current callback, so disconnected
listeners are skipped and newly connected listeners cannot enter that dispatch.
This path needs no heap snapshot or cleanup after an error. Larger dispatches
use a shared protected helper to restore state after errors. Tracking
is initialized lazily, preserving the 208-byte fresh empty-signal footprint;
signals that use the protected path acquire extra bookkeeping storage.

The [paired native comparison](../benchmarks/benchmark.fire.native.md) rotates the
previous mutation-safe source, current source, and FastSignal in one process over
31 measured rounds. Ten listeners improved from about 298 to 262 ns (median
paired change -11.3%); the checked-payload case improved from 440 to 396 ns (-10%).
Zero/two listeners and 100/1,000 listeners remained close to their baseline.
The [interpreted comparison](../benchmarks/benchmark.fire.interpreted.md) shows
the tradeoff: the same ten-listener workloads were approximately 10–15% slower.
This optimization targets native execution, not a speedup in every runtime mode.
These are run-specific results, not guarantees.

The callback work differs from the extended benchmark, so compare before/after
within this suite rather than comparing absolute times between suites. Reports
retain source hashes, raw timings and P10–P90 batch-average ranges; noisy small
differences are not evidence of a universal win.

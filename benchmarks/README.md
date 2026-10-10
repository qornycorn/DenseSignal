# LuneBlox benchmarks

Run from the **repository root**. Scripts and default output files live here;
signal implementations remain in the root directory.

```sh
# Compare the current source against the previous mutation-safe implementation.
luneblox run benchmarks/performance.luneblox.luau native
luneblox run benchmarks/performance.luneblox.luau interpreted

# Full four-library comparison; use smoke for quick validation.
luneblox run benchmarks/benchmark.extended.luneblox.luau native full
luneblox run benchmarks/benchmark.extended.luneblox.luau native smoke

# Original eight-workload suite.
luneblox run benchmarks/benchmark.luneblox.luau native full
```

The performance runner accepts an optional output prefix and baseline source as
its second and third arguments. Other runners accept an output prefix/path as
their third argument. Existing outputs are never overwritten. Run benchmarks
sequentially and avoid other CPU-intensive work while measuring.

## Fire optimization results

[Native comparison](benchmark.fire.native.md) ·
[Native raw samples](benchmark.fire.native.json) ·
[Interpreted comparison](benchmark.fire.interpreted.md)

The baseline in `fixtures/DenseSignal.before-fire-optimization.luau` already has
the mutation-safety fix. It is a frozen measurement fixture, not production code.
The current source snapshots 3–12 pending listener slots into stack locals, checks
connection identity before each invocation, and leaves the larger dispatch path
unchanged. No per-Fire snapshot table or coroutine is allocated.

In the captured native run, ten-listener dispatch improved from 297.6 to 262.0
ns/op (-11.3% median paired change). A callback with payload checks improved from
440.0 to 395.9 ns/op (-10.0%). Cases with 0–2 and 100–1,000 listeners remained
within about 1% of their paired baseline. Interpreted execution is a tradeoff:
the ten-listener cases were approximately 10–15% slower. This is an optimization
for native execution, not an across-the-board performance claim.

## Measurement details

The paired runner uses 3 warmups and 31 measured rounds, rotating Before, After,
and FastSignal within each round. Adaptive calibration targets 2 ms per batch,
subject to an iteration cap. Medians and P10–P90 describe batch-average ns/op;
paired changes compare After/Before within each round. Ranges are not individual
event latency or statistical confidence intervals. A warm Fire precedes timing,
so this measures steady-state dispatch rather than the first-use allocation.

The extended runner covers 29 workloads: creation, 0–1,000 listeners, 0–32
arguments, connection churn, oldest/middle/newest removal, and one replacement
followed by 1/10/100 fires. Mixed results are per whole cycle, not per Fire.
Full mode uses 3 repetitions of 15 samples after warmups. An asterisk means
calibration hit a cap before the target duration; treat small differences there
cautiously. Setup, forced GC, validation, and cleanup are outside timed regions;
callback work and natural GC are included.

Memory rows are retained VM heap deltas, not total allocation volume or peak RSS.
Full-GC durations cover the whole VM and are not predicted in-game pause times.
Behavioral failures are reported separately and do not abort the extended timing
suite. Use `tests/dispatch.luneblox.luau` for a regression suite that fails on
incorrect behavior.

JSON reports preserve raw timing samples and source hashes. Compare within the
same suite: callback work differs between runners. Native codegen is requested
consistently, but this does not prove every function compiled natively or predict
performance in a Roblox experience.

# LuneBlox benchmarks

Run from the **repository root**. Scripts and default output files live here.
`modules.luneblox.luau` centralizes the implementation paths: DenseSignal comes from
`src/repstorage/DenseSignal/DenseSignal.luau`, and comparison signals come from
`src/plrclient/benchmarks/`. FastSignal uses `Immediate.luau` with its `Deferred.luau`
dependency; both sources are included in its source fingerprint. All dependencies
use the selected native/interpreted mode and are loaded before measurements.

In Studio, the suite loads `ReplicatedStorage.shared.DenseSignal`, as mapped by
`default.project.json`, rather than the benchmark-local copy.

```sh
# Compare the current source against the previous mutation-safe implementation.
luneblox run benchmarks/performance.luneblox.luau native
luneblox run benchmarks/performance.luneblox.luau interpreted

# Full four-library comparison; use smoke for quick validation.
luneblox run benchmarks/benchmark.extended.luneblox.luau native full
luneblox run benchmarks/benchmark.extended.luneblox.luau native smoke

# Original eight-workload suite.
luneblox run benchmarks/benchmark.luneblox.luau interpreted full
```

The performance runner accepts an optional output prefix and baseline source as
its second and third arguments. Other runners accept an output prefix/path as
their third argument. Existing outputs are never overwritten. Run benchmarks
sequentially and avoid other CPU-intensive work while measuring.

## Latest benchmark results

The **interpreted full** eight-workload run uses LuneBlox `0.10.16+740`,
100 handlers and 32 arguments, with **3,240 validated executions**.
The seven-workload arithmetic means are 1.5 µs for DenseSignal, 14.9 µs for
FastSignal.Immediate, 14.3 µs for GoodSignal, and 14.1 µs for SimpleSignal.
These means are not an overall performance score.
[Summary table](../README.md#benchmark) ·
[Raw interpreted results](benchmark.interpreted.full.1791703334.json)

The **native full** detailed run covers 29 workloads, P10–P90 timing ranges,
behavioral probes, retained memory and GC diagnostics. All four implementations
passed the nine behavioral checks. DenseSignal retains 208 bytes per empty signal;
FastSignal, GoodSignal and SimpleSignal retain 112, 80 and 80 bytes respectively.
[Detailed report](benchmark.extended.native.full.1791703372.md) ·
[Raw native results](benchmark.extended.native.full.1791703372.json)

The two runs use different execution modes and callback workloads; compare
implementations within each run. FastSignal is the current vendored Immediate
variant, and its fingerprint includes the Deferred module that supplies shared methods.

## Before/after comparison

The baseline in `fixtures/DenseSignal.before-fire-optimization.luau` already has
the mutation-safety fix. It is a frozen measurement fixture, not production code.
The current source snapshots 3–12 pending listener slots into stack locals, checks
connection identity before each invocation, and leaves the larger dispatch path
unchanged. No per-Fire snapshot table or coroutine is allocated.

Use `performance.luneblox.luau` to generate a paired before/after report for the
current source. The latest reports linked above compare the four implementations;
they do not measure improvement against this frozen baseline.

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

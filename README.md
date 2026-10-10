<div align="center">

# _DenseSignal_

**A synchronous Luau signal optimized for frequent event dispatch.**

Dense callback arrays · O(1) disconnection · Generic types

[Quick results](#benchmark) · [Extended benchmark →](benchmarks/benchmark.extended.native.full.1791661443.md)

</div>

---

## ✨ Why DenseSignal?

- **Built for frequent dispatch** — dense callback arrays keep callbacks compact.
- **O(1) disconnection** — disconnect without scanning the callback list.
- **Generic types** — typed event arguments for clearer APIs.
- **Synchronous execution** — callbacks run during dispatch.

## Installation

Download the `.rbxm` file from **Assets** on the
[latest release](https://github.com/qornycorn/DenseSignal/releases).

<a id="benchmark"></a>

## ⚡ Benchmark

**LuneBlox `0.10.16+740`** · Interpreted · Full suite

**100 handlers / 32 arguments** · Times in **µs**, lower is faster.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| CreateAndFire | 0.4 | 0.4 | 0.8 | 0.8 |
| ConnectAndDisconnect | 0.2 | 0.2 | 0.2 | 0.2 |
| FireWithNoConnections | 0.0 | 0.1 | 0.0 | 0.0 |
| Fire | 0.1 | 0.1 | 0.6 | 0.6 |
| FireManyArguments | 0.4 | 0.4 | 1.8 | 1.8 |
| FireManyHandlers | **3.9** | 4.2 | 56.9 | 57.4 |
| FireYieldingHandler | N/A | N/A | 0.9 | 0.9 |
| WaitOnEvent | 1.6 | 1.6 | 2.2 | 2.2 |
| Average¹ | 1.0 | 1.0 | 8.9 | 9.0 |

3,240 validated executions · [Raw results](benchmarks/benchmark.interpreted.full.1791661822.json)

### Native · extended highlights

Selected medians from the **native full** suite, converted to **µs**.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| Fire · 10 listeners | 0.438 | 0.436 | 4.637 | 4.672 |
| Fire · 100 listeners | **3.723** | 3.912 | 45.787 | 46.150 |
| Fire · 1,000 listeners | **36.140** | 38.755 | 462.257 | 467.595 |
| Fire · 32 arguments | **0.071** | 0.111 | 1.358 | 1.360 |

DenseSignal passed all nine behavioral checks in this run. Empty signals retained
208 bytes each; the full report includes connection memory and GC measurements.

**[View extended benchmark →](benchmarks/benchmark.extended.native.full.1791661443.md)**
29 workloads, P10–P90 ranges, behavioral checks, memory, and methodology ·
[Raw JSON](benchmarks/benchmark.extended.native.full.1791661443.json)

<sub>¹ Arithmetic mean of 7 common workloads, not an overall performance score.
0.0 µs means below 0.05 µs after rounding. N/A means no result reported.
Rounded ties do not imply identical timings. Modes and callback work differ between
suites; compare libraries within each table. Results vary by workload and environment.</sub>

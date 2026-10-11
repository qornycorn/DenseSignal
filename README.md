<div align="center">

# _DenseSignal_

**A synchronous Luau signal optimized for frequent event dispatch.**

Dense callback arrays · O(1) disconnection · Generic types

[Quick results](#benchmark) · [Detailed benchmark →](benchmarks/benchmark.extended.native.full.1791703372.md)

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
| CreateAndFire | 0.7 | 1.7 | 1.4 | 1.4 |
| ConnectAndDisconnect | 0.4 | 0.5 | 0.3 | 0.3 |
| FireWithNoConnections | 0.1 | 0.1 | 0.0 | 0.0 |
| Fire | 0.1 | 1.0 | 1.0 | 1.0 |
| FireManyArguments | 0.6 | 3.1 | 3.2 | 3.1 |
| FireManyHandlers | **6.2** | 94.1 | 91.1 | 89.2 |
| FireYieldingHandler | N/A | N/A | 1.4 | 1.4 |
| WaitOnEvent | 2.5 | 4.0 | 3.4 | 3.4 |
| Average¹ | 1.5 | 14.9 | 14.3 | 14.1 |

3,240 validated executions · [Raw results](benchmarks/benchmark.interpreted.full.1791703334.json)

FastSignal uses its **Immediate** variant. DenseSignal is loaded from the shared
production module; implementation paths and source fingerprints are recorded in the JSON.

### Detailed benchmark · native full

Selected medians from the **native full** suite, converted to **µs**.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| Fire · 10 listeners | **0.713** | 7.858 | 7.686 | 7.823 |
| Fire · 100 listeners | **6.173** | 77.738 | 76.385 | 76.690 |
| Fire · 1,000 listeners | **57.583** | 763.119 | 765.734 | 764.030 |
| Fire · 32 arguments | **0.117** | 2.188 | 2.161 | 2.178 |

All four implementations passed the nine behavioral checks in this run. DenseSignal
handlers suspend the Fire caller when yielding; FastSignal.Immediate, GoodSignal,
and SimpleSignal handlers yield independently. Empty DenseSignal instances retained
208 bytes each; the full report includes connection memory and GC measurements.

**[View detailed benchmark →](benchmarks/benchmark.extended.native.full.1791703372.md)**
29 workloads, P10–P90 ranges, behavioral checks, memory, and methodology ·
[Raw JSON](benchmarks/benchmark.extended.native.full.1791703372.json)

<sub>¹ Arithmetic mean of 7 common workloads, not an overall performance score.
0.0 µs means below 0.05 µs after rounding. N/A means no result reported.
Rounded ties do not imply identical timings. Modes and callback work differ between
suites; compare libraries within each table. Results vary by workload and environment.</sub>

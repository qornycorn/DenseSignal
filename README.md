<div align="center">

<<<<<<< HEAD
# _DenseSignal_
=======
# DenseSignal
>>>>>>> 21e0eb9918de7f75315912048a4564b9ed4cfc06

**A synchronous Luau signal optimized for frequent event dispatch.**

Dense callback arrays · O(1) disconnection · Generic types

<<<<<<< HEAD
[Quick results](#benchmark) · [Extended benchmark →](benchmarks/benchmark.extended.native.full.1791661443.md)

=======
>>>>>>> 21e0eb9918de7f75315912048a4564b9ed4cfc06
</div>

---

## ✨ Why DenseSignal?

- **Built for frequent dispatch** — dense callback arrays keep callbacks compact.
- **O(1) disconnection** — disconnect without scanning the callback list.
- **Generic types** — typed event arguments for clearer APIs.
- **Synchronous execution** — callbacks run during dispatch.

<<<<<<< HEAD
<a id="benchmark"></a>

## ⚡ Benchmark

**LuneBlox `0.10.16+740`** · Interpreted · Full suite

=======
## ⚡ Benchmark

**LuneBlox `0.10.16+740`** · Native · Full suite  
>>>>>>> 21e0eb9918de7f75315912048a4564b9ed4cfc06
**100 handlers / 32 arguments** · Times in **µs**, lower is faster.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
<<<<<<< HEAD
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

## Installation

To get the `.rbxm` file, open the, open the [DenseSignal's releases page](https://github.com/qornycorn/DenseSignal/releases) and download it from the latest release under Assets.
=======
| CreateAndFire | 0.3 | **0.2** | 0.6 | 0.6 |
| ConnectAndDisconnect | 0.1 | 0.1 | 0.1 | 0.1 |
| FireWithNoConnections | 0.0 | 0.0 | 0.0 | 0.0 |
| Fire | **0.0** | 0.1 | 0.5 | 0.5 |
| FireManyArguments | **0.3** | 0.4 | 1.6 | 1.6 |
| FireManyHandlers | **1.9** | 2.2 | 45.9 | 46.0 |
| FireYieldingHandler | N/A | N/A | 0.7 | 0.7 |
| WaitOnEvent | **1.3** | 1.4 | 1.9 | 1.8 |
| Average¹ | **0.6** | **0.6** | 7.2 | 7.2 |

> **Dispatch highlights:** DenseSignal takes ~14% less time than FastSignal
> with 100 handlers and 25% less time with 32 arguments.
> The 100-handler workload takes ~24× less time than GoodSignal and SimpleSignal.

FastSignal leads CreateAndFire. DenseSignal leads Fire, FireManyArguments,
FireManyHandlers, and WaitOnEvent in this run.

<sub>¹ Arithmetic mean of 7 common workloads, not an overall performance score.
0.0 µs means below 0.05 µs after rounding. N/A means no result reported.
Comparisons use rounded timings from this run; results vary by workload and environment.</sub>
>>>>>>> 21e0eb9918de7f75315912048a4564b9ed4cfc06

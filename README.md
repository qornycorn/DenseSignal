<div align="center">

# DenseSignal

**A synchronous Luau signal optimized for frequent event dispatch.**

Dense callback arrays · O(1) disconnection · Generic types

</div>

---

## ✨ Why DenseSignal?

- **Built for frequent dispatch** — dense callback arrays keep callbacks compact.
- **O(1) disconnection** — disconnect without scanning the callback list.
- **Generic types** — typed event arguments for clearer APIs.
- **Synchronous execution** — callbacks run during dispatch.

## ⚡ Benchmark

**LuneBlox `0.10.16+740`** · Native · Full suite  
**100 handlers / 32 arguments** · Times in **µs**, lower is faster.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
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
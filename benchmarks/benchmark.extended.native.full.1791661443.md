# Extended signal benchmark

[← README summary](../README.md#benchmark) · [Raw JSON](benchmark.extended.native.full.1791661443.json)

LuneBlox 0.10.16+740 · native · full · windows/x86_64

## Timing

Median of repetition medians, **nanoseconds per operation**. Brackets: P10–P90 of batch averages. Lower is faster.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| CreateOnly | 147.244 [137.769–165.558] | 33.142 [30.773–38.884]* | 57.974 [51.356–70.303]* | 56.467 [52.697–62.899] |
| CreateAndFire | 344.690 [321.801–410.814] | 248.926 [234.171–324.812] | 645.239 [616.539–715.657] | 633.264 [581.144–698.176] |
| Fire/H0 | 19.977 [18.990–21.137] | 29.155 [27.835–31.039] | 18.132 [17.477–19.222] | 18.058 [17.495–19.038] |
| Fire/H1 | 57.013 [55.021–59.150] | 83.617 [80.807–87.297] | 478.648 [473.586–497.976] | 484.596 [468.786–502.175] |
| Fire/H10 | 437.866 [424.443–447.314] | 435.632 [418.994–451.616] | 4636.951 [4555.554–4853.259] | 4672.351 [4558.152–4826.653] |
| Fire/H100 | 3723.281 [3597.281–3786.453] | 3912.422 [3774.594–4000.047] | 45786.641 [45041.688–46656.047] | 46150.391 [44973.187–46558.016] |
| Fire/H1000 | 36139.844 [35098.750–37488.594] | 38754.688 [36767.500–40092.813] | 462257.031 [455666.719–477798.906] | 467594.531 [459291.250–476333.906] |
| Arguments/A0 | 45.641 [44.002–47.547] | 74.927 [72.092–82.084] | 448.967 [440.066–483.135] | 450.661 [436.108–462.397] |
| Arguments/A1 | 57.269 [54.564–60.246] | 83.804 [81.798–88.350] | 492.299 [477.220–501.220] | 491.130 [479.850–507.746] |
| Arguments/A4 | 58.136 [56.343–62.150] | 85.095 [82.107–90.561] | 577.792 [564.781–602.344] | 580.893 [566.115–601.043] |
| Arguments/A8 | 59.981 [57.968–63.206] | 88.342 [84.760–93.073] | 678.549 [664.758–702.985] | 683.707 [663.174–695.376] |
| Arguments/A16 | 64.502 [61.344–69.074] | 94.063 [88.324–101.102] | 937.141 [901.110–966.014] | 938.243 [897.584–981.013] |
| Arguments/A32 | 70.863 [68.396–75.189] | 111.092 [107.256–117.175] | 1358.459 [1344.376–1382.854] | 1359.830 [1325.333–1395.835] |
| ConnectDisconnect/H0 | 128.979 [122.554–160.956] | 100.284 [93.867–120.635] | 114.609 [108.696–133.021] | 115.506 [107.866–135.699] |
| ConnectDisconnect/H10 | 131.689 [123.922–156.910] | 153.125 [145.692–183.234] | 119.522 [112.926–138.218] | 117.999 [112.959–135.233] |
| ConnectDisconnect/H100 | 131.755 [126.572–142.517] | 202.778 [187.098–214.488] | 117.400 [113.613–126.663] | 120.723 [112.231–127.140] |
| ConnectDisconnect/H1000 | 133.743 [123.414–143.391] | 954.633 [923.225–1035.494] | 122.879 [118.287–128.760] | 119.171 [116.876–129.547] |
| Disconnect/H10/oldest | 177.100 [130.376–206.594]* | 102.360 [85.152–125.272]* | 260.650 [201.052–310.558]* | 281.260 [217.196–317.684]* |
| Disconnect/H10/middle | 193.010 [143.714–218.902]* | 104.990 [89.894–148.154]* | 206.010 [154.818–240.478]* | 210.750 [154.252–236.428]* |
| Disconnect/H10/newest | 172.690 [122.816–209.096]* | 111.910 [91.046–122.882]* | 100.800 [73.708–132.914]* | 108.570 [77.990–127.892]* |
| Disconnect/H100/oldest | 336.900 [292.720–424.800]* | 159.200 [144.100–190.280]* | 1580.200 [1447.820–2156.140]* | 2043.500 [1470.900–2379.540]* |
| Disconnect/H100/middle | 401.900 [359.220–476.720]* | 169.900 [151.520–219.420]* | 1259.700 [937.640–1478.840]* | 1311.300 [952.520–1495.280]* |
| Disconnect/H100/newest | 338.800 [273.340–401.760]* | 193.600 [162.360–271.660]* | 159.100 [146.960–235.480]* | 193.100 [160.160–251.560]* |
| Disconnect/H1000/oldest | 464.000 [402.200–624.000]* | 242.000 [211.400–335.000]* | 14166.000 [12408.800–20344.600]* | 17261.000 [12901.600–20689.400]* |
| Disconnect/H1000/middle | 507.000 [456.400–606.200]* | 313.000 [259.000–410.200]* | 8648.000 [6461.400–10239.000]* | 8787.000 [6727.400–10666.000]* |
| Disconnect/H1000/newest | 408.000 [372.400–459.000]* | 264.000 [229.400–382.200]* | 209.000 [187.800–263.200]* | 238.000 [197.800–304.600]* |
| Mixed/H100/F1 | 2074.805 [1928.867–2199.609] | 2620.195 [2444.242–2748.648] | 45901.875 [44834.086–46935.547] | 46031.992 [45056.680–47308.344] |
| Mixed/H100/F10 | 19316.406 [18037.422–21458.672] | 23858.594 [22119.531–25305.469] | 467328.906 [449986.719–494886.563] | 467889.062 [450601.563–492897.656] |
| Mixed/H100/F100 | 190806.250 [178771.250–201588.750] | 216662.500 [209611.250–231226.250] | 4518006.250 [4368073.750–4661188.750] | 4546125.000 [4405626.250–4653655.000] |

*Calibration hit the fixture/iteration cap before the target duration; interpret small differences cautiously. Mixed reports one cycle (one replacement plus F fires), not one Fire. Create includes storing the new object. See benchmarks/README.md for workload definitions.*

## Behavioral probes

FAIL means the stated expectation was not met; it does not establish that the library promises that behavior.

| Probe | Module | Result |
|:---|:---|:---|
| SelfDisconnect | DenseSignal | PASS |
| SelfDisconnect | FastSignal | PASS |
| SelfDisconnect | GoodSignal | PASS |
| SelfDisconnect | SimpleSignal | PASS |
| DisconnectOther | DenseSignal | PASS |
| DisconnectOther | FastSignal | PASS |
| DisconnectOther | GoodSignal | PASS |
| DisconnectOther | SimpleSignal | PASS |
| DisconnectOnePending | DenseSignal | PASS |
| DisconnectOnePending | FastSignal | PASS |
| DisconnectOnePending | GoodSignal | PASS |
| DisconnectOnePending | SimpleSignal | PASS |
| ConnectDuringFire | DenseSignal | PASS |
| ConnectDuringFire | FastSignal | PASS |
| ConnectDuringFire | GoodSignal | PASS |
| ConnectDuringFire | SimpleSignal | PASS |
| DisconnectAllDuringFire | DenseSignal | PASS |
| DisconnectAllDuringFire | FastSignal | PASS |
| DisconnectAllDuringFire | GoodSignal | PASS |
| DisconnectAllDuringFire | SimpleSignal | PASS |
| RecursiveFire | DenseSignal | PASS |
| RecursiveFire | FastSignal | PASS |
| RecursiveFire | GoodSignal | PASS |
| RecursiveFire | SimpleSignal | PASS |
| OnceRecursive | DenseSignal | PASS |
| OnceRecursive | FastSignal | PASS |
| OnceRecursive | GoodSignal | PASS |
| OnceRecursive | SimpleSignal | PASS |
| StaleConnection | DenseSignal | PASS |
| StaleConnection | FastSignal | PASS |
| StaleConnection | GoodSignal | PASS |
| StaleConnection | SimpleSignal | PASS |
| NilPayload | DenseSignal | PASS |
| NilPayload | FastSignal | PASS |
| NilPayload | GoodSignal | PASS |
| NilPayload | SimpleSignal | PASS |
| YieldBehavior | DenseSignal | Handler suspends Fire caller (synchronous) |
| YieldBehavior | FastSignal | Handler suspends Fire caller (synchronous) |
| YieldBehavior | GoodSignal | Handler yields independently |
| YieldBehavior | SimpleSignal | Handler yields independently |

## Memory

Median retained VM heap bytes per object/operation after full GC. Connection rows include amortized signal storage. Churn measures residual heap growth, **not allocation volume**.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| Signals | 208.000 | 48.000 | 80.000 | 80.000 |
| Connections | 164.429 | 164.429 | 176.000 | 176.000 |
| Churn | 0.003 | 0.003 | 0.000 | 0.000 |

Full-GC duration and raw heap/timing samples are in the companion JSON. Full-GC duration is a whole-VM diagnostic, not a production GC pause prediction.

## Method

Rotating module order; adaptive calibration targets a minimum batch duration on every module. Fresh fixtures, full GC before timed batches; natural GC remains enabled inside batches. Setup, explicit GC, verification and cleanup excluded. Callback work included. All modules O2 with matching codegen request, not proof that every function compiled natively. Raw batch seconds retained. P10/P90 describe batch-average ns/op, not individual-call latency. No aggregate performance score.

Source SHA-256 fingerprints and runner settings are saved in the companion JSON. These local vendored implementations are compared, not every library using these names. This LuneBlox run is not an in-game Roblox measurement.

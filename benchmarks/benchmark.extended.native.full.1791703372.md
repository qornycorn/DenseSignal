# Extended signal benchmark

LuneBlox 0.10.16+740 · native · full · windows/x86_64

## Timing

Median of repetition medians, **nanoseconds per operation**. Brackets: P10–P90 of batch averages. Lower is faster.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| CreateOnly | 244.592 [220.425–279.267] | 118.246 [106.159–137.872] | 92.780 [82.493–111.444] | 89.938 [78.779–109.387] |
| CreateAndFire | 519.019 [472.190–644.158] | 1435.620 [1299.294–1679.302] | 1059.326 [995.947–1297.676] | 1103.638 [961.638–1310.447] |
| Fire/H0 | 34.482 [31.793–38.969] | 51.546 [48.798–61.642] | 30.476 [29.055–33.005] | 31.680 [29.978–34.255] |
| Fire/H1 | 95.297 [87.598–108.063] | 842.264 [792.708–918.107] | 832.687 [765.151–910.905] | 827.231 [773.335–896.165] |
| Fire/H10 | 712.512 [664.570–770.063] | 7857.532 [7371.345–8458.945] | 7686.157 [7363.943–8193.079] | 7823.340 [7393.550–8227.776] |
| Fire/H100 | 6173.437 [5720.094–6671.094] | 77738.437 [74111.156–82771.094] | 76384.688 [73197.844–84370.844] | 76690.000 [74086.281–82791.000] |
| Fire/H1000 | 57582.812 [54851.875–62660.000] | 763118.750 [725003.125–819965.938] | 765734.375 [723609.687–806667.500] | 764029.688 [720233.438–806574.375] |
| Arguments/A0 | 71.484 [65.816–77.823] | 757.841 [712.873–803.325] | 735.562 [702.291–772.164] | 735.735 [683.720–796.149] |
| Arguments/A1 | 90.790 [84.977–97.985] | 809.454 [758.734–870.939] | 791.809 [747.004–869.081] | 801.428 [743.366–864.480] |
| Arguments/A4 | 92.072 [85.848–103.674] | 937.692 [882.062–997.225] | 920.764 [876.347–997.509] | 905.875 [871.029–994.043] |
| Arguments/A8 | 94.943 [87.031–104.111] | 1107.922 [1059.672–1181.213] | 1100.067 [1052.405–1171.932] | 1092.493 [1021.394–1159.221] |
| Arguments/A16 | 99.033 [94.058–109.974] | 1472.983 [1406.284–1561.013] | 1486.017 [1424.733–1594.631] | 1452.872 [1397.422–1550.295] |
| Arguments/A32 | 117.075 [108.166–124.856] | 2187.750 [2061.110–2366.078] | 2160.855 [2068.619–2262.969] | 2177.661 [2072.288–2297.628] |
| ConnectDisconnect/H0 | 213.135 [196.616–237.998] | 308.292 [288.344–343.509] | 186.478 [168.694–211.910] | 182.135 [170.435–200.558] |
| ConnectDisconnect/H10 | 215.723 [205.461–246.133] | 278.882 [257.938–318.236] | 187.201 [174.778–213.009] | 184.906 [170.948–206.493] |
| ConnectDisconnect/H100 | 212.402 [197.826–228.242] | 280.996 [257.774–306.616] | 191.860 [176.985–219.673] | 189.512 [176.194–207.009] |
| ConnectDisconnect/H1000 | 223.044 [206.018–239.039] | 281.567 [256.224–321.350] | 188.239 [173.346–211.625] | 191.391 [175.692–215.663] |
| Disconnect/H10/oldest | 206.850 [171.062–264.040]* | 204.770 [175.272–256.636]* | 311.420 [286.370–404.228] | 314.240 [286.898–382.344] |
| Disconnect/H10/middle | 211.180 [180.128–257.784]* | 234.010 [200.026–299.216]* | 229.620 [213.750–303.920]* | 225.000 [204.506–263.452]* |
| Disconnect/H10/newest | 197.990 [176.534–243.640]* | 238.480 [201.960–327.916]* | 127.800 [116.310–154.224]* | 131.730 [111.236–174.320]* |
| Disconnect/H100/oldest | 470.800 [425.580–611.360]* | 368.100 [293.120–444.100]* | 2245.600 [2025.160–3192.140]* | 2167.600 [2024.160–2571.300]* |
| Disconnect/H100/middle | 562.400 [522.480–760.460]* | 383.800 [320.940–496.040]* | 1482.100 [1352.080–1857.680]* | 1529.400 [1381.880–1949.700]* |
| Disconnect/H100/newest | 444.100 [390.960–550.600]* | 375.400 [316.420–592.900]* | 259.600 [222.140–300.740]* | 261.800 [235.240–317.380]* |
| Disconnect/H1000/oldest | 732.000 [597.800–867.200]* | 473.000 [424.600–672.000]* | 19319.000 [17291.200–25670.200]* | 18477.000 [17046.400–24377.200]* |
| Disconnect/H1000/middle | 804.000 [734.600–1039.800]* | 516.000 [435.800–691.400]* | 9974.000 [9281.000–11935.600]* | 9957.000 [9234.400–12571.800]* |
| Disconnect/H1000/newest | 653.000 [539.800–807.200]* | 500.000 [439.800–941.000]* | 463.000 [326.400–542.800]* | 447.000 [391.600–837.400]* |
| Mixed/H100/F1 | 3039.688 [2909.203–3304.781] | 68513.828 [65660.516–72076.031] | 69228.125 [66590.844–73522.766] | 68276.563 [66166.078–70884.219] |
| Mixed/H100/F10 | 28154.687 [26446.250–30160.625] | 666656.250 [655507.031–700121.875] | 673852.344 [646322.187–714017.031] | 667288.281 [649266.250–710719.688] |
| Mixed/H100/F100 | 281356.250 [264772.500–308931.250] | 6854781.250 [6493168.750–7123166.250] | 6735018.750 [6531658.750–7228118.750] | 6888500.000 [6596778.750–7323927.500] |

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
| YieldBehavior | FastSignal | Handler yields independently |
| YieldBehavior | GoodSignal | Handler yields independently |
| YieldBehavior | SimpleSignal | Handler yields independently |

## Memory

Median retained VM heap bytes per object/operation after full GC. Connection rows include amortized signal storage. Churn measures residual heap growth, **not allocation volume**.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| Signals | 208.000 | 112.000 | 80.000 | 80.000 |
| Connections | 164.429 | 416.000 | 176.000 | 176.000 |
| Churn | 0.003 | 0.000 | 0.000 | 0.000 |

Full-GC duration and raw heap/timing samples are in the companion JSON. Full-GC duration is a whole-VM diagnostic, not a production GC pause prediction.

## Method

Rotating module order; adaptive calibration targets a minimum batch duration on every module. Fresh fixtures, full GC before timed batches; natural GC remains enabled inside batches. Setup, explicit GC, verification and cleanup excluded. Callback work included. All modules O2 with matching codegen request, not proof that every function compiled natively. Raw batch seconds retained. P10/P90 describe batch-average ns/op, not individual-call latency. No aggregate performance score.

Source SHA-256 fingerprints and runner settings are saved in the companion JSON. These local vendored implementations are compared, not every library using these names. This LuneBlox run is not an in-game Roblox measurement.

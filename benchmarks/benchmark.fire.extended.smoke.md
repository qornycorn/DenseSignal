# Extended signal benchmark

LuneBlox 0.10.16+740 · native · smoke · windows/x86_64

## Timing

Median of repetition medians, **nanoseconds per operation**. Brackets: P10–P90 of batch averages. Lower is faster.

| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |
|:---|---:|---:|---:|---:|
| CreateOnly | 145.886 [141.414–151.638] | 32.227 [30.762–32.725] | 48.260 [44.364–50.526] | 56.781 [44.261–57.181] |
| CreateAndFire | 278.906 [275.781–284.883] | 220.752 [217.197–255.713] | 626.855 [617.676–634.629] | 613.770 [612.285–625.098] |
| Fire/H0 | 20.831 [20.690–21.119] | 30.566 [29.663–32.256] | 19.464 [18.790–19.547] | 19.550 [18.778–19.554] |
| Fire/H1 | 60.461 [59.827–61.067] | 84.741 [84.243–85.063] | 513.733 [509.895–563.733] | 488.818 [488.271–512.051] |
| Fire/H10 | 464.453 [452.031–465.234] | 456.836 [449.336–458.320] | 4688.770 [4661.191–4890.488] | 4682.715 [4658.418–4821.309] |
| Fire/H100 | 3725.625 [3714.625–3749.625] | 3905.625 [3880.625–4026.125] | 46774.375 [46395.875–48551.375] | 46701.875 [46467.375–47476.375] |
| Fire/H1000 | 35418.750 [34658.750–38033.750] | 43231.250 [38961.250–43941.250] | 442881.250 [439846.250–462576.250] | 454562.500 [446592.500–471662.500] |
| Arguments/A0 | 46.631 [45.859–50.234] | 82.019 [75.457–82.625] | 446.375 [444.158–465.740] | 458.423 [450.864–459.780] |
| Arguments/A1 | 58.020 [56.643–58.567] | 85.840 [84.453–89.980] | 484.460 [479.353–495.095] | 487.866 [471.558–492.720] |
| Arguments/A4 | 56.458 [56.047–60.901] | 84.485 [82.698–86.497] | 551.062 [546.375–553.894] | 555.872 [541.731–578.704] |
| Arguments/A8 | 58.813 [58.657–65.649] | 90.723 [89.102–91.504] | 685.571 [680.356–707.661] | 674.072 [669.678–682.354] |
| Arguments/A16 | 86.072 [69.490–102.166] | 167.163 [108.843–200.688] | 1288.379 [1212.373–1451.494] | 1249.182 [1008.079–1438.918] |
| Arguments/A32 | 74.243 [73.579–75.142] | 111.182 [107.666–112.490] | 1414.526 [1392.046–1418.413] | 1384.961 [1371.660–1403.320] |
| ConnectDisconnect/H0 | 127.661 [126.489–131.274] | 97.778 [96.938–128.403] | 105.786 [105.122–141.821] | 106.128 [104.175–107.104] |
| ConnectDisconnect/H10 | 129.614 [129.380–130.103] | 168.799 [162.744–209.072] | 110.986 [109.482–156.963] | 167.480 [121.504–186.973] |
| ConnectDisconnect/H100 | 128.945 [127.414–159.102] | 215.195 [197.227–246.789] | 166.758 [134.727–182.133] | 125.937 [125.812–169.688] |
| ConnectDisconnect/H1000 | 128.369 [125.400–129.014] | 894.507 [886.519–899.116] | 121.875 [119.180–122.031] | 119.360 [118.774–119.380] |
| Disconnect/H10/oldest | 160.693 [122.021–162.607] | 89.771 [80.962–124.321] | 250.952 [235.249–271.460] | 260.474 [256.860–278.306] |
| Disconnect/H10/middle | 202.246 [153.428–211.250] | 102.625 [99.578–122.234] | 163.074 [153.308–225.876] | 213.013 [177.524–217.495] |
| Disconnect/H10/newest | 154.272 [140.923–278.657] | 126.587 [105.474–187.603] | 148.218 [120.376–216.431] | 160.083 [94.868–164.409] |
| Disconnect/H100/oldest | 812.300 [694.860–845.180] | 377.900 [351.820–408.620] | 3144.000 [3063.840–3883.760] | 3043.100 [3033.100–3583.340] |
| Disconnect/H100/middle | 920.600 [808.200–958.040] | 404.500 [344.180–583.220] | 1874.200 [1866.200–2060.520] | 2016.500 [1808.820–2078.340] |
| Disconnect/H100/newest | 862.300 [761.180–960.380] | 483.600 [387.920–497.680] | 304.200 [269.080–356.440]* | 392.100 [327.860–413.780] |
| Disconnect/H1000/oldest | 1022.000 [894.000–1043.600]* | 643.000 [504.600–699.000]* | 28950.000 [27388.400–32858.800] | 38055.000 [28331.000–38563.800] |
| Disconnect/H1000/middle | 1411.000 [1071.000–1467.800]* | 554.000 [546.000–702.800]* | 21484.000 [14340.800–21765.600] | 15684.000 [14410.400–19975.200] |
| Disconnect/H1000/newest | 1135.000 [1015.000–1487.000]* | 567.000 [491.000–639.800]* | 493.000 [375.400–501.800]* | 713.000 [661.000–790.600]* |
| Mixed/H100/F1 | 5867.500 [5664.500–9941.500] | 7006.250 [6954.250–10662.250] | 131487.500 [127614.500–140215.500] | 172671.250 [131574.250–184200.250] |
| Mixed/H100/F10 | 52850.000 [52750.000–53900.000] | 64175.000 [62695.000–64205.000] | 1268712.500 [1147652.500–1269082.500] | 1240362.500 [1230352.500–1259472.500] |
| Mixed/H100/F100 | 532700.000 [527100.001–535100.001] | 623800.001 [621559.999–711240.000] | 12537999.999 [11239840.001–12552160.001] | 12596800.001 [12385440.001–12708960.000] |

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
| ConnectDuringFire | FastSignal | FAIL: X:\Database\1 - Roblox\11 - DenseSignal\DenseSignal\benchmarks/benchmark.extended.luneblox:112: X:\Database\1 - Roblox\11 - DenseSignal\DenseSignal\benchmarks/benchmark.extended.luneblox:109: New callback ran in the current fire |
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
| Connections | 144.768 | 144.768 | 176.000 | 176.000 |
| Churn | 0.032 | 0.032 | 0.000 | 0.000 |

Full-GC duration and raw heap/timing samples are in the companion JSON. Full-GC duration is a whole-VM diagnostic, not a production GC pause prediction.

## Method

Rotating module order; adaptive calibration targets a minimum batch duration on every module. Fresh fixtures, full GC before timed batches; natural GC remains enabled inside batches. Setup, explicit GC, verification and cleanup excluded. Callback work included. All modules O2 with matching codegen request, not proof that every function compiled natively. Raw batch seconds retained. P10/P90 describe batch-average ns/op, not individual-call latency. No aggregate performance score.

Source SHA-256 fingerprints and runner settings are saved in the companion JSON. These local vendored implementations are compared, not every library using these names. This LuneBlox run is not an in-game Roblox measurement.

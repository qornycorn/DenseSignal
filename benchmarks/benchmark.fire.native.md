# DenseSignal Fire optimization: controlled performance comparison

LuneBlox 0.10.16+740 · native

Median ns/op; lower is faster. Brackets are P10–P90 batch averages. Positive paired change means slower than the frozen pre-fix source.

| Case | Before | After | FastSignal | Median paired change |
|:---|---:|---:|---:|---:|
| CreateOnly | 138.965 [130.017–161.578] | 137.061 [130.048–152.832] | 30.658 [29.578–32.440] | -0.4% |
| CreateAndFire | 339.832 [318.591–357.312] | 343.408 [322.058–370.081] | 233.411 [226.929–256.934] | +0.5% |
| Fire/H0 | 21.844 [21.181–22.838] | 21.794 [21.011–23.935] | 30.476 [29.314–31.748] | -0.5% |
| Fire/H1 | 39.687 [38.651–41.330] | 39.879 [39.064–41.203] | 67.979 [66.040–69.748] | -0.5% |
| Fire/H2 | 64.539 [61.707–66.339] | 64.349 [61.752–65.689] | 87.479 [84.607–89.600] | -0.3% |
| Fire/H3 | 160.710 [155.599–167.885] | 103.739 [99.809–106.524] | 107.845 [103.948–109.561] | -35.1% |
| Fire/H4 | 178.931 [175.439–181.329] | 126.324 [122.491–129.944] | 128.870 [124.084–132.874] | -29.6% |
| Fire/H8 | 255.591 [246.991–261.792] | 216.797 [209.485–226.715] | 225.293 [213.782–242.731] | -15.1% |
| Fire/H10 | 297.575 [283.073–305.355] | 261.987 [251.676–271.362] | 268.424 [255.957–277.726] | -11.3% |
| Fire/H12 | 333.750 [321.777–346.836] | 310.264 [299.639–320.664] | 317.852 [307.529–327.100] | -7.5% |
| Fire/H13 | 355.599 [346.105–373.622] | 356.478 [351.053–370.812] | 332.454 [318.381–352.745] | +0.1% |
| Fire/H16 | 407.129 [389.673–428.455] | 410.840 [393.054–420.374] | 384.216 [364.124–404.236] | +0.2% |
| FireChecked/H10 | 439.974 [427.653–452.555] | 395.931 [389.046–407.764] | 408.952 [396.159–427.848] | -10.0% |
| Fire/H100 | 1979.883 [1905.371–2036.377] | 1988.965 [1948.779–2048.145] | 2174.316 [2097.168–2254.102] | +0.7% |
| Fire/H1000 | 18787.500 [18067.187–19282.031] | 18790.625 [18356.250–19428.125] | 21363.281 [21111.719–22284.375] | +0.1% |
| Arguments/A32 | 52.885 [50.987–54.634] | 53.606 [51.529–55.914] | 91.327 [87.297–95.183] | +0.4% |
| ConnectDisconnect/H100 | 113.202 [108.615–116.916] | 112.317 [109.409–117.877] | 185.162 [177.365–198.230] | -1.0% |
| Mixed/H100/F10 | 20582.813 [19914.844–32182.031] | 20285.937 [19310.156–28490.625] | 22441.406 [21782.812–28271.094] | +0.1% |

Alternating/rotating Before, After and FastSignal within 31 rounds; 3 warmups; adaptive common batch size targeting 2ms, cap 131072 (16384 for creation). Counter/checksum callback, same runner and O2/codegen request. Setup, warm Fire, full GC, verification and cleanup excluded. Natural GC enabled. Batch-average ns/op, not individual latency. Mixed is one replacement plus ten fires. Paired percentages are After/Before minus one for each round; noise is not a confidence interval.

Source hashes and every raw sample are in the companion JSON. Baseline: benchmarks/fixtures/DenseSignal.before-fire-optimization.luau.

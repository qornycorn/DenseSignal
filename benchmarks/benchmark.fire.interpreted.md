# DenseSignal Fire optimization: controlled performance comparison

LuneBlox 0.10.16+740 · interpreted

Median ns/op; lower is faster. Brackets are P10–P90 batch averages. Positive paired change means slower than the frozen pre-fix source.

| Case | Before | After | FastSignal | Median paired change |
|:---|---:|---:|---:|---:|
| CreateOnly | 175.220 [164.380–203.247] | 178.082 [163.934–236.707] | 46.643 [45.398–50.720] | +0.3% |
| CreateAndFire | 473.840 [447.437–548.535] | 460.986 [448.682–515.234] | 365.503 [356.885–450.488] | -2.2% |
| Fire/H0 | 37.050 [35.982–40.782] | 36.993 [35.976–39.099] | 47.717 [45.964–51.068] | -0.6% |
| Fire/H1 | 67.563 [65.234–82.687] | 66.702 [65.680–68.884] | 125.479 [120.990–135.043] | -0.3% |
| Fire/H2 | 134.552 [130.127–155.408] | 134.766 [130.402–142.957] | 160.443 [153.101–185.901] | +0.1% |
| Fire/H3 | 304.939 [299.172–388.114] | 304.539 [298.986–357.106] | 203.088 [194.708–220.508] | +0.7% |
| Fire/H4 | 353.503 [349.536–381.982] | 356.555 [350.500–420.813] | 251.172 [243.640–267.590] | +0.4% |
| Fire/H8 | 497.437 [487.085–535.876] | 560.327 [545.557–687.134] | 425.024 [400.354–459.668] | +13.5% |
| Fire/H10 | 571.712 [561.654–644.368] | 656.885 [631.706–969.206] | 496.680 [479.053–590.560] | +14.8% |
| Fire/H12 | 639.746 [619.492–821.133] | 738.730 [705.566–927.520] | 563.906 [537.656–869.785] | +13.9% |
| Fire/H13 | 683.073 [641.753–831.641] | 685.156 [658.898–735.634] | 608.984 [587.283–639.453] | +1.1% |
| Fire/H16 | 771.606 [746.582–802.979] | 781.543 [761.621–897.900] | 710.718 [690.283–848.462] | +0.9% |
| FireChecked/H10 | 706.234 [675.977–881.136] | 774.170 [750.749–885.547] | 618.799 [596.549–664.974] | +10.4% |
| Fire/H100 | 3676.172 [3494.824–4148.730] | 3719.531 [3583.887–4074.902] | 4034.863 [3825.293–5054.004] | +0.9% |
| Fire/H1000 | 34507.813 [32476.563–38803.125] | 33935.937 [31575.000–36923.438] | 37900.000 [35821.875–40856.250] | -0.7% |
| Arguments/A32 | 86.807 [84.424–89.694] | 86.813 [83.112–92.191] | 146.750 [143.799–158.286] | +0.1% |
| ConnectDisconnect/H100 | 226.477 [219.025–238.818] | 225.543 [222.125–233.777] | 259.406 [245.026–279.382] | +0.2% |
| Mixed/H100/F10 | 36373.437 [34406.250–38200.000] | 36682.812 [34598.438–38654.688] | 39735.937 [37887.500–41167.187] | +0.8% |

Alternating/rotating Before, After and FastSignal within 31 rounds; 3 warmups; adaptive common batch size targeting 2ms, cap 131072 (16384 for creation). Counter/checksum callback, same runner and O2/codegen request. Setup, warm Fire, full GC, verification and cleanup excluded. Natural GC enabled. Batch-average ns/op, not individual latency. Mixed is one replacement plus ten fires. Paired percentages are After/Before minus one for each round; noise is not a confidence interval.

Source hashes and every raw sample are in the companion JSON. Baseline: benchmarks/fixtures/DenseSignal.before-fire-optimization.luau.

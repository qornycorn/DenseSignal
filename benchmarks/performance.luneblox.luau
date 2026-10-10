-- Controlled before/after comparison, from repository root:
-- luneblox run benchmarks/performance.luneblox.luau [native|interpreted] [output-prefix] [baseline-source]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")
local task = require("@lune/task")
local mode = process.args[1] or "native"
assert(mode == "native" or mode == "interpreted")
local prefix = process.args[2] or "benchmarks/benchmark.fire." .. mode .. "." .. os.time()
assert(not fs.isFile(prefix .. ".json") and not fs.isFile(prefix .. ".md"), "Output exists")
local paths = { Before = process.args[3] or "benchmarks/fixtures/DenseSignal.before-fire-optimization.luau", After = "DenseSignal.luau", FastSignal = "FastSignal.luau" }
local names, modules, hashes = { "Before", "After", "FastSignal" }, {}, {}
for name, path in paths do
    local source = fs.readFile(path)
    hashes[name] = serde.hash("sha256", source)
    source = source:gsub("%-%-!native", ""):gsub("%-%-!optimize 2", "")
    modules[name] = luau.load(luau.compile("return function(task)\n" .. source .. "\nend", {
        optimizationLevel = 2,
    }), { codegenEnabled = mode == "native", debugName = name })()(task)
end
local function percentile(values, fraction)
    local copy = table.clone(values); table.sort(copy)
    return copy[math.max(1, math.ceil(#copy * fraction))]
end
local cases = {
    { Name = "CreateOnly", Kind = "Create", H = 0 },
    { Name = "CreateAndFire", Kind = "CreateFire", H = 0 },
    { Name = "Fire/H0", H = 0 }, { Name = "Fire/H1", H = 1 },
    { Name = "Fire/H2", H = 2 }, { Name = "Fire/H3", H = 3 },
    { Name = "Fire/H4", H = 4 }, { Name = "Fire/H8", H = 8 }, { Name = "Fire/H10", H = 10 },
    { Name = "Fire/H12", H = 12 }, { Name = "Fire/H13", H = 13 }, { Name = "Fire/H16", H = 16 },
    { Name = "FireChecked/H10", Kind = "Checked", H = 10 },
    { Name = "Fire/H100", H = 100 }, { Name = "Fire/H1000", H = 1000 },
    { Name = "Arguments/A32", Kind = "Args", H = 1 },
    { Name = "ConnectDisconnect/H100", Kind = "Churn", H = 100 },
    { Name = "Mixed/H100/F10", Kind = "Mixed", H = 100 },
}
local function measure(S, case, n)
    local s, count, checksum, valid = S.new(), 0, 0, true
    local callback
    if case.Kind == "Checked" then
        -- Match the extended suite's one-argument callback work.
        callback = function(...)
            count += 1
            valid = valid and select("#", ...) == 1
            valid = valid and select(1, ...) == 1 and select(1, ...) == 1
        end
    else
        callback = function(value) count += 1; checksum += value or 0 end
    end
    local connections, created = {}, table.create(if case.Kind == "Create" or case.Kind == "CreateFire" then n else 0)
    for i = 1, case.H do connections[i] = s:Connect(callback) end
    -- Warm bookkeeping and cached callback execution before the timed steady state.
    s:Fire(1); count = 0; checksum = 0
    local run
    if case.Kind == "Create" then
        run = function() for i = 1, n do created[i] = S.new() end end
    elseif case.Kind == "CreateFire" then
        run = function() for i = 1, n do local item = S.new(); created[i] = item; item:Connect(callback); item:Fire(1) end end
    elseif case.Kind == "Args" then
        run = function() for _ = 1, n do s:Fire(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32) end end
    elseif case.Kind == "Churn" then
        run = function() for _ = 1, n do s:Connect(callback):Disconnect() end end
    elseif case.Kind == "Mixed" then
        run = function() for i = 1, n do
            local index = (i - 1) % case.H + 1
            connections[index]:Disconnect(); connections[index] = s:Connect(callback)
            for _ = 1, 10 do s:Fire(1) end
        end end
    else
        run = function() for _ = 1, n do s:Fire(1) end end
    end
    luau.collect()
    local started = os.clock(); run(); local elapsed = os.clock() - started
    local expected = if case.Kind == "Create" or case.Kind == "Churn" then 0
        elseif case.Kind == "CreateFire" then n
        elseif case.Kind == "Mixed" then n * case.H * 10 else n * case.H
    assert(valid and count == expected and (case.Kind == "Checked" or checksum == expected), case.Name .. " callback mismatch")
    if case.Kind == "Churn" then s:Fire(1); assert(count == case.H) end
    s:DisconnectAll(); for _, item in created do item:DisconnectAll() end
    return elapsed
end
local report = { Runtime = _VERSION, Mode = mode, SourceSHA256 = hashes, SourcePaths = paths, Samples = 31, Rows = {},
    RunnerSHA256 = serde.hash("sha256", fs.readFile("benchmarks/performance.luneblox.luau")),
    Method = "Alternating/rotating Before, After and FastSignal within 31 rounds; 3 warmups; adaptive common batch size targeting 2ms, cap 131072 (16384 for creation). Counter/checksum callback, same runner and O2/codegen request. Setup, warm Fire, full GC, verification and cleanup excluded. Natural GC enabled. Batch-average ns/op, not individual latency. Mixed is one replacement plus ten fires. Paired percentages are After/Before minus one for each round; noise is not a confidence interval." }
local md = { "# DenseSignal Fire optimization: controlled performance comparison", "", report.Runtime .. " · " .. mode, "",
    "Median ns/op; lower is faster. Brackets are P10–P90 batch averages. Positive paired change means slower than the frozen pre-fix source.", "",
    "| Case | Before | After | FastSignal | Median paired change |", "|:---|---:|---:|---:|---:|" }
for caseIndex, case in cases do
    local cap = if case.Kind == "Create" or case.Kind == "CreateFire" then 16384 else 131072
    local n = math.max(1, math.floor(128 / math.max(1, case.H)))
    local calibration
    while true do
        local minimum = math.huge; calibration = {}
        for _, name in names do local elapsed = measure(modules[name], case, n); calibration[name] = elapsed; minimum = math.min(minimum, elapsed) end
        if minimum >= 0.002 or n >= cap then break end
        n = math.min(cap, n * 2)
    end
    local row = { Case = case.Name, Iterations = n, RawSeconds = { Before = {}, After = {}, FastSignal = {} }, CalibrationSeconds = calibration, Stats = {} }
    for round = 1, 34 do
        for offset = 0, 2 do
            local name = names[(caseIndex + round + offset) % 3 + 1]
            local elapsed = measure(modules[name], case, n)
            if round > 3 then table.insert(row.RawSeconds[name], elapsed) end
        end
    end
    local line = "| " .. case.Name .. " |"
    for _, name in names do
        local values = {}; for _, elapsed in row.RawSeconds[name] do table.insert(values, elapsed * 1e9 / n) end
        row.Stats[name] = { Median = percentile(values, 0.5), P10 = percentile(values, 0.1), P90 = percentile(values, 0.9) }
        local stat = row.Stats[name]
        line ..= string.format(" %.3f [%.3f–%.3f] |", stat.Median, stat.P10, stat.P90)
    end
    local changes = {}
    for i = 1, 31 do changes[i] = (row.RawSeconds.After[i] / row.RawSeconds.Before[i] - 1) * 100 end
    row.PairedChangePercent = { Median = percentile(changes, 0.5), P10 = percentile(changes, 0.1), P90 = percentile(changes, 0.9) }
    line ..= string.format(" %+.1f%% |", row.PairedChangePercent.Median)
    table.insert(report.Rows, row); table.insert(md, line); print(line)
end
table.insert(md, "\n" .. report.Method)
table.insert(md, "\nSource hashes and every raw sample are in the companion JSON. Baseline: " .. paths.Before .. ".")
fs.writeFile(prefix .. ".json", serde.encode("json", report, true))
fs.writeFile(prefix .. ".md", table.concat(md, "\n") .. "\n")
print("Saved " .. prefix .. ".json and .md")

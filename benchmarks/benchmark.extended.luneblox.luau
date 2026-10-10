local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")
local task = require("@lune/task")

local mode = process.args[1] or "native"
local profile = process.args[2] or "full"
assert(mode == "native" or mode == "interpreted", "Expected native or interpreted")
assert(profile == "full" or profile == "smoke", "Expected full or smoke")
assert(#process.args <= 3, "Usage: [native|interpreted] [full|smoke] [output-prefix]")
local prefix = process.args[3] or string.format("benchmarks/benchmark.extended.%s.%s.%d", mode, profile, os.time())
for _, extension in { ".json", ".md" } do
    assert(not fs.isFile(prefix .. extension) and not fs.isDir(prefix .. extension), "Output already exists: " .. prefix .. extension)
end
local config = {
    Mode = mode, Profile = profile, OptimizationLevel = 2,
    Repeats = if profile == "full" then 3 else 1,
    Samples = if profile == "full" then 15 else 3,
    Warmups = if profile == "full" then 3 else 1,
    TargetSeconds = if profile == "full" then 0.003 else 0.0003,
    MaxIterations = 262144,
    MemoryObjects = if profile == "full" then 10000 else 1000,
}
local names = { "DenseSignal", "FastSignal", "GoodSignal", "SimpleSignal" }
local modules, hashes, adaptedHashes = {}, {}, {}
for _, name in names do
    local source = fs.readFile(name .. ".luau")
    hashes[name] = serde.hash("sha256", source)
    local lines = string.split(source, "\n")
    for i, line in lines do
        if line:match("^%s*%-%-!native%s*$") or line:match("^%s*%-%-!optimize%s+%d+%s*$") then lines[i] = "" end
    end
    local adapted = "return function(task)\n" .. table.concat(lines, "\n") .. "\nend"
    adaptedHashes[name] = serde.hash("sha256", adapted)
    modules[name] = luau.load(luau.compile(adapted, {
        optimizationLevel = 2, debugLevel = 1, coverageLevel = 0,
    }), { debugName = name, codegenEnabled = mode == "native" })()(task)
end

local function quantile(values, q)
    local sorted = table.clone(values)
    table.sort(sorted)
    local position = 1 + (#sorted - 1) * q
    local lo = math.floor(position)
    local hi = math.ceil(position)
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (position - lo)
end
local function stats(values)
    return { Median = quantile(values, 0.5), P10 = quantile(values, 0.1), P90 = quantile(values, 0.9), Min = math.min(table.unpack(values)), Max = math.max(table.unpack(values)) }
end
local report = {
    Runtime = _VERSION, OS = process.os, Architecture = process.arch,
    TimestampUnix = os.time(), Config = config, SourceSHA256 = hashes, AdaptedSourceSHA256 = adaptedHashes,
    RunnerSHA256 = serde.hash("sha256", fs.readFile("benchmarks/benchmark.extended.luneblox.luau")),
    RobloxFastFlags = process.env.LUNE_ROBLOX_FFLAGS ~= "0",
    RunnerJitEnvironment = process.env.LUNE_LUAU_JIT or "default",
    Correctness = {}, Timing = {}, Memory = {}, ValidatedTimingBatches = 0,
    Method = "Rotating module order; adaptive calibration targets a minimum batch duration on every module. Fresh fixtures, full GC before timed batches; natural GC remains enabled inside batches. Setup, explicit GC, verification and cleanup excluded. Callback work included. All modules O2 with matching codegen request, not proof that every function compiled natively. Raw batch seconds retained. P10/P90 describe batch-average ns/op, not individual-call latency. No aggregate performance score.",
}

-- These are explicit behavioral probes, not a claim that every library promises
-- identical mutation semantics. Failures are recorded and do not hide timings.
local probes = {
    { "SelfDisconnect", "Each callback disconnects itself; every listener runs once across two fires.", function(S)
        local s, counts = S.new(), { 0, 0, 0 }
        for i = 1, 3 do
            local c
            c = s:Connect(function() counts[i] += 1; c:Disconnect() end)
        end
        s:Fire(); s:Fire(); s:DisconnectAll()
        assert(counts[1] == 1 and counts[2] == 1 and counts[3] == 1, "Callbacks skipped or duplicated")
    end },
    { "DisconnectOther", "First executing callback removes all other listeners; it must execute only once in that fire.", function(S)
        local s, connections, calls = S.new(), {}, 0
        for i = 1, 4 do
            connections[i] = s:Connect(function()
                calls += 1
                for j, c in connections do if j ~= i then c:Disconnect() end end
            end)
        end
        local ok, err = pcall(function() s:Fire() end)
        s:DisconnectAll()
        assert(ok, tostring(err)); assert(calls == 1, "Expected 1 invocation, got " .. calls)
    end },
    { "DisconnectOnePending", "First callback removes one pending listener; the other three run exactly once.", function(S)
        local s, connections, counts, removed = S.new(), {}, { 0, 0, 0, 0 }, nil
        for i = 1, 4 do
            connections[i] = s:Connect(function()
                counts[i] += 1
                if not removed then
                    removed = if i == 1 then 2 else 1
                    connections[removed]:Disconnect()
                end
            end)
        end
        local ok, err = pcall(function() s:Fire() end)
        s:DisconnectAll(); assert(ok, tostring(err))
        for i, count in counts do
            assert(count == (if i == removed then 0 else 1), "Listener " .. i .. " ran " .. count .. " times")
        end
    end },
    { "ConnectDuringFire", "A listener added during Fire is deferred to the next Fire.", function(S)
        local s, added, calls = S.new(), false, 0
        s:Connect(function()
            if not added then added = true; s:Connect(function() calls += 1 end) end
        end)
        local ok, err = pcall(function()
            s:Fire(); assert(calls == 0, "New callback ran in the current fire")
            s:Fire(); assert(calls == 1, "New callback did not run in the next fire")
        end)
        s:DisconnectAll(); assert(ok, tostring(err))
    end },
    { "DisconnectAllDuringFire", "Clearing listeners during Fire completes without an error; a subsequent Fire is empty.", function(S)
        local s, calls = S.new(), 0
        for _ = 1, 4 do s:Connect(function() calls += 1; s:DisconnectAll() end) end
        local ok, err = pcall(function() s:Fire() end)
        local after = calls
        s:Fire(); s:DisconnectAll()
        assert(ok, tostring(err)); assert(calls == after, "Callback ran after DisconnectAll")
    end },
    { "RecursiveFire", "One nested Fire reaches each of three listeners exactly twice in total.", function(S)
        local s, counts, nested = S.new(), { 0, 0, 0 }, false
        for i = 1, 3 do s:Connect(function()
            counts[i] += 1
            if not nested then nested = true; s:Fire() end
        end) end
        s:Fire(); s:DisconnectAll()
        assert(counts[1] == 2 and counts[2] == 2 and counts[3] == 2, "Nested dispatch count mismatch")
    end },
    { "OnceRecursive", "Once disconnects before a recursive Fire and invokes its callback only once.", function(S)
        local s, calls = S.new(), 0
        s:Once(function() calls += 1; if calls == 1 then s:Fire() end end)
        s:Fire(); s:Fire(); s:DisconnectAll()
        assert(calls == 1, "Once invoked more than once")
    end },
    { "StaleConnection", "Repeated disconnect and a stale connection after DisconnectAll do not remove a new listener.", function(S)
        local s, calls = S.new(), 0
        local old = s:Connect(function() end)
        s:DisconnectAll(); s:Connect(function() calls += 1 end)
        old:Disconnect(); old:Disconnect(); s:Fire(); s:DisconnectAll()
        assert(calls == 1, "Stale connection removed an active listener")
    end },
    { "NilPayload", "Fire and Wait preserve interior and trailing nil arguments.", function(S)
        local s, received, waited = S.new(), nil, nil
        s:Connect(function(...) received = table.pack(...) end)
        local thread = coroutine.create(function() waited = table.pack(s:Wait()) end)
        task.spawn(thread); s:Fire(1, nil, 3, nil); s:DisconnectAll()
        assert(coroutine.status(thread) == "dead", "Waiter not finished")
        for _, args in { received, waited } do
            assert(args.n == 4 and args[1] == 1 and args[2] == nil and args[3] == 3 and args[4] == nil, "Payload mismatch")
        end
        assert(received and waited, "Missing callback or Wait result")
    end },
}
print(_VERSION .. " | " .. mode .. " | " .. profile)
print("Behavioral probes (explicit expectations; independent of timings)")
for _, probe in probes do
    for _, name in names do
        local ok, err = pcall(probe[3], modules[name])
        table.insert(report.Correctness, { Case = probe[1], Expectation = probe[2], Module = name, Passed = ok, Error = if ok then "" else tostring(err) })
        print(string.format("  %-25s %-13s %s", probe[1], name, if ok then "PASS" else "FAIL: " .. tostring(err)))
    end
end

-- Yield support differs by design. Observe caller suspension with a raw coroutine
-- and explicitly resume the suspended handler; do not time incompatible semantics.
for _, name in names do
    local s, handler, finished, returned = modules[name].new(), nil, false, false
    s:Connect(function() handler = coroutine.running(); coroutine.yield(); finished = true end)
    local caller = coroutine.create(function() s:Fire(); returned = true end)
    local ok, err = coroutine.resume(caller)
    local isolated = returned
    if handler and coroutine.status(handler) == "suspended" then
        local resumed, resumeError = coroutine.resume(handler)
        assert(resumed, tostring(resumeError))
    end
    s:DisconnectAll()
    assert(ok and finished and returned, "Yield probe cleanup failed: " .. tostring(err))
    table.insert(report.Correctness, { Case = "YieldBehavior", Module = name, Observation = if isolated then "Handler yields independently" else "Handler suspends Fire caller (synchronous)", Passed = true })
end

local cases = {
    { Name = "CreateOnly", Kind = "Create" },
    { Name = "CreateAndFire", Kind = "CreateFire" },
}
for _, handlers in { 0, 1, 10, 100, 1000 } do
    table.insert(cases, { Name = "Fire/H" .. handlers, Kind = "Fire", Handlers = handlers, Arguments = 1 })
end
for _, arguments in { 0, 1, 4, 8, 16, 32 } do
    table.insert(cases, { Name = "Arguments/A" .. arguments, Kind = "Fire", Handlers = 1, Arguments = arguments })
end
for _, handlers in { 0, 10, 100, 1000 } do
    table.insert(cases, { Name = "ConnectDisconnect/H" .. handlers, Kind = "Churn", Handlers = handlers })
end
for _, handlers in { 10, 100, 1000 } do
    for _, position in { "oldest", "middle", "newest" } do
        table.insert(cases, { Name = "Disconnect/H" .. handlers .. "/" .. position, Kind = "Disconnect", Handlers = handlers, Position = position })
    end
end
for _, fires in { 1, 10, 100 } do
    table.insert(cases, { Name = "Mixed/H100/F" .. fires, Kind = "Mixed", Handlers = 100, Fires = fires })
end

-- Compile direct argument lists once, outside measurement; table.unpack must not
-- obscure signal argument dispatch costs. Only count/first/last are checked.
local fireLoops = {}
for _, n in { 0, 1, 4, 8, 16, 32 } do
    local args = {}
    for i = 1, n do args[i] = tostring(i) end
    local source = "return function(s, iterations) for _ = 1, iterations do s:Fire(" .. table.concat(args, ",") .. ") end end"
    fireLoops[n] = luau.load(luau.compile(source, { optimizationLevel = 2 }), { codegenEnabled = mode == "native", debugName = "ArgumentLoop" .. n })()
end
local function prepare(S, case, iterations)
    local s, calls, valid = S.new(), 0, true
    local objects, connections = {}, {}
    local function callback(...) -- Fixed O(1) work regardless of payload size.
        calls += 1
        if case.Kind == "Fire" then
            local n = case.Arguments
            valid = valid and select("#", ...) == n
            if n > 0 then valid = valid and select(1, ...) == 1 and select(n, ...) == n end
        end
    end
    local run, verify
    if case.Kind == "Create" or case.Kind == "CreateFire" then
        objects = table.create(iterations)
        run = function()
            for i = 1, iterations do
                local object = S.new(); objects[i] = object
                if case.Kind == "CreateFire" then object:Connect(callback); object:Fire() end
            end
        end
        verify = function()
            assert(#objects == iterations, "Missing instances")
            assert(calls == (if case.Kind == "CreateFire" then iterations else 0), "Create count mismatch")
        end
    elseif case.Kind == "Fire" then
        for _ = 1, case.Handlers do s:Connect(callback) end
        run = function() fireLoops[case.Arguments](s, iterations) end
        verify = function() assert(valid and calls == iterations * case.Handlers, "Dispatch/payload mismatch") end
    elseif case.Kind == "Churn" or case.Kind == "Mixed" then
        for i = 1, case.Handlers do connections[i] = s:Connect(callback) end
        run = function()
            for i = 1, iterations do
                if case.Kind == "Mixed" then
                    local index = (i - 1) % case.Handlers + 1
                    connections[index]:Disconnect(); connections[index] = s:Connect(callback)
                    for _ = 1, case.Fires do s:Fire() end
                else
                    s:Connect(callback):Disconnect()
                end
            end
        end
        verify = function()
            local expected = if case.Kind == "Mixed" then iterations * case.Fires * case.Handlers else 0
            assert(calls == expected, "Mixed count mismatch")
            s:Fire(); assert(calls == expected + case.Handlers, "Churn lost or retained a listener")
        end
    else
        -- Fresh signals preserve the requested removal position on every operation.
        -- Limit fixture size during calibration to avoid gigabytes of setup data.
        objects = table.create(iterations); connections = table.create(iterations)
        local index = if case.Position == "oldest" then 1 elseif case.Position == "newest" then case.Handlers else math.ceil(case.Handlers / 2)
        for i = 1, iterations do
            local object = S.new(); objects[i] = object
            for j = 1, case.Handlers do
                local c = object:Connect(callback)
                if j == index then connections[i] = c end
            end
        end
        run = function() for i = 1, iterations do connections[i]:Disconnect() end end
        verify = function()
            for _, object in objects do object:Fire() end
            assert(calls == iterations * (case.Handlers - 1), "Disconnect count mismatch")
        end
    end
    return {
        Run = run, Verify = verify,
        Cleanup = function() s:DisconnectAll(); for _, object in objects do object:DisconnectAll() end end,
    }
end
local function measure(name, case, iterations)
    local state = prepare(modules[name], case, iterations)
    luau.collect()
    local start = os.clock()
    state.Run()
    local elapsed = os.clock() - start
    local ok, err = pcall(state.Verify)
    state.Cleanup()
    assert(ok, name .. "/" .. case.Name .. ": " .. tostring(err))
    assert(elapsed > 0, "Timer resolution too low")
    report.ValidatedTimingBatches += 1
    return elapsed
end
print("\nTiming: median ns/op (P10-P90 stored in JSON and Markdown)")
for caseIndex, case in cases do
    local cap = if case.Kind == "Disconnect" then math.max(16, math.floor(100000 / case.Handlers)) else config.MaxIterations
    if case.Kind == "Create" or case.Kind == "CreateFire" then cap = 32768 end
    local workPerIteration = (case.Handlers or 1) * (case.Fires or 1)
    local iterations = math.min(cap, math.max(1, math.min(64, math.floor(2048 / math.max(1, workPerIteration)))))
    local calibration
    while true do
        local fastest = math.huge
        calibration = {}
        for _, name in names do
            local seconds = measure(name, case, iterations)
            calibration[name] = seconds
            fastest = math.min(fastest, seconds)
        end
        if fastest >= config.TargetSeconds or iterations >= cap then break end
        iterations = math.min(cap, iterations * 2)
    end
    local row = { Case = case.Name, Workload = case, Iterations = iterations, CalibrationSeconds = calibration, Modules = {} }
    for _, name in names do row.Modules[name] = { RawSeconds = {}, RepetitionMediansNs = {} } end
    for repetition = 1, config.Repeats do
        local raw = {}
        for _, name in names do raw[name] = {} end
        for round = 1, config.Warmups + config.Samples do
            for offset = 0, #names - 1 do
                local name = names[(caseIndex + repetition + round + offset) % #names + 1]
                local seconds = measure(name, case, iterations)
                if round > config.Warmups then
                    table.insert(raw[name], seconds * 1e9 / iterations)
                    table.insert(row.Modules[name].RawSeconds, seconds)
                end
            end
        end
        for _, name in names do table.insert(row.Modules[name].RepetitionMediansNs, quantile(raw[name], 0.5)) end
    end
    local line = string.format("%-31s", case.Name)
    for _, name in names do
        local result, ns = row.Modules[name], {}
        for _, seconds in result.RawSeconds do table.insert(ns, seconds * 1e9 / iterations) end
        result.BatchAverageNs = stats(ns)
        result.MedianNs = quantile(result.RepetitionMediansNs, 0.5)
        result.BelowTarget = calibration[name] < config.TargetSeconds
        line ..= string.format(" | %s %.3f%s", name, result.MedianNs, if result.BelowTarget then "*" else "")
    end
    table.insert(report.Timing, row)
    print(line)
end

-- Heap deltas are not total allocated bytes or per-module peak RSS. All probes
-- use the same VM: full collections and warmups reduce, but cannot remove, noise.
local function memorySample(S, kind)
    local n = config.MemoryObjects
    local objects = table.create(n) -- Harness storage excluded from baseline delta.
    local s = S.new()
    local noop = function() end
    luau.collect()
    local baseline = collectgarbage("count")
    local started = os.clock()
    for i = 1, n do
        if kind == "Signals" then objects[i] = S.new()
        elseif kind == "Connections" then objects[i] = s:Connect(noop)
        else s:Connect(noop):Disconnect() end
    end
    local workSeconds = os.clock() - started
    local beforeCollect = collectgarbage("count")
    started = os.clock(); luau.collect(); local retainedGcSeconds = os.clock() - started
    local retained = collectgarbage("count")
    if kind == "Signals" then for _, object in objects do object:DisconnectAll() end end
    s:DisconnectAll(); table.clear(objects)
    started = os.clock(); luau.collect(); local cleanupGcSeconds = os.clock() - started
    local afterCleanup = collectgarbage("count")
    return {
        BaselineKiB = baseline, BeforeCollectionDeltaKiB = beforeCollect - baseline,
        RetainedDeltaKiB = retained - baseline, AfterCleanupDeltaKiB = afterCleanup - baseline,
        WorkSeconds = workSeconds, RetainedFullGcSeconds = retainedGcSeconds, CleanupFullGcSeconds = cleanupGcSeconds,
    }
end
print("\nMemory: retained bytes/object after full GC (VM heap deltas)")
for kindIndex, kind in { "Signals", "Connections", "Churn" } do
    local row = { Case = kind, Objects = config.MemoryObjects, Modules = {} }
    for _, name in names do memorySample(modules[name], kind); row.Modules[name] = { Raw = {} } end
    for round = 1, config.Samples do
        for offset = 0, #names - 1 do
            local name = names[(kindIndex + round + offset) % #names + 1]
            table.insert(row.Modules[name].Raw, memorySample(modules[name], kind))
        end
    end
    for _, name in names do
        local values, gc, work = {}, {}, {}
        for _, sample in row.Modules[name].Raw do
            table.insert(values, sample.RetainedDeltaKiB * 1024 / config.MemoryObjects)
            table.insert(gc, sample.RetainedFullGcSeconds * 1e3)
            table.insert(work, sample.WorkSeconds * 1e9 / config.MemoryObjects)
        end
        row.Modules[name].RetainedBytesPerObject = stats(values)
        row.Modules[name].FullGcMilliseconds = stats(gc)
        row.Modules[name].WorkNsPerOperation = stats(work)
        print(string.format("  %-12s %-13s %.3f bytes/op; full GC %.3f ms", kind, name, quantile(values, 0.5), quantile(gc, 0.5)))
    end
    table.insert(report.Memory, row)
end

local markdown = {
    "# Extended signal benchmark", "",
    string.format("%s · %s · %s · %s/%s", report.Runtime, mode, profile, report.OS, report.Architecture), "",
    "## Timing", "", "Median of repetition medians, **nanoseconds per operation**. Brackets: P10–P90 of batch averages. Lower is faster.", "",
    "| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |", "|:---|---:|---:|---:|---:|",
}
for _, row in report.Timing do
    local line = "| " .. row.Case .. " |"
    for _, name in names do
        local result = row.Modules[name]
        line ..= string.format(" %.3f [%.3f–%.3f]%s |", result.MedianNs, result.BatchAverageNs.P10, result.BatchAverageNs.P90, if result.BelowTarget then "*" else "")
    end
    table.insert(markdown, line)
end
table.insert(markdown, "\n*Calibration hit the fixture/iteration cap before the target duration; interpret small differences cautiously. Mixed reports one cycle (one replacement plus F fires), not one Fire. Create includes storing the new object. See benchmarks/README.md for workload definitions.*")
table.insert(markdown, "\n## Behavioral probes\n\nFAIL means the stated expectation was not met; it does not establish that the library promises that behavior.\n\n| Probe | Module | Result |\n|:---|:---|:---|")
for _, result in report.Correctness do
    local detail = result.Observation or (if result.Passed then "PASS" else "FAIL: " .. result.Error)
    detail = detail:gsub("\n", " "):gsub("|", "/")
    table.insert(markdown, "| " .. result.Case .. " | " .. result.Module .. " | " .. detail .. " |")
end
table.insert(markdown, "\n## Memory\n\nMedian retained VM heap bytes per object/operation after full GC. Connection rows include amortized signal storage. Churn measures residual heap growth, **not allocation volume**.\n\n| Workload | DenseSignal | FastSignal | GoodSignal | SimpleSignal |\n|:---|---:|---:|---:|---:|")
for _, row in report.Memory do
    local line = "| " .. row.Case .. " |"
    for _, name in names do line ..= string.format(" %.3f |", row.Modules[name].RetainedBytesPerObject.Median) end
    table.insert(markdown, line)
end
table.insert(markdown, "\nFull-GC duration and raw heap/timing samples are in the companion JSON. Full-GC duration is a whole-VM diagnostic, not a production GC pause prediction.\n\n## Method\n\n" .. report.Method)
table.insert(markdown, "\nSource SHA-256 fingerprints and runner settings are saved in the companion JSON. These local vendored implementations are compared, not every library using these names. This LuneBlox run is not an in-game Roblox measurement.")
fs.writeFile(prefix .. ".json", serde.encode("json", report, true))
fs.writeFile(prefix .. ".md", table.concat(markdown, "\n") .. "\n")
print("\nValidated timing batches: " .. report.ValidatedTimingBatches)
print("Saved: " .. prefix .. ".json and " .. prefix .. ".md")

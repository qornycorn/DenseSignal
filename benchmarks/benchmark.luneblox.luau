-- Run from the folder containing FastSignal, DenseSignal, GoodSignal and SimpleSignal.
-- luneblox run benchmarks/benchmark.luneblox.luau [interpreted|native] [smoke|full] [output.json]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")
local task = require("@lune/task")
local mode = process.args[1] or "interpreted"
local profile = process.args[2] or "full"
assert(mode == "interpreted" or mode == "native", "Expected interpreted or native")
assert(profile == "smoke" or profile == "full", "Expected smoke or full")
assert(#process.args <= 3, "Usage: [interpreted|native] [smoke|full] [output.json]")
local output = process.args[3] or string.format("benchmarks/benchmark.%s.%s.%d.json", mode, profile, os.time())
assert(not fs.isFile(output) and not fs.isDir(output), "Output exists; choose another filename: " .. output)
local names = { "DenseSignal", "FastSignal", "GoodSignal", "SimpleSignal" }
local cases = { "CreateAndFire", "ConnectAndDisconnect", "FireWithNoConnections", "Fire", "FireManyArguments", "FireManyHandlers", "FireYieldingHandler", "WaitOnEvent" }
local config = {
    Mode = mode, Profile = profile, OptimizationLevel = 2, Handlers = 100, Arguments = 32,
    Samples = if profile == "smoke" then 3 else 31,
    Warmups = if profile == "smoke" then 1 else 5,
    Repeats = if profile == "smoke" then 1 else 3,
    Iterations = if profile == "smoke" then 100 else 2000,
}
local modules, hashes, adaptedHashes = {}, {}, {}
for _, name in names do
    local source = fs.readFile(name .. ".luau")
    hashes[name] = serde.hash("sha256", source)
    local lines = string.split(source, "\n")
    for i, line in lines do
        if line:match("^%s*%-%-!native%s*$") or line:match("^%s*%-%-!optimize%s+%d+%s*$") then lines[i] = "" end
    end
    -- A lexical task parameter supports Roblox-global task without a custom environment.
    -- Factory compilation and invocation are outside all measurements.
    local adapted = "return function(task)\n" .. table.concat(lines, "\n") .. "\nend"
    adaptedHashes[name] = serde.hash("sha256", adapted)
    local bytecode = luau.compile(adapted, { optimizationLevel = 2, debugLevel = 1, coverageLevel = 0 })
    modules[name] = luau.load(bytecode, { debugName = name, codegenEnabled = mode == "native" })()(task)
end

local function prepare(Signal, case)
    local iterations = if case == "FireManyHandlers" then math.max(1, math.floor(config.Iterations / config.Handlers)) else config.Iterations
    local count, sum, started = 0, 0, 0
    local signal = Signal.new()
    local created, threads = table.create(iterations), table.create(iterations)
    local function callback(value)
        count += 1
        sum += value or 0
    end
    local run, verify
    if case == "CreateAndFire" then
        run = function()
            for i = 1, iterations do
                local new = Signal.new()
                created[i] = new
                new:Connect(callback)
                new:Fire(1)
            end
        end
        verify = function() assert(count == iterations and sum == iterations, "CreateAndFire failed") end
    elseif case == "ConnectAndDisconnect" then
        run = function()
            for _ = 1, iterations do signal:Connect(callback):Disconnect() end
        end
        verify = function() signal:Fire(1); assert(count == 0, "Connection was not removed") end
    elseif case == "FireWithNoConnections" then
        run = function() for _ = 1, iterations do signal:Fire() end end
        verify = function()
            signal:Connect(callback)
            signal:Fire(1)
            assert(count == 1 and sum == 1, "Empty signal could not be reused")
        end
    elseif case == "FireManyArguments" then
        signal:Connect(function(...)
            count += 1
            if select("#", ...) ~= 32 then sum = -math.huge; return end
            for i = 1, 32 do sum += select(i, ...) end
        end)
        run = function()
            for _ = 1, iterations do
                signal:Fire(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                    17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32)
            end
        end
        verify = function() assert(count == iterations and sum == iterations * 528, "Payload mismatch") end
    elseif case == "FireYieldingHandler" then
        local suspended
        signal:Connect(function()
            suspended = coroutine.running()
            started += 1
            coroutine.yield()
            count += 1
        end)
        run = function()
            for i = 1, iterations do
                suspended = nil
                signal:Fire()
                assert(suspended and coroutine.status(suspended) == "suspended", "Handler did not yield")
                threads[i] = suspended
                task.spawn(suspended)
            end
        end
        verify = function() assert(started == iterations and count == iterations, "Yield/resume failed") end
    elseif case == "WaitOnEvent" then
        run = function()
            for i = 1, iterations do
                local waiter = coroutine.create(function()
                    local value = signal:Wait()
                    count += 1
                    sum += value
                end)
                threads[i] = waiter
                task.spawn(waiter)
                signal:Fire(1)
            end
        end
        verify = function()
            assert(count == iterations and sum == iterations, "Wait payload mismatch")
            for _, thread in threads do assert(coroutine.status(thread) == "dead", "Waiter unfinished") end
        end
    else
        local handlers = if case == "FireManyHandlers" then config.Handlers else 1
        for _ = 1, handlers do signal:Connect(callback) end
        run = function() for _ = 1, iterations do signal:Fire(1) end end
        verify = function()
            assert(count == iterations * handlers and sum == count, "Fire callback count mismatch")
        end
    end
    return {
        Run = run, Verify = verify, Iterations = iterations,
        Cleanup = function()
            signal:DisconnectAll()
            for _, new in created do new:DisconnectAll() end
            -- Successful yielded handlers return to the module's reusable runner pool.
            -- Do not close those cached runners; waiters are verified dead above.
        end,
    }
end

local function median(values)
    local sorted = table.clone(values)
    table.sort(sorted)
    return sorted[math.ceil(#sorted / 2)]
end
local report = {
    Runtime = _VERSION, OS = process.os, Architecture = process.arch, TimestampUnix = os.time(),
    Config = config, SourceSHA256 = hashes, AdaptedSourceSHA256 = adaptedHashes,
    RunnerSHA256 = serde.hash("sha256", fs.readFile("benchmarks/benchmark.luneblox.luau")),
    RobloxFastFlags = process.env.LUNE_ROBLOX_FFLAGS ~= "0",
    RunnerJitEnvironment = process.env.LUNE_LUAU_JIT or "default",
    Method = "Median of repetition medians, microseconds per iteration. Rotating module order. Fresh fixtures, full GC after setup. Setup/GC/verify/cleanup excluded; callback work included. All modules compiled at O2 with matching codegen request; native compilation of every function is not guaranteed. Lexical task injection, no custom environment. Avg uses only the seven workloads supported by all four modules.",
    Workloads = {
        CreateAndFire = "New + store signal + Connect + Fire; cleanup excluded",
        ConnectAndDisconnect = "Connect + Disconnect on an existing empty signal",
        FireWithNoConnections = "Fire with zero listeners",
        Fire = "Fire(1) with one counter/checksum listener",
        FireManyArguments = "Fire with 32 numbers; one listener checks argument count and sums all values",
        FireManyHandlers = "One Fire(1) dispatching 100 counter/checksum listeners",
        FireYieldingHandler = "One Fire + handler coroutine.yield + suspension assertion + task.spawn resume; not frame latency",
        WaitOnEvent = "Create/store/start waiter coroutine + Wait subscription + Fire + waiter completion",
    },
    Rows = {}, Summary = {}, ValidatedExecutions = 0,
}
local function cell(value)
    return " " .. value .. string.rep(" ", math.max(0, 12 - utf8.len(value))) .. " |"
end
local width = 24
local header = string.format("%-" .. width .. "s |", "")
for _, name in names do header ..= cell(name) end
local divider = string.rep("-", #header)
local totals = { 0, 0, 0, 0 }
local commonCases = 0
print(_VERSION .. " | " .. mode .. " | " .. profile .. " | 100 handlers / 32 arguments")
print(header)
print(divider)
for caseIndex, case in cases do
    local repetitions = {}
    for _, name in names do repetitions[name] = {} end
    for repetition = 1, config.Repeats do
        local raw = {}
        for _, name in names do raw[name] = {} end
        local iterations
        for round = 1, config.Warmups + config.Samples do
            for offset = 0, #names - 1 do
                local name = names[(caseIndex + repetition + round + offset) % #names + 1]
                if case == "FireYieldingHandler" and (name == "FastSignal" or name == "DenseSignal") then continue end
                local state = prepare(modules[name], case)
                luau.collect()
                local elapsed
                local ok, err = pcall(function()
                    local start = os.clock()
                    state.Run()
                    elapsed = os.clock() - start
                    state.Verify()
                end)
                state.Cleanup()
                assert(ok, name .. "/" .. case .. ": " .. tostring(err))
                assert(elapsed > 0, "Increase iterations: timer resolution too low")
                report.ValidatedExecutions += 1
                iterations = state.Iterations
                if round > config.Warmups then table.insert(raw[name], elapsed) end
            end
        end
        for _, name in names do
            if #raw[name] == 0 then continue end
            local us = median(raw[name]) * 1e6 / iterations
            table.insert(repetitions[name], us)
            table.insert(report.Rows, { Case = case, Module = name, Repeat = repetition,
                Iterations = iterations, RawSeconds = raw[name], MedianMicroseconds = us })
        end
    end
    local summary = { Case = case, Microseconds = {} }
    local line = string.format("%-" .. width .. "s |", case)
    for i, name in names do
        if #repetitions[name] == 0 then
            summary.Microseconds[name] = "N/A"
            line ..= cell("N/A")
        else
            local value = median(repetitions[name])
            summary.Microseconds[name] = value
            line ..= cell(string.format("%.1fμs", value))
            if case ~= "FireYieldingHandler" then totals[i] += value end
        end
    end
    if case ~= "FireYieldingHandler" then commonCases += 1 end
    table.insert(report.Summary, summary)
    print(line)
end
print(divider)
local average = string.format("%-" .. width .. "s |", "Avg")
report.AverageMicroseconds = {}
for i, name in names do
    local value = totals[i] / commonCases
    report.AverageMicroseconds[name] = value
    average ..= cell(string.format("%.1fμs", value))
end
print(average)
print("Avg: arithmetic mean of the 7 common workloads; not an overall performance score.")
print("0.0μs means rounding below 0.05μs, not zero work. Lower is faster.")
fs.writeFile(output, serde.encode("json", report, true))
print("Validated: " .. report.ValidatedExecutions .. "; JSON: " .. output)

-- Run from the repository root: luneblox run tests/dispatch.luneblox.luau [native|interpreted]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local task = require("@lune/task")
local process = require("@lune/process")
local mode = process.args[1] or "native"
assert(mode == "native" or mode == "interpreted", "Expected native or interpreted")
local source = fs.readFile(process.args[2] or "DenseSignal.luau")
source = source:gsub("%-%-!native", ""):gsub("%-%-!optimize 2", "")
local S = luau.load(luau.compile("return function(task)\n" .. source .. "\nend", {
    optimizationLevel = 2,
}), { codegenEnabled = mode == "native" })()(task)
local passed = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ": " .. tostring(err))
    passed += 1
    print("PASS " .. name)
end
test("Disconnect pending callbacks without duplicates", function()
    local s, counts, connections = S.new(), { 0, 0, 0, 0 }, {}
    for i = 1, 4 do connections[i] = s:Connect(function()
        counts[i] += 1
        if i == 4 then connections[1]:Disconnect(); connections[2]:Disconnect() end
    end) end
    s:Fire(); s:Fire()
    assert(counts[1] == 0 and counts[2] == 0 and counts[3] == 2 and counts[4] == 2)
end)
test("Clear, reconnect and recursively fire during dispatch", function()
    local s, oldCalls, newCalls = S.new(), 0, 0
    local stale = s:Connect(function() oldCalls += 1 end)
    s:Connect(function()
        s:DisconnectAll()
        s:Connect(function() newCalls += 1 end)
        stale:Disconnect()
        s:Fire()
    end)
    s:Fire(); assert(oldCalls == 0 and newCalls == 1)
    s:Fire(); assert(oldCalls == 0 and newCalls == 2)
end)
test("Nested disconnect keeps outer indices stable", function()
    local s, a, b, c, nested = S.new(), 0, 0, 0, false
    local first = s:Connect(function() a += 1 end)
    s:Connect(function() b += 1 end)
    s:Connect(function()
        c += 1
        if not nested then nested = true; s:Fire() else first:Disconnect() end
    end)
    s:Fire(); assert(a == 0 and b == 2 and c == 2)
    s:Fire(); assert(a == 0 and b == 3 and c == 3)
end)
test("New listeners join nested Fire, not the existing Fire", function()
    local s, fresh, other, added = S.new(), 0, 0, false
    s:Connect(function() other += 1 end)
    s:Connect(function()
        if not added then
            added = true
            s:Connect(function() fresh += 1 end)
            s:Fire()
        end
    end)
    s:Fire(); assert(fresh == 1 and other == 2)
    s:Fire(); assert(fresh == 2 and other == 3)
end)
test("Once disconnects before recursive Fire", function()
    local s, once, regular = S.new(), 0, 0
    s:Connect(function() regular += 1 end)
    s:Once(function() once += 1; s:Fire() end)
    s:Fire(); s:Fire()
    assert(once == 1 and regular == 3)
end)
test("Callback errors preserve identity and restore dispatch state", function()
    local s, calls, marker, failing = S.new(), 0, {}, nil
    s:Connect(function() calls += 1 end)
    for _ = 1, 12 do s:Connect(function() end) end -- Exercise the protected path.
    failing = s:Connect(function() failing:Disconnect(); error(marker) end)
    local ok, err = pcall(function() s:Fire() end)
    assert(not ok and err == marker and calls == 0)
    s:Fire(); assert(calls == 1)
    local replacement = s:Connect(function() calls += 10 end)
    replacement:Disconnect(); s:Fire(); assert(calls == 2)
end)
test("Nested errors restore both dispatch frames", function()
    local s, recursive, calls, marker, entered = S.new(), nil, 0, {}, false
    s:Connect(function() calls += 1 end)
    for _ = 1, 12 do s:Connect(function() end) end
    recursive = s:Connect(function()
        if entered then recursive:Disconnect(); error(marker) end
        entered = true; s:Fire()
    end)
    local ok, err = pcall(function() s:Fire() end)
    assert(not ok and err == marker)
    s:Fire(); assert(calls == 1)
end)
test("A suspended Fire survives removal, addition and another Fire", function()
    local s, cancelledCalls, regular, fresh, once = S.new(), 0, 0, 0, 0
    local cancelled = s:Connect(function() cancelledCalls += 1 end)
    s:Connect(function() regular += 1 end)
    s:Once(function() once += 1; coroutine.yield() end)
    local outer = coroutine.create(function() s:Fire() end)
    assert(coroutine.resume(outer)); assert(coroutine.status(outer) == "suspended")
    cancelled:Disconnect()
    s:Connect(function() fresh += 1 end)
    s:Fire(); assert(fresh == 1 and regular == 1)
    assert(coroutine.resume(outer)); assert(coroutine.status(outer) == "dead")
    assert(cancelledCalls == 0 and once == 1 and fresh == 1 and regular == 2)
    s:Fire(); assert(fresh == 2 and regular == 3)
end)
test("DisconnectAll cancels old suspended dispatch only", function()
    local s, cancelledCalls, fresh = S.new(), 0, 0
    s:Connect(function() cancelledCalls += 1 end)
    s:Once(function() coroutine.yield() end)
    local outer = coroutine.create(function() s:Fire() end)
    assert(coroutine.resume(outer))
    s:DisconnectAll(); s:Connect(function() fresh += 1 end)
    s:Fire(); assert(fresh == 1)
    assert(coroutine.resume(outer)); assert(coroutine.status(outer) == "dead")
    assert(cancelledCalls == 0 and fresh == 1)
    s:Fire(); assert(fresh == 2)
end)
test("Wait preserves nil payloads when its resumption mutates the signal", function()
    local s, cancelledCalls, received = S.new(), 0, nil
    s:Connect(function() cancelledCalls += 1 end)
    local waiter = coroutine.create(function()
        received = table.pack(s:Wait())
        s:DisconnectAll()
    end)
    task.spawn(waiter); s:Fire(1, nil, 3, nil)
    assert(coroutine.status(waiter) == "dead" and cancelledCalls == 0)
    assert(received.n == 4 and received[1] == 1 and received[2] == nil and received[3] == 3 and received[4] == nil)
end)
test("Single-listener fast path remains synchronous and defers new listeners", function()
    local s, first, second, added = S.new(), 0, 0, false
    s:Connect(function()
        first += 1
        if not added then added = true; s:Connect(function() second += 1 end) end
    end)
    s:Fire(); assert(first == 1 and second == 0)
    s:Fire(); assert(first == 2 and second == 1)
end)

test("Mutation and recursion across every small-dispatch boundary", function()
    for _, size in { 3, 4, 8, 9, 10, 11, 12, 13, 16, 17, 32 } do
        local s, connections, counts, first, fresh = S.new(), {}, table.create(size, 0), true, 0
        for i = 1, size do connections[i] = s:Connect(function()
            counts[i] += 1
            if i == size and first then
                first = false
                connections[1]:Disconnect(); connections[size - 1]:Disconnect()
                connections[size]:Disconnect()
                s:Connect(function() fresh += 1 end)
                s:Fire()
            end
        end) end
        s:Fire()
        assert(counts[1] == 0 and counts[size - 1] == 0 and counts[size] == 1)
        for i = 2, size - 2 do assert(counts[i] == 2, "Nested snapshot mismatch at size " .. size) end
        assert(fresh == 1)
        s:Fire(); assert(fresh == 2)
        for i = 2, size - 2 do assert(counts[i] == 3, "Post-dispatch mismatch at size " .. size) end
    end
end)
test("Small snapshot survives nested protected clear and reconnect", function()
    local s, stale, pending, fresh, nested = S.new(), {}, 0, 0, 0
    for i = 1, 9 do stale[i] = s:Connect(function() pending += 1 end) end
    s:Connect(function()
        for _ = 1, 23 do s:Connect(function() pending += 1 end) end
        s:Connect(function()
            nested += 1; s:DisconnectAll()
            s:Connect(function() fresh += 1 end)
            s:Fire()
        end)
        s:Fire()
    end)
    s:Fire()
    assert(pending == 0 and fresh == 1 and nested == 1)
    for _, c in stale do c:Disconnect() end
    s:Fire(); assert(fresh == 2)
end)
test("Protected Fire can clear into a mutating small dispatch", function()
    local s, oldCalls, newCalls = S.new(), 0, 0
    for _ = 1, 31 do s:Connect(function() oldCalls += 1 end) end
    s:Connect(function()
        s:DisconnectAll()
        local pending = {}
        for i = 1, 9 do pending[i] = s:Connect(function() newCalls += 1 end) end
        s:Once(function() for _, c in pending do c:Disconnect() end end)
        s:Fire()
    end)
    s:Fire(); s:Fire()
    assert(oldCalls == 0 and newCalls == 0)
    s:Connect(function() newCalls += 1 end); s:Fire(); assert(newCalls == 1)
end)
test("Pending-slot reuse during a ten-listener Fire never calls new listeners", function()
    local s, pending, oldCalls, fresh = S.new(), {}, 0, 0
    for i = 1, 9 do pending[i] = s:Connect(function() oldCalls += 1 end) end
    s:Once(function()
        for _, c in pending do c:Disconnect() end
        for _ = 1, 20 do s:Connect(function() fresh += 1 end) end
    end)
    s:Fire(); assert(oldCalls == 0 and fresh == 0)
    s:Fire(); assert(oldCalls == 0 and fresh == 20)
end)
test("Nil payload and error identity on small and protected paths", function()
    for _, size in { 2, 3, 10, 12, 13, 32 } do
        local s, calls, marker, failing = S.new(), 0, {}, nil
        for _ = 1, size - 1 do s:Connect(function(...)
            local args = table.pack(...)
            assert(args.n == 4 and args[1] == 1 and args[2] == nil and args[3] == 3 and args[4] == nil)
            calls += 1
        end) end
        failing = s:Connect(function() failing:Disconnect(); error(marker) end)
        local ok, err = pcall(function() s:Fire(1, nil, 3, nil) end)
        assert(not ok and err == marker and calls == 0)
        s:Fire(1, nil, 3, nil); assert(calls == size - 1)
    end
end)
test("Ten-listener suspended snapshot survives slot reuse and compaction", function()
    local s, pending, calls, fresh = S.new(), {}, 0, 0
    for i = 1, 9 do pending[i] = s:Connect(function() calls += 1 end) end
    s:Once(function() coroutine.yield() end)
    local outer = coroutine.create(function() s:Fire() end)
    assert(coroutine.resume(outer)); assert(coroutine.status(outer) == "suspended")
    for _, c in pending do c:Disconnect() end
    for _ = 1, 20 do s:Once(function() fresh += 1 end) end
    s:Fire(); assert(fresh == 20)
    assert(coroutine.resume(outer)); assert(coroutine.status(outer) == "dead")
    assert(calls == 0 and fresh == 20)
    s:Fire(); assert(calls == 0 and fresh == 20)
end)

-- Black-box randomized oracle: each Fire must call each still-eligible listener
-- once, never call new listeners, and never resurrect removed listeners.
test("1000 deterministic mixed-mutation scenarios", function()
    local seed = 173
    local function random(n) seed = (seed * 48271) % 2147483647; return seed % n + 1 end
    for _ = 1, 1000 do
        local s, active, connections, nextId = S.new(), {}, {}, 0
        local expected, seen, mutate
        local function connect()
            nextId += 1
            local id = nextId
            active[id] = true
            connections[id] = s:Connect(function()
                assert(expected[id] and active[id] and not seen[id], "Unexpected or duplicate callback " .. id)
                seen[id] = true
                if mutate then local action = mutate; mutate = nil; action() end
            end)
        end
        local function disconnect(id)
            connections[id]:Disconnect(); connections[id]:Disconnect()
            active[id] = nil
            if expected and not seen[id] then expected[id] = nil end
        end
        for _ = 1, random(40) do connect() end
        for round = 1, 5 do
            expected, seen = table.clone(active), {}
            mutate = function()
                for _ = 1, random(12) do
                    local choice = random(8)
                    if choice <= 4 then disconnect(random(nextId))
                    elseif choice <= 7 then connect()
                    else
                        s:DisconnectAll(); table.clear(active)
                        for id in expected do if not seen[id] then expected[id] = nil end end
                        connect()
                    end
                end
            end
            s:Fire()
            for id in expected do assert(seen[id], "Skipped callback " .. id) end
            expected, seen, mutate = table.clone(active), {}, nil
            s:Fire()
            for id in expected do assert(seen[id], "Compaction lost callback " .. id) end
            if next(active) == nil then connect() end
        end
    end
end)
print(string.format("%d regression groups passed (%s)", passed, mode))

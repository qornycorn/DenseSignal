-- Shared workloads for Benchmarker and the standalone sweep. No game instances are created.
local Suite = {}
Suite.ModuleNames = { "SimpleSignal", "GoodSignal", "FastSignal", "DenseSignal" }

Suite.Scales = { 1, 8, 32, 128, 512, 2048 }
Suite.StressScales = { 8192, 16384 }
Suite.Names = {
	"New",
	"Connect",
	"DisconnectNewest",
	"DisconnectOldest",
	"DisconnectShuffled",
	"DisconnectAll",
	"FireEmpty",
	"Fire0",
	"Fire1",
	"Fire8",
	"Fire32",
	"FireWork",
	"FireDistinct",
	"ManySignals",
	"OnceConnect",
	"OnceFire",
	"SelfDisconnect",
	"Churn",
	"Lifecycle",
	"WaitRoundTrip",
	"Reentrant",
	"YieldRoundTrip",
}

local function noop() end

-- Modules that cannot run YieldRoundTrip (handlers run on pooled threads that must not yield).
local NoYieldSupport = { FastSignal = true, DenseSignal = true }

-- Normalizes a required module into a table exposing `new()`.
-- Most modules return { new = ... }. SignalPlus returns the constructor function itself,
-- so it is wrapped. Its script attribute "Deferred" must NOT be set: deferred
-- handlers would not have run by the time Verify executes.
function Suite.Adapt(name, loaded)
	local api
	if type(loaded) == "function" then
		api = {
			new = function()
				return loaded()
			end,
		}
	else
		assert(
			type(loaded) == "table" and type(loaded.new) == "function",
			name .. ": module must return a table with .new or a constructor function"
		)
		api = loaded
	end
	-- Probe: handlers must have run by the time Fire returns (synchronous dispatch).
	local signal = api.new()
	local ran = 0
	signal:Connect(function()
		ran += 1
	end)
	signal:Fire()
	signal:DisconnectAll()
	assert(
		ran == 1,
		name
			.. ": handlers did not run synchronously during Fire "
			.. "(deferred mode?). Use FastSignal.Immediate; for SignalPlus, set 'Deferred' to false/unset."
	)
	return api
end

function Suite.LoadModules(parent)
	local modules = {}
	for _, name in ipairs(Suite.ModuleNames) do
		local module: Instance?
		if name == "DenseSignal" then
			local shared = game:GetService("ReplicatedStorage")
			module = if shared then shared:FindFirstChild("DenseSignal") else nil
			assert(module and module:IsA("ModuleScript"), "Missing ModuleScript: ReplicatedStorag.DenseSignal")
		else
			module = parent:FindFirstChild(name)
		end
		assert(module and module:IsA("ModuleScript"), "Missing ModuleScript: " .. name)
		local loaded
		if name == "FastSignal" and module:FindFirstChild("Immediate") then
			-- The adaptive entry point follows Studio's event mode. These workloads
			-- measure completed callbacks, so explicitly select immediate dispatch.
			local immediate = module:FindFirstChild("Immediate")
			assert(immediate and immediate:IsA("ModuleScript"), "FastSignal.Immediate must be a ModuleScript")
			loaded = require(immediate)
		elseif name == "SignalPlus" then
			-- SignalPlus reads its 'Deferred' attribute once, when first required, and require()
			-- caches the result for the whole Studio session. Requiring a fresh clone makes
			-- attribute changes take effect on every Benchmarker rerun.
			local copy = module:Clone()
			assert(copy, "SignalPlus must be Archivable to reload it")
			local ok, result = pcall(require, copy)
			copy:Destroy()
			assert(ok, result)
			loaded = result
		else
			loaded = require(module)
		end
		modules[name] = Suite.Adapt(name, loaded)
	end
	return modules
end

function Suite.Cases(scales)
	local cases = {}
	for _, name in ipairs(Suite.Names) do
		for _, size in ipairs(scales or Suite.Scales) do
			assert(size >= 1 and size % 1 == 0, "Sizes must be positive integers")
			table.insert(cases, { Name = name, Size = size, Label = name .. "/" .. size })
		end
	end
	return cases
end

function Suite.Supports(moduleName, case)
	return case.Name ~= "YieldRoundTrip" or not NoYieldSupport[moduleName]
end

-- Setup, validation and cleanup are deliberately outside the measured Run call.
-- Work counters are part of the handler cost and identical across implementations.
function Suite.Prepare(Signal, case)
	local name, n = case.Name, case.Size
	assert(type(n) == "number" and n >= 1 and n % 1 == 0, "Size must be a positive integer")
	local state = {
		Signals = {},
		Connections = {},
		Threads = {},
		Count = 0,
		Sum = 0,
		Expected = 0,
		ExpectedSum = 0,
		Operations = n,
		Unit = "operations",
	}
	local function newSignal()
		local signal = Signal.new()
		table.insert(state.Signals, signal)
		return signal
	end
	local function count()
		state.Count += 1
	end
	local function populate(signal, handler, once)
		for i = 1, n do
			state.Connections[i] = if once then signal:Once(handler) else signal:Connect(handler)
		end
	end
	local signal = newSignal()
	state.Primary = signal
	local run

	if name == "New" then
		state.Results = table.create(n)
		run = function()
			for i = 1, n do
				state.Results[i] = Signal.new()
			end
		end
		state.Unit = "new signals"
	elseif name == "Connect" or name == "OnceConnect" then
		state.Connections = table.create(n)
		run = function()
			for i = 1, n do
				state.Connections[i] = if name == "OnceConnect" then signal:Once(count) else signal:Connect(count)
			end
		end
		state.Expected = n -- Verify fires these outside the timer.
		state.Unit = "connections"
	elseif name == "DisconnectNewest" or name == "DisconnectOldest" or name == "DisconnectShuffled" then
		populate(signal, count)
		local order = table.create(n)
		for i = 1, n do
			order[i] = if name == "DisconnectNewest" then n - i + 1 else i
		end
		if name == "DisconnectShuffled" then
			-- Private deterministic PRNG: does not alter math.random's game-wide state.
			local seed = 1729
			for i = n, 2, -1 do
				seed = (seed * 48271) % 2147483647
				local j = seed % i + 1
				order[i], order[j] = order[j], order[i]
			end
		end
		run = function()
			for i = 1, n do
				state.Connections[order[i]]:Disconnect()
			end
		end
		state.Unit = "disconnects"
	elseif name == "DisconnectAll" then
		populate(signal, count)
		run = function()
			signal:DisconnectAll()
		end
		state.Operations, state.Unit = 1, "DisconnectAll calls"
	elseif name == "FireEmpty" then
		run = function()
			for _ = 1, n do
				signal:Fire()
			end
		end
		state.Unit = "fires"
	elseif
		name == "Fire0"
		or name == "Fire1"
		or name == "Fire8"
		or name == "Fire32"
		or name == "FireWork"
		or name == "FireDistinct"
	then
		local fires = math.max(1, math.floor(4096 / n))
		state.Operations, state.Unit = fires, "fires"
		state.Expected = n * fires
		local handler = count
		if name == "Fire1" then
			handler = function(a)
				state.Count += 1
				state.Sum += a
			end
			state.ExpectedSum = state.Expected * 7
		elseif name == "Fire8" then
			handler = function(a, b, c, d, e, f, g, h)
				state.Count += 1
				state.Sum += a + b + c + d + e + f + g + h
			end
			state.ExpectedSum = state.Expected * 36
		elseif name == "Fire32" then
			handler = function(...)
				state.Count += 1
				state.Sum += select("#", ...) + select(32, ...)
			end
			state.ExpectedSum = state.Expected * 64
		elseif name == "FireWork" then
			handler = function()
				local sum = 0
				for i = 1, 32 do
					sum += i * i
				end
				state.Count += 1
				state.Sum += sum
			end
			state.ExpectedSum = state.Expected * 11440
		end
		if name == "FireDistinct" then
			for i = 1, n do
				local value = i
				signal:Connect(function()
					state.Count += 1
					state.Sum += value
				end)
			end
			state.ExpectedSum = fires * n * (n + 1) / 2
		else
			populate(signal, handler)
		end
		if name == "Fire1" then
			run = function()
				for _ = 1, fires do
					signal:Fire(7)
				end
			end
		elseif name == "Fire8" then
			run = function()
				for _ = 1, fires do
					signal:Fire(1, 2, 3, 4, 5, 6, 7, 8)
				end
			end
		elseif name == "Fire32" then
			run = function()
				for _ = 1, fires do
					signal:Fire(
						1,
						2,
						3,
						4,
						5,
						6,
						7,
						8,
						9,
						10,
						11,
						12,
						13,
						14,
						15,
						16,
						17,
						18,
						19,
						20,
						21,
						22,
						23,
						24,
						25,
						26,
						27,
						28,
						29,
						30,
						31,
						32
					)
				end
			end
		else
			run = function()
				for _ = 1, fires do
					signal:Fire()
				end
			end
		end
	elseif name == "ManySignals" then
		for _ = 1, n do
			newSignal():Connect(count)
		end
		run = function()
			for i = 2, n + 1 do
				state.Signals[i]:Fire()
			end
		end
		state.Expected, state.Unit = n, "signals fired"
	elseif name == "OnceFire" or name == "SelfDisconnect" then
		if name == "OnceFire" then
			populate(signal, count, true)
		else
			for i = 1, n do
				local connection
				connection = signal:Connect(function()
					connection:Disconnect()
					count()
				end)
				state.Connections[i] = connection
			end
		end
		run = function()
			signal:Fire()
		end
		state.Expected, state.Operations, state.Unit = n, 1, "fires"
	elseif name == "Churn" then
		populate(signal, count)
		run = function()
			for i = 1, n do
				state.Connections[i]:Disconnect()
				state.Connections[i] = signal:Connect(count)
			end
		end
		state.Expected, state.Unit = n, "disconnect/connect pairs"
	elseif name == "Lifecycle" then
		run = function()
			for _ = 1, n do
				local item = Signal.new()
				local connection = item:Connect(count)
				item:Fire()
				connection:Disconnect()
				item:DisconnectAll()
			end
		end
		state.Expected, state.Unit = n, "lifecycles"
	elseif name == "WaitRoundTrip" then
		-- Includes waiter coroutine creation, registration, Fire and completion.
		run = function()
			for i = 1, n do
				local thread = coroutine.create(function()
					local a, b, c = signal:Wait()
					if a == 7 and b == nil and c == 11 then
						state.Sum += 1
					end
					count()
				end)
				state.Threads[i] = thread
				assert(coroutine.resume(thread))
			end
			signal:Fire(7, nil, 11)
		end
		state.Expected, state.ExpectedSum, state.Unit = n, n, "waiter round trips"
	elseif name == "Reentrant" then
		local depth = 0
		signal:Connect(function()
			count()
			if depth == 0 then
				depth = 1
				signal:Fire()
				depth = 0
			end
		end)
		run = function()
			for _ = 1, n do
				signal:Fire()
			end
		end
		state.Expected, state.Unit = n * 2, "outer fires (depth 2)"
	elseif name == "YieldRoundTrip" then
		-- Controlled suspension avoids frame-duration noise and leaves no scheduled work.
		populate(signal, function()
			table.insert(state.Threads, coroutine.running())
			coroutine.yield()
			count()
		end)
		run = function()
			signal:Fire()
			for i, thread in ipairs(state.Threads) do
				assert(coroutine.resume(thread))
				state.Threads[i] = nil -- Completed runners belong to the module's coroutine cache.
			end
		end
		state.Expected, state.Unit = n, "yield/resume handlers"
	else
		error("Unknown benchmark: " .. tostring(name))
	end

	state.Run = run
	state.Verify = function()
		if name == "New" then
			assert(#state.Results == n, "Missing new signals")
			for _, item in ipairs(state.Results) do
				local c = item:Connect(noop)
				c:Disconnect()
			end
		elseif
			name == "Connect"
			or name == "OnceConnect"
			or name == "Churn"
			or string.sub(name, 1, 10) == "Disconnect"
		then
			signal:Fire()
		end
		if name == "OnceFire" or name == "SelfDisconnect" or name == "OnceConnect" or name == "WaitRoundTrip" then
			signal:Fire() -- Must not call consumed handlers again.
		end
		assert(state.Count == state.Expected, name .. ": wrong callback count " .. state.Count .. "/" .. state.Expected)
		assert(state.Sum == state.ExpectedSum, name .. ": wrong payload checksum")
		if name == "WaitRoundTrip" then
			for _, thread in ipairs(state.Threads) do
				assert(coroutine.status(thread) == "dead", "Waiter did not finish")
			end
		end
	end
	state.Cleanup = function()
		for _, item in ipairs(state.Signals) do
			item:DisconnectAll()
		end
		for _, item in ipairs(state.Results or {}) do
			item:DisconnectAll()
		end
		for _, thread in ipairs(state.Threads) do
			if coroutine.status(thread) == "suspended" then
				pcall(coroutine.close, thread)
			end
		end
		table.clear(state.Signals)
		table.clear(state.Connections)
		table.clear(state.Threads)
	end
	return state
end

function Suite.Warmup(modules)
	for _, Signal in pairs(modules) do
		local signal = Signal.new()
		signal:Connect(noop)
		signal:Fire()
		signal:DisconnectAll()
	end
end

return Suite

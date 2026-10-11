-- Run from the repository root: luneblox run tests/suite.luneblox.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local root = roblox.Instance.new("Folder")
local replicatedStorage = roblox.Instance.new("ReplicatedStorage")
local shared = roblox.Instance.new("Folder")
shared.Name = "shared"
shared.Parent = replicatedStorage
local gameContext = {
	GetService = function(_, name)
		assert(name == "ReplicatedStorage")
		return replicatedStorage
	end,
}
local sources, cache = {}, {}
local function addModule(name, parent, source)
	local module = roblox.Instance.new("ModuleScript")
	module.Name = name
	module.Parent = parent
	sources[module] = source
	return module
end
local function loadModule(module)
	if cache[module] then
		return cache[module]
	end
	local source = assert(sources[module], "Unexpected module: " .. module.Name)
	local factory = luau.load("return function(task, script, require, game)\n" .. source .. "\nend")()
	local loaded = factory(task, module, loadModule, gameContext)
	cache[module] = loaded
	return loaded
end

local base = "src/plrclient/benchmarks/"
local suiteModule = addModule("suite", root, fs.readFile(base .. "suite.luau"))
for _, name in { "SimpleSignal", "GoodSignal" } do
	addModule(name, root, fs.readFile(base .. name .. ".luau"))
end
local dense = addModule("DenseSignal", shared, fs.readFile("src/repstorage/DenseSignal/DenseSignal.luau"))
addModule("DenseSignal", root, 'error("Benchmark-local DenseSignal must not be loaded")')
-- Fail if the loader touches the adaptive entry point, regardless of event mode.
local fast = addModule("FastSignal", root, 'error("Adaptive entry point must not be required")')
local immediate = addModule("Immediate", fast, fs.readFile(base .. "FastSignal/Immediate.luau"))
local deferred = addModule("Deferred", fast, fs.readFile(base .. "FastSignal/Deferred.luau"))

local Suite = loadModule(suiteModule)
local modules = Suite.LoadModules(root)
assert(modules.DenseSignal == loadModule(dense), "Expected ReplicatedStorage.shared.DenseSignal")
assert(modules.FastSignal == loadModule(immediate), "Expected FastSignal.Immediate")
assert(cache[fast] == nil, "Adaptive entry point was loaded")

local passed = 0
for name, Signal in modules do
	for _, case in Suite.Cases({ 1, 8, 32 }) do
		if Suite.Supports(name, case) then
			local state = Suite.Prepare(Signal, case)
			local ok, message = pcall(function()
				state.Run()
				state.Verify()
			end)
			state.Cleanup()
			assert(ok, name .. "/" .. case.Label .. ": " .. tostring(message))
			passed += 1
		end
	end
end

-- Keep the synchronous probe: silently accepting deferred dispatch would time
-- scheduling only and invalidate the callback counts in these workloads.
local ok, message = pcall(Suite.Adapt, "FastSignal", loadModule(deferred))
assert(not ok and string.find(tostring(message), "did not run synchronously", 1, true))
task.wait()

-- Older single-file FastSignal modules without an Immediate child still load.
fast.Parent = nil
local legacy = addModule("FastSignal", root, fs.readFile(base .. "SimpleSignal.luau"))
assert(Suite.LoadModules(root).FastSignal == loadModule(legacy))
root:Destroy()
replicatedStorage:Destroy()
fast:Destroy()
print(string.format("PASS Immediate selection, deferred rejection, legacy fallback; %d workload cases", passed))

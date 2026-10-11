--[[
This file is for use by Benchmarker (https://boatbomber.itch.io/benchmarker)

]]
local ROOT = game:GetService("StarterPlayer").StarterPlayerScripts.client.benchmarks
-- Benchmarker reruns in the same Studio environment. require(original) may
-- return an older Suite even after its Source has been edited.
local suiteCopy = ROOT.suite:Clone()
assert(suiteCopy, "SignalBenchmarkSuite must be Archivable to reload it")
local loaded, Suite = pcall(require, suiteCopy)
suiteCopy:Destroy()
assert(loaded, Suite)
-- Returns { [moduleName] = { new = function } } for every name in Suite.ModuleNames (incl. SignalPlus).
local Modules = Suite.LoadModules(ROOT)

local CASE = "Fire0" -- See Suite.Names (22 workloads).
local SIZE = 512 -- Default scales: 1, 8, 32, 128, 512, 2048; stress: 8192, 16384.
local case = { Name = CASE, Size = SIZE }
local functions = {}
for name, Signal in pairs(Modules) do
	if Suite.Supports(name, case) then
		local moduleName = name
		local implementation = Signal
		functions[moduleName] = function(Profiler)
			-- A fresh fixture per invocation, including plugin validation calls that
			-- can occur without BeforeEach. No shared mutable state across hooks.
			local state
			local activeSection = false
			local ok, message = pcall(function()
				Profiler.Begin("Setup")
				activeSection = true
				Suite.Warmup({ [moduleName] = implementation })
				state = Suite.Prepare(implementation, case)
				Profiler.End()
				activeSection = false

				Profiler.Begin("Workload")
				activeSection = true
				state.Run()
				Profiler.End()
				activeSection = false

				Profiler.Begin("Verify")
				activeSection = true
				state.Verify()
				Profiler.End()
				activeSection = false
			end)
			if activeSection then
				Profiler.End()
			end
			if state then
				Profiler.Begin("Cleanup")
				local cleaned, cleanupError = pcall(state.Cleanup)
				Profiler.End()
				assert(cleaned, cleanupError)
			end
			assert(ok, message)
		end
	end
end

return {
	ParameterGenerator = function()
		return
	end,
	BeforeAll = function() end,
	AfterAll = function() end,
	BeforeEach = function() end,
	AfterEach = function() end,
	Functions = functions,
}

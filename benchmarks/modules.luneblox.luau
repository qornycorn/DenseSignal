-- Shared source paths and compilation for runners launched from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local task = require("@lune/task")

local Modules = {}
Modules.Paths = {
	DenseSignal = "src/repstorage/DenseSignal/DenseSignal.luau",
	FastSignal = "src/plrclient/benchmarks/FastSignal/Immediate.luau",
	GoodSignal = "src/plrclient/benchmarks/GoodSignal.luau",
	SimpleSignal = "src/plrclient/benchmarks/SimpleSignal.luau",
}

function Modules.Load(path, mode)
	assert(mode == "native" or mode == "interpreted", "Expected native or interpreted")
	local cache, sources, adaptedSources = {}, {}, {}
	local function loadSource(sourcePath)
		if cache[sourcePath] then
			return cache[sourcePath]
		end
		local source = fs.readFile(sourcePath)
		table.insert(sources, source)
		local lines = string.split(source, "\n")
		for i, line in lines do
			if line:match("^%s*%-%-!native%s*$") or line:match("^%s*%-%-!optimize%s+%d+%s*$") then
				lines[i] = ""
			end
		end
		local adapted = "return function(task, script, require)\n" .. table.concat(lines, "\n") .. "\nend"
		table.insert(adaptedSources, adapted)
		local directory = sourcePath:match("^(.*)[/\\]") or "."
		-- FastSignal.Immediate requires its sibling Deferred for shared methods.
		local scriptContext = { Parent = { Deferred = directory .. "/Deferred.luau" } }
		local factory = luau.load(
			luau.compile(adapted, { optimizationLevel = 2, debugLevel = 1, coverageLevel = 0 }),
			{ debugName = sourcePath, codegenEnabled = mode == "native" }
		)()
		local loaded = factory(task, scriptContext, loadSource)
		cache[sourcePath] = loaded
		return loaded
	end
	local loaded = loadSource(path)
	-- Include dependency sources so FastSignal fingerprints cover both variants.
	return loaded, serde.hash("sha256", table.concat(sources, "\n\0\n")),
		serde.hash("sha256", table.concat(adaptedSources, "\n\0\n"))
end

return Modules

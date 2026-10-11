local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local module = roblox.Instance.new("ModuleScript")
module.Name = "DenseSignal"
module.Source = fs.readFile("src/repstorage/DenseSignal/DenseSignal.luau")

fs.writeFile("DenseSignal.rbxm", roblox.serializeModel({ module }))

print("done")

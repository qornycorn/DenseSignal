--------------------------------------------------------------------------------
--                           Fast FastSignal-like class                           --
-- This is a FastSignal class that is implemented in the most performant way      --
-- possible, sacrificing correctness. The event handlers will be called       --
-- directly, so it is not safe to yield in them, and it is also not safe to   --
-- connect new handlers in the middle of a handler (though it is still safe   --
-- for a handler to specifically disconnect itself)                           -- 
--------------------------------------------------------------------------------

local FastSignal = {}
FastSignal.__index = FastSignal

local Connection = {}
Connection.__index = Connection

function Connection.new(FastSignal, handler)
	return setmetatable({
		_handler = handler,
		_FastSignal = FastSignal,
	}, Connection)
end

function Connection:Disconnect()
	self._FastSignal[self] = nil
end

function FastSignal.new()
	return setmetatable({}, FastSignal)
end

function FastSignal:Connect(fn)
	local connection = Connection.new(self, fn)
	self[connection] = true
	return connection
end

function FastSignal:DisconnectAll()
	table.clear(self)
end

function FastSignal:Fire(...)
	if next(self) then
		for handler, _ in pairs(self) do
			handler._handler(...)
		end
	end
end

function FastSignal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn;
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function FastSignal:Once(fn)
	local cn;
	cn = self:Connect(function(...)
		cn:Disconnect()
		fn(...)
	end)
	return cn
end

return FastSignal
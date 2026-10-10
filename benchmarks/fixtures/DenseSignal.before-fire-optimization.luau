--!strict
--!native
--!optimize 2

--	Synchronous DenseSignal optimized for dispatch through a dense array of callbacks. 	--

-- MIT License																			--

-- Copyright (c) 2026 qornyy															--

-- Permission is hereby granted, free of charge, to any person obtaining a copy			--
-- of this software and associated documentation files (the "Software"), to deal		--
-- in the Software without restriction, including without limitation the rights			--
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell			--
-- copies of the Software, and to permit persons to whom the Software is				--
-- furnished to do so, subject to the following conditions:								--

-- The above copyright notice and this permission notice shall be included in all		--
-- copies or substantial portions of the Software.										--

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR			--
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,				--
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE			--
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER				--
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,		--
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE		--
-- SOFTWARE.																			--

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type DenseSignal<T...> = {
	Connect: (self: DenseSignal<T...>, fn: (T...) -> ()) -> Connection,
	Once: (self: DenseSignal<T...>, fn: (T...) -> ()) -> Connection,
	Fire: (self: DenseSignal<T...>, T...) -> (),
	Wait: (self: DenseSignal<T...>) -> T...,
	DisconnectAll: (self: DenseSignal<T...>) -> (),
}

type DenseSignalImpl<T...> = DenseSignal<T...> & {
	_handlers: { (T...) -> () },
	_connections: { ConnectionImpl<T...> | false },
	_depth: number,
	_pending: { number }?,
}

type ConnectionImpl<T...> = Connection & {
	_DenseSignal: DenseSignalImpl<T...>,
	_index: number,
}

local DenseSignal = {}
DenseSignal.__index = DenseSignal
-- Allocate per-instance dispatch bookkeeping only when it is first needed.
DenseSignal._depth = 0

local Connection = {}
Connection.__index = Connection

local function disconnected(...: any): () end

-- Remove deferred holes only after every dispatch using these indices finishes.
-- Each disconnected slot is processed once; ordinary disconnect stays O(1).
local function compact<T...>(self: DenseSignalImpl<T...>, pending: { number }): ()
	local handlers, connections = self._handlers, self._connections
	local last = #handlers
	for _, index in pending do
		while last > 0 and not connections[last] do
			handlers[last] = nil
			connections[last] = nil
			last -= 1
		end
		if index < last then
			local moved = connections[last]
			if moved then
				handlers[index] = handlers[last]
				connections[index] = moved
				moved._index = index
				handlers[last] = nil
				connections[last] = nil
				last -= 1
			end
		end
	end
	self._pending = nil
end

function Connection.Disconnect<T...>(self: ConnectionImpl<T...>): ()
	local DenseSignal = self._DenseSignal
	local index = self._index
	local connections = DenseSignal._connections
	if connections[index] ~= self then return end
	local handlers = DenseSignal._handlers
	if DenseSignal._depth > 0 then
		-- Keep active Fire loops stable and skip this listener immediately.
		handlers[index] = disconnected
		connections[index] = false
		local pending = DenseSignal._pending
		if not pending then
			pending = {}
			DenseSignal._pending = pending
		end
		pending[#pending + 1] = index
		self._index = 0
		return
	end
	local last = #handlers
	local moved = connections[last] :: ConnectionImpl<T...>
	handlers[index] = handlers[last]
	connections[index] = moved
	moved._index = index
	handlers[last] = nil
	connections[last] = nil
	self._index = 0
end

function DenseSignal.new<T...>(): DenseSignal<T...>
	return setmetatable({ _handlers = {}, _connections = {} }, DenseSignal) :: any
end

function DenseSignal.Connect<T...>(self: DenseSignalImpl<T...>, fn: (T...) -> ()): Connection
	local index = #self._handlers + 1
	local connection: ConnectionImpl<T...> = setmetatable({ _DenseSignal = self, _index = index }, Connection) :: any
	self._handlers[index] = fn
	self._connections[index] = connection
	return connection
end

function DenseSignal.DisconnectAll<T...>(self: DenseSignalImpl<T...>): ()
	if self._depth > 0 then
		-- Active loops keep their old array, now containing only no-op callbacks.
		-- New connections belong to a fresh array and cannot enter those loops.
		local handlers = self._handlers
		for i = 1, #handlers do handlers[i] = disconnected end
		self._handlers = {}
		self._connections = {}
		self._pending = nil
		return
	end
	table.clear(self._handlers)
	table.clear(self._connections)
end

local function dispatch<T...>(handlers: { (T...) -> () }, ...: T...): ()
	for i = #handlers, 1, -1 do
		handlers[i](...)
	end
end

function DenseSignal.Fire<T...>(self: DenseSignalImpl<T...>, ...: T...): ()
	local handlers = self._handlers
	-- No remaining indices need protection for zero or one callback.
	local count = #handlers
	if count == 0 then return end
	if count == 1 then
		handlers[1](...)
		return
	end
	if count == 2 then
		-- Snapshot the only pending callback in locals. Swap-remove remains safe
		-- here, and connection identity rejects DisconnectAll/reconnect changes.
		local first = self._connections[1]
		local handler = handlers[1]
		handlers[2](...)
		if first and self._connections[first._index] == first then handler(...) end
		return
	end
	self._depth += 1
	local ok, message = pcall(dispatch, handlers, ...)
	local depth = self._depth - 1
	self._depth = depth
	if depth == 0 then
		local pending = self._pending
		if pending then compact(self, pending) end
	end
	-- Restore bookkeeping even when a synchronous callback raises an error.
	if not ok then error(message, 0) end
end

function DenseSignal.Once<T...>(self: DenseSignalImpl<T...>, fn: (T...) -> ()): Connection
	local connection: Connection
	connection = self:Connect(function(...: T...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function DenseSignal.Wait<T...>(self: DenseSignalImpl<T...>): T...
	local thread = coroutine.running()
	local connection: Connection
	connection = self:Connect(function(...: T...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

return DenseSignal

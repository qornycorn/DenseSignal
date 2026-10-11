--!strict
--!native
--!optimize 2

-- Synchronous DenseSignal optimized for dispatch through a dense array of callbacks. 	--

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

DenseSignal._depth = 0

local Connection = {}
Connection.__index = Connection

local function disconnected(...: any): () end

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
			if type(moved) == "table" then
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
	if connections[index] ~= self then
		return
	end
	local handlers = DenseSignal._handlers
	if DenseSignal._depth > 0 then
		handlers[index] = disconnected
		connections[index] = false
		local pending = DenseSignal._pending
		if pending then
			pending[#pending + 1] = index
		else
			DenseSignal._pending = { index }
		end
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
		local handlers = self._handlers
		for i = 1, #handlers do
			handlers[i] = disconnected
		end
		self._handlers = {}
		self._connections = {}
		self._pending = nil
		return
	end
	table.clear(self._handlers)
	table.clear(self._connections)
end

local function dispatchSmall<T...>(
	handlers: { (T...) -> () },
	connections: { ConnectionImpl<T...> | false },
	count: number,
	...: T...
): ()
	local c1 = connections[1]
	local c2 = connections[2]
	local c3 = if count > 3 then connections[3] else false
	local c4 = if count > 4 then connections[4] else false
	local c5 = if count > 5 then connections[5] else false
	local c6 = if count > 6 then connections[6] else false
	local c7 = if count > 7 then connections[7] else false
	local c8 = if count > 8 then connections[8] else false
	local c9 = if count > 9 then connections[9] else false
	local c10 = if count > 10 then connections[10] else false
	local c11 = if count > 11 then connections[11] else false
	handlers[count](...)
	if type(c11) == "table" then
		local index = c11._index
		if connections[index] == c11 then
			handlers[index](...)
		end
	end
	if type(c10) == "table" then
		local index = c10._index
		if connections[index] == c10 then
			handlers[index](...)
		end
	end
	if type(c9) == "table" then
		local index = c9._index
		if connections[index] == c9 then
			handlers[index](...)
		end
	end
	if type(c8) == "table" then
		local index = c8._index
		if connections[index] == c8 then
			handlers[index](...)
		end
	end
	if type(c7) == "table" then
		local index = c7._index
		if connections[index] == c7 then
			handlers[index](...)
		end
	end
	if type(c6) == "table" then
		local index = c6._index
		if connections[index] == c6 then
			handlers[index](...)
		end
	end
	if type(c5) == "table" then
		local index = c5._index
		if connections[index] == c5 then
			handlers[index](...)
		end
	end
	if type(c4) == "table" then
		local index = c4._index
		if connections[index] == c4 then
			handlers[index](...)
		end
	end
	if type(c3) == "table" then
		local index = c3._index
		if connections[index] == c3 then
			handlers[index](...)
		end
	end
	if type(c2) == "table" then
		local index = c2._index
		if connections[index] == c2 then
			handlers[index](...)
		end
	end
	if type(c1) == "table" then
		local index = c1._index
		if connections[index] == c1 then
			handlers[index](...)
		end
	end
end

local function dispatch<T...>(handlers: { (T...) -> () }, ...: T...): nil
	for i = #handlers, 1, -1 do
		handlers[i](...)
	end

	return nil
end

function DenseSignal.Fire<T...>(self: DenseSignalImpl<T...>, ...: T...): ()
	local handlers = self._handlers

	local count = #handlers
	if count == 0 then
		return
	end
	if count == 1 then
		handlers[1](...)
		return
	end
	if count == 2 then
		local first = self._connections[1]
		local handler = handlers[1]
		handlers[2](...)
		if type(first) == "table" and self._connections[first._index] == first then
			handler(...)
		end
		return
	end
	if count <= 12 then
		dispatchSmall(handlers, self._connections, count, ...)
		return
	end
	self._depth += 1
	local ok, message = pcall(dispatch, handlers, ...)
	local depth = self._depth - 1
	self._depth = depth
	if depth == 0 then
		local pending = self._pending
		if pending then
			compact(self, pending)
		end
	end

	if not ok then
		error(message, 0)
	end
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

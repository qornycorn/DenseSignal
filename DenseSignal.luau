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
	_connections: { ConnectionImpl<T...> },
}

type ConnectionImpl<T...> = Connection & {
	_DenseSignal: DenseSignalImpl<T...>,
	_index: number,
}

local DenseSignal = {}
DenseSignal.__index = DenseSignal

local Connection = {}
Connection.__index = Connection

function Connection.Disconnect<T...>(self: ConnectionImpl<T...>): ()
	local DenseSignal = self._DenseSignal
	local index = self._index
	local connections = DenseSignal._connections
	if connections[index] ~= self then return end
	local handlers = DenseSignal._handlers
	local last = #handlers
	local moved = connections[last]
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
	table.clear(self._handlers)
	table.clear(self._connections)
end

function DenseSignal.Fire<T...>(self: DenseSignalImpl<T...>, ...: T...): ()
	local handlers = self._handlers
	for i = #handlers, 1, -1 do
		handlers[i](...)
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
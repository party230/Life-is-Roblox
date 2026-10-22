--!strict
-- Minimal pure-Luau signal. Handlers run synchronously in connection order.

export type Connection = { disconnect: (self: Connection) -> (), connected: boolean }

export type Signal<T...> = {
	connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	fire: (self: Signal<T...>, T...) -> (),
	destroy: (self: Signal<T...>) -> (),
}

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local handlers: { { fn: (T...) -> (), conn: Connection } } = {}
	local self = {}

	function self.connect(_: Signal<T...>, handler: (T...) -> ()): Connection
		local conn = { connected = true } :: any
		local entry = { fn = handler, conn = conn }
		function conn.disconnect(c: Connection)
			if not c.connected then
				return
			end
			c.connected = false
			local index = table.find(handlers, entry)
			if index then
				table.remove(handlers, index)
			end
		end
		table.insert(handlers, entry)
		return conn
	end

	function self.once(s: Signal<T...>, handler: (T...) -> ()): Connection
		local conn: Connection
		conn = s:connect(function(...: T...)
			conn:disconnect()
			handler(...)
		end)
		return conn
	end

	function self.fire(_: Signal<T...>, ...: T...)
		-- Snapshot so handlers can disconnect during fire.
		for _, entry in table.clone(handlers) do
			if entry.conn.connected then
				entry.fn(...)
			end
		end
	end

	function self.destroy(_: Signal<T...>)
		for _, entry in handlers do
			entry.conn.connected = false
		end
		table.clear(handlers)
	end

	return (self :: any) :: Signal<T...>
end

return Signal

return {
	distribute = function(world, count, kind, blacklist, ...)
		if type(world) ~= "table" then error("Bad argument #1 expected table, got " .. type(world), 2) end
		if type(count) ~= "number" then error("Bad argument #2: expected number, got " .. type(count), 2) end
		if type(kind) ~= "string" then error("Bad argument #3: expected string, got " .. type(kind), 2) end

		for _ = 1, count do
			local x = math.random(5, world.width)
			local y = math.random(1, world.height)

			-- Prevent overwriting entrance
			local success = true
			if blacklist then
				for _, item in ipairs(blacklist) do
					if item[1] == x and item[2] == y then
						success = false
						break
					end
				end
			end

			if success then
				world.setBlock(x, y, kind, ...)
			end
		end
	end,

	-- line = function(world, sX, sY, eX, eY, type, ...)
	--
	-- end
}

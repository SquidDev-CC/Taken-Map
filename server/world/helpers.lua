return function(world)
	function world.distribute(count, kind, blacklist, ...)
		if type(count) ~= "number" then error("Bad argument #1: expected number, got " .. type(count), 2) end
		if type(kind) ~= "string" then error("Bad argument #2: expected string, got " .. type(kind), 2) end

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
	end

	function world.setBlocks(x, y, width, height, kind)
		if type(x) ~= "number" then error("Bad argument #1: expected number, got " .. type(x), 2) end
		if type(y) ~= "number" then error("Bad argument #2: expected number, got " .. type(y), 2) end
		if type(width) ~= "number" then error("Bad argument #3: expected number, got " .. type(width), 2) end
		if type(height) ~= "number" then error("Bad argument #4: expected number, got " .. type(height), 2) end
		if type(kind) ~= "string" then error("Bad argument #5: expected string, got " .. type(kind), 2) end

		if width < 1 then error("width is < 1", 2) end
		if height < 1 then error("height is < 1", 2) end

		width = width + x - 1
		height = height + y - 1

		for x = x, width do
			for y = y, height do
				world.setBlock(x, y, kind)
			end
		end
	end

	-- line = function(world, sX, sY, eX, eY, type, ...)
	--
	-- end
end

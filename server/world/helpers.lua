local floor, abs = math.floor, math.abs

return function(world)
	local width, height = world.width, world.height

	function world.distribute(count, kind, blacklist, ...)
		if type(count) ~= "number" then error("Bad argument #1: expected number, got " .. type(count), 2) end
		if type(kind) ~= "string" then error("Bad argument #2: expected string, got " .. type(kind), 2) end

		for _ = 1, count do
			local x = math.random(5, width)
			local y = math.random(1, height)

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

	function world.setBlocks(x, y, width, height, kind, ...)
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
				world.setBlock(x, y, kind, ...)
			end
		end
	end

	local function pixel(x, y, kind, ...)
		if x >= 1 and y >= 1 and x <= width and y <= height then
			world.setBlock(x, y, kind, ...)
		end
	end

	function world.line(x_1, y_1, x_2, y_2, kind, ...)
		if (x_1 < 1 and x_2 < 1) or (x_1 > width and x_2 > width) or (y_1 < 1 and y_2 < 1) or (y_1 > height and y_2 > height)  then return end

		x_1, x_2 = floor(x_1), floor(x_2)
		y_1, y_2 = floor(y_1), floor(y_2)

		local ndx, ndy = x_2 - x_1, y_2 - y_1
		local dx, dy = abs(ndx), abs(ndy)
		local steep = dy > dx
		if steep then
			dy, dx = dx, dy
		end

		local e = 2 * dy - dx
		local x, y = x_1, y_1

		local signy, signx = 1, 1
		if ndx < 0 then signx = -1 end
		if ndy < 0 then signy = -1 end

		for i = 1, dx do
			pixel(x, y, kind, ...)
			while e >= 0 do
				if steep then
					x = x + signx
				else
					y = y + signy
				end
				e = e - 2 * dx
			end

			if steep then
				y = y + signy
			else
				x = x + signx
			end
			e = e + 2 * dy
		end
		pixel(x_2, y_2, kind, ...)
	end

end

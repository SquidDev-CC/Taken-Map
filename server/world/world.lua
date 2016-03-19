local execAsync = commands.native.execAsync
local exec = commands.native.exec


return function(xBase, yBase, zBase)
	Builder.setPosition(xBase, yBase, zBase)

	local xSize, ySize, zSize
	local xPlayer, yPlayer, zPlayer
	local xExit, yExit, zExit

	local function assertAbove(requirements, message)
		if not requirements then
			error(message, 3)
		end
	end

	--[[
		Setup the dimensions of the room.
		This builds the walls, floors and ceiling
	]]
	local function setDimensions(x, z, y)
		x = tonumber(x)
		z = tonumber(z)
		y = tonumber(y or 7)
		assertAbove(
			x and x > 0 and x <= 32 and
			z and z > 0 and z <= 32 and
			y and y > 0 and y <= 32,
			"X and Z must be specified and between 1 and 32 inclusive")
		assertAbove(not xSize, "Dimensions already specified")

		xSize = x
		ySize = y
		zSize = z

		-- Walls on x plane
		Builder.box(
			-1, xSize + 2,
			-1, ySize + 2,
			-1, 1,
			Config.World.Wall
		)

		Builder.box(
			-1, xSize + 2,
			-1, ySize + 2,
			zSize + 1, 1,
			Config.World.Wall
		)

		-- Walls on z plane
		Builder.box(
			-1, 1,
			-1, ySize + 2,
			-1, zSize + 2,
			Config.World.Wall
		)

		Builder.box(
			xSize + 1, 1,
			-1, ySize + 2,
			-1, zSize + 2,
			Config.World.Wall
		)

		-- Ceiling/floor
		Builder.box(
			0, xSize + 1,
			-1, 1,
			0, zSize + 1,
			Config.World.Floor
		)

		Builder.box(
			0, xSize + 1,
			ySize, 1,
			0, zSize + 1,
			Config.World.Ceiling
		)
	end

	--[[
		Set the player's location,
		This teleports them there
	]]
	local function setPlayer(x, z, y)
		x = tonumber(x)
		z = tonumber(z)
		y = tonumber(y or 0)
		assertAbove(xSize, "Dimensions must be set first")
		assertAbove(
			x and x >= 0 and x <= xSize and
			z and z >= 0 and z <= zSize and
			y and y >= 0 and y <= ySize - 1,
			"x, y and z must be within dimensions")
		assertAbove(not xPlayer, "Player already specified")

		xPlayer = x
		yPlayer = y
		zPlayer = z

		execAsync("tp @a " .. (xBase + x) .. " " .. (yBase + y) .. " " .. (zBase + z))
		execAsync("gamemode a @a") -- Force survival mode
		execAsync("gamemode c @a[name=ThatVeggie]") -- Unless you are me!
	end

	--[[
		Set the exit. By default this is composed of a tier-1 beacon
		with light-blue stained glass above
	]]
	local function setExit(x, z, y)
		x = tonumber(x)
		z = tonumber(z)
		y = tonumber(y or 0)
		assertAbove(xSize, "Dimensions must be set first")
		assertAbove(
			x and x >= 0 and x <= xSize and
			z and z >= 0 and z <= zSize and
			y and y >= 0 and y <= ySize - 1,
			"x, y and z must be within dimensions")
		assertAbove(not xExit, "Exit already specified")

		xExit = x
		yExit = y
		zExit = z

		-- Build beacon
		Builder.box(
			x - 1, 3,
			y - 3, 1,
			z - 1, 3,
			"minecraft:iron_block"
		)

		Builder.pixel(x, y - 2, z, "minecraft:beacon")
		Builder.pixel(x, y - 1, z, Config.World.Exit)
	end

	local function addItem(x, y, z, item)
		x = tonumber(x)
		z = tonumber(z)
		y = tonumber(y or 0)
		assertAbove(xSize, "Dimensions must be set first")
		assertAbove(
			x and x >= 0 and x <= xSize and
			z and z >= 0 and z <= zSize and
			y and y >= 0 and y <= ySize - 1,
			"x, y and z must be within dimensions")

		execAsync(
			"summon Item " .. (xBase + x) .. " " .. (yBase + y) .. " " .. (zBase + z) .. " " ..
			Utils.serializeJSON(Items.itemEntity(item, true))
		)

		print("summon Item " .. (xBase + x) .. " " .. (yBase + y) .. " " .. (zBase + z) .. " " ..
			Utils.serializeJSON(Items.itemEntity(item, true)))
	end

	local function tick()
		-- Because the radius is stupid we check for one block below instead
		return not exec("testfor @a[x=" .. (xExit + xBase) .. ",y=" .. (yExit + yBase - 1) .. ",z=" .. (zExit + zBase) ..",r=1]")
	end


	return {
		setDimensions = setDimensions,
		setPlayer = setPlayer,
		setExit = setExit,
		tick = tick,
		addItem = addItem
	}
end

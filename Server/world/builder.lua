local execAsync = commands.native.execAsync

local xStart, yStart, zStart = commands.getBlockPosition()

local set = {}
local function pixel(x, y, z, type)
	execAsync("setblock " .. (x + xStart) .. " " .. (y + yStart) .. " " .. (z + zStart) .. " " .. type)
	set[#set + 1] = {x, y, z}
end

local function box(xStart, xSize, yStart, ySize, zStart, zSize, type)
	for x = xStart, xStart + xSize - 1 do
		for y = yStart, yStart + ySize - 1 do
			for z = zStart, zStart + zSize - 1 do
				pixel(x, y, z, type)
			end
		end
	end
end

local function setPosition(x, y, z)
	xStart, yStart, zStart = x, y, z
end

local function clear()
	local mSet = set
	set = {}
	for _, k in pairs(mSet) do
		pixel(k[1], k[2], k[3], "minecraft:air")
	end
end

return {
	pixel = pixel,
	box = box,
	setPosition = setPosition,
	clear = clear,
}

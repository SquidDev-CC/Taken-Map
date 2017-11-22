--- commands.async.fills the world with blocks

local commands = require "server.commands"
local type, assert = type, assert

--- Create a new map data
local function create(xSize, ySize, zSize)
	local data = {}
	for x = 1, xSize do
		local xData = {}
		data[x] = xData

		for y = 1, ySize do
			local yData = {}
			xData[y] = yData

			for z = 1, zSize do yData[z] = false end
		end
	end

	return data
end

local function toTable(a)
	local ty = type(a)
	if ty == "table" then
		return a
	elseif ty == "string" then
		return { a, 1, 1, 1 }
	else
		return nil
	end
end

local function eq(a, b)
	if a == b then return true end
	if a == nil or b == nil or a == false or b == false then return false end

	if type(a) == "string" then a = { a, 1, 1, 1} end
	if type(b) == "string" then b = { b, 1, 1, 1} end

	assert(type(a) == "table")
	assert(type(b) == "table")

	for i = 1, 4 do
		if a[i] ~= b[i] then return false end
	end
	return true
end

local function buildRow(data, length, x, y, z, dX, dY, dZ, index)
	local run, runLength
	for _ = 1, length do
		local row = data[x][y]
		local current = row[z]

		if run ~= nil and eq(run, current) then
			runLength = runLength + 1
			row[z] = false
		else
			if run ~= nil then
				run[index] = runLength
			end

			run = toTable(current)
			if run ~= nil then
				runLength = 1
				row[z] = run
			end
		end

		x = x + dX
		y = y + dY
		z = z + dZ
	end

	if run ~= nil then
		run[index] = runLength
	end
end

local function optimise(data)
	local xSize, ySize, zSize = #data, #data[1], #data[1][1]

	for x = 1, xSize do
		for y = 1, ySize do
			buildRow(data, zSize, x, y, 1, 0, 0, 1, 4)
		end
	end

	for x = 1, xSize do
		for z = 1, zSize do
			buildRow(data, ySize, x, 1, z, 0, 1, 0, 3)
		end
	end

	for y = 1, ySize do
		for z = 1, zSize do
			buildRow(data, xSize, 1, y, z, 1, 0, 0, 2)
		end
	end
end

local function build(data, xOff, yOff, zOff, blocks)
	local xSize, ySize, zSize = #data, #data[1], #data[1][1]

	local index = 1 -- For overriding blocks
	for x = 1, xSize do
		local xRow = data[x]
		for y = 1, ySize do
			local yRow = xRow[y]
			for z = 1, zSize do
				local block = yRow[z]
				local ty = type(block)
				if ty == "string" then
					if blocks then
						block = blocks[index]
						index = index + 1
					end
					commands.async.fill(x + xOff, y + yOff, z + zOff, x + xOff, y + yOff, z + zOff, block)
				elseif ty == "table" then
					local blockName = block[1]
					if blocks then
						blockName = blocks[index]
						index = index + 1
					end
					commands.async.fill(
						x + xOff, y + yOff,z + zOff,
						x + xOff + block[2] - 1, y + yOff + block[3] - 1, z + zOff + block[4] - 1,
						blockName
					)
				end
			end

		end
	end
end

return {
	create = create,
	optimise = optimise,
	build = build,
}

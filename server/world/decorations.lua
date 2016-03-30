local decorations = {}

local function add(name, number)
	decorations[name] = "minecraft:stained_hardened_clay " .. math.floor(math.log(number) / math.log(2))
end

for name, v in pairs(colors) do
	if type(v) == "number" then add(name, v) end
end

for name, v in pairs(colours) do
	if type(v) == "number" then add(name, v) end
end


return decorations

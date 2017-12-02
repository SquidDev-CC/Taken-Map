local function range(start, finish)
	if finish == nil then
		finish = start
		start = 1
	end

	local out, n = {}, 0
	for i = start, finish do
		n = n + 1
		out[n] = i
	end

	return out
end

local function combine(left, right, func)
	local out, n = {}, 0
	for i = 1, #left do
		local l = left[i]
		for j = 1, #right do
			n = n + 1
			out[n] = func(l, right[j])
		end
	end

	return out
end

local function copy(table, blacklist, cache)
	if cache then
		local val = cache[table]
		if val then return val end
	else
		cache = {}
	end

	local out = {}
	cache[table] = out
	for k, v in pairs(table) do
		if not blacklist or not blacklist[k] then
			if type(v) == "table" then
				out[k] = copy(v, blacklist, cache)
			else
				out[k] = v
			end
		end
	end

	return out
end

--- Determine whether two collections are equal
local function equal(a, b)
	if a == b then return true end

	-- Ensure both objects are tables.
	if type(a) ~= "table"or type(b) ~= "table" then
		return false
	end

	-- Check no keys are missing
	for k in pairs(a) do
		if b[k] == nil then return false end
	end

	-- And check all values are equal
	for k in pairs(b) do
		if a[k] ~= b[k] then return false end
	end

	return true
end

return {
	range = range,
	combine = combine,
	copy = copy,
	equal = equal,
}

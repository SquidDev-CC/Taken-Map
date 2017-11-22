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

return {
	range = range,
	combine = combine,
	copy = copy,
}

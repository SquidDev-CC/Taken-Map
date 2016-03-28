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

return {
	range = range,
	combine = combine,
}

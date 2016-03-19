local function assertEq(expected, actual, message)
	if expected ~= actual then
		if message then
			message = " " .. message
		else
			message = ""
		end
		error("Expected " .. tostring(expected) .. message .. ", got " .. tostring(actual), 0)
	end
end

local function assertLt(expected, actual, message)
	if expected >= actual then
		if message then
			message = " " .. message
		else
			message = ""
		end
		error("Expected " .. tostring(expected) .. message .. ", got " .. tostring(actual), 0)
	end
end

local function assertGt(expected, actual, message)
	if expected <= actual then
		if message then
			message = " " .. message
		else
			message = ""
		end
		error("Expected " .. tostring(expected) .. message .. ", got " .. tostring(actual), 0)
	end
end

return setmetatable({
	eq = assertEq,
	lt = assertLt,
	gt = assertGt,
}, { __call = function(self, ...) return assert(...) end })

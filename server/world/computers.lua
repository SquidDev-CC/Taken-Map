local computers = {}

local merge
merge = function(old, new)
	for key, newValue in pairs(new or {}) do
		local oldValue = old[key]

		local oldType = type(oldValue)
		if oldType == "nil" then
			old[key] = newValue
		elseif oldType ~= type(newValue) then
			error("Type must be " .. oldType .. " for " .. key)
		elseif oldType == "table" then
			old[key] = merge(oldValue, newValue)
		else
			old[key] = newValue
		end
	end
	return old
end

function computers.createPocket(id, label, wireless, otherTags)
	return merge({
		display = {
			Name = label or  "Computer " .. id,
		},
		computerID = id,
		upgrade = wireless and 1 or 0,
	}, otherTags)
end

return computers

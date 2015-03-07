local function serializeJSONImpl( t, tTracking )
	local sType = type(t)
	if t == EMPTY_ARRAY then
		return "[]"

	elseif sType == "table" then
		if tTracking[t] ~= nil then
			error( "Cannot serialize table with recursive entries", 0 )
		end
		tTracking[t] = true

		if next(t) == nil then
			-- Empty tables are simple
			return "{}"
		else
			-- Other tables take more work
			local sObjectResult = "{"
			local sArrayResult = "["
			local nObjectSize = 0
			local nArraySize = 0
			for k,v in pairs(t) do
				if type(k) == "string" then
					local sEntry = serializeJSONImpl( k, tTracking ) .. ":" .. serializeJSONImpl( v, tTracking )
					if nObjectSize == 0 then
						sObjectResult = sObjectResult .. sEntry
					else
						sObjectResult = sObjectResult .. "," .. sEntry
					end
					nObjectSize = nObjectSize + 1
				end
			end
			for n,v in ipairs(t) do
				local sEntry = serializeJSONImpl( v, tTracking )
				if nArraySize == 0 then
					sArrayResult = sArrayResult .. sEntry
				else
					sArrayResult = sArrayResult .. "," .. sEntry
				end
				nArraySize = nArraySize + 1
			end
			sObjectResult = sObjectResult .. "}"
			sArrayResult = sArrayResult .. "]"
			if nObjectSize > 0 or nArraySize == 0 then
				return sObjectResult
			else
				return sArrayResult
			end
		end

	elseif sType == "string" then
		local s = string.format("%q", t)
		if '"' .. t .. '"' == s then
			return t
		else
			return s
		end

	elseif sType == "number" or sType == "boolean" then
		return tostring(t)

	else
		error( "Cannot serialize type "..sType, 0 )

	end
end

function serializeJSON( t )
	local tTracking = {}
	return serializeJSONImpl( t, tTracking )
end

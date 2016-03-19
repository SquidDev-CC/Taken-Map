local commands = commands
return function(name, wrap, verbose)
	if wrap or verbose then
		local func = commands[name]
		return function(...)
			local success, res = func(...)
			if not success or verbose then
				print(textutils.serialize({...}))
				print(textutils.serialize(res))
			end
		end
	else
		return commands.async[name]
	end
end

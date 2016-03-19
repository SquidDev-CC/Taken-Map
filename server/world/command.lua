local commands = commands

return function(name, wrap, verbose)
	if not commands then error("No commands") verbose = true end
	if wrap or verbose then
		local func
		if not commands then
			func = print
		else
		 	func = commands[name]
		end
		return function(...)
			local success, res = func(...)
			if not success or verbose then
				print(textutils.serialize({...}))
				print(textutils.serialize(res))
			end

			return success, res
		end
	else
		return commands.async[name]
	end
end

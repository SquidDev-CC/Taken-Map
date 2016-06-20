--- Main bootstrapper for the script
arg = { ... }
if commands then
	require "server"
elseif pocket then
	require "client"
else
	error("Expected to be run on command or pocket computer")
end

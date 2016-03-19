local original = term.current()

assert(xpcall(
	function() require "client.loop" end,
	function(msg)
		term.redirect(original)
		term.setCursorPos(1, 1)
		term.setBackgroundColor(colors.black)
		term.clear()
		if debug then print(debug.traceback(msg)) end
	end
))

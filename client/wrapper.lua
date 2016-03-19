local original = term.getCurrent()

assert(xpcall(
	function() require "client.ide.startup" end,
	function(msg)
		term.redirect(original)
		term.setCursorPos(1, 1)
		term.setBackgroundColor(color.black)
		term.clear()
		print(debug.traceback(msg))
		return msg
	end
))

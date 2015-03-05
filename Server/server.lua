rednet.open("back")
rednet.send(Config.Editor.Id, {
	Action = 'Files',
	Files = {
		{
			Name = "Testing.lua",
			Lines = {
				"for i = 0, 10 do",
				"  print('HELLO')",
				"end",
				"-- Insert code here",
				"print('Hello')",
			},

			ReadOnly = {
				{1, 3},
				{5}
			},
		},
		{
			Name = "Another.lua",
			Lines = {
				"-- So welcome to this thing",
				"do.evilThing()",
				"-- Nehehee!",
			},

			ReadOnly = {
				{2},
			},
		},
	}
})

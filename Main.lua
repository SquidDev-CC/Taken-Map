term.redirect(term.native())

local bedrockPath='/' if OneOS then OneOS.LoadAPI('/System/API/Bedrock.lua', false)elseif fs.exists(bedrockPath..'/Bedrock')then os.loadAPI(bedrockPath..'/Bedrock')else if http then print('Downloading Bedrock...')local h=http.get('http://pastebin.com/raw.php?i=0MgKNqpN')if h then local f=fs.open(bedrockPath..'/Bedrock','w')f.write(h.readAll())f.close()h.close()os.loadAPI(bedrockPath..'/Bedrock')else error('Failed to download Bedrock. Is your internet working?') end else error('This program needs to download Bedrock to work. Please enable HTTP.') end end if Bedrock then Bedrock.BasePath = bedrockPath Bedrock.ProgramPath = shell.getRunningProgram() end


local program = Bedrock:Initialise()

program:Run(function()
end)
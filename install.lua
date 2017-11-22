--- An awful install script for taken

local json
do
	--Credit goes to http://www.computercraft.info/forums2/index.php?/topic/5854-json-api-v201-for-computercraft/
	local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}
	local whites = {['\n']=true; ['r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
	local function removeWhite(str)
		while whites[str:sub(1, 1)] do str = str:sub(2) end
		return str
	end

	local jsonParseValue
	local function jsonParseBoolean(str)
		if str:sub(1, 4) == "true" then
			return true, removeWhite(str:sub(5))
		else
			return false, removeWhite(str:sub(6))
		end
	end

	local function jsonParseNull(str)
		return nil, removeWhite(str:sub(5))
	end

	local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
	local function jsonParseNumber(str)
		local i = 1
		while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
			i = i + 1
		end
		local val = tonumber(str:sub(1, i - 1))
		str = removeWhite(str:sub(i))
		return val, str
	end

	local function jsonParseString(str)
		local i,j = str:find('^".-[^\\]"')
		local s = str:sub(i + 1,j - 1)

		for k,v in pairs(controls) do
			s = s:gsub(v, k)
		end
		str = removeWhite(str:sub(j + 1))
		return s, str
	end

	local function jsonParseArray(str)
		str = removeWhite(str:sub(2))

		local val = {}
		local i = 1
		while str:sub(1, 1) ~= "]" do
			local v = nil
			v, str = jsonParseValue(str)
			val[i] = v
			i = i + 1
			str = removeWhite(str)
		end
		str = removeWhite(str:sub(2))
		return val, str
	end

	local function jsonParseMember(str)
		local k = nil
		k, str = jsonParseValue(str)
		local val = nil
		val, str = jsonParseValue(str)
		return k, val, str
	end

	local function jsonParseObject(str)
		str = removeWhite(str:sub(2))

		local val = {}
		while str:sub(1, 1) ~= "}" do
			local k, v = nil, nil
			k, v, str = jsonParseMember(str)
			val[k] = v
			str = removeWhite(str)
		end
		str = removeWhite(str:sub(2))
		return val, str
	end

	function jsonParseValue(str)
		local fchar = str:sub(1, 1)
		if fchar == "{" then
			return jsonParseObject(str)
		elseif fchar == "[" then
			return jsonParseArray(str)
		elseif tonumber(fchar) ~= nil or numChars[fchar] then
			return jsonParseNumber(str)
		elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
			return jsonParseBoolean(str)
		elseif fchar == "\"" then
			return jsonParseString(str)
		elseif str:sub(1, 4) == "null" then
			return jsonParseNull(str)
		end
		return nil
	end

	local function jsonDecode(str)
		str = removeWhite(str)
		t = jsonParseValue(str)
		return t
	end

	json = function(url)
		local file = http.get(url)
		return file and jsonDecode(file.readAll())
	end
end

--- Attempt to download a file listing
local function getTree(repo, branch, tries)
	local path = 'https://api.github.com/repos/'..repo..'/git/trees/'..branch..'?recursive=1'
	for i = 1, tries do
		local result = json(path)
		if result and result.tree then
			return result.tree
		end
	end

	return nil
end

--- Download individual files
local function download(repo, branch, tries, tree)
	local getRaw = 'https://raw.github.com/'..repo..'/'..branch..'/'
	local success, failures = {}, {}

	local count = 0
	local total = 0

	local function updateCount()
		local x, y = term.getCursorPos()
		term.setCursorPos(1, y)
		term.clearLine()
		write(("Downloading: %s/%s (%s%%)"):format(count, total, count / total * 100))
	end

	-- Download a file and store it in the tree
	local function download(file)
		local path = file.path
		local contents

		-- Attempt to download the file
		for i = 1, tries do
			local url = (getRaw .. path):gsub(' ','%%20')
			local f = http.get(url)

			if f then
				count = count + 1
				success[path] = f.readAll()
				updateCount()
				return
			end
		end

		failures[path] = true
		updateCount()
	end

	local functions = {}
	for _, file in ipairs(tree) do
		if file.type == 'blob' then
			total = total + 1
			functions[total] = function() download(file) end
		end
	end

	write("Downloading...")
	parallel.waitForAll(unpack(functions))
	print()
	return success, failures
end

if fs.exists("startup") and not fs.isDir("startup") then
	error("Some startup file already exists. Please delete it or create a startup directory.")
end

local repo, branch, tries = "SquidDev-CC/Taken-Map", "master", 2

local tree = getTree(repo, branch, tries)
if not tree then error("Cannot fetch tree", 0) end

local prefixes = { "client", "data", "server", "shared", "init.lua" }
for i = 1, #prefixes do prefixes[prefixes[i]] = i end
for i = #tree, 1, -1 do
	if not prefixes[tree[i].path:match("^([^/]+)")] then
		table.remove(tree, i)
	end
end

local files, errored = download(repo, branch, tries, tree)
if next(errored) then error("Some files failed to download\n", 0) end

for k, v in pairs(files) do
	local handle = fs.open(fs.combine("taken", k), "w")
	handle.write(v)
	handle.close()
end


local handle = fs.open("startup/99_taken.lua", "w")
handle.writeLine([[shell.run("/taken/init.lua")]])
handle.close()

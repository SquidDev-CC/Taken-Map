--- The main lua parser and lexer.
-- LexLua returns a Lua token stream, with tokens that preserve
-- all whitespace formatting information.
-- ParseLua returns an AST, internally relying on LexLua.
-- @module howl.lexer.parse

local min = math.min
local insert = table.insert

local function TokenList(tokens)
	local n = #tokens
	local pointer = 1

	--- Get this element in the token list
	-- @tparam int offset The offset in the token list
	local function Peek(offset)
		return tokens[min(n, pointer + (offset or 0))]
	end

	--- Get the next token in the list
	-- @tparam table tokenList Add the token onto this table
	-- @treturn Token The token
	local function Get(tokenList)
		local token = tokens[pointer]
		pointer = min(pointer + 1, n)
		if tokenList then
			insert(tokenList, token)
		end
		return token
	end

	--- Check if the next token is of a type
	-- @tparam string type The type to compare it with
	-- @treturn bool If the type matches
	local function Is(type)
		return Peek().Type == type
	end

	--- Check if the next token is a symbol and return it
	-- @tparam string symbol Symbol to check (Optional)
	-- @tparam table tokenList Add the token onto this table
	-- @treturn [ 0 ] ?|token If symbol is not specified, return the token
	-- @treturn [ 1 ] boolean If symbol is specified, return true if it matches
	local function ConsumeSymbol(symbol, tokenList)
		local token = Peek()
		if token.Type == 'Symbol' then
			if symbol then
				if token.Data == symbol then
					if tokenList then insert(tokenList, token) end
					pointer = pointer + 1
					return true
				else
					return nil
				end
			else
				if tokenList then insert(tokenList, token) end
				pointer = pointer + 1
				return token
			end
		else
			return nil
		end
	end

	--- Check if the next token is a keyword and return it
	-- @tparam string kw Keyword to check (Optional)
	-- @tparam table tokenList Add the token onto this table
	-- @treturn [ 0 ] ?|token If kw is not specified, return the token
	-- @treturn [ 1 ] boolean If kw is specified, return true if it matches
	local function ConsumeKeyword(kw, tokenList)
		local token = Peek()
		if token.Type == 'Keyword' and token.Data == kw then
			if tokenList then insert(tokenList, token) end
			pointer = pointer + 1
			return true
		else
			return nil
		end
	end

	--- Check if the next token matches is a keyword
	-- @tparam string kw The particular keyword
	-- @treturn boolean If it matches or not
	local function IsKeyword(kw)
		local token = Peek()
		return token.Type == 'Keyword' and token.Data == kw
	end

	--- Check if the next token matches is a symbol
	-- @tparam string symbol The particular symbol
	-- @treturn boolean If it matches or not
	local function IsSymbol(symbol)
		local token = Peek()
		return token.Type == 'Symbol' and token.Data == symbol
	end

	--- Check if the next token is an end of file
	-- @treturn boolean If the next token is an end of file
	local function IsEof()
		return Peek().Type == 'Eof'
	end

	return {
		Peek = Peek,
		Get = Get,
		Is = Is,
		ConsumeSymbol = ConsumeSymbol,
		ConsumeKeyword = ConsumeKeyword,
		IsKeyword = IsKeyword,
		IsSymbol = IsSymbol,
		IsEof = IsEof,
		Tokens = tokens,
	}
end

local function createLookup(tbl)
	for k,v in ipairs(tbl) do tbl[v] = k end
	return tbl
end

local digits = createLookup { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }
local hexDigits = createLookup { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f' }
local symbols = createLookup { '+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#' }
local keywords = createLookup {
	'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'goto', 'if',
	'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while',
}
local statListCloseKeywords = createLookup { 'end', 'else', 'elseif', 'until' }
local unops = createLookup { '-', 'not', '#' }

--- One token
-- @table Token
-- @tparam string Type The token type
-- @param Data Data about the token
-- @tparam string CommentType The type of comment  (Optional)
-- @tparam number Line Line number (Optional)
-- @tparam number Char Character number (Optional)
local Token = {}

--- Creates a string representation of the token
-- @treturn string The resulting string
function Token:Print()
	return "<"..(self.Type .. string.rep(' ', math.max(3, 12-#self.Type))).."  "..(self.Data or '').." >"
end

local tokenMeta = { __index = Token }

--- Create a list of @{Token|tokens} from a Lua source
-- @tparam string src Lua source code
-- @treturn TokenList The list of @{Token|tokens}
local function LexLua(src)
	--token dump
	local tokens = {}

	do -- Main bulk of the work
		local sub = string.sub

		--line / char / pointer tracking
		local pointer = 1
		local line = 1
		local char = 1

		--get / peek functions
		local function get()
			local c = sub(src, pointer,pointer)
			if c == '\n' then
				char = 1
				line = line + 1
			else
				char = char + 1
			end
			pointer = pointer + 1
			return c
		end

		local function peek(n)
			n = n or 0
			return sub(src, pointer+n,pointer+n)
		end
		local function consume(chars)
			local c = peek()
			for i = 1, #chars do
				if c == chars:sub(i,i) then return get() end
			end
		end

		--shared stuff
		local function generateError(err)
			error(">> :"..line..":"..char..": "..err, 0)
		end

		local function tryGetLongString()
			local start = pointer
			if peek() == '[' then
				local equalsCount = 0
				local depth = 1
				while peek(equalsCount+1) == '=' do
					equalsCount = equalsCount + 1
				end
				if peek(equalsCount+1) == '[' then
					--start parsing the string. Strip the starting bit
					for _ = 0, equalsCount+1 do get() end

					--get the contents
					local contentStart = pointer
					while true do
						--check for eof
						if peek() == '' then
							generateError("Expected `]"..string.rep('=', equalsCount).."]` near <eof>.", 3)
						end

						--check for the end
						local foundEnd = true
						if peek() == ']' then
							for i = 1, equalsCount do
								if peek(i) ~= '=' then foundEnd = false end
							end
							if peek(equalsCount+1) ~= ']' then
								foundEnd = false
							end
						else
							if peek() == '[' then
								-- is there an embedded long string?
								local embedded = true
								for i = 1, equalsCount do
									if peek(i) ~= '=' then
										embedded = false
										break
									end
								end
								if peek(equalsCount + 1) == '[' and embedded then
									-- oh look, there was
									depth = depth + 1
									for i = 1, (equalsCount + 2) do
										get()
									end
								end
							end
							foundEnd = false
						end

						if foundEnd then
							depth = depth - 1
							if depth == 0 then
								break
							else
								for i = 1, equalsCount + 2 do
									get()
								end
							end
						else
							get()
						end
					end

					--get the interior string
					local contentString = src:sub(contentStart, pointer-1)

					--found the end. Get rid of the trailing bit
					for i = 0, equalsCount+1 do get() end

					--get the exterior string
					local longString = src:sub(start, pointer-1)

					--return the stuff
					return contentString, longString
				else
					return nil
				end
			else
				return nil
			end
		end

		local function isDigit(c) return c >= '0' and c <= '9' end

		--main token emitting loop
		while true do
			--get leading whitespace. The leading whitespace will include any comments
			--preceding the token. This prevents the parser needing to deal with comments
			--separately.
			local comments, cn
			while true do
				local c = sub(src, pointer, pointer)
				if c == '#' and peek(1) == '!' and line == 1 then
					-- #! shebang for linux scripts
					get()
					get()
					while peek() ~= '\n' and peek() ~= '' do
						get()
					end
				end
				if c == ' ' or c == '\t' then
					--whitespace
					char = char + 1
					pointer = pointer + 1
				elseif c == '\n' or c == '\r' then
					char = 1
					line = line + 1
					pointer = pointer + 1
				elseif c == '-' and peek(1) == '-' then
					--comment
					get()
					get()
					local startLine, startChar, startPointer = line, char, pointer
					local wholeText, _ = tryGetLongString()
					if not wholeText then
						local next = sub(src, pointer, pointer)
						while next ~= '\n' and next ~= '' do
							get()
							next = sub(src, pointer, pointer)
						end
						wholeText = sub(src, startPointer, pointer - 1)
					end
					if not comments then
						comments = {}
						cn = 0
					end
					cn = cn + 1
					comments[cn] = {
						Data = wholeText,
						Line = startLine,
						Char = startChar,
					}
				else
					break
				end
			end

			--get the initial char
			local thisLine = line
			local thisChar = char
			local c = sub(src, pointer, pointer)

			--symbol to emit
			local toEmit = nil

			--branch on type
			if c == '' then
				--eof
				toEmit = { Type = 'Eof' }

			elseif (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or c == '_' then
				--ident or keyword
				local start = pointer
				repeat
					get()
					c = sub(src, pointer, pointer)
				until not ((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or c == '_' or (c >= '0' and c <= '9'))
				local dat = src:sub(start, pointer-1)
				if keywords[dat] then
					toEmit = {Type = 'Keyword', Data = dat}
				else
					toEmit = {Type = 'Ident', Data = dat}
				end

			elseif (c >= '0' and c <= '9') or (c == '.' and digits[peek(1)]) then
				--number const
				local start = pointer
				if c == '0' and peek(1) == 'x' then
					get();get()
					while hexDigits[peek()] do get() end
					if consume('Pp') then
						consume('+-')
						while digits[peek()] do get() end
					end
				else
					while digits[peek()] do get() end
					if consume('.') then
						while digits[peek()] do get() end
					end
					if consume('Ee') then
						consume('+-')

						if not digits[peek()] then generateError("Expected exponent") end
						repeat get() until not digits[peek()]
					end

					local n = peek():lower()
					if (n >= 'a' and n <= 'z') or n == '_' then
						generateError("Invalid number format")
					end
				end
				toEmit = {Type = 'Number', Data = src:sub(start, pointer-1)}

			elseif c == '\'' or c == '\"' then
				local start = pointer
				--string const
				local delim = get()
				local contentStart = pointer
				while true do
					local c = get()
					if c == '\\' then
						get() --get the escape char
					elseif c == delim then
						break
					elseif c == '' then
						generateError("Unfinished string near <eof>")
					end
				end
				local content = src:sub(contentStart, pointer-2)
				local constant = src:sub(start, pointer-1)
				toEmit = {Type = 'String', Data = constant, Constant = content}

			elseif c == '[' then
				local content, wholetext = tryGetLongString()
				if wholetext then
					toEmit = {Type = 'String', Data = wholetext, Constant = content}
				else
					get()
					toEmit = {Type = 'Symbol', Data = '['}
				end

			elseif c == '>' or c == '<' or c == '=' then
				get()
				if consume('=') then
					toEmit = {Type = 'Symbol', Data = c..'='}
				else
					toEmit = {Type = 'Symbol', Data = c}
				end

			elseif c == '~' then
				get()
				if consume('=') then
					toEmit = {Type = 'Symbol', Data = '~='}
				else
					generateError("Unexpected symbol `~` in source.", 2)
				end

			elseif c == '.' then
				get()
				if consume('.') then
					if consume('.') then
						toEmit = {Type = 'Symbol', Data = '...'}
					else
						toEmit = {Type = 'Symbol', Data = '..'}
					end
				else
					toEmit = {Type = 'Symbol', Data = '.'}
				end

			elseif c == ':' then
				get()
				if consume(':') then
					toEmit = {Type = 'Symbol', Data = '::'}
				else
					toEmit = {Type = 'Symbol', Data = ':'}
				end

			elseif symbols[c] then
				get()
				toEmit = {Type = 'Symbol', Data = c}

			else
				local contents, all = tryGetLongString()
				if contents then
					toEmit = {Type = 'String', Data = all, Constant = contents}
				else
					generateError("Unexpected Symbol `"..c.."` in source.", 2)
				end
			end

			--add the emitted symbol, after adding some common data
			toEmit.Line = thisLine
			toEmit.Char = thisChar
			if comments then toEmit.Comments = comments end
			tokens[#tokens+1] = toEmit

			--halt after eof has been emitted
			if toEmit.Type == 'Eof' then break end
		end
	end

	--public interface:
	local tokenList = TokenList(tokens)

	return tokenList
end

--- Create a AST tree from a Lua Source
-- @tparam TokenList tok List of tokens from @{LexLua}
-- @treturn table The AST tree
local function ParseLua(tok)
	--- Generate an error
	-- @tparam string msg The error message
	-- @raise The produces error message
	local function GenerateError(msg)
		local err = tok.Peek().Line..":"..tok.Peek().Char..": "..msg.."\n"
		local peek = tok.Peek()
		err = err.. " got " .. peek.Type .. ": " .. peek.Data.. "\n"
		error(err)
	end

	local ParseExpr,
	      ParseStatementList,
	      ParseSimpleExpr,
	      ParsePrimaryExpr,
	      ParseSuffixedExpr

	--- Parse the function definition and its arguments
	-- @tparam table tokenList A table to fill with tokens
	-- @treturn Node A function Node
	local function ParseFunctionArgsAndBody()
		if not tok.ConsumeSymbol('(') then
			GenerateError("`(` expected.")
		end

		--arg list
		local argList = {}
		local isVarArg = false
		while not tok.ConsumeSymbol(')') do
			if tok.Is('Ident') then
				argList[#argList+1] = tok.Get().Data
				if not tok.ConsumeSymbol(',') then
					if tok.ConsumeSymbol(')') then
						break
					else
						GenerateError("`)` expected.")
					end
				end
			elseif tok.ConsumeSymbol('...') then
				isVarArg = true
				if not tok.ConsumeSymbol(')') then
					GenerateError("`...` must be the last argument of a function.")
				end
				break
			else
				GenerateError("Argument name or `...` expected")
			end
		end

		--body
		local body = ParseStatementList()

		--end
		if not tok.ConsumeKeyword('end') then
			GenerateError("`end` expected after function body")
		end

		return {
			AstType   = 'Function',
			Arguments = argList,
			Body      = body,
			VarArg    = isVarArg,

		}
	end

	--- Parse a simple expression
	-- @treturn Node the resulting node
	function ParsePrimaryExpr()
		if tok.ConsumeSymbol('(') then
			local ex = ParseExpr()
			if not tok.ConsumeSymbol(')') then
				GenerateError("`)` Expected.")
			end

			return {
				AstType = 'Parentheses',
				Inner   = ex,
			}

		elseif tok.Is('Ident') then
			local id = tok.Get()

			return {
				AstType  = 'VarExpr',
				Name     = id.Data,
			}
		else
			GenerateError("primary expression expected")
		end
	end

	--- Parse some table related expressions
	-- @tparam boolean onlyDotColon Only allow '.' or ':' nodes
	-- @treturn Node The resulting node
	function ParseSuffixedExpr(onlyDotColon)
		--base primary expression
		local prim = ParsePrimaryExpr()

		while true do
			if tok.IsSymbol('.') or tok.IsSymbol(':') then
				local symb = tok.Get().Data
				if not tok.Is('Ident') then
					GenerateError("<Ident> expected.")
				end
				local id = tok.Get()

				prim = {
					AstType  = 'MemberExpr',
					Base     = prim,
					Indexer  = symb,
					Ident    = id,
				}

			elseif not onlyDotColon and tok.ConsumeSymbol('[') then
				local ex = ParseExpr()
				if not tok.ConsumeSymbol(']') then
					GenerateError("`]` expected.")
				end

				prim = {
					AstType  = 'IndexExpr',
					Base     = prim,
					Index    = ex,
				}

			elseif not onlyDotColon and tok.ConsumeSymbol('(') then
				local args = {}
				while not tok.ConsumeSymbol(')') do
					args[#args+1] = ParseExpr()
					if not tok.ConsumeSymbol(',') then
						if tok.ConsumeSymbol(')') then
							break
						else
							GenerateError("`)` Expected.")
						end
					end
				end

				prim = {
					AstType   = 'CallExpr',
					Base      = prim,
					Arguments = args,
				}

			elseif not onlyDotColon and tok.Is('String') then
				--string call
				prim = {
					AstType    = 'StringCallExpr',
					Base       = prim,
					Arguments  = { tok.Get() },
				}

			elseif not onlyDotColon and tok.IsSymbol('{') then
				--table call
				local ex = ParseSimpleExpr()
				-- FIX: ParseExpr() parses the table AND and any following binary expressions.
				-- We just want the table

				prim = {
					AstType   = 'TableCallExpr',
					Base      = prim,
					Arguments = { ex },

				}

			else
				break
			end
		end
		return prim
	end

	--- Parse a simple expression (strings, numbers, booleans, varargs)
	-- @treturn Node The resulting node
	function ParseSimpleExpr()
		local next = tok.Peek()
		local type = next.Type
		if type == 'Number' then
			return {
				AstType = 'NumberExpr',
				Value   = tok.Get(),
			}
		elseif type == 'String' then
			return {
				AstType = 'StringExpr',
				Value   = tok.Get(),
			}
		elseif type == 'Keyword' then
			local data = next.Data
			if data == 'nil' then
				tok.Get()
				return {
					AstType = 'NilExpr',
				}
			elseif data == 'false' or data == 'true' then
				return {
					AstType = 'BooleanExpr',
					Value   = (tok.Get().Data == 'true'),
				}
			elseif data == 'function' then
				tok.Get()
				local func = ParseFunctionArgsAndBody()

				func.IsLocal = true
				return func
			end
		elseif type == 'Symbol' then
			local data = next.Data
			if data == '...' then
				tok.Get()
				return {
					AstType  = 'DotsExpr',
				}
			elseif data == '{' then
				tok.Get()

				local entryList = {}
				local v = {
					AstType = 'ConstructorExpr',
					EntryList = entryList,
				}

				while true do
					if tok.IsSymbol('[') then
						--key
						tok.Get()
						local key = ParseExpr()
						if not tok.ConsumeSymbol(']') then
							GenerateError("`]` Expected")
						end
						if not tok.ConsumeSymbol('=') then
							GenerateError("`=` Expected")
						end
						local value = ParseExpr()
						entryList[#entryList+1] = {
							Type  = 'Key',
							Key   = key,
							Value = value,
						}

					elseif tok.Is('Ident') then
						--value or key
						local lookahead = tok.Peek(1)
						if lookahead.Type == 'Symbol' and lookahead.Data == '=' then
							--we are a key
							local key = tok.Get()
							if not tok.ConsumeSymbol('=') then
								GenerateError("`=` Expected")
							end
							local value = ParseExpr()
							entryList[#entryList+1] = {
								Type  = 'KeyString',
								Key   = key.Data,
								Value = value,
							}

						else
							--we are a value
							local value = ParseExpr()
							entryList[#entryList+1] = {
								Type = 'Value',
								Value = value,
							}
						end
					elseif tok.ConsumeSymbol('}') then
						break

					else
						--value
						local value = ParseExpr()
						entryList[#entryList+1] = {
							Type = 'Value',
							Value = value,
						}
					end

					if tok.ConsumeSymbol(';') or tok.ConsumeSymbol(',') then
						--all is good
					elseif tok.ConsumeSymbol('}') then
						break
					else
						GenerateError("`}` or table entry Expected")
					end
				end
				return v
			end
		end

		return ParseSuffixedExpr()
	end

	local unopprio = 8
	local priority = {
		['+'] = {6,6},
		['-'] = {6,6},
		['%'] = {7,7},
		['/'] = {7,7},
		['*'] = {7,7},
		['^'] = {10,9},
		['..'] = {5,4},
		['=='] = {3,3},
		['<'] = {3,3},
		['<='] = {3,3},
		['~='] = {3,3},
		['>'] = {3,3},
		['>='] = {3,3},
		['and'] = {2,2},
		['or'] = {1,1},
	}

	--- Parse an expression
	-- @tparam int level Current level (Optional)
	-- @treturn Node The resulting node
	function ParseExpr(level)
		level = level or 0
		--base item, possibly with unop prefix
		local exp
		if unops[tok.Peek().Data] then
			local op = tok.Get().Data
			exp = ParseExpr(unopprio)

			local nodeEx = {
				AstType = 'UnopExpr',
				Rhs     = exp,
				Op      = op,
				OperatorPrecedence = unopprio,
			}

			exp = nodeEx
		else
			exp = ParseSimpleExpr()
		end

		--next items in chain
		while true do
			local prio = priority[tok.Peek().Data]
			if prio and prio[1] > level then
				local op = tok.Get().Data
				local rhs = ParseExpr(prio[2])

				local nodeEx = {
					AstType = 'BinopExpr',
					Lhs     = exp,
					Op      = op,
					OperatorPrecedence = prio[1],
					Rhs     = rhs,
				}

				exp = nodeEx
			else
				break
			end
		end

		return exp
	end

	--- Parse a statement (if, for, while, etc...)
	-- @treturn Node The resulting node
	local function ParseStatement()
		local stat = nil

		local next = tok.Peek()
		if next.Type == "Keyword" then
			local type = next.Data
			if type == 'if' then
				tok.Get()

				--setup
				local clauses = {}
				local nodeIfStat = {
					AstType = 'IfStatement',
					Clauses = clauses,
				}
				--clauses
				repeat
					local nodeCond = ParseExpr()

					if not tok.ConsumeKeyword('then') then
						GenerateError("`then` expected.")
					end
					local nodeBody = ParseStatementList()
					clauses[#clauses+1] = {
						Condition = nodeCond,
						Body = nodeBody,
					}
				until not tok.ConsumeKeyword('elseif')

				--else clause
				if tok.ConsumeKeyword('else') then
					local nodeBody = ParseStatementList()
					clauses[#clauses+1] = {
						Body = nodeBody,
					}
				end

				--end
				if not tok.ConsumeKeyword('end') then
					GenerateError("`end` expected.")
				end

				stat = nodeIfStat
			elseif type == 'while' then
				tok.Get()

				--condition
				local nodeCond = ParseExpr()

				--do
				if not tok.ConsumeKeyword('do') then
					return GenerateError("`do` expected.")
				end

				--body
				local nodeBody = ParseStatementList()

				--end
				if not tok.ConsumeKeyword('end') then
					GenerateError("`end` expected.")
				end

				--return
				stat = {
					AstType = 'WhileStatement',
					Condition = nodeCond,
					Body      = nodeBody,
				}
			elseif type == 'do' then
				tok.Get()

				--do block
				local nodeBlock = ParseStatementList()
				if not tok.ConsumeKeyword('end') then
					GenerateError("`end` expected.")
				end

				stat = {
					AstType = 'DoStatement',
					Body    = nodeBlock,
				}
			elseif type == 'for' then
				tok.Get()

				--for block
				if not tok.Is('Ident') then
					GenerateError("<ident> expected.")
				end
				local baseVarName = tok.Get()
				if tok.ConsumeSymbol('=') then
					--numeric for
					local forVar = baseVarName.Data

					local startEx = ParseExpr()
					if not tok.ConsumeSymbol(',') then
						GenerateError("`,` Expected")
					end
					local endEx = ParseExpr()
					local stepEx
					if tok.ConsumeSymbol(',') then
						stepEx = ParseExpr()
					end
					if not tok.ConsumeKeyword('do') then
						GenerateError("`do` expected")
					end

					local body = ParseStatementList()
					if not tok.ConsumeKeyword('end') then
						GenerateError("`end` expected")
					end

					stat = {
						AstType  = 'NumericForStatement',
						Variable = forVar,
						Start    = startEx,
						End      = endEx,
						Step     = stepEx,
						Body     = body,
					}
				else
					--generic for
					local varList = { baseVarName.Data }
					while tok.ConsumeSymbol(',') do
						if not tok.Is('Ident') then
							GenerateError("for variable expected.")
						end
						varList[#varList+1] = tok.Get().Data
					end
					if not tok.ConsumeKeyword('in') then
						GenerateError("`in` expected.")
					end
					local generators = {ParseExpr()}
					while tok.ConsumeSymbol(',') do
						generators[#generators+1] = ParseExpr()
					end

					if not tok.ConsumeKeyword('do') then
						GenerateError("`do` expected.")
					end

					local body = ParseStatementList()
					if not tok.ConsumeKeyword('end') then
						GenerateError("`end` expected.")
					end

					stat = {
						AstType      = 'GenericForStatement',
						VariableList = varList,
						Generators   = generators,
						Body         = body,
					}
				end
			elseif type == 'repeat' then
				tok.Get()

				local body = ParseStatementList()

				if not tok.ConsumeKeyword('until') then
					GenerateError("`until` expected.")
				end

				local cond = ParseExpr()

				stat = {
					AstType   = 'RepeatStatement',
					Condition = cond,
					Body      = body,
				}
			elseif type == 'function' then
				tok.Get()

				if not tok.Is('Ident') then
					GenerateError("Function name expected")
				end
				local name = ParseSuffixedExpr(true) --true => only dots and colons

				local func = ParseFunctionArgsAndBody()

				func.IsLocal = false
				func.Name    = name
				stat = func
			elseif type == 'local' then
				tok.Get()

				if tok.Is('Ident') then
					local varList = { tok.Get().Data }
					while tok.ConsumeSymbol(',') do
						if not tok.Is('Ident') then
							GenerateError("local var name expected")
						end
						varList[#varList+1] = tok.Get().Data
					end

					local initList = {}
					if tok.ConsumeSymbol('=') then
						repeat
							initList[#initList+1] = ParseExpr()
						until not tok.ConsumeSymbol(',')
					end

					stat = {
						AstType   = 'LocalStatement',
						LocalList = varList,
						InitList  = initList,

					}

				elseif tok.ConsumeKeyword('function') then
					if not tok.Is('Ident') then
						GenerateError("Function name expected")
					end
					local name = tok.Get().Data
					local localVar = name

					local func = ParseFunctionArgsAndBody()

					func.Name    = localVar
					func.IsLocal = true
					stat = func

				else
					GenerateError("local var or function def expected")
				end
			elseif type == '::' then
				tok.Get()

				if not tok.Is('Ident') then
					GenerateError('Label name expected')
				end
				local label = tok.Get().Data
				if not tok.ConsumeSymbol('::') then
					GenerateError("`::` expected")
				end
				stat = {
					AstType = 'LabelStatement',
					Label   = label,
				}
			elseif type == 'return' then
				tok.Get()

				local exList = {}
				if not tok.IsKeyword('end') then
					-- Use PCall as this may produce an error
					local st, firstEx = pcall(ParseExpr)
					if st then
						exList[1] = firstEx
						while tok.ConsumeSymbol(',') do
							exList[#exList+1] = ParseExpr()
						end
					end
				end
				stat = {
					AstType   = 'ReturnStatement',
					Arguments = exList,
				}
			elseif type == 'break' then
				tok.Get()

				stat = {
					AstType = 'BreakStatement',
				}
			elseif type == 'goto' then
				tok.Get()

				if not tok.Is('Ident') then
					GenerateError("Label expected")
				end
				local label = tok.Get().Data
				stat = {
					AstType = 'GotoStatement',
					Label   = label,
				}
			end
		end

		if not stat then
			--statementParseExpr
			local suffixed = ParseSuffixedExpr()

			--assignment or call?
			if tok.IsSymbol(',') or tok.IsSymbol('=') then
				--check that it was not parenthesized, making it not an lvalue
				if (suffixed.ParenCount or 0) > 0 then
					GenerateError("Can not assign to parenthesized expression, is not an lvalue")
				end

				--more processing needed
				local lhs = { suffixed }
				while tok.ConsumeSymbol(',') do
					lhs[#lhs+1] = ParseSuffixedExpr()
				end

				--equals
				if not tok.ConsumeSymbol('=') then
					GenerateError("`=` Expected.")
				end

				--rhs
				local rhs = {ParseExpr()}
				while tok.ConsumeSymbol(',') do
					rhs[#rhs+1] = ParseExpr()
				end

				--done
				stat = {
					AstType = 'AssignmentStatement',
					Lhs     = lhs,
					Rhs     = rhs,
				}

			elseif suffixed.AstType == 'CallExpr' or
				   suffixed.AstType == 'TableCallExpr' or
				   suffixed.AstType == 'StringCallExpr'
			then
				--it's a call statement
				stat = {
					AstType    = 'CallStatement',
					Expression = suffixed,
				}
			else
				GenerateError("Assignment Statement Expected")
			end
		end

		if stat and not stat.Head then stat.Head = next end

		if tok.IsSymbol(';') then
			stat.Semicolon = tok.Get()
		end
		return stat
	end

	--- Parse a a list of statements
	-- @treturn Node The resulting node
	function ParseStatementList()
		local body = {}
		local nodeStatlist   = {
			AstType = 'Statlist',
			Body    = body,
		}

		while not statListCloseKeywords[tok.Peek().Data] and not tok.IsEof() do
			local nodeStatement = ParseStatement()
			body[#body + 1] = nodeStatement
		end

		if tok.IsEof() then
			tok.Get()
		end

		--nodeStatlist.Body = stats
		return nodeStatlist
	end

	return ParseStatementList()
end

return function(contents)
	local lexed = LexLua(contents)
	os.queueEvent("foo")
	coroutine.yield("foo")

	local parsed = ParseLua(lexed)
	os.queueEvent("foo")
	coroutine.yield("foo")
	return parsed
end

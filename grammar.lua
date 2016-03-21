require'string_ext'

local grammar_source = [[


	chunk ::= block

	block ::= {stat} [retstat]

	stat ::=  ‘;’ |
		 varlist ‘=’ explist |
		 functioncall |
		 label |
		 ‘break’ |
		 ‘goto’ Name |
		 ‘do’ block ‘end’ |
		 ‘while’ exp ‘do’ block ‘end’ |
		 ‘repeat’ block ‘until’ exp |
		 ‘if’ exp ‘then’ block {‘elseif’ exp ‘then’ block} [‘else’ block] ‘end’ |
		 ‘for’ Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end |
		 ‘for’ namelist ‘in’ explist ‘do’ block ‘end’ |
		 ‘function’ funcname funcbody |
		 ‘local’ ‘function’ Name funcbody |
		 ‘local’ namelist [‘=’ explist]

	retstat ::= ‘return’ [explist] [‘;’]

	label ::= ‘::’ Name ‘::’

	funcname ::= Name {‘.’ Name} [‘:’ Name]

	varlist ::= var {‘,’ var}

	var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name

	namelist ::= Name {‘,’ Name}

	explist ::= exp {‘,’ exp}

	exp ::=  ‘nil’ | ‘false’ | ‘true’ | Numeral | LiteralString | ‘...’ | functiondef |
		 prefixexp | tableconstructor | exp binop exp | unop exp

	prefixexp ::= var | functioncall | ‘(’ exp ‘)’

	functioncall ::=  prefixexp arg1s | prefixexp ‘:’ Name arg1s

	arg1s ::=  ‘(’ [explist] ‘)’ | tableconstructor | LiteralString

	functiondef ::= ‘function’ funcbody

	funcbody ::= ‘(’ [parlist] ‘)’ block ‘end’

	parlist ::= namelist [‘,’ ‘...’] | ‘...’

	tableconstructor ::= ‘{’ [fieldlist] ‘}’

	fieldlist ::= field {fieldsep field} [fieldsep]

	field ::= ‘[’ exp ‘]’ ‘=’ exp | Name ‘=’ exp | exp

	fieldsep ::= ‘,’ | ‘;’

	binop ::=  ‘+’ | ‘-’ | ‘*’ | ‘/’ | ‘//’ | ‘^’ | ‘%’ |
		 ‘&’ | ‘~’ | ‘|’ | ‘>>’ | ‘<<’ | ‘..’ |
		 ‘<’ | ‘<=’ | ‘>’ | ‘>=’ | ‘==’ | ‘~=’ |
		 ‘and’ | ‘or’

	Name ::=  "([%w_]+[%w%d_]*)"

	Numeral ::= "(-?%d+%.?%d*)"

	LiteralString ::= "'(.-)'" | "\"(.-)\""



	unop ::= ‘-’ | ‘not’ | ‘#’ | ‘~’ | { ‘!’ |
]]

local bnf_mt = {}
local bnf_rule_mt = {}

function bnf_rule_mt:__tostring()
	--if type(self)=='string' then return self end
	local s, sep = '', ', '
	if self.alternation then sep = ' | ' end
	for _, v in ipairs(self) do s = s .. tostring(v) .. sep end
	s = s:gsub(sep..'$', '')
	if self.optional then s = '[ ' .. s .. ' ]' end
	if self.repetition then s = '{ ' .. s .. ' }' end
	if self.literal then s = '‘' .. s .. '’' end
	if self.regexp then s = '"' .. s .. '"' end
	return s
end

local function bnf_rule__call(self, bnf, str, start)
	local _, ws = str:find("^%s+", start)
	if ws then start = ws+1 end
	if self.alternation then
		for _, v in ipairs(self) do
			if type(v)=='string' then assert(bnf[v])	v = bnf[v]			end
			if v==self then error(self) end
			local res = v(bnf, str, start)
			if res and res>start then return res end
		end
		return
	elseif self.literal then
		local _, e = str:find(self[1], start, true)
		if e then return e end
		return
	elseif self.regexp then
		local _, e = str:find('^'..self[1], start)
		if e then return e end
		return
	end
	local i = start
	for _, v in ipairs(self) do
		--print(i, v, v.regexp, type(v)=='string')
		if type(v)=='string' then
			if bnf[v]==nil then error(v) end
			v = bnf[v]
		end
		local res = v(bnf, str, i)
		if res then i = res else return end
	end
	return i
--	if self.optional then s = '[ ' .. s .. ' ]' end
--	if self.repetition then s = '{ ' .. s .. ' }' end

end

function bnf_rule_mt:__call(bnf, str, start)
	local start = start or 1
	if self.repetition then
		local i = start
		while i do
			local i2 = bnf_rule__call(self, bnf, str, i)

			if i2==nil or i2>=#str then return i end
			if i2<=i then break end
			i = i2
		end
		if self.optional then return start else return end
	else
		local res = bnf_rule__call(self, bnf, str, start)
		if res then return res+1 end
		if self.optional then return start else return end
	end
end

function bnf_mt:__tostring()
	local s = ''
	for k, v in pairs(self) do
		s = s..'\n'..k..' ::= '..tostring(v)..'\n'
	end
	return s
end


local bnf = setmetatable({}, bnf_mt)
local rule_name, curr_rule, alternation

local function toks_bnf_expr(str)
	local curr_rule, alternation = setmetatable({}, bnf_rule_mt)
	for name, bp, ep, arg11 in str:gtok{
		id='(%w+)',
		literal='‘([^’]+)’',
		opt='(%b[])', ws='%s+', rep='(%b{})', alt='|',
		regexp='"(.-[^\\])"'
	} do
		if name~='ws' then --
			if name~='alt' then
				if name=='rep' then
					table.insert(curr_rule,
						rawset(toks_bnf_expr(arg11:sub(2, -1)), 'repetition', true))
				elseif name=='opt' then
					table.insert(curr_rule,
						rawset(toks_bnf_expr(arg11:sub(2, -1)), 'optional', true))
				elseif name=='literal' then
					table.insert(curr_rule,
						setmetatable({ arg11, literal=true }, bnf_rule_mt))
				elseif name=='regexp' then
					table.insert(curr_rule,
						setmetatable({ arg11:gsub('\\"', '"'), regexp=true }, bnf_rule_mt))
					--				elseif name=='id' then
--					table.insert(curr_rule, rawset({ arg11 }, 'rule', true))
				else
					table.insert(curr_rule, arg11)
				end
			else
				assert(#curr_rule>0)
				if alternation==nil then
					alternation={ curr_rule, alternation=true }
				else
					table.insert(alternation, curr_rule)
				end
				curr_rule = setmetatable({}, bnf_rule_mt)
			end
		end
	end
	if alternation and #curr_rule>0 then
		table.insert(alternation, curr_rule)
		return setmetatable(alternation, bnf_rule_mt)
	else
		return setmetatable(curr_rule, bnf_rule_mt)
	end
end


do
for name, bp, ep, arg11, alt in grammar_source:gtok{
	lval='(%w+)%s*::=', id='(%w+)',
	literal='‘([^’]+)’',
	opt='(%b[])', ws='%s+', rep='(%b{})', alt='|',
	regexp='"(.-[^\\])"'
} do
	if name~='ws' then
		if name=='lval' then
			if rule_name then
				local rule
				if alternation==nil then
					rule = curr_rule
				else
					table.insert(alternation, curr_rule)
					rule = alternation
				end
				bnf[rule_name] = setmetatable(rule, bnf_rule_mt)
			end
			rule_name = arg11
			curr_rule = setmetatable({}, bnf_rule_mt)
			alternation = nil
		elseif name~='alt' then
			if name=='rep' then
				table.insert(curr_rule,
					rawset(toks_bnf_expr(arg11:sub(2, -1)), 'repetition', true))
			elseif name=='opt' then
				table.insert(curr_rule,
					rawset(toks_bnf_expr(arg11:sub(2, -1)), 'optional', true))
			elseif name=='literal' then
				table.insert(curr_rule, setmetatable({arg11, literal=true}, bnf_rule_mt))
			elseif name=='regexp' then
				table.insert(curr_rule,
					setmetatable({arg11:gsub('\\"', '"'), regexp=true }, bnf_rule_mt))
			else
				table.insert(curr_rule, arg11)
			end
		else
			assert(#curr_rule>0)
			if alternation==nil then
				alternation=setmetatable({ curr_rule, alternation=true }, bnf_rule_mt)
			else
				table.insert(alternation, curr_rule)
			end
			curr_rule = setmetatable({}, bnf_rule_mt)
		end
	end
end
end
local inspect = require'inspect'
--inspect(bnf)


--print(bnf)
--print(bnf.Name)
--inspect(bnf.Name)
--print(bnf.Name(bnf, 'id588>=xxxx '))
--print(bnf.Name(bnf, '>=xxx '))
--print(bnf.Numeral(bnf, '-666.3 '))

--print('LiteralString', bnf.LiteralString(bnf, '"-666.3 "'))
--print(bnf.exp(bnf, [[-sffx()+6]]))
--print(bnf.tableconstructor(bnf, [[x=9,y=0,false} == 0]], 1))
--print(bnf.binop(bnf, [[- ()+6]]))
----function f1(rule, bnf)
----	--print(rule)
----	rule.xx=true
--	for k, v in ipairs(rule) do
--		if type(v)=='string' then rule[k]=bnf[v] elseif v.xx then f1(v, bnf) end
--	end
--end

--for k, v in pairs(bnf) do f1(v, bnf) end

--inspect(bnf.fieldlist)
--print(bnf.fieldlist)
for k,v in pairs(bnf.block) do print(k,v) end

--print(bnf.Numeral(bnf, '5+5-f(f/6,5-1)'))
print(bnf.stat(bnf,[[ x]]))
--print(bnf:exp([[-sffx()+6]]))
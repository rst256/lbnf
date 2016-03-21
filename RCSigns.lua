local overload = require"overload"
local inspect = require"inspect"

local M = {}

local RCSign_op = {}
local RCSign_mt = { __index=RCSign_op }

-- local function rcs_expr_parse(rcsign, rcs_expr, ...)
-- 	if rcs_expr==nil then return rcsign end
-- 		print(rcs_expr)
-- 	return rcs_expr_parse(rcsign, ...)
-- end
-- rcs_expr_parse({}, 5, 666, 777)
-- local rcs_expr_tokens = {
-- 	charClass='\\([wspadclgxu%.%^%$])',
-- 	simpleGroup='(%b())',
-- 	namedGroub='(%b{})',
-- 	charSet='(%b[])',
-- }

local rcs_expr_chars = {}
local rcs_expr_tokens = {}

local rcs_expr_quant = '([%*%+%-%?]?)'
local function rcs_expr_parse(rcsign, rcs_expr)
	local i, ptr = 1, ''
	while i<=#rcs_expr do
		for k, v in pairs(rcs_expr_tokens) do
			local cc, qnt, i2 = rcs_expr:match('^'..k..rcs_expr_quant..'()', i)
			if cc~=nil then
				local tok = v(cc, qnt)
				-- print(cc, qnt, i2, inspect.inspect(tok):gsub('%s+', ' '), ptr);
				if type(tok)=='string' then ptr = ptr .. tok else
					-- print(ptr, inspect.inspect(tok):gsub('%s+', ' '));
					if ptr~='' then table.insert(rcsign, ptr); ptr = ''; end
					table.insert(rcsign, tok)
				end
				i=i2; goto token_match;
			end
		end
		--print(i, rcs_expr:sub(i, i))
		i = i + 1
		::token_match::
	end
	if ptr~='' then table.insert(rcsign, ptr) end
	return rcsign
end


rcs_expr_tokens['|'] = function(cc, qnt)
	return '%'..cc..qnt 	end
rcs_expr_tokens['\\([wspadclgxuWSPADCLGXU])'] = function(cc, qnt)
	return '%'..cc..qnt 	end
rcs_expr_tokens['\\([%.%^%$])'] = function(cc, qnt)  return cc..qnt 	end
rcs_expr_tokens['(%b())'] = function(cc, qnt)
	return { qnt=qnt, class= 'group', body=rcs_expr_parse({}, cc:match'%((.-)%)$') }
end
rcs_expr_tokens['(%b{})'] = function(cc, qnt)
	local name, body = cc:match'{%s*([%w%d_]*)%s*=?(.*)}$'
	print(cc, name, body)
	return { qnt=qnt, class= 'symbol', name=name, body=rcs_expr_parse({}, body) }
end
rcs_expr_tokens['(%b[])'] = function(cc, qnt)
	cc = cc:gsub('%%', '%%%%')
	cc = cc:gsub('\\([wspadclgxuWSPADCLGXU%^%-])', '%%%1')
	cc = cc:gsub('\\\\', '%%%%')
	cc = cc:gsub('\\(%.)', '.')
	return cc..qnt
end

inspect(rcs_expr_parse({}, '\\g*\\w+[^\\w%+\\-](\\W+ {}) ${sym1=\\d*\\S+}\\p-{ sym1 }6666\\$'))
inspect(rcs_expr_parse({}, '\\d*\\S+$[\\.\\\\]-'))

function RCSign_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = get_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end

function RCSign_op:find(source, start)
	local node = self
	for k=start or 1, #source do
		if node.childs==nil then return k, node.value end
		local n = node.childs[source:sub(k, k)]
		if n==nil then return k-1, node.value end
		node = n
	end
	return #source
end

function RCSign_mt:__call(pattern)
	local node, node2 = self.childs
	for c, p, q in self.pattern_iter(pattern) do
		if node==nil then return end
		node2 = node[c..p..q]
		if node2==nil then return end
		node = node2.childs
	end
	return node2.value
end

local function RCSign__tostring(self, step)
	local s = tostring(self.value or '')
	if self.childs==nil then return s end
	s = s..'\n'
	for k, v in pairs(self.childs) do
		s = s..string.rep(' ', step)..k..':'..RCSign__tostring(v, step+1)--..','
	end
	return s
end

function RCSign_mt:__tostring()
	return RCSign__tostring(self, 0)
end

function M.RCSign(rcs_expr)

	return setmetatable({ childs={} }, RCSign_mt)
end





return M
package.path = [[C:\Projects\Lua\utils\?.lua]]

local inspect = require'inspect'
local class = require'class'
require'string_ext'

local M = {  }


local function tokenize(str, rules, start)
	local src = {}
	for tok_class, tok_value, bp, ep in str:gtok(rules, start) do
		--print(string.format("%0.15s", tok_class),
--			string.format("%q", tok_value:sub(1, 20):gsub('\n', '\\n')))
		table.insert(src, {
			tok_value=tok_value, tok_class=tok_class, ep=ep, bp=bp })
	end
	return src
end
M.tokenize = tokenize


local togmrrule

local function table_merge(dst, apd)
	for k, V in ipairs(apd) do table.insert(dst, v); end--apd[k]=nil; end
	for k, V in pairs(apd) do dst[k]=v; end
end

local function alt(arg, greedy_mode)
	local greedy_mode = greedy_mode
	if greedy_mode==nil then greedy_mode = true end
	for k, v in pairs(arg) do arg[k] = togmrrule(v) end
	return function(src, start, ctx)
		if src==nil then return 'alt' end
		local greedy_idx, greedy_name = 1
		for k, v in pairs(arg) do
			local idx = v(src, start, ctx)
			if idx then
				if greedy_mode then
					if greedy_idx<idx then greedy_idx=idx; greedy_name=k; end
				else
					--table_merge(ctx, ctx_tmp)
					return idx, k
				end
			end
		end
		if greedy_mode and greedy_idx>1 then
			--table_merge(ctx, greedy_ctx)
			return greedy_idx, greedy_name
		end
	end
end

local function rep(arg)
	local arg = togmrrule(arg)
	return function(src, start, ctx)
		if src==nil then return 'rep' end
		local idx = start
		::loop::
		local idx_tmp = arg(src, idx, ctx)
		if idx_tmp and idx_tmp>idx then
			idx=idx_tmp; goto loop
		else
			if idx>start then return idx else return end
		end
	end
end

local function opt(arg)
	local arg = togmrrule(arg)
	return function(src, start, ctx)
		if src==nil then return 'opt' end
		local idx = arg(src, start, ctx)
		if idx then return idx else return start end
	end
end

local function ref(gmr, name)
	return function(src, start, ctx)
		if src==nil then return 'ref' end
		local start = start or 1
		if gmr[name]==nil then error(name, 2); end
		return gmr[name](src, start, ctx)
	end
end

local function el(tok_class, tok_value)
	return function(src, start)
		if src==nil then return 'el' end
		if start>#src then return end
		if src[start].tok_class~=tok_class then return end
		if tok_value~=nil and src[start].tok_value~=tok_value then return end
		return start+1
	end
end

local function seq(...)
	local rule = {...}
	for k, v in ipairs(rule) do rule[k] = togmrrule(v) end
	return function(src, start, ctx)
		if src==nil then return 'seq' end
		local idx = start or 1
		for k, v in ipairs(rule) do
			idx = v(src, idx, ctx)
			if idx==nil then return end
		end
		return idx
	end
end

local function list(members, separators, ldelim, rdelim)
	local members, separators, ldelim, rdelim = alt(members),
		togmrrule(separators), togmrrule(ldelim), togmrrule(rdelim)
	return function(src, start, ctx)
		if src==nil then return 'list' end
		local idx = start or 1
		if ldelim then idx = ldelim(src, idx, ctx) if idx==nil then return end end
		while idx<=#src do
			local idx_tmp, alt_name = members(src, idx, ctx)
			if idx_tmp==nil then return end
			idx = idx_tmp
			if separators then
				local idx_tmp = separators(src, idx, ctx)
				if idx_tmp==nil then if rdelim then return else return idx end end
				idx = idx_tmp
			end

		end

		if rdelim then idx = rdelim(src, idx, ctx) if idx==nil then return end end

		for k, v in ipairs(rule) do
			idx = v(src, idx, ctx)
			if idx==nil then return end
		end
		return idx
	end
end

local capt_reserved = { class=1, bi=1, ei=1 }
local function capt(arg, name)
	if capt_reserved[name] then
		error('capt result field '..name..' is reserved', 2) end
	local arg = togmrrule(arg)
	return function(src, start, ctx)
		if src==nil then return 'capt', name end
		local own_ctx = { }--bi=start, up=ctx }
		local idx, alt_name = arg(src, start, own_ctx)
		if idx then
			if arg()=='el' then
				own_ctx=src[idx-1].tok_value
			elseif next(own_ctx)==nil then
				own_ctx={ bi=start, ei=idx-1 }
			end
			if arg()=='alt' and alt_name~=nil then
				own_ctx.class=alt_name
			end
			if name==nil then table.insert(ctx, own_ctx) else ctx[name] = own_ctx end
			return idx
		end
	end
end

 togmrrule = function(arg)
	if arg==nil then return end
	if type(arg)=='string' then
		local tok_class, capt_name = arg:match"([^\n]+)(\n?[%w%d_]*)"
		if #capt_name>1 then return capt(el(tok_class), capt_name:sub(2, 0)) end
		if #capt_name==1 then return capt(el(tok_class)) end
		return el(tok_class)
	end
	return arg
end


tok_rules = require'aminorex_syntax'
local str_src = [[
typedef struct  {
	const char * name;
	struct stmt_param params[];
} stmt_t;
/*@ [some_%w+](W){
		return self..'='..(vars[W] or W)
}@*/
typedef struct ast_node {
	stmt_t* type;
	void * data;
	struct ast_node* up;

} ast_node_t;

some_f(xxxx)
/*@{
VMA['=>'] = function(self, name, mode)
	local s = vars[self]..'.'..name..'('..self
	if mode.ei==mode.bi then s = s .. ',' else s = s .. ')' end
	return s
end

}@*/
int x;
int y;

x=>ctx(1,22  ,3);
y=>ctx();
#pragma
]]

if arg[1] then
--	file = io.popen('tcc -E '..arg[1], "r")
	file = io.open(arg[1], "r")
	str_src = file:read'*a'
	file:close()
end


--print('----------------------- tokenizing -----------------------')



typedefs = {}
lua_gmacros = {}
lua_macros = setmetatable({}, { __index=lua_gmacros })
vardefs = {}
VMA = {}
--setmetatable({}, { __index={
--	[':'] = function(self, name, mode)
--		if mode==nil then
--			return
--		elseif mode.class=='call' then
--			local s = vardefs[self]:sub(1, -2)..'_'..name..'('..self
--			if mode.ei==mode.bi then s = s .. ', ' else s = s .. ')' end
--			return s
--		end
--	end
--}})

local eval_lua_env = setmetatable({}, { __index= {
	types=typedefs, vars=vardefs, VMA=VMA
}})

local function eval_lua(code)
	local fn, err = load(code, nil, 't', eval_lua_env)
	if fn==nil then error(err, 2) end
	return fn
end

local function amino_tokenize(code, tok_src)
	local tok_src = tok_src or {}
for tok_class, bp, ep, tok_value, a1, a2, a3 in code:gtok(tok_rules) do

	if tok_class=='typedef' then
		typedefs[tok_value] = true
	elseif tok_class=='ident' and typedefs[tok_value] then
		tok_class='type'
	end

	if tok_class=='lua_def_gen' then
		tok_value = tok_value:sub(2, -1)
		local fn =
			eval_lua('local self, '..a1:sub(2, -1)..' = ... \n'..a2:sub(2, -1))
		lua_gmacros[tok_value] = fn
		tok_rules[tok_value] = 'finite:('..tok_value..')%s*(%b())'
	end

	if tok_class=='lua_pp_def' then
		local fn = eval_lua('local '..a1:sub(2, -1)..' = ... \n'..a2:sub(2, -1))
		lua_macros[tok_value] = fn
		table.insert(tok_rules.lua_macros, 'finite:('..tok_value..')%s*(%b())')
	end

	if lua_gmacros[tok_class] then
		tok_value = { name=tok_class, args=a1, self=tok_value }
	end

	if tok_class=='lua_macros' then
		tok_value = { name=tok_value, args=a1 }
	end

	if tok_class=='pp_include' then
--		local file = io.open([[C:\bin\npl.ru2\symdb\include\]]..tok_value, "r")
--		local hdr_src = file:read'*a'
--		file:close()
--		amino_tokenize(hdr_src)
	end

	table.insert(tok_src, {
		tok_value=tok_value, tok_class=tok_class, ep=ep, bp=bp })

--	print(string.format("%0.15s", tok_class),
--		string.format("%q", code:sub(bp, ep):gsub('\n', '\\n')))

end
	return tok_src
end
tok_src = amino_tokenize(str_src)

--print('------------------------ parsing ------------------------')


local gmr1 = {}

gmr1.vardef = seq( 'type\ntype', opt'*', 'ident\nvar',
	alt{ ';', '=\ninitialized' })
gmr1.typename = seq( '$', 'ident\nvar' )
gmr1.typetok = seq( 'ident\nvar', '@' )
gmr1.lua_macros = el'lua_macros'
gmr1.lua_pp_block = el'lua_pp_block'
gmr1.lua_gmacros = function(s, i, ctx)
	if s==nil then return 'lua_gmacros' end
	if lua_gmacros[s[i].tok_class] then
		return i+1
	end
end
gmr1.var = function(s, i)
	if s==nil then return 'el' end
	if s[i].tok_class=='ident' and vardefs[s[i].tok_value]~=nil then
	return i+1 end
end
gmr1.VMA = seq(
	capt(gmr1.var, 'var'),
	alt{ '=>\noper', '::\noper' }, 'ident\nfield', --':\noper',
	opt(capt(alt{ call=seq('(', opt((')'))), index='[', assign='=' }, 'mode'))
)



local function gparse(tok_src, gmr_rules, start, skip_unknown)
	local i = start or 1
	return function()
		::start_l::
		if i>#tok_src then return end
		local i_max, rule_name, alt_max, ctx_max = 1
		for k, v in pairs(gmr_rules) do
			local ctx = {}
			local i_tmp,rn = v(tok_src, i, ctx)
			if i_tmp and i_max<i_tmp then
				i_max=i_tmp; rule_name=k; alt_max=rn; ctx_max=ctx;
			end
		end
		if rule_name==nil then
			if skip_unknown then i=i+1; goto start_l; else return end
		end
		local s = str_src:sub(tok_src[i].bp, tok_src[i_max-1].ep-1)
		local i_tmp = i
		i = i_max
		if next(ctx_max)==nil then ctx_max=nil end
		return rule_name, ctx_max, i_tmp, i, alt_max
	end
end

local s, p = '', 1

for rule_name, ctx, i_tmp, i, alt_max in gparse(tok_src, gmr1, 1, true) do
	local bp, ep = tok_src[i_tmp].bp, tok_src[i-1].ep

	if rule_name=='vardef' then
		vardefs[ctx.var] = ctx.type
		--print(rule_name, ctx.var, ctx.type, ctx.initialized )

	elseif rule_name=='typename' and vardefs[ctx.var] then
		--print(rule_name, ctx.var, vardefs[ctx.var])
		s = s..str_src:sub(p, bp-1)..'"'..vardefs[ctx.var]..'"'
		p = ep

	elseif rule_name=='typetok' and vardefs[ctx.var] then
		--print(rule_name, ctx.var, vardefs[ctx.var])
		s = s..str_src:sub(p, bp-1)..vardefs[ctx.var]
		p = ep

	elseif rule_name=='lua_macros' or rule_name=='lua_gmacros' then
		local args = {}
		if rule_name=='lua_gmacros' then
			table.insert(args, tok_src[i-1].tok_value.self) end
		for a in tok_src[i-1].tok_value.args:sub(2, -1):gmatch"%s*([^;]*)" do
			table.insert(args, a)
		end
		local res =lua_macros[tok_src[i-1].tok_value.name](table.unpack(args))
		if type(res)=='boolean' then if res then res = '1' else res='0' end end
		--print(rule_name, tok_src[i-1].tok_value.name, res)
		s = s..str_src:sub(p, bp-1)..(res or '')
		p = ep

	elseif rule_name=='lua_pp_block' then
		local res, err =eval_lua(tok_src[i-1].tok_value:sub(2, -1))()
		if res==false then
			error(err or 'error', 2)
		elseif type(res)=='string' then
			s = s..str_src:sub(p, bp-1)..(res or '')
			p = ep
		end

	elseif rule_name=='VMA' then
		--print(rule_name, ctx.var..ctx.oper..ctx.field, ctx.mode)
--		inspect(ctx)
		local vma_oper = VMA[ctx.oper]
		if vma_oper==nil then
			error(bp..': VMA "'..ctx.var..ctx.oper..ctx.field..
				'" operator not defined', 2) end
		local vma_src, err = vma_oper(ctx.var, ctx.field, ctx.mode)
		if not vma_src then
			error(bp..': VMA "'..ctx.var..ctx.oper..ctx.field..
				'" operation error '..(err or ''), 2) end
		s = s..str_src:sub(p, bp-1)..vma_src
		p = ep
	end
	----print(rule_name, i_tmp, i, alt_max)
end
s = s..str_src:sub(p, 0)

--if arg[1] then
--	file = io.open(arg[1]..'.c', "w+")
--	file:write(s)
--	file:close()

--	file = io.popen('tcc -E '..arg[1]..'.c', "r")
--	file = io.open(arg[1], "r")
--	str_src = file:read'*a'
--	file:close()
--end
--print('------------------------ output ------------------------')
--print(s)


if arg[1] then
	file = io.open(arg[2] or arg[1]..'.c', "w+")
	file:write(s)
	file:close()
end

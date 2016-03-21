local inspect = require'inspect'
local class = require'class'
require'string_ext'

local M = {  }


local function tokenize(str, rules, start)
	local src = { lexemes_count=0, lexemes={} }
	for tok_class, bp, ep, tok_value in str:gtok(rules, start) do
		if src.lexemes[tok_class]==nil then
			src.lexemes_count=src.lexemes_count+1
			src.lexemes[tok_class]=src.lexemes_count
		end
		print(string.format("%0.15s", tok_class),
			string.format("%q", tok_value:sub(1, 20):gsub('\n', '\\n')))
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
		local greedy_idx, greedy_ctx = 1
		for k, v in pairs(arg) do
			--local own_ctx = { class=k }
			local idx, own_ctx = v(src, start)
			if idx then
				if type(own_ctx)=='table' and type(k)=='string' then own_ctx.class=k; end
				if greedy_mode then
					if greedy_idx<idx then
						greedy_idx=idx; greedy_ctx=own_ctx; end
				else
					--table_merge(ctx, ctx_tmp)
					--if ctx then table.insert(ctx, own_ctx) end
					return idx, own_ctx
				end
			end
		end
		if greedy_mode and greedy_idx>1 then
			--table_merge(ctx, greedy_ctx)
--			if ctx then table.insert(ctx, own_ctx) end
			return greedy_idx, greedy_ctx
		end
	end
end

local function rep(arg)
	local arg = togmrrule(arg)
	return function(src, start, ctx)
		if src==nil then return 'rep' end
		local idx = start
		local rep_ctx = {}
		::loop::
		local idx_tmp, own_ctx = arg(src, idx, ctx)
		if idx_tmp and idx_tmp>idx then
			idx=idx_tmp; table.insert(rep_ctx, own_ctx); goto loop
		else
			if idx>start then
				if #rep_ctx==0 then rep_ctx=nil end
				return idx, rep_ctx
			else return end
		end
	end
end

local function opt(arg)
	local arg = togmrrule(arg)
	return function(src, start)
		if src==nil then return 'opt' end
		local idx, own_ctx = arg(src, start)
		if idx then return idx, own_ctx else return start end
	end
end

local function ref(gmr, name)
	return function(src, start, ctx)
		if src==nil then return 'ref' end
		local start = start or 1
		if gmr[name]==nil then error(name, 2); end

		return gmr[name](src, start)
	end
end

local function el(tok_class)
	return function(src, start)
		if src==nil then return 'el', tok_class end
		if start>#src or src[start].tok_class~=tok_class then return end
		return start+1--, src[start].tok_value
	end
end

local function seq(...)
	local rule, capt = {...}, {}
	for k, v in ipairs(rule) do
		rule[k], capt[k] = togmrrule(v)
		assert(type(rule[k])=='function')
	end
	return function(src, start)
		if src==nil then return 'seq', rule end
		local idx = start or 1
		local seq_ctx = {}
		for k, v in ipairs(rule) do
			if type(v)=='table' then inspect(v) end
			idx, own_ctx = v(src, idx)
			if idx==nil then return else
			table.insert(seq_ctx, own_ctx) end
		end
		if #seq_ctx==0 then seq_ctx=nil end
		return idx, seq_ctx
	end
end

local function list(items, seps, options)
	local options = setmetatable(options or {}, {
		__index = {item_end=1, }} )
	return function(src, start)
		if src==nil then return 'list' end
		local idx = start or 1
		local ctx = {}
		if options.sep_star then goto match_sep end

		::match_item::
		 i, c = items(src, idx)
		if i==nil or i>#src then if idx>start and options.item_end then
			return idx,ctx else return end
		end
		idx=i; table.insert(ctx,c)

		::match_sep::
		local i2, c2 = seps(src, idx)
		if i2==nil or i2>#src then if idx>start and options.sep_end then
			return idx,ctx else return end
		end
		if options.store_seps then table.insert(ctx, c2) end
		idx=i2

		goto match_item
	end
end




 togmrrule = function(arg)
	if arg==nil then return end
	if type(arg)=='string' then
		local tok_class, capt_name = arg:match"([^\n]+)(\n?[%w%d_]*)"
		if #capt_name>1 then capt_name=capt_name:sub(2, 0) end
		if #capt_name==1 then capt_name=false end
		return el(tok_class), capt_name
--		return el(arg)
	end
--	if type(arg)=='table' then
--		if #arg>0 then return seq(arg) else return alt(arg) end
--	end
	return arg
end


tok_rules = require'c_syntax'
local str_src = [[
int XXX0=0+6+7+8*6/2+9-(777777*8888888+5555555)*6*6+1;
int XXX=00-666666+777777*222222-44444-999;
int ggg65(void);
char gdf66();
int xx2(long tt, int fgf);
//typedef struct { int x; union { char c; long l; }; } struct_union_type;
int xx=0+6+(6*9)+www(77+4);
int hh;
int gg2=*fvxf;
typedef int new_type;
char xxx(int);
void et_fn(int  c, char ccc);
int main(int argc, char argv, int xx){
	f1(55+8, -1+5);
	return 66;
}
int ggg65(void){ printf("jkdsfbsd\n"); return 6; }

]]
--str_src:match"typedef%s+struct%s*%b{}%s*([%w_]+[%w%d_]*)%s*;"

print('----------------------- tokenizing -----------------------')
local tok_src = tokenize(str_src, tok_rules)

--inspect(tok_src.lexemes)

local function general_match_fn(self, src, idx, ctx, capt)
	if type(self)=='number' then
		if src[idx].tok_class==self then
			if capt then table.insert(ctx,src[idx].tok_class) end return idx end
	elseif getmetatable(self)=='lbnf_symbol' then

	end
end

local function lbnf_symbols(symbols)
	local mts = {}
	for k, v in pairs(symbols) do
		local sym_mt = {}
		if v.varargs then
			sym_mt.__call = function(...) return setmetatable({...}, mts[k] ) end
		else
			sym_mt.__call = function(a) return setmetatable({a}, mts[k] ) end
		end
		local match_fn
		if v.determine then
			match_fn = function(self, src, idx, ctx)
				return general_match_fn(self, src, idx, ctx)
			end
		else
			match_fn = function(self, src, idx, ctx)
				local own_ctx = {}
				idx = general_match_fn(self, src, idx, own_ctx)
				if idx then table.insert(ctx, own_ctx); return idx; end
			end
		end
		mts[k] = setmetatable({
			__metatable='lbnf_symbol',
			__index=v,
			__call=match_fn
		}, sym_mt)
	end
	return mts
end
lbnf_symbols{
	concat = { varargs=1, determine=1 },
	altern = { varargs=1},
	['repeat'] = { },
	option = {},
	capture = { varargs=1, determine=1 },
	except = { varargs=1, determine=1 },
}

function c(arg)
	local arg = togmrrule(arg)
	return function(src, idx)
		local i = arg(src, idx)
		if idx==nil then return end
		if i==idx+1 then return i, src[idx].tok_value end
		return i
	end
end
local binop = alt{
	'+', '-', '*', '\\', '/', '&', '|', '&&', '||',
	'==', '<=', '>=', '!=',
}

local unop = alt{
	'-', '*', '!', '&'
}

local fn_arg_def = seq(c'type\ntype', opt(c'ident\nname'))
--	function(s)
--		ss='fn_arg_def'
--	for _,v in ipairs(s) do ss = ss ..v.type..' '..(v.name or '')..',' end
--	return ss
--end)



local func_args = opt(alt{
	c'void',
	seq(fn_arg_def, opt(rep(seq(',', fn_arg_def)))),
})


local fn_arg_decl = seq('type\ntype', 'ident\nname')
local func_args_decl = opt(alt{
	'void',
	seq(fn_arg_decl ,opt(rep(seq(',',fn_arg_decl))))
})

local gmr2 = {}
local gmr_block = {}


local gmr1 = {}
gmr1.typedef = seq( el'typedef' ,c'type', c'ident',';')
--gmr1.typedef =	gen_mt(gmr1.typedef)

--local expr_el = (alt{
--	'number', 'ident', 'string',
--	seq('(', ref(gmr2, 'expr'), ')'),
--	funccall=ref(gmr2, 'funccall'),
--})

--gmr2.expr = alt{
--	seq(unop, expr_el), expr_el,
--	(seq(expr_el, rep(seq(binop, expr_el))))


local value = alt{
	c'number\n', c'ident\n', c'string\n',
	expr=seq('(', ref(gmr2, 'expr'), ')'),
	--ref(gmr2, 'funccall')
}

local binop1 = alt{
	c'+', c'-'
}

local binop2 = alt{
	 c'*', c'\\', c'/'
}
gmr2.expr = rep(alt{
	binop1=seq(opt(binop1),value,opt(binop1), opt(rep(seq(value, (binop1))))),
	binop2=seq(opt(binop2),value,opt(binop2), opt(rep(seq(value, opt(binop2)))))
})
--gmr2.expr = rep(alt{
--	list(value, alt{'-', '+'}, 1), list(value, alt{'*', '/'}, 1)
--})

--i, c = list(value, alt{'-', '+'}, 1)(tok_src, 1)
--print(table.unpack(c))
--i, c = list(value, alt{'*', '/'}, 1)(tok_src, i)
--print(table.unpack(c))
--i, c = list(value, alt{'+', '-'}, 1)(tok_src, i)
--print(table.unpack(c)
--os.exit()
--function capt(arg, name)
--	return setmetatable({ src_expr=arg, capt_name=name },	{
--		__call=function(self, ...) return self.src_expr(...) end,
--	}
--}


gmr2.funccall = seq(c'ident\nname', '(',
	opt(seq(gmr2.expr, opt(rep(seq(',', gmr2.expr))))), ')'
)
local function iif(cond, th, el)
	if cond then return th else return el end end

gmr1.funcdef = seq(
	alt{ c'void', c'type'} , c'ident\nname', '(', func_args, ')', ';')
local function vardef_mt(s)--inspect(s.initval)
	return s.type..' '..s.name..iif(s.initval, '='..tostring(s.initval)..';', ';')
end
--gmr1.funcdef2 = seq('ident', 'ident', '(', func_args, ')', ';')
gmr1.vardef = seq(c'type\ntype', c'ident\nname',
	alt{ ';', initial = seq('=', gmr2.expr, ';')})

gmr_block.funccall = seq(gmr2.funccall, ';')
gmr_block.retstat = seq(el'return', opt(gmr2.expr, 'rv') , ';')
gmr_block.vardef = gmr1.vardef

--local code_blocks = capt(rep(alt(gmr_block)))

gmr1.funcdecl = seq( 'type\nrettype', 'ident', '(',
	func_args_decl,
	')',	'{', opt(rep(alt(gmr_block))), '}'
)

print('------------------------ parsing ------------------------')

local function gparse(tok_src, gmr_rules, start)
	local i = start or 1
	return function()
		if i>#tok_src then return end
		local i_max, rule_name, alt_max, ctx_max = 1
		for k, v in pairs(gmr_rules) do
			--ocal ctx = {}
			local i_tmp, ctx = v(tok_src, i)
			if i_tmp and i_max<i_tmp then
				i_max=i_tmp; rule_name=k; alt_max=rn; ctx_max=ctx;
			end
		end
		if rule_name==nil then return end
		local s = str_src:sub(tok_src[i].bp, tok_src[i_max-1].ep-1)
		local i_tmp = i
		i = i_max
--		if next(ctx_max)==nil then ctx_max=nil end
		return rule_name, ctx_max, i_tmp, i, alt_max
	end
end

do
local compact_skip_toks = { ['(']=1,[')']=1 }
local function compact(ctx, cmp_ctx)
	if type(ctx)~='table' then return ctx end
	local cmp_ctx = cmp_ctx or {}
	for _,v in ipairs(ctx) do
		if type(v)~='table' or v.class then
			if not compact_skip_toks[v] then
				table.insert(cmp_ctx, compact(v)) end
		else compact(v, cmp_ctx) end
	end
	if ctx.class then cmp_ctx.class = ctx.class end
	return cmp_ctx
end

for rule_name, ctx, i_tmp, i, alt_max in gparse(tok_src, gmr1) do
	local str_ctx={}--.args
	if ctx then compact(ctx, str_ctx) end
--		str_ctx=inspect.inspect(ctx):gsub('( +)', ' '):gsub('([ \n\t]+)', ' ')
--	end


--if rule_name=='funcdef' then
	s = inspect.inspect(str_ctx):gsub('(%b{})', function(s)
			if s:match'(class%s*=%s*")([%w%d_]+)"%s*%}' then
		return s:gsub('(.-),%s*(class%s*=%s*")([%w%d_]+)"%s*%}', '  %3{ %1 }') end
		end)
	print(rule_name..':['..i_tmp..'-'..i..']', s)--print()
end

end

--local name_fmt = '%30q'
--local idx_fmt = '%.3d-%.3d'
--local i = 1
--while i and i<=#tok_src do
--	local i_max, rule_name, alt_max = 1
--	for k, v in pairs(gmr1) do
--		local i_tmp,rn = v(tok_src, i)
--		if i_tmp and i_max<i_tmp then
--			i_max=i_tmp; rule_name=k; alt_max=rn;
--		end
--	end
--	if rule_name==nil then break end
--	local s = str_src:sub(tok_src[i].bp, tok_src[i_max-1].ep-1):
--			gsub('\n', '\\n'):gsub('\t', '\\t')
--	if #s>60 then s = s:sub(1, 30)..' ...  '..s:sub(#s-30, #s)
--	elseif #s<60 then s = s .. string.rep(' ', 65-#s)	end
--	print(
--		name_fmt:format(rule_name),
--		idx_fmt:format(i, i_max),
--		s, alt_max
--	)
--	i = i_max
--end
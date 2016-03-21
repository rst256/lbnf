local inspect=require'inspect'
require'table_ext'


local stat_mt = { __metatable='statement' }

local function abs_isin(self, value, parent)
	if type(self)=='table' then
		if type(self[value])=='boolean' then
			return self[value]
		elseif type(self[value])=='function' then
			return self[value](self, parent)
		end
		error("2 "..type(self[value]), 2)
	elseif type(self)=='function' then
		return self(value)
	elseif type(self)=='boolean' then
		return self
	end
	error("1 "..type(value), 2)
end

local function ssm__tostring(self, is_sub)
	if type(self)=='string' then return self end
	local o, s='', self
	for k,v in orderedPairs(s) do
		if type(k)=='number' then
			o=o..ssm__tostring(v, true)..', '
		else
			if v.__lquant then
				o=o..k..v.__lquant..'='..ssm__tostring(v, true)..', '
			else
				o=o..k..'='..ssm__tostring(v, true)..', '
			end
		end
	end
	if #o>1 then o=o:sub(1, #o-2) end
	if self.__type then o=self.__type:sub(1, 1)..o..self.__type:sub(2, 2) end
	--if not is_sub and self.__name then o=self.__name..'=('..o..')' end
	if self.__quant then o=o..self.__quant end
	return o
end

local ssm_idx = {}
local ssm_mt = { __metatable='ssm', __tostring=ssm__tostring }


local M = {
	new_ssm=new_ast,
	new_ssm=new_ssm
}

local ast_idx = {}

function ast_idx:ssm()
	return self.__ssmcur.__root
end





local ast_mt = { __metatable='ast' }

function ast_mt:__index(name)
		if ast_idx[name] then return ast_idx[name](self) end
		--print(name, rawget(self, '__ssmcur')[name])
		if rawget(self, '__ssmcur')[name] then
			local o={insert=ast_mt.__insert,
				__ssmcur=rawget(self, '__ssmcur')[name], __root=rawget(self, '__root')
			}
			return setmetatable(o, ast_mt)
		end
	end

function ast_mt.__insert(self, name, opts)
	if self.__ssmcur[name]==nil then
		error(name..' not allowed in '..tostring(self.__ssmcur), 2) end
	local o={
		__ssmcur=self.__ssmcur[name], __root=self.__root, insert=ast_mt.__insert
	}
	o.opts=opts
	return setmetatable(o, ast_mt)
end

function M.new_ast(ssm)
	if getmetatable(ssm)~='ssm' then error('ssm expected', 2) end
	local o={ __ssm=ssm, __ssmcur=ssm, insert=ast_mt.__insert }
	o.__root=o
	return setmetatable(o, ast_mt)
end

do
local ast_reserved = {
	ssm=true, __root=true, __ssmcur=true
}
local function ast__next(t, k0)
		local k, v = next(t, k0)
		if k==nil then return end
		if ast_reserved[k] then return ast__next(t, k) end
		return k, v
end
function ast_mt:__pairs()
	return ast__next, self
end
end




local function parse_ssm(s, root, out)
	local root=root or { }
	local out=out or {}
	local blocks={}

	local function parse_block(b, s1, bl)
		return s1:gsub('(%b'..b..')', function(a)
			bl[#bl+1]=parse_ssm(a:sub(2, #a-1), root, {})
			bl[#bl].__type=b
			return '%'..#bl..'%'
		end)
	end

	local function add_ssm(dst, value, name)
		local obj, idx
		if type(value)=='string' then
			local vm, vq=value:match'([^%s%+%*?]*)([%+%*?]?)'
			local i=vm:match'%%(%d+)%%'
			if i==nil then obj=setmetatable({vm}, ssm_mt)	else obj=blocks[i+0]
			end
			if #vq>0 then obj.__quant=vq end
		end
		obj.__root=root
		obj.__parent=dst
		if name then
			local nm, nq=name:match'(%a+)([%+%*?]?)'
			obj.__name=nm
			if #nq>0 then obj.__lquant=nq end
			idx=nm
		else
			idx=rawlen(dst)+1
		end
		dst[idx]=obj
	end

	local s=parse_block('[]', s, blocks)
	s=parse_block('{}', s, blocks)
	s=parse_block('()', s, blocks)

	s=s:gsub('(%a+[%+%*?]?)=([^%s]*)', function(n,v)
--		local nm, nq=n:match'(%a+)([%+%*?]?)'
--		local vm, vq=v:match'([^%s%+%*?]*)([%+%*?]?)'
--		local i=vm:match'%%(%d+)%%'
--		if i then	out[nm]=blocks[i+0]	else
--			out[nm]=setmetatable({vm, __root=root}, ssm_mt) end
--		if #nq>0 then out[nm].__lquant=nq end
--		if #vq>0 then out[nm].__quant=vq end
		add_ssm(out, v, n)
		return ''
	end)

	for v in s:gmatch('([^%s]+)') do
--		local vm, vq=v:match'([^%s%+%*?]+)([%+%*?]?)'
--		local i=vm:match'%%(%d+)%%'
--		local o1
--		if i then o1=blocks[i+0] else
--			o1=setmetatable({vm, __root=root}, ssm_mt) end
--		if #vq>0 then o1.__quant=vq end
--		table.insert(out, o1)
		add_ssm(out, v)
	end

	if next(out)==nil then return end
	if next(out, next(out))==nil then out=out[next(out)] end
	out.__root=root
	if type(out)=='table' and getmetatable(out)~='ssm' then
		out=setmetatable(out, ssm_mt)
	end
--	if out0==nil then root
	return out
end

ssm_comp_mt = { }
function ssm_comp_mt:__pow(obj)
	if type(obj)=='string' then
		for _,v in ipairs(self) do
			if getmetatable(v)=='ssm' and v ^ obj then return true end
			if (v.__name or v)==obj then return true end
		end
	elseif type(obj)=='table' then
		for _,v in ipairs(self) do if v==obj then return true end end
	elseif getmetatable(obj)=='ssm_comp' then
		return obj==self
	end
	return false
end


ssm_comp_skip_keys={
	__type=true, __rep=true, __opt=true, __name=true
}

ssm_comp_type={
	seq=setmetatable({
		is_allow=function(self, obj)
			if type(obj)=='string' then
				for _,v in ipairs(self) do
					if (v.__name or v)==obj then return true end
				end
			elseif type(obj)=='table' then
				if getmetatable(obj)=='ssm' then
					for _,v in ipairs(self) do if v==obj then return true end end
				elseif getmetatable(obj)=='ssm_comp' then
					return obj==self
				end
			end
			return false
		end,
	}, {
		__tostring=function() return 'seq' end,
		__metatable='seq'
	}),
	alt=setmetatable({
		is_allow=function(self, obj)
			if type(obj)=='string' then return self[obj]~=nil end
			if type(obj)=='table' then return self[obj.__name]~=nil end
		end,
	}, {
		__tostring=function() return 'alt' end,
		__metatable='alt'
	})
}

function ssm_compile(ssm, root)
	local root=root or ssm
	local o={ }
	for k,v in pairs(ssm) do
		local nd={ __rep=v.rep, __opt=v.opt }
		if type(k)=='string' then nd.__name=k
		elseif type(k)=='table' then nd.__name=k.ns
		end
		if v.alt then
			nd.__type=ssm_comp_type.alt
			for _,a in ipairs(v) do
				if a.link then nd[a.link]=a.ref	else
					table.insert(nd, a) end
			end
		elseif v.seq then
			nd.__type=ssm_comp_type.seq
			for _,a in ipairs(v) do
				if type(a)=='string' then table.insert(nd, a)
				--elseif a.ref then table.insert(nd, a.ref)
				else table.insert(nd, a)--ssm_compile(a, root))
				end
			end
		end
		o[k] = nd
		--o[k] = setmetatable(nd, ssm_comp_mt)
	end
	--o=setmetatable(o, ssm_comp_mt)
	for k,v in pairs(o) do
		if not ssm_comp_skip_keys[n] then	for n,a in pairs(v) do
			if type(a)=='string' and not ssm_comp_skip_keys[n] then v[n]=o[a] end
		end end
	end
	return o
end

function M.new_ssm(conf)
	local o={ __source=conf }
	for k,v in pairs(conf) do
		o[k]=parse_ssm(v, o)
		o[k].__name=k
	end
	o.__root=o
	return setmetatable(o, ssm_mt)
end

function ssm_mt:__index(name)
	if ssm_idx[name] then return ssm_idx[name](self) end
end

do
local ssm_reserved = {
	__type=true, __quant=true, __lquant=true, __root=true, __source=true,
	__name=true, __parent=true
}
local function ssm__next(t, k0)
		local k, v = next(t, k0)
		if k==nil then return end
		if ssm_reserved[k] then return ssm__next(t, k) end
		return k, v
end
function ssm_mt:__pairs()
	return ssm__next, self
end
end

function ssm_mt:__call(...)
	if self.__root==self then return ssm_compile(self, ...) end
	local o={ ssm=self.__root, __ssmcur=self, ... }
	return setmetatable(o, ast_mt)
end

function ssm_mt:__len()
	if self.__type~='[]' then return rawlen(self) else return -1 end
end

function ssm_idx:opt()
	return self.__quant=='?' or self.__quant=='*'
end

function ssm_idx:rep()
	return self.__quant=='+' or self.__quant=='*'
end

function ssm_idx:alt()
	return self.__type=='[]'
end

function ssm_idx:seq()
	return #self>0
end

function ssm_idx:link()
	if #self==1 and self.__quant==nil and self.__type~='[]' then
		return self[1]
	end
end

function ssm_idx:ref()
	if #self==1 and self.__quant==nil and self.__type~='[]' then
		return self.__root[self[1]]
	end
end

function ssm_idx:up()
	return self.__parent or self.__root
end

function ssm_idx:ns()
	return rawget(self, '__name')
end


a1=M.new_ssm{
	root='chunks',
	chunks='chunk*',
	chunk='[func if while assign goto+]',
	func='name=id args=id* body=chunks',
	func_expr='args=id* body=chunks',
	value='[$const id func_expr expr]',
	expr='[(op=unop value=value) (lvalue=value op=binop rvalue=value)]',
	assign='local?= lval=id rval=expr?',
	['return']='retval=expr*',
	['goto']='label=label',
	id='$scope{block=chunks up=redefine}',
	label='$scope{block=chunks up=hide}',
	['if']='ifthen+=(cond=expr body=chunks)? else?=chunks',
	['while']='cond=expr:bool body=chunks'
}


local test_a1={
	["chunks"]="chunk*",
	["func_expr"]="args=id*, body=chunks",
	["assign"]="local?=, lval=id, rval=expr?",
	["root"]="chunks",
	["func"]="args=id*, body=chunks, name=id",
	["while"]="body=chunks, cond=expr:bool",
	["if"]="else?=chunks, ifthen+=(body=chunks, cond=expr)?",
	["label"]="{block=chunks, up=hide}",
	["id"]="{block=chunks, up=redefine}",
	["return"]="expr*",
	["chunk"]="[func, if, while, assign, goto+]",
	["goto"]="label",
	["expr"]="[(op=unop, value=value), (lvalue=value, op=binop, rvalue=value)]",
	["value"]="[$const, id, func_expr, expr]",
}
local o1=a1
for k,v in pairs(o1) do
	local o=tostring(o1[k])
	if o~=test_a1[k] then
		print('error '..k..'\n need: "'..test_a1[k]..'"\n  got: "'..o..'"')
	end
end


for k,v in pairs(o1['if'].ifthen) do print(k,v) end
for k,v in pairs(o1['chunk']) do print(k,v) end

assert(o1.expr.alt)
assert(not o1.assign.lval.alt)
assert(not o1.expr.seq)
assert(o1.chunks.seq)
--assert(#o1.chunks==2)
assert(#o1.expr==-1)
assert(o1.expr.alt)
assert(o1['chunk'][5].rep)
assert(not o1['chunk'][5].opt)
assert(#o1['chunk'][5]==1)
assert(not o1['chunk'][5].alt)
assert(o1['root'].ref==o1.chunks)
assert(o1['chunks'].ref==nil)
assert(o1['func']['args'].ref==nil)
assert(o1['if']['else'].ref==o1.chunks)

assert(o1['root'].link=='chunks')
assert(o1['chunks'].link==nil)
assert(o1['func']['args'].link==nil)
assert(o1['if']['else'].link=='chunks')


ast1=M.new_ast(o1)
--f1=ast1:insert('if', { ifthen={ cond='a>0', body='return a+b' } })
--f1_else=f1['else']:insert('return', { lval='s1', rval='str1' })
--inspect(f1)
--inspect(f1_else)
o1_func1=o1.func({ name='func1' })
inspect(o1_func1)
inspect(o1_func1.ssm)
print(o1_func1.__ssmcur)
print(o1_func1.body)

print(o1.func.name)
print(o1.func.name.up)
c1=o1()
inspect(c1['return'])
inspect(c1['return'][1]==c1['return'][1].__name)
inspect(c1['chunks'])
inspect(c1['chunk'].__type.is_allow(c1['chunk'], 'func'))
inspect(c1['chunks'].__type.is_allow(c1['chunks'], 'if'))
inspect(c1['chunks'].__type.is_allow(c1['chunks'], 'chunk'))
--return M
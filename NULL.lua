require'string_ext'
local inspect=require'inspect'


local function indexof(parent, predefs)
	return setmetatable(predefs or {}, { __index=parent })
end


-- local function push_scope(parent, predefs)
-- 		local c2={}
-- 		local idx, out = rule(s, start, indexof(ctx, {capture=c2}))
-- 		local idx, out = rule(s, start, (ctx ))
-- 		-- if idx then table.insert(ctx.capture, c2) print(idx, table.unpack(c2)) end
-- 		return idx, out-- or c2
-- 
-- 	return setmetatable(predefs or {}, { __index=parent })
-- end


local lbnfoper_mt = {}
local lbnfoper_attribs = { captin=1, }
local lbnfoper_funcs = {}


 -- named_capture
function lbnfoper_funcs:alt(source, start, ctx)
	local idx, captopt = start, rawget(self, 'capture_options')
	for _, rule in ipairs(self.rules) do
		local c2={}
		local idx, out = rule(source, start, indexof(ctx, {capture=c2}))
		if idx then
			if #c2==1 then table.insert(ctx.capture, c2[1]) else
				table.insert(ctx.capture, c2)  end

			-- if captopt then ctx.capture[captopt] = out else table.insert(ctx.capture, out)  end
			return idx, out
		end
	end
end

function lbnfoper_funcs:rep(source, start, ctx)
	local idx= start
	::loop::
		local i, c = self.rule(source, idx, ctx)
		if not i then return idx, c end assert(i~=idx)

		idx = i;
	goto loop
end

function lbnfoper_funcs:seq(source, start, ctx)
	local idx = start
	for k, rule in ipairs(self.seq_rules) do
		local i, c = rule(source, idx, ctx)
		if i then idx = i;	else return end
	end
	return idx, out
end

function lbnfoper_funcs:l(source, start, ctx)
			local capname = rawget(self, 'capture_name')
	local out, idx = source:match('^%s*'..self.pattern..'()', start)
		if idx then
			if capname then ctx.capture[capname]=out else 	table.insert(ctx.capture, out)  end
		end

		if idx==nil then return out elseif out=='' then return idx end
		return idx, out
end



function lbnfoper_mt:__index(name)
	if lbnfoper_attribs[name] then rawset(self, name, true) end
	return self
end





function lbnfoper_mt:__call(source, start, ctx)
	-- if self.par
		-- local c2={}
		-- local idx, out = rule(source, start, indexof(ctx, {capture=c2}))
		-- if idx then
			-- if #c2==1 then table.insert(ctx.capture, c2[1]) else
				-- table.insert(ctx.capture, c2)  end

	return self:parse(source, start, ctx)
end




function lbnfoper_mt:__pow(capture_name)
	local c = { capture_name=capture_name, real_object=self }
	for k,_ in pairs(self) do c[k]=rawget(self, k) end
	 -- rawset(c, ')
	return setmetatable(c, lbnfoper_mt)
end

function lbnfoper_mt:__div(capture_options)
	local rule = self
	return function(s, start, ctx)
		local c2={}
		local idx, out = rule(s, start, indexof(ctx, {capture=c2}))
		if idx then table.insert(ctx.capture, c2) print(idx, table.unpack(c2)) end
		return idx, out-- or c2
	end
end



function alt(...)
	return setmetatable({ parse=lbnfoper_funcs.alt, rules={...} }, lbnfoper_mt)
end

function rep(rule)
	return setmetatable({ parse=lbnfoper_funcs.rep, rule=rule }, lbnfoper_mt)
end

function seq(...)
	return setmetatable({ parse=lbnfoper_funcs.seq, seq_rules={...} }, lbnfoper_mt)
end

function l(pattern)
	return setmetatable({ parse=lbnfoper_funcs.l, pattern=pattern }, lbnfoper_mt)
end


function opt(rule)
	return function(source, start, ctx)
		return rule(source, start, ctx) or start
	end
end


-- function l(pattern)
-- 	return function(s, start, ctx)
-- 		local out, idx = s:match('^%s*'..pattern..'()', start)
-- 		if idx==nil then return out elseif out=='' then return idx end
-- 		return idx, out
-- 	end
-- end

function ref(gmr, name)
	return function(s, start, ctx)
		local rule = gmr[name]
		if not rule then error('err: ref '..name) end
		-- local c2={}
		-- local idx, out = rule(s, start, indexof(ctx, {capture=c2}))
		local idx, out = rule(s, start, (ctx ))
		-- if idx then table.insert(ctx.capture, c2) print(idx, table.unpack(c2)) end
		return idx, out-- or c2
	end
end


local char = l"('[^']+')"
local str = l'(".-[^\\]")'
local id = l'([_%w]+[_%w%d]*)'
local num = l"(-?%d+%.?%d*)"

local gmr1 = setmetatable({}, { __index=ref })

local value = alt(
	gmr1.fncall,
	id, num, str, char, seq( l'%(', gmr1.expr, l'%)' )

)
gmr1.expr = seq(
	value
		,rep(seq( alt( l'(%-)', l'(%+)', l'(%*)' ), value))
)
gmr1.fncall = seq( id^'func', l'%(', rep(seq( ref(gmr1,'expr'), l'(,?)' ))^'args' ,l'%)' )


local src0 = '66+6 *063+(1+ x +34+6) +  func( x*6,4*sin(0))'
local src = ' 1 + 2 * ( 31 - fn32  (  321 *  x322 , ( 4 * sin(0) ) )  )  + 0'

print()

ctx={ capture={} }
local i, c = gmr1.expr(src, 1, ctx)
--inspect(i, (c), #src)

local function tostring_(ss)
	local s_num, s_str = '', ''
	for k, v in pairs(ss) do
		if type(v)=='table' then s_num=s_num..' {'..tostring_(v) ..'} '
		elseif type(k)=='number' then s_num=s_num..' '..v
		else s_str=s_str..' '..k..': '..v..', ' end
	end
	return s_str..' '..s_num
end


print(tostring_(ctx.capture):gsub('(%s+)', ' '))
print(src:gsub('(%s+)', ' '))
-- inspect(i,  ctx.capture)





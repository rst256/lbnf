local inspect=require'inspect'
local lbnf=require'lbnf'


local alt = lbnf.combineRules
local rep = lbnf.repeatRule
local seq = lbnf.sequenceRules
local p = lbnf.stringPattern
local l = lbnf.stringLiteral
local opt = lbnf.optionalRule
local ref = lbnf.referenceRule
local list = lbnf.listRule




local char = p"('[^']+')"
local str = p'(".-[^\\]")'
local id = p'([_%w]+[_%w%d]*)'
local num = p"(-?%d+%.?%d*)"

local g = setmetatable({}, { __index=ref })


g.binop10=p'(or)' 
g.binop9=p'(and)'
g.binop8=alt{ p'(<)', p'(>)', p'(<=)', p'(>=)', p'(~=)', p'(==)' }
g.binop7=p'(|)' 
g.binop6=p'(~)'
g.binop5=p'(&)'
g.binop4=alt{ p'(<<)', p'(>>)' }
g.binop3=p'(%.%.)'
g.binop2=alt{ p'(%+)', p'(%-)' }
g.binop1=alt{ p'(%*)', p'(/)', p'(//)', p'(%%)' }
g.binop0=p'(%^)'
g.unop=alt{ p'(not)', p'(#)', p'(%-)', p'(~)' }


local value = seq{ opt(g.unop), alt({ g.fncall, id, num, str, char, seq{ p'%(', g.expr, p'%)' } }) }

g.expr0 =	list(value, 			g.binop0 )
g.expr1 =	list(g.expr0,		g.binop1 )
g.expr2 =	list(g.expr1, 	g.binop2 )
g.expr3 =	list(g.expr2, 	g.binop3 )
g.expr4 =	list(g.expr3, 	g.binop4 )
g.expr5 =	list(g.expr4, 	g.binop5 )
g.expr6 =	list(g.expr5, 	g.binop6 )
g.expr7 =	list(g.expr6, 	g.binop7 )
g.expr8 =	list(g.expr7, 	g.binop8 )
g.expr9 =	list(g.expr8, 	g.binop9 )
g.expr 	=	list(g.expr9, 	g.binop10 )

-- g.expr =list(g.expr1, alt({ p'(%-)', p'(%+)' }) )

g.expr_list = list( g.expr, p',' )
g.fncall = seq({ id, p'%(', (g.expr_list), p'%)' }, {[0]='fncall', 'fname', 'args' })

g.fndef = seq({ l'function', id, p'%(', list(id, l','), p'%)', g.body, l'end' }, {[0]='fndef', 'fname', 'args', 'body' })
g.ifstat = seq({ 
	l'if', g.expr, l'then', g.body, opt(seq{ l'else', g.body }),l'end' }, {[0]='ifstat', 'cond', 'then', 'else' })
g.assign = seq({ id, l'=', g.expr }, {[0]='assign', 'lvar', 'rval' } )
g.Return = seq({ l'return', g.expr }, {[0]='return' })

g.body = opt(list( alt{ g.fndef, g.ifstat, g.assign, g.Return, g.fncall, p'(break)' }, p';?' ))




local src0 = '66||6 *063+(1+ x +34+6) +  func( x^2*6,4*sin(0))'
-- local src = ' 1 + 2 -3 * ( 31 - fn32  (  321 *  x322, 4 * sin(0)  ) + f0(3) )  + 0'
-- local src = ' 1 + 2 * f( 31  )  + 0'
local src1 = ' 1 + 2 -3 * 4*5*6 +7*(9+ 0)/6+4'
local src = [[
a= 1 + 2 -3 * 4*5^2*6 +7*(9+ 0)/6+4
if x+6 or -666 .. 'fsdfsdf' then 
	x= 1-type(x);
	function func1 ( a, b , c)
		r = #a + b + c
		if r then print(r) end
		return r+1
	end
else
	f=0;
end

]]


local function tostring_(ss, dep)
	if type(ss)~='table' then return tostring(ss) end
	local dep, s_num, s_str, s_type = dep or 0, '', ''
	local count=0
	for k, v in pairs(ss) do
		if k==0 then s_type=v
		elseif type(k)=='number' then s_num=s_num..tostring_(v, dep+1)..'\t'
		else s_str=s_str..k..'='..tostring_(v, dep+1)..',\t' end
		count=count+1
	end
	local s=s_str:sub(1,-1)..s_num:sub(1,-1)
	if s_type then s='{'..s_type..': '..s..'}' elseif count>1 then s='('..s..')' end
	if #s>80 then s=s:gsub(' *\t+ *', '\n'..string.rep(' ', dep+1)) else s=s:gsub('%s+', ' ') end
	return s
end


ctx={ capture={} }
local i, c = g.body(src, 1, ctx)
out1=tostring_(ctx.capture):gsub('(%s+)', ' ')



print(tostring_(c))
print()
print(src)





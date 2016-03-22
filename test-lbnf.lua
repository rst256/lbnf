local inspect=require'inspect'
local lbnf=require'lbnf'


local alt = lbnf.combineRules
local rep = lbnf.repeatRule
local seq = lbnf.sequenceRules
local p = lbnf.stringPattern
local opt = lbnf.optionalRule
local ref = lbnf.referenceRule
local list = lbnf.listRule



function getRule(l)

local char = p"('[^']+')"
local str = p'(".-[^\\]")'
local id = p'([_%w]+[_%w%d]*)'
local num = p"(-?%d+%.?%d*)"
-- id.handler=function(x, c, o) print(x, c, o) if o=='x322' then  return false end end
local gmr1 = setmetatable({}, { __index=ref })

local value = alt(
	gmr1.fncall,
	id, num, str, char, seq( p'%(', gmr1.expr, p'%)' ) 
)
-- gmr1.expr = seq(
-- 	value
-- 		,rep(seq( alt( p'(%-)', p'(%+)', p'(%*)',seq(p'(%|)', p'(%|)') ), value))
-- )
-- gmr1.expr =seq(  value, opt(seq(alt( p'(%-)', p'(%+)', p'(%*)' ), gmr1.expr )) )
gmr1.expr =list(value, alt( p'(%-)', p'(%+)', p'(%*)' ) )

-- 
-- gmr1.expr =alt(
-- 	seq(value, alt( p'(%-)', p'(%+)', p'(%*)' ),  gmr1.expr),
-- 	value
-- )
-- gmr1.expr=
-- gmr1.expr_list =alt(
-- 	seq( gmr1.expr, p',', gmr1.expr_list ),
-- 	gmr1.expr
-- )
gmr1.expr_list = list( gmr1.expr, p',' )
-- gmr1.expr_list = seq( gmr1.expr, opt(seq(p',', gmr1.expr_list)) )

gmr1.fncall = seq( id, p'%(', opt(gmr1.expr_list), p'%)' )
-- gmr1.fncall = seq( id^'func', p'%(', rep(seq( gmr1.expr, p',?' ))^'args' ,p'%)' )
-- gmr1.fncall.handler=print
  return gmr1.expr
end



local src0 = '66||6 *063+(1+ x +34+6) +  func( x*6,4*sin(0))'
-- local src = ' 1 + 2 * f( 31  )  + 0'
local src = ' 1 + 2 -3 * ( 31 - fn32  (  321 *  x322, 4 * sin(0)  ) + f0() )  + 0'

print()
--inspect(i, (c), #src)

local function tostring_(ss)
	local s_num, s_str = '', ''
	for k, v in pairs(ss) do
		if type(v)=='table' then s_num=s_num..'{'..tostring_(v) ..'}'
		elseif type(k)=='number' then s_num=s_num..' '..v
		else s_str=s_str..k..':'..v..' ' end
	end
	return s_str..s_num
end


ctx={ capture={} }
local i, c = getRule(l)(src, 1, ctx)
out1=tostring_(ctx.capture):gsub('(%s+)', ' ')

-- local l = lbnf.stringPattern

-- ctx={ capture={} }
-- local i, c = getRule(lbnf.stringPattern)(src, 1, ctx)
-- out2=tostring_(ctx.capture):gsub('(%s+)', ' ')
-- 
-- print(out1)
-- assert(out1==out2)


print(tostring_(c))
print(src)
-- inspect(i,  ctx.capture)





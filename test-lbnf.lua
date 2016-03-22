local inspect=require'inspect'
local lbnf=require'lbnf'


local alt = lbnf.combineRules
local rep = lbnf.repeatRule
local seq = lbnf.sequenceRules
local l = lbnf.stringPattern
local opt = lbnf.optionalRule
local ref = lbnf.referenceRule






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





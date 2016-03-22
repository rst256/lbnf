local lbnf=require'lbnf'

--просто назначаем краткие имена для констр. правил
local alt = lbnf.combineRules
local rep = lbnf.repeatRule
local seq = lbnf.sequenceRules
local p = lbnf.stringPattern
local opt = lbnf.optionalRule
local ref = lbnf.referenceRule
local list = lbnf.listRule
--alt выбор первого подходящ. правило из списка
--seq последов. правил
--list список 




local id = p'([_%w]+[_%w%d]*)'
local num = p"(-?%d+%.?%d*)"

-- это таблица, нужна только что бы правило value смогло ссылаться на gmr1.expr - `ref(gmr1, 'expr')`
local gmr1 = { }


-- правило вырора (число или ид или выраж. в скобках) 
local value = alt(	id, num, str, char, seq( p'%(', ref(gmr1, 'expr'), p'%)' ) ) 

-- правило для выражений, состоит из 2х правил вложенных друнг в друга по приоритету
gmr1.expr =list(list(value, p'(%*)'  ), alt( p'(%-)', p'(%+)' ) )





-- это не важно, печатает результат
local function tostring_(ss)
	local s_num, s_str = '', ''
	for k, v in pairs(ss) do
		if type(v)=='table' then s_num=s_num..'{'..tostring_(v) ..'}'
		elseif type(k)=='number' then s_num=s_num..' '..v
		else s_str=s_str..k..':'..v..' ' end
	end
	return s_str..s_num
end

--все я устал комментировать...
local src = '1 + 2 + 3 * x- 5-55 + 6-66 * 7 * 8 *(9 -0)'
local i, c = gmr1.expr(src, 1, ctx)

print(tostring_(c))
print(src)





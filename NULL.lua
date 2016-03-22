local lbnf=require'lbnf'

--������ ��������� ������� ����� ��� ������. ������
local alt = lbnf.combineRules
local rep = lbnf.repeatRule
local seq = lbnf.sequenceRules
local p = lbnf.stringPattern
local opt = lbnf.optionalRule
local ref = lbnf.referenceRule
local list = lbnf.listRule
--alt ����� ������� ��������. ������� �� ������
--seq ��������. ������
--list ������ 




local id = p'([_%w]+[_%w%d]*)'
local num = p"(-?%d+%.?%d*)"

-- ��� �������, ����� ������ ��� �� ������� value ������ ��������� �� gmr1.expr - `ref(gmr1, 'expr')`
local gmr1 = { }


-- ������� ������ (����� ��� �� ��� �����. � �������) 
local value = alt(	id, num, str, char, seq( p'%(', ref(gmr1, 'expr'), p'%)' ) ) 

-- ������� ��� ���������, ������� �� 2� ������ ��������� ����� � ����� �� ����������
gmr1.expr =list(list(value, p'(%*)'  ), alt( p'(%-)', p'(%+)' ) )





-- ��� �� �����, �������� ���������
local function tostring_(ss)
	local s_num, s_str = '', ''
	for k, v in pairs(ss) do
		if type(v)=='table' then s_num=s_num..'{'..tostring_(v) ..'}'
		elseif type(k)=='number' then s_num=s_num..' '..v
		else s_str=s_str..k..':'..v..' ' end
	end
	return s_str..s_num
end

--��� � ����� ��������������...
local src = '1 + 2 + 3 * x- 5-55 + 6-66 * 7 * 8 *(9 -0)'
local i, c = gmr1.expr(src, 1, ctx)

print(tostring_(c))
print(src)





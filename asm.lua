--package.path = package.path .. [[C:\Projects\Lua\utils\?.lua]]
require'string_ext'
--local translit = require'translit'

--#define NOT_NULL(E) if(!E) exit(0)
--/* Найти исходное определение.
-- Если ид ident был переопределен в области scope тогда будет возвращено
-- его
-- (т.е. ident имеет определение
--*/
--	//внешнее беззнаковое

local src = [[
int впвп(void);
целое пппп6=0;
typedef int my   type;
целое main(целое argc, char **argv){
	константа my type local sym ппвп=0;
	если(local sym ппвп) пппп6=1;
	возврат впвп();
}
int впвп(void){ printf("jkdsfbsd\n"); return 6; }

]]


local function keywords(kwords, rules, modif)
	local rules = rules or {}
	if modif==nil then modif = '' else modif = modif..':' end
	for kw in kwords:gmatch"%s*([^%s]+)%s*" do
		rules[kw] = modif..'('..kw:esc_pattern()..')'
	end
	return rules
end

local tok_rules = {
	ident = '([_%wа-яА-Я]+[_%w%dа-яА-Я ]*[_%w%dа-яА-Я]+)',
	number = { "(-?%d+%.?%d*)", "finite:(NULL)" },
	string = '(".-[^\\]")',
	char = "('[^']+')",
	pp = "([\n]%s*#%w+%s+[^\n]+\n)",
	comm = { "(//[^\n]+\n)", "(/%*.-%*/)" },
	ws = "(%s+)",
	ptr_rang = "(%*[%s%*]*%*)",
}

keywords('++ -- == <= >= == || && + - * / \\ | & ! != = , ; : ? ', tok_rules)
keywords('{ } [ ] < > -> . ( )', tok_rules)

local translate_keyword = {
	['если']='if', ['стоп']='break', ['иначе']='else', ['возврат']='return',
	['для']='for', ['пока']='while', ['выбор']='switch',
	['типопр']='typedef',
}

local translate_type = {
	['целое']='int', ['пустое']='void'
}

local translate_attrib = {
	['внешнее']='extern', ['константа']='const', ['беззнаковое']='unsigned',
}

local function translate_rule(t)
	local rules = {}
	for k, v in pairs(t) do
		table.insert(rules, 'finite:('..k..')')
		table.insert(rules, 'finite:('..v..')')
	end
	return rules
end


local translit_counter = 1
local id_assoc = {}
local id_ru2en = {}
local type_assoc = {}
local type_ru2en = {}
local function esc_spaces(str)
--	local n = id_ru2en[str]
--	if n~=nil then return n end
--	n = str:gsub('(%s+)', '_'):gsub('([^%w%d_]+)', function(a)
--		translit_counter = translit_counter + 1
--		return '_'..translit_counter..'_' end)
--	id_assoc[n] = str
--	id_ru2en[str] = n
--	return n
	return str:gsub('(%s+)', '_')
end

local function translate_function(translate)
	return function(str) return translate[str] or esc_spaces(str) end
end

--tok_rules.keyword = keywords('if then else return for while switch', false, 'finite')
tok_rules.keyword = translate_rule(translate_keyword)
tok_rules.type = translate_rule(translate_type)
tok_rules.attrib = translate_rule(translate_attrib)
--tok_rules.type = keywords('int char void', false, 'finite')
table.insert(tok_rules.type, 'finite:(my +type)')


pp = {
	ident = function(str)
		local n = id_ru2en[str]
		if n~=nil then return n end
		n = str:gsub('(%s+)', '_')
		n = n:gsub('([^%w%d_]+)', function(a)
			translit_counter = translit_counter + 1
			return '_'..translit_counter..'_' end)
		if n~=str then id_assoc[n] = str; id_ru2en[str] = n; end
		return n
	end,
	keyword = translate_function(translate_keyword),
	type = function(str)
		local n = translate_type[str] or type_ru2en[str]
		if n~=nil then return n end
		str = str:gsub('(%s+)', '_')
		n = str:gsub('([^%w%d_]+)', function(a)
			translit_counter = translit_counter + 1
			return '_'..translit_counter..'_' end)
		if n~=str then type_assoc[n] = str; type_ru2en[str] = n; end
		return n
	end,
	attrib = translate_function(translate_attrib),
}


local s = ''
for name,arg, arg2 in src:gtok(tok_rules) do
	print(string.format("%0.15s", name),
		string.format("%q", arg:sub(1, 20):gsub('\n', '\\n')), arg2)
	local pp_helper = pp[name] or tostring
	s = s .. pp_helper(arg)
end
print('------------------------ out ------------------------')
print(s)

local file = io.open("out.c", "w+")
file:write(s)
file:close()

local file = io.open("clztest_out.h", "w+")
file:write[[/*
Use this file for testing naming conflicts in auto generated names
For use add this at begining to you source file
*/
]]

file:write('\n/* Check types */\n')
for k,v in pairs(type_assoc) do
	file:write('typedef int '..k..';\n')
end

file:write('\n/* Check variables */\n')
for k,v in pairs(id_assoc) do
	file:write('int '..k..';\n')
end


file:close()



file = io.open("out.err", "w+")
file:close()

os.execute([[C:\lcc\bin\lcc.exe C:\Projects\Lua\utils\out.c -errout=out.err 2>NULL]])
os.execute([[C:\lcc\bin\lcclnk C:\Projects\Lua\utils\out.obj 2>> out.err]])


file = io.open("out.err", "r")
err = file:read'*a'
file:close()

for k,v in pairs(id_assoc) do
	--print(k, v)
	err = err:gsub("("..k..")", v)--"‘"..v.."’")
	--err = err:gsub("'("..k..")'", "‘"..v.."’")
end

for k,v in pairs(type_assoc) do
	--print(k, v)
	err = err:gsub("("..k..")", v)--"‘"..v.."’")
	--err = err:gsub("'("..k..")'", "‘"..v.."’")
end

print('------------------------ err ------------------------')
print(err)

print('------------------------ run ------------------------')
os.execute([[C:\Projects\Lua\utils\out.exe 2>> out.l]])
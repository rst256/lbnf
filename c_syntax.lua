

local function keywords(kwords, rules, modif)
	local rules = rules or {}
	if modif==nil then modif = '' else modif = modif..':' end
	for kw in kwords:gmatch"%s*([^%s]+)%s*" do
		rules[kw] = modif..'('..kw:esc_pattern()..')'
	end
	return rules
end

local tok_rules = {
	ident = '([_%w]+[_%w%d]*)',
	number = { "(-?%d+%.?%d*)", "finite:(NULL)" },
	string = '(".-[^\\]")',
	char = "('[^']+')",
	pp = "([\n]%s*#%w+%s+[^\n]+\n)",
	comm = { "skip:(//[^\n]+\n)", "skip:(/%*.-%*/)" },
	ws = "skip:(%s+)",
	ptr_rang = "(%*[%s%*]*%*)",
}

keywords('++ -- == <= >= == || && + - * / \\ | & ! != = , ; : ? ', tok_rules)

keywords('void typedef else break switch if return for while', tok_rules, 'finite')

keywords('{ } [ ] < > -> . ( )', tok_rules)

tok_rules.type = keywords(
	'int char long float double short', false, 'finite')

tok_rules.attrib = keywords(
	'extern const unsigned static volatile', false, 'finite')




return tok_rules
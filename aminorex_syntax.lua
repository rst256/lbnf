require'string_ext'

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
	number = "(-?%d+%.?%d*)",
	char = "('[^']+')",
	pp = "(%s*#%s*[%w%d_]+)",
	pp_include= '%s*#%s*include%s*"(.-[^\\])"',
	lua_pp_def = "finite:/%*@%s*([_%w]+[_%w%d]*)%s*(%b())%s*(%b{})%s*@%*/",
	lua_def_gen = "finite:/%*@%s*(%b[])%s*(%b())%s*(%b{})%s*@%*/",
	lua_pp_block = "finite:/%*@%s*(%b{})%s*@%*/",
	string = '(".-[^\\]")',
	comm = { "skip:(//[^\n]+\n)", "skip:(/%*.-%*/)" },
	ws = "skip:(%s+)",
	typedef = {		'finite:typedef%s+struct%s*[%w_]*[%w%d_]*%s*%b{}%s*%**%s*([%w_]+[%w%d_]*)%s*;',
'finite:typedef%s+union%s*[%w_]*[%w%d_]*%s*%b{}%s*%**%s*([%w_]+[%w%d_]*)%s*;',
'finite:typedef%s+enum%s*[%w_]*[%w%d_]*%s*%b{}%s*%**%s*([%w_]+[%w%d_]*)%s*;',
		'finite:typedef%s+[^;]-%s+%**%s*([%w_]+[%w%d_]*)%s*;',
	},
	lua_macros = {},
}

keywords('$ @', tok_rules)

keywords('++ -- == <= >= == || && + - * / \\ | & ! != = , ; : ? ', tok_rules)

keywords('void else break switch if return for while', tok_rules)

keywords('{ } [ ] < > -> . ( ) => ::', tok_rules)

tok_rules.type = keywords(
	'int char long float double short', false, 'finite')

tok_rules.attrib = keywords(
	'extern const unsigned static volatile', false, 'finite')






return tok_rules
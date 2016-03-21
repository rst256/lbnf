require"package_ext"
local inspect=require'inspect'
local serpent = require("serpent")
-- local inspect1 = require"inspect"
-- inspect1(inspect)
local path_sep = package.config:match'([^\n]+)\n'

local function get_test_fn(filename)
	local name = filename:match('.*'..path_sep..'(.*)')
	local path = filename:match('(.*)'..path_sep..'.*')..path_sep..'.tests'..path_sep
	return path..name, name:match"([^%.]+)"
end

local src_fn = arg[1]
local tst_fn, mn = get_test_fn(src_fn)

local file = io.open(tst_fn, "r")
if not file then error("can't open test file: "..tst_fn, 2) end
local tst_src = file:read("*a")
file:close()

print('\n----------------------- run tests for '..mn..'-----------------------')

local mod = require(mn)
local env = setmetatable({ [mn]=mod, serpent=serpent, inspect=inspect },  {
	__index=function(self, key) return rawget(mod, key) or rawget(_G, key) end,
	__metatable='test_env'
})

local function pp_macros(mn, to, src)
	return src:gsub(mn..'%s*(%b())', function(args)
		local s = ''
		local args = args:sub(2, #args-1)..','
		for arg in args:gmatch"%s*([^;]+)%s*," do
			s = s .. 'io.write("-------------- '..arg..
				' --------------\\n"..'..to..'('..
				arg..').."\\n");\n'
		end
		return s
	end)
end

tst_src = pp_macros('%$', 'serpent.block', tst_src)
tst_src = pp_macros('%?', 'inspect.inspect', tst_src)

--print(tst_src)
importstring(tst_src, tst_fn, env)()

-- for k,v in pairs(arg) do print(k,v) end
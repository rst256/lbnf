require'table_ext'

local M = { packages={} }

local template_mt = { __metatable='template' }

-- function template_mt:__tostring()
--   if self.__source==nil then
--   	if self.__file~=nil then self.__source=self.__file:read'*a' end
--   end
--   return self.__source
-- end

function M.open(file_name)
	local f = io.open(file_name)
  if f==nil then return nil end
  return M.new(f:read'*a')
end

local path = "?.lua;modules/?.lua"
-- package.path = package.path .. ";?.lua;.tests/?.lua"
local _, _, path_separator = string.find(package.config, "^(%S+)\n")

local function searcher(modulename)
	local errmsg = ""
	local modulepath = string.gsub(modulename, "%.", path_separator)
	for mp in string.gmatch(path, "([^;]+)") do
		local filename = string.gsub(mp, "%?", modulepath)
		local fh = io.open(filename, "rb")
		if io.type(fh) == "file" then
			--local first_line = fh:read("*l")
			fh:close()
			return filename, nil
		end
		errmsg = errmsg.."\n\tno file '"..filename.."' (checked with plugins loader)"
	end
  error(errmsg, 2)
end

local function include(name, env)
	if M.packages[name] then return M.packages[name] end
	local f = searcher(name)
  fn, er = load(io.open(f):read'*a', 'module: '..name, 'tb', env)
  if not fn then error(er, 2) end
  M.packages[name] = fn()
  return M.packages[name]
end

local function import(name, env)
	if M.packages[name] then return M.packages[name] end
	local f = searcher(name)
	local module_lib = {}
	local env1 = setmetatable({}, {
		__index=function(self, n) return module_lib[n] or env[n] end,
		__newindex=function(self, n, v) module_lib[n]=v end,
	})
  fn, er = load(io.open(f):read'*a', 'module: '..name, 'tb', env1)
  if not fn then error(er, 2) end
  local fn_ret, fn_er = fn()
  if fn_ret==false then error('module: '..name..' runtime error '..(fn_er or ''), 2) end
  M.packages[name] = module_lib
  return M.packages[name]
end

local function write(s)
	if output==nil then output='' end
	output=output..s
end

function M.echo(src)
	local tmpl = M.new(src)
	if tmpl==nil then return end
	return tmpl
  -- return setmetatable({}, {
  -- 	__call=function(self, ...) tmpl.write(tmpl(...)) end,
  -- 	__index=tmpl, __newindex=tmpl,
  -- })
end

function M.new(src)
  local s=src:gsub('^#([^\n]*)', '@[local %1 = ...]')

  local function pp_block(s)
	  -- local s = s:gsub('(@)(%b{})', function(p, d)
	  -- 	local d = d:sub(2, #d-1)
	  -- 	local t, n, b = d:match'%s*([%a_]+[%a%d_]*)%s+([%a_]+[%a%d_]*)%s*:(.+)'
	  -- 	print(t, n, b)
	  -- end)
		local out, bi0='', 1

	  local function pp_literal(ls)
			return (' '..ls):gsub('(%$%b[])',
				function(v) return ']] .. '..v:sub(3, #v-1)..' .. [[' end)
	  end

	  for bi, block, ei in s:gmatch'()@(%b[])()' do
	  	if bi>bi0 then out=out..'write([['..pp_literal(s:sub(bi0, bi-1))..']])\n' end
	  	out=out..block:sub(2, #block-1)..'\n'
	  	bi0=ei--+1
	  end

	  if bi0<#s then out=out..'write([['..pp_literal(s:sub(bi0, #s))..']])\n' end
	  out=out..'\n\n return output'

		return out
  end

  -- for bi, block, ei in s:gmatch'()@(%b[])()' do
  -- 	if bi>bi0 then out=out..'write([['..pp_literal(s:sub(bi0, bi-1))..']])\n' end
  -- 	out=out..block:sub(2, #block-1)..'\n'
  -- 	bi0=ei--+1
  -- end
  -- if bi0<#s then out=out..'write([['..pp_literal(s:sub(bi0, #s))..']])\n' end
  -- out=out..'\n\n return output'
  --print(out)
  local fn, er
  local env = { template=M.new, write=write }
  env.include=function(name) return include(name, env) end
  env.import=function(name) return import(name, env) end
  env.fread=function(name)
  	local f = io.open(name)
  	if f then return f:read'*a' else error('open file '..name, 2) end
  end
  env = setmetatable(env, {
  	__index=_G,
  	__call=function(self, ...) return fn(...) end
  })
  fn, er = load(pp_block(s), '', 't', env)
  if not fn then error(er, 2) end
  return env
end

function template_mt:__newindex(name, value)
  self.__args[name]=value
end

function template_mt:__index(name)
  return rawget(self.__args, name)
end

template_mt.__pairs=gen_pairs{
	skip_keys={ __source=true, __file=true, __args=true }
}


return M
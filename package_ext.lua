#@debug: local inspect = require("inspect")

local rawget, rawset, getmetatable, setmetatable, type, print =
	rawget, rawset, getmetatable, setmetatable, type, print

local M = { error=error }
local M_mt = {}

if _VERSION > "Lua 5.1" then
--	assert(not setfenv)
	setfenv = setfenv or function(func, env)
		local fn, err = load(string.dump(func), "setfenv", "b", env)
		if fn == nil then M.error("setfenv: " .. err, 2) end
		return fn
	end
	--assert(not getfenv)
	function getfenv(func) return _G;	end --fixme
end

if _VERSION > "Lua 5.2" then
	do
		--assert(not loadstring)
		function loadstring(source_string, chunk_name, env)
			return load(source_string, chunk_name, "bt", env or _ENV);
		end
	end
end

--table.insert( package.loaders, function(...) print("package.loaders", ...) end )
--setmetatable(package.preload, {
--		__index = function(t, k)
--			print("package.preload", t, k)
--			return function(...)
--				print("@@@@", ...)
--				return {...}
--			end
--		end
--	}
--)

--package.preload["class(.*)"] = function(t, k)
--			print("package.preload", t, k)
--			return function(...)
--				print("@@@@", ...)
--				return {...}
--			end
--		end

--print( require"class(m)")


M.default_proxy = setmetatable({
		require = require, print = print, setmetatable = setmetatable
	}, {
		__index = function(t, k)
			--print("package.__index", t, k, _G[k])
			if _G[k] then
				--io.write(k.." = "..k..", ");
				return _G[k]
			else
				return {key = k}
			end
		end,
		__newindex = function(t, k, v)
			--print("package.__newindex", t, k, v)
			rawset( t, k, v )
		end
})

function M.importstring(src, path, proxy)
	local func, errmsg
	--[[
	if type(locals)=='table' then
		local loc_names, loc_vals, src_sh = '  ', {}, ''
		for k, v in pairs(local) do
			 = loc_names..k..', '
			table.insert(loc_vals, v)
		end
		src = src:gsub("^(%s*#[^\n]*)", function(sh) src_sh = sh; return ''	end)
		src = src_sh..'\n'..loc_names:sub(1, #loc_names-2)..' = ...;\n'..src
	end
	]]--
	if _VERSION <= 'Lua 5.1' then
		func, errmsg = loadstring(src, path or debug.getinfo(2,"l").currentline)
		if func then setfenv(func, proxy or M.default_proxy) end
	else
		func, errmsg = load(src, path or debug.getinfo(2,"l").currentline,
			"bt", proxy or M.default_proxy)
	end
	if not func then
		M.error("M.import:\n"..errmsg, 2)
	end
	return func
end
importstring = M.importstring

function M.import(name, searchpath, proxy)
	local path, errmsg = package.searchpath(name, searchpath or package.path)
	if path == nil then
		M.error("M.import: module "..name.." not find:\n"..errmsg, 2); end

	local file = io.open(path, "r")
	local src = file:read("*a")
	file:close()

	return M.importstring(src, path, proxy)
end
import = M.import



do

local class_locals = [[
local error, class, typeof, classof = ...;\n
]]

local class_env = {}


M.class = setmetatable({ __path=package.path }, { __index=function(self, name)
	local path, errmsg = package.searchpath(name, self.__path, class_env)
	if path == nil then
		M.error("file for class "..name.." not find:\n"..errmsg, 2); end

	local file = io.open(path, "r")
	local src = file:read("*a")
	file:close()

	src = src:gsub("%f[%a]class%f[%A]%s+(%w+)%s*(%b{})", function(name, body)
		body = body:sub(2, #body-1)
		print("class", name, body)

	end)

	return M.importstring(src, path, proxy)
end})

end


return M
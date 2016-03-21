
local M = {}

local rawtype = type
local default_type = "...";

local selector_mt = {}
function selector_mt:__call(...)
	--~ for _, v in ipairs{...} do
	while arg do

			local arg = ...
			--~ local is_match, error_msg = self:check(arg)
			local is_match, result = self:check(v)
			if type(is_match) ~= "boolean" then error(" is_match type:", 2)
			elseif is_match then return result
			elseif result then print(arg, result) end
			return nil
		end
	end


function selector( selector_class, ...)
	return setmetatable(selector_class:new(...), selector_mt)
end

function M.metatype(var)
	local t = { type = rawtype(var) }
	if t.type == "table" or t.type == "userdata"  then
		local mt = getmetatable(var);
		local mt_raw = debug.getmetatable(var);
		if rawtype(mt) == "table" or rawtype(mt) == "userdata"  then
			setmetatable(t, {__index = mt})
		else
			t.meta = mt
		end
		if rawtype(mt_raw) == "table" or rawtype(mt_raw) == "userdata"  then
			local mt_call_t = rawtype(mt_raw["__call"])
			if mt_call_t == "function" then
				t.callable = true
			elseif mt_call_t == "table" or mt_call_t == "userdata" then
				t.callable = M.metatype(mt_raw["__call"]).callable
			end
		end
	elseif t.type == "function" then
		t.callable = true
	end
	return t
end

local function swith_type(type_tree, var)
	local mt = getmetatable(var);
	if rawtype(mt) == "string" then
		return	type_tree[mt] or type_tree[rawtype(var)] or
					type_tree[default_type] or false;
	else
		return type_tree[rawtype(var)] or type_tree[default_type] or false; end
end

local function call_func(type_tree, ...)

	local tt_node, call_tt_node = type_tree, type_tree[default_type];
	for _, arg in ipairs({...}) do
		local r = swith_type(tt_node, arg);
		if r == false then
			break;
		else
			tt_node = r;
			if getmetatable(r) and getmetatable(r).__call then call_tt_node = r; end
		end
	end
	return call_tt_node(...);
end

local overload_short_typenames = {
	["_"] = "nil", b = "boolean", c = "thread",
	n = "number", s = "string",	t = "table", f = "function",
	u = "userdata", v = "..."
}

local function add_overload_func(func_table, sign, ovl_func)
	if rawtype(func_table) ~= "table" then
		error("arg #1 expect table got "..rawtype(func_table), 2)
	end
	if rawtype(sign) ~= "string" then
		error("arg #2 expect string got "..rawtype(ovl_func), 2)
	end
	if type(ovl_func) ~= "function" then
		error("arg #3 expect function got "..rawtype(ovl_func), 2)
	end

	local tt_node = func_table
	if sign:match("^[0bcfnstuv]+$") then
		for i=1, #sign do
			local w = overload_short_typenames[string.char(sign:byte(i))]
			local tt_node_next = tt_node[w] or {};
			if tt_node[w] == nil then
				rawset(tt_node, w, tt_node_next);
			end
			tt_node = tt_node_next;
		end
	else
		for w in string.gmatch(sign, "([_%a%.]+[_%a%.%d:]*)%s*,?") do --"([%a*%.]+)%s*,?"
			local tt_node_next = tt_node[w] or {};
			if tt_node[w] == nil then
				rawset(tt_node, w, tt_node_next);
			end
			tt_node = tt_node_next;
		end
	end
	setmetatable(tt_node, {
			__call = function(self, ...) return ovl_func(...); end
	});

	return func_table
end

local overload_function_mt = {
	__call = call_func,
	__metatable = "overload",
	__newindex = add_overload_func
}

function M.tofunc(over_obj)
	if M.metatype(over_obj).meta ~= "overload" then
		error("arg #1 expect metatable `overload`, got "..type(over_obj), 2);
	end
	return function(...) return over_obj(...) end
end

local function overload(func, sign, ovl_func)
	local func_table;
	local t = M.metatype(func)
	if t.type == "function" then
		func_table = setmetatable({}, overload_function_mt);
		rawset(func_table, default_type, setmetatable({}, {
			__call = function(self, ...) return func(...); end
		}) );
	elseif t.meta == "overload" then
		func_table = func
	elseif t.type == "table" and sign == nil then
		func_table = setmetatable({}, overload_function_mt);
		for k, v in pairs(func) do
			if not M.metatype(v).callable then
				error("arg #1 field "..k.." expected callable value, got "..type(v), 2)
			end
			add_overload_func(func_table, k, v)
		end
		return func_table
	else
		error("error, arg #1 expect function or table, got "..t, 2)
	end
	return add_overload_func(func_table, sign, ovl_func);
end
M.overload = overload;

local function coercion( coercion_function, source_type_selector, target_type_selector )
	local func_table;
	if type(coercion_function) == "function" then
		func_table = setmetatable({
			source_types = selectors_table{ },
			target_types = selectors_table{  }
		}, 	{
			__call = call_func,
			__metatable = "coercion",
			__newindex = add_coercion_func
		});
	elseif type(coercion_function) == "function" then
		func_table = coercion_function;
	else
		return
	end
	return add_coercion(func_table, source_type_selector, target_type_selector);
end
M.coercion = coercion;

local M_mt = {
	__index = M,
	__call = swith_type
	--~  function(self, base_func, over_sign, over_func)
	--~ 	local t = type(base_func)
	--~ 	if t == "table" then
	--~ 		if
	--~ end
}


return setmetatable({}, M_mt )
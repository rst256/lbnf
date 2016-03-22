local class = require'class'

local M = {}

local lbnfoper = class.lbnfoper{



}




local function indexof(parent, predefs)
	return setmetatable(predefs or {}, { __index=parent })
end




local lbnfoper_mt = { __index={} }
local lbnfoper_attribs = { captin=1, }
local lbnfoper_funcs = {}


 -- named_capture
function lbnfoper_funcs:combineRules(source, start, ctx)
	local idx, captopt = start, rawget(self, 'capture_options')
	for _, rule in ipairs(self.rules) do
		local idx, out = rule(source, start, ctx)
		if idx~=nil then return idx, out end
	end
end

function lbnfoper_funcs:repeatRule(source, start, ctx)
	local idx, out = start, {}
	::loop::
		local i, c = self.rule(source, idx, ctx)
		if not i then return idx, out end assert(i~=idx)
		idx = i; table.insert(out, c)
	goto loop
end

function lbnfoper_funcs:seq(source, start, ctx)
	local idx, out = start, {}
	for k, rule in ipairs(self.seq_rules) do
		local i, c = rule(source, idx, ctx)
		if i==nil then return end
		idx = i; table.insert(out, c)
	end
	return idx, out
end

function lbnfoper_funcs:listRule(source, start, ctx)
	local idx, out = start, {}
	::loop::
		local i, c = self.item(source, idx, ctx)
		if i==nil then if idx==start then return else return idx, out end end
		idx = i; table.insert(out, c)

		local i, c = self.separator(source, idx, ctx)
		if i==nil then return idx, out end 
		idx = i; table.insert(out, c)

	goto loop
end

function M.listRule(list_item_rule, separator_rule)
	return setmetatable({ 
		item=list_item_rule, separator=separator_rule, parse=lbnfoper_funcs.listRule}, lbnfoper_mt)
end

function lbnfoper_funcs:ultraFilter(source, start, ctx)
	-- local capname = rawget(self, 'capture_name')
	local idx, out = self.filter_func(source, start, self.filter_opts)
	-- if idx then
	-- 	if capname then ctx.capture[capname]=out else 	table.insert(ctx.capture, out)  end
	-- end
	return idx, out
end


-- function lbnfoper_mt.__index.capture(name)
-- 	if lbnfoper_attribs[name] then rawset(self, name, true) end
-- 	return self
-- end





function lbnfoper_mt:__call(source, start, ctx)
	-- if self.parse~=lbnfoper_funcs.ultraFilter then
	-- 	local c2={}
	-- 	local idx, out = rule(source, start, indexof(ctx, {capture=c2}))
	-- 	if idx then
	-- 		if #c2==1 then table.insert(ctx.capture, c2[1]) else table.insert(ctx.capture, c2)  end
	-- 		return idx, out
	-- 	end
	-- else
		local idx, out = self:parse(source, start, ctx)	
		if idx~=nil and self.handler then 
			local result = self:handler(ctx, out)
			if result==false then return elseif result==nil then return idx, out else return idx, result end
		else
			return idx, out
		end
		-- local c2={}
		-- local idx, out = rule(source, start, indexof(ctx, {capture=c2}))
		-- if idx then
			-- if #c2==1 then table.insert(ctx.capture, c2[1]) else
				-- table.insert(ctx.capture, c2)  end


end




function lbnfoper_mt:__pow(capture_name)
	local c = { capture_name=capture_name, real_object=self }
	for k,_ in pairs(self) do c[k]=rawget(self, k) end
	 -- rawset(c, ')
	return setmetatable(c, lbnfoper_mt)
end

function lbnfoper_mt:__div(capture_options)
	local rule = self
	return function(s, start, ctx)
		local c2={}
		local idx, out = rule(s, start, indexof(ctx, {capture=c2}))
		if idx then table.insert(ctx.capture, c2) print(idx, table.unpack(c2)) end
		return idx, out-- or c2
	end
end



function M.combineRules(...)
	return setmetatable({ parse=lbnfoper_funcs.combineRules, rules={...} }, lbnfoper_mt)
end

function M.repeatRule(repeated_rule)
	return setmetatable({ parse=lbnfoper_funcs.repeatRule, rule=repeated_rule }, lbnfoper_mt)
end

function M.sequenceRules(...)
	return setmetatable({ parse=lbnfoper_funcs.seq, seq_rules={...} }, lbnfoper_mt)
end



function M.stringPattern(pattern)
	return M.ultraFilter(function(source, start, pattern)
		local out, idx = source:match('^%s*'..pattern..'()', start)
		if idx==nil then assert(type(out)=='number' or out==nil) return out end
		assert(type(idx)=='number' ) 
		return idx, out 
	end, pattern)
end



function M.optionalRule(optional_rule)
	return function(source, start, ctx)
		local idx, out = optional_rule(source, start, ctx)
		if idx==nil then return start else return idx, out end
	end
end



function M.referenceRule(table_of_rules, rule_name)
	return function(s, start, ctx)
		local rule = table_of_rules[rule_name]
		if not rule then error('referenceRule: '..table_of_rules..' ["'..rule_name..'"] == nil') end
		-- local c2={}
		-- local idx, out = rule(s, start, indexof(ctx, {capture=c2}))
		local idx, out = rule(s, start, (ctx ))
		-- if idx then table.insert(ctx.capture, c2) print(idx, table.unpack(c2)) end
		return idx, out-- or c2
	end
end

function M.ultraFilter(filter_func, filter_opts)
	return setmetatable({ 
		parse=lbnfoper_funcs.ultraFilter, filter_func=filter_func, filter_opts=filter_opts 
	}, lbnfoper_mt)
end



return M
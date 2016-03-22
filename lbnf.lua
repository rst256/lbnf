
local M = {}

local function indexof(parent, predefs)
	return setmetatable(predefs or {}, { __index=parent })
end


-- local function push_scope(parent, predefs)
-- 		local c2={}
-- 		local idx, out = rule(s, start, indexof(ctx, {capture=c2}))
-- 		local idx, out = rule(s, start, (ctx ))
-- 		-- if idx then table.insert(ctx.capture, c2) print(idx, table.unpack(c2)) end
-- 		return idx, out-- or c2
-- 
-- 	return setmetatable(predefs or {}, { __index=parent })
-- end


local lbnfoper_mt = {}
local lbnfoper_attribs = { captin=1, }
local lbnfoper_funcs = {}


 -- named_capture
function lbnfoper_funcs:alt(source, start, ctx)
	local idx, captopt = start, rawget(self, 'capture_options')
	for _, rule in ipairs(self.rules) do
		local c2={}
		local idx, out = rule(source, start, indexof(ctx, {capture=c2}))
		if idx then
			if #c2==1 then table.insert(ctx.capture, c2[1]) else
				table.insert(ctx.capture, c2)  end

			-- if captopt then ctx.capture[captopt] = out else table.insert(ctx.capture, out)  end
			return idx, out
		end
	end
end

function lbnfoper_funcs:rep(source, start, ctx)
	local idx= start
	::loop::
		local i, c = self.rule(source, idx, ctx)
		if not i then return idx, c end assert(i~=idx)

		idx = i;
	goto loop
end

function lbnfoper_funcs:seq(source, start, ctx)
	local idx = start
	for k, rule in ipairs(self.seq_rules) do
		local i, c = rule(source, idx, ctx)
		if i then idx = i;	else return end
	end
	return idx, out
end

function lbnfoper_funcs:l(source, start, ctx)
			local capname = rawget(self, 'capture_name')
	local out, idx = source:match('^%s*'..self.pattern..'()', start)
		if idx then
			if capname then ctx.capture[capname]=out else 	table.insert(ctx.capture, out)  end
		end

		if idx==nil then return out elseif out=='' then return idx end
		return idx, out
end



function lbnfoper_mt:__index(name)
	if lbnfoper_attribs[name] then rawset(self, name, true) end
	return self
end





function lbnfoper_mt:__call(source, start, ctx)
	-- if self.par
		-- local c2={}
		-- local idx, out = rule(source, start, indexof(ctx, {capture=c2}))
		-- if idx then
			-- if #c2==1 then table.insert(ctx.capture, c2[1]) else
				-- table.insert(ctx.capture, c2)  end

	return self:parse(source, start, ctx)
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
	return setmetatable({ parse=lbnfoper_funcs.alt, rules={...} }, lbnfoper_mt)
end

function M.repeatRule(repeated_rule)
	return setmetatable({ parse=lbnfoper_funcs.rep, rule=repeated_rule }, lbnfoper_mt)
end

function M.sequenceRules(...)
	return setmetatable({ parse=lbnfoper_funcs.seq, seq_rules={...} }, lbnfoper_mt)
end

function M.stringPattern(pattern)
	return setmetatable({ parse=lbnfoper_funcs.l, pattern=pattern }, lbnfoper_mt)
end


function M.optionalRule(optional_rule)
	return function(source, start, ctx)
		return optional_rule(source, start, ctx) or start
	end
end


-- function l(pattern)
-- 	return function(s, start, ctx)
-- 		local out, idx = s:match('^%s*'..pattern..'()', start)
-- 		if idx==nil then return out elseif out=='' then return idx end
-- 		return idx, out
-- 	end
-- end

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

return M
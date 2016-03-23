require'string_ext'

local M = {}


function M.combineRules(combined_rules)
	return function(source, start, pattern)
		local idx = start
		for _, rule in ipairs(combined_rules) do
			local idx, out = rule(source, start, ctx)
			if idx~=nil then return idx, out end
		end
	end
end

function M.repeatRule(repeated_rule)
	return function(source, start, pattern)
		local idx, out = start, {}
		::loop::
			local i, c = repeated_rule(source, idx, ctx)
			if not i then return idx, out end assert(i~=idx)
			idx = i; table.insert(out, c)
		goto loop
	end
end

function M.listRule(item, separator)
	return function(source, start, pattern)
		local idx, out = start, {}
		::loop::
			local i, c = item(source, idx, ctx)
			if i==nil then if idx==start then return else return idx, out end end
			idx = i; table.insert(out, c)
	
			local i, c = separator(source, idx, ctx)
			if i==nil then if #out==1 then return idx, out[1] end  return idx, out end 
			idx = i; table.insert(out, c)
	
		goto loop
	end
end

function M.sequenceRules(seq_rules, seq_names)
	local seq_names = seq_names or {}
	return function(source, start, ctx)
		local idx, out, ns_idx = start, { [0]=seq_names[0] }, 0
		for _, rule in ipairs(seq_rules) do
			local i, c = rule(source, idx, ctx)
			if i==nil then return end 
			if c~=nil then 
				ns_idx=ns_idx+1
				if seq_names[ns_idx] then out[seq_names[ns_idx]]=c else table.insert(out, c) end
			end 
			idx = i; 
		end
		return idx, out
	end
end



function M.stringPattern(pattern)
	return function(source, start, ctx)
		local out, idx = source:match('^%s*'..pattern..'()', start)
		if idx==nil then assert(type(out)=='number' or out==nil) return out end
		assert(type(idx)=='number' ) 
		return idx, out 
	end
end


function M.stringLiteral(literal)
	return function(source, start, ctx) return source:match('^%s*'..literal:esc_pattern()..'()', start) end
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
		local idx, out = rule(s, start, (ctx ))
		return idx, out
	end
end



return M
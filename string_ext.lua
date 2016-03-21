local function _gtok(str, rules, start, greedy_mode)
	local max_pos, max_capt, max_name, max_mdf = 1
	for k,v in pairs(rules) do
		local mdf, mdf_val, pttr, capt, ep
		if type(v)=='table' then
			ep, mdf, name, capt = _gtok(str, v, start, greedy_mode)
			if ep then table.insert(capt, ep) end
		else
			mdf, mdf_val, pttr = v:match"(%w*)(%d*):?(.+)"
			capt = { str:match('^'..pttr..'()', start) }
			ep = capt[#capt]
		end
		if ep then
			if greedy_mode and mdf~='finite' then
				if max_pos<ep then
					max_capt = capt; max_pos = ep; max_name = k; max_mdf = mdf;
				end
			else
				return ep, mdf, k, {table.unpack(capt, 1, #capt-1)}
			end
		end
	end
	if not greedy_mode or max_capt==nil then return end
	return max_pos, max_mdf, max_name, {table.unpack(max_capt, 1, #max_capt-1)}
end

function string.gtok(str, rules, start, greedy_mode)
	local start = start or 1
	local bp
	local greedy_mode = greedy_mode or true
	return function()
		::start_l::
		local ep, mdf, name, capt = _gtok(str, rules, start, greedy_mode)
		if ep then
			bp = start
			start = ep
			if mdf=='skip' then goto start_l end
			return name, bp, ep, table.unpack(capt)
		end
	end
end

do

	local rawsub = string.sub

	function string:sub(b, e)
		if e<=0 then e = #self + e end
		return rawsub(self, b, e)
	end

end

function string:esc_pattern()
	local res = self:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	return res
end


return string
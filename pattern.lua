local M = {}
--branchely

function M.select(enum)
	return function(src, idx)
		for _, v in ipairs(enum) do
			local i, r = v(src, idx)
			if i then return i, r end
		end
	end
end

function M.classify(rules)
	return function(src, idx)
		local k0, i0, r0, conflicted
		for k, v in pairs(rules) do
			local i, r = v(src, idx)
			if i~=nil and (i0==nil or i>=i0) then
				if i==i0 then conflicted=k else conflicted=false end
				k0=k; i0=i; r0=r;
			end
		end
		return i0, k0, r0, conflicted
	end
end


function M.gtok(rules, ctx, start)
	local idx = start or 1
	local ctx = ctx or {}
	return function()
		local k0, i0, r0
		for k, v in pairs(rules) do
			local i, r = v(src, idx, ctx)
			if i~=nil then
				if v.finite then k0=k; i0=i; r0=r; break; end
				if (i0==nil or i>=i0) then k0=k; i0=i; r0=r; end
			end
		end
		if
		idx = i0
		return k0, r0
	end
end






return string
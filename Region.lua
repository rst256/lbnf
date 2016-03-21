

local M = {}

local Region_op = {}
local Region_mt = { __index=Region_op }

function get_child(node, value)
		local childs = node.childs or rawset(node, 'childs', {}).childs
		return childs[value] or rawset(childs, value, {})[value]
end

function Region_op:add(value)
end


function Region_mt:__call(value)
	local node, node2 = self.childs
	for c, p, q in pattern:gmatch"(%%?)(.)([%+%*%-%?]?)" do
		if node==nil then return end
		node2 = node[c..p..q]
		if node2==nil then return end
		node = node2.childs
	end
	return node2.value
end



function Region_mt:__tostring()
	local s = ''
	for _, v in pairs(self) do
		s = s..tostring(v)..' '
	end
	return s
end

function M.Region(...)
	return setmetatable({ ... }, Region_mt)
end






return M
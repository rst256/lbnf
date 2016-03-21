local overload = require"overload";
local set=require"set"

local M = {}

local ADTree_op = {}
local ADTree_mt = { __index=ADTree_op }

function get_child(node, value)
	if node.childs==nil then return nil end
	return node.childs[value] or table.unpack{false, node.childs}
end

function add_child(node, value)
print(node, value)
		local node2, childs = get_child(node, value)
		if node2==nil then
			return rawset(node, 'childs', { [value]={} }).childs[value]--.childs
		elseif childs then return rawset(childs, value, {})[value]
		end
		-- if childs
		return nil --or rawset(childs, value, {})[value]
		-- local
		-- return childs[value] or rawset(childs, value, {})[value]
end

function ADTree_op.pattern_iter(pattern)
		return pattern:gmatch"(%%?)(.)([%+%*%-%?]?)"
end

function ADTree_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = add_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end
	-- 	if node.childs==nil then return k, node.value end
	-- 	local n = get_child(node, source:sub(k, k))
	-- 	local n = node.childs[source:sub(k, k)]
	-- 	if n==nil then return k-1, node.value end
	-- 	node = n
	-- end

function ADTree_op:find(source, start)
	local node = self
	for k=start or 1, #source do
		local n = get_child(node, source:sub(k, k))
		if not n then return k-1, node.value end
		node = n
	end
	return #source
end

function ADTree_mt:__call(pattern)
	local node, node2 = self.childs
	for c, p, q in self.pattern_iter(pattern) do
		if node==nil then return end
		node2 = node[c..p..q]
		if node2==nil then return end
		node = node2.childs
	end
	return node2.value
end

local function ADTree__tostring(self, step)
	local s = tostring(self.value or '')
	if self.childs==nil then return s end
	s = s..'\n'
	for k, v in pairs(self.childs) do
		s = s..string.rep(' ', step)..k..':'..ADTree__tostring(v, step+1)--..','
	end
	return s
end

function ADTree_mt:__tostring()
	return ADTree__tostring(self, 0)
end

function M.ADTree()
	return setmetatable({ childs={} }, ADTree_mt)
end




local ADTreeNode_op = {  }
local ADTreeNode_mt = { __index=ADTreeNode_op, __metatable='ADTreeNode' }


ADTreeNode_mt.__newindex = overload(rawset,	'table table table',
	function(self, key, value)
	print'dfdf'
		rawset(self, '__count', #self-1); rawset(self, key, value)
	end)

function ADTreeNode_mt:__len()	print'dfd66666f' return self.__count end


function ADTreeNode_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = add_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end

function M.ADTreeNode(opt)
	return setmetatable({ branches={}, __count=0 }, ADTreeNode_mt)
end


local ADTreeItem_op = {  }
local ADTreeItem_mt = { __index=ADTreeItem_op, __metatable='ADTreeItem' }


function ADTree_mt:__newindex(key, value)
	return ADTree__tostring(self, 0)
end

function ADTreeItem_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = add_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end

function M.ADTreeItem(opt)
	return setmetatable({ branches={} }, ADTreeItem)
end
--
--
-- loc set=require("set").new
-- local ADSet_op = {  }
-- local ADSet_mt = { __index=ADSet_op, __metatable='ADSet' }
--
--
-- function ADTree_mt:__newindex(key, value)
-- 	return ADTree__tostring(self, 0)
-- end
--
-- function ADSet_op:intersept(pattern, value)
-- 	local node = self
-- 	for c, p, q in self.pattern_iter(pattern) do
-- 		node = add_child(node, c..p..q)
-- 	end
-- 	if node.value~=nil then return false end
-- 	node.value = value
-- 	return true
-- end
--
-- function M.ADSet(opt)
-- 	return setmetatable({ branches={} }, ADSet)
-- end

return M
local types=import.s("types.callable").types.Attr

local M_mt = {}

function M_mt:__call(pattern)
	local node, node2 = self.childs
	for c, p, q in self.pattern_iter(pattern) do
		if node==nil then return end
		node2 = node[c..p..q]
		if node2==nil then return end
		node = node2.childs
	end
	return node2.value
end

local M = setmetatable({}, M_mt)


local PP_op = {}
local PP_mt = { __index=PP_op }

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

function PP_op.pattern_iter(pattern)
		return pattern:gmatch"(%%?)(.)([%+%*%-%?]?)"
end

function PP_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = add_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end


function PP_op:find(source, start)
	local node = self
	for k=start or 1, #source do
		local n = get_child(node, source:sub(k, k))
		if not n then return k-1, node.value end
		node = n
	end
	return #source
end

function PP_mt:__call(pattern)
	local node, node2 = self.childs
	for c, p, q in self.pattern_iter(pattern) do
		if node==nil then return end
		node2 = node[c..p..q]
		if node2==nil then return end
		node = node2.childs
	end
	return node2.value
end

local function PP__tostring(self, step)
	local s = tostring(self.value or '')
	if self.childs==nil then return s end
	s = s..'\n'
	for k, v in pairs(self.childs) do
		s = s..string.rep(' ', step)..k..':'..PP__tostring(v, step+1)--..','
	end
	return s
end

function PP_mt:__tostring()
	return PP__tostring(self, 0)
end

function M.PP()
	return setmetatable({ childs={} }, PP_mt)
end




local PPNode_op = {  }
local PPNode_mt = { __index=PPNode_op, __metatable='PPNode' }


PPNode_mt.__newindex = overload(rawset,	'table table table',
	function(self, key, value)
	print'dfdf'
		rawset(self, '__count', #self-1); rawset(self, key, value)
	end)

function PPNode_mt:__len()	print'dfd66666f' return self.__count end


function PPNode_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = add_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end

function M.PPNode(opt)
	return setmetatable({ branches={}, __count=0 }, PPNode_mt)
end


local PP_Item_op = {  }
local PP_Item_mt = { __index=PP_Item_op, __metatable='PP_Item' }


function PP_mt:__newindex(key, value)
	return PP__tostring(self, 0)
end

function PP_Item_op:add(pattern, value)
	local node = self
	for c, p, q in self.pattern_iter(pattern) do
		node = add_child(node, c..p..q)
	end
	if node.value~=nil then return false end
	node.value = value
	return true
end

function M.PP_Item(opt)
	return setmetatable({ branches={} }, PP_Item)
end
--
--
-- loc set=require("set").new
-- local ADSet_op = {  }
-- local ADSet_mt = { __index=ADSet_op, __metatable='ADSet' }
--
--
-- function PP_mt:__newindex(key, value)
-- 	return PP_tostring(self, 0)
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


local M_mt = {}

function M_mt:__index(name)
	return function(members)
		self[name] = members
		return self[name]
	end
end

function M_mt:__newindex(class_name, members)
	local new_class = { __metatable=tostring(class_name) }
	for k, v in pairs(members or {}) do
		local mt_name = self.mt_names[k]
		if mt_name~=nil then new_class[mt_name] = v end
	end

	if members.properties then
		local __index
		if type(new_class.__index)=='table' then
			local ___index = new_class.__index
			__index = function(self, name) return ___index[name] end
		else
			__index = new_class.__index or function() return end
		end
		local __newindex = new_class.__newindex or rawset

		new_class.__index = function(self, name)
			local prop = members.properties[name]
			if type(prop)=='function' then return prop(self)
			elseif type(prop)=='table' then
			if prop.get then return prop.get(self) else
				error('property "'..class_name..'.'..name..'" is write only', 2) end
			else return __index(self, name) end
		end

		new_class.__newindex = function(self, name, value)
			local prop = members.properties[name]
			if type(prop)=='function' then prop(self, value)
			elseif type(prop)=='table' then
				if prop.set then prop.set(self, value) else
					error('property "'..class_name..'.'..name..'" is read only', 2) end
			else __newindex(self, name, value) end
		end
	end

	if members.methods then
		local __index
		if type(new_class.__index)=='table' then
			local ___index = new_class.__index
			__index = function(self, name) return ___index[name] end
		elseif type(new_class.__index)=='function' then
			__index = new_class.__index
		else
			__index = function() end
		end
		new_class.__index = function(self, name)
			local raw_method = members.methods[name]
			if raw_method then
				local method = function(self2, ...)
					if self==self2 then
						return raw_method(self, ...)
					else
						return raw_method(self, self2, ...)
					end
				end
				rawset(self, name, method)
				return method
			else
				return __index(self, name)
			end
		end
	end

	if self.gen_tostring or new_class.__tostring~=nil then
		if type(new_class.__tostring)~='function' then
			local tostr = 'class<'..tostring(new_class.__tostring or class_name)..'>'
			new_class.__tostring = function(self) return tostr end
		end
	end

	self.__classes[class_name] = new_class
	rawset(self, class_name, function(...)
		local obj
		if members.ctx then obj = members.ctx(...) else obj = {...} end
		return setmetatable(obj, new_class)
	end)
end

local M = {
	__classes = {},
	__private = {},
	gen_tostring = false,
	mt_names = {
		index='__index', __index='__index',
		newindex='__newindex', __newindex='__newindex',
		call='__call', __call='__call', ['()']='__call',
		add='__add', __add='__add', ['+']='__add',
		sub='__sub', __sub='__sub', ['-']='__sub',
		tostring='__tostring', __tostring='__tostring', ['"']='__tostring',
		len='__len', __len='__len', ['#']='__len',
		pow='__pow', __pow='__pow', ['^']='__pow',
		shared='shared'
	}
}

return setmetatable(M, M_mt)


--class.gen_tostring=true

--class.stmnt = {
--	index = function(self, name) return name end,
--	methods = { p=print },
--	shared = { ps=error }
--}

--local list = class.list{
--	index = function(self, name) return name..'list' end,
--	ctx = function(...) return { opts={...} } end,
--	properties = {
--		count=function(self, v) if v then self[0]=v else return #self+6 end end,
--		first=666,
--		next={ set=print },
--		prev={ get=type, set=inspect }
--	},
--	tostring=false
--}

--local ast1 = M.ast{ x=0 }
--local stmnt1 = class.stmnt( 'stmnt1', 2 )
--local stmnt2 = class.stmnt{ 'stmnt2' }
--local list1 = class.list{ 'list1' }
--local list2 = list{ 'list2' }
--print(ast1[nil].opts.x, ast1.opts.x)
--inspect(stmnt1, stmnt1.ss)
--inspect(stmnt2)

--inspect(list1.kkk, list1.first)
--list2[1]=1
--inspect(list2, list2.count)
--list2.count=-666
--list2.first='first'
--list2.next='next'
--inspect(list2, list2.count)
--print(list2.prev)
--print(list2)
----list2.prev=9
----print(list2.next)
--stmnt2.p('stmnt2.p', 77)
--stmnt2:p('stmnt2:p', 88)
----return M
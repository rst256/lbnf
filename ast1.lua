local inspect=require'inspect'
require'table_ext'


local class = require'class'



local M = {}

local statement_member = class.statement_member{
	ctx=function(...)
		local s = {}
		for _, v in ipairs{...} do s[v] = true end
		return { members=s }
	end,
	methods = {
		add = function(self, ...) for _, v in ipairs{...} do self.members[v] = true end	end,
		check = function(self, v) return self.members[v] or false end,
		sync=function(self, asm)
			local smts = asm.statements
			--for k, v in pairs(self.members) do
			local k, v = next(self.members)
			while v do
				if type(k)=='string' and smts[k] then
					local k_tmp = k
					self.members[smts[k]] = true
					k, v = next(self.members, k)
					self.members[k_tmp] = nil
				else
					k, v = next(self.members, k)
				end

			end
		end,
	},
	index = {
		is_single = true, is_require = true
	},
	properties = {
		rep = { get = function(self) self.is_single=false; return self; end },
		opt = { get = function(self) self.is_require=false; return self; end },
	},
	tostring=function(self)
		local s = ''
		for k, v in pairs(self.members) do
			--if v then
				if type(k)=='string' then s = s..'<'.. k .. '>, ' else s = s..k.name .. ', ' end
			--end
		end
		s = ' '..s:gsub(', $', '')..' '
		if not self.is_require then s = '[' .. s .. ']' end
		if not self.is_single then s = '{' .. s .. '}' end
		return s
	end,
}

local statement = class.statement{
	ctx=function(asm, members, name)
		if type(members)~='table' then
			return { members= members , asm=asm, name=name }
		end
		local s = {}
		for k, v in pairs(members) do
			if type(v)=='string' then
				s[k] = statement_member(asm.statements[v] or v)
			elseif getmetatable(v)=='statement_member' then
				s[k] = v
			elseif type(v)=='table' then
				s[k] = statement_member(table.unpack(v))
			end
		end
		return { members=s, asm=asm, name=name }
	end,
	methods = {
		sync=function(self)
			if type(self.members)~='table' then return end
			local smts = self.asm.statements
			for k, v in pairs(self.members) do
				if type(v)=='string' and smts[v] then
					self.members[k] = statement_member(smts[v])
					self.members[k].sync(self.asm)
--v.sync(self.asm)
				elseif getmetatable(v)=='statement_member' then
					v.sync(self.asm)
					--self.members[k] = v
--				elseif type(v)=='table' then
--					self.members[k] = statement_member(v)
				end
			end
		end,
	},
	tostring=function(self)
		if type(self.members)~='table' then return '"'..tostring(self.members)..'"\n' end
		local s = '\n'
		for k, v in pairs(self.members) do
			if type(v)=='string' then
				s = s .. k .. ' = "' .. v .. '"\n'
			else
				s = s .. k .. ' = ' .. tostring(v) .. '\n'
			end
		end
		return s--:sub(1, #s-1)
	end,
}


M.asm = class.asm{
	ctx=function() return { root={}, statements={} } end,
	newindex = function(self, name, val)
		if getmetatable(val)=='statement' then
			val.name = name
			self.statements[name] = val
		elseif type(val)~='table' then
			self.statements[name] = val
		else
			self.statements[name] = statement(self, val, name)
		end
	end,
	methods = {
		sync=function(self)
			for _, v in pairs(self.statements) do if type(v)=='table' then v.sync() end end
		end,
	},
	tostring=function(self)
		local s = ''
		for k, v in pairs(self.statements) do
			local sv
			if type(v)=='table' then sv=tostring(v):gsub('\n','\n  ') else sv='"'..v..'"   ' end
			s = s .. k .. ' : ' .. sv:sub(1, #sv-3) .. '\n'
		end
		return s
	end,
}

a1=M.asm()


a1.typedef={
	typename='ret',
	typedef='typeexpr'
}
a1.ret={
	retval = statement_member('expr', 'value', 'ident').opt.rep
}
a1.call={
	func_name={'ident', 'expr'}, args=statement_member('expr').opt.rep
}
a1.ident='ident'
a1.value={
	value=statement_member('string', 'number', 'bool', 'nil')
}
--inspect(a1)
print(a1)
print'------------------------------------- sync -------------------------------------\n'
a1.sync()
print(a1)
--s1=statement_member('expr').opt.rep
--print(s1)
--print(s1, s1.may_ommit)
--s1.add('value', 'ident')
--inspect(s1)

--stat_return=statement(a1, {
--	retval = statement_member('expr', 'value', 'ident').opt.rep
--})
--inspect(stat_return)

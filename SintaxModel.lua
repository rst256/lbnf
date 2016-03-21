local inspect = require("inspect")

local M = {}




local Block_op = {}
local Block_mt = { __index=Block_op }

function Block_mt:__tostring()
	local s = ''
	for _, v in pairs(self) do
		s = s..tostring(v)..' '
	end
	return s
end

function M.Block(...)
	return setmetatable({ ... }, Block_mt)
end





local Struct_op = {}
local Struct_mt = { __index=Struct_op }

function Struct_mt:__tostring()
	local s = ''
	for _, v in pairs(self) do
		s = s..tostring(v)..' '
	end
	return s
end

function M.Struct(...)
	return setmetatable({ ... }, Struct_mt)
end




local Expr_op = {}
local Expr_mt = { __index=Expr_op }

function Expr_mt:__tostring()
	local s = ''
	for _, v in pairs(self) do
		s = s..tostring(v)..' '
	end
	return s
end

function M.Expr(...)
	return setmetatable({ ... }, Expr_mt)
end




local Word_op = {}
local Word_mt = { __index=Word_op }

function Word_mt:__tostring()
	local s = ''
	for _, v in pairs(self) do
		s = s..tostring(v)..' '
	end
	return s
end

function M.Word(...)
	return setmetatable({ ... }, Word_mt)
end


local inspect=require'inspect'

local config = {
	macros={ prefix='@' },
	block={ open='{', close='}' }
}

local M = {	config=config }

function M.get(...)
	return
end

return M



local M = {
	parent=false,
	childs={},
	synapse={},
	transfer_func = function(self, signal) return signal end,
	activation_func = function(self, signal) return signal end,
	__metatable='node',
}

local tree = {
	root={},
	__metatable='neuron',
}

local node = {
	axon=false,
	dendrites={},
	__metatable='neuron',
}

M.tree = 
(options)

function M.tree(options)
	local t = type(arg)
  if t=='userdata' or t=='table' then
  	return getmetatable(arg) or t
  else 
  	return t
  end
end

return M
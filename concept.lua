

local M = {}

function M.class(options)
	local t = type(arg)
  if t=='userdata' or t=='table' then
  	return getmetatable(arg) or t
  else
  	return t
  end
end

M.notion = M.cardinality{
	concretization
	duration
}

M.notion = M.class{
	concretization
	duration
}



function M.notion(options)

	local t = type(arg)
  if t=='userdata' or t=='table' then
  	return getmetatable(arg) or t
  else
  	return t
  end
end

function concept(options)
	local t = type(arg)
  if t=='userdata' or t=='table' then
  	return getmetatable(arg) or t
  else
  	return t
  end
end


function M.concept(options)
	local t = type(arg)
  if t=='userdata' or t=='table' then
  	return getmetatable(arg) or t
  else
  	return t
  end
end

return M
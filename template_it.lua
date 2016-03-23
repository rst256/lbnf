local template = require'template'
local t1=template.open(arg[1] or 'out.c')

-- file=io.open(arg[2] or 'out.lua', 'w+')
s=t1()

-- file:write(s)
io:write(s)
-- file:close()
-- os.execute[[cmd /c ""C:\Projects\Lua\cmodules\.Makefile.bat" 
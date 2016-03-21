local template = require'template'
local t1=template.open(arg[1])

file=io.open(arg[2], 'w+')
s=t1()

file:write(s)
file:close()
-- os.execute[[cmd /c ""C:\Projects\Lua\cmodules\.Makefile.bat" "C:\Projects\Lua\cmodules\luam_test_class.c" run "C:\Projects\Lua\cmodules" PauseOnError"]]
 ISO (we used mandriva-linux-one-2010-spring-KDE4-europe1-americas-cdrom-i586.iso)

 http://mirror.rosalab.ru/mandriva/official/iso/2010.1/mandriva-linux-one-2010-spring-KDE4-europe1-americas-cdrom-i586.iso


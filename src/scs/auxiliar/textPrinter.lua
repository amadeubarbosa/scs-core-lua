
local IDENT_NUM = 2

local printer = {}

----------------------------------------------------------------------------------

---
--
---
function printer:write(ident, t, value)
  local spaces = string.rep(" ", ident * IDENT_NUM)
  
  if t and t.type then    
    print(string.format("%s(%s) %s", spaces, t.type, value))
  else
    print(string.format("%s%s", spaces, value))
  end
end

---
--
---
function printer:flush()
  return
end


return printer
oil = require "oil"

-- OiL configuration
local orb = oil.init()

oil.main(function()
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/hello.idl")

  -- loading Hello
  local f = assert(io.open("hello.ior", "r"), "Error opening hello server's IOR file!")
  local ior = f:read("*all")
  f:close()

  local helloIComponent = orb:newproxy(ior, "synchronous", "IDL:scs/core/IComponent:1.0")

  local hello = helloIComponent:getFacetByName("Hello")
  hello = orb:narrow(hello)
  hello:sayHello()
  print("Hello said!")
end)

oil = require "oil"

-- caso o script não seja dispardo via console, é necessário capturar os argumentos
-- local arg = {...}

-- OiL configuration
local orb = oil.init()

oil.main(function()
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/pingPong.idl")

  -- loading PingPong 1
  local f = assert(io.open("pingpong" .. arg[1] .. ".ior", "r"), "Error opening PingPong " .. arg[1] .. " server's IOR file!")
  local ior = f:read("*all")
  f:close()

  local pp1IComponent = orb:newproxy(ior, "synchronous", "IDL:scs/core/IComponent:1.0")
  local pp1IReceptacles = pp1IComponent:getFacetByName("IReceptacles")
  pp1IReceptacles = orb:narrow(pp1IReceptacles)
  local pp1 = pp1IComponent:getFacetByName("PingPongServer")
  pp1 = orb:narrow(pp1)

  -- loading PingPong 2
  f = assert(io.open("pingpong" .. arg[2] .. ".ior", "r"), "Error opening PingPong " .. arg[2] .. " server's IOR file!")
  ior = f:read("*all")
  f:close()

  local pp2IComponent = orb:newproxy(ior, "synchronous", "IDL:scs/core/IComponent:1.0")
  local pp2IReceptacles = pp2IComponent:getFacetByName("IReceptacles")
  pp2IReceptacles = orb:narrow(pp2IReceptacles)
  local pp2 = pp2IComponent:getFacetByName("PingPongServer")
  pp2 = orb:narrow(pp2)

  -- connecting both
  pp1IReceptacles:connect("PingPongReceptacle", pp2)
  pp2IReceptacles:connect("PingPongReceptacle", pp1)

  -- calling startup on both
  pp1IComponent:startup()
  pp2IComponent:startup()

  -- calling start on one
  pp2:start()
end)

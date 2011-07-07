local oil = require "oil"
local ComponentContext = require "scs.core.ComponentContext"
local Log = require "scs.util.Log"
local utils  = require "scs.core.utils"
utils = utils()
Log:level(3)

-- OiL configuration
local orb = oil.init()

oil.main(function()
  -- starts to wait for remote calls
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/pingPong.idl")
  oil.newthread(orb.run, orb)

  -- assembles the component
  dofile("PingPong.lua")
  local componentId = { name = "PingPongServer", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "lua" }
  local ppInst = ComponentContext(orb, componentId)
  ppInst:addFacet("PingPongServer", "IDL:scs/demos/pingpong/PingPongServer:1.0", PingPongServer())
  ppInst:updateFacet("IComponent", PingPongIComponent())
  ppInst:addReceptacle("PingPongReceptacle", "IDL:scs/demos/pingpong/PingPongServer:1.0", false)

  -- initialization
  ppInst.utils = utils
  ppInst.utils.verbose = true

  -- argument treatment
  local pingPong = ppInst.PingPongServer
  pingPong.id = tonumber(arg[1]) or pingPong.id

  -- publishes the IComponent facet's IOR to a file. We could publish any facet,
  -- since the _component() exists to obtain the IComponent facet, and any 
  -- other facet from it. This step can also be replaced by other methods of
  -- publishing, like a name server.
  oil.writeto("pingpong" .. pingPong.id .. ".ior", orb:tostring(ppInst.IComponent))
  Log:info("Component PingPongServer " .. pingPong.id .. " was started successfully.")
end)


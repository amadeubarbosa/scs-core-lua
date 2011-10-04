local oil = require "oil"
local ComponentContext = require "scs.core.ComponentContext"
local Log = require "scs.util.Log"
Log:level(1)

-- OiL configuration
local orb = oil.init()

oil.main(function()
  -- starts to wait for remote calls
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/hello.idl")
  oil.newthread(orb.run, orb)

  -- assembles the component
  dofile("Hello.lua")
  local componentId = { name = "Hello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local instance = ComponentContext(orb, componentId)
  instance:addFacet("Hello", "IDL:scs/demos/helloworld/Hello:1.0", Hello())

  instance.Hello.name = arg[1] or instance.Hello.name

  -- publishes the IComponent facet's IOR to a file. We could publish any facet,
  -- since the _component() exists to obtain the IComponent facet, and any 
  -- other facet from it. This step can also be replaced by other methods of
  -- publishing, like a name server.
  oil.writeto("hello.ior", tostring(instance.IComponent))
  Log:info("Component Hello was started successfully.")
end)


local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local CoreComponentContext = require "scs.core.ComponentContext"

local utils = require "scs.composite.Utils"
utils = utils()

-- OiL configuration
local orb = oil.init({host = "localhost", port = 2610, localrefs = "proxy"})
local helloFacetInterface = "IDL:scs/demos/helloworld/Hello:1.0"

oil.main(function()
	local idlPath = os.getenv("IDL_PATH")
  orb:loadidlfile(idlPath .. "/scs.idl")
  orb:loadidlfile(idlPath .. "/composite.idl")
  oil.newthread(orb.run, orb)

  -- Cria dois componentes Hello 
  local keys = { IComponent = "CompositeComponent2" }
  local componentId = { name = "CompositeComponent2", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local comp1 = ComponentContext(orb, componentId, keys)
    
  local keys = { IComponent = "CoreComponent" }
  componentId = { name = "CoreComponent", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local comp2 = CoreComponentContext(orb, componentId, keys)
end)

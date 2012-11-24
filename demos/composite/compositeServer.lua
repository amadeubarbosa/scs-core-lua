local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local Log = require "scs.util.Log"

local utils = require "scs.composite.Utils"
utils = utils()

Log:level(5)

-- OiL configuration
local orb = oil.init()
local helloFacetName = "Hello"
local helloFacetInterface = "IDL:scs/demos/helloworld/Hello:1.0"

oil.main(function()
	local idlPath = os.getenv("IDL_PATH")
  orb:loadidlfile(idlPath .. "/scs.idl")
  orb:loadidlfile(idlPath .. "/hello.idl")
  orb:loadidlfile(idlPath .. "/composite.idl")
  oil.newthread(orb.run, orb)

	-- Cria dois componentes Hello
	dofile("subComponets.lua")	
  local componentId = { name = helloFacetName, major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent1 = ComponentContext(orb, componentId)
  helloComponent1:addFacet(helloFacetName, helloFacetInterface, Hello("SubComponent One"))

  
  local componentId = { name = helloFacetName, major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent2 = ComponentContext(orb, componentId)
  helloComponent2:addFacet(helloFacetName, helloFacetInterface, Hello("SubComponent Two"))

	-- Cria o componente composto
	local componentId = { name = "ComplexHello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
	local component = ComponentContext(orb, componentId)
	local icontentController = component:getFacetByName(utils.ICONTENTCONTROLLER_NAME).facet_ref
	
	-- Adiciona os componentes Hello no Componente Composto e cria uma faceta.
	local membershipID1 = icontentController:addSubComponent(helloComponent1:getIComponent())
	local membershipID2 = icontentController:addSubComponent(helloComponent2:getIComponent())
	
	local internalFacetList = {
			{id = membershipID1, name = helloFacetName},
			{id = membershipID2, name = helloFacetName}
			}
	icontentController:bindFacet(internalFacetList, helloFacetInterface)
		
  -- publishes the IComponent facet's IOR to a file. We could publish any facet,
  -- since the _component() exists to obtain the IComponent facet, and any 
  -- other facet from it. This step can also be replaced by other methods of
  -- publishing, like a name server.
  oil.writeto("server.ior", tostring(component:getIComponent()))
  Log:info("ComplexHello iniciado com sucesso.")
end)

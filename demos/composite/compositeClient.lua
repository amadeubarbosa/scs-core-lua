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

	--Getting proxy to primitive component
	local primitiveComponentIOR = oil.readfrom("server.ior")
	local primitiveComponent = orb:newproxy(primitiveComponentIOR)

	--Getting proxy to composite component
	local contentControllerIOR = oil.readfrom("content_controller.ior")
	local contentControllerComponent = orb:newproxy(contentControllerIOR)
	contentControllerComponent = orb:narrow(contentControllerComponent,"IDL:scs/core/IComponent:1.0")

	primitiveComponent:startup()
	contentControllerComponent:startup()

	if primitiveComponent then
	
		scOfPrimitive = primitiveComponent:getFacetByName("ISuperComponent")
		scOfPrimitive = orb:narrow(scOfPrimitive,"IDL:scs/core/ISuperComponent:1.0")
		
		print(scOfPrimitive:getSuperComponents())
		local compositeFacet  = contentControllerComponent:getFacetByName("IContentController")
		compositeFacet = orb:narrow(compositeFacet,"IDL:scs/core/IContentController:1.0")
	
		print('Composite component id: '..compositeFacet:getId())
		print(compositeFacet:addSubComponent(primitiveComponent))
		print(compositeFacet:findComponent(0))
		
		--[[
			compositeFacet:unbindFacet(0)
			print(compositeFacet:removeSubComponent(0))
		]]
		print(compositeFacet:bindFacet(0,'IHello','IExternalHello'))
		
		local exposeFacet = contentControllerComponent:getFacetByName('IExternalHello')
		exposeFacet = orb:narrow(exposeFacet,"IDL:scs/demos/helloworld/IHello:1.0")
		
		if exposeFacet then
			exposeFacet:sayHello('Teste')
		end
		
	end

end)


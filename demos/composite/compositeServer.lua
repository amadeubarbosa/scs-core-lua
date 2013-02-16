local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local Log = require "scs.util.Log"
local oo = require "loop.base"

local utils = require "scs.composite.Utils"
utils = utils()

Log:level(5)

-- Implementação da faceta IHello
local Hello = oo.class{}
function Hello:__new(name)
  return oo.rawnew(self,{name = name})
end
function Hello:sayHello()
  print("Hello " .. self.name .. "!")
end

-- Conector da faceta Hello
local HelloConnector = oo.class()

function HelloConnector:__new(helloFacets)
  return oo.rawnew(self,{facets = helloFacets})
end

function HelloConnector:sayHello()
  local orb = self.context._orb
  for _,facet in ipairs(self.facets) do
    facet = orb:narrow(facet, helloFacetInterface)
    facet:sayHello()
  end
end

-- OiL configuration
local orb = oil.init({localrefs = "proxy"})
local helloFacetInterface = "IDL:scs/demos/helloworld/Hello:1.0"

oil.main(function()
  local idlPath = os.getenv("IDL_PATH")
  orb:loadidlfile(idlPath .. "/scs.idl")
  orb:loadidlfile(idlPath .. "/composite.idl")
  orb:loadidlfile(idlPath .. "/hello.idl")
  oil.newthread(orb.run, orb)

  -- Cria dois componentes Hello e o conector
  local componentId = { name = "Hello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent1 = ComponentContext(orb, componentId)
  helloComponent1:addFacet("IHello1", helloFacetInterface, Hello("SubComponent One"))

  componentId = { name = "Hello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent2 = ComponentContext(orb, componentId)
  helloComponent2:addFacet("IHello2", helloFacetInterface, Hello("SubComponent Two"))

  local helloFacets = {}
  table.insert(helloFacets, helloComponent1:getIComponent():getFacetByName("IHello1"))
  table.insert(helloFacets, helloComponent2:getIComponent():getFacetByName("IHello2"))

  componentId = { name = "HelloConnector", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloConnector = ComponentContext(orb, componentId)
  helloConnector:addFacet("IHello", helloFacetInterface, HelloConnector(helloFacets))

  -- Cria o componente composto
  local componentId = { name = "ComplexHello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local component = ComponentContext(orb, componentId)
  local icontentController = component:getFacetByName(utils.ICONTENTCONTROLLER_NAME).facet_ref

  -- Adiciona os componentes Hello no Componente Composto e cria uma faceta.
  local membershipID1 = icontentController:addSubComponent(helloComponent1:getIComponent())
  local membershipID2 = icontentController:addSubComponent(helloComponent2:getIComponent())
  local membershipID3 = icontentController:addSubComponent(helloConnector:getIComponent())

  icontentController:bindFacet(membershipID3, "IHello", "IHelloX")

  -- publishes the IComponent facet's IOR to a file. We could publish any facet,
  -- since the _component() exists to obtain the IComponent facet, and any
  -- other facet from it. This step can also be replaced by other methods of
  -- publishing, like a name server.
  oil.writeto("server.ior", tostring(component:getIComponent()))
  Log:info("ComplexHello iniciado com sucesso.")
end)

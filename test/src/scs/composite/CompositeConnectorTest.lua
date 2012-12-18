local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local Log = require "scs.util.Log"
local oo = require "loop.base"

local utils = require "scs.composite.Utils"
utils = utils()

Log:level(4)

local receptacleName = "HelloReceptacle"

--implementação da faceta IHello
local Hello = oo.class{}
function Hello:__new(name)
	return oo.rawnew(self,{name = name})
end
function Hello:sayHello()
	print("Hello " .. self.name .. "!")
end

--implementação do conector IHello
local ConnectorHello = oo.class{}
function ConnectorHello:__new()
	return oo.rawnew(self,{})
end
function ConnectorHello:sayHello()
  local receptacle =  self.context:getReceptacleByName(receptacleName)
  if receptacle == nil then return end
  
  for _,connection in pairs(receptacle.connections) do
    connection.objref:sayHello()
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

  -- Cria dois componentes Hello  
  local componentId = { name = "Hello1", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent1 = ComponentContext(orb, componentId)
  helloComponent1:addFacet("IHello1", helloFacetInterface, Hello("SubComponent One"))	
  
  local componentId = { name = "Hello2", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent2 = ComponentContext(orb, componentId)
  helloComponent2:addFacet("IHello2", helloFacetInterface, Hello("SubComponent Two"))

  -- Cria o conector
  local componentId = { name = "Hello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloConnector = ComponentContext(orb, componentId)
  helloConnector:addFacet("IHello", helloFacetInterface, ConnectorHello())
  helloConnector:addReceptacle(receptacleName, helloFacetInterface, true)

	-- Cria o componente composto
	local componentId = { name = "ComplexHello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
	local component = ComponentContext(orb, componentId)
	local icontentController = component:getFacetByName(utils.ICONTENTCONTROLLER_NAME).facet_ref

  -- Adiciona o conector
  local membershipIDConnector = icontentController:addSubComponent(helloConnector:getIComponent())
  
  -- Verifica se um objeto fora do Componente Composto pode conectar em um componente de dentro do componente composto.
	-- TODO: !!!
  
  
	-- Adiciona os componentes Hello no Componente Composto e cria uma faceta.
	local membershipID1 = icontentController:addSubComponent(helloComponent1:getIComponent())
	local membershipID2 = icontentController:addSubComponent(helloComponent2:getIComponent())
	
  -- Conectar os subcomponentes no Conector.
  local helloReceptacle = helloConnector:getFacetByName(utils.IRECEPTACLES_NAME)  
  helloReceptacle = orb:narrow(helloReceptacle.facet_ref, utils.IRECEPTACLES_INTERFACE) 
  helloReceptacle:connect(receptacleName, helloComponent1:getFacetByName("IHello1").facet_ref)
  helloReceptacle:connect(receptacleName, helloComponent2:getFacetByName("IHello2").facet_ref)
  
	-- Verificando que o componentes foram criados
	local membershipDescription = icontentController:getSubComponents()
	for _, desc in pairs(membershipDescription) do 
		local iComponent = orb:narrow(desc.iComponent, utils.ICOMPONENT_INTERFACE)
		print(string.format("  MembershipID = %s | ComponentID.Name = %s", desc.id, iComponent:getComponentId().name))
	end
  
	local bindingID = icontentController:bindConnectorFacet(membershipIDConnector, "IHello", "IHelloX")
  
  print("Testa se o conector está funcionando corretamente.")
  local connectorFacet = component:getFacetByName("IHelloX").facet_ref
  connectorFacet = orb:narrow(connectorFacet, helloFacetInterface)
  connectorFacet:sayHello()
  
  print "\nRemovendo o Conector"
  local facetList = component.IMetaInterface:getFacets()
  local ok = icontentController:unbindFacet(bindingID)
  local facetList2 = component.IMetaInterface:getFacets()
  if ok and (#facetList ~= #facetList2) then
    print("** Conector removido.")
  else
    print("** Conector não removido.")
  end
  
  Log:info("Teste realizado com Sucesso.")
  os.exit(0)
end)

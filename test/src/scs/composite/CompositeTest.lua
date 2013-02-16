local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local Log = require "scs.util.Log"
local oo = require "loop.base"
local Idl = require "scs.composite.Idl"
local CoreComponentContext = require "scs.core.ComponentContext"


local utils = require "scs.composite.Utils"
utils = utils()

Log:level(4)


--implementação da faceta IHello
local Hello = oo.class{}
function Hello:__new(name)
  return oo.rawnew(self,{name = name})
end
function Hello:sayHello()
  print("Hello " .. self.name .. "!")
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

  --- Cria quatro componentes Hello
  -- Component1 e Component2 = Componente Hello normal
  -- Component3 = Componente Hello com um Receptáculo
  -- Componnet4 = Componente do SCS-Core
  local componentId = { name = "Hello1", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent1 = ComponentContext(orb, componentId)
  helloComponent1:addFacet("IHello1", helloFacetInterface, Hello("SubComponent One"))

  componentId = { name = "Hello2", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent2 = ComponentContext(orb, componentId)
  helloComponent2:addFacet("IHello2", helloFacetInterface, Hello("SubComponent Two"))

  componentId = { name = "Hello3", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent3 = ComponentContext(orb, componentId)
  helloComponent3:addFacet("IHello3", helloFacetInterface, Hello("SubComponent Three"))
  helloComponent3:addReceptacle("HelloReceptacle", helloFacetInterface, true)

  componentId = { name = "Hello4", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local helloComponent4 = CoreComponentContext(orb, componentId)
  helloComponent4:addFacet("IHello4", helloFacetInterface, Hello("SubComponent Three"))

  -- Cria dois componentes compostos
  componentId = { name = "ComplexHello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local component = ComponentContext(orb, componentId)
  local icontentController = component:getFacetByName(utils.ICONTENTCONTROLLER_NAME).facet_ref

  componentId = { name = "ComplexHello2", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local component2 = ComponentContext(orb, componentId)
  local icontentController2 = component:getFacetByName(utils.ICONTENTCONTROLLER_NAME).facet_ref

  -- Adiciona os componentes Hello no Componente Composto e cria uma faceta.
  local membershipID1 = icontentController:addSubComponent(helloComponent1:getIComponent())
  local membershipID2 = icontentController:addSubComponent(helloComponent2:getIComponent())
  local membershipID3 = icontentController:addSubComponent(helloComponent3:getIComponent())

  -- Tenta adicionar um componente do SCS-Core no Componente Composto
  local ok, errorMsg = pcall(icontentController.addSubComponent, icontentController, helloComponent4:getIComponent())
  if ok then
    error("Operacao nao permitida. Excecao deveria ser sido lancada.")
  elseif errorMsg._repid ~= idl.throw.InvalidComponent then
    error("Excecao deveria ser ".. idl.throw.InvalidComponent .. " e foi " .. errorMsg._repid)
  end

  -- Tenta adicionar compartilhar um subcomponente que possui receptáculos
  ok, errorMsg = pcall(icontentController.addSubComponent, icontentController, helloComponent3:getIComponent())
  if ok then
    error("Operacao nao permitida. Excecao deveria ser sido lancada")
  elseif errorMsg._repid ~= idl.throw.UnshareableComponent then
    error("Excecao deveria ser ".. idl.throw.UnshareableComponent .. " e foi " .. errorMsg_repid)
  end

  -- Verifica se o componentes foram criados
  local membershipDescription = icontentController:getSubComponents()
  for _, desc in pairs(membershipDescription) do
    local iComponent = orb:narrow(desc.iComponent, utils.ICOMPONENT_INTERFACE)
    print(string.format("  MembershipID = %s | ComponentID.Name = %s", desc.id, iComponent:getComponentId().name))
  end

  print "\nProcura o componente Adicionado"
  local iComponent = icontentController:findComponent(membershipID2)
  print(utils:getNameVersion(iComponent:getComponentId()))

  local internalFacetList = {
      {id = membershipID1, name = "IHello1"},
      {id = membershipID2, name = "IHello2"}
      }
  local bindingID = icontentController:bindFacet(internalFacetList, utils.replication,  "IHelloX")

  print "\nVerifica se o superComponente foi adicionado"
  local superCompList = helloComponent2.ISuperComponent:getSuperComponents()
  print(string.format("O componente '%s' possui os seguintes superComponentes:",
      utils:getNameVersion(helloComponent2:getComponentId())))

  for _,superComp in ipairs(superCompList) do
    superComp = orb:narrow(superComp, utils.ICOMPONENT_INTERFACE)
    print("  " .. utils:getNameVersion(superComp:getComponentId()))
  end

  print "\nRecupera todos os SubComponentes"
  local subComponents = icontentController:getSubComponents()
  for _, membershipDesc in pairs(membershipDescription) do
    print(membershipDesc.id, utils:getNameVersion(membershipDesc.iComponent:getComponentId()))
  end

  print "\Remove o Subcomponente"
  local ok = icontentController:removeSubComponent(membershipID2)
  print("Removido? ", ok)

  print "\Remove o Conector"
  local facetList = component.IMetaInterface:getFacets()
  local ok = icontentController:unbind(bindingID)
  local facetList2 = component.IMetaInterface:getFacets()
  if ok and (#facetList ~= #facetList2) then
    print("** Conector removido.")
  else
    print("** Conector não removido.")
  end

  Log:info("Teste realizado com Sucesso.")
  os.exit(0)
end)

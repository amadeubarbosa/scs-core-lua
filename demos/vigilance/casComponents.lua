--[[----------------------------------------------------------------------------
    O demo que cria um componente composto que representa uma casa, que possui
  duas facetas. Uma faceta que controla as cameras fora da casa e cameras internas.
  
----------------------------------------------------------------------]]

local oo = require "loop.simple"
local class = oo.class

local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local scsLog = require "scs.util.Log"

oil.verbose:level(0)
scsLog:level(3)

------------------------------------------------------------------------
-- 1. Implementacao da faceta
------------------------------------------------------------------------

-- Facetas do Componente SpeedCar
local IRecord = class()
function IRecord:__new(name) return oo.rawnew(self, {name = name}) end

function IRecord:record()
  print("[" .. self.name .. "] Start record")
end

function IRecord:stop()
  print("[" .. self.name .. "] Stop record")
end

------------------------------------------------------------------------
-- 2. Implementacao do conector
------------------------------------------------------------------------

local IRecordConnector = class()
function IRecordConnector:call(facetName, facetInterface, functionName)
  local context = self.context
  local orb = context._orb

  local returnList = {}

  receptacle = context:getReceptacleByName(facetName)
  for _,facet in pairs(receptacle.connections) do
    facet = orb:narrow(facet.objref, facetInterface)
    local ok, returnValue = pcall(facet[functionName], facet)
    table.insert(returnList, returnValue)
  end

  return returnList
end

function IRecordConnector:record()
  self:call("IRecord","IDL:IRecord:1.0", "record")
end

function IRecordConnector:stop()
  self:call("IRecord","IDL:IRecord:1.0", "stop")
end

------------------------------------------------------------------------
-- 3. Funcoes auxiliares
------------------------------------------------------------------------

function CreateCamera(orb, name)
  local componentId = { name = "Camera", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local cameraComponent = ComponentContext(orb, componentId)
  cameraComponent:addFacet("IRecord", "IDL:IRecord:1.0", IRecord(name))
  
  return cameraComponent.IComponent
end

------------------------------------------------------------------------
-- 4. Main
------------------------------------------------------------------------

local orb = oil.init({localrefs = "proxy"})

oil.main(function()
  local idlPath = os.getenv("IDL_PATH")
  orb:loadidlfile(idlPath .. "/scs.idl")
  orb:loadidlfile(idlPath .. "/composite.idl")
  orb:loadidlfile("idl/recorder.idl")

  oil.newthread(orb.run, orb)

  ---- 4.1 Criar a casa
  local houseComptId = { name = "Casa", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local houseComponent = ComponentContext(orb, houseComptId)

  local houseIComponent = houseComponent:getFacetByName("IComponent").facet_ref
  houseIComponent = orb:narrow(houseIComponent, "IDL:scs/core/IComponent:1.0")
  
---- 4.2 Criar 2 cameras internas e 2 cameras externas à casa
  local cameraEx1 = CreateCamera(orb, "Cam Externa 1")
  local cameraEx2 = CreateCamera(orb, "Cam Externa 2")
  local cameraEx3 = CreateCamera(orb, "Cam Externa 3")
  local cameraIn1 = CreateCamera(orb, "Cam Interna 1")
  local cameraIn2 = CreateCamera(orb, "Cam Interna 2")

---- 4.3 Criar dois conectores
  local connectorComptId = { name = "RecordConnector", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local conectorExterno = ComponentContext(orb, connectorComptId)
  conectorExterno:addFacet("IRecord", "IDL:IRecord:1.0", IRecordConnector())
  conectorExterno:addReceptacle("IRecord", "IDL:IRecord:1.0", true)
  
  local conectorInterno = ComponentContext(orb, connectorComptId)
  conectorInterno:addFacet("IRecord", "IDL:IRecord:1.0", IRecordConnector())
  conectorInterno:addReceptacle("IRecord", "IDL:IRecord:1.0", true)
  
---- 4.4 Adicionar o componentes na casa
  local houseContentController = houseIComponent:getFacetByName("IContentController")
  houseContentController = orb:narrow(houseContentController, "IDL:scs/composite/IContentController:1.0")
  houseContentController:addSubComponent(cameraEx1)
  houseContentController:addSubComponent(cameraEx2)
  houseContentController:addSubComponent(cameraEx3)  
  houseContentController:addSubComponent(cameraIn1)
  houseContentController:addSubComponent(cameraIn2)
  local connExId = houseContentController:addSubComponent(conectorExterno.IComponent)
  local connInId = houseContentController:addSubComponent(conectorInterno.IComponent)
  
---- 4.5 Conecta as cameras nos conecteores
  local receptacle = conectorExterno.IReceptacles
  receptacle = orb:narrow(receptacle, "IDL:scs/core/IReceptacles:1.0")
  local recordFacet = orb:narrow(cameraEx1:getFacetByName("IRecord"), "IDL:IRecord:1.0")
  receptacle:connect("IRecord", recordFacet)  
  recordFacet = orb:narrow(cameraEx2:getFacetByName("IRecord"), "IDL:IRecord:1.0")
  receptacle:connect("IRecord", recordFacet)
  recordFacet = orb:narrow(cameraEx3:getFacetByName("IRecord"), "IDL:IRecord:1.0")
  receptacle:connect("IRecord", recordFacet)
  
  local receptacle = conectorInterno.IReceptacles
  receptacle = orb:narrow(receptacle, "IDL:scs/core/IReceptacles:1.0")
  recordFacet = orb:narrow(cameraIn1:getFacetByName("IRecord"), "IDL:IRecord:1.0")
  receptacle:connect("IRecord", recordFacet)  
  recordFacet = orb:narrow(cameraIn2:getFacetByName("IRecord"), "IDL:IRecord:1.0")
  receptacle:connect("IRecord", recordFacet)
  
---- 4.6 Faz o bind das Facetas dos conectores
  houseContentController:bindFacet(connExId, "IRecord", "IRecordEx")
  houseContentController:bindFacet(connInId, "IRecord", "IRecordIn")

  
---- 4.7 Inicia a gravação das cameras externas, para a gravação das cameras externas e inicia a gravação das cameras internas
  local externalCameras = houseIComponent:getFacetByName("IRecordEx")
  externalCameras = orb:narrow(externalCameras, "IDL:IRecord:1.0")
  local internalCameras = houseIComponent:getFacetByName("IRecordIn")
  internalCameras = orb:narrow(internalCameras, "IDL:IRecord:1.0")
  
  externalCameras:record()
  externalCameras:stop()
  internalCameras:record()
  
end)

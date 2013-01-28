--[[----------------------------------------------------------------------------
  Demo que reflete a interacao entre os componentes Room, RoomConfigurator
  e SpeedCars. Mais informacoes sobre a arquitetura podem ser encontrados no
  documentos no site do projeto [1]. Todas as interfaces utilizadas nessa demo
  sao originarias do projeto CAS versao 2.0, sem nenhuma alteracao.

  Atualmente o CAS utiliza o Openbus para conectar diferentes componentes, como
  por exemplo o componente Room ao componente RoomConfigurator. Como o
  objetivo desta demo nao e replicar toda a infraestrutura necessaria para
  executar o CAS, a demo ira remover a necessidade do Openbus. Desta forma sera
  necessario que o componente RoomConfigurator crie o componente Room.

  O demo sera dividido da seguinte forma:
    1. Implementacao das facetas dos componentes Room, SpeedCar e
  RoomConfigurator.
    2. Implementacao dos conectores que serao utilizados no componente
    composto Room
    3. Funções auxiliares
    4. Execucao do demo
      4.1 Criar os componentes RoomConfigurator e Room
      4.2 RoomConfigurator encontra o Room e o configura
      4.3 Simula o painel de controles recebendo informacoes sobre o componente Room e os SpeedCars
      4.4 Criar dois SpeedCars
      4.5 SpeedCars encontram o RoomConfigurator específico e pedem para serem adicionados no Room
      4.6 Verificar se os SpeedCars estao no estado 'ready'
      4.7 Iniciar Gravacao
      4.8 Verificar se os SpeedCars estao no estado 'recording'

  [1] https://jira.tecgraf.puc-rio.br/confluence/display/CASPUB/Capture+and+Access+System
----------------------------------------------------------------------]]


--- Componentes Dummy do CAS

local oo = require "loop.simple"
local class = oo.class

local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"

------------------------------------------------------------------------
-- 1. Implementacao das facetas
------------------------------------------------------------------------

-- Facetas do Componente SpeedCar
local IRecord = class()
function IRecord:getStatus() return self.state or "ready" end
function IRecord:startRecord()
  print "[SpeedCar] Recording"
  self.state = "recording"
end

local IConfigurable =  class()

local IDataTransfer = class()

local IActivitiesListener = class()
IActivitiesListener.connected  = function(self, name)
  return string.format("O SpeedCar %s foi conectado com sucesso.", name)
end
IActivitiesListener.disconnected  = function(self, name)
 return string.format("O SpeedCar %s foi desconectado com sucesso.", name)
end

-- Faceta do Componente Room
local IRoom = class()
function IRoom:__new(name) return oo.rawnew(self,{name = name}) end
function IRoom:getName() return self.name end
function IRoom:getStatus() return "True" end


-- Faceta do Componente Room Configurator
local IRoomConfigurator = class()
function IRoomConfigurator:__new()
  return oo.rawnew(self,{room = roomIComponent, membershipIdMap = membershipIdMap})
end
function IRoomConfigurator:connectComponent(speedCarComponent)
  local context = self.context
  local orb = context._orb
  local connectorsIdMap = context.membershipIdMap

  local contentController = context.room:getFacetByName("IContentController")
  contentController:addSubComponent(speedCarComponent)

  -- Conectar a faceta do Speedcar no conector IRecord
  local scRecord = speedCarComponent:getFacetByName("IRecord")
  local recordConn = contentController:findComponent(connectorsIdMap.IRecord)
  recordReceptacles = recordConn:getFacetByName("IReceptacles")
  recordReceptacles = orb:narrow(recordReceptacles, "IDL:scs/core/IReceptacles:1.0")
  recordReceptacles:connect("IRecord", scRecord)

  -- Conectar a faceta do Speedcar no conector IConfigurable
  local scConfigurable = speedCarComponent:getFacetByName("IConfigurable")
  local confConn = contentController:findComponent(connectorsIdMap.IConfigurable)
  confReceptacles = confConn:getFacetByName("IReceptacles")
  confReceptacles = orb:narrow(confReceptacles, "IDL:scs/core/IReceptacles:1.0")
  confReceptacles:connect("IConfigurable", scConfigurable)

  -- Conectar a faceta do Speedcar no conector IDataTransfer
  local scDataTransf = speedCarComponent:getFacetByName("IDataTransfer")
  local dataTransfConn = contentController:findComponent(connectorsIdMap.IDataTransfer)
  dataTransfReceptacles = dataTransfConn:getFacetByName("IReceptacles")
  dataTransfReceptacles = orb:narrow(dataTransfReceptacles, "IDL:scs/core/IReceptacles:1.0")
  dataTransfReceptacles:connect("IDataTransfer", scDataTransf)

  -- Conectar a faceta do Speedcar no conector IActivitiesListener
  local scChecker = speedCarComponent:getFacetByName("IActivitiesListener")
  local checkerConn = contentController:findComponent(connectorsIdMap.IActivitiesListener)
  checkerReceptacles = checkerConn:getFacetByName("IReceptacles")
  checkerReceptacles = orb:narrow(checkerReceptacles, "IDL:scs/core/IReceptacles:1.0")
  checkerReceptacles:connect("IActivitiesListener", scChecker)
end

------------------------------------------------------------------------
-- 2. Implementacao dos conectores
------------------------------------------------------------------------

-- Connector IReceptacles
--local IRecepaclesConn =


-- Conectores do Room
local IRecordConnector = class()
function IRecordConnector:call(facetName,facetInterface, functionName)
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

function IRecordConnector:startRecord()
  self:call("IRecord","IDL:cas/recorder/IRecord:1.0", "startRecord")
end
function IRecordConnector:getStatus()
  local mainStatus = "ready"
  statusList = self:call("IRecord","IDL:cas/recorder/IRecord:1.0", "getStatus")

  for _,status in pairs(statusList) do
    if mainStatus ~= status then
      mainStatus = status
    end
  end

  return mainStatus
end

local IConfigurableConnector =  class()

local IDataTransferConnector = class()

local IComponentCheckerConnector = class()

------------------------------------------------------------------------
-- 3. Funcoes auxiliares
------------------------------------------------------------------------

function findSpeedCarRoom()
  return roomConfiguratorComponent.IComponent
end

function CreateRoom(orb)
  local componentId = { name = "Room", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local roomComponent = ComponentContext(orb, componentId)
  roomComponent:addFacet("IRoom", "IDL:cas/room/IRoom:1.0", IRoom("Show HSBC"))
  return roomComponent.IComponent
end

function AddConectors(orb, roomIContent)
  membershipIdMap = {}

  -- Record Connector
  local connectorCompId = { name = "RecordConnector", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local recordConnComponent = ComponentContext(orb, connectorCompId)
  recordConnComponent:addFacet("IRecord", "IDL:cas/recorder/IRecord:1.0", IRecordConnector())
  recordConnComponent:addReceptacle("IRecord", "IDL:cas/recorder/IRecord:1.0", true)
  membershipIdMap.IRecord = roomIContent:addSubComponent(recordConnComponent.IComponent)
  roomIContent:bindConnectorFacet(membershipIdMap.IRecord, "IRecord", "IRecord")

  -- Configurable Connector
  connectorCompId = { name = "ConfigurableConnector", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local configurableConnComponent = ComponentContext(orb, connectorCompId)
  configurableConnComponent:addFacet("IConfigurable", "IDL:cas/configuration/IConfigurable:1.0", IConfigurable())
  configurableConnComponent:addReceptacle("IConfigurable", "IDL:cas/configuration/IConfigurable:1.0", true)
  membershipIdMap.IConfigurable = roomIContent:addSubComponent(configurableConnComponent.IComponent)
  roomIContent:bindConnectorFacet(membershipIdMap.IConfigurable, "IConfigurable", "IConfigurable")

   -- DataTransfer Connector
  connectorCompId = { name = "DataTransferConnector", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local dataTransferConnComponent = ComponentContext(orb, connectorCompId)
  dataTransferConnComponent:addFacet("IDataTransfer", "IDL:cas/transfer/IDataTransfer:1.0", IDataTransfer())
  dataTransferConnComponent:addReceptacle("IDataTransfer", "IDL:cas/transfer/IDataTransfer:1.0", true)
  membershipIdMap.IDataTransfer = roomIContent:addSubComponent(dataTransferConnComponent.IComponent)
  roomIContent:bindConnectorFacet(membershipIdMap.IDataTransfer, "IDataTransfer", "IDataTransfer")

  -- ActivitiesListener Connector
  connectorCompId = { name = "ActivitiesListenerConnector", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local checkerConnComponent = ComponentContext(orb, connectorCompId)
  checkerConnComponent:addFacet("IActivitiesListener", "IDL:cas/monitoring/IActivitiesListener:1.0", IActivitiesListener())
  checkerConnComponent:addReceptacle("IActivitiesListener", "IDL:cas/monitoring/IActivitiesListener:1.0", true)
  membershipIdMap.IActivitiesListener = roomIContent:addSubComponent(checkerConnComponent.IComponent)
  --roomIContent:bindConnectorReceptacle(membershipIdMap.IActivitiesListener, "IActivitiesListener", "IActivitiesListener")

  return membershipIdMap
end

function CreateSpeedCar(orb)
  local componentId = { name = "SpeedCar", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local speedCar = ComponentContext(orb, componentId)
  speedCar:addFacet("IRecord", "IDL:cas/recorder/IRecord:1.0", IRecord())
  speedCar:addFacet("IConfigurable", "IDL:cas/configuration/IConfigurable:1.0", IConfigurable())
  speedCar:addFacet("IDataTransfer", "IDL:cas/transfer/IDataTransfer:1.0", IDataTransfer())
  speedCar:addFacet("IActivitiesListener", "IDL:cas/monitoring/IActivitiesListener:1.0", IActivitiesListener())
  return speedCar.IComponent
end

------------------------------------------------------------------------
-- 4. Main
------------------------------------------------------------------------

local orb = oil.init({localrefs = "proxy"})

oil.main(function()
  local idlPath = os.getenv("IDL_PATH")
  orb:loadidlfile(idlPath .. "/scs.idl")
  orb:loadidlfile(idlPath .. "/composite.idl")
  orb:loadidlfile(idlPath .. "/configurable.idl")
  orb:loadidlfile(idlPath .. "/dataTransfer.idl")
  orb:loadidlfile(idlPath .. "/monitoring.idl")
  orb:loadidlfile(idlPath .. "/recorder.idl")
  orb:loadidlfile(idlPath .. "/roomConfigurator.idl")
  orb:loadidlfile(idlPath .. "/room.idl")
  oil.newthread(orb.run, orb)


---- 4.1 Criar os componentes RoomConfigurator e Room
  componentId = { name = "RoomConfigurator", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  roomConfiguratorComponent = ComponentContext(orb, componentId)
  roomConfiguratorComponent:addFacet("IRoomConfigurator", "IDL:cas/room/IRoomConfigurator:1.0", IRoomConfigurator())
  roomConfiguratorComponent:addReceptacle("RoomRecptacle", "IDL:cas/room/IRoom:1.0", true)

  local roomIComponent = CreateRoom(orb)

---- 4.2 RoomConfigurator encontra o Room e o configura
  roomConfiguratorComponent.room = roomIComponent
  local roomIContentController  = roomIComponent:getFacetByName("IContentController")
  local membershipIdMap = AddConectors(orb, roomIContentController)
  roomConfiguratorComponent.membershipIdMap = membershipIdMap

---- 4.3 Simula o painel de controles recebendo informacoes sobre o componente Room e os SpeedCars
  local controlPainer = ComponentContext(orb, componentId)
  controlPainer:addFacet("IActivitiesListener", "IDL:cas/monitoring/IActivitiesListener:1.0", IActivitiesListener())
  local controlPainelListener = controlPainer.IComponent:getFacetByName("IActivitiesListener")
  local controlPainelListener = orb:narrow(controlPainelListener, "IDL:cas/monitoring/IActivitiesListener:1.0")
  local roomRecepacles = roomIComponent:getFacetByName("IReceptacles")
  --roomRecepacles:connect("IActivitiesListener", controlPainelListener)


---- 4.4 Criar dois SpeedCars
  local speedCarComponent1 = CreateSpeedCar(orb)
  local speedCarComponent2 = CreateSpeedCar(orb)

---- 4.5 SpeedCars encontram o RoomConfigurator específico e pedem para serem adicionados no Room
  roomConfiguratorComponent = findSpeedCarRoom()
  if not roomConfiguratorComponent then
    print "Room Configurator não foi encontrado"
    os.exit(1)
  end

  roomContentController = roomConfiguratorComponent:getFacetByName("IRoomConfigurator")
  roomConfiguratorComponent = orb:narrow(roomConfiguratorComponent, "IDL:cas/room/IRoomConfigurator:1.0")
  roomContentController:connectComponent(speedCarComponent1)
  roomContentController:connectComponent(speedCarComponent2)

---- 4.6 Verificar se os SpeedCars estao no estado 'ready'
  local roomRecord = roomIComponent:getFacetByName("IRecord")
  roomRecord = orb:narrow(roomRecord, "IDL:cas/recorder/IRecord:1.0")
  local status = roomRecord:getStatus()
  print ("SpeedCar status: " .. status)

---- 4.7 Iniciar Gravacao
  roomRecord:startRecord()

---- 4.8 Verificar se os SpeedCars estao no estado 'recording'
  status = roomRecord:getStatus()
  print ("SpeedCar status: " .. status)


end)










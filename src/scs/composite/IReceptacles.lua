--
-- SCS
-- IReceptacles.lua
-- Description: Implementacao de IReceptacles que estende da implementacao base (SCS-Core)
-- Version: 1.0
--

local SuperIReceptacles = require "scs.core.Receptacles"
local oo = require "loop.simple"
local tabop = require "loop.table"
local memoize = tabop.memoize
local class = oo.class
local utils = require "scs.composite.Utils"
local compositeIdl = require "scs.composite.Idl"
local Log = require "scs.util.Log"
local Proxy = require "scs.composite.Proxy"
Proxy = Proxy.proxyComponent
utils = utils()

------------------------------------------------------------------------

local IReceptacles = class({}, SuperIReceptacles)

function IReceptacles:__new(orb, id, basicKeys)
  local receptacles = SuperIReceptacles()
  receptacles.connect = newConnect
  receptacles.disconnect = newDisconnect

  return receptacles
end

---
-- Conecta uma conexao ao receptaculo selecionado.
-- @remark A funcao verifica se a conexao pode ser adicionada no componente
--
---
function newConnect(self, name, connection)
  local context = self.context
  local orb = context._orb
  local iCompConnection = connection:_component()

  if isBinded(context, name) then
    Log:info("Adicionando receptaculo ao bind")

    local receptacleDesc = context:getReceptacleByName(name).bind
    local permission = receptacleDesc.permission
    local bindIReceptacle = receptacleDesc.facet
    local receptacleName = receptacleDesc.internalName
    local connectionInterface = context:getReceptacleByName(name).interface_name

    -- Cria o proxy
    local proxy = Proxy(orb)
    local connIComponentFacet = orb:narrow(connection:_component(), utils.ICOMPONENT_INTERFACE)
    proxy:setProxyComponent(connIComponentFacet, permission)

    -- Preferi nao adicionar o proxy no supercomponente para o getSubcomponets()
    -- nao ficar cheio proxys. Mas de repente sera necessario.
    -- Apenas defini que o pai do proxy e o superComponent. Temos que guarda-los em
    -- alguma estrutura de dados para depois conseguirmos destrui-los.
    local proxySuperComponent = proxy:getFacetByName(utils.ISUPERCOMPONENT_NAME).facet_ref
    local iComponent =  orb:narrow(context.IComponent, utils.ICOMPONENT_INTERFACE)
    proxySuperComponent:addSuperComponent(iComponent)

    -- Adicionar a faceta correta do proxy no receptaculo do componente interno.
    local proxyFacet = proxy:getFacet(connectionInterface).facet_ref
    bindIReceptacle:connect(receptacleName, proxyFacet)

  else
    Log:debug("Verifica compatibilidade entre a faceta e o receptaculo.")

    if not verifyCompatibility(self, name, iCompConnection) then
      error( orb:newexcept{ _repid = compositeIdl.throw.InvalidComponent })
    end
  end

  return SuperIReceptacles.connect(self, name, connection)
end

---
--
---
function newDisconnect(self, connId)
  return SuperIReceptacles:disconnect(connId)
end


---
--
---
function isBinded(context, name)
  if not context:getReceptacleByName(name) then
    return false
  end
  return (context:getReceptacleByName(name).bind ~= nil)
end

---
--
---
function verifyCompatibility(self, name, iComponent)
  local context = self.context
  local orb = context._orb

  -- Obeter a SuperComponentList do próprio componente.
  local superComponentFacet = context:getFacetByName(utils.ISUPERCOMPONENT_NAME).facet_ref
  superComponentFacet = orb:narrow(superComponentFacet, utils.ISUPERCOMPONENT_INTERFACE)
  local superComponentList = superComponentFacet:getSuperComponents()

  -- Obter a SuperComponentList da conexão.
  local connIComponentFacet = orb:narrow(iComponent, utils.ICOMPONENT_INTERFACE)
  local ok, connISuperCompFacet = pcall(connIComponentFacet.getFacetByName,
      connIComponentFacet, utils.ISUPERCOMPONENT_NAME)
  if not ok or not connISuperCompFacet then
    Log:error(string.format("A conexao nao eh compativel com o receptaculo '%s'.",name), connISuperCompFacet)
    error( orb:newexcept{ _repid = compositeIdl.throw.InvalidConnection })
  end

  connISuperCompFacet = orb:narrow(connISuperCompFacet, utils.ISUPERCOMPONENT_INTERFACE)
  local connSuperComponentList = connISuperCompFacet:getSuperComponents()

  if #superComponentList == 0 and #connSuperComponentList == 0 then
    return true
  end
  
  if ((#superComponentList > 0 and #connSuperComponentList == 0)
      or (#superComponentList == 0 and #connSuperComponentList > 0)) then
    Log:error(string.format("Componententes nao compativeis: #SuperComponent = %s | Componente do receptaculo a ser conectado = %s ",
        #superComponentList, #connSuperComponentList))
    return false
  end

  for _,superComponent in ipairs(superComponentList) do
    local superComponentFacet = orb:narrow(superComponent, utils.ICOMPONENT_INTERFACE)
    local superContentFacet = superComponentFacet:getFacetByName(utils.ICONTENTCONTROLLER_NAME)
    superContentFacet = orb:narrow(superContentFacet, utils.ICONTENTCONTROLLER)

    for _,connSuperComponent in ipairs(connSuperComponentList) do
      local connSuperComponentFacet = orb:narrow(connSuperComponent, utils.ICOMPONENT_INTERFACE)
      local connSuperContentFacet = connSuperComponentFacet:getFacetByName(utils.ICONTENTCONTROLLER_NAME)
      connSuperContentFacet = orb:narrow(connSuperContentFacet, utils.ICONTENTCONTROLLER)

      if superContentFacet:getId() == connSuperContentFacet:getId() then
        return true
      end
    end
  end

  Log:debug(string.format("Os componentes nao estao dentro de um mesmo supercomponente com o receptaculo '%s'.",name))
  return false
end

return IReceptacles

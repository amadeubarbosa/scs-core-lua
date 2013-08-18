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

    -- Preferi nao adicionar o proxy no supercomponente para o gerSubcomponets()
    -- nao ficar cheio proxys. Mas de repente será necessário
    -- Apenas defini que o pai do proxy é o superComponent.
    local proxySuperComponent = proxy:getFacetByName(utils.ISUPERCOMPONENT_NAME).facet_ref
    local iComponent =  orb:narrow(context.IComponent, utils.ICOMPONENT_INTERFACE)
    proxySuperComponent:addSuperComponent(iComponent)

    -- Adicionar a faceta correta do proxy no receptaculo do componente interno.
    local proxyFacet = proxy:getFacetByName(utils.ICOMPONENT_NAME).facet_ref
    proxyFacet =  orb:narrow(proxyFacet, utils.ICOMPONENT_INTERFACE)
    proxyFacet = proxyFacet:getFacetByName(utils.ICOMPONENT_NAME)
    bindIReceptacle:connect(receptacleName, proxyFacet)

    iCompConnection = proxy:getIComponent()
  end

  if not self:verifyCompatibility(name, iCompConnection)then
    error { _repid = compositeIdl.throw.InvalidComponent }
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

  local superComponentFacet = context:getFacetByName(utils.ISUPERCOMPONENT_NAME).facet_ref
  superComponentFacet = orb:narrow(superComponentFacet, utils.ISUPERCOMPONENT_INTERFACE)
  local superComponentList = superComponentFacet:getSuperComponents()

  -- Obter a SuperComponentList da conexão
  local connIComponentFacet = orb:narrow(iComponent, utils.ICOMPONENT_INTERFACE)
  local ok, connISuperCompFacet = pcall(connIComponentFacet.getFacetByName,
      connIComponentFacet, utils.ISUPERCOMPONENT_NAME)
  if not ok or not connISuperCompFacet then
    error { _repid = compositeIdl.throw.InvalidConnection }
  end
  connISuperCompFacet = orb:narrow(connISuperCompFacet, utils.ISUPERCOMPONENT_INTERFACE)
  local connSuperComponentList = connISuperCompFacet:getSuperComponents()

  if #superComponentList == 0 and #connSuperComponentList == 0 then
    return true
  end

  if ((#superComponentList > 0 and #connSuperComponentList == 0)
      or (#superComponentList == 0 and #connSuperComponentList > 0)) then
    error { _repid = compositeIdl.throw.InvalidConnection }
  end

  for _,superComponent in pairs(superComponentList) do
    local superComponentFacet = orb:narrow(superComponent, utils.ICOMPONENT_INTERFACE)
    local superContentFacet = superComponentFacet:getFacetByName(utils.ICONTENTCONTROLLER_NAME)
    superContentFacet = orb:narrow(superContentFacet, utils.ICONTENTCONTROLLER)

    for _,connSuperComponent in pairs(connSuperComponentList) do
      local connSuperComponentFacet = orb:narrow(connSuperComponent, utils.ICOMPONENT_INTERFACE)
      local connSuperContentFacet = connSuperComponentFacet:getFacetByName(utils.ICONTENTCONTROLLER_NAME)
      connSuperContentFacet = orb:narrow(connSuperContentFacet, utils.ICONTENTCONTROLLER)

      if superContentFacet:getId() == connSuperContentFacet:getId() then
        return true
      end
    end
  end

  return false
end

return IReceptacles

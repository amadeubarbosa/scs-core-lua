--
-- SCS
-- IReceptacles.lua
-- Description: Implementacao de IReceptacles que estende da implementacao base (SCS-Core)
-- Version: 1.0
--

local SuperIReceptacles = require "scs.core.Receptacles"
local oo = require "loop.simple"
local class = oo.class
local utils = require "scs.composite.Utils"
local compositeIdl = require "scs.composite.Idl"
utils = utils()
------------------------------------------------------------------------

local IReceptacles = class({}, SuperIReceptacles)

function IReceptacles:__new(orb, id, basicKeys)
  local receptacles = SuperIReceptacles()
  receptacles.connect = newConnect

  return receptacles
end

function newConnect(self, name, connection)
  local context = self.context
  local orb = context._orb

  local superComponentFacet = context:getFacetByName(utils.ISUPERCOMPONENT_NAME).facet_ref
  superComponentFacet = orb:narrow(superComponentFacet, utils.ISUPERCOMPONENT_INTERFACE)
  local superComponentList = superComponentFacet:getSuperComponents()

  -- Obter a SuperComponentList da conexão
  local connIComponentFacet = orb:narrow(connection:_component(),utils.ICOMPONENT_INTERFACE)
  local ok, connISuperCompFacet = pcall(connIComponentFacet.getFacetByName,
      connIComponentFacet, utils.ISUPERCOMPONENT_NAME)
  if not ok or not connISuperCompFacet then
    error { _repid = compositeIdl.throw.InvalidConnection }
  end
  connISuperCompFacet = orb:narrow(connISuperCompFacet, utils.ISUPERCOMPONENT_INTERFACE)
  local connSuperComponentList = connISuperCompFacet:getSuperComponents()

  if #superComponentList == 0 and #connSuperComponentList == 0 then
    return SuperIReceptacles.connect(self, name, connection)
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
        return SuperIReceptacles.connect(self, name, connection)
      end
    end
  end

  error { _repid = compositeIdl.throw.InvalidConnection }
end

return IReceptacles

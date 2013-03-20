--
-- SCS
-- IContentController.lua
-- Description:  ... . .. . . . . .
-- Version: 1.0
--

local oo = require "loop.base"
local class = oo.class

local utils = require "scs.composite.Utils"
utils = utils()
local Log = require "scs.util.Log"

local compositeIdl = require "scs.composite.Idl"
local ConnectorBuilder = require "scs.composite.Publisher"
------------------------------------------------------------------------

local ContentController = class()

function ContentController:__new()

  return oo.rawnew(self, {
      creationDate = os.date("%Y%m%d-%X"),
      membershipId = 1, -- Representa os subcomponentes
      componentSet = {},
  })
end

---
--
---
function ContentController:getId()
  local componentIOR = self.context.IComponent
  return tostring(componentIOR) .. "--" .. self.creationDate
end

---
--
---
function ContentController:addSubComponent(component)
  local context = self.context
  local orb = context._orb

  local subIComponent = orb:narrow(component, utils.ICOMPONENT_INTERFACE)
  if not subIComponent then
    error { _repid = compositeIdl.throw.InvalidComponent }
  end

  local ok, superCompFacet = pcall(subIComponent.getFacetByName, subIComponent, utils.ISUPERCOMPONENT_NAME)
  if not ok or not superCompFacet then
    error { _repid = compositeIdl.throw.InvalidComponent }
  end
  superCompFacet = orb:narrow(superCompFacet, utils.ISUPERCOMPONENT_INTERFACE)

  ok, metaInterfaceFacet = pcall(subIComponent.getFacetByName, subIComponent, utils.IMETAINTERFACE_NAME)
  if not ok or not metaInterfaceFacet then
    error { _repid = compositeIdl.throw.InvalidComponent }
  end
  metaInterfaceFacet = orb:narrow(metaInterfaceFacet, utils.IMETAINTERFACE_INTERFACE)

  if #metaInterfaceFacet:getReceptacles() > 0 and #superCompFacet:getSuperComponents() > 0 then
    error { _repid = compositeIdl.throw.UnshareableComponent }
  end

  ok = pcall(superCompFacet.addSuperComponent, superCompFacet, context.IComponent)
  if not ok then
    error { _repid = compositeIdl.throw.ComponentFailure }
  end

  local membershipId = self.membershipId
  self.membershipId = membershipId + 1

  self.componentSet[membershipId] = subIComponent
  return membershipId
end

---
--
---
function ContentController:removeSubComponent(membershipId)
  local context = self.context
  local orb = context._orb

  local ok, subComponent = pcall(self.findComponent, self, membershipId)
  if not ok or not subComponent then
    Log:warn(string.format("MemberID:%s não foi encontrado no componente composto",membershipId))
    return false
  end

  local ok, superCompFacet = pcall(subComponent.getFacetByName, subComponent, utils.ISUPERCOMPONENT_NAME)
  if not ok or not superCompFacet then
    Log:error("Faceta ISuperComponent não encontrada")
    return false
  end

  local removed
  superCompFacet = orb:narrow(superCompFacet, utils.ISUPERCOMPONENT_INTERFACE)
  ok, removed = pcall(superCompFacet.removeSuperComponent, superCompFacet, context.IComponent)
  if not ok then
    Log:error("Faceta encontrada não é ISuperComponent.")
    return false
  end
  if not removed then
    Log:error("Faceta não foi removida do Subcomponente")
    return false
  end

  self.componentSet[membershipId] = nil
  return true
end

---
--
---
function ContentController:getSubComponents()
  local subComponents = {}

  for id,component in pairs (self.componentSet) do
    table.insert(subComponents, {id = id, iComponent = component})
  end

  return subComponents
end

---
--
---
function ContentController:retrieveBindings()
  local context = self.context
  local bindDesc = {}

  for _, facet in pairs(context:getFacets()) do
  if facet.bindingId then
    table.insert(bindDesc, { id = facet.bindingId, name = facet.name, isFacet = true })
  end
  end

  for _, receptacle in pairs(context:getReceptacles()) do
  if facet.bindingId then
    table.insert(bindDesc, { id = receptacle.bindingId, name = receptacle.name, isFacet = false })
  end
  end

  return bindDesc
end

---
--
---
function ContentController:findComponent(membershipId)
  if not self.componentSet[membershipId] then
    error { _repid = compositeIdl.throw.ComponentNotFound }
  end

  return self.componentSet[membershipId]
end

---
--
---
function ContentController:bindFacet(connectorID, internalFacetName, externalFacetName)
  local context = self.context
  local orb = context._orb

  local ok, subcomponent = pcall(self.findComponent, self, connectorID)
  if not ok or not subcomponent then
    error { _repid = compositeIdl.throw.ComponentNotFound, id = connectorID }
  end

  local internalFacet = subcomponent:getFacetByName(internalFacetName)
  if not internalFacet then
    error { _repid = compositeIdl.throw.FacetNotFound }
  end

  local facetInComposite = context:getFacetByName(externalFacetName)
  if facetInComposite then
    error { _repid = compositeIdl.throw.FacetAlreadyExists }
  end

  local metaFacet = subcomponent:getFacetByName(utils.IMETAINTERFACE_NAME)
  metaFacet = orb:narrow(metaFacet, utils.IMETAINFERFACE_INTERFACE)

  local descriptions = metaFacet:getFacetsByName({internalFacetName})
  if #descriptions < 1 then
    error { _repid = compositeIdl.throw.FacetNotFound }
  end

  local facetDescription = descriptions[1]
  local interfaceName = facetDescription.interface_name
  local facetRef = facetDescription.facet_ref

  context:registerFacet(externalFacetName, interfaceName, facetRef, nil)
  context:setFacetAsBind(externalFacetName)

  return context:getFacetByName(externalFacetName).bindingId
end

---
--
---
local function unbindFacet(self, bindingId)
  local context = self.context
  local orb = context._orb

  local facets = context:getFacets()
  for _,facet in ipairs(facets) do
    if facet.bindingId == bindingId then
      local connector = context:getFacetByName(facet.name)
      context:removeFacet(facet.name)

      local status, errMsg = pcall(orb.deactivate, orb, connector)
      if not status then
        Log:error("Erro ao desativar o servant",errMsg)
        return false
      end
      return true
    end
  end

  return false
end

---
--
---
local function unbindReceptacle(self, bindingId)
  local context = self.context

  local receptacles = context:getReceptacles()
  for _,receptacle in ipairs(receptacles) do
    if receptacle.bindingId == bindingId then
      context:removeReceptacle(receptacle.name)
      return true
    end
  end

  return false
end

---
--
---
function ContentController:unbind(bindingId)
  if not unbindFacet(self, bindingId) then
    return unbindReceptacle(self, bindingId)
  end
  return true
end

---
--
---
function ContentController:bindReceptacle(connectorID, internalReceptacleName, externalReceptacleName)
  local context = self.context
  local orb = context._orb

  local ok, subcomponent = pcall(self.findComponent, self, connectorID)
   if not ok or not subcomponent then
    error { _repid = compositeIdl.throw.ComponentNotFound, id = connectorID }
  end

  local isubReceptacle = subcomponent:getFacetByName(utils.IRECEPTACLES_NAME)
  if not isubReceptacle then
    error { _repid = compositeIdl.throw.ReceptacleNotAvailableInComponent }
  end
  isubReceptacle = orb:narrow(isubReceptacle, utils.IRECEPTACLES_INTERFACE)

  local metaFacet = subcomponent:getFacetByName(utils.IMETAINTERFACE_NAME)
  if not metaFacet then
    error { _repid = compositeIdl.throw.ReceptacleNotAvailableInComponent }
  end
  metaFacet = orb:narrow(metaFacet, utils.IMETAINTERFACE_INTERFACE)

  local descriptions = metaFacet:getReceptaclesByName({internalReceptacleName})
  if #descriptions < 1 then
    error { _repid = compositeIdl.throw.ReceptacleNotFound }
  end

  local recptacleDescription = descriptions[1]
  isMultiplex = recptacleDescription.isMultiplex
  interfaceName = recptacleDescription.interface_name

  context:addReceptacle(externalReceptacleName, interfaceName, isMultiplex)
  context:setReceptacleAsBind(externalReceptacleName, isubReceptacle, internalReceptacleName)

  return context:getReceptacleByName(externalReceptacleName).bind.id
end

return ContentController

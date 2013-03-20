--
-- SCS
-- ComponentContext.lua
-- Description:
-- Version: 1.0
--

local ISuperComponent = require "scs.composite.ISuperComponent"
local IContentController = require "scs.composite.IContentController"
local IReceptacles = require "scs.composite.IReceptacles"
local SuperComponentContext = require "scs.core.ComponentContext"
local oo = require "loop.simple"
local class = oo.class
local utils = require "scs.composite.Utils"
local Log = require "scs.util.Log"
utils = utils()
------------------------------------------------------------------------

local ComponentContext = class({}, SuperComponentContext)

function ComponentContext:__new(orb, id, basicKeys)
  local component = SuperComponentContext.__new(self, orb, id, basicKeys)
  addCompositeFacets(component, basicKeys)

  component.bindingId = 1

  component:updateFacet(utils.IRECEPTACLES_NAME, IReceptacles())
  return component
end

function addCompositeFacets(component, basicKeys)
  local basicKeys = basicKeys or {}

  component:addFacet(utils.ICONTENTCONTROLLER_NAME,
      utils.ICONTENTCONTROLLER_INTERFACE,
      IContentController(), basicKeys.IContentController)

   component:addFacet(utils.ISUPERCOMPONENT_NAME,
      utils.ISUPERCOMPONENT_INTERFACE,
      ISuperComponent(), basicKeys.ISuperComponent)
end

function ComponentContext:setFacetAsBind(name)
  if not self._facets[name] then
    Log:error("A faceta nao existe")
    return
  end

  self._facets[name].bindingId = self.bindingId
  self.bindingId = self.bindingId + 1
end

---
-- Optei por colocar somente n-1, obrigando a utilização de um conector.
---
function ComponentContext:setReceptacleAsBind(name, ireceptacle, internalReceptacleName)
  if not self._receptacles[name] then
    Log:error("O receptaculo nao existe")
    return
  end

  self._receptacles[name].bind = {id = self.bindingId, facet = ireceptacle, internalName = internalReceptacleName }
  self.bindingId = self.bindingId + 1
end

return ComponentContext

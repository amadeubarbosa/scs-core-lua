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
utils = utils()
------------------------------------------------------------------------

local ComponentContext = class({}, SuperComponentContext)

function ComponentContext:__new(orb, id, basicKeys)
  local component = SuperComponentContext.__new(self, orb, id, basicKeys)
  addCompositeFacets(component, basicKeys)

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


return ComponentContext

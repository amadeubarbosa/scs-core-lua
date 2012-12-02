

---
-- SCS
-- ISuperComponent.lua
-- Description:  ... . .. . . . . .
-- Version: 1.0
---

local oo = require "loop.base"
local class = oo.class

local utils = require "scs.composite.Utils"
utils = utils()


local ISuperComponent = class()

function ISuperComponent:__new()
 
  return oo.rawnew(self, {superComponents = {}})
end


function ISuperComponent:addSuperComponent(iComponent)
	local context = self.context
	local composite = context._orb:narrow(iComponent:getFacetByName(utils.ICONTENTCONTROLLER_NAME))

	self.superComponents[composite:getId()] = composite
end


function ISuperComponent:removeSuperComponent(iComponent)
	-- Não sei como fazer? Via ComponentID?
end


function ISuperComponent:getSuperComponents()
	local context = self.context
	local superComponents = {}

	for _, icomponent in pairs(context._superComponents) do
		table.insert(superComponents, icomponent)
	end

	return superComponents
end


return ISuperComponent

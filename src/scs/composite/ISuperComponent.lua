

--
-- SCS
-- ISuperComponent.lua
-- Description:  ... . .. . . . . .
-- Version: 1.0
--

local class = require "loop.base"
local utils = require "scs.composite.utils"
utils = utils()


local ISuperComponent = class()

function __new()
	superComponents = {}
end


function ISuperComponent:addSuperComponent(iComponent)
	local context = self.context

	local composite = context._orb:narrow(iComponent:getFacetByName(utils.ICONTENTCONTROLLER_NAME))
	self.superComponents[composite:getId()] = composite
end


function SuperComponent:removeSuperComponent(iComponent)
	-- Não sei como fazer? Via ComponentID?
end


function SuperComponent:getSuperComponents()
	local context = self.context
	local superComponents = {}

	for _, icomponent in pairs(context._superComponents) do
		table.insert(superComponents, icomponent)
	end

	return superComponents
end

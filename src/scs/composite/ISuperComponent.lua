

---
-- SCS
-- ISuperComponent.lua
-- Description:  ... . .. . . . . .
-- Version: 1.0
---

local oo = require "loop.base"
local class = oo.class
local pairs = pairs
local Log = require "scs.util.Log"

local utils = require "scs.composite.Utils"
utils = utils()


local ISuperComponent = class()

function ISuperComponent:__new()
 
  return oo.rawnew(self, {superComponents = {}})
end


function ISuperComponent:addSuperComponent(iComponent)
	local context = self.context
	local composite = context._orb:narrow(iComponent:getFacetByName(utils.ICONTENTCONTROLLER_NAME))

  if not iComponent:_is_a(utils.ICOMPONENT_INTERFACE) then
    error { compositeIdl.throw.InvalidComponent }
  end

	self.superComponents[composite:getId()] = iComponent
end


function ISuperComponent:removeSuperComponent(iComponent)
	local context = self.context
  local composite = context._orb:narrow(iComponent:getFacetByName(utils.ICONTENTCONTROLLER_NAME))
  
  local ok, compositeId = pcall(composite.getId, composite)
  if not ok or not compositeId then
    Log:error("ID não retornado pela funcao getId().")
    return false
  end 
  
  local remComponent = self.superComponents[compositeId]
  if not remComponent then
    Log:error(string.format("O id '%s' não existe", composite:getId()))
    return false
  end 
  
  self.superComponents[composite:getId()] = nil
  return true
end


function ISuperComponent:getSuperComponents()
	local context = self.context
	local superComponents = {}

	for _, icomponent in pairs(self.superComponents) do
		table.insert(superComponents, icomponent)
	end

	return superComponents
end


return ISuperComponent

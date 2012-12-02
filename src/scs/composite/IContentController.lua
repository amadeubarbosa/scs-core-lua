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
--local ConnectorBuilder = require "loop.object.Publisher"
local ConnectorBuilder = require "scs.composite.Publisher"
------------------------------------------------------------------------

local ContentController = class()



function ContentController:__new()
  math.randomseed(os.date("%M%S"))
  self.id = not self.id and math.random(100,999) or self.id + 1

  return oo.rawnew(self, {
      id = self.id,
      membershipId = 1, -- Representa os subcomponentes
      bindingId = 1, -- Representa os conectores criados
      facetConnectorsMap = {},
      receptacleConnectorsMap = {},
      componentSet = {},
  })
end


function ContentController:getId()
	return tostring(self.id)
end


function ContentController:addSubComponent(component)
	local context = self.context
  local orb = context._orb

  local subIComponent = orb:narrow(component, utils.ICOMPONENT_INTERFACE)
  if not subIComponent then
    error { compositeIdl.throw.InvalidComponent }
  end

	local ok, superCompFacet = pcall(subIComponent.getFacetByName, subIComponent, utils.ISUPERCOMPONENT_NAME)
	if not ok or not superCompFacet then
		error { compositeIdl.throw.InvalidComponent }
	end

	superCompFacet = orb:narrow(superCompFacet, utils.ISUPERCOMPONENT_INTERFACE)
  if not superCompFacet then
    error { compositeIdl.throw.InvalidComponent }
  end 
  
 	ok = pcall(superCompFacet.addSuperComponent, superCompFacet, context.IComponent)
	if not ok then
		error { compositeIdl.throw.ComponentFailure }
	end

	local membershipId = self.membershipId
	self.membershipId = membershipId + 1

	self.componentSet[membershipId] = subIComponent
	return membershipId
end

-- Não possui exceção porque o usuário não quer ficar tratando falhas. Só quer remover o componente.
function ContentController:removeSubComponent(membershipId)
	local context = self.context  
  local orb = context._orb

	local ok subComponent = pcall(self.findComponent, self, membershipId)
	if not ok or not subcomponent then
    Log:warn(string.format("MemberID:%s não foi encontrado no componente composto",membershipId))
    return false
	end

	local ok, superCompFacet = pcall(subComponent.getFacetByName, subComponent, utils.ISUPERCOMPONENT_NAME)
	if not ok or not superCompFacet then
    Log:error("Faceta ISuperComponent não encontrada")
		return false
	end

	superCompFacet = orb:narrow(scFacet, utils.ISUPERCOMPONENT_INTERFACE)
	ok = pcall(superCompFacet.removeSuperComponent, superCompFacet, context.IComponent)
	if not ok then
    Log:error("Faceta encontrada não é da interface ISuperComponent.")
		return false
	end

	self.componentSet[membershipId] = nil
  return true
end

function ContentController:getSubComponents()
	local subComponents = {}

	for id,component in pairs (self.componentSet) do
		table.insert(subComponents, {id = id, iComponent = component})
	end

	return subComponents
end

function ContentController:findComponent(membershipId)
	if not self.componentSet[membershipId] then
		error { compositeIdl.throw.ComponentNotFound }
	end

	return self.componentSet[membershipId]
end


function ContentController:bindFacet(internalFacetList, externalFacetName)
	local context = self.context
	local orb = context._orb
	local componentsList = {}
	local interfaceName = nil

	for _,facetBind in ipairs(internalFacetList) do
		local ok, subcomponent = pcall(self.findComponent, self, facetBind.id)
		if not ok or not subcomponent then    
			error { compositeIdl.throw.ComponentNotFound, id = id }
		end

		local internalFacet = subcomponent:getFacetByName(facetBind.name)
		if not internalFacet then
			error { compositeIdl.throw.FacetNotAvailableInComponent }
		end

		local facetInComposite = context:getFacetByName(externalFacetName)    
		if facetInComposite then
			error { compositeIdl.throw.FacetAlreadyExists }
		end

		local metaFacet = subcomponent:getFacetByName(utils.IMETAINTERFACE_NAME)

		metaFacet = orb:narrow(metaFacet, utils.IMETAINFERFACE_INTERFACE)

		local descriptions = metaFacet:getFacetsByName({facetBind.name})
		if #descriptions < 1 then
			error { compositeIdl.throw.FacetNotFound }
		end

		local facetDescription = descriptions[1]

		if not interfaceName then
      interfaceName = facetDescription.interface_name
		elseif interfaceName ~= facetDescription.interface_name then
			error { compositeIdl.throw.IncompatibleInterfaces }
		end

		local facetRef = orb:narrow(facetDescription.facet_ref, interfaceName)
		table.insert(componentsList, facetRef)
	end

	-- Cria o conector
	local connector = ConnectorBuilder(componentsList)
  
  context:addFacet(externalFacetName, interfaceName, connector)

	local bindingId = self.bindingId
	self.facetConnectorsMap[bindingId] = externalFacetName
	self.bindingId  = bindingId + 1

	return bindingId

end

function ContentController:unbindFacet(bindingId)
	local context = self.context
	local orb = context._orb

	local facetName = self.facetConnectorsMap[bindingId]
	if not facetName then
		return
	end

	local connector = context:getFacetByName(facetName)
	context:removeFacet(facetName)


	local status, err = oil.pcall(orb.deactivate, orb, connector) -- será?
	if not status then
		-- throw??
	end
end

function ContentController:bindReceptacle(subcomponents, internalReceptacleName, externalReceptacleName)
	local context = self.context
	local componentsList = {}
	local interfaceName = nil
	local isMultiplex = false -- Se um componente não for multiplex o conector não será multiplex

	for _,id in pairs(subcomponents) do

		local ok, subcomponent = pcall(self.findComponent, self, id)
		if not ok or not subcomponent then
			error { compositeIdl.throw.ComponentNotFound, id = id }
		end

		local metaFacet = subcomponent:getFacetByName(utils.IMETAINFERFACE_NAME)
		if not metaFacet then
			error { compositeIdl.throw.ReceptacleNotAvailableInComponent }
		end
		metaFacet = orb:narrow(metaFacet, utils.IMETAINFERFACE_INTERFACE)

		local ireceptacleFacet = subcomponent:getFacetByName(utils.IRECEPTACLE_NAME)
		if not ireceptacleFacet then
			error { compositeIdl.throw.ReceptacleNotAvailableInComponent }
		end
		ireceptacleFacet = orb:narrow(ireceptacleFacet, utils.IRECEPTACLE_INTERFACE)


		local descriptions = metaFacet:getReceptaclesByName({internalReceptacleName})
		if #descriptions < 1 then
			error { compositeIdl.throw.ReceptacleNotFound }
		end

		local recptacleDescription = descriptions[1]
		isMultiplex = isMultiplex and recptacleDescription.isMultiplex

		if not interfaceName then
			interfaceName = recptacleDescription.interface_name
		elseif interfaceName ~= recptacleDescription.interface_name then
			error { compositeIdl.throw.IncompatibleInterfaces }
		end


		table.insert(componentsList, ireceptacleFacet)
	end

	-- Cria o conector
	local connector = ConnectorBuilder(componentsList)
	context:addReceptacle(externalFacetName, interfaceName, connector)

	local bindingId = self.bindingId
	self.receptacleConnectorsMap[bindingId] = externalReceptacleName
	self.bindingId  = bindingId + 1

	return bindingId
end

function ContentController:unbindReceptacle(bindingId)
	local context = self.context

	local receptacleName = context.receptacleBinding[bindingId]
	if not receptacleName then
		return
	end

	local receptacle = context:removeReceptacle(receptacleName)
	if not receptacle then
		return
	end

	self.receptacleConnectorsMap[bindingId] = nil
end

return ContentController

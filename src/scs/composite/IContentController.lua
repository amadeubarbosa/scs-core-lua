
--
-- SCS
-- IContentController.lua
-- Description:  ... . .. . . . . .
-- Version: 1.0
--

local class = require "loop.base"
local utils = require "scs.composite.utils"
local compositeIdl = require "idl.composite.idl"
local ConnectorBuilder = require "loop.object.Publisher"
utils = utils()


local ContentController = oo.class{}


function ContentController:__new()
  self.id = 123 -- ????
  self.membershipID = 1 -- Representa os subcomponentes
  self.bindingId = 1 -- Representa os conectores criados
  self.facetConnectorsMap = {}
  self.receptacleConnectorsMap = {}
  self.componentSet = {}
end


function ContentController:getId()
	return tostring(id)
end


function ContentController:addSubComponent(component)
	local context = self.context

	local ok, superCompFacet = pcall(component.getFacetByName, component, Utils.ISUPERCOMPONENT_NAME)
	if not ok or superCompFacet = nil then
		error { compositeIdl.throw.InvalidComponent }
	end

	superCompFacet = superCompFacet:__narrow(scFacet,Utils.ISUPERCOMPONENT_INTERFACE)
	ok = pcall(superCompFacet.addSuperComponent, superCompFacet, context.IComponent)
	if not ok then
		error { compositeIdl.throw.ComponentFailure }
	end

	local membershipID = self.membershipID
	self.membershipID = membershipID + 1

	context.componentSet[membershipID] = component
	return membershipId

end


function ContentController:removeSubComponent(membershipId)
	local context = self.context

	local ok subComponent = pcall(self.findComponent, self, membershipId)
	if not ok or not subcomponent then
		error { compositeIdl.throw.ComponentNotFoundException }
	end

	local ok, superCompFacet = pcall(subComponent.getFacetByName, subComponent, Utils.ISUPERCOMPONENT_NAME)
	if not ok or superCompFacet = nil then
		error { compositeIdl.throw.ComponentFailure, msg = "Faceta ISuperComponent não encontrada"  }
	end

	superCompFacet = superCompFacet:__narrow(scFacet, Utils.ISUPERCOMPONENT_INTERFACE)
	ok = pcall(superCompFacet.removeSuperComponent, superCompFacet, context.IComponent)
	if not ok then
		error { compositeIdl.throw.ComponentFailure, msg = "Faceta encontrada não é da interface ISuperComponent."  }
	end

	context._componentSet[membershipId] = nil
end


function ContentController:getSubComponents()
	local self = self.context
	local subComponents = {}

	for _,component in pairs (self.componentSet) do
		table.insert(subComponents,component)
	end

	return subComponents
end

function ContentController:findComponent(membershipId)
	local context = self.context

	if not context.componentSet[membershipId] then
		error { compositeIdl.throw.ComponentNotFound }
	end

	return context.componentSet[membershipId]
end


function ContentController:bindFacet(subcomponents, internalFacetName, externalFacetName)
	local context = self.context
	local orb = self._orb
	local componentsList = {}
	local interfaceName = nil

	for _,id in pairs(subcomponents)
		local ok, subcomponent = pcall(self.findComponent, self, id)
		if not ok or not subcomponent then
			error { compositeIdl.throw.ComponentNotFound, id = id }
		end

		local internalFacet = subcomponent:getFacetByName(internalFacetName)
		if not internalFacet then
			error { compositeIdl.throw.FacetNotAvailableInComponent }
		end

		local facetInComposite = context:getFacetByName(externalFacetName)
		if facetInComposite then
			error { compositeIdl.throw.FacetAlreadyExists }
		end

		local metaFacet = subcomponent:getFacetByName(Utils.IMETAINFERFACE_NAME)
		metaFacet = orb:narrow(metaFacet, Utils.IMETAINFERFACE_INTERFACE)

		local descriptions = metaFacet:getFacetsByName({internalFacetName})
		if #descriptions < 1 then
			error { compositeIdl.throw.FacetNotFound }
		end

		local facetDescription = descriptions[1]

		if not interfaceName then
			interfaceName = facetDescription.interface_name
		else if interfaceName ~= facetDescription.interface_name then
			error { compositeIdl.throw.IncompatibleInterfaces }
		end

		local facetRef = orb:narrow(facetDescription.facet_ref)
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

	for _,id in pairs(subcomponents)

		local ok, subcomponent = pcall(self.findComponent, self, id)
		if not ok or not subcomponent then
			error { compositeIdl.throw.ComponentNotFound, id = id }
		end

		local metaFacet = subcomponent:getFacetByName(Utils.IMETAINFERFACE_NAME)
		if not metaFacet then
			error { compositeIdl.throw.ReceptacleNotAvailableInComponent }
		end
		metaFacet = orb:narrow(metaFacet, Utils.IMETAINFERFACE_INTERFACE)

		local ireceptacleFacet = subcomponent:getFacetByName(Utils.IRECEPTACLE_NAME)
		if not ireceptacleFacet then
			error { compositeIdl.throw.ReceptacleNotAvailableInComponent }
		end
		ireceptacleFacet = orb:narrow(ireceptacleFacet, Utils.IRECEPTACLE_INTERFACE)


		local descriptions = metaFacet:getReceptaclesByName({internalReceptacleName})
		if #descriptions < 1 then
			error { compositeIdl.throw.ReceptacleNotFound }
		end

		local recptacleDescription = descriptions[1]
		isMultiplex = isMultiplex and recptacleDescription.isMultiplex

		if not interfaceName then
			interfaceName = recptacleDescription.interface_name
		else if interfaceName ~= recptacleDescription.interface_name then
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

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
 	ok = pcall(superCompFacet.addSuperComponent, superCompFacet, context.IComponent)
	if not ok then
		error { compositeIdl.throw.ComponentFailure }
	end

	local membershipId = self.membershipId
	self.membershipId = membershipId + 1

	self.componentSet[membershipId] = subIComponent
	return membershipId
end

-- N�o possui exce��o porque o usu�rio n�o quer ficar tratando falhas. S� quer remover o componente.
function ContentController:removeSubComponent(membershipId)
	local context = self.context  
  local orb = context._orb

	local ok, subComponent = pcall(self.findComponent, self, membershipId)
	if not ok or not subComponent then
    Log:warn(string.format("MemberID:%s n�o foi encontrado no componente composto",membershipId))
    return false
	end

	local ok, superCompFacet = pcall(subComponent.getFacetByName, subComponent, utils.ISUPERCOMPONENT_NAME)
	if not ok or not superCompFacet then
    Log:error("Faceta ISuperComponent n�o encontrada")
		return false
	end
  
  local removed
	superCompFacet = orb:narrow(superCompFacet, utils.ISUPERCOMPONENT_INTERFACE)
	ok, removed = pcall(superCompFacet.removeSuperComponent, superCompFacet, context.IComponent)
	if not ok then
    Log:error("Faceta encontrada n�o � ISuperComponent.")
		return false
	end
  if not removed then 
    Log:error("Faceta n�o foi removida do Subcomponente")
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


function ContentController:bindFacet(internalFacetList, connectorType, externalFacetName)
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
  SetConnectorType(connector, connectorType)
  
  context:addFacet(externalFacetName, interfaceName, connector)

	local bindingId = self.bindingId
	self.facetConnectorsMap[bindingId] = externalFacetName
	self.bindingId  = bindingId + 1

	return bindingId

end

function ContentController:bindConnectorFacet(connectorID, internalFacetName, externalFacetName)
  local context = self.context
  local orb = context._orb
  
  local ok, subcomponent = pcall(self.findComponent, self, connectorID)
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
  
  local metaFacet = subcomponent:getFacetByName(utils.IMETAINTERFACE_NAME)
  metaFacet = orb:narrow(metaFacet, utils.IMETAINFERFACE_INTERFACE)

  local descriptions = metaFacet:getFacetsByName({internalFacetName})
  if #descriptions < 1 then
    error { compositeIdl.throw.FacetNotFound }
  end

  local facetDescription = descriptions[1]
  local interfaceName = facetDescription.interface_name
  local facetRef = facetDescription.facet_ref

  context:registerFacet(externalFacetName, interfaceName, nil, facetRef, nil)
  
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
		return false
	end

	local connector = context:getFacetByName(facetName)
	context:removeFacet(facetName)

	local status, errMsg = pcall(orb.deactivate, orb, connector) -- ser�?
	if not status then
    Log:error("Erro ao desativar o servant",errMsg)
		return false
	end
  
  return true
end

function ContentController:bindReceptacle(subcomponents, internalReceptacleName, externalReceptacleName)
	local context = self.context
	local componentsList = {}
	local interfaceName = nil
	local isMultiplex = false -- Se um componente n�o for multiplex o conector n�o ser� multiplex

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

function SetConnectorType(connector, connectorType)
  if connectortype ==  utils.replication then
    connector.opBool = function (a,b) return a end
    connector.opNumber = connector.opBool
    connector.opString = connector.opBool
    function connector.opList(mainList, subList)
      return mainList
    end
  
  elseif connectortype == utils.consensus then
    connector.opBool = function (a,b) return a and b end
    connector.opNumber = function (a,b,lenght) return (a + b)/lenght end
    connector.opString = function (a,b) return a end
    function connector.opList(mainList, subList, iteration) -- M�dia ponderada
      for i,elements in ipairs(subList) do
        mainList[i] = (mainList[i] * iteration + elements * 1)/(iteration + 1)
      end
      return mainList
    end
  
  elseif connectortype == utils.cooperation then
    connector.opBool = function (a,b) return a or b end
    connector.opNumber = function (a,b) return a end
    connector.opString = function (a,b) return a end
    function connector.opList(mainList, subList)
      for _,elements in ipairs(subList) do 
        table.insert(mainList,elements) 
      end
      return mainList
    end
  else
    error { compositeIdl.throw.UnknownConnectorType } 
  end
  
end

return ContentController

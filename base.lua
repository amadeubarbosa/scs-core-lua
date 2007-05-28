local verbose = require "oil.verbose"



local error        	= error
local getmetatable 	= getmetatable
local ipairs       	= ipairs
local module       	= module
local require      	= require
local tonumber     	= tonumber
local tostring     	= tostring
local type         	= type
local io 			= io
local string		= string
local assert		= assert
local os			= os
local print			= print
local pairs			= pairs

local oo        = require "loop.base"
local component = require "loop.component.base"
local ports     = require "loop.component.base"
local oil		= require "oil"

--------------------------------------------------------------------------------

module "scs.core.base"

--------------------------------------------------------------------------------

local IsMultipleReceptacle = {
	[ports.HashReceptacle] = true,
	[ports.ListReceptacle] = true,
	[ports.SetReceptacle] = true,
}

function newComponent(factory, descriptions)
	local instance = factory()
	instance.facetDescs = {}
	instance.receptacleDescs = {}
	instance.receptsByConId = {}
	instance.numConnections = 0
	instance.nextConnId = 0
	instance.maxConnections = 100
	for name, kind in component.ports(instance) do
		if kind == ports.Facet then
			instance.facetDescs[name] = descriptions[name]
			instance.facetDescs[name].facet_ref = oil.newobject(instance[name], descriptions[name].interface_name)
			instance[name] = instance.facetDescs[name].facet_ref
		elseif kind == ports.Receptacle or IsMultipleReceptacle[kind] then
			if not descriptions[name].connections then
				descriptions[name].connections = {}
--				descriptions[name].keys = {}
			end
			instance.receptacleDescs[name] = descriptions[name]
		end
	end
	return instance
end

--------------------------------------------------------------------------------

Component = oo.class{ context = false }

function Component:startup()
end

function Component:shutdown()
end

function Component:getFacet(interface)
	self = self.context
	for name, kind in component.ports(self) do
		if kind == ports.Facet and self.facetDescs[name].interface_name == interface then
			return self[name]
		end
	end
end

function Component:getFacetByName(name)
	self = self.context
	if component.templateof(self)[name] == ports.Facet then
		return self[name]
	end
end

--------------------------------------------------------------------------------

Receptacles = oo.class{ context = false }

function Receptacles:connect(receptacle, object)
	if not object then error{ "IDL:scs::core/InvalidConnection:1.0" } end
	self = self.context
	local bindKey = 0
	local port = component.templateof(self)[receptacle]
	if port == ports.Receptacle then
		-- this is a standard receptacle, which accepts only one connection
		if self[receptacle] then
			error{ "IDL:scs::core/AlreadyConnected:1.0" }
		else
			-- this receptacle accepts only one connection
			self[receptacle] = object
		end
	elseif IsMultipleReceptacle[port] then
		-- this receptacle accepts multiple connections
		bindKey = self[receptacle]:__bind(object)
	else
		error{ "IDL:scs::core/InvalidName:1.0" }
	end
	if (self.numConnections <= self.maxConnections) then
		self.numConnections = self.numConnections + 1
		self.nextConnId = self.nextConnId + 1
		self.receptacleDescs[receptacle].connections[nextConnId] = {	id = nextConnId, 
																				objref = object}
		self.receptsByConId[nextConnId] = self.receptacleDescs[receptacle]
--[[
		if bindKey > 0 then
			self.receptDescripts[receptacle].keys[nextConnId] = bindKey
		end
--]]
		return nextConnId
	end
	error{ "IDL:scs::core/ExceededConnectionLimit:1.0" }
end

function Receptacles:disconnect(connId)
	self = self.context
	receptacle = self.receptsByConId[connId].name
	local port = component.templateof(self)[receptacle]
	if port == ports.Receptacle then
		if self[receptacle] then
			self[receptacle] = nil
		else
			error{ "IDL:scs::core/InvalidConnection:1.0" }
		end
	elseif IsMultipleReceptacle[port] then
		if self[receptacle]:__unbind(connId) then
			self.numConnections = self.numConnections - 1
			self.receptacleDescs[receptacle].connections[connId] = nil
			self.receptsByConId[connId].connections[connId] = nil
--			self.receptDescripts[receptacle].keys[connId] = nil
		else
			error{ "IDL:scs::core/InvalidConnection:1.0" }
		end
	else
		error{ "IDL:scs::core/InvalidName:1.0", name = receptacle }
	end
end

function Receptacles:getConnections(receptacle)
	self = self.context
	if self.context.receptacleDescs[receptacle] then
		return self.receptacleDescs[receptacle].connections
	end
	error{ "IDL:scs::core/InvalidName:1.0", name = receptacle }
end

--------------------------------------------------------------------------------

MetaInterface = oo.class{ context = false }

function MetaInterface:getDescriptions(portType, selected)
	self = self.context
	if not selected then
		if portType == "receptacle" then
			return self.receptacleDescs
		elseif portType == "facet" then
			return self.facetDescs
		end
	end
	local descs = {}
	for _, name in ipairs(selected) do
		if portType == "receptacle" then
			if self.receptacleDescs[name] then
				descs[name] = self.receptacleDescs[name]
			else
				error{ "IDL:scs::core/InvalidName:1.0", name = name }
			end
		elseif portType == "facet" then
			if self.facetDescs[name] then
				descs[name] = self.facetDescs[name]
			else
				error{ "IDL:scs::core/InvalidName:1.0", name = name }
			end
		end
	end
	return descs
end


function MetaInterface:getFacets()
	return self:getDescriptions("facet")
end

function MetaInterface:getFacetsByName(names)
	return self:getDescriptions("facet", names)
end

function MetaInterface:getReceptacles()
	return self:getDescriptions("receptacle")
end

function MetaInterface:getReceptaclesByName(names)
	return self:getDescriptions("receptacle", names)
end

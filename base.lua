--
-- SCS
-- base.lua
-- Description: Basic SCS classes and API
-- Version: 1.0
--

local oo        = require "loop.base"
local component = require "loop.component.base"
local ports     = require "loop.component.base"
local oil		= require "oil"

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

--------------------------------------------------------------------------------

module "scs.core.base"

--------------------------------------------------------------------------------

-- This structure is used to check the type of the receptacle
local IsMultipleReceptacle = {
	[ports.HashReceptacle] = true,
	[ports.ListReceptacle] = true,
	[ports.SetReceptacle] = true,
}

--
-- Description: Creates a new component instance and prepares it to be used in the system.
-- Parameter factory: Factory object that will be used to create the instance.
-- Parameter descriptions: Table with the facet and receptacle descriptions for the component. 
-- 						   Indexed by the name of the port.
-- Return Value: New LOOP component as specified by the factory's template. Nil if something 
--				 goes wrong.
--
function newComponent(factory, descriptions)
	local instance = factory()
	if not instance then
		return nil
	end
	instance._facetDescs = {}
	instance._receptacleDescs = {}
	instance._receptsByConId = {}
	instance._numConnections = 0
	instance._nextConnId = 0
	instance._maxConnections = 100
	for name, kind in component.ports(instance) do
		if kind == ports.Facet then
			instance._facetDescs[name] = descriptions[name]
			instance._facetDescs[name].facet_ref = oil.newobject(instance[name], 
												   descriptions[name].interface_name)
			instance[name] = instance._facetDescs[name].facet_ref
		elseif kind == ports.Receptacle or IsMultipleReceptacle[kind] then
			if not descriptions[name]._connections then
				descriptions[name]._connections = {}
			end
			descriptions[name]._keys = {}
			instance._receptacleDescs[name] = descriptions[name]
		end
	end
	return instance
end

--------------------------------------------------------------------------------

--
-- Component Class
-- Implementation of the IComponent Interface from scs.idl
--
Component = oo.class{ context = false }

--
-- Description: Does nothing initially. Will probably receive another implementation by the
-- 				application component's developer.
--
function Component:startup()
end

--
-- Description: Does nothing initially. Will probably receive another implementation by the
-- 				application component's developer.
--
function Component:shutdown()
end

--
-- Description: Provides a specific interface's object.
-- Parameter interface: The desired interface.
-- Return Value: The CORBA object that implements the interface. 
--
function Component:getFacet(interface)
	self = self.context
	for name, kind in component.ports(self) do
		if kind == ports.Facet and self._facetDescs[name].interface_name == interface then
			return self[name]
		end
	end
end

--
-- Description: Provides a specific interface's object.
-- Parameter interface: The desired interface's name.
-- Return Value: The CORBA object that implements the interface. 
--
function Component:getFacetByName(name)
	self = self.context
	if component.templateof(self)[name] == ports.Facet then
		return self[name]
	end
end

--------------------------------------------------------------------------------

--
-- Receptacles Class
-- Implementation of the IReceptacles Interface from scs.idl
--
Receptacles = oo.class{ context = false }

--
-- Description: Connects an object to the specified receptacle.
-- Parameter receptacle: The receptacle's name that corresponds to the interface implemented by the
-- 						 provided object.
-- Parameter object: The CORBA object that implements the expected interface.
-- Return Value: The connection's identifier.
--
function Receptacles:connect(receptacle, object)
	if not object then error{ "IDL:scs/core/InvalidConnection:1.0" } end
	self = self.context
	local bindKey = 0
	local port = component.templateof(self)[receptacle]
	if port == ports.Receptacle then
		-- this is a standard receptacle, which accepts only one connection
		if self[receptacle] then
			error{ "IDL:scs/core/AlreadyConnected:1.0" }
		else
			-- this receptacle accepts only one connection
			self[receptacle] = object
		end
	elseif IsMultipleReceptacle[port] then
		-- this receptacle accepts multiple connections
		-- in the case of a HashReceptacle, we must provide an identifier, which will be the 
		-- connection's id.
		-- if it's not a HashReceptacle, it'll ignore the provided identifier
		bindKey = self[receptacle]:__bind(object, (self._nextConnId + 1))
	else
		error{ "IDL:scs/core/InvalidName:1.0" }
	end
	if (self._numConnections <= self._maxConnections) then
		self._numConnections = self._numConnections + 1
		self._nextConnId = self._nextConnId + 1
		self._receptacleDescs[receptacle]._connections[self._nextConnId] = { id = self._nextConnId, 
																			 objref = object }
		self._receptsByConId[self._nextConnId] = self._receptacleDescs[receptacle]
		-- defining size of the table since we cannot use the operator #
		if not self._receptacleDescs[receptacle]._numConnections then
			self._receptacleDescs[receptacle]._numConnections = 0
		end
		self._receptacleDescs[receptacle]._numConnections = self._receptacleDescs[receptacle]._numConnections + 1
		if bindKey > 0 then
			self._receptacleDescs[receptacle]._keys[self._nextConnId] = bindKey
		end
		return self._nextConnId
	end
	error{ "IDL:scs/core/ExceededConnectionLimit:1.0" }
end

--
-- Description: Disconnects an object from a receptacle.
-- Parameter connId: The connection's identifier.
--
function Receptacles:disconnect(connId)
	self = self.context
	receptacle = self._receptsByConId[connId].name
	local port = component.templateof(self)[receptacle]
	if port == ports.Receptacle then
		if self[receptacle] then
			self[receptacle] = nil
		else
			error{ "IDL:scs/core/InvalidConnection:1.0" }
		end
	elseif IsMultipleReceptacle[port] then
		if self[receptacle]:__unbind(self._receptacleDescs[receptacle]._keys[connId]) then
			self._numConnections = self._numConnections - 1
			self._receptacleDescs[receptacle]._connections[connId] = nil
			self._receptsByConId[connId]._connections[connId] = nil
			self._receptacleDescs[receptacle]._keys[connId] = nil
			-- defining size of the table for operator #
			self._receptacleDescs[receptacle]._numConnections = self._receptacleDescs[receptacle]._numConnections - 1
		else
			error{ "IDL:scs/core/InvalidConnection:1.0" }
		end
	else
		error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
	end
end

--
-- Description: Provides information about all the current connections of a receptacle.
-- Parameter receptacle: The receptacle's name.
-- Return Value: All current connections of the specified receptacle.
--
function Receptacles:getConnections(receptacle)
	self = self.context
	if self.context._receptacleDescs[receptacle] then
		return self._receptacleDescs[receptacle]._connections
	end
	error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
end

--------------------------------------------------------------------------------

--
-- MetaInterface Class
-- Implementation of the IMetaInterface Interface from scs.idl
--
MetaInterface = oo.class{ context = false }

--
-- Description: Provides descriptions for one or more ports.
-- Parameter portType: Type of the port. May be facet or receptacle.
-- Parameter selected: Names of the ports. If nil, descriptions for all ports of the type will be
--					   returned.
-- Return Value: The descriptions that apply.
--
function MetaInterface:getDescriptions(portType, selected)
	self = self.context
	if not selected then
		if portType == "receptacle" then
			return self._receptacleDescs
		elseif portType == "facet" then
			return self._facetDescs
		end
	end
	local descs = {}
	for _, name in ipairs(selected) do
		if portType == "receptacle" then
			if self._receptacleDescs[name] then
				descs[name] = self._receptacleDescs[name]
			else
				error{ "IDL:scs/core/InvalidName:1.0", name = name }
			end
		elseif portType == "facet" then
			if self._facetDescs[name] then
				descs[name] = self._facetDescs[name]
			else
				error{ "IDL:scs/core/InvalidName:1.0", name = name }
			end
		end
	end
	return descs
end


--
-- Description: Provides descriptions for all the facets.
-- Return Value: The descriptions.
--
function MetaInterface:getFacets()
	return self:getDescriptions("facet")
end

--
-- Description: Provides descriptions for one or more facets.
-- Parameter names: Names of the facets.
-- Return Value: The descriptions that apply.
--
function MetaInterface:getFacetsByName(names)
	return self:getDescriptions("facet", names)
end

--
-- Description: Provides descriptions for all the receptacles.
-- Return Value: The descriptions.
--
function MetaInterface:getReceptacles()
	return self:getDescriptions("receptacle")
end

--
-- Description: Provides descriptions for one or more receptacles.
-- Parameter names: Names of the receptacles.
-- Return Value: The descriptions that apply.
--
function MetaInterface:getReceptaclesByName(names)
	return self:getDescriptions("receptacle", names)
end

--------------------------------------------------------------------------------

--
-- Util Class
-- Implementation of the utilitary class. It's use is not mandatory.
--
Utils = oo.class{ 	verbose 	= false,
					fileVerbose = false,
					newLog		= true,
					fileName 	= "",
				}

--
-- Description: Prints a message to the standard output and/or to a file.
-- Parameter message: Message to be delivered.
--
function Utils:verbosePrint(message)
	if self.verbose then
		print(message)
	end
	if self.fileVerbose then
		local f = assert(io.open("../../../../logs/lua/"..self.fileName.."/"..self.fileName..".log",
								 "a"))
		if self.newLog then
			f:write("\n-----------------------------------------------------\n")
			f:write(os.date().." "..os.time().."\n")
			self.newLog = false
		end
		f:write(message.."\n")
		f:close()
	end
end	

--
-- Description: Reads a file with properties and store them at a table.
-- Parameter t: Table that will receive the properties.
-- Parameter file: File to be read.
--
function Utils:readProperties (t, file)
	local f = assert(io.open(file, "r"), "Error opening properties file!")
	while true do
		prop = f:read("*line")
		if prop == nil then
			break
		end
		-- substitutes spaces for nothing
		local line = string.gsub(prop, " ", "")
		local i = string.find(line, "=")
		self:verbosePrint("SCS::Utils::ReadProperties : Line: " .. line)
		if i ~= 1 then
			t[string.sub(line, 1, i - 1)] = string.sub(line, i + 1, string.len(line))
		end
	end
	f:close()
end

--
-- Description: Prints a table recursively.
-- 
function Utils:print_r (t, indent, done)
	done = done or {}
	indent = indent or 0
	if type(t) == "table" then
		for key, value in pairs (t) do
			io.write(string.rep (" ", indent)) -- indent it
			if type (value) == "table" and not done [value] then
			  done [value] = true
			  io.write(string.format("[%s] => table\n", tostring (key)));
			  io.write(string.rep (" ", indent+4)) -- indent it
			  io.write("(\n");
			  self:print_r (value, indent + 7, done)
			  io.write(string.rep (" ", indent+4)) -- indent it
			  io.write(")\n");
			else
			  io.write(string.format("[%s] => %s\n", tostring (key),tostring(value)))
			end
		end
	else
		io.write(t .. "\n")
	end
end

--
-- Description: Converts a table with an alphanumeric indice to an array.
-- Parameter message: Table to be converted.
-- Return Value: The array.
--
function Utils:convertToArray(inputTable)
	self:verbosePrint("SCS::Utils::ConvertToArray")
	local outputArray = {}
	local i = 1
	for index, item in pairs(inputTable) do
--		table.insert(outputArray, item)
		if index ~= "n" then
			outputArray[i] = item
			i = i + 1
		end
	end
	self:verbosePrint("SCS::Utils::ConvertToArray : Finished.")
	return outputArray
end

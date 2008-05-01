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
local table			= table

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
function newComponent(factory, descriptions, componentId)
 	for name, impl in pairs(factory) do
 		impl.context = false
 	end
	local instance = factory()
	if not instance then
		return nil
	end
  instance._componentId = componentId
	instance._facetDescs = {}
	instance._receptacleDescs = {}
	instance._receptsByConId = {}
	instance._numConnections = 0
	instance._nextConnId = 0
	instance._maxConnections = 100
	for name, kind in component.ports(instance) do
		if kind == ports.Facet then
			instance._facetDescs[name] = {}
			instance._facetDescs[name].name = descriptions[name].name
			instance._facetDescs[name].interface_name = descriptions[name].interface_name
			instance._facetDescs[name].facet_ref = oil.newobject(instance[name], 
												   descriptions[name].interface_name)
			instance[name] = instance._facetDescs[name].facet_ref
		elseif kind == ports.Receptacle or IsMultipleReceptacle[kind] then
			instance._receptacleDescs[name] = {}
			instance._receptacleDescs[name].name = descriptions[name].name
			instance._receptacleDescs[name].interface_name = descriptions[name].interface_name
			instance._receptacleDescs[name].is_multiplex = descriptions[name].is_multiplex
			instance._receptacleDescs[name].connections = descriptions[name].connections or {}
			instance._receptacleDescs[name]._keys = {}
		end
	end
	return instance
end

--------------------------------------------------------------------------------

--
-- Component Class
-- Implementation of the IComponent Interface from scs.idl
--
Component = oo.class{}

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

--
-- Description: Provides its own componentId (name and version).
-- Return Value: The componentId. 
--
function Component:getComponentId()
    return self.context._componentId
end

--------------------------------------------------------------------------------

--
-- Receptacles Class
-- Implementation of the IReceptacles Interface from scs.idl
--
Receptacles = oo.class{}

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

	if (self._numConnections > self._maxConnections) then
		error{ "IDL:scs/core/ExceededConnectionLimit:1.0" }
	end

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
		error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
	end
	
	self._numConnections = self._numConnections + 1
	self._nextConnId = self._nextConnId + 1
	self._receptacleDescs[receptacle].connections[self._nextConnId] = { id = self._nextConnId, 
																		 objref = object }
	self._receptsByConId[self._nextConnId] = self._receptacleDescs[receptacle]
	-- defining size of the table since we cannot use the operator #
	if not self._receptacleDescs[receptacle]._numConnections then
		self._receptacleDescs[receptacle]._numConnections = 0
	end
	self._receptacleDescs[receptacle]._numConnections = 
							self._receptacleDescs[receptacle]._numConnections + 1
	if bindKey > 0 then
		self._receptacleDescs[receptacle]._keys[self._nextConnId] = bindKey
	end
	return self._nextConnId
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
		if not self[receptacle]:__unbind(self._receptacleDescs[receptacle]._keys[connId]) then
			error{ "IDL:scs/core/InvalidConnection:1.0" }
		end
	else
		error{ "IDL:scs/core/NoConnection:1.0" }
	end
	self._numConnections = self._numConnections - 1
	self._receptacleDescs[receptacle].connections[connId] = nil
	self._receptsByConId[connId].connections[connId] = nil
	self._receptacleDescs[receptacle]._keys[connId] = nil
	-- defining size of the table for operator #
	self._receptacleDescs[receptacle]._numConnections = 
							self._receptacleDescs[receptacle]._numConnections - 1
end

--
-- Description: Provides information about all the current connections of a receptacle.
-- Parameter receptacle: The receptacle's name.
-- Return Value: All current connections of the specified receptacle.
--
function Receptacles:getConnections(receptacle)
	self = self.context
	if self._receptacleDescs[receptacle] then
		return Utils:convertToArray(self._receptacleDescs[receptacle].connections)
	end
	error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
end

--------------------------------------------------------------------------------

--
-- MetaInterface Class
-- Implementation of the IMetaInterface Interface from scs.idl
--
MetaInterface = oo.class{}

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
			local descs = {}
			for receptacle, desc in pairs(self._receptacleDescs) do
				local connsArray = Utils:convertToArray(desc.connections)
				local newDesc = {}
				newDesc.name = desc.name
				newDesc.interface_name = desc.interface_name
				newDesc.is_multiplex = desc.is_multiplex
				newDesc.connections = connsArray
				table.insert(descs, newDesc)
			end
			return descs
		elseif portType == "facet" then
			return Utils:convertToArray(self._facetDescs)
		end
	end
	local descs = {}
	for _, name in ipairs(selected) do
		if portType == "receptacle" then
			if self._receptacleDescs[name] then
				local connsArray = Utils:convertToArray(self._receptacleDescs[name].connections)
				local newDesc = {}
				newDesc.name = self._receptacleDescs[name].name
				newDesc.interface_name = self._receptacleDescs[name].interface_name
				newDesc.is_multiplex = self._receptacleDescs[name].is_multiplex
				newDesc.connections = connsArray
				table.insert(descs, newDesc)
			else
				error{ "IDL:scs/core/InvalidName:1.0", name = name }
			end
		elseif portType == "facet" then
			if self._facetDescs[name] then
				table.insert(descs, self._facetDescs[name])
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
-- Interceptor Manager Class
--
-- Implementation of interceptor manager, used to allow the existence of 
-- more than one interceptor for each port of a component.
-- The actual implementation of interception in LOOP allow the insertion of
-- only one interceptor for each port.
--

local InterceptorManager = oo.class{}

--
-- Description: Initialization method
-- Return Value: A new InterceptorManager object
--
function InterceptorManager:__init(context)
    local object = oo.rawnew(self, {})
    object._interceptors = {}
    object._interceptorId = 0
    object._size = 0
    return object
end

--
-- Description: Get size of interceptors list
-- Return Value: Size of list
--
function InterceptorManager:getSize()
    return self._size
end

--
-- Description: Adds an interceptor
-- Parameter iceptor: Interceptor to be added
-- Return Value: The id of the added interceptor or '-1' in case of interceptor doesn't
--               provide after or before methods implementation (wrong implementation)
--
function InterceptorManager:addInterceptor( iceptor )  
    -- chencking iceptor
    if type(iceptor.before) ~= "function" and type(iceptor.after) ~= "function" then
        -- Does not implement any necessary function: 'before' or 'after'.
        --print("WARNING: Invalid interceptor to addInterceptor. Interceptor not added.")
        return -1
    end
    
    -- adding interceptor to list of interceptors
    self._size = self._size + 1
    self._interceptorId = self._interceptorId + 1
    self._interceptors[self._interceptorId] = { before  = iceptor.before, 
                                                after   = iceptor.after }
    return self._interceptorId
end

--
-- Description: Removes an interceptor
-- Parameter id: Id of interceptor to be removed
-- Return Value: True if remoed and false if interceptor doesn't exist
--
function InterceptorManager:removeInterceptor( id )
    -- removing interceptor from list of interceptors
    if self._interceptors[id] == nil then
        --print("WARNING: Invalid id to removeInterceptor.")
        return false
    else
        self._interceptors[id] = nil
        self._size = self._size - 1
        return true
    end
end

--
-- Description: Calls every "before" method from all interceptors that implement it
-- Parameter request: Request table.
-- Parameter ...: Parameters sent to intercepted method
-- Return Value: Values that will be used as the parameters of the actual event being intercepted
--
function InterceptorManager:before( request, ... )
    -- calling before methods for each interceptor
    for _, iceptor in pairs(self._interceptors) do
        if type(iceptor.before) == "function" then
            iceptor.before( self.context, request, ... )
        end
    end
    return ...
end

--
-- Description: Calls every "after" method from all interceptors that implement it
-- Parameter request: Request table.
-- Parameter ...: Parameters sent to intercepted method
-- Return Value: Values that will be used as the parameters of the actual event being intercepted
--
function InterceptorManager:after( request, ... )
    -- calling after methods for each interceptor
    for _, iceptor in pairs(self._interceptors) do
        if type(iceptor.after) == "function" then
            iceptor.after( self.context, request, ... )
        end
    end
    return ...
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
		self:verbosePrint("SCS::Utils::ReadProperties : Line: " .. prop)
		local a,b = string.match(prop, "%s*(%S*)%s*[=]%s*(.*)%s*")
		if a ~= nil then
			t[a] = b
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

--
-- Description: Converts a string to a boolean.
-- Parameter str: String to be converted.
-- Return Value: The boolean.
--
function Utils:toBoolean(inputString)
    self:verbosePrint("SCS::Utils::StringToBoolean")
    local inputString = tostring(inputString)
    local result = false
    if string.find(inputString, "true") and string.len(inputString) == 4 then
        result = true
    end
    self:verbosePrint("SCS::Utils::StringToBoolean : " .. tostring(result) .. ".")
    self:verbosePrint("SCS::Utils::StringToBoolean : Finished.")
    return result
end

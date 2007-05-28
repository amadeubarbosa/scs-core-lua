local verbose = require "oil.verbose"



local error			= error
local getmetatable	= getmetatable
local ipairs		= ipairs
local module		= module
local require		= require
local tonumber		= tonumber
local tostring		= tostring
local type			= type
local io 			= io
local string		= string
local assert		= assert
local os			= os
local print			= print

local oo        = require "loop.base"
local comp		= require "loop.component.base"
local ports     = require "loop.component.base"

local IsMultipleReceptacle = 
{
	[ports.HashReceptacle] = true,
	[ports.ListReceptacle] = true,
	[ports.SetReceptacle] = true,
}
--------------------------------------------------------------------------------

module "scs"

--------------------------------------------------------------------------------

Component = oo.class{ 	context 		= false, 
						__idltype 		= "IDL:SCS/IComponent:1.0", 
						facetDescripts	= {},
						receptDescripts	= {},
						receptByConId 	= {},
						nextConnId		= 0,
						numConnections 	= 0,
						maxConnections 	= 100,
					}

Component.facetDescripts["IDL:SCS/IComponent:1.0"]		= {}
Component.facetDescripts["IDL:SCS/IReceptacles:1.0"]	= {}
Component.facetDescripts["IDL:SCS/IMetaInterface:1.0"]	= {}

Component.facetDescripts["IDL:SCS/IComponent:1.0"].name 			= "IComponent"
Component.facetDescripts["IDL:SCS/IComponent:1.0"].interface_name 	= "IDL:SCS/IComponent:1.0"
Component.facetDescripts["IDL:SCS/IComponent:1.0"].facet_ref		= 

function Component:startup()
end

function Component:shutdown()
end

function Component:getFacet(interface)
	self = self.context
	for name, kind in comp.ports(self) do
		if kind == ports.Facet and self[name].__idltype == interface then
			return self[name]
		end
	end
end

function Component:getFacetByName(name)
	self = self.context
	if comp.templateof(self)[name] == ports.Facet then
		return self[name]
	end
end

--------------------------------------------------------------------------------

Receptacles = oo.class{ context = false, __idltype = "IDL:SCS/IReceptacles:1.0" }

function Receptacles:connect(receptacle, object)
	if not object then error{ "IDL:SCS/InvalidConnection:1.0" } end
	self = self.context
	local bindKey = 0
	local port = comp.templateof(self)[receptacle]
	if port == ports.Receptacle then
		-- this is a standard receptacle, which accepts only one connection
		if self[receptacle] then
			error{ "IDL:SCS/AlreadyConnected:1.0" }
		else
			-- this receptacle accepts only one connection
			self[receptacle] = object
		end
	elseif IsMultipleReceptacle[port] then
		-- this receptacle accepts multiple connections
		bindKey = self[receptacle]:__bind(object)
	else
		error{ "IDL:SCS/InvalidName:1.0" }
	end
	if (self.IComponent.numConnections < self.IComponent.maxConnections) then
		self.IComponent.numConnections = self.IComponent.numConnections + 1
		self.IComponent.nextConnId = self.IComponent.nextConnId + 1
		self.IComponent.receptDescripts[receptacle].connections[nextConnId] = {	id = nextConnId, 
																				objref = object}
		self.IComponent.receptByConId[nextConnId] = self.IComponent.receptDescripts[receptacle].connections[nextConnId]
		if bindKey > 0 then
			self.IComponent.receptDescripts[receptacle].keys[nextConnId] = bindKey
		end
		return nextConnId
	end
	error{ "IDL:SCS/ExceededConnectionLimit:1.0" }
end

function Receptacles:disconnect(connId)
	self = self.context
	if self.IComponent.receptByConId[connId] then
		local receptacle = self.IComponent.receptByConId[connId]
		local receptInterfName = receptacle.interface_name
		local port = comp.templateof(self)[receptInterfName]
		self.IComponent.receptDescripts[receptInterfName].connections[connId] = nil
		receptacle.connections[connId] = nil
		receptacle.keys[connId] = nil
		self.IComponent.numConnections = self.IComponent.numConnections - 1
		if port == ports.Receptacle then
			-- this is a standard receptacle, which accepts only one connection
			self[receptInterfName] = nil
		elseif IsMultipleReceptacle[port] then
			-- this receptacle accepts multiple connections
			local key = receptacle.keys[connId]
			if self[receptInterfName].__get(key) then
				self[receptInterfName]:__unbind(key)
			else
				error{ "IDL:SCS/InvalidConnection:1.0" }
			end
		else
			error{ "IDL:SCS/InvalidConnection:1.0" }
		end
	end
	error{ "IDL:SCS/NoConnection:1.0" }
end

function Receptacles:getConnections(receptacle)
	local receptDesc = self.context.IComponent.receptDescripts[receptacle]
	if receptDesc then
		return receptDesc.connections
	end
	error{ "IDL:SCS/InvalidName:1.0" }
end

--------------------------------------------------------------------------------

MetaInterface = oo.class{ context = false, __idltype = "IDL:SCS/IMetaInterface:1.0" }

function MetaInterface:getFacets(selected)
	self = self.context
	local facets = {}
	for name, kind in comp.ports(self) do
		if kind == ports.Facet and (not selected or selected[name]) then
			local object = self[name]
			local meta = getmetatable(object)
			facets[facets+1] = {
				name = name,
				interface_name = meta and meta.__idltype,
				facet_ref = object,
			}
		end
	end
	return facets
end

function MetaInterface:getFacetsByName(names)
	for _, name in ipairs(names) do
		names[name] = true
	end
	return self:getFacets(names)
end

function MetaInterface:getReceptacles(selected)
	self = self.context
	local receptacles = {}
	for name, kind in comp.ports(self) do
		if kind == ports.Receptacles and (not selected or selected[name]) then
			local is_multiple
			local connections = self[name]
			if connections then
				is_multiple = connections.__all
				connections = Receptacles.getConnections(self, name)
			end
			receptacles[receptacles+1] = {
				name = name,
				interface_name = "CORBA::Object",
				is_multiple = is_multiple,
				connections = connections or {},
			}
		end
	end
	return receptacles
end

function MetaInterface:getReceptaclesByName()
	for _, name in ipairs(names) do
		names[name] = true
	end
	return self:getReceptacles(names)
end

--------------------------------------------------------------------------------

Utils = oo.class{}
Utils.verbose = false
Utils.fileVerbose = false
Utils.filename = ""

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
		self:verbosePrint("SCSUtils::ReadProperties : Line: " .. line)
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
-- Description: Recebe uma mensagem e imprime se o verbose estiver ativado.
-- Parameter message: Mensagem.
--
function Utils:verbosePrint(message)
	if self.verbose then
		print(message)
	end
	if self.fileVerbose then
		local f = assert(io.open("logs/"..self.filename..".log", "a"))
		if self.verbose == false then
			self.verbose = true
			f:write("\n-----------------------------------------------------\n")
			f:write(os.date().." "..os.time().."\n")
		end
		f:write(message.."\n")
		f:close()
	end
end	

--
-- Description: Como quando retornamos via corba uma tabela 
-- com indice alfanumerico precisamos converter as nossas tabelas para esse formato.
-- Parameter message: Tabela a ser convertida.
-- Return Value: a tabela em formato de array.
--
function Utils:convertToArray(inputTable)
	self:verbosePrint("SCSUtils::ConvertToArray")
	local outputArray = {}
	local i = 1
	for index, item in pairs(inputTable) do
--		table.insert(outputArray, item)
		if index ~= "n" then
			outputArray[i] = item
			i = i + 1
		end
	end
	self:verbosePrint("SCSUtils::ConvertToArray : Finished.")
	return outputArray
end

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

--------------------------------------------------------------------------------

module "core.scs"

--------------------------------------------------------------------------------

local IsMultipleReceptacle = {
	[ports.HashReceptacle] = true,
	[ports.ListReceptacle] = true,
	[ports.SetReceptacle] = true,
}

function newComponent(template, descriptions)
	local base = {}
	base.facetDescs = {}
	base.receptacleDescs = {}
	base.receptsByConId = {}
	base.numConnections = 0
	base.nextConnId = 0
	base.maxConnections = 100
	for name, kind in component.ports(template) do
		if kind == ports.Facet then
			base[name] = descriptions[name].facet_ref
			base.facetDescs[name] = descriptions[name]
		elseif kind == ports.Receptacle or IsMultipleReceptacle[kind] then
			if not descriptions[name].connections then
				descriptions[name].connections = {}
--				descriptions[name].keys = {}
			end
			base.receptacleDescs[name] = descriptions[name]
		end
	end
	return template(base)
end

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

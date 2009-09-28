--
-- SCS
-- base.lua
-- Description: Basic SCS classes and API
-- Version: 1.0
--

local oo        = require "loop.base"
local component = require "loop.component.base"
local ports     = require "loop.component.base"
local oil       = require "oil"
local utils     = require "scs.core.utils"
utils = utils.Utils()

-- If we stored a broker instance previously, use it. If not, use the default broker
local _orb = oil.orb or oil.init()

local error         = error
local getmetatable  = getmetatable
local ipairs        = ipairs
local module        = module
local require       = require
local tonumber      = tonumber
local tostring      = tostring
local type          = type
local io            = io
local string        = string
local assert        = assert
local os            = os
local print         = print
local pairs         = pairs
local table         = table

--------------------------------------------------------------------------------

module "scs.core.base"

--------------------------------------------------------------------------------

local ComponentContext = oo.class{}
function ComponentContext:__init()
  local inst = oo.rawnew(self, {})
  return inst
end

local function _get_component(self)
  return self.context.IComponent
end

local function fillBasicDescriptions(facetDescs)
  local hasIC = false
  local hasIR = false
  local hasIM = false
  for name, desc in pairs(facetDescs) do
    if desc.interface_name == "IDL:scs/core/IComponent:1.0" then
      hasIC = true
    elseif desc.interface_name == "IDL:scs/core/IReceptacles:1.0" then
      hasIR = true
    elseif desc.interface_name == "IDL:scs/core/IMetaInterface:1.0" then
      hasIM = true
    end
  end
  -- did not include IComponent
  if not hasIC then
    -- checks if the name IComponent can be used
    if facetDescs.IComponent then
      return false
    end
    facetDescs.IComponent = {}
    facetDescs.IComponent.name                      = "IComponent"
    facetDescs.IComponent.interface_name            = "IDL:scs/core/IComponent:1.0"
    facetDescs.IComponent.class                     = Component
  end
  -- did not include IReceptacles
  if not hasIR then
    -- checks if the name IReceptacles can be used
    if facetDescs.IReceptacles then
      return false
    end
    facetDescs.IReceptacles = {}
    facetDescs.IReceptacles.name                    = "IReceptacles"
    facetDescs.IReceptacles.interface_name          = "IDL:scs/core/IReceptacles:1.0"
    facetDescs.IReceptacles.class                   = Receptacles
  end
  -- did not include IMetaInterface
  if not hasIM then
    -- checks if the name IMetaInterface can be used
    if facetDescs.IMetaInterface then
      return false
    end
    facetDescs.IMetaInterface = {}
    facetDescs.IMetaInterface.name                  = "IMetaInterface"
    facetDescs.IMetaInterface.interface_name        = "IDL:scs/core/IMetaInterface:1.0"
    facetDescs.IMetaInterface.class                 = MetaInterface
  end
  return true
end

--
-- Description: Creates a new component instance and prepares it to be used in the system.
-- Parameter facetDescs: Table with the facet descriptions for the component.
-- Parameter descriptions: Table with the receptacle descriptions for the component.
-- Parameter orb: Optional. The orb which will be used to create servants and other tasks.
-- Return Value: New SCS component as specified by the descriptions. Nil if something goes wrong.
--
function newComponent(facetDescs, receptDescs, componentId, orb)
  if not componentId then
    return nil, "ERROR: Missing ComponentId parameter"
  end
  if not facetDescs then
    facetDescs = {}
  end
  if not receptDescs then
    receptDescs = {}
  end
  if not orb then
    orb = _orb
  end
  -- template and factory objects are always re-created on purpose because
  -- component files and descriptions may have changed.
  -- in the future, better deployment features will be implemented.
  local template = {}
  local factory = {}
  -- inserts IComponent, IReceptacles and IMetaInterface facets if needed
  if not fillBasicDescriptions(facetDescs) then
    return nil, "ERROR: Couldn't add basic facets (IComponent, IReceptacles and IMetaInterface)"
  end
  -- first item (key "1") in factory will be used as the component holder
  table.insert(factory, ComponentContext)
  for name, desc in pairs(facetDescs) do
    template[name] = ports.Facet
    desc.class.context = false
    factory[name] = desc.class
    if not factory[name] then
      return nil, "ERROR: Missing the implementation of the facet "..name
    end
  end
  template = component.Template(template)
  factory = template(factory)
  local instance = factory()
  if not instance then
    return nil, "ERROR: The load of the facets failed"
  end
  instance._orb = orb
  instance._componentId = componentId
  instance._facetDescs = {}
  instance._receptacleDescs = {}
  instance._receptsByConId = {}
  for name, desc in pairs(facetDescs) do
    instance._facetDescs[name] = {}
    instance._facetDescs[name].name = desc.name
    instance._facetDescs[name].interface_name = desc.interface_name
    instance._facetDescs[name].key = desc.key
    instance._facetDescs[name].facet_ref = orb:newservant(instance[name], desc.key, desc.interface_name)
    instance[name] = instance._facetDescs[name].facet_ref
  end
  for name, desc in pairs(receptDescs) do
    instance._receptacleDescs[name] = {}
    instance._receptacleDescs[name].name = desc.name
    instance._receptacleDescs[name].interface_name = desc.interface_name
    instance._receptacleDescs[name].is_multiplex = desc.is_multiplex
    instance._receptacleDescs[name].connections = desc.connections or {}
    if desc.is_multiplex then
      instance[name] = instance._receptacleDescs[name].connections
    end
  end
  for name, desc in pairs(facetDescs) do
    instance._facetDescs[name].facet_ref._component = _get_component
  end
  return instance
end

--
-- Description: Re-creates the component's facets. Useful for re-enabling a component after a shutdown.
-- Parameter instance: Component instance.
--
function restoreFacets(instance)
  for name, kind in component.ports(instance) do
    if kind == ports.Facet and name ~= "IComponent" then
      instance._facetDescs[name].facet_ref = instance._orb:newservant(instance[name], descriptions[name].key,
                           descriptions[name].interface_name)
      instance[name] = instance._facetDescs[name].facet_ref
    end
  end
end

--------------------------------------------------------------------------------

--
-- Component Class
-- Implementation of the IComponent Interface from scs.idl
--
Component = oo.class{}

function Component:__init()
  return oo.rawnew(self, {})
end

--
-- Description: Does nothing initially. Will probably receive another implementation by the
--        application component's developer.
--
function Component:startup()
end

--
-- Description: Does nothing initially. Will probably receive another implementation by the
--        application component's developer.
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
  for name, desc in pairs(self._facetDescs) do
    if desc.interface_name == interface then
      return desc.facet_ref
    end
  end
end

--
-- Description: Provides a specific interface's object.
-- Parameter interface: The desired interface's name.
-- Return Value: The CORBA object that implements the interface. 
--
function Component:getFacetByName(name)
  return self.context[name]
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

function Receptacles:__init()
  return oo.rawnew(self, {_nextConnId = 0, _maxConnections = 100, _numConnections = 0})
end

--
-- Description: Connects an object to the specified receptacle.
-- Parameter receptacle: The receptacle's name that corresponds to the interface implemented by the
--             provided object.
-- Parameter object: The CORBA object that implements the expected interface.
-- Return Value: The connection's identifier.
--
function Receptacles:connect(receptacle, object)
  local context = self.context
  local desc = context._receptacleDescs[receptacle]
  if not desc then 
    error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
  end
  if not object then 
    error{ "IDL:scs/core/InvalidConnection:1.0" }
  end
  local status, err = oil.pcall(object._is_a, object, desc.interface_name)
  if not (status and err) then
    error{ "IDL:scs/core/InvalidConnection:1.0" }
  end
  object = context._orb:narrow(object, desc.interface_name)

  if (self._numConnections > self._maxConnections) then
    error{ "IDL:scs/core/ExceededConnectionLimit:1.0" }
  end

  -- here we can find out the number of connections with the '#' operator
  -- because there'll always be only one connection.
  if not desc.is_multiplex and #(desc.connections) > 0 then
    error{ "IDL:scs/core/AlreadyConnected:1.0" }
  end
  
  self._nextConnId = self._nextConnId + 1
  desc.connections[self._nextConnId] = {id = self._nextConnId, objref = object}
  context._receptsByConId[self._nextConnId] = desc
  -- it's not possible to use the '#' operator to find out the number of
  -- connections. There are 2 causes:
  -- a) If a connection(ex: connId 3) is unmade the index sequence gets broken
  --    (i.e. 1, 2, 4, 5, ...) and the operator may return a wrong size.
  -- b) The number of connections is per component, not per receptacle.
  self._numConnections = self._numConnections + 1

  -- helping the user
  if not desc.is_multiplex then
    context[receptacle] = object
  end

  return self._nextConnId
end

--
-- Description: Disconnects an object from a receptacle.
-- Parameter connId: The connection's identifier.
--
function Receptacles:disconnect(connId)
  local context = self.context
  local desc = context._receptsByConId[connId]

  if not context._receptacleDescs[desc.name] then
    error{ "IDL:scs/core/NoConnection:1.0" }
  end

  if not desc then
    error{ "IDL:scs/core/InvalidConnection:1.0" }
  end

  if not desc.is_multiplex then
    context[desc.name] = nil
  end

  desc.connections[connId] = nil
  self._numConnections = self._numConnections - 1
end

--
-- Description: Provides information about all the current connections of a receptacle.
-- Parameter receptacle: The receptacle's name.
-- Return Value: All current connections of the specified receptacle.
--
function Receptacles:getConnections(receptacle)
  self = self.context
  if self._receptacleDescs[receptacle] then
    return utils:convertToArray(self._receptacleDescs[receptacle].connections)
  end
  error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
end

--------------------------------------------------------------------------------

--
-- MetaInterface Class
-- Implementation of the IMetaInterface Interface from scs.idl
--
MetaInterface = oo.class{}

function MetaInterface:__init()
  return oo.rawnew(self, {})
end

--
-- Description: Provides descriptions for one or more ports.
-- Parameter portType: Type of the port. May be facet or receptacle.
-- Parameter selected: Names of the ports. If nil, descriptions for all ports of the type will be
--             returned.
-- Return Value: The descriptions that apply.
--
function MetaInterface:getDescriptions(portType, selected)
  self = self.context
  if not selected then
    if portType == "receptacle" then
      local descs = {}
      for receptacle, desc in pairs(self._receptacleDescs) do
        local connsArray = utils:convertToArray(desc.connections)
        local newDesc = {}
        newDesc.name = desc.name
        newDesc.interface_name = desc.interface_name
        newDesc.is_multiplex = desc.is_multiplex
        newDesc.connections = connsArray
        table.insert(descs, newDesc)
      end
      return descs
    elseif portType == "facet" then
      return utils:convertToArray(self._facetDescs)
    end
  end
  local descs = {}
  for _, name in ipairs(selected) do
    if portType == "receptacle" then
      if self._receptacleDescs[name] then
        local connsArray = utils:convertToArray(self._receptacleDescs[name].connections)
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

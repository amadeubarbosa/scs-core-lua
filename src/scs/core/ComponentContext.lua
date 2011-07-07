--
-- SCS
-- ComponentContext.lua
-- Description: Basic SCS classes and API
-- Version: 1.0
--

local oo            = require "loop.base"
local comp          = require "loop.component.base"
local ports         = require "loop.component.base"
local oil           = require "oil"
local Component     = require "scs.core.Component"
local Receptacles   = require "scs.core.Receptacles"
local MetaInterface = require "scs.core.MetaInterface"
local Log           = require "scs.util.Log"
local utils         = require "scs.core.utils"
utils = utils()

local module = module
local pairs  = pairs
local table  = table
local type   = type
local error  = error
local string = string

--------------------------------------------------------------------------------

module ("scs.core.ComponentContext", oo.class)

--------------------------------------------------------------------------------
local unknownInterfaceErrorMessage = "Unknown interface. Try loading the correspondent IDL file or code on the ORB first."

local function addBasicFacet(self, name, interface, object, key)
  local errMsg = "A basic SCS interface is not known by the ORB. Please load scs.idl file on the ORB first."
  local success, err = oil.pcall(self.addFacet,
                                 self,
                                 name,
                                 interface,
                                 object,
                                 key)
  if not success then
    if string.find(err, unknownInterfaceErrorMessage) then
      error(errMsg)
    else
      error(err)
    end
  end
end

local function addBasicFacets(self, basicKeys)
  local basicKeys = basicKeys or {}
  addBasicFacet(self, utils.ICOMPONENT_NAME, utils.ICOMPONENT_INTERFACE,
    Component(), basicKeys.IComponent)
  addBasicFacet(self, utils.IRECEPTACLES_NAME, utils.IRECEPTACLES_INTERFACE,
    Receptacles(), basicKeys.IReceptacles)
  addBasicFacet(self, utils.IMETAINTERFACE_NAME, utils.IMETAINTERFACE_INTERFACE,
    MetaInterface(), basicKeys.IMetaInterface)
end

local function _get_component(self)
  return self.context.IComponent
end

local function deactivateFacet(self, name)
  self._orb:deactivate(self._facets[name].facet_ref)
end

local function putFacet(self, name, interface, implementation, key)
  local impl = implementation
  if type(impl._component) ~= "function" then
    impl._component = _get_component
  end
  impl.context = impl.context or self
  local success, servant = oil.pcall(self._orb.newservant,
                                     self._orb,
                                     impl,
                                     key,
                                     interface)
  if not success then
    if servant[1] == "IDL:omg.org/CORBA/INTERNAL:1.0" and servant.message == "unknown interface" then
      error(unknownInterfaceErrorMessage)
    else
      error(servant)
    end
  end
  self._facets[name] = {name = name, interface_name = interface,
    facet_ref = servant, key = key, implementation = impl}
  self[name] = servant
  local msg = "Facet " .. name .. " with interface " .. interface .. " was added to the component."
  if key then
    msg = msg .. " The key " .. key .. " was used."
  end
  Log:scs(msg)
end

function __init(self, orb, id, basicKeys)
  if not id then
    return nil, "ERROR: Missing ComponentId parameter"
  end
  local instance = oo.rawnew(self, {_orb = orb or oil.init(), _componentId = id,
    _facets = {}, _receptacles = {}})
  addBasicFacets(instance, basicKeys)
  return instance
end

function getComponentId(self)
  return self._componentId
end

function addFacet(self, name, interface, implementation, key)
  if self._facets[name] ~= nil then
    error("Facet already exists.")
  end
  putFacet(self, name, interface, implementation, key)
end

function updateFacet(self, name, implementation)
  local facet = self._facets[name]
  self:removeFacet(facet.name)
  self:addFacet(name, facet.interface_name, implementation, facet.key)
end

function removeFacet(self, name)
  if self._facets[name] == nil then
    error("Facet does not exist.")
  end
  deactivateFacet(self, name)
  self._facets[name] = nil
  self[name] = nil
  Log:scs("Facet " .. name .. " was removed from the component.")
end

function addReceptacle(self, name, interface, multiplex)
  if self._receptacles[name] ~= nil then
    error("Receptacle already exists.")
  end
  self._receptacles[name] = {name = name, interface_name = interface,
    is_multiplex = multiplex, connections = {}}
  Log:scs("Receptacle " .. name .. " expecting interface " .. interface .. " was added to the component.")
end

function removeReceptacle(self, name)
  self._receptacles[name] = nil
  Log:scs("Receptacle " .. name .. " was removed from the component. If it had active connections, access to them may be lost.")
end

--
-- Description: Activates all of the component's facets.
-- Return value: Table containing the names(indexes) and error messages(values)
--               of the facets that could not be activated.
--
function activateComponent(self)
  local errFacets = {}
  for name, facet in pairs(self._facets) do
    local status, err = oil.pcall(self._orb.newservant, self._orb,
      facet.implementation, facet.key, facet.interface_name)
    if not status then
      errFacets[name] = err
      Log:error("Facet " .. name .. " was not activated. Error: " .. err)
    else
      Log:scs("Facet " .. name .. " was activated.")
    end
  end
  return errFacets
end

--
-- Description: Deactivates all of the component's facets. If a facet is
-- successfully deactivated, its facet_ref field will NOT be set to nil, because
-- it can be reactivated later.
-- Return value: Table containing the names(indexes) and error messages(values)
--               of the facets that could not be deactivated.
--
function deactivateComponent(self)
  local errFacets = {}
  for name, facet in pairs(self._facets) do
    local status, err = oil.pcall(self._orb.deactivate, self._orb,
      facet.facet_ref, facet.interface_name)
    if not status then
      errFacets[name] = err
      Log:error("Facet " .. name .. " was not deactivated. Error: " .. err)
    else
      Log:scs("Facet " .. name .. " was deactivated.")
    end
  end
  return errFacets
end

function getFacets(self)
  return self._facets
end

function getFacetByName(self, name)
  return self._facets[name]
end

function getReceptacles(self)
  return self._receptacles
end

function getReceptacleByName(self, name)
  return self._receptacles[name]
end

function getIComponent(self)
  return self[utils.ICOMPONENT_NAME]
end

function stringifiedComponentId(self)
  return utils:getNameVersion(self._componentId)
end

function getORB(self)
  return self._orb
end

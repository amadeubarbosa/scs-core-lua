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
local utils         = require "scs.core.utils"
utils = utils()

local module = module
local pairs  = pairs
local table  = table
local type   = type

local idlpath = os.getenv("IDL_PATH") or ""

--------------------------------------------------------------------------------

module ("scs.core.ComponentContext", oo.class)

--------------------------------------------------------------------------------

local function _addBasicFacets(self, basicKeys)
  local basicKeys = basicKeys or {}
  self:putFacet(utils.ICOMPONENT_NAME, utils.ICOMPONENT_INTERFACE, Component(),
    basicKeys.IComponent)
  self:putFacet(utils.IRECEPTACLES_NAME, utils.IRECEPTACLES_INTERFACE,
    Receptacles(), basicKeys.IReceptacles)
  self:putFacet(utils.IMETAINTERFACE_NAME, utils.IMETAINTERFACE_INTERFACE,
    MetaInterface(), basicKeys.IMetaInterface)
end

local function _get_component(self)
  return self.context.IComponent
end

function __init(self, orb, id, basicKeys)
  if not id then
    return nil, "ERROR: Missing ComponentId parameter"
  end
  local instance = oo.rawnew(self, {_orb = orb or oil.init(), _componentId = id,
    _facets = {}, _receptacles = {}})
  instance._orb:loadidlfile(idlpath .. "/scs.idl")
  _addBasicFacets(instance, basicKeys)
  return instance
end

function getComponentId(self)
  return self._componentId
end

local function deactivateFacet(self, name)
  self._orb:deactivate(self._facets[name].facet_ref)
end

function putFacet(self, name, interface, implementation, key)
  if type(implementation._component) ~= "function" then
    implementation._component = _get_component
  end
  implementation.context = implementation.context or self
  if self._facets[name] ~= nil then
    deactivateFacet(self, name)
    --TODO: logar que uma faceta foi substituida
  else
    --TODO: logar que uma faceta foi adicionada
  end
  local servant = self._orb:newservant(implementation, key, interface)
  self._facets[name] = {name = name, interface_name = interface,
    facet_ref = servant, key = key, implementation = implementation}
  self[name] = servant
end

function putReceptacle(self, name, interface, multiplex)
  if self._receptacles[name] ~= nil then
    --TODO: logar que um receptaculo foi substituido e todas as suas conexoes, perdidas
  else
    --TODO: logar que um receptaculo foi adicionado
  end
  self._receptacles[name] = {name = name, interface_name = interface,
    is_multiplex = multiplex, connections = {}}
end

function removeFacet(self, name)
  deactivateFacet(self, name)
  self._facets[name] = nil
  self[name] = nil
  --TODO: logar que uma faceta foi removida
end

function removeReceptacle(self, name)
  self._receptacles[name] = nil
  --TODO: logar que um receptaculo foi removido e todas as suas conexoes, perdidas
end

function activateComponent(self)
  local errFacets = {}
  for name, facet in pairs(self._facets) do
    local status, err = oil.pcall(self._orb.newservant, self._orb,
      facet.implementation, facet.key, facet.interface_name)
    --TODO: logar de acordo
    if not status then
      errFacets[name] = err
    end
  end
  return errFacets
end

--TODO: checar se comentario abaixo ainda esta bom.
--
-- Description: Deactivate the component's facets. The facet_ref references
-- remain not null after the call, as to maintain the Lua table reachable.
-- It's the user's responsibility to reactivate the facets when deemed
-- appropriate.
-- Parameter instance: Component instance.
-- Return value: Table containing the names(indexes) and error messages(values)
--               of the facets that could not be deactivated.
--
function deactivateComponent(self)
  local errFacets = {}
  for name, facet in pairs(self._facets) do
    local status, err = oil.pcall(self._orb.deactivate, self._orb,
      facet.facet_ref)
    --TODO: logar de acordo
    if not status then
      errFacets[name] = err
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

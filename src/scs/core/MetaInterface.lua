--
-- SCS
-- metainterface.lua
-- Description: IMetaInterface interface base implementation
-- Version: 1.0
--

local oo    = require "loop.base"
local utils = require "scs.core.utils"
utils = utils()

local pairs  = pairs
local ipairs = ipairs
local error  = error
local table  = table

--------------------------------------------------------------------------------

module ("scs.core.MetaInterface", oo.class)

--------------------------------------------------------------------------------

function __init(self)
  return oo.rawnew(self, {})
end

--
-- Description: Provides descriptions for one or more ports.
-- Parameter portType: Type of the port. May be facet or receptacle.
-- Parameter selected: Names of the ports. If nil, descriptions for all ports of the type will be
--             returned.
-- Return Value: The descriptions that apply.
--
function getDescriptions(self, portType, selected)
  self = self.context
  if not selected then
    if portType == "receptacle" then
      local descs = {}
      for receptacle, desc in pairs(self._receptacles) do
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
      return utils:convertToArray(self._facets)
    end
  end
  local descs = {}
  for _, name in ipairs(selected) do
    if portType == "receptacle" then
      if self._receptacles[name] then
        local connsArray = utils:convertToArray(self._receptacles[name].connections)
        local newDesc = {}
        newDesc.name = self._receptacles[name].name
        newDesc.interface_name = self._receptacles[name].interface_name
        newDesc.is_multiplex = self._receptacles[name].is_multiplex
        newDesc.connections = connsArray
        table.insert(descs, newDesc)
      else
        error{ "IDL:scs/core/InvalidName:1.0", name = name }
      end
    elseif portType == "facet" then
      if self._facets[name] then
        table.insert(descs, self._facets[name])
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
function getFacets(self)
  return self:getDescriptions("facet")
end

--
-- Description: Provides descriptions for one or more facets.
-- Parameter names: Names of the facets.
-- Return Value: The descriptions that apply.
--
function getFacetsByName(self, names)
  return self:getDescriptions("facet", names)
end

--
-- Description: Provides descriptions for all the receptacles.
-- Return Value: The descriptions.
--
function getReceptacles(self)
  return self:getDescriptions("receptacle")
end

--
-- Description: Provides descriptions for one or more receptacles.
-- Parameter names: Names of the receptacles.
-- Return Value: The descriptions that apply.
--
function getReceptaclesByName(self, names)
  return self:getDescriptions("receptacle", names)
end


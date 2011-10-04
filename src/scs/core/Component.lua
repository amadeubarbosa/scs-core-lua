--
-- SCS
-- component.lua
-- Description: IComponent interface base implementation
-- Version: 1.0
--

local oo = require "loop.base"

local pairs = pairs

--------------------------------------------------------------------------------

module ("scs.core.Component", oo.class)

--------------------------------------------------------------------------------

function __new(self)
  return oo.rawnew(self, {})
end

--
-- Description: Does nothing initially. Will probably receive another implementation by the
--        application component's developer.
--
function startup(self)
end

--
-- Description: Does nothing initially. Will probably receive another implementation by the
--        application component's developer.
--
function shutdown(self)
end

--
-- Description: Provides a specific interface's object. If more than one facet
-- implements this interface, the first to be found will be returned.
-- Parameter interface: The desired interface.
-- Return Value: The CORBA object that implements the interface.
--
function getFacet(self, interface)
  self = self.context
  for name, desc in pairs(self._facets) do
    if desc.interface_name == interface then
      return desc.facet_ref
    end
  end
end

--
-- Description: Provides a specific facet's object, specified by name.
-- Parameter interface: The desired facet's name.
-- Return Value: The CORBA object that implements the interface.
--
function getFacetByName(self, name)
  self = self.context
  for _, desc in pairs(self._facets) do
    if desc.name == name then
      return desc.facet_ref
    end
  end
end

--
-- Description: Provides its own componentId.
-- Return Value: The componentId.
--
function getComponentId(self)
    return self.context._componentId
end


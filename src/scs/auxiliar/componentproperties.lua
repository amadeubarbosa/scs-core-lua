--
-- SCS
-- componentproperties.lua
-- Description: Properties class
-- Version: 1.0
--

local oo = require "loop.base"
local Log = require "scs.util.Log"
local utils   = require "scs.core.utils"

local assert = assert

--------------------------------------------------------------------------------
-- ComponentProperties Class
--------------------------------------------------------------------------------

local CpnProperties = oo.class{
  componentName = "",
}

function CpnProperties:__new()
  local inst = oo.rawnew(self, {})
  inst.props = inst.props or {}
  inst.utils = utils()
  return inst
end

function CpnProperties:findProperty(t, name)
  for index, prop in ipairs(t) do
    if prop.name == name then
      return prop
    end
  end
end

--
-- Description: Returns the component's properties.
-- Return Value: Array of properties.
--
function CpnProperties:getProperties()
  Log:info(self.componentName .. "::ComponentProperties::GetProperties")
  local ret = self.utils:convertToArray(self.props)
  Log:info(self.componentName .. "::ComponentProperties::GetProperties : Finished.")
  return ret
end

--
-- Description: Returns one property.
-- Parameter name: Property's name.
-- Return Value: The property structure.
-- Throws: IDL:UndefinedProperty
--
function CpnProperties:getProperty(name)
  Log:info(self.componentName .. "::ComponentProperties::GetProperty")
  Log:info(self.componentName .. "::ComponentProperties::GetProperty : Finished.")
  return self.props[name]
end

--
-- Description: Sets a property, be it already defined or not.
-- Parameter property: The property structure.
--
function CpnProperties:setProperty(property)
  Log:info(self.componentName .. "::ComponentProperties::SetProperty")
  local prop = self.props[property.name]
  if not prop then
    self.props[property.name] = property
  else
    if prop.read_only == true then
      error{"IDL:scs/auxiliar/ReadOnlyProperty:1.0"}
    else
      prop.value = property.value
      prop.read_only = self.utils:toBoolean(property.read_only)
    end
  end
  Log:info(self.componentName .. "::ComponentProperties::SetProperty : Finished.")
end

--------------------------------------------------------------------------------

local module = {
  CpnProperties = CpnProperties
}

return module

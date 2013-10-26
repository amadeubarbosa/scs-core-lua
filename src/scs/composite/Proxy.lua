
local ComponentContext = require "scs.core.ComponentContext"
local compositeIdl = require "scs.composite.Idl"
local tabop = require "loop.table"
local memoize = tabop.memoize
local ISuperComponent = require "scs.composite.ISuperComponent"
local utils = require "scs.composite.Utils"
local Log = require "scs.util.Log"
utils = utils()
local oo = require "loop.simple"
local class = oo.class
local Wrapper = require "loop.object.Wrapper"

------------------------------------------------------------------------


local ProxyComponent = class({}, ComponentContext)
local FacetProxy = class()
local Proxy = { proxyComponent = ProxyComponent, facetProxy = FacetProxy }

function ProxyComponent:__new(orb)
  local componentId = { name = "Proxy", major_version = 1,
      minor_version = 0, patch_version = 0, platform_spec = "" }
  local component = ComponentContext.__new(self, orb, componentId)
  component:addFacet(utils.ISUPERCOMPONENT_NAME,
      utils.ISUPERCOMPONENT_INTERFACE, ISuperComponent())

  component.isStartedUp = false

  Log:info("Component Proxy criado")
  return component
end

---
--
---
function ProxyComponent:setProxyComponent(iComponent, permission)
  local orb = self._orb

  self.isStartedUp = true

  Log:info("Proxy inicializado. permission=" .. permission)
  local metaFacet = iComponent:getFacetByName(utils.IMETAINTERFACE_NAME)
  metaFacet = orb:narrow(metaFacet, utils.IMETAINFERFACE_INTERFACE)
  local descriptions = metaFacet:getFacets()

  if #descriptions < 1 then
    Log:error("Erro ao buscar as facetas do componente solicitado.")
    return
  end

  for _,description in ipairs(descriptions) do
    local facetName = description.name
    local interfaceName = description.interface_name
    local facetRef = description.facet_ref

    -- Não fazer o bind do ISuperComponent e criar um proxy separado.
    if interfaceName ~= utils.ISUPERCOMPONENT_INTERFACE then
      local newFacet = orb:narrow(facetRef, interfaceName)
      local facetProxy

      if interfaceName == utils.ICOMPONENT_INTERFACE then
        facetProxy = self:createIComponentWrapper(newFacet)
      else
        canCallFunction = function(self) return self.component.isStartedUp end
        facetProxy = FacetProxy(newFacet, canCallFunction)
        facetProxy.component = self
      end

      if permission == "CURRENT" then
        facetProxy._component = function(self) return end
      elseif permission == "ALL" then
        facetProxy._component = function(self) return self.context.IComponent end
      else
        --throw exception
      end

      if self:containsFacet(facetName) then
        self:updateFacet(facetName, facetProxy)
      else
        self:addFacet(facetName, interfaceName, facetProxy)
      end
    end
  end
end

---
--
---
function ProxyComponent:createIComponentWrapper(iComponent)
  local iComponentWrapper =  Wrapper{ __object = iComponent}
  local iSuperComponentFacet = self:getFacetByName(utils.ISUPERCOMPONENT_NAME).facet_ref

  function iComponentWrapper:getFacetByName(name)
    if name == utils.ISUPERCOMPONENT_NAME then
      return iSuperComponentFacet
    else
      return self.__object:getFacetByName(name)
    end
  end

  function iComponentWrapper:getFacet(interface)
    if interface == utils.ISUPERCOMPONENT_INTERFACE then
      return iSuperComponentFacet
    else
      return self.__object:getFacet(interface)
    end
  end

  return iComponentWrapper
end


------------------------------------------------------------------------
-- Classe Proxy
------------------------------------------------------------------------

---
-- function(self) return <boolean> end
---
function FacetProxy:__new(facet, canCallFunction)
  canCallFunction = canCallFunction or function(self) return true end
  Log:info("Facet Proxy criado")
  return oo.rawnew(self, {
  canCall = canCallFunction,
  facet = facet, 
  __type = facet:_interface() })
end

local methods = memoize(function(method)
  return function(self, ...)
    return method(self.facet, ...)
  end
end, "k")

FacetProxy.__index = function(self, key)
  local value = self.facet[key]  
  if self.canCall() then    
    if type(key) == "string" and not key:match("^__") then
      Log:debug("Proxy: calling method " .. key)
      if type(value) == "function" then 
        return methods[value]
      else 
        return value
      end
    end
  else
    Log:error("Log: Componente não inicializado")
  end
end

return Proxy

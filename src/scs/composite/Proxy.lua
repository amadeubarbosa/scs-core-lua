
local ComponentContext = require "scs.core.ComponentContext"
local compositeIdl = require "scs.composite.Idl"
local Publisher = require "scs.composite.Publisher"
local tabop = require "loop.table"
local memoize = tabop.memoize
local ISuperComponent = require "scs.composite.ISuperComponent"
local utils = require "scs.composite.Utils"
local Log = require "scs.util.Log"
utils = utils()
local oo = require "loop.simple"
local class = oo.class

------------------------------------------------------------------------

local Proxy = class({}, ComponentContext)
local FacetProxy = class()

function Proxy:__new(orb)
  local componentId = { name = "Proxy", major_version = 1,
      minor_version = 0, patch_version = 0, platform_spec = "" }
  local component = ComponentContext.__new(self, orb, componentId)
  component:addFacet(utils.ISUPERCOMPONENT_NAME,
      utils.ISUPERCOMPONENT_INTERFACE, ISuperComponent())

  component.isStartedUp = false

  return component
end

---
--
---
function Proxy:setProxyComponent(iComponent, permission)
  local orb = self._orb

  self.isStartedUp = true

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

    -- N�o fazer o bind do ISuperComponent e criar um proxy separado.
    if interfaceName ~= utils.ISUPERCOMPONENT_INTERFACE then
      local newFacet = orb:narrow(facetRef, interfaceName)
      local facetProxy = FacetProxy(self, newFacet)

      if permission == "CURRENT" then
          facetProxy._component = function(self) return end
      elseif permission == "ALL" then
          facetProxy._component = function(self) return context.IComponent end
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

------------------------------------------------------------------------
-- Classe Proxy
------------------------------------------------------------------------
function FacetProxy:__new(facet)
  return oo.rawnew(self, {facet = facet})
end

---
--
---
FacetProxy.__index = memoize(function(method)
  if string.sub(method,1,2) ~= "__" then
    return function(self, ...)
      io.write("calling: " .. method .. " Params:  ")
      print(...)
      if self.context.isStartedUp then
        local facet = self.facet
        return facet[method](facet, ...)
      else
        print("Log: Componente n�o inicializado")
      end
    end
  end
end, "k")


return Proxy

local ComponentContext = require "scs.composite.ComponentContext"
local compositeIdl = require "scs.composite.Idl"
local Publisher = require "scs.composite.Publisher"
local tabop = require "loop.table"
local memoize = tabop.memoize
local ISuperComponent = require "scs.composite.ISuperComponent"
local utils = require "scs.composite.Utils"
utils = utils()
local oo = require "loop.simple"
local class = oo.class

------------------------------------------------------------------------

local Proxy = class({}, ComponentContext)

function Proxy:__new(orb, id, basicKeys)
  local component = ComponentContext.__new(self, orb, id, basicKeys)
  component.isStartedUp = false

  return component
end

---
--
---
function Proxy:setProxyComponent(iComponent, permission)
  local context = self.context

  self:setBasicFacets(iComponent)

  local metaFacet = component:getFacetByName(utils.IMETAINTERFACE_NAME).facet_ref
  metaFacet = orb:narrow(metaFacet, utils.IMETAINFERFACE_INTERFACE)
  local descriptions = metaFacet:getFacets()

  for _,description in pairs(descriptions) do
    local facetName = description.name
    local interfaceName = description.interface_name
    local facetRef = description.facet_ref

    -- Não fazer o bind do ISuperComponent e criar um proxy separado.
    if interfaceName == utils.ISUPERCOMPONENT_INTERFACE then
      return
    end

    local facetProxy = FacetProxy(self, facetRef)

    if permission == "CURRENT" then
        facetProxy._component = function(self) return end
    elseif permission == "ALL" then
        facetProxy._component = function(self) return context.IComponent end
    else
        --throw exception
    end

    context:addFacet(facetName, interfaceName, facetProxy)
  end

  component.isStartedUp = true
end

function Proxy:setBasicFacets(iComponent)
  iComponentFacet = iComponent:getFacetByName(utils.ICOMPONENT_NAME)
  iReceptacleFAcet = iComponent:getFacetByName(utils.IRECEPTACLES_NAME)
  iMetainterfaceFacet = iComponent:getFacetByName(utils.IMETAINTERFACE_NAME)

  component:updateFacet(utils.ICOMPONENT_NAME, FacetProxy(iComponentFacet))
  component:updateFacet(utils.IRECEPTACLES_NAME, FacetProxy(iReceptacleFAcet))
  component:updateFacet(utils.IMETAINTERFACE_NAME, FacetProxy(iMetainterfaceFacet))
end


------------------------------------------------------------------------
-- Classe Proxy
------------------------------------------------------------------------
local FacetProxy = class{}
function FacetProxy:__new(facet)
  self.facet = facet
end

---
--
---
FacetProxy.__index = memoize(function(method)
  if string.sub(method,1,2) ~= "__" then
    return function(self, ...)
      print ("calling: " .. method)
      if self.context.isStartedUp then
        return self.facet[method](...)
      else
        print("Log: Componente não inicializado")
      end
    end
  end
end, "k")


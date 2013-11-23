----------------------------------------------------------------------------------
-- Varre os componentes mostrando cada subcomponetne existente 
-- no CAS dado um nó raiz.
-- 
-- Exemplo de arquivo de configuração:
--  config = {
--    F = {},
--    R = {},
--    CONN = {},
--
--    C = {"connector"},
--    S = {"space"},
--    SP = {"speedcar"},
--  }
-- 
-- Autor: Mauricio Arieira
----------------------------------------------------------------------------------


local oil = require "oil"
local oo = require "loop.base"
local class = oo.class
local scsUtils = require "scs.composite.utils"
scsUtils = scsUtils()

---
--
---
function string.split(str, sep)
  result = {}
  string.gsub(str .. sep, "([^" .. sep .. "]*)"..sep, function(c) table.insert(result, c) end)
  return result
end

---
--
---
function string.findMatch(s, pattern)
  local st, en = string.find (s:upper(), pattern:upper())
  return st ~= nil
end

----------------------------------------------------------------------------------

local Inspector = class()

function Inspector:__new(config, orb, printer)
  return oo.rawnew(self,
      {
      printer = printer or require "scs.auxiliar.textPrinter",
      config = config,
      orb = orb,
      root = {},
      })
end

---
--
---
function Inspector:getMembersData(component)
  local orb = self.orb

  local metaInterface = component:getFacetByName(scsUtils.IMETAINTERFACE_NAME)
  metaInterface = orb:narrow(metaInterface, scsUtils.IMETAINTERFACE_INTERFACE)

  local facet = metaInterface:getFacets()
  local receptacles = metaInterface:getReceptacles()
  
  return facet, receptacles
end

---
--
---
function Inspector:getType(componentId)
  for _, t in pairs(self.config) do
    if type(t) == "table" and t.pattern and string.findMatch(componentId.name, t.pattern) then
      return t
    end
  end
  
  return
end

---
--
---
function Inspector:getComponentData(component)
  local orb = self.orb

  local facets, receptacles = self:getMembersData(component)
  local componentId = component:getComponentId()
  local componentIdStr = scsUtils:getNameVersion(componentId)
  local compConfig = self:getType(componentId)
  
  local componentDesc = { 
      facets = facets, 
      receptacles = receptacles,
      componentId = componentIdStr,
      config = compConfig,
  }

  return componentDesc
end 

---
--
---
function Inspector:execute(component)
  self:executeInterno(self.root, component)
end

---
--
---
function Inspector:executeInterno(node, component)
  local orb = self.orb
  local componentDesc = self:getComponentData(component)

  local iContentFacet = component:getFacetByName(scsUtils.ICONTENTCONTROLLER_NAME)
  iContentFacet = orb:narrow(iContentFacet, scsUtils.ICONTENTCONTROLLER_INTERFACE)
  if not iContentFacet then
    print("Componente" .. scsUtils:getNameVersion(component) .. "' não é um componente Composto!")
    return
  end
  
  componentDesc.id = iContentFacet:getId()
  componentDesc.subComponentes = {}
  
  local subComponentDesc
  local subComponents = iContentFacet:getSubComponents()
  for _, subComponent in ipairs(subComponents) do
    local subIcomponent = orb:narrow(subComponent.icomponent, scsUtils.ICOMPONENT_INTERFACE)
    self:executeInterno(componentDesc.subComponentes, subIcomponent, orb)
  end
  
  table.insert(node, componentDesc)
end

---
--
---
function Inspector:print()
  for _,node in ipairs(self.root) do
    self:printInterno(node, 0)
  end
  
  self.printer:flush()
end

---
--
---
function Inspector:printInterno(component, ident)
  local orb = self.orb
  local config = self.config
  local printer = self.printer
  
  if component.config then printer:write(ident, component.config, component.componentId, true) end

  ident = ident + 1
  if #component.facets > 0 then
    for _, facet in ipairs(component.facets) do
      if config.F then printer:write(ident, config.F, facet.name, false) end
    end
  end

  local receptacles = component.receptacles
  if # receptacles > 0 then
    for _, receptacle in ipairs(receptacles) do
      local hasChild = (receptacle.connections == true)
      if config.R then printer:write(ident, config.R, receptacle.name, hasChild) end
      
      if receptacle.connections then
        for _, connection in ipairs(receptacle.connections) do
          local component = connection.objref:_component()
          component = orb:narrow(component, scsUtils.ICOMPONENT_INTERFACE)
          local connId = scsUtils:getNameVersion(component:getComponentId())
          if config.CONN then printer:write(ident + 1, config.CONN, connId, false) end
        end
      end
    end
  end
  
  if #component.subComponentes > 0 then
    printer:write(ident, config.SUBCC, "SubComponents", true)
    for _, subComponent in ipairs(component.subComponentes) do
      self:printInterno(subComponent, ident + 1)
    end
  end
end


return Inspector
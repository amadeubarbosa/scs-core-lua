----------------------------------------------------------------------------------
-- Varre os componentes mostrando cada subcomponetne existente 
-- no CAS dado um nó raiz.
-- 
-- Exemplo de arquivo de configuração:
--  config = {
--    F = true,
--    R = true,
--    CONN = true,
--
--    C = "connector",
--    S = "space",
--    SP = "speedcar",
--  }
-- 
-- Autor: Mauricio Arieira
----------------------------------------------------------------------------------

local IDENT_NUM = 2

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
  --return string.sub (s, st, en)
end

----------------------------------------------------------------------------------

local Inspector = class()

function Inspector:__new(config, orb)
  return oo.rawnew(self,
      {
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
function Inspector:getGroup(componentId)
  for group, value in pairs(self.config) do
    if type(value) == "string" and string.findMatch(componentId.name, value) then
      return group
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
  local group = self:getGroup(componentId)
  
  local componentDesc = { 
      facets = facets, 
      receptacles = receptacles,
      componentId = componentIdStr,
      group = group,
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
end

---
--
---
function Inspector:printInterno(component, ident)
  local orb = self.orb
  local config = self.config
  local spaces = string.rep(" ", ident)
  
  
  if component.group then print(string.format("%s(%s) %s", spaces,  component.group , component.componentId )) end

  local spaces = string.rep(" ", ident + IDENT_NUM)
  if #component.facets > 0 then
    for _, facet in ipairs(component.facets) do
      if config.F then print(string.format("%s(F) %s", spaces, facet.name)) end
    end
  end

  local receptacles = component.receptacles
  if # receptacles > 0 then
    for _, receptacle in ipairs(receptacles) do
      if config.R then print(string.format("%s(R) %s", spaces, receptacle.name)) end
      
      if receptacle.connections then
        for _, connection in ipairs(receptacle.connections) do
          local component = connection.objref:_component()
          component = orb:narrow(component, scsUtils.ICOMPONENT_INTERFACE)
          local connId = scsUtils:getNameVersion(component:getComponentId())
          if config.CONN then print(string.format("%s(Conn) %s", spaces .. string.rep(" ", 2), connId)) end
        end
      end
    end
  end
  
  if #component.subComponentes > 0 then
    print(string.format("%sSubComponents:", spaces))
    for _, subComponent in ipairs(component.subComponentes) do
      self:printInterno(subComponent, ident + 2*IDENT_NUM)
    end
  end
end

    
return Inspector
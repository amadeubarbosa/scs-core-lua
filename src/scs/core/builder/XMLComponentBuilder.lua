local oil = require "oil"
local oo = require "loop.base"
require "LuaXML.xml"
local xmlParser = xmlParser
require "LuaXML.handler"
local simpleTreeHandler = simpleTreeHandler
local ComponentContext = require "scs.core.ComponentContext"
local utils = require "scs.core.utils"
utils = utils()

local COMPONENT_ID_ELEMENT = "id"
local COMPONENT_ID_NAME = "name"
local COMPONENT_ID_VERSION = "version"
local COMPONENT_ID_PLATFORM_SPEC = "platformSpec"
local COMPONENT_CONTEXT_ELEMENT = "context"
local COMPONENT_CONTEXT_TYPE = "type"
local IDL_ELEMENT = "idl"
local FACET_ELEMENT = "facet"
local FACET_NAME = "name"
local FACET_INTERFACE_NAME = "interfaceName"
local FACET_IMPL = "facetImpl"
local FACET_KEY = "key"
local RECEPTACLE_ELEMENT = "receptacle"
local RECEPTACLE_NAME = "name"
local RECEPTACLE_INTERFACE_NAME = "interfaceName"
local RECEPTACLE_MULTIPLEX = "isMultiplex"
local VERSION_DELIMITER = "%."

local idlpath = os.getenv("IDL_PATH")

--------------------------------------------------------------------------------

local function getComponentId(self, idTag)
  if not idTag then
    return nil
  end
  local id = {}
  id.name = idTag[COMPONENT_ID_NAME]
  _, _, id.major_version, id.minor_version, id.patch_version = string.find(
    idTag[COMPONENT_ID_VERSION], "(%d)" .. VERSION_DELIMITER .. "(%d)" ..
    VERSION_DELIMITER .. "(%d)")
  id.platform_spec = idTag[COMPONENT_ID_PLATFORM_SPEC]
  return id
end

local function getContextType(self, ctxtTag)
  if not ctxtTag then
    return nil
  end
  local typeTag = ctxtTag[COMPONENT_CONTEXT_TYPE]
  return require (typeTag)
end

local function loadIDLs(self, idlsTag, orb)
  if not idlsTag then
    return nil
  end
  local idlTag = idlsTag[IDL_ELEMENT]
  if #idlTag == 0 or type(idlTag) == "string" then
    --If the idl element has size 0, its not an array (not indexed by numbers)
    -- and thus has only one element, which will be a string
    orb:loadidlfile(idlpath .. "/" .. idlTag)
  else
    --It's an array
    local i = 1
    for k, v in ipairs(idlTag) do
      orb:loadidlfile(idlpath .. "/" .. v)
    end
  end
end

local function readAndPutFacet(self, facetTag, component)
  local impl = require (facetTag[FACET_IMPL])
  local name = facetTag[FACET_NAME]
  if component:getFacetByName(name) then
    component:updateFacet(name, impl())
  else
    component:addFacet(name, facetTag[FACET_INTERFACE_NAME],
                       impl(), facetTag[FACET_KEY])
  end
end

local function readAndPutFacets(self, facetsTag, component)
  if not facetsTag then
    return nil
  end
  local facetTag = facetsTag[FACET_ELEMENT]
  if #facetTag == 0 then
    --If the facet element has size 0, its not an array (not indexed by numbers)
    -- and thus has only one element
    readAndPutFacet(self, facetTag, component)
  else
    --It's an array
    local i = 1
    for k, v in ipairs(facetTag) do
      readAndPutFacet(self, v, component)
    end
  end
end

local function readAndPutReceptacle(self, receptTag, component)
  component:addReceptacle(receptTag[RECEPTACLE_NAME],
                          receptTag[RECEPTACLE_INTERFACE_NAME],
                          receptTag[RECEPTACLE_MULTIPLEX])
end

local function readAndPutReceptacles(self, receptsTag, component)
  if not receptsTag then
    return nil
  end
  local receptTag = receptsTag[RECEPTACLE_ELEMENT]
  if #receptTag == 0 then
    --If the receptacle element has size 0, its not an array (not indexed by numbers)
    -- and thus has only one element
    readAndPutReceptacle(self, receptTag, component)
  else
    --It's an array
    local i = 1
    for k, v in ipairs(receptTag) do
      readAndPutReceptacle(self, v, component)
    end
  end
end

--------------------------------------------------------------------------------

local XMLComponentBuilder = oo.class()

function XMLComponentBuilder.__new(self)
  return oo.rawnew(self, {})
end

--- Builds a component, based on a XML file. The component will be composed of
-- the basic facets, plus all facets and receptacles present on the XML file.
--
-- @param orb The orb that shall be associated to this component and its CORBA objects.
-- @param file The XML file.
-- @return A fully assembled component, with working facets, as described by the XML file.
function XMLComponentBuilder.build(self, orb, file)
  local component
  local xml = simpleTreeHandler()
  local f, e = io.open(file, "r")
  if f then
    local xmltext = f:read("*a")
    local xmlparser = xmlParser(xml)
    xmlparser:parse(xmltext)
    -- Now the xml table has the xml file contents
    local id = getComponentId(self, xml.root.component.id)
    local ctxtType = getContextType(self, xml.root.component.context) or ComponentContext
    component = ctxtType(orb, id)
    --TODO: log idl loading
    loadIDLs(self, xml.root.component.idls, component._orb)
    readAndPutReceptacles(self, xml.root.component.receptacles, component)
    readAndPutFacets(self, xml.root.component.facets, component)
  else
    error(e)
  end
  return component
end

return XMLComponentBuilder

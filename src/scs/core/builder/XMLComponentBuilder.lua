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

local module = module
local ipairs = ipairs
local type   = type
local io     = io
local string = string
local require = require

local idlpath = os.getenv("IDLPATH_DIR")

--------------------------------------------------------------------------------

module ("scs.core.builder.XMLComponentBuilder", oo.class)

--------------------------------------------------------------------------------

function __init(self)
  return oo.rawnew(self, {})
end

function build(self, orb, file)
  local component
  local xml = simpleTreeHandler()
  local f, e = io.open(file, "r")
  if f then
    local xmltext = f:read("*a")
    local xmlparser = xmlParser(xml)
    xmlparser:parse(xmltext)
    -- Now the xml table has the xml file contents
    local id = self:getComponentId(xml.root.component.id)
    component = ComponentContext(orb, id)
    --TODO: log idl loading
    self:loadIDLs(xml.root.component.idls, component._orb)
    self:readAndPutReceptacles(xml.root.component.receptacles, component)
    self:readAndPutFacets(xml.root.component.facets, component)
  else
    error(e)
  end
  return component
end

function getComponentId(self, idTag)
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

function loadIDLs(self, idlsTag, orb)
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

function readAndPutFacet(self, facetTag, component)
  local impl = require (facetTag[FACET_IMPL])
  component:putFacet(facetTag[FACET_NAME], facetTag[FACET_INTERFACE_NAME],
                     impl(), facetTag[FACET_KEY])
end

function readAndPutFacets(self, facetsTag, component)
  if not facetsTag then
    return nil
  end
  local facetTag = facetsTag[FACET_ELEMENT]
  if #facetTag == 0 then
    --If the facet element has size 0, its not an array (not indexed by numbers)
    -- and thus has only one element
    self:readAndPutFacet(facetTag, component)
  else
    --It's an array
    local i = 1
    for k, v in ipairs(facetTag) do
      self:readAndPutFacet(v, component)
    end
  end
end

function readAndPutReceptacle(self, receptTag, component)
  component:putReceptacle(receptTag[RECEPTACLE_NAME],
                          receptTag[RECEPTACLE_INTERFACE_NAME],
                          receptTag[RECEPTACLE_MULTIPLEX])
end

function readAndPutReceptacles(self, receptsTag, component)
  if not receptsTag then
    return nil
  end
  local receptTag = receptsTag[RECEPTACLE_ELEMENT]
  if #receptTag == 0 then
    --If the receptacle element has size 0, its not an array (not indexed by numbers)
    -- and thus has only one element
    self:readAndPutReceptacle(receptTag, component)
  else
    --It's an array
    local i = 1
    for k, v in ipairs(receptTag) do
      self:readAndPutReceptacle(v, component)
    end
  end
end

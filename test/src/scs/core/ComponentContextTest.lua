local oil = require "oil"

local ComponentContext = require "scs.core.ComponentContext"
local IComponent = require "scs.core.Component"

local utils = require "scs.core.utils"
utils = utils()

local Check = require "latt.Check"

local Log = require "scs.util.Log"

local ComponentId = {
  name = "ComponentContextTest",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = "lua",
}

oil.verbose:level(0)
Log:level(0)

local orb = oil.init()
orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")

Suite = {
  Test1 = {
    testConstructContext = function(self)
      Check.assertNotNil(ComponentContext(orb, ComponentId))
    end,

    testConstructContext2 = function(self)
      Check.assertNotNil(ComponentContext(nil, ComponentId))
    end,

    testConstructContext3 = function(self)
      Check.assertNil(ComponentContext(orb, nil))
    end,

    testConstructContext4 = function(self)
      local keys = {}
      keys[utils.ICOMPONENT_NAME] = "testConstructContext4"
      Check.assertNotNil(ComponentContext(orb, ComponentId, keys))
    end,

    testGetORB = function(self)
      local component = ComponentContext(orb, ComponentId)
      Check.assertEquals(orb, component:getORB())
    end,

    testGetORB2 = function(self)
      local component = ComponentContext(nil, ComponentId)
      Check.assertNotNil(component:getORB())
    end,

    testGetFacets = function(self)
      local component = ComponentContext(orb, ComponentId)
      local facets = component:getFacets()
      Check.assertNotNil(facets)
      local i = 0
      for k, v in pairs(facets) do
        i = i + 1
      end
      Check.assertEquals(3, i)
    end,

    testGetReceptacles = function(self)
      local component = ComponentContext(orb, ComponentId)
      local receptacles = component:getReceptacles()
      Check.assertNotNil(receptacles)
      local i = 0
      for k, v in pairs(receptacles) do
        i = i + 1
      end
      Check.assertEquals(0, i)
    end,

    testGetComponentId = function(self)
      local component = ComponentContext(orb, ComponentId)
      Check.assertNotNil(component:stringifiedComponentId())
      local id = component:getComponentId()
      Check.assertNotNil(id)
      Check.assertEquals(ComponentId.name, id.name)
      Check.assertEquals(ComponentId.major_version, id.major_version)
      Check.assertEquals(ComponentId.minor_version, id.minor_version)
      Check.assertEquals(ComponentId.patch_version, id.patch_version)
      Check.assertEquals(ComponentId.platform_spec, id.platform_spec)
    end,

    testGetFacetByName = function(self)
      local component = ComponentContext(orb, ComponentId)
      Check.assertNotNil(component:getFacetByName(utils.ICOMPONENT_NAME))
      Check.assertNil(component:getFacetByName(""))
      Check.assertNil(component:getFacetByName())
    end,

    testGetIComponent = function(self)
      local keys = {}
      keys[utils.ICOMPONENT_NAME] = "testGetIComponent"
      local component = ComponentContext(orb, ComponentId, keys)
      local ic = component:getIComponent()
      Check.assertNotNil(ic)
      local facet = component:getFacetByName(utils.ICOMPONENT_NAME)
      Check.assertEquals(ic, facet.facet_ref)
      Check.assertEquals(utils.ICOMPONENT_NAME, facet.name)
      Check.assertEquals(utils.ICOMPONENT_INTERFACE, facet.interface_name)
      Check.assertEquals("testGetIComponent", facet.key)
    end,

    testGetIReceptacles = function(self)
      local keys = {}
      keys[utils.IRECEPTACLES_NAME] = "testGetIReceptacles"
      local component = ComponentContext(orb, ComponentId, keys)
      local facet = component:getFacetByName(utils.IRECEPTACLES_NAME)
      Check.assertNotNil(facet)
      Check.assertEquals(utils.IRECEPTACLES_NAME, facet.name)
      Check.assertEquals(utils.IRECEPTACLES_INTERFACE, facet.interface_name)
      Check.assertEquals("testGetIReceptacles", facet.key)
    end,

    testGetIMetaInterface = function(self)
      local keys = {}
      keys[utils.IMETAINTERFACE_NAME] = "testGetIMetaInterface"
      local component = ComponentContext(orb, ComponentId, keys)
      local facet = component:getFacetByName(utils.IMETAINTERFACE_NAME)
      Check.assertNotNil(facet)
      Check.assertEquals(utils.IMETAINTERFACE_NAME, facet.name)
      Check.assertEquals(utils.IMETAINTERFACE_INTERFACE, facet.interface_name)
      Check.assertEquals("testGetIMetaInterface", facet.key)
    end,

    testDeactivateComponent = function(self)
      local component = ComponentContext(orb, ComponentId)
      local errors = component:deactivateComponent()
      Check.assertEquals(0, #errors)
    end,

    testActivateComponent = function(self)
      local component = ComponentContext(orb, ComponentId)
      component:deactivateComponent()
      local errors = component:activateComponent()
      Check.assertEquals(0, #errors)
    end,

    testSubstituteFacet = function(self)
      local component = ComponentContext(orb, ComponentId)
      local facet = component:getFacetByName(utils.ICOMPONENT_NAME)
      local newImpl = IComponent()
      component:updateFacet(utils.ICOMPONENT_NAME, newImpl)
      Check.assertNotNil(component:getIComponent())
      local newFacet = component:getFacetByName(utils.ICOMPONENT_NAME)
      Check.assertNotEquals(facet.facet_ref, newFacet.facet_ref)
      Check.assertNotEquals(facet.implementation, newFacet.implementation)
      Check.assertEquals(newImpl, newFacet.implementation)
    end,

    testGetReceptacleByName = function(self)
      local component = ComponentContext(orb, ComponentId)
      local recName = "MyReceptacle"
      component:putReceptacle(recName, utils.ICOMPONENT_INTERFACE, false)
      Check.assertNotNil(component:getReceptacleByName(recName))
    end,

    testSubstituteReceptacle = function(self)
      local component = ComponentContext(orb, ComponentId)
      local recName = "MyReceptacle"
      component:putReceptacle(recName, utils.ICOMPONENT_INTERFACE, false)
      local rec = component:getReceptacleByName(recName)
      component:putReceptacle(recName, utils.ICOMPONENT_INTERFACE, true)
      local newRec = component:getReceptacleByName(recName)
      Check.assertNotEquals(rec.connections, newRec.connections)
      Check.assertEquals(false, rec.is_multiplex)
      Check.assertEquals(true, newRec.is_multiplex)
    end,

    testRemoveFacet = function(self)
      local component = ComponentContext(orb, ComponentId)
      Check.assertNotNil(component:getFacetByName(utils.IMETAINTERFACE_NAME))
      component:removeFacet(utils.IMETAINTERFACE_NAME)
      Check.assertNil(component:getFacetByName(utils.IMETAINTERFACE_NAME))
    end,

    testRemoveReceptacle = function(self)
      local component = ComponentContext(orb, ComponentId)
      local recName = "MyReceptacle"
      component:putReceptacle(recName, utils.ICOMPONENT_INTERFACE, false)
      Check.assertNotNil(component:getReceptacleByName(recName))
      component:removeReceptacle(recName)
      Check.assertNil(component:getReceptacleByName(recName))
    end,

    testGetComponentCCM = function(self)
      local component = ComponentContext(orb, ComponentId)
      local ir = component:getFacetByName(utils.IRECEPTACLES_NAME)
      Check.assertNotNil(ir.facet_ref:_component())
    end,
  },
}

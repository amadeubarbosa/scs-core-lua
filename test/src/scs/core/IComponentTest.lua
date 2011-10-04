local oil = require "oil"

local ComponentContext = require "scs.core.ComponentContext"

local utils = require "scs.core.utils"
utils = utils()

local Log = require "scs.util.Log"

local Check = require "latt.Check"

local ComponentId = {
  name = "IComponentTest",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = "lua",
}

oil.verbose:level(0)
Log:level(0)

local orb = oil.init()
orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")

local ic

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local context = ComponentContext(orb, ComponentId)
      ic = context:getIComponent()
    end,

    testGetComponentId = function(self)
      local cpId = ic:getComponentId()
      Check.assertNotNil(cpId)
      Check.assertEquals(ComponentId.name, cpId.name)
      Check.assertEquals(ComponentId.major_version, cpId.major_version)
      Check.assertEquals(ComponentId.minor_version, cpId.minor_version)
      Check.assertEquals(ComponentId.patch_version, cpId.patch_version)
      Check.assertEquals(ComponentId.platform_spec, cpId.platform_spec)
    end,

    testGetFacet = function(self)
      Check.assertNotNil(ic:getFacet(utils.ICOMPONENT_INTERFACE))
      Check.assertNotNil(ic:getFacet(utils.IRECEPTACLES_INTERFACE))
      Check.assertNotNil(ic:getFacet(utils.IMETAINTERFACE_INTERFACE))
      Check.assertNil(ic:getFacet(""))
    end,

    testGetFacetByName = function(self)
      Check.assertNotNil(ic:getFacetByName(utils.ICOMPONENT_NAME))
      Check.assertNotNil(ic:getFacetByName(utils.IRECEPTACLES_NAME))
      Check.assertNotNil(ic:getFacetByName(utils.IMETAINTERFACE_NAME))
      Check.assertNil(ic:getFacetByName(""))
    end,
  },
}

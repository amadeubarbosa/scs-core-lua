local oil = require "oil"

local ComponentContext = require "scs.core.ComponentContext"

local utils = require "scs.core.utils"
utils = utils()

local Log = require "scs.util.Log"

local Check = require "latt.Check"

local ComponentId = {
  name = "IMetaInterfaceTest",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = "lua",
}

oil.verbose:level(0)
Log:level(0)

local orb = oil.init()

local context = ComponentContext(orb, ComponentId)
context:putReceptacle("IMetaInterfaceTest", utils.ICOMPONENT_INTERFACE, false)
local facet = context:getFacetByName(utils.IMETAINTERFACE_NAME)
local imi = facet.facet_ref

Suite = {
  Test1 = {
    testGetFacets = function(self)
      Check.assertEquals(3, #(imi:getFacets()))
    end,

    testGetFacetsByName = function(self)
      Check.assertEquals(3, #(imi:getFacetsByName({
        utils.ICOMPONENT_NAME,
        utils.IRECEPTACLES_NAME,
        utils.IMETAINTERFACE_NAME})))
      Check.assertEquals(0, #(imi:getFacetsByName({})))
    end,

    testGetFacetsByName2 = function(self)
      Check.assertError(imi.getFacetsByName, imi, {""})
    end,

    testGetReceptacles = function(self)
      Check.assertEquals(1, #(imi:getReceptacles()))
    end,

    testGetReceptacles2 = function(self)
      Check.assertEquals(1, #(imi:getReceptacles()))
    end,

    testGetReceptaclesByName = function(self)
      Check.assertEquals(0, #(imi:getReceptaclesByName({})))
      Check.assertEquals(1, #(imi:getReceptaclesByName({
        "IMetaInterfaceTest"})))
    end,

    testGetReceptaclesByName2 = function(self)
      Check.assertError(imi.getReceptaclesByName, imi, {""})
    end,

  },
}

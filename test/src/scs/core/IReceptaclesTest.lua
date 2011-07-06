local oil = require "oil"

local ComponentContext = require "scs.core.ComponentContext"

local utils = require "scs.core.utils"
utils = utils()

local Log = require "scs.util.Log"

local Check = require "latt.Check"

local testName = "IReceptaclesTest"
local ComponentId = {
  name = testName,
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = "lua",
}

oil.verbose:level(0)
Log:level(0)

local orb = oil.init()
orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")

local context
local facet
local ir

Suite = {
  Test1 = {
    beforeEachTest = function(self)
      context = ComponentContext(orb, ComponentId)
      facet = context:getFacetByName(utils.IRECEPTACLES_NAME)
      ir = facet.facet_ref
      context:addReceptacle(testName, utils.ICOMPONENT_INTERFACE, true)
    end,

    afterEachTest = function(self)
      context:removeReceptacle(testName)
    end,

    testGetConnections = function(self)
      Check.assertError(ir.getConnections, ir, "") --InvalidName
    end,

    testGetConnections2 = function(self)
      Check.assertEquals(0, #(ir:getConnections(testName)))
    end,

    testConnect = function(self)
      Check.assertError(ir.connect, ir, "", context:getIComponent()) --InvalidName
    end,

    testConnect2 = function(self)
      local imiFacet = context:getFacetByName(utils.IMETAINTERFACE_NAME)
      Check.assertError(ir.connect, ir, testName, imiFacet.facet_ref) --InvalidConnection
    end,

    testConnect3 = function(self)
      -- substitutes receptacle for one with only one connection
      context:removeReceptacle(testName)
      context:addReceptacle(testName, utils.ICOMPONENT_INTERFACE, false)
      local id = ir:connect(testName, context:getIComponent())
      Check.assertNotNil(id)
      Check.assertError(ir.connect, ir, testName, context:getIComponent()) --AlreadyConnected
      ir:disconnect(id)
    end,

    testConnect4 = function(self)
      local maxConns = ir._maxConnections
      ir._maxConnections = 2
      local id = ir:connect(testName, context:getIComponent())
      Check.assertNotNil(id)
      local id2 = ir:connect(testName, context:getIComponent())
      Check.assertNotNil(id2)
      Check.assertError(ir.connect, ir, testName, context:getIComponent()) --ExceededConnectionLimit
      ir:disconnect(id)
      ir:disconnect(id2)
      ir._maxConnections = maxConns
    end,

    testDisconnect = function(self)
      Check.assertError(ir.disconnect, ir, 0) --InvalidConnection
    end,

    testDisconnect2 = function(self)
      Check.assertError(ir.disconnect, ir, 1) --NoConnection
    end,

    testDisconnect3 = function(self)
      local id = ir:connect(testName, context:getIComponent())
      Check.assertNotNil(id)
      ir:disconnect(id)
      Check.assertError(ir.disconnect, ir, id) --InvalidConnection
    end,
  },
}

local oil = require "oil"

local CoreComponentContext = require "scs.core.ComponentContext"
local ComponentContext = require "scs.composite.ComponentContext"

local Idl = require "scs.composite.Idl"
local utils = require "scs.composite.Utils"
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
orb:loadidlfile(os.getenv("IDL_PATH") .. "/composite.idl")

local icontroller
local coreComponent
local compositeComponent

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local compositeComponent1 = ComponentContext(orb, ComponentId)
      icontroller = compositeComponent1.IContentController
      coreComponent = orb:newproxy("corbaloc::localhost:2620/CoreComponent")
      coreComponent = orb:narrow(coreComponent, utils.IComponent)
      compositeComponent = orb:newproxy("corbaloc::localhost:2620/CompositeComponent")
      compositeComponent = orb:narrow(compositeComponent, utils.IComponent)
    end,

    testId = function(self)
      local icontroller2 = compositeComponent:getFacetByName(utils.ICONTENTCONTROLLER_NAME)
      icontroller2 = orb:narrow(icontroller2, utils.ICONTENTCONTROLLER_INTERFACE)
      local id = icontroller:getId()
      local id2 = icontroller2:getId()
      Check.assertNotEquals(id , id2)
    end,

    --[[ LATT não permite
    testAddSubComponent = function(self)

      local membershipID1 = icontroller:addSubComponent(compositeComponent)
      local membershipID2 = icontroller:addSubComponent(compositeComponent)
      Check.assertNotEquals(membershipID1, membershipID2)
    end,]]--

    testAddSubComponent_CoreComponent = function(self)
      local exception = Check.assertError(icontroller.addSubComponent, icontroller, coreComponent)
      Check.assertEquals(idl.throw.InvalidComponent, exception._repid)
    end,

    testremoveSubComponent_ID = function(self)
        Check.assertFalse(icontroller:removeSubComponent(math.random(10,100)))
    end,

    --[[ LATT não permite
    testremoveSubComponent_InvalidNumber = function(self)
        local membershipID1 = icontroller:addSubComponent(compositeComponent)
        Check.assertTrue(icontroller:removeSubComponent(membershipID1))
    end,]]--

    --[[ LATT não permite
    testGetSubComponets = function(self)
      local membershipID1 = icontroller:addSubComponent(compositeComponent)
      local membershipID2 = icontroller:addSubComponent(compositeComponent)
      local componentsID = icontroller:getSubComponents()
    end,]]--

    testFindComponent_InvalidID = function(self)
      local exception = Check.assertError(icontroller.findComponent, icontroller, math.random(10,100))
      Check.assertEquals(exception._repid, idl.throw.ComponentNotFound)
    end,

    --[[LATT não permite
    testFindComponent = function(self)
      local membershipID1 = icontroller:addSubComponent(compositeComponent)
      local iComponent = icontroller:findComponent(membershipID1)

      Check.assertNotNil(iComponent)
      iComponent = orb:narrow(iComponent, utils.ICOMPONENT_INTERFACE)
      Check.assertEquals(iComponent:getComponentId().name, compositeComponent:getComponentId.name)
    end,]]--

    testBindFacet_InvalidID = function(self)
      local testId = math.random(10,100)
      local exception = Check.assertError(icontroller.bindFacet, icontroller, testId, "IHello", "IHelloX")
      Check.assertEquals(exception._repid, idl.throw.ComponentNotFound)
      Check.assertEquals(testId, exception.id)
    end,

    testUnbind_InvalidID = function(self)
      Check.assertFalse(icontroller:unbind(888))
    end,

    testGetSubComponents_EmptyList = function(self)
      local emptyList = icontroller:getSubComponents()
      Check.assertEmpty(emptyList)
    end,

    testRetrieveBindings_EmptyList = function(self)
      local emptyList = icontroller:retrieveBindings()
      Check.assertEmpty(emptyList)
    end,

  },
}

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
local compositeComponent2

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local compositeComponent = ComponentContext(orb, ComponentId)
      icontroller = compositeComponent.IContentController      
      coreComponent = orb:newproxy("corbaloc::localhost:2610/CoreComponent")
      coreComponent = orb:narrow(coreComponent, utils.IComponent)
      compositeComponent2 = orb:newproxy("corbaloc::localhost:2610/CompositeComponent2")
      compositeComponent2 = orb:narrow(compositeComponent2, utils.IComponent)
    end,
    
    testId = function(self)      
      local icontroller2 = compositeComponent2:getFacetByName(utils.ICONTENTCONTROLLER_NAME)
      icontroller2 = orb:narrow(icontroller2, utils.ICONTENTCONTROLLER_INTERFACE)
      local id = icontroller:getId()
      local id2 = icontroller2:getId()
      Check.assertNotEquals(id , id2)
    end,
    
    --[[ LATT não permite
    testAddSubComponent = function(self)
            
      local membershipID1 = icontroller:addSubComponent(compositeComponent2)
      local membershipID2 = icontroller:addSubComponent(compositeComponent2)
      Check.assertNotEquals(membershipID1, membershipID2)
    end,]]--
    
    testAddSubComponent_CoreComponent = function(self)
      local exception = Check.assertError(icontroller.addSubComponent, icontroller, coreComponent)      
      Check.assertEquals(exception[1], idl.throw.InvalidComponent)
    end,
    
    testremoveSubComponent_InvalidNumber = function(self)
        Check.assertFalse(icontroller:removeSubComponent(math.random(10,100)))
    end,
    
    --[[ LATT não permite
    testremoveSubComponent_InvalidNumber = function(self)
        local membershipID1 = icontroller:addSubComponent(compositeComponent2)
        Check.assertTrue(icontroller:removeSubComponent(membershipID1))
    end,]]--
    
    --[[ LATT não permite
    testGetSubComponets = function(self)
      local membershipID1 = icontroller:addSubComponent(compositeComponent2)
      local membershipID2 = icontroller:addSubComponent(compositeComponent2)
      local componentsID = icontroller:getSubComponents()
    end,]]--
    
    testFindComponent_InvalidID = function(self)
      local exception = Check.assertError(icontroller.findComponent, icontroller, math.random(10,100))
      Check.assertEquals(exception[1], idl.throw.ComponentNotFound)    
    end,
    
    --[[LATT não permite
    testFindComponent = function(self)
      local membershipID1 = icontroller:addSubComponent(compositeComponent2)
      local iComponent = icontroller:findComponent(membershipID1)
      
      Check.assertNotNil(iComponent)
      iComponent = orb:narrow(iComponent, utils.ICOMPONENT_INTERFACE)
      Check.assertEquals(iComponent:getComponentId().name, compositeComponent2:getComponentId.name)
    end,]]--
    
    testRemoveSubComponent_InvalidID = function(self)
      Check.assertFalse(icontroller:removeSubComponent(888))
    end,
    
    testUnbindFacet_InvalidID = function(self)
      Check.assertFalse(icontroller:unbindFacet(888))
    end,
        
  },
}

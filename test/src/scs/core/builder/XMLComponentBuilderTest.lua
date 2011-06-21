local oil = require"oil"
local oo = require "loop.simple"

local Check = require "latt.Check"

local ComponentContext = require "scs.core.ComponentContext"
local utils = require "scs.core.utils"
utils = utils()
local builder = require "scs.core.builder.XMLComponentBuilder"
builder = builder()

oil.verbose:level(0)

local orb = oil.init()
local xmlFile = os.getenv("SCS_HOME") .. "/test/src/scs/core/builder/example.xml"

Suite = {
  Test1 = {
    testCreateComponentFromXML = function(self)
      local cp = builder:build(orb, xmlFile)
      Check.assertNotNil(cp)
      Check.assertTrue(cp:retTrue())

      local fNames = {}
      fNames["IComponent2"] = true
      fNames["IComponent3"] = true
      fNames[utils.ICOMPONENT_NAME] = true
      fNames[utils.IRECEPTACLES_NAME] = true
      fNames[utils.IMETAINTERFACE_NAME] = true

      local facets = cp:getFacets()
      local i = 0
      for k, v in pairs(facets) do
        Check.assertTrue(fNames[k])
        i = i + 1
      end
      Check.assertEquals(5, i)

      local rNames = {}
      rNames["Receptaculo1"] = true
      rNames["Receptaculo2"] = true

      local receptacles = cp:getReceptacles()
      i = 0
      for k, v in pairs(receptacles) do
        Check.assertTrue(rNames[k])
        i = i + 1
      end
      Check.assertEquals(2, i)
    end,
  },
}

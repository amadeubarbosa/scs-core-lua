local oop = require "loop.base"

local Test = require "latt.Test"
local TestCase = require "latt.TestCase"
local TestSuite = require "latt.TestSuite"

local TestRunner =oop.class()

function TestRunner.__new(self, suite)
  return oop.rawnew(self, { suite = suite, })
end

function TestRunner.run(self)
  local testCases = {}
  for testCaseName, testCase in pairs(self.suite) do
    if (string.sub(testCaseName, 1, 4) == "Test") and (type(testCase) == "table") then
      local tests = {}
        for testName, test in pairs(testCase) do
          if (string.sub(testName, 1, 4) == "test") and (type(test) == "function") then
            table.insert(tests, Test(testName, test, testCase))
          end
        end
        table.insert(testCases, TestCase(testCaseName, testCase, tests))
    end
  end

  local suite = TestSuite(self.suite.name, testCases)
  return suite:run()
end

return TestRunner

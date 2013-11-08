local oop = require "loop.base"

local TestResult = require "latt.TestResult"

local TestSuite = oop.class()

function TestSuite.__new(self, name, testCases)
  return oop.rawnew(self, { name = name, testCases = testCases, })
end

function TestSuite.run(self)
  local result = TestResult(self.name)
  result:startTestSuite()
  for _, testCase in ipairs(self.testCases) do
    testCase:run(result)
  end
  result:stopTestSuite()
  return result
end

return TestSuite

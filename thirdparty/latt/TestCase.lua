local oop = require "loop.base"

local TestCase = oop.class()

function TestCase.__new(self, name, testCase, tests)
  return oop.rawnew(self, { name = name, testCase = testCase, tests = tests, })
end

function TestCase.run(self, result)
  result:startTestCase(self.name)
  if self.testCase.beforeTestCase then
    self.testCase:beforeTestCase()
  end
  for _, test in pairs(self.tests) do
    if self.testCase.beforeEachTest then
      self.testCase:beforeEachTest()
    end
    test:run(result)
    if self.testCase.afterEachTest then
      self.testCase:afterEachTest()
    end
  end
  if self.testCase.afterTestCase then
    self.testCase:afterTestCase()
  end
  result:stopTestCase()
end

return TestCase

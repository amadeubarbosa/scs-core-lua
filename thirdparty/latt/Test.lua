local oop = require "loop.base"

local latt = latt

local Test = oop.class()

function Test.__new(self, name, test, testCase)
  return oop.rawnew(self, { name = name, test = test, testCase = testCase, })
end

function Test.run(self, result)
  result:startTest(self.name)
  local _, errorMessage = latt.pcall(self.test, self.testCase)
  result:stopTest(errorMessage)
end

return Test

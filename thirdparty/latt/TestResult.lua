local oop = require "loop.base"

local TestResult = oop.class()

function TestResult.__new(self, suiteName)
  return oop.rawnew(self, {
    suiteName = suiteName,
    testCounter = 0,
    failureCounter = 0,
    failures = {},
  })
end

function TestResult.startTestSuite(self)
  self.startTime = os.time()
end

function TestResult.stopTestSuite(self)
  self.stopTime = os.time()
end

function TestResult.startTestCase(self, testCaseName)
  self.currentTestCaseName = testCaseName
end

function TestResult.stopTestCase(self)
  self.currentTestCaseName = nil
end

function TestResult.startTest(self, testName)
  self.currentTestName = testName
end

function TestResult.stopTest(self, errorMessage)
  self.testCounter = self.testCounter + 1
  if errorMessage then
    self.failureCounter = self.failureCounter + 1
    table.insert(self.failures, {testCaseName = self.currentTestCaseName, testName = self.currentTestName, errorMessage = errorMessage, })
  end
  self.currentTestName = nil
end

return TestResult

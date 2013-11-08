local print = print
local ipairs = ipairs
local io = io
local os = os

local oop = require "loop.base"

local ConsoleResultViewer = oop.class()

function ConsoleResultViewer.__new(self, result)
  return oop.rawnew(self, { result = result, })
end

function ConsoleResultViewer.show(self)
  print("==============================================")
  print("LATT (Lua Automated Testing Tool) version 1.0\n")
  print("Time: "..os.difftime(self.result.stopTime, self.result.startTime).." second(s)\n")
  if self.result.failureCounter ~= 0 then
    print("There were "..self.result.failureCounter.." failure(s):")
    for i, failure in ipairs(self.result.failures) do
      print(i..") "..failure.testCaseName.." - "..failure.testName)
      print(failure.errorMessage.."\n")
    end
    print("FAILURES!!!")
    print("Tests run: "..self.result.testCounter..",  Failures: "..self.result.failureCounter.."")
  else
    print("OK ("..self.result.testCounter.." tests)")
  end
  print("==============================================")
end

function ConsoleResultViewer.showAsError(self)
  if self.result.failureCounter ~= 0 then
    io.stderr:write("==============================================\n")
    io.stderr:write("LATT (Lua Automated Testing Tool) version 1.0\n")
    io.stderr:write("Time: "..os.difftime(self.result.stopTime, self.result.startTime).." second(s)\n")
    io.stderr:write("There were "..self.result.failureCounter.." failure(s):\n")
    for i, failure in ipairs(self.result.failures) do
      io.stderr:write(i..") "..failure.testCaseName.." - "..failure.testName.."\n")
      io.stderr:write(failure.errorMessage.."\n")
    end
    io.stderr:write("FAILURES!!!\n")
    io.stderr:write("Tests run: "..self.result.testCounter..",  Failures: "..self.result.failureCounter.."\n")
    io.stderr:write("==============================================\n")
  end
end

return ConsoleResultViewer

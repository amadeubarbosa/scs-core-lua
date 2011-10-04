if #arg == 0 or #arg > 2 then
  io.stderr:write("Use: lua OiLTestRunner.lua <test_suite_file_name>\n")
  os.exit(1)
end

require "oil"

local orb = oil.init {flavor = "cooperative;corba.intercepted",}

latt = {}
latt.pcall = pcall

dofile(arg[1])
if not Suite then
  error("Suite not found !!!")
end

local show = true
if arg[2] == "no" then
  show = false
end

local TestRunner = require("latt.TestRunner")
local ConsoleResultViewer = require("latt.ConsoleResultViewer")

function runTest()
  local testRunner = TestRunner(Suite)
  local result = testRunner:run()
  local viewer = ConsoleResultViewer(result)
  if show then
    viewer:show()
  else
    viewer:showAsError()
  end
  return (result.failureCounter == 0)
end

function main()
  oil.newthread(orb.run, orb)

  local status, result = latt.pcall(runTest)
  if not status then
    if show then
       print(result)
    else
       io.stderr:write(result[1] .. "\n")
       io.stderr:write(result.traceback)
    end
    os.exit(1)
  end

  os.exit(result and 0 or 1)
end

oil.main(main)

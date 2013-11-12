local _G = require "_G"
local table = _G.table
local pack = table.pack or _G.pack
local unpack = table.unpack or _G.unpack
local error = _G.error
local tostring = _G.tostring
local type = _G.type

local oop = require "loop.base"

local latt = _G.latt

local function assertBoolean(condition)
  if type(condition) ~= "boolean" then
    error("The condition is not a boolean value.", 3)
  end
end

local Check = oop.class()

function Check.assertError(f, ...)
  local arg = pack(...)
  local success = latt.pcall(f, unpack(arg))
  if success then
    error("Function shouldn't run successfully.", 2)
  end
end

function Check.assertEquals(expected, actual)
  if expected ~= actual then
    error("The expected value ["..tostring(expected).."] must be equal the actual value ["..tostring(actual).."].", 2)
  end
end

function Check.assertNotEquals(expected, actual)
  if expected == actual then
    error("The expected value ["..tostring(expected).."] shouldn't be equal the actual value ["..tostring(actual).."].", 2)
  end
end

function Check.assertTrue(condition)
  assertBoolean(condition)
  if condition == false then
    error("The condition must be true.", 2)
  end
end

function Check.assertFalse(condition)
  assertBoolean(condition)
  if condition == true then
    error("The condition must be false.", 2)
  end
end

function Check.assertNil(variable)
  if variable ~= nil then
    error("The variable must be nil. Actual value: ["..tostring(variable).."].", 2)
  end
end

function Check.assertNotNil(variable)
  if variable == nil then
    error("The variable shouldn't be nil.", 2)
  end
end

return Check

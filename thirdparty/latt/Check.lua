local unpack = unpack
local error = error
local tostring = tostring
local type = type

local oop = require "loop.base"

local latt = latt

module("latt.Check", oop.class)

local function assertBoolean(condition)
  if type(condition) ~= "boolean" then
    error("The condition is not a boolean value.", 3)
  end
end

function assertError(f, ...)
  local success = latt.pcall(f, unpack(arg))
  if success then
    error("Function shouldn't run successfully.", 2)
  end
end

function assertEquals(expected, actual)
  if expected ~= actual then
    error("The expected value ["..tostring(expected).."] must be equal the actual value ["..tostring(actual).."].", 2)
  end
end

function assertNotEquals(expected, actual)
  if expected == actual then
    error("The expected value ["..tostring(expected).."] shouldn't be equal the actual value ["..tostring(actual).."].", 2)
  end
end

function assertTrue(condition)
  assertBoolean(condition)
  if condition == false then
    error("The condition must be true.", 2)
  end
end

function assertFalse(condition)
  assertBoolean(condition)
  if condition == true then
    error("The condition must be false.", 2)
  end
end

function assertNil(variable)
  if variable ~= nil then
    error("The variable must be nil. Actual value: ["..tostring(variable).."].", 2)
  end
end

function assertNotNil(variable)
  if variable == nil then
    error("The variable shouldn't be nil.", 2)
  end
end

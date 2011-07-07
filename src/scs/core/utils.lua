--
-- SCS
-- utils.lua
-- Description: Basic SCS utils
-- Version: 1.0
--

local oo  = require "loop.base"
local oil = require "oil"
local Log = require "scs.util.Log"

local module    = module
local tostring  = tostring
local type      = type
local io        = io
local string    = string
local assert    = assert
local os        = os
local print     = print
local pairs     = pairs

--------------------------------------------------------------------------------

module ("scs.core.utils", oo.class)

--------------------------------------------------------------------------------

function __init(self)
  local instance = oo.rawnew(self, {fileName = "",
                          verbose = false,
                          fileVerbose = false,
                          newLog = true})

  instance.ICOMPONENT_NAME = "IComponent"
  instance.ICOMPONENT_INTERFACE = "IDL:scs/core/IComponent:1.0"
  instance.IRECEPTACLES_NAME = "IReceptacles"
  instance.IRECEPTACLES_INTERFACE = "IDL:scs/core/IReceptacles:1.0"
  instance.IMETAINTERFACE_NAME = "IMetaInterface"
  instance.IMETAINTERFACE_INTERFACE = "IDL:scs/core/IMetaInterface:1.0"

  return instance
end

--
-- Description: Prints a message to the standard output and/or to a file.
-- Parameter message: Message to be delivered.
--
function verbosePrint(self, ...)
  if self.verbose then
    print(...)
  end
  if self.fileVerbose then
    local f = io.open("../../../../logs/lua/"..self.fileName.."/"..self.fileName..".log", "at")
    if not f then
      os.execute("mkdir \"../../../../logs/lua/" .. self.fileName .. "\"")
      f = io.open("../../../../logs/lua/" .. self.fileName .. "/" .. self.fileName , "wt")
      -- do not throw error if f is nil
      if not f then return end
    end
    if self.newLog then
      f:write("\n-----------------------------------------------------\n")
      f:write(os.date().." "..os.time().."\n")
      self.newLog = false
    end
    f:write(...)
    f:write("\n")
    f:close()
  end
end

--
-- Description: Reads a file with properties and store them at a table.
-- Parameter t: Table that will receive the properties.
-- Parameter file: File to be read.
--
function readProperties (self, t, file)
  local f = assert(io.open(file, "r"), "Error opening properties file!")
  while true do
    prop = f:read("*line")
    if prop == nil then
      break
    end
    Log:utils("ReadProperties : Line: " .. prop)
    local a,b = string.match(prop, "%s*(%S*)%s*[=]%s*(.*)%s*")
    if a ~= nil then
      local readonly = false
      local first = string.sub(a, 1, 1)
      if first == '#' then
        a = string.sub(a, 2)
        readonly = true
      end
      t[a] = { name = a, value = b, read_only = readonly }
    end
  end
  f:close()
end

--
-- Description: Prints a table recursively.
--
function print_r (self, t, indent, done)
  done = done or {}
  indent = indent or 0
  if type(t) == "table" then
    for key, value in pairs (t) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        self:print_r (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n", tostring (key),tostring(value)))
      end
    end
  else
    io.write(t .. "\n")
  end
end

--
-- Description: Converts a table with an alphanumeric indice to an array.
-- Parameter message: Table to be converted.
-- Return Value: The array.
--
function convertToArray(self, inputTable)
  Log:utils("ConvertToArray: Begin")
  local outputArray = {}
  local i = 1
  for index, item in pairs(inputTable) do
--    table.insert(outputArray, item)
    if index ~= "n" then
      outputArray[i] = item
      i = i + 1
    end
  end
  Log:utils("ConvertToArray : Finished.")
  return outputArray
end

--
-- Description: Converts a string to a boolean.
-- Parameter str: String to be converted.
-- Return Value: The boolean.
--
function toBoolean(self, inputString)
    Log:utils("StringToBoolean: Begin")
    local inputString = tostring(inputString)
    local result = false
    if string.find(inputString, "true") and string.len(inputString) == 4 then
        result = true
    end
    Log:utils("StringToBoolean : " .. tostring(result) .. ".")
    Log:utils("StringToBoolean : Finished.")
    return result
end

--
-- Description: Converts a ComponentId to a stringified version of its name and version numbers.
-- Parameter componentId: ComponentId to be converted.
-- Return Value: A string containing the stringified version.
--
function getNameVersion(self, componentId)
    return componentId.name .. componentId.major_version .. componentId.minor_version ..
    componentId.patch_version
end

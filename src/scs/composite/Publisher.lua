
local _G = require "_G"
local pairs = _G.pairs
local ipairs = _G.ipairs

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class

local table = table
local type = type
local print = _G.print
local string = string

------------------------------------------------------------------------

module(..., class)

 
__index = memoize(function(method)
--print("-?-", method)
  if string.sub(method,1,2) ~= "__" then 
    return function(self, ...)    
      local list = {}
      for _, object in ipairs(self) do
        table.insert(list, object[method](object, ...))  
      end
      if #list == 0 then
        return
      end

      return simplesFunction(self[1], list)  
    end
  end
end, "k")

function __newindex(self, key, value)
--print("-!-", self, key, value)
	for _, object in pairs(self) do
		object[key] = value
	end
end

------------------------------------------------------------------------
function simplesFunction(obj, list) 
  local f
  
  if #list == 1 then 
    return list[1]
  end
  
  if type(list[1]) == "boolean" then f = obj.opBool 
  elseif type(list[1]) == "number" then f = obj.opNumber 
  elseif type(list[1]) == "string" then f = obj.opString 
  elseif type(list[1]) == "table" then f = obj.opList 
  end
  
  local v = table.remove(list, 1)
  for _,k in ipairs(list) do
    v = f(v, k, #list)
  end
  return v 
end




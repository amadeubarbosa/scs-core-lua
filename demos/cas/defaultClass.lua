
local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class

local io = _G.io
local print = print
local pairs = pairs
local tostring = tostring

------------------------------------------------------------------------

module(..., class)

 
__index = memoize(function(method)
print("-?-", self, key, value)
    return function(self, ...)
      io.write("Método '" .. method .. "'")
      if #arg > 0 then io.write("\n Parâmetros de entrada:\n  ") end
      for _, object in pairs(arg) do
        io.write(tostring(object) .. ", ")
      end
      print "\n"
    end
end, "k")

function __newindex(self, key, value)
print("-!-", self, key, value)
end


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

---
-- Classe respons�vel por repassar as opera��es para os objetos internas. Se existir mais de um objeto
-- cadastrado, � necess�rio implementar as fun��es agregadoras de retornos, s�o elas: opBool, opNumber,
-- opString, opList. Que recebem como par�metro o valor agregador, o valor que se deseja agregar e o
-- o par�metro opcional iteration que calcula qual � a itera��o atual.
--
-- Lembrando que todos os objetos devem ser do mesmo tipo, e devem possuir a implementa��o das mesmas fun��es.
---
module(..., class)


__index = memoize(function(method)
--print("-?-", method)
  if string.sub(method,1,2) ~= "__" then
    return function(self, ...)
      if #self == 1 then
        return object[method](object, ...)
      else
        local list = {}
        for _, object in ipairs(self) do
          table.insert(list, object[method](object, ...))
        end
        if #list == 0 then
          return
        end

        return returnFunction(self[1], list)
      end
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
function returnFunction(obj, list)
  local f

  if #list == 1 then
    return list[1]
  end

  if type(list[1]) == "boolean" then f = obj.opBool
  elseif type(list[1]) == "number" then f = obj.opNumber
  elseif type(list[1]) == "string" then f = obj.opString
  elseif type(list[1]) == "table" then f = obj.opList
  end

  local mainList = table.remove(list, 1)
  for iteration,subList in ipairs(list) do
    mainList = f(mainList, subList, iteration)
  end
  return mainList
end




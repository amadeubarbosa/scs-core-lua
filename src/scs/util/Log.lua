-- $Id: Log.lua 99700 2009-12-04 20:51:35Z rodrigoh $

local Viewer = require "loop.debug.Viewer"
local Verbose = require "loop.debug.Verbose"

---
--Mecanismo para debug do SCS baseado no módulo Verbose provido pelo LOOP
---
local Log = Verbose()

-- Coloca data e hora no log
Log.timed = "%d/%m/%Y %H:%M:%S"

-- Usa uma instância própria do Viewer para não interferir com o do OiL
Log.viewer = Viewer{
  maxdepth = 2,
  indentation = "|  ",
  -- output = io.output()
}

-- Definição dos tags que compõem cada grupo
Log.groups.fatal = {"error"}
Log.groups.basic = {"init", "warn"}
Log.groups.service = {"execution_node", "container", "info"}
Log.groups.core = {"scs", "utils", "config"}
Log.groups.mechanism = {"interceptor", "conn", "debug"}
Log.groups.all = {"fatal", "basic", "service", "core", "mechanism"}

-- Definição dos níveis de debug (em ordem crescente)
Log:newlevel{"fatal"}
Log:newlevel{"basic"}
Log:newlevel{"service"}
Log:newlevel{"core"}
Log:newlevel{"mechanism"}

-- Caso seja necessário exibir o horário do registro
-- timed.basic =  "%d/%m %H:%M:%S"
-- timed.all =  "%d/%m %H:%M:%S"

return Log
-- $Id: Log.lua 99700 2009-12-04 20:51:35Z rodrigoh $

local Viewer = require "loop.debug.Viewer"
local Verbose = require "loop.debug.Verbose"

---
--Mecanismo para debug do SCS baseado no m�dulo Verbose provido pelo LOOP
---
module ("scs.util.Log", Verbose)

-- Coloca data e hora no log
timed = "%d/%m %H:%M:%S"

-- Usa uma inst�ncia pr�pria do Viewer para n�o interferir com o do OiL
viewer = Viewer{
           maxdepth = 2,
           indentation = "|  ",
           -- output = io.output()
         }

-- Defini��o dos tags que comp�em cada grupo
groups.basic = {"init", "warn", "error"}
groups.service = {"execution_node", "container"}
groups.mechanism = {"interceptor", "conn"}
groups.core = {"scs"}
groups.all = {"basic", "service", "core"}

-- Defini��o dos n�veis de debug (em ordem crescente)
_M:newlevel{"basic"}
_M:newlevel{"service"}
_M:newlevel{"core"}

-- Caso seja necess�rio exibir o hor�rio do registro
-- timed.basic =  "%d/%m %H:%M:%S"
-- timed.all =  "%d/%m %H:%M:%S"

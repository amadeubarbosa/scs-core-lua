local print = print
local coroutine = coroutine
local loadfile = loadfile
local assert = assert
local oop = require "loop.simple"

local oil = require "oil"
local utils     = require "scs.core.utils"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")

module ("scs.adaptation.OilUtilities", oop.class)

local utils = utils.Utils() 

function existent(self, proxy)
    utils:verbosePrint("[existent] OilUtilities")
	local not_exists = nil

	--recarregar timeouts de erro (para tempo ser din�mico em tempo de execu��o)
    local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()

	--Tempo total em caso de falha = sleep * MAX_TIMES
	local MAX_TIMES = timeOut.non_existent.MAX_TIMES
	local timeToTrie = 1
	local threadTime = timeOut.non_existent.sleep
	local executedOK = nil
	local parent = oil.tasks.current

	local thread = coroutine.create(function()
			   executedOK, not_exists = oil.pcall(proxy._non_existent, proxy)
			   oil.tasks:resume(parent)
	end)
	
	while executedOK == nil do
	
	  oil.tasks:resume(thread)
	  oil.tasks:suspend(threadTime)
	  oil.tasks:remove(thread)
	  
	  timeToTrie = timeToTrie + 1
	  
	  if timeToTrie > MAX_TIMES then
	     break
	  end
    end
    
    if executedOK == nil and not_exists == nil then
        return false, "call timeout"   
    elseif not_exists ~= nil then
       if executedOK and not not_exists then		
          return true
       else		
          return false, not_exists
       end
    else
       return false, not_exists
    end
end



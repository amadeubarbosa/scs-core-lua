local Receptacles = require "scs.core.Receptacles"
local oop = require "loop.simple"
local print = print
local pairs = pairs
local tostring = tostring

local oil = require "oil"

local utils = require "scs.core.utils"
local OilUtilities = require "scs.util.OilUtilities"

module("scs.adaptation.AdaptiveReceptacle")

--
-- Receptacles Class
-- Implementation of the IReceptacles Interface from scs.idl
--

AdaptiveReceptacleFacet = oop.class({}, Receptacles)

--The first of the list always starts as the leader

function AdaptiveReceptacleFacet:__init()
  self = Receptacles.__init(self)
  self.activeConnId = 1
  self.utils = utils.Utils()
  return self
end

function AdaptiveReceptacleFacet:updateActiveConnId(conns)
  self.utils:verbosePrint("[AdaptiveReceptacleFacet:updateActiveConnId]")
  if # conns == 0 then
  --if the list is empty, there aren't active receptacle
     self.activeConnId = 0
  else
    if self.activeConnId == # conns then
        self.activeConnId = 1
      else
          self.activeConnId = self.activeConnId + 1
    end
  end
end

--
--@see scs.core.Receptacles#connect
--
-- Description: Connects an object to the specified receptacle.
-- Parameter receptacle: The receptacle's name that corresponds to the interface implemented by the
--             provided object.
-- Parameter object: The CORBA object that implements the expected interface.
-- Return Value: The connection's identifier.
--
function AdaptiveReceptacleFacet:connect(receptacle, object)
  self.utils:verbosePrint("[AdaptiveReceptacleFacet:connect]")

  self:updateConnections(receptacle)
  -- Connects the service at the receptacle
  local connId = Receptacles.connect(self,
                          receptacle,
                          object) -- calling inherited method
  if not connId then
    self.utils:verbosePrint("Failure attempting to connect service")
    return connId
  elseif connId == 1 then
  -- this is the first to connect
  -- make sure that the reference to the leader is correct
    self.activeConnId = 1
  end
  self.utils:verbosePrint("[AdaptiveReceptacleFacet:connect] Service was connected successefully")
  return connId

end

--
--@see scs.core.Receptacles#disconnect
--
-- Description: Disconnects an object from a receptacle.
-- Parameter connId: The connection's identifier.
--
function AdaptiveReceptacleFacet:disconnect(connId)
  self.utils:verbosePrint("[AdaptiveReceptacleFacet:disconnect]")
  Receptacles.disconnect(self,connId) -- calling inherited method
end

--
--@see scs.core.Receptacles#getConnections
--
-- Description: Provides information about all the current connections of a receptacle.
-- Parameter receptacle: The receptacle's name.
-- Return Value: All current connections of the specified receptacle.
--
function AdaptiveReceptacleFacet:getConnections(receptacle)
  self.utils:verbosePrint("[AdaptiveReceptacleFacet:getConnections]")
  self:updateConnections(receptacle)
  return Receptacles.getConnections(self,receptacle) -- calling inherited method
end

--
--@see AdaptiveReceptacleFacet#updateConnections
--
-- Description: Disconnects any non existent service of a receptacle.
-- Parameter receptacle: The receptacle's name.
--
function AdaptiveReceptacleFacet:updateConnections(receptacle)
  self.utils:verbosePrint("[AdaptiveReceptacleFacet:updateConnections]")
  local conns = Receptacles.getConnections(self,receptacle)
  if conns then
  -- each connected service is tested,
  -- if a communication failure happened, the service is disconnected
    local alreadyUpdated = false
    for connId,conn in pairs(conns) do
      self.utils:verbosePrint("[AdaptiveReceptacleFacet:updateConnections] Testing conection [".. tostring(connId) .."]")
      local serviceRec = self.context:getORB():narrow(conn.objref, "IDL:scs/core/IComponent:1.0")
      if not OilUtilities:existent(serviceRec) then
        self.utils:verbosePrint("[AdaptiveReceptacleFacet:updateConnections] The service was not found. It will be disconnected from receptacle.")
        -- serviceRec esta com falha -> desconectar
        local succ, err = oil.pcall(self.disconnect, self, connId)
        if not succ then
          self.utils:verbosePrint("[AdaptiveReceptacleFacet:updateConnections] Error:" .. err[1])
        end
        if self.activeConnId == connId and not alreadyUpdated then
        --atualiza receptacle lider
          self:updateActiveConnId(conns)
          alreadyUpdated = true
        end
      end
    end
  end
end

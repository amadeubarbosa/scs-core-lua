
local scs = require "scs.core.base"
local oop = require "loop.simple"
local print = print
local pairs = pairs
local tostring = tostring

local oil = require "oil"
local orb = oil.orb

local utils     = require "scs.core.utils"
local TableDB       = require "scs.util.TableDB"
local OilUtilities = require "scs.adaptation.OilUtilities"

module("scs.adaptation.PersistentReceptacle")

--
-- PersistentReceptacle Class
-- Implementation of the IReceptacles Interface from scs.idl
--

PersistentReceptacleFacet = oop.class({}, scs.adaptation.AdaptiveReceptacle)

function PersistentReceptacleFacet:__init(dbfile)
  self = scs.adaptation.AdaptiveReceptacle.__init(self)
  self.connectionsDB = TableDB(dbfile)
  --used to load data during getConnections at the first time
  self.firstRequired = true
  return self
end

function PersistentReceptacleFacet:connect(receptacle, object)
  self.utils:verbosePrint("[PersistentReceptacleFacet:connect]")

  local connId = scs.adaptation.AdaptiveReceptacle.connect(self, receptacle, object)
  if type(connId) == "number" then
    if not self.connectionsDB:get(connId) then
    --saves onle if it is not already saved
      self.connectionsDB:save(connId, orb:tostring(object))
    end
  end
  return connId
end

--
--@see scs.core.Receptacles#disconnect
--
-- Description: Disconnects an object from a receptacle.
-- Parameter connId: The connection's identifier.
--
function PersistentReceptacleFacet:disconnect(connId)
  self.utils:verbosePrint("[PersistentReceptacleFacet:disconnect]")
  if self.connectionsDB:get(connId) then
  --removes only if exists
    self.connectionsDB:remove(connId)
  end
  return scs.adaptation.AdaptiveReceptacle.disconnect(self,connId) -- calling inherited method
end

function PersistentReceptacleFacet:getConnections(receptacle)
  self.utils:verbosePrint("[PersistentReceptacleFacet:getConnections]")
  if self.firstRequired then
    -- Load the connections
    local data = assert(self.connectionsDB:getValues())
    for connId, objIOR in ipairs(data) do
      local object = newproxy(objIOR)
      local newConnId = scs.adaptation.AdaptiveReceptacle.connect(self, receptacle, object)
      if newConnId ~= connId then
        --update the connId only if the new one is different from the one saved
        self.connectionsDB:remove(connId, object)
        self.connectionsDB:save(newConnId, object)
      end
    end
    self.firstRequired = false
  end
  return scs.adaptation.AdaptiveReceptacle.getConnections(self,receptacle) -- calling inherited method
end

local ipairs = ipairs
local assert = assert
local scs = require "scs.core.base"
local oop = require "loop.simple"
local print = print
local pairs = pairs
local tostring = tostring
local type = type
local tonumber = tonumber
local error = error

local oil = require "oil"
local orb = oil.orb

local utils     = require "scs.core.utils"
local OilUtilities = require "scs.adaptation.OilUtilities"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

module("scs.adaptation.PersistentReceptacle")

--
-- PersistentReceptacle Class
-- Implementation of the IReceptacles Interface from scs.idl
--

PersistentReceptacleFacet = oop.class({}, AdaptiveReceptacle.AdaptiveReceptacleFacet)


-- Description: Creates an instance of the receptacle.
-- Parameter dbmanager: represents the persistent db manager.
--           This manager must implement 'save', 'remove', and 'get'
--           SCS provides an implementation for this manager.
--           Check the file /util/TableDB.lua
-- Example of instantiation and usage during Component configuration:
--   local receptFacetRef = orb:newservant(MyService.ReceptacleFacet(TableDB(dbfile)),
--                                        "","IDL:scs/core/IReceptacles:1.0")
--   facetDescriptions.IReceptacles.facet_ref      = receptFacetRef

function PersistentReceptacleFacet:__init(dbmanager)
  --Checks if dbmanager implements the required operations
  if type(dbmanager.save) ~= "function"   or
     type(dbmanager.remove) ~= "function" or
     type(dbmanager.get) ~= "function"    then
     error ( orb:newexcept{"CORBA::PERSIST_STORE"}[1] )
  end
  self = AdaptiveReceptacle.AdaptiveReceptacleFacet.__init(self)
  self.connectionsDB = dbmanager
  --used to load data during getConnections at the first time
  self.firstRequired = true
  return self
end

function PersistentReceptacleFacet:connect(receptacle, object)
  self.utils:verbosePrint("[PersistentReceptacleFacet:connect]")

  local connId = AdaptiveReceptacle.AdaptiveReceptacleFacet.connect(self, receptacle, object)
  if type(connId) == "number" then
    if not self.connectionsDB:get(connId) then
    --saves onle if it is not already saved
      self.connectionsDB:save(tonumber(connId), orb:tostring(object))
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
  return AdaptiveReceptacle.AdaptiveReceptacleFacet.disconnect(self,connId) -- calling inherited method
end

function PersistentReceptacleFacet:getConnections(receptacle)
  self.utils:verbosePrint("[PersistentReceptacleFacet:getConnections]")
  if self.firstRequired then
    -- Load the connections
    local data = assert(self.connectionsDB:getValues())
    for connId, objIOR in ipairs(data) do
      local object = orb:newproxy(objIOR, "synchronous", oil.corba.idl.object)
      if OilUtilities:existent(object) then
        local newConnId = self:connect(receptacle, object)
        if newConnId ~= connId then
          --update the connId only if the new one is different from the one saved
          self.connectionsDB:remove(connId)
          self.connectionsDB:save(tonumber(newConnId), objIOR)
        end
      else
         self.connectionsDB:remove(connId)
      end
    end
    self.firstRequired = false
  end
  return AdaptiveReceptacle.AdaptiveReceptacleFacet.getConnections(self,receptacle) -- calling inherited method
end

local oop = require "loop.simple"
local oil = require "oil"
local Log = require "scs.util.Log"
local utils = require "scs.core.utils"
local OilUtilities = require "scs.util.OilUtilities"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

local ipairs = ipairs
local assert = assert
local pairs = pairs
local pcall = pcall
local tostring = tostring
local type = type
local tonumber = tonumber
local error = error


--
-- PersistentReceptacle Class
-- Implementation of the IReceptacles Interface from scs.idl
--

local PersistentReceptacleFacet = oop.class({}, AdaptiveReceptacle.AdaptiveReceptacleFacet)


-- Description: Creates an instance of the receptacle.
-- Parameter dbmanager: represents the persistent db manager.
--           This manager must implement 'save', 'remove', and 'get'
--           SCS provides an implementation for this manager.
--           Check the file /util/TableDB.lua
-- Example of instantiation and usage during Component configuration:
--   local receptFacetRef = orb:newservant(MyService.ReceptacleFacet(TableDB(dbfile)),
--                                        "","IDL:scs/core/IReceptacles:1.0")
--   facetDescriptions.IReceptacles.facet_ref      = receptFacetRef

function PersistentReceptacleFacet:__new(dbmanager)
  --Checks if dbmanager implements the required operations
  if type(dbmanager.save) ~= "function"   or
     type(dbmanager.remove) ~= "function" or
     type(dbmanager.get) ~= "function"    then
     error ( self.context:getORB():newexcept{"CORBA::PERSIST_STORE"}[1] )
  end
  self = AdaptiveReceptacle.AdaptiveReceptacleFacet.__new(self)
  self.connectionsDB = dbmanager
  --used to load data during getConnections at the first time
  self.firstRequired = true
  return self
end

function PersistentReceptacleFacet:connect(receptacle, object)
  Log:scs("[PersistentReceptacleFacet:connect]")

  local status, connId = pcall(AdaptiveReceptacle.AdaptiveReceptacleFacet.connect,
                                   self, receptacle, object)
  if status then
    if type(connId) == "number" then
      if not self.connectionsDB:get(connId) then
      --saves onle if it is not already saved
        self.connectionsDB:save(tonumber(connId), tostring(object))
      end
    end
  else
    --couldnt connect, the error must be propagated
    error{ connId[1] }
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
  Log:scs("[PersistentReceptacleFacet:disconnect]")
  if self.connectionsDB:get(connId) then
  --removes only if exists
    self.connectionsDB:remove(connId)
  end
  local status, err = pcall(AdaptiveReceptacle.AdaptiveReceptacleFacet.disconnect, self,connId) -- calling inherited method
  if not status then
    error { err[1] }
  end
end

function PersistentReceptacleFacet:getConnections(receptacle)
  Log:scs("[PersistentReceptacleFacet:getConnections]")
  if self.firstRequired then
    -- Load the connections
    local data = assert(self.connectionsDB:getValues())
    for connId, objIOR in ipairs(data) do
      local object = self.context:getORB():newproxy(objIOR, "synchronous", oil.corba.idl.object)
      if OilUtilities:existent(object) then
        local status, newConnId = pcall(self.connect, self, receptacle, object)
        if status then
          if newConnId ~= connId then
            --update the connId only if the new one is different from the one saved
            self.connectionsDB:remove(connId)
            self.connectionsDB:save(tonumber(newConnId), objIOR)
          end
        end
      else
         self.connectionsDB:remove(connId)
      end
    end
    self.firstRequired = false
  end
  return AdaptiveReceptacle.AdaptiveReceptacleFacet.getConnections(self,receptacle) -- calling inherited method
end

local module = {
  PersistentReceptacleFacet = PersistentReceptacleFacet
}

return module

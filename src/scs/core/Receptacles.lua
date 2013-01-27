--
-- SCS
-- receptacles.lua
-- Description: IReceptacles interface base implementation
-- Version: 1.0
--

local oo    = require "loop.base"
local oil   = require "oil"
local utils = require "scs.core.utils"
utils = utils()

local error = error
local pcall = pcall
local type = type

--------------------------------------------------------------------------------

module ("scs.core.Receptacles", oo.class)

--------------------------------------------------------------------------------

function __new(self)
  return oo.rawnew(self, {_nextConnId = 0, _maxConnections = 100,
                          _numConnections = 0, _receptsByConId = {}})
end

--
-- Description: Connects an object to the specified receptacle.
-- Parameter receptacle: The receptacle's name that corresponds to the interface
-- implemented by the provided object.
-- Parameter object: The CORBA object that implements the expected interface.
-- Return Value: The connection's identifier.
--
function connect(self, receptacle, object)
  local context = self.context
  local desc = context._receptacles[receptacle]
  if not desc then
    error{ _repid = "IDL:scs/core/InvalidName:1.0", name = receptacle }
  end
  if not object then
    error{ _repid = "IDL:scs/core/InvalidConnection:1.0" }
  end
  local status, err
  if object._is_a then
    status, err = pcall(object._is_a, object, desc.interface_name)
  else
    -- This oil version does not provide an easy way to call the _is_a method on
    -- local objects with collocation enabled.
    -- Thus, the below two lines are a temporary workaround for this problem.
    local iface = object.__type
    if type(iface) == "table" and iface.is_a then
      status, err = pcall(iface.is_a, iface, desc.interface_name)
    end
  end
  if not (status and err) then
    error{ _repid = "IDL:scs/core/InvalidConnection:1.0" }
  end
  object = context._orb:narrow(object, desc.interface_name)

  if (self._numConnections >= self._maxConnections) then
    error{ _repid = "IDL:scs/core/ExceededConnectionLimit:1.0" }
  end

  -- it's not possible to use the '#' operator to find out the number of
  -- connections. There are 2 causes:
  -- a) If a connection(ex: connId 3) is unmade the index sequence gets broken
  --    (i.e. 1, 2, 4, 5, ...) and the operator may return a wrong size.
  -- b) The number of connections is per component, not per receptacle.
  if not desc.is_multiplex and self._numConnections > 0 then
    error{ _repid = "IDL:scs/core/AlreadyConnected:1.0" }
  end

  self._nextConnId = self._nextConnId + 1
  desc.connections[self._nextConnId] = {id = self._nextConnId, objref = object}
  self._receptsByConId[self._nextConnId] = desc

  self._numConnections = self._numConnections + 1

  return self._nextConnId
end

--
-- Description: Disconnects an object from a receptacle.
-- Parameter connId: The connection's identifier.
--
function disconnect(self, connId)
  local context = self.context
  local desc = self._receptsByConId[connId]

  if connId <= 0 then
    error{ _repid = "IDL:scs/core/InvalidConnection:1.0" }
  end

  if not desc then
    error{ _repid = "IDL:scs/core/NoConnection:1.0" }
  end

  desc.connections[connId] = nil
  self._receptsByConId[connId] = nil
  self._numConnections = self._numConnections - 1
end

--
-- Description: Provides information about all the current connections of a
-- receptacle.
-- Parameter receptacle: The receptacle's name.
-- Return Value: All current connections of the specified receptacle.
--
function getConnections(self, receptacle)
  self = self.context
  if self._receptacles[receptacle] then
    return utils:convertToArray(self._receptacles[receptacle].connections)
  end
  error{ _repid = "IDL:scs/core/InvalidName:1.0", name = receptacle }
end


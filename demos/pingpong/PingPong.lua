local oil    = require "oil"
local oo     = require "loop.base"

--------------------------------------------------------------------------------
-- PingPongServer Facet
--------------------------------------------------------------------------------

PingPongServer = oo.class{ id = 0, stop = false }

function PingPongServer:__init()
  return oo.rawnew(self, {})
end

function PingPongServer:ping()
  if self.stop == true then
    return
  end
  print("PingPong " .. self.id .. " received ping from PingPong " .. self.otherPP:getId() .. "! Ponging in 3 seconds...")
  oil.sleep(3)
  oil.newthread(self.otherPP.pong, self.otherPP)
end

function PingPongServer:pong()
  if self.stop == true then
    return
  end
  print("PingPong " .. self.id .. " received pong from PingPong " .. self.otherPP:getId() .. "! Pinging in 3 seconds...")
  oil.sleep(3)
  oil.newthread(self.otherPP.ping, self.otherPP)
end

function PingPongServer:setId(id)
  self.id = id
end

function PingPongServer:getId()
  return self.id
end

function PingPongServer:start()
  print("PingPong " .. self.id .. " received an start call!")
  self.stop = false
  oil.newthread(self.otherPP.ping, self.otherPP)
end

function PingPongServer:stop()
  self.stop = true
end

--------------------------------------------------------------------------------
-- IComponent Facet
--------------------------------------------------------------------------------

function PPStartup (self)
  self = self.context
  self.utils:verbosePrint("PingPong::IComponent::Startup")
  if self.IReceptacles._numConnections ~= 1 then
    error{"IDL:scs/core/StartupFailed:1.0"}
  end
  self.PingPongServer.otherPP = self.IReceptacles:getConnections("PingPongReceptacle")[1].objref
  self.utils:verbosePrint("PingPong::IComponent::Startup : Done.")
end

function PPShutdown (self)
  self = self.context
  self.utils:verbosePrint("PingPong::IComponent::Shutdown")
  self.PingPongServer.stop = true
  self.utils:verbosePrint("PingPong::IComponent::Shutdown : Done.")
end


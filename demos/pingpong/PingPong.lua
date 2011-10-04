local oil       = require "oil"
local oo        = require "loop.base"
local oos       = require "loop.simple"
local Component = require "scs.core.Component"
local Log       = require "scs.util.Log"

--------------------------------------------------------------------------------
-- PingPongServer Facet
--------------------------------------------------------------------------------

PingPongServer = oo.class{ id = 0, stop = false }

function PingPongServer:__new()
  return oo.rawnew(self, {})
end

function PingPongServer:ping()
  if self.stop == true then
    return
  end
  Log:info("PingPong " .. self.id .. " received ping from PingPong " .. self.otherPP:getId() .. "! Ponging in 3 seconds...")
  oil.sleep(3)
  oil.newthread(self.otherPP.pong, self.otherPP)
end

function PingPongServer:pong()
  if self.stop == true then
    return
  end
  Log:info("PingPong " .. self.id .. " received pong from PingPong " .. self.otherPP:getId() .. "! Pinging in 3 seconds...")
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
  Log:info("PingPong " .. self.id .. " received an start call!")
  self.stop = false
  oil.newthread(self.otherPP.ping, self.otherPP)
end

function PingPongServer:stop()
  self.stop = true
end

--------------------------------------------------------------------------------
-- IComponent Facet
--------------------------------------------------------------------------------

PingPongIComponent = oos.class({}, Component)

function PingPongIComponent:__new()
  self = Component.__new(self)
  return self
end

function PingPongIComponent:startup()
  local context = self.context
  Log:config("PingPong::IComponent::Startup")
  if context.IReceptacles._numConnections ~= 1 then
    error{"IDL:scs/core/StartupFailed:1.0"}
  end
  context.PingPongServer.otherPP = context.IReceptacles:getConnections("PingPongReceptacle")[1].objref
  Log:config("PingPong::IComponent::Startup : Done.")
end

function PingPongIComponent:shutdown()
  local context = self.context
  Log:config("PingPong::IComponent::Shutdown")
  context.PingPongServer.stop = true
  Log:config("PingPong::IComponent::Shutdown : Done.")
end


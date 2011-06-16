local oo    = require "loop.base"

Hello = oo.class{name = "World"}

function Hello:__init()
  return oo.rawnew(self, {})
end

function Hello:sayHello()
  print("Hello " .. self.name .. "!")
end


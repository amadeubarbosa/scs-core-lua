local oo    = require "loop.base"

Hello = oo.class{name = "World"}

function Hello:__new()
  return oo.rawnew(self, {})
end

function Hello:sayHello()
  print("Hello " .. self.name .. "!")
end


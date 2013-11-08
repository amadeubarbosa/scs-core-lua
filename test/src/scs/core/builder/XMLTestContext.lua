local oo = require "loop.simple"

local ComponentContext = require "scs.core.ComponentContext"

--------------------------------------------------------------------------------

local XMLTestContext = oo.class({}, ComponentContext)

function XMLTestContext.retTrue(self) return true end

return XMLTestContext

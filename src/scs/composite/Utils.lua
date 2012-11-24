
-- Podemos encapsular o utils antigo
local CoreUtils = require "scs.core.utils"
local oo = require "loop.simple"
local class = oo.class

local Utils = class({}, CoreUtils)

Utils.ICONTENTCONTROLLER_NAME = "IContentController"
Utils.ICONTENTCONTROLLER_INTERFACE = "IDL:scs/core/IContentController:1.0"
Utils.ISUPERCOMPONENT_NAME = "ISuperComponent"
Utils.ISUPERCOMPONENT_INTERFACE = "IDL:scs/core/ISuperComponent:1.0"


return Utils

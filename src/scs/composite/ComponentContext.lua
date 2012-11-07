

--
-- SCS
-- ComponentContext.lua
-- Description:
-- Version: 1.0
--

local ISuperComponent = require "scs.core.ISuperComponent"
local SuperComponentContext = require "scs.core.ComponentContext"
local class = require "loop.simple"
local utils = require "scs.composite.utils"
utils = utils()


local ComponentContext = class({}, SuperComponentContext)

function ComponentContext:addBasicFacets(basicKeys)
	local basicKeys = basicKeys or {}
	SuperComponentContext:addBasicFacets(basicKeys)
	addBasicFacet(self, utils.ICONTENTCONTROLLER_NAME,
			utils.ICONTENTCONTROLLER_INTERFACE,
			ISuperComponent(), basicKeys.ISuperComponent)
end

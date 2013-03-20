--
-- SCS
-- IReceptacles.lua
-- Description: Implementacao de IReceptacles que estende da implementacao base (SCS-Core)
-- Version: 1.0
--

local SuperIReceptacles = require "scs.core.Receptacles"
local oo = require "loop.simple"
local class = oo.class
local utils = require "scs.composite.Utils"
local compositeIdl = require "scs.composite.Idl"
local Log = require "scs.util.Log"
utils = utils()
------------------------------------------------------------------------

local IReceptacles = class({}, SuperIReceptacles)

function IReceptacles:__new(orb, id, basicKeys)
  local receptacles = SuperIReceptacles()
  receptacles.connect = newConnect

  return receptacles
end

---
-- Conecta uma conexão ao receptaculo selecionado.
-- @remark A funcao verifica se a conexão pode ser adicionada no componente
--
---
function newConnect(self, name, connection)
  local context = self.context
  local orb = context._orb

  if isBinded(context, name) then
    local receptacleDesc = context:getReceptacleByName(name).bind
    local bindDesc = receptacleDesc.facet
    local bindIReceptacle = receptacleDesc.facet
    local receptacleName = receptacleDesc.internalName

    Log:info("Adicionando receptaculo ao bind")

    bindIReceptacle:connect(receptacleName, connection)
  end

  return SuperIReceptacles.connect(self, name, connection)
end

function isBinded(context, name)
  if not context:getReceptacleByName(name) then
    return false
  end
  return (context:getReceptacleByName(name).bind ~= nil)
end

return IReceptacles

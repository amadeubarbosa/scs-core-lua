local oil = require "oil"
local ComponentContext = require "scs.composite.ComponentContext"
local Log = require "scs.util.Log"

local utils = require "scs.composite.Utils"
utils = utils()

Log:level(5)

-- OiL configuration
local orb = oil.init()
local helloFacetName = "Hello"
local helloFacetInterface = "IDL:scs/demos/helloworld/Hello:1.0"

oil.main(function()
  local idlPath = os.getenv("IDL_PATH")
  orb:loadidlfile(idlPath .. "/scs.idl")
  orb:loadidlfile(idlPath .. "/composite.idl")
  orb:loadidlfile(idlPath .. "/hello.idl")
  oil.newthread(orb.run, orb)

  --Getting proxy to primitive component
  local serverIOR = oil.readfrom("server.ior")
  local compositeComponent = orb:newproxy(serverIOR)

  local helloFacet = compositeComponent:getFacetByName("IHelloX")
  helloFacet = orb:narrow(helloFacet, helloFacetInterface)
  if not helloFacet then
    print("[ERROR] Faceta não encontrada.")
    os.exit(1)
  end

  helloFacet:sayHello()
  return
end)


require "oil"
oil.main(function()
  oil.loadidlfile("../../../../../idl/scs.idl")
  local SCS = oil.newproxy(assert(oil.readfrom("../core.ior")))
  local status, error = oil.pcall(SCS.startup, SCS)
  if not status then
    print(error)
    return
  end

  local status, rcpFacet = oil.pcall(SCS.getFacet, SCS, "IDL:scs/core/IReceptacles:1.0")
  if not status then
    print("[IReceptacles::IComponent] Error while calling getFacet(IDL:scs/core/IReceptacles:1.0)")
    print("[IReceptacles::IComponent] Error: " .. rcpFacet)
    return
  end
  rcpFacet:_narrow()

  receptacleName = "defaultName"
  local object = oil.newproxy(assert(oil.readfrom("../object.ior")))
  
  local status, connectionId = oil.pcall(rcpFacet.connect, rcpFacet, receptacleName, object)
  if not status then
    print("[IReceptacles::IReceptacles] Error while calling connect")
    print("[IReceptacles::IReceptacles] Error: " .. connectionId)
    return
  end
  
  print("connect executed successfully!")
  print("This connectionId = " .. connectionId)
end)

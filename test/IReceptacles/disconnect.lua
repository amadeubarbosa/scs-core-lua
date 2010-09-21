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

  local connectionId = 1
  
  local status, void = oil.pcall(rcpFacet.disconnect, rcpFacet, connectionId)
  if not status then
    print("[IReceptacles::IReceptacles] Error while calling disconnect")
    print("[IReceptacles::IReceptacles] Error: " .. void)
    return
  end
  
  print("disconnect executed successfully!")
end)

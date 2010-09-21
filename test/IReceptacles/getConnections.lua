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

  local receptacleName = "defaultName"
  
  local status, connectionDescriptions = oil.pcall(rcpFacet.getConnections, rcpFacet, receptacleName)
  if not status then
    print("[IReceptacles::IReceptacles] Error while calling getConnections")
    print("[IReceptacles::IReceptacles] Error: " .. connectionDescriptions)
    return
  end
  
  if not connectionDescriptions then
    print("[IReceptacles::IReceptacles] Warning: getConnections returned a nil Connection Descriptions")
  else
    print("Printing Connection Descriptions ... ")
    for k, connDescription in pairs(connectionDescriptions) do
      print("Index = " .. k)
      print("  ConnectionId \t= " .. connDescription.id)
      print("  Object \t= " .. connDescription.objref)
    end
  end
  
  print("getConnections executed successfully!")
end)

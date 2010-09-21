require "oil"
oil.main(function()
  oil.loadidlfile("../../../../../idl/scs.idl")
  local SCS = oil.newproxy(assert(oil.readfrom("../core.ior")))
  local status, error = oil.pcall(SCS.startup, SCS)
  if not status then
    print(error)
    return
  end

  local status, miFacet = oil.pcall(SCS.getFacet, SCS, "IDL:scs/core/IMetaInterface:1.0")
  if not status then
    print("[IMetaInterface::IComponent] Error while calling getFacet(IDL:scs/core/IMetaInterface:1.0)")
    print("[IMetaInterface::IComponent] Error: " .. miFacet)
    return
  end
  rcpFacet:_narrow()
  
  local status, receptacleDescriptions = oil.pcall(miFacet.getReceptacles, miFacet)
  if not status then
    print("[IMetaInterface::IMetaInterface] Error while calling getReceptacles")
    print("[IMetaInterface::IMetaInterface] Error: " .. receptacleDescriptions)
    return
  end
  
  if not receptacleDescriptions then
    print("[IMetaInterface::IMetaInterface] Warning: getReceptacles returned a nil Receptacles Descriptions")
  else
    print("Printing Receptacles Descriptions ... ")
    for k, rcpDescription in pairs(receptacleDescriptions) do
      print("Index = " .. k)
      print("  name \t= " .. rcpDescription.name)
      print("  interface_name \t= " .. rcpDescription.interface_name)
      print("  is_multiplex \t= " .. rcpDescription.is_multiplex)
      print("  ConnectionDescriptions \t= " .. rcpDescription.connections)
    end
  end
  
  print("getReceptacles executed successfully!")
end)

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
  
  local nameList = { 1 = "defaultName1", 2 = "defaultName2", 3 = "defaultName3" }
  
  local status, facetDescriptions = oil.pcall(miFacet.getFacetsByName, miFacet, nameList)
  if not status then
    print("[IMetaInterface::IMetaInterface] Error while calling getFacetsByName")
    print("[IMetaInterface::IMetaInterface] Error: " .. facetDescriptions)
    return
  end
  
  if not facetDescriptions then
    print("[IMetaInterface::IMetaInterface] Warning: getFacetsByName returned a nil Receptacles Descriptions")
  else
    print("Printing Facets Descriptions ... ")
    for k, fctDescription in pairs(facetDescriptions) do
      print("Index = " .. k)
      print("  name \t= " .. fctDescription.name)
      print("  interface_name \t= " .. fctDescription.interface_name)
      print("  facet_ref \t= " .. fctDescription.facet_ref)
    end
  end
  
  print("getFacetsByName executed successfully!")
end)

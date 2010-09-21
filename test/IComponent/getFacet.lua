require "oil"
oil.main(function()
  oil.loadidlfile("../../../../../idl/scs.idl")
  local SCS = oil.newproxy(assert(oil.readfrom("../core.ior")))
  local status, error = oil.pcall(SCS.startup, SCS)
  if not status then
    print(error)
    return
  end
  
  --facetInterfaceName = "IDL:scs/core/IComponent:1.0"
  local facetInterfaceName = "defaultFacetInterfaceName"

  local status, cmpFacet = oil.pcall(SCS.getFacet, SCS, facetInterfaceName)
  if not status then
    print("[IComponent::IComponent] Error while calling getFacet(" .. facetInterfaceName .. ")")
    print("[IComponent::IComponent] Error: " .. cmpFacet)
    return
  end
  cmpFacet:_narrow()

  print("getFacet executed successfully!")
end)

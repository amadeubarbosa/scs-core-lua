require "oil"
oil.main(function()
  oil.loadidlfile("../../../../../idl/scs.idl")
  local SCS = oil.newproxy(assert(oil.readfrom("../core.ior")))
  local status, error = oil.pcall(SCS.startup, SCS)
  if not status then
    print(error)
    return
  end
  
  local facetName = "defaultName"

  local status, cmpFacet = oil.pcall(SCS.getFacetByName, SCS, facetName)
  if not status then
    print("[IComponent::IComponent] Error while calling getFacetByName(" .. facetName .. ")")
    print("[IComponent::IComponent] Error: " .. cmpFacet)
    return
  end
  cmpFacet:_narrow()

  print("getFacetByName executed successfully!")
end)

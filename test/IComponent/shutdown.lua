require "oil"
oil.main(function()
  oil.loadidlfile("../../../../../idl/scs.idl")
  local SCS = oil.newproxy(assert(oil.readfrom("../core.ior")))
  local status, error = oil.pcall(SCS.shutdown, SCS)
  if not status then
    print(error)
    return
  end
  
  print("shutdown executed successfully!")
end)

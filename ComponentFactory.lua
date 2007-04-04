--
-- @author Carlos Eduardo Lara Augusto
--
--require "oil"
require "SCSUtils"
--oil.loadidlfile("../deployment.idl")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------        CONSTRUCTOR        ---------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SCSObject = {facets = {}, facetsByName = {}, receptacles = {}, receptaclesByConId = {}, maxReceptacleId = 0, numConnections = 0, maxConnections = 1000}

function SCSObject:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------        EXPORTED FUNCTIONS        ------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
ComponentFactory = {}

function ComponentFactory:createSCSObject()
	local obj = SCSObject:new()

	obj.implComponent = obj:new()
	obj.implReceptacles = obj:new()
	obj.implMetaInterface = obj:new()

	obj.objComponent = oil.newobject(obj.implComponent, "IDL:SCS/IComponent:1.0")
	obj.objReceptacles = oil.newobject(obj.implReceptacles, "IDL:SCS/IReceptacles:1.0")
	obj.objMetaInterface = oil.newobject(obj.implMetaInterface, "IDL:SCS/IMetaInterface:1.0")
	
	obj.facets["IDL:SCS/IComponent:1.0"] = {name = "IComponent", interface_name = "IDL:SCS/IComponent:1.0", facet_ref = obj.objComponent}
	obj.facets["IDL:SCS/IReceptacles:1.0"] = {name = "IReceptacles", interface_name = "IDL:SCS/IReceptacles:1.0", facet_ref = obj.objReceptacles}
	obj.facets["IDL:SCS/IMetaInterface:1.0"] = {name = "IMetaInterface", interface_name = "IDL:SCS/IMetaInterface:1.0", facet_ref = obj.objMetaInterface}
	
	obj.facetsByName["IComponent"] = obj.facets["IDL:SCS/IComponent:1.0"]
	obj.facetsByName["IReceptacles"] = obj.facets["IDL:SCS/IReceptacles:1.0"]
	obj.facetsByName["IMetaInterface"] = obj.facets["IDL:SCS/IMetaInterface:1.0"]
	
	obj.utils = SCSUtils:create()
	
	--------------------------------------------
	--------------------------------------------
	----        ICOMPONENT FUNCTIONS        ----
	--------------------------------------------
	--------------------------------------------
	
	--
	-- Description: Starts the Component.
	--
	function obj.implComponent:startup()
	end
	
	--
	-- Description: Shuts down the Component.
	--
	function obj.implComponent:shutdown()
	end
	
	--
	-- Description: Returns a facet by its interface name.
	-- Parameter facet_interface: Interface name.
	--
	function obj.implComponent:getFacet(facet_interface)
		local f = self.facets[facet_interface]
		if not f then return nil end
		return f.facet_ref
	end
	
	--
	-- Description: Returns a facet by its name.
	-- Parameter facet: Facet name.
	--
	function obj.implComponent:getFacetByName(facet)
		local f = self.facetsByName[facet]
		if not f then return nil end
		return f.facet_ref
	end
	
	---------------------------------------------
	---------------------------------------------
	----        IRECEPTACLE FUNCTIONS        ----
	---------------------------------------------
	---------------------------------------------
	
	--		Componente/Faceta:Versao = {
	--										name = "IComponent",
	--										interface_name = "IDL:SCS/IComponent:1.0",
	--										is_multiplex = false,
	--										connections = {
	--     	  												1 = {
	--															id = 1,
	--      															objref = object1
	--														}
	--    	  												3 = {
	--															id = 3,
	--      															objref = object3
	--														}
	--								  					  }
	--								   }
	
	--
	-- Description: Connects a component facet.
	-- Parameter receptacle: Receptacle's name.
	-- Parameter obj: Remote object reference.
	-- Return Value: Connection identifier.
	-- Throws: IDL:InvalidConnection, InvalidParameter, ExceededConnectionLimit, AlreadyConnected exceptions
	--
	function obj.implReceptacles:connect(receptacle, object)
		assert(receptacle, "IDL:InvalidParameter")
		assert(object, "IDL:InvalidConnection")
		assert(self.receptacles[receptacle], "IDL:InvalidName")
		assert(self.numConnections <= self.maxConnections, "IDL:ExceededConnectionLimit")
		-- test if it's multiplex
		if self.receptacles[receptacle].is_multiplex then
			assert(#self.receptacles[receptacle].connections > 0, "IDL:AlreadyConnected")
		end
		local id = -1
		self.numConnections = self.numConnections + 1
		id = self.maxReceptacleId + 1
		self.maxReceptacleId = id
		self.receptacles[receptacle].connections[id] =	{
															id = id,
															objref = object
														}
		self.receptaclesByConId[id] = self.receptacles[receptacle]
		return id
	end
	
	--
	-- Description: Disconnects a component.
	-- Parameter id: Connection identifier.
	-- Throws: IDL:InvalidConnection, InvalidParameter exceptions
	--
	function obj.implReceptacles:disconnect(id)
		assert(id, "IDL:InvalidParameter")
		local receptacle = self.receptaclesByConId[id].name
		assert(self.receptacles[receptacle], "IDL:InvalidConnection")
		assert(self.receptacles[receptacle].connections[id], "IDL:NoConnection")
		self.receptacles[receptacle].connections[id] = nil
		self.receptaclesByConId[id] = nil
	end
	
	--
	-- Description: Informs the receptacle's connections.
	-- Parameter receptacle: Receptacle's name.
	-- Return Value: Receptacle's connections.
	-- Throws: IDL:InvalidName, InvalidParameter exceptions
	--
	function obj.implReceptacles:getConnections(receptacle)
		assert(receptacle, "IDL:InvalidParameter")
		assert(self.receptacles[receptacle], "IDL:InvalidName", receptacle)
		return self.receptacles[receptacle].connections
	end
	
	------------------------------------------------
	------------------------------------------------
	----        IMETAINTERFACE FUNCTIONS        ----
	------------------------------------------------
	------------------------------------------------
	
	--
	-- Description: Informs the component's facets.
	-- Return Value: All facet descriptions.
	--
	function obj.implMetaInterface:getFacets()
		return self.utils:convertToArray(facets)
	end
	
	--
	-- Description: Informs the component's facets, according to a name list.
	-- Parameter names: List containing the names of the facets.
	-- Return Value: List containing the corresponding facet descriptions.
	--
	function obj.implMetaInterface:getFacetsByName(names)
		local temp = {}
		local i = 1
		for index, name in pairs(names) do
			temp[i] = self.facetsByName[name]
			i = i + 1
		end
		return temp
	end
	
	--
	-- Description: Informs the component's receptacles.
	-- Return Value: All receptacle descriptions.
	--
	function obj.implMetaInterface:getReceptacles()
		return self.utils:convertToArray(receptacles)
	end
	
	--
	-- Description: Informs the component's receptacles, according to a name list.
	-- Parameter names: List containing the names of the receptacles.
	-- Return Value: List containing the corresponding receptacle descriptions.
	--
	function obj.implMetaInterface:getReceptaclesByName(names)
		local temp = {}
		local i = 1
		for index, name in pairs(names) do
			temp[i] = self.receptacles[name]
			i = i + 1
		end
		return temp
	end

	return obj
-- end of createSCSObject
end

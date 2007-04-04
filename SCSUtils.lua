--
-- @author Carlos Eduardo Lara Augusto
--

local utils = {verbose = false, fileVerbose = false, filename = "SCSLog"}

function utils:new (o)
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
SCSUtils = {}

function SCSUtils:create()
	local obj = utils:new()
	
	--
	-- Description: Prints a table recursively.
	-- 
	function obj:readProperties (t, file)
		local f = assert(io.open(file, "r"), "Error opening properties file!")
		while true do
			prop = f:read("*line")
			if prop == nil then
				break
			end
			-- substitutes spaces for nothing
			local line = string.gsub(prop, " ", "")
			local i = string.find(line, "=")
			self:verbosePrint("SCSUtils::ReadProperties : Line: " .. line)
			if i ~= 1 then
				t[string.sub(line, 1, i - 1)] = string.sub(line, i + 1, string.len(line))
			end
		end
		f:close()
	end
	
	--
	-- Description: Prints a table recursively.
	-- 
	function obj:print_r (t, indent, done)
	    done = done or {}
	    indent = indent or 0
	    if type(t) == "table" then
	        for key, value in pairs (t) do
	            io.write(string.rep (" ", indent)) -- indent it
	            if type (value) == "table" and not done [value] then
	              done [value] = true
	              io.write(string.format("[%s] => table\n", tostring (key)));
	              io.write(string.rep (" ", indent+4)) -- indent it
	              io.write("(\n");
	              self:print_r (value, indent + 7, done)
	              io.write(string.rep (" ", indent+4)) -- indent it
	              io.write(")\n");
	            else
	              io.write(string.format("[%s] => %s\n", tostring (key),tostring(value)))
	            end
	        end
	    else
	        io.write(t .. "\n")
	    end
	end
	
	--
	-- Description: Recebe uma mensagem e imprime se o verbose estiver ativado.
	-- Parameter message: Mensagem.
	--
	function obj:verbosePrint(message)
		if self.verbose then
			print(message)
		end
		if self.fileVerbose then
			local f = assert(io.open("logs/"..self.filename..".log", "a"))
			if self.verbose == false then
				self.verbose = true
				f:write("\n-----------------------------------------------------\n")
				f:write(os.date().." "..os.time().."\n")
			end
			f:write(message.."\n")
			f:close()
		end
	end	
	
	--
	-- Description: Como quando retornamos via corba uma tabela 
	-- com indice alfanumerico precisamos converter as nossas tabelas para esse formato.
	-- Parameter message: Tabela a ser convertida.
	-- Return Value: a tabela em formato de array.
	--
	function obj:convertToArray(inputTable)
		self:verbosePrint("SCSUtils::ConvertToArray")
		local outputArray = {}
		local i = 1
		for index, item in pairs(inputTable) do
	--		table.insert(outputArray, item)
			if index ~= "n" then
				outputArray[i] = item
				i = i + 1
			end
		end
		self:verbosePrint("SCSUtils::ConvertToArray : Finished.")
		return outputArray
	end
	
	return obj
end

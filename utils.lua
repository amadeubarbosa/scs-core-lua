local print			= print
local error			= error
local module		= module
local io 			= io
local string		= string
local assert		= assert
local os			= os

local oo        	= require "loop.base"

--------------------------------------------------------------------------------

module "scs.core"

--------------------------------------------------------------------------------

Utils = oo.class{ 	context 	= false,
					verbose 	= false,
					fileVerbose = false,
					newLog		= true,
					fileName 	= "",
				}

--
-- Description: Prints a message to the standard output and/or to a file.
-- Parameter message: Message to be delivered.
--
function Utils:verbosePrint(message)
	if verbose then
		print(message)
	end
	if fileVerbose then
		local f = assert(io.open("../../../../logs/lua/"..fileName.."/"..fileName..".log", "a"))
		if newLog then
			f:write("\n-----------------------------------------------------\n")
			f:write(os.date().." "..os.time().."\n")
			newLog = false
		end
		f:write(message.."\n")
		f:close()
	end
end	

--
-- Description: Reads a file with properties and store them at a table.
-- Parameter t: Table that will receive the properties.
-- Parameter file: File to be read.
--
function Utils:readProperties (t, file)
	local f = assert(io.open(file, "r"), "Error opening properties file!")
	while true do
		prop = f:read("*line")
		if prop == nil then
			break
		end
		-- substitutes spaces for nothing
		local line = string.gsub(prop, " ", "")
		local i = string.find(line, "=")
		verbosePrint("SCSUtils::ReadProperties : Line: " .. line)
		if i ~= 1 then
			t[string.sub(line, 1, i - 1)] = string.sub(line, i + 1, string.len(line))
		end
	end
	f:close()
end

--
-- Description: Prints a table recursively.
-- 
function Utils:print_r (t, indent, done)
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
			  print_r (value, indent + 7, done)
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
-- Description: Converts a table with an alphanumeric indice to an array.
-- Parameter message: Table to be converted.
-- Return Value: The array.
--
function Utils:convertToArray(inputTable)
--	verbosePrint("SCSUtils::ConvertToArray")
	local outputArray = {}
	local i = 1
	for index, item in pairs(inputTable) do
--		table.insert(outputArray, item)
		if index ~= "n" then
			outputArray[i] = item
			i = i + 1
		end
	end
--	verbosePrint("SCSUtils::ConvertToArray : Finished.")
	return outputArray
end

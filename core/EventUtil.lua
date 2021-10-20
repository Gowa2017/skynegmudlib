local eansi = require("eansi")

local M     = {}
function M.genWrite(socket)
  return function(string) socket:write(eansi(string)) end
end
---comment
---@param socket TelnetSocket
---@return fun(message:string)
function M.genSay(socket)
  return function(string) socket:write(eansi(string .. "\r\n")) end
end
return M

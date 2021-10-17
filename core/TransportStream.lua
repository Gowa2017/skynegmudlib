local EventEmitter = require("core.EventEmitter")

---@class TransportStream : EventEmitter
local M            = class(EventEmitter)

function M:readable() return true end
function M:writable() return true end

function M:write() end

---
---A subtype-safe way to execute commands on a specific type of stream that invalid types will ignore. For given input
---for command (example, `"someCommand"` ill look for a method called `executeSomeCommand` on the `TransportStream`
---@param  command string
---@vararg any
---@return any
function M:command(command, ...)
  if not command or #command < 1 then
    error("Must specify a command to the stream")
  end
  command = "execute" .. command[0]:upper() .. command:sub(2)
  if type(self[command]) == "function" then return self[command](...) end
end

function M:address() return end
--- this is end
function M:stop() end
function M:setEncoding() end
function M:pause() end
function M:resume() end
function M:destroy() end

---
---Attach a socket to this stream
---@param socket any
function M:attach(socket)
  self.socket = socket;
  self.socket:on("close", function() self:emit("close") end)
end

return M

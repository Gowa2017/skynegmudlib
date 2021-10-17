---@class CommandManager : Class
local M      = class()

local tablex = require "pl.tablex"
function M:_init() self.commands = {} end

function M:get(command) return self.commands[command] end

function M:add(command)
  self.commands[command.name] = command
  if command.aliases then
    tablex.foreach(command.aliases,
                   function(alias, i) self.commands[alias] = command end)
  end
end

function M:remove(command) self.commands[command.name] = nil end

function M:find(search)
  for name, command in pairs(self.commands) do
    local s, _ = name:find(search)
    if s == 1 then return command end
  end
end

return M

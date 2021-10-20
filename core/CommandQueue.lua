local class  = require("pl.class")
---@class CommandQueue : Class
local M      = class()
local tablex = require("pl.tablex")
function M:_init()
  self.commands = {}
  self.lag = 0
  self.lastRun = 0
end

function M:addLag(amount) self.lag = self.lag + math.max(0, amount) end

function M:enqueue(executable, lag)
  local a = tablex.update(executable, { lag = lag })
  self.commands[#self.commands + 1] = a
  return #self.commands
end

function M:hasPending() return #self.commands > 0 end

function M:execute()
  if #self.commands < 1 or self.msTilNextRun() > 0 then return false end
  local command = table.remove(self.commands, 1)
  self.lastRun = os.time()
  self.lag = command.lag
  command.execute()
  return true
end

function M:queue() return self.commands end

function M:flush() self.commands = {} end

function M:reset()
  self:flush()
  self.lastRun = 0
  self.lag = 0
end

function M:lagRemaining() return self:msTilNextRun() / 1000 end

function M:msTilNextRun()
  return math.max(0, (self.lastRun + self.lag) - os.time())
end

function M:getTimeTilRun(commandIndex)
  return self:getTimeTilRun(commandIndex) / 1000
end

function M:getMsTilRun(commandIndex)
  if not self.commands[commandIndex] then error("Invalid command index") end
  local lagTotal = self.msTilNextRun()
  for i = 1, #self.commands do
    if i == commandIndex then return lagTotal end
    lagTotal = lagTotal + self.commands[i].lag
  end
end

return M

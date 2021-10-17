local class        = require("pl.class")
local EventEmitter = require("core.EventEmitter")
local Data         = require("core.Data")
local Player       = require("core.Player")
local EventManager = require("core.EventManager")
local tablex       = require("pl.tablex")
local wrapper      = require("core.lib.wrapper")

---@class PlayerManager :EventEmitter
---@field events EventManager
local M            = class(EventEmitter)

function M:_init()
  self:super()
  self.players = {}
  self.events = EventManager()
  self.loader = nil
  self:on("updateTick", wrapper.bind(self.tickAll, self))
end

function M:setLoader(loader) self.loader = loader end

function M:getPlayer(name) return self.players[name:lower()] end

function M:addPlayer(player) self.players[self:keyify(player)] = player end

function M:removePlayer(player, killSocket)
  if killSocket then player.socket:ended() end
  player:removeAllListeners()
  player:removeFromCombat()
  player.effectys:clear()
  if player.room then player.room:removePlayer(player) end

  player.__pruned = true
  self.players[self:keyify(player)] = nil
end

function M:getPlayersAsArray() return tablex.values(self.players) end

function M:addListener(event, func) self.events:add(event, func) end

function M:filter(fn) return tablex.filter(self:getPlayersAsArray(), fn) end

function M:loadPlayer(state, account, username, force)
  if self.players[username] and not force then return self:getPlayer(username) end
  if not self.loader then error("No entity loader configured for players") end

  local data   = self.loader:fetch(username)
  data.name = username

  local player = Player(data)
  player.account = account

  self.events:attach(player)

  self:addPlayer(player)
  return player
end

function M:keyify(player) return player.name:lower() end

function M:exists(name) return Data.exists("player", name) end

function M:save(player)
  if not self.loader then error("No entity loader configured for players") end

  self.loader:update(player.name, player:serialize())

  player:emit("saved")
end

function M:saveAll()
  for name, player in ipairs(self.players) do self:save(player) end
end

function M:tickAll()
  for _, player in pairs(self.players) do player:emit("updateTick") end
end

function M:getBroadcastTargets() return self:getPlayersAsArray() end

return M

local Player  = require("core.Player")
local Game    = require("core.GameState")
local Account = require("core.Account")
local pretty  = require("pl.pretty")

function createplayer(account, name, state)
  local player            = Player({
    name    = name,
    account = Account({ username = account }),
  })

  local defaultAttributes = {
    health    = 100,
    strength  = 20,
    agility   = 20,
    intellect = 20,
    stamina   = 20,
    armor     = 0,
    critical  = 0,
    mana      = 2,
  }
  for name, value in pairs(defaultAttributes) do
    player:addAttribute(state.AttributeFactory:create(name, value))
  end
  return player
end

---@type Player
-- local player    = createplayer("json", "json")
-- Game.PlayerManager:save(player)

---@type GameState
local state   = Game("mud")
state:load()
state:start()
local area    = state.AreaFactory:create("limbo")
area:hydrate(state)

--- test quest
---@type Player
local player  = state.PlayerManager:loadPlayer(state, "test", "json")
player:hydrate(state)
-- local player  = createplayer("test", "json", state)
-- state.PlayerManager:addPlayer(player)
-- state.PlayerManager:save(player)
-- player:hydrate()
---@type Quest
local quest   = state.QuestFactory:create(state, "limbo:journeybegins", player)
player.questTracker:start(quest)
local Item    = require("core.Item")
local sword   = state.ItemFactory:createByType(area, "limbo:rustysword", Item)
player:addItem(sword)
itm = state.ItemFactory:createByType(area, "limbo:leathervest", Item)
player:addItem(itm)
-- player:equip(itm, "chest")
-- player:equip(sword, "weild")

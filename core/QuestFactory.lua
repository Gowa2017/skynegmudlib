local class  = require("pl.class")
local sfmt   = string.format
local Quest  = require("core.Quest");
local Logger = require("core.Logger");
---@class QuestFactory : Class
local M      = class()
function M:_init() self.quests = {} end

function M:add(areaName, id, config)
  local entityRef = self:makeQuestKey(areaName, id)
  config.entityReference = entityRef
  self.quests[entityRef] = { id     = id, area   = areaName, config = config }
end

function M:set(qid, val) self.quests[qid] = val end

function M:get(qid) return self.quests[qid] end

---@param player Player
---@param questRef string
---@return boolean
function M:canStart(player, questRef)
  local quest   = self.quests[questRef]
  if not quest then error(sfmt("Invalid quest id [%q]", questRef)) end
  local tracker = player.questTracker
  if tracker.completedQuests[questRef] and not quest.config.repeatable then
    return false
  end
  if tracker:isActive(questRef) then return false end
  if not quest.config.requires then return true end
  for _, requiresRef in ipairs(quest.config.requires) do
    if not tracker:isComplete(requiresRef) then return false end

  end
  return true
end

---comment
---@param GameState table
---@param qid string
---@param player Player
---@param state table
---@return Quest
function M:create(GameState, qid, player, state)
  state = state or {}
  local quest    = self.quests[qid]
  if not quest then error(sfmt("Trying to create invalid quest id [%q]", qid)) end
  ---@type Quest
  local instance = Quest(GameState, quest.id, quest.config, player)
  instance.state = state
  for _, goal in ipairs(quest.config.goals) do
    local goalType = GameState.QuestGoalManager:get(goal.type)
    instance:addGoal(goalType(instance, goal.config, player))
  end
  instance:on("progress", function(progress)
    player:emit("questProgress", instance, progress)
    player:save()
  end)
  instance:on("start", function()
    player:emit("questStart", instance)
    instance:emit("progress", instance:getProgress())
  end)

  instance:on("turn-in-ready",
              function() player:emit("questTurnReady", instance) end)

  instance:on("complete", function()
    player:emit("questComplete", instance)
    player.questTracker:complete(instance.entityReference)
    if not quest.config.rewards then
      player:save()
      return
    end
    for _, reward in ipairs(quest.config.rewards) do
      local rewardClass = GameState.QuestGoalManager:get(reward.type)
      if not rewardClass then
        error(sfmt("Quest [%q] has invalid reward type [%q]", qid, reward.type))
      end
      rewardClass.reward(GameState, instance, reward.config, player)
    end
    player:save()

  end)
  return instance
end

function M:makeQuestKey(area, id) return area .. ":" .. id; end

return M

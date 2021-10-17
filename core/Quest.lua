local class        = require("pl.class")
local tablex       = require("pl.tablex")

local EventEmitter = require("core.EventEmitter");
---@class Quest : EventEmitter
---@field goals table<QuestGoal,boolean>
---@field state table<QuestGoal, boolean>
local M            = class(EventEmitter)

function M:_init(GameState, id, config, player)
  self:super();

  self.id = id;
  self.entityReference = config.entityReference;
  self.config = tablex.update({
    title             = "Missing Quest Title",
    description       = "Missing Quest Description",
    completionMessage = nil,
    requires          = {},
    level             = 1,
    autoComplete      = false,
    repeatable        = false,
    rewards           = {},
    goals             = {},
  }, config);

  self.player = player;
  self.goals = {};
  self.state = {};
  self.GameState = GameState;
end

function M:emit(event, ...)
  EventEmitter.emit(self, event, ...)
  if event == "progress" then return end
  tablex.foreach(self.goals, function(_, goal, ...) goal:emit(event, ...) end,
                 ...)

end

function M:addGoal(goal)
  self.goals[goal] = true
  goal:on("progress", function() self:onProgressUpdated() end)
end

function M:onProgressUpdated()
  local progress = self:getProgress()
  if progress.percent >= 100 then
    if self.config.autoComplete then
      self:complete()
    else
      self:emit("turn-in-ready")
    end
    return
  end
  self:emit("progress", progress)
end

function M:getProgress()
  local overallPercent = 0;
  local overallDisplay = {};
  tablex.foreach(self.goals, function(_, goal)
    local goalProgress = goal:getProgress()
    overallPercent = overallPercent + goalProgress.percent
    overallDisplay[#overallDisplay + 1] = goalProgress.dispaly
  end)
  return {
    percent = math.floor(overallPercent / tablex.size(self.goals)),
    display = table.concat(overallDisplay, "\r\n"),
  };
end

function M:serialize()
  return {
    state    = tablex.imap(function(goal) return goal:serialize() end,
                           tablex.keys(self.goals)),
    progress = self:getProgress(),
    config   = {
      desc   = self.config.desc,
      level  = self.config.level,
      titlex = self.config.title,
    },
  };
end

function M:hydrate()
  tablex.foreach(self.state, function(goalState, i)
    self.goals[i]:hydrate(goalState.state)
  end)
end

function M:complete()
  self:emit("complete")
  for _, goal in ipairs(self.goals) do goal:complete() end

end

return M

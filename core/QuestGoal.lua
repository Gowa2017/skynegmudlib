local EventEmitter = require("core.EventEmitter");
local tablex       = require("pl.tablex")
---@class QuestGoal : EventEmitter
local M            = class(EventEmitter)
function M:_init(quest, config, player)
  self:super();

  self.config = tablex.copy(config)
  self.quest = quest;
  self.state = {};
  self.player = player;
end

function M:getProgress()
  return {
    percent = 0,
    display = "[WARNING] Quest does not have progress display configured. Please tell an admin",
  };
end

function M:complete() end

function M:serialize()
  return {
    state    = self.state,
    progress = self:getProgress(),
    config   = self.config,
  };
end

function M:hydrate(state) self.state = state; end

return M

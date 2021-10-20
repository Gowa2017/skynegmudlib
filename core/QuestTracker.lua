local class  = require("pl.class")
local tablex = require("pl.tablex")

---@class QuestTracker : Class
local M      = class()
function M:_init(player, active, completed)
  self.player = player
  self.activeQuests = tablex.copy(active or {})
  self.completedQuests = tablex.copy(completed or {})
end

function M:emit(event, ...)
  for _, quest in pairs(self.activeQuests) do quest:emit(event, ...) end
end

function M:isActive(qid) return self.activeQuests[qid] end

function M:isCompleted(qid) return self.completedQuests[qid] end

function M:get(qid) return self.activeQuests[qid] end

function M:complete(qid)
  if not self:isActive(qid) then error("Quest not started") end
  self.completedQuests[qid] = {
    started     = self.activeQuests[qid].stated,
    completedAt = os.time(),
  }
  self.activeQuests[qid] = nil
end

function M:start(quest)
  local qid = quest.entityReference
  if self.activeQuests[qid] then error("Quest already started") end
  quest.started = os.time()
  self.activeQuests[qid] = quest
  quest:emit("start")
end

function M:hydrate(state)
  for qid, data in pairs(self.activeQuests) do
    local quest = state.QuestFactory:create(state, qid, self.player, data.state)
    quest.started = data.started
    quest:hydrate()
    self.activeQuests[qid] = quest
  end
end

function M:serialize()
  local completed = {}
  local active    = {}
  for k, v in pairs(self.completedQuests) do
    completed[#completed + 1] = { k, v }
  end
  for qid, quest in pairs(self.activeQuests) do
    active[#active + 1] = { qid, quest:serialize() }
  end
  return { completed = completed, active    = active }
end

return M

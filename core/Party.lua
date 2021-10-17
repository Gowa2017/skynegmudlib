local class  = require("pl.class")
---@class Party
local M      = class()

local tablex = require("pl.tablex")
function M:_init(leader)
  self.invited = {}
  self.leader = leader
  self.members = {}
  self.members[leader] = true
end

function M:delete(member)
  self.members[member] = nil
  member.party = nil
end

function M:add(memeber)
  self.members[memeber] = true
  memeber.party = self
  self.invited[memeber] = nil
end

function M:disband()
  for member, _ in pairs(self.members) do self.members[member] = nil end
end

function M:invite(target) self.invited[target] = true end

function M:isInvited(target) return self.invited[target] end

function M:removeInvite(target) self.invited[target] = nil end

function M:getBroadcastTargets() return tablex.keys(self.members) end

return M

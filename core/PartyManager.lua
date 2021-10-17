local Party = require("core.Party");

---@class PartyManager
local M     = class()
function M:_init() self.partys = {} end

function M:create(leader)
  local party = Party(leader)
  self.partys[party] = true
end

function M:disband(party)
  self.partys[party] = nil
  party:disband()
  party = nil
end

return M

---@class MobManager
local M = class()
function M:cotr() self.mobs = {} end

function M:addMob(mob) self.mobs[mob] = true end

function M:removeMob(mob)
  mob.effects:clear()
  local room = mob.room
  if room then
    room.area:removeNpc(mob)
    room:removeNpc(mob, true)
  end
  mob.__pruned = true
  mob:removeAllListeners()
  self.mobs[mob] = nil
end

return M

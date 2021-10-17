local SkillFlag = require("core.SkillFlag")

---@class SkillManager
local M         = class()
function M:_init() self.skills = {} end

---@param skill string
---@return Skill
function M:get(skill) return self.skills[skill] end

function M:add(skill) self.skills[skill.id] = skill end

function M:remove(skill) self.skills[skill.id] = nil end

function M:find(search, includePassive)
  for id, skill in pairs(self.skills) do
    if not includePassive and skill.flags.includes(SkillFlag.PASSIVE) then
      goto continue
    end
    if id:find(search) == 1 then return skill end
    ::continue::
  end
end

return M

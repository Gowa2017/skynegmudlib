local SkillFlag   = require("core.SkillFlag")
local SkillType   = require("core.SkillType")
local SkillErrors = require("core.SkillErrors")
local Damage      = require("core.Damage")
local Broadcast   = require("core.Broadcast")
local tablex      = require("pl.tablex")
local wrapper     = require("core.lib.wrapper")

local sfmt        = string.format
---@class Skill : Class
local M           = class()

function M:_init(id, config, state)
  local c = tablex.update({
    configureEffect = function() end,
    cooldown        = nil,
    effect          = nil,
    flags           = {},
    info            = function() return {} end,
    initiatesCombat = false,
    name            = nil,
    requiresTarget  = true,
    resource        = nil, -- /* format [{ attribute: 'someattribute', cost: 10}] */
    run             = function() return {} end,
    targetSelf      = false,
    type            = SkillType.SKILL,
    options         = {},
  }, config)

  self.configureEffect = c.configureEffect

  self.cooldownGroup = nil
  if c.cooldown and type(c.cooldown) == "table" then
    self.cooldownGroup = c.cooldown.group
    self.cooldownLength = c.cooldown.length
  else
    self.cooldownLength = c.cooldown
  end

  self.effect = c.effect
  self.flags = c.flags
  self.id = id
  self.info = wrapper.bind(c.info, self)
  self.initiatesCombat = c.initiatesCombat
  self.name = name
  self.options = c.options
  self.requiresTarget = c.requiresTarget
  self.resource = c.resource
  self.run = wrapper.bind(c.run, self)
  self.state = state
  self.targetSelf = c.targetSelf
  self.type = c.type
end

function M:execute(args, player, target)
  if self.flags:find(SkillFlag.PASSIVE) then error(SkillErrors.PassiveError) end

  local cdEffect = self:onCooldown(player)
  if self.cooldownLength and cdEffect then error(SkillErrors.CooldownError) end
  if self.resource then
    if not self:hasEnoughResources(player) then
      error(SkillErrors.NotEnoughResourcesError)
    end
  end

  if target ~= player and self.initiatesCombat then
    player:initiateCombat(target)
  end

  if self:run(args, player, target) then
    self:cooldown(player)
    if self.resource then self:payResourceCosts(player) end
  end

  return true
end

function M:payResourceCosts(player)
  local hasMultipleResourceCosts = type(self.resource) == "table"
  if hasMultipleResourceCosts then
    for _, resourceCost in ipairs(self.resource) do
      self:payResourceCost(player, resourceCost)
    end
    return true
  end

  return self:payResourceCost(player, self.resource)
end

function M:payResourceCost(player, resource)
  local damage = Damage(resource.attribute, resource.cost, player, self,
                        { hidden = true })

  damage:commit(player)
end

function M:activate(player)
  if not self.flags:find(SkillFlag.PASSIVE) then return end

  if not self.effect then error("Passive skill has no attached effect") end

  local effect = self.state.EffectFactory:create(self.effect, {
    description = self:info(player),
  })
  effect = self:configureEffect(effect)
  effect.skill = self
  player:addEffect(effect)
  self:run(player)
end

function M:onCooldown(character)
  for _, effect in ipairs(character.effects:entries()) do
    if effect.id == "cooldown" and effect.state.cooldownId ==
      self:getCooldownId() then return effect end
  end
  return false
end

function M:cooldown(character)
  if not self.cooldownLength then return end
  character:addEffect(self:createCooldownEffect())
end

function M:getCooldownId()
  return
    self.cooldownGroup and "skillgroup:" .. self.cooldownGroup or "skill:" +
      self.id
end

function M:createCooldownEffect()
  if not self.state.EffectFactory:has("cooldown") then
    self.state.EffectFactory:add("cooldown", self:getDefaultCooldownConfig())
  end

  local effect = self.state.EffectFactory:create("cooldown", {
    name     = "Cooldown: " .. self.name,
    duration = self.cooldownLength * 1000,
  }, { cooldownId = self.getCooldownId() })
  effect.skill = self

  return effect
end

function M:getDefaultCooldownConfig()
  return {
    config    = {
      name        = "Cooldown",
      description = "Cannot use ability while on cooldown.",
      unique      = false,
      type        = "cooldown",
    },
    state     = { cooldownId = nil },
    listeners = {
      effectDeactivated = function()
        Broadcast.sayAt(self.target, sfmt(
                          "You may now use <bold>%s</bold> again.",
                          self.skill.name))
      end,
    },
  }
end

function M:hasEnoughResources(character)
  if type(self.resource) == "table" then
    for _, resource in ipairs(self.resource) do
      if not self:hasEnoughResource(character, resource) then return false end
    end
  end
  return self.hasEnoughResource(character, self.resource)
end

function M:hasEnoughResource(character, resource)
  return not resource.cost or (character:hasAttribute(resource.attribute) and
           character:getAttribute(resource.attribute) > resource.cost)
end

return M

local class           = require("pl.class")
local sfmt            = string.format
local Broadcast       = require("core.Broadcast")
local WorldAudience   = require("core.WorldAudience")
local PrivateAudience = require("core.PrivateAudience")
local PartyAudience   = require("core.PartyAudience")
local wrapper         = require("core.lib.wrapper")
local tablex          = require("pl.tablex")

---@class Channel :Class
---@field name string
---@field miniRequireRole? string
---@field bundle string
---@field description string
---@field audience ChannelAudience
---@field color string
---@field aliases string[]
---@field formater table<string, function> # sender, target
local M               = class("Channel")

function M:_init(config)
  assert(config.name, "Channels must have a name to be usable.")
  assert(config.audience,
         sfmt("Channel %s is missing a valid audience", config.name))
  self.name = config.name
  self.minRequiredRole = config.minRequiredRole and config.minRequiredRole or
                           false
  self.description = config.description
  self.bundle = config.bundle or false
  self.audience = config.audience or WorldAudience()
  self.color = config.color or false
  self.aliases = config.aliases
  self.formatter = config.formatter or {
    sender = wrapper.bind(self.formatToSender, self),
    target = wrapper.bind(self.formatToReceipient, self),
  }
end

function M:send(state, sender, message)
  assert(message and #message > 0, "No message")
  assert(self.audience,
         sfmt("Channel %s has invalid audience %s", self.name, self.audience))

  self.audience:configure({ state, sender, message })
  local targets    = self.audience:getBroadcastTargets()

  if PartyAudience:class_of(self.audience) and not tablex.size(targets) then
    error("NoPartyError()")
  end

  -- Allow audience to change message e.g., strip target name.
  message = self.audience:alterMessage(message)

  -- Private channels also send the target player to the formatter
  if PrivateAudience:class_of(self.audience) then
    if not tablex.size(targets) then error("NoRecipientError()") end
    Broadcast.sayAt(sender, self.formatter.sender(sender, targets[0], message,
                                                  wrapper.bind(self.colorify,
                                                               self)))
  else
    Broadcast.sayAt(sender, self.formatter
                      .sender(sender, nil, message,
                              wrapper.bind(self.colorify, self)))
  end

  -- send to audience targets
  Broadcast.sayAtFormatted(self.audience, message, function(target, message)
    return self.formatter.target(sender, target, message,
                                 wrapper.bind(self.colorify, self))
  end)

  -- strip color tags
  -- const rawMessage = message.replace(/\<\/?\w+?\>/gm, '')
  local rawMessage = message

  for _, target in ipairs(targets) do
    target:emit("channelReceive", self, sender, rawMessage)

  end
end

function M:describeSelf(sender)
  Broadcast.sayAt(sender, "\r\nChannel: " .. self.name)
  Broadcast.sayAt(sender, "Syntax: " .. self.getUsage())
  if self.description then Broadcast.sayAt(sender, self.description) end
end

function M:getUsage()
  if PrivateAudience:class_of(self.audience) then
    return sfmt("%s <target> [message]", self.name)
  end

  return sfmt("%q [message]", self.name)
end

---
---How to render the message the player just sent to the channel
---E.g., you may want "chat" to say "You chat, 'message here'"
---@param sender Player
---@param message string
---@param colorify function
---@return string
---
function M:formatToSender(sender, target, message, colorify)
  return colorify(sfmt("[%q] %q: %q", self.name, sender.name, message))
end

---
---How to render the message to everyone else
---E.g., you may want "chat" to say "Playername chats, 'message here'"
---@param sender Player
---@param target Player
---@param message string
---@param colorify function
---@return string
function M:formatToReceipient(sender, target, message, colorify)
  return self:formatToSender(sender, target, message, colorify)
end

function M:colorify(message)
  if not self.color then return message end

  local colors      = type(self.color) == "table" and self.color or
                        { self.color }

  -- local open = colors.map(color => '<${color}>').join('')
  -- local close = colors.reverse().map(color => '</${color}>').join('')
  local open, close = "", ""

  return open .. message .. close
end

return M

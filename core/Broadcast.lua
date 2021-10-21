local sfmt   = string.format
local tablex = require("pl.tablex")
local Logger = require("core.Logger")

local ansi   = require("eansi")
ansi._colortag = "%b<>"

---@class Broadcastable
---@field getBroadcastTargets fun(): any[]
---@class Broadcast
local M      = {}

---comment
---@param source Broadcastable
---@param message string
---@param wrapWidth boolean
---@param useColor boolean
---@param formatter? fun(target:Broadcastable, message:string):string
function M.at(source, message, wrapWidth, useColor, formatter)
  message = message or ""
  useColor = useColor == nil and true
  formatter = formatter or function(target, msg) return msg end

  if not M.isBroadcastable(source) then
    error(sfmt(
            "Tried to broadcast message to non-broadcastable object: MESSAGE [%s]",
            message));
  end
  --   message = Broadcast._fixNewlines(message);
  for _, target in ipairs(source:getBroadcastTargets()) do
    local targetMessage = formatter(target, message)
    targetMessage = wrapWidth and M.wrap(targetMessage, wrapWidth) or
                      ansi(targetMessage)
    -- Logger.info("Broadcast.at %s", targetMessage)
    if not target.socket or not target.socket.writable then goto continue end
    if target.socket._prompted then
      target.socket:write("\r\n")
      target.socket._prompted = false
    end
    local targetMessage = formatter(target, message)
    targetMessage = wrapWidth and M.wrap(targetMessage, wrapWidth) or
                      ansi(targetMessage)
    target.socket:write(targetMessage);
    ::continue::
  end

end

function M.isBroadcastable(source)
  return source and type(source.getBroadcastTargets) == "function"
end

---
---Broadcast.at for all except given list of players
---@param  source Broadcastable
---@param  message  string
---@param  excludes Player[]
---@param  wrapWidth boolean | number
---@param  useColor boolean
---@param  formatter function
function M.atExcept(source, message, excludes, wrapWidth, useColor, formatter)
  if not M.isBroadcastable(source) then
    error(sfmt(
            "Tried to broadcast message to non-broadcastable object: MESSAGE [%s]",
            message));
  end

  local targets   = source:getBroadcastTargets()
  excludes = tablex.index_map(excludes)
  targets = tablex.filter(targets,
                          function(target) return excludes[target] == nil end)

  local newSource = { getBroadcastTargets = function() return targets end };

  M.at(newSource, message, wrapWidth, useColor, formatter);
end

---
---Helper wrapper around Broadcast.at to be used when you're using a formatter
---@param source Broadcastable
---@param message string
---@param formatter function
---@param wrapWidth number | boolean
---@param useColor boolean
function M.atFormatted(source, message, formatter, wrapWidth, useColor)
  M.at(source, message, wrapWidth, useColor, formatter);
end

---
---'Broadcast.at' with a newline
---
function M.sayAt(source, message, wrapWidth, useColor, formatter)
  M.at(source, message, wrapWidth, useColor, function(target, message)
    return (formatter and formatter(target, message) or message) .. "\r\n";
  end);
end

---
---'Broadcast.atExcept' with a newline
---@see {@link Broadcast#atExcept}
---
function M.sayAtExcept(
  source, message, excludes, wrapWidth, useColor, formatter
)
  M.atExcept(source, message, excludes, wrapWidth, useColor,
             function(target, message)
    return (formatter and formatter(target, message) or message) .. "\r\n";
  end);
end

---
---'Broadcast.atFormatted' with a newline
---@see {@link Broadcast#atFormatted}
---
function M.sayAtFormatted(source, message, formatter, wrapWidth, useColor)
  M.sayAt(source, message, wrapWidth, useColor, formatter);
end

---
---Render the player's prompt including any extra prompts
---@param player Player
---@param extra  table   extra data to avail to the prompt string interpolator
---@param wrapWidth number
---@param useColor boolean
---
function M.prompt(player, extra, wrapWidth, useColor)
  player.socket._prompted = false;
  M.at(player, "\r\n" .. player:interpolatePrompt(player.prompt, extra) .. " ",
       wrapWidth, useColor);
  local needsNewline = tablex.size(player.extraPrompts) > 0;
  if needsNewline then M.sayAt(player) end

  for id, extraPrompt in pairs(player.extraPrompts) do
    M.sayAt(player, extraPrompt:renderer(), wrapWidth, useColor)
    if extraPrompt.removeOnRender then player:removePrompt(id) end

  end
  if needsNewline then M.at(player, "> ") end

  player.socket._prompted = true;
  if player.socket.writable then player.socket:command("goAhead"); end
end

---
---Generate an ASCII art progress bar
---@param width number Max width
---@param percent number Current percent
---@param color string
---@param barChar string Character to use for the current progress
---@param fillChar string Character to use for the rest
---@param delimiters string Characters to wrap the bar in
---@return string
---
function M.progress(width, percent, color, barChar, fillChar, delimiters)
  barChar = barChar or "#"
  fillChar = fillChar or " "
  delimiters = delimiters or "()"
  percent = math.max(0, percent);
  width = width - 3; -- account for delimiters and tip of bar
  if percent == 100 then

    width = width + 1; -- 100% bar doesn't have a second right delimiter
  end
  barChar = barChar:sub(1, 1)
  fillChar = fillChar:sub(1, 1)
  local leftDelim, rightDelim = delimiters:sub(1, 1), delimiters:sub(2, 2);
  local openColor             = "<${color}>";
  local closeColor            = "</${color}>";
  local buf                   = openColor .. leftDelim .. "<bold>";
  local widthPercent          = math.floor((percent / 100) * width);
  local res                   = { buf }
  res[#res + 1] = M.line(widthPercent, barChar) ..
                    (percent == 100 and "" or rightDelim);
  res[#res + 1] = M.line(width - widthPercent, fillChar);
  res[#res + 1] = "</bold>" .. rightDelim .. closeColor;
  return table.concat(buf, "");
end

---
---Center a string in the middle of a given width
---@param width number
---@param message string
---@param color string
---@param fillChar? string Character to pad with, defaults to ' '
---@return string
---
function M.center(width, message, color, fillChar)
  fillChar = fillChar or " "
  local padWidth   = width / 2 - #message / 2;
  local openColor  = "";
  local closeColor = "";
  if color then
    openColor = "<" .. color .. ">";
    closeColor = "" --  "</${color}>";
  end

  return (openColor .. M.line(math.floor(padWidth), fillChar) .. message ..
           M.line(math.ceil(padWidth), fillChar) .. closeColor);
end

---
---Render a line of a specific width/color
---@param  width number
---@param  fillChar string
---@param  color? string
---@return string
---
function M.line(width, fillChar, color)
  fillChar = fillChar or "-"
  local openColor  = "";
  local closeColor = "";
  if color then
    openColor = "<" .. color .. ">";
    closeColor = "" -- "</${color}>";
  end
  return openColor .. string.rep(fillChar, width) .. closeColor;
end

---
---Wrap a message to a given width. Note: Evaluates color tags
---@param  message string
---@param  width? number   Defaults to 80
---@return string
function M.wrap(message, width)
  width = width or 80
  return M._fixNewlines(ansi(message))
  -- return M._fixNewlines(M.wrap(ansi(message), width));
end

---
---Indent all lines of a given string by a given amount
---@param  message string
---@param  indent number
---@return string
function M.indent(message, indent)
  message = M._fixNewlines(message);
  local padding = M.line(indent, " ");
  return padding .. message:gsub("\r\n", "\r\n" .. padding);
end

---
---Fix LF unpaired with CR for windows output
---@param  message string
---@return string
---
function M._fixNewlines(message)
  -- // Fix \n not in a \r\n pair to prevent bad rendering on windows
  -- message = message.replace(/\r\n/g, '<NEWLINE>').split('\n');
  -- message = message.join('\r\n').replace(/<NEWLINE>/g, '\r\n');
  -- // fix sty's incredibly stupid default of always appending ^[[0m
  -- return message.replace(/\x1B\[0m$/, '');
  return message
end

return M

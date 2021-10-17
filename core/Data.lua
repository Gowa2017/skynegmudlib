local class    = require("pl.class")
local tconcat  = table.concat

local fs       = require("pl.path")
local file     = require("pl.file")
local pretty   = require("pl.pretty")

local dataPath

---@class Data
local M        = class()
function M.setDataPath(path) dataPath = path end

function M.parseFile(filepath)
  if not fs.exists(filepath) then error("File [%s] does not exist!", filepath) end
  return loadfile(filepath, "bt")()
end

function M.saveFile(filepath, data, callback)
  if not fs.exists(filepath) then error("File [%s] does not exist!", filepath) end
  pretty.dump(data, filepath)
  if callback then callback() end
end

function M.load(type, id) return M.parseFile(M.getDataFilePath(type, id)) end

function M.save(type, id, data, callback)
  file.write(M.getDataFilePath(type, id),
             tconcat({ "return", pretty.write(data) }, " "))
  if callback then callback() end
end

function M.exists(type, id) return fs.exists(M.getDataFilePath(type, id)) end

function M.getDataFilePath(type, id)
  if type == "player" then return dataPath .. "player/" .. id .. ".lua" end
  if type == "account" then return dataPath .. "account/" .. id .. ".lua" end
end

function M.isScriptFile(path, file)
  file = file or path
  return fs.isfile(path) and file:match(".*%.lua")
end

function M.loadMotd()
  local motd = file.read(dataPath + "motd")
  return motd
end

return M

local sfmt         = string.format
local M            = {}
local level        = 0
local levels       = {
  VERBOSE  = 0,
  DEBUG    = 1,
  INFO     = 2,
  WARNING  = 3,
  ERROR    = 4,
  CRITICAL = 5,
}
local SERVICE_DESC = SERVICE_DESC or ""

local function logFile(sSubType, sMsg, ...)
  local call = debug.getinfo(3, "S")
  local info = level < 2 and call.short_src .. ":" .. call.linedefined or ""
  if level > levels[sSubType] then return end
  local s    = sfmt("%-8s:[%s] %s %s", sSubType, SERVICE_DESC, sfmt(sMsg, ...),
                    info)
  print(s)
end

function M.log(sMsg, ...)
  local s = sfmt("%-8s: %s", "NOTSET", sfmt(sMsg, ...))
  print(s)
end

function M.error(sMsg, ...) logFile("ERROR", sMsg, ...) end

function M.info(sMsg, ...) logFile("INFO", sMsg, ...) end

function M.warning(sMsg, ...) logFile("WARNING", sMsg, ...) end

M.warn = M.warning

function M.debug(sMsg, ...) logFile("DEBUG", sMsg, ...) end

function M.verbose(sMsg, ...) logFile("VERBOSE", sMsg, ...) end

function M.setLevel(l) level = l end

return M

local class          = require("pl.class")
local tconcat        = table.concat
local sfmt           = string.format
local fs             = require("pl.file");
local dir            = require("pl.dir")

local path           = require("pl.path");

local FileDataSource = require("core.DataSource.FileDataSource");
local YamlDataSource = require("core.DataSource.YamlDataSource");

---
--- Data source for areas stored in yml. Looks for a directory structure like:
---
---   path/
---     area-one/
---       manifest.yml
---     area-two/
---       manifest.yml
---
--- Config:
---   path: string: relative path to directory containing area folders
---
---
---@class YamlAreaDataSource : FileDataSource
local M              = class(FileDataSource)

function M:hasData(config)
  config = config or {}
  local dirPath = self:resolvePath(config);
  return path.exists(dirPath);
end

function M:fetchAll(config)
  config = config or {}
  local dirPath = self:resolvePath(config);
  if not self:hasData(config) then
    error(sfmt("Invalid path [%q] specified for YamlAreaDataSource", dirPath));
  end
  local data    = {}
  local dirs    = dir.getdirectories(dirPath)
  for _, file in ipairs(dirs) do
    if not path.isdir(file) then goto continue end

    local manifestPath = tconcat({ file, "manifest.yml" }, "/")
    if not path.exists(manifestPath) then goto continue end
    local _, name      = path.splitpath(file)
    data[name] = self:fetch(config, name)
    ::continue::
  end
  return data
end

function M:fetch(config, id)
  config = config or {}
  local dirPath = self:resolvePath(config);
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] specified for YamlAreaDataSource", dirPath));
  end

  local source  = YamlDataSource({}, dirPath);

  return source:fetchAll({ path = id .. "/manifest.yml" });
end

function M:update(config, id, data)
  local dirPath = self:resolvePath(config);
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] specified for YamlAreaDataSource", dirPath));
  end

  local source  = YamlDataSource({}, dirPath);
  return source:replace({ path = id .. "/manifest.yml" }, data);
end
return M

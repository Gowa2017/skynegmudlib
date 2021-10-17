local yaml   = require("lyaml")
local pretty = require("pl.pretty")

local file   =
  "/Users/gowa/mud/ranviermud/bundles/bundle-example-areas/areas/limbo/loot-pools.yml"

local function convert(path)
  local f   = assert(io.open(path, "r"), "")
  local doc = f:read("a")
  return yaml.load(doc)
end

local t      = convert(file)

pretty.dump(t,
            "/Users/gowa/Repo/skynetmudlib/bundles/bundle-example-areas/areas/limbo/loot-pools.lua")

local Game   = require("Game")
local Config = require("Config")
---@type GameState
local state  = Game("mud")

state.DataSourceRegistry:load(require, state.dirname, {
  Yaml          = { require = "DataSource.YamlDataSource" },
  YamlDirectory = { require = "DataSource.YamlDirectoryDataSource" },
  YamlArea      = { require = "DataSource.YamlAreaDataSource" },
})

state.EntityLoaderRegistry:load(state.DataSourceRegistry, {
  areas  = { source = "YamlArea", config = { path = "bundles/[BUNDLE]/areas" } },
  npcs   = {
    source = "Yaml",
    config = { path = "bundles/[BUNDLE]/areas/[AREA]/npcs.yml" },
  },
  items  = {
    source = "Yaml",
    config = { path = "bundles/[BUNDLE]/areas/[AREA]/items.yml" },
  },
  rooms  = {
    source = "Yaml",
    config = { path = "bundles/[BUNDLE]/areas/[AREA]/rooms.yml" },
  },
  quests = {
    source = "Yaml",
    config = { path = "bundles/[BUNDLE]/areas/[AREA]/quests.yml" },
  },
})

state.BundleManager:loadAreas("test")

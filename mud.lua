return {
  port                      = 4000,
  bundles                   = {
    "bundle-example-areas",
    "bundle-example-quests",
    "bundle-example-lib",
  },
  dataSources               = {
    Lua           = { require = "core.DataSource.LuaDataSource" },
    LuaDirectory  = { require = "core.DataSource.LuaDirectoryDataSource" },
    LuaArea       = { require = "core.DataSource.LuaAreaDataSource" },
    Yaml          = { require = "core.DataSource.YamlDataSource" },
    YamlDirectory = { require = "core.DataSource.YamlDirectoryDataSource" },
    YamlArea      = { require = "core.DataSource.YamlAreaDataSource" },
  },
  entityLoaders             = {
    accounts = { source = "LuaDirectory", config = { path = "data/account" } },
    players  = { source = "LuaDirectory", config = { path = "data/player" } },
    areas    = {
      source = "LuaArea",
      config = { path = "bundles/[BUNDLE]/areas" },
    },
    npcs     = {
      source = "Lua",
      config = { path = "bundles/[BUNDLE]/areas/[AREA]/npcs.lua" },
    },
    items    = {
      source = "Lua",
      config = { path = "bundles/[BUNDLE]/areas/[AREA]/items.lua" },
    },
    rooms    = {
      source = "Lua",
      config = { path = "bundles/[BUNDLE]/areas/[AREA]/rooms.lua" },
    },
    quests   = {
      source = "Lua",
      config = { path = "bundles/[BUNDLE]/areas/[AREA]/quests.lua" },
    },
    help     = {
      source = "LuaDirectory",
      config = { path = "bundles/[BUNDLE]/help" },
    },
  },
  maxAccountNameLength      = 20,
  minAccountNameLength      = 3,
  maxPlayerNameLength       = 20,
  minPlayerNameLength       = 3,
  maxCharacters             = 3,
  reportToAdmins            = false,
  startingRoom              = "limbo:white",
  moveCommand               = "move",
  skillLag                  = 2000,
  defaultMaxPlayerInventory = 16,
  maxIdleTime               = 20,
}

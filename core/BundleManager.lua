local sfmt             = string.format

local fs               = require("pl.path")
local dir              = require("pl.dir")
local file             = require("pl.file")
local tablex           = require("pl.tablex")
local pretty           = require("pl.pretty")

local Data             = require("core.Data")
local Area             = require("core.Area")
local Command          = require("core.Command")
local CommandType      = require("core.CommandType")
local Item             = require("core.Item")
local Npc              = require("core.Npc")
local QuestGoal        = require("core.QuestGoal")
local QuestReward      = require("core.QuestReward")
local Room             = require("core.Room")
local Skill            = require("core.Skill")
local SkillType        = require("core.SkillType")
local Helpfile         = require("core.Helpfile")
local Logger           = require("core.Logger")

local AttributeFormula = require("core.Attribute").AttributeFormula

local srcPath          = "./"

---@class BundleManager : Class
local M                = class()

function M:_init(path, state)
  if not path or not fs.exists(path) then error("Invalid bundle path") end
  self.state = state
  self.bundlesPath = path
  self.areas = {}
  self.loaderRegistry = self.state.EntityLoaderRegistry
end

function M:loadBundles(distribute)
  distribute = distribute == nil and true or distribute
  Logger.verbose("LOAD: BUNDLES")

  local bundles = dir.getdirectories(self.bundlesPath)
  for _, bundlePath in ipairs(bundles) do
    local bundle = bundlePath:sub(#self.bundlesPath + 1)
    if fs.isfile(bundlePath) or bundle == "." or bundle == ".." then
      goto continue
    end

    if not tablex.find(self.state.Config.get("bundles", {}), bundle) then
      goto continue
    end

    self:loadBundle(bundle, bundlePath)
    ::continue::
  end

  self.state.AttributeFactory:validateAttributes()

  Logger.verbose("ENDLOAD: BUNDLES")

  if not distribute then return end

  for _, areaRef in ipairs(self.areas) do
    local area = self.state.AreaFactory:create(areaRef)
    area:hydrate(self.state)
    self.state.AreaManager:addArea(area)
  end
end

function M:loadBundle(bundle, bundlePath)
  local features = {
    -- quest goals/rewards have to be loaded before areas that have quests which use those goals
    { path = "quest-goals/", fn   = "loadQuestGoals" },
    { path = "quest-rewards/", fn   = "loadQuestRewards" },

    { path = "attributes.lua", fn   = "loadAttributes" },

    -- any entity in an area, including the area itself, can have behaviors so load them first
    { path = "behaviors/", fn   = "loadBehaviors" },

    { path = "channels.lua", fn   = "loadChannels" },
    { path = "commands/", fn   = "loadCommands" },
    { path = "effects/", fn   = "loadEffects" },
    { path = "input-events/", fn   = "loadInputEvents" },
    { path = "server-events/", fn   = "loadServerEvents" },
    { path = "player-events.lua", fn   = "loadPlayerEvents" },
    { path = "skills/", fn   = "loadSkills" },
  }

  Logger.verbose("LOAD: BUNDLE [%s] START", bundle)
  for _, feature in ipairs(features) do
    local path = bundlePath .. "/" .. feature.path
    if fs.exists(path) then self[feature.fn](self, bundle, path) end
  end

  self:loadAreas(bundle)
  self:loadHelp(bundle)

  Logger.verbose("ENDLOAD: BUNDLE [%q]", bundle)
end

function M:loadQuestGoals(bundle, goalsDir)
  Logger.verbose("\tLOAD: Quest Goals...")
  local files = dir.getfiles(goalsDir)

  for _, goalPath in ipairs(files) do
    local _, goalFile   = fs.splitpath(goalPath)
    if not Data.isScriptFile(goalPath, goalFile) then goto continue end
    ::continue::
    local goalName, ext = fs.splitext(goalFile)
    local loader        = require(goalPath:gsub(ext, ""))
    local goalImport    = QuestGoal:class_of(loader()) and loader or
                            loader(srcPath)
    Logger.verbose("\t\t%s", goalName)

    self.state.QuestGoalManager:set(goalName, goalImport)

    Logger.verbose("\tENDLOAD: Quest Goals...")
  end
end

function M:loadQuestRewards(bundle, rewardsDir)
  Logger.verbose("\tLOAD: Quest Rewards...")

  local files = dir.getfiles(rewardsDir)

  for _, rewardPath in ipairs(files) do
    local _, rewardFile   = fs.splitpath(rewardPath)
    if not Data.isScriptFile(rewardPath, rewardFile) then goto continue end

    local rewardName, ext = fs.splitext(rewardFile)
    local loader          = require(rewardPath:gsub(ext, ""))
    local rewardImport    = QuestReward:class_of(loader()) and loader or
                              loader(srcPath)
    Logger.verbose("\t\t%s", rewardName)

    self.state.QuestRewardManager:set(rewardName, rewardImport)
  end

  Logger.verbose("\tENDLOAD: Quest Rewards...")
  ::continue::
end

function M:loadAttributes(bundle, attributesFile)
  Logger.verbose("\tLOAD: Attributes...")

  local attributes = loadfile(attributesFile, "bt")()
  local errormsg   = sfmt("\tAttributes file [%s] from bundle [%s]",
                          attributesFile, bundle)
  if type(attributes) ~= "table" then
    Logger.error("%s does not define an array of attributes", errormsg)
    return
  end

  for _, attribute in ipairs(attributes) do
    if type(attribute) ~= "table" then
      Logger.error("%s not an object", errormsg)
      goto continue
    end

    if not attribute["name"] or not attribute["base"] then
      Logger.error("%s does not include required properties name and base",
                   errormsg)
      goto continue
    end

    local formula
    if attribute.formula then
      formula = AttributeFormula(attribute.formula.requires,
                                 attribute.formula.fn)
    end

    Logger.verbose("\t\t-> %s", attribute.name)

    self.state.AttributeFactory:add(attribute.name, attribute.base, formula,
                                    attribute.metadata)
    ::continue::
  end

  Logger.verbose("\tENDLOAD: Attributes...")
end

function M:loadPlayerEvents(bundle, eventsFile)
  Logger.verbose("\tLOAD: Player Events...")

  local loader          = require(eventsFile:gsub(".lua", ""))
  local playerListeners = self:_getLoader(loader, srcPath).listeners

  for eventName, listener in pairs(playerListeners) do
    Logger.verbose("\t\tEvent: %s", eventName)
    self.state.PlayerManager:addListener(eventName, listener(self.state))
  end

  Logger.verbose("\tENDLOAD: Player Events...")
end

function M:loadAreas(bundle)
  Logger.verbose("\tLOAD: Areas...");

  local areaLoader = self.loaderRegistry:get("areas");
  areaLoader:setBundle(bundle);
  local areas      = {};

  if not areaLoader:hasData() then return areas end

  areas = areaLoader:fetchAll();

  for name, manifest in pairs(areas) do
    self.areas[#self.areas + 1] = name
    self:loadArea(bundle, name, manifest)

  end
  Logger.verbose("\tENDLOAD: Areas");
end

function M:loadArea(bundle, areaName, manifest)
  local definition = {
    bundle   = bundle,
    manifest = manifest,
    quests   = {},
    items    = {},
    npcs     = {},
    rooms    = {},
  }

  local scriptPath = self:_getAreaScriptPath(bundle, areaName)

  if manifest.script then
    local areaScriptPath = sfmt("%s/%s.lua", scriptPath, manifest.script) -- '${scriptPath}/${manifest.script}.js'
    if not fs.exists(areaScriptPath) then
      Logger.warn("\t\t\t[%s] has non-existent script \"%s\"", areaName,
                  manifest.script)
    end

    Logger.verbose("\t\t\tLoading Area Script for [%s]: %s", areaName,
                   manifest.script)
    self:loadEntityScript(self.state.AreaFactory, areaName, areaScriptPath)
  end

  Logger.verbose("\t\tLOAD: Quests...")
  definition.quests = self:loadQuests(bundle, areaName)
  Logger.verbose("\t\tLOAD: Items...")
  definition.items = self:loadEntities(bundle, areaName, "items",
                                       self.state.ItemFactory)
  Logger.verbose("\t\tLOAD: NPCs...")
  definition.npcs = self:loadEntities(bundle, areaName, "npcs",
                                      self.state.MobFactory)
  Logger.verbose("\t\tLOAD: Rooms...")
  definition.rooms = self:loadEntities(bundle, areaName, "rooms",
                                       self.state.RoomFactory)
  Logger.verbose("\t\tDone.")

  for _, npcRef in pairs(definition.npcs) do
    local npc = self.state.MobFactory:getDefinition(npcRef)
    if not npc.quests then goto continue end
    for _, qid in ipairs(npc.quests) do
      local quest = self.state.QuestFactory:get(qid)
      if not quest then
        Logger.error("\t\t\tError: NPC is questor for non-existent quest [%q]",
                     qid)
        goto continue2
      end
      quest.npc = npcRef
      self.state.QuestFactory.set(qid, quest)
      ::continue2::
    end
    ::continue::
  end
  self.state.AreaFactory:setDefinition(areaName, definition)
end

function M:loadEntities(bundle, areaName, type, factory)
  local loader     = self.loaderRegistry:get(type)
  loader:setBundle(bundle)
  loader:setArea(areaName)

  if not loader:hasData() then return {} end

  local entities   = loader:fetchAll()
  if not entities then
    Logger.warn("\t\t\t%q has an invalid value [%q]", type, entities)
    return {}
  end

  local scriptPath = self:_getAreaScriptPath(bundle, areaName)
  local res        = {}
  for _, entity in ipairs(entities) do
    local entityRef = factory:createEntityRef(areaName, entity.id)
    factory:setDefinition(entityRef, entity)
    if entity.script then
      local entityScript = sfmt("%s/%s/%s.lua", scriptPath, type, entity.script)
      if not fs.exists(entityScript) then
        Logger.warn("\t\t\t[%s] has non-existent script \"%s\"", entityRef,
                    entity.script)
      else
        Logger.verbose("\t\t\tLoading Script [%s] %s", entityRef, entity.script)
        self:loadEntityScript(factory, entityRef, entityScript)
      end
    end

  end

  return res
end

function M:loadEntityScript(factory, entityRef, scriptPath)
  local loader          = require(scriptPath:gsub(".lua", ""))
  local scriptListeners = self:_getLoader(loader, srcPath).listeners

  for eventName, listener in pairs(scriptListeners) do
    Logger.verbose("\t\t\t\tEvent: %s", eventName)
    factory:addScriptListener(entityRef, eventName, listener(self.state))
  end
end

function M:loadQuests(bundle, areaName)
  local loader     = self.loaderRegistry:get("quests")
  loader:setBundle(bundle)
  loader:setArea(areaName)
  local ok, quests = pcall(loader.fetchAll, loader)
  if not ok then
    Logger.error(quests)
    quests = {}
  end
  local res        = {}
  for _, quest in pairs(quests) do
    Logger.verbose("\t\t\tLoading Quest [%s:%s]", areaName, quest.id)
    self.state.QuestFactory:add(areaName, quest.id, quest)
    res[#res + 1] = self.state.QuestFactory:makeQuestKey(areaName, quest.id)

  end

  return res
end

function M:loadCommands(bundle, commandsDir)
  Logger.verbose("\tLOAD: Commands...")
  local files = dir.getallfiles(commandsDir)

  for _, commandFile in ipairs(files) do
    local commandPath = commandsDir .. commandFile
    if not Data.isScriptFile(commandPath, commandFile) then goto continue end
    local commandName = fs.basename(commandFile, fs.extension(commandFile))
    local command     = self:createCommand(commandPath, commandName, bundle)
    self.state.CommandManager:add(command)

    ::continue::
  end

  Logger.verbose("\tENDLOAD: Commands...")
end

function M:createCommand(commandPath, commandName, bundle)
  local loader    = require(commandPath)
  local cmdImport = self:_getLoader(loader, srcPath, self.bundlesPath)
  cmdImport.command = cmdImport.command(self.state)

  return Command(bundle, commandName, cmdImport, commandPath)
end

function M:loadChannels(bundle, channelsFile)
  Logger.verbose("\tLOAD: Channels...")

  local loader   = require(channelsFile)
  local channels = self:_getLoader(loader, srcPath)

  if type(channels) ~= "table" then channels = { channels } end
  tablex.foreachi(channels, function(channel, i)
    channel.bundle = bundle
    self.state.ChannelManager:add(channel)
  end)

  Logger.verbose("\tENDLOAD: Channels...")
end

function M:loadHelp(bundle)
  Logger.verbose("\tLOAD: Help...")
  local loader  = self.loaderRegistry:get("help")
  loader:setBundle(bundle)

  if not loader:hasData() then return end

  local records = loader:fetchAll()
  for _, helpName in ipairs(records) do
    local hfile = Helpfile(bundle, helpName, records[helpName])
    self.state.HelpManager:add(hfile)

  end
  Logger.verbose("\tENDLOAD: Help...")
end

function M:loadInputEvents(bundle, inputEventsDir)
  Logger.verbose("\tLOAD: Events...")
  local files = fs.getallfiles(inputEventsDir)

  for _, eventFile in ipairs(files) do
    local eventPath   = inputEventsDir .. eventFile
    if not Data.isScriptFile(eventPath, eventFile) then goto continue end

    local eventName   = fs.basename(eventFile, fs.extension(eventFile))
    local loader      = require(eventPath)
    local eventImport = self:_getLoader(loader, srcPath)

    if type(eventImport.event) ~= "function" then
      error(sfmt(
              "Bundle %s has an invalid input event %s. Expected a function, got: %q",
              bundle, eventName, eventImport.event))
    end

    self.state.InputEventManager:add(eventName, eventImport.event(self.state))
    ::continue::
  end
  Logger.verbose("\tENDLOAD: Events...")
end

function M:loadBehaviors(bundle, behaviorsDir)
  Logger.verbose("\tLOAD: Behaviors...")

  local loadEntityBehaviors = function(type, manager, state)
    local typeDir = behaviorsDir + type + "/"

    if not fs.exists(typeDir) then return end

    Logger.verbose("\t\tLOAD: BEHAVIORS [%s]...", type)
    local files   = fs.getallfiles(typeDir)

    for _, behaviorFile in ipairs(files) do
      local behaviorPath      = typeDir .. behaviorFile
      if not Data.isScriptFile(behaviorPath, behaviorFile) then
        goto continue
      end

      local behaviorName      = fs.basename(behaviorFile,
                                            fs.extension(behaviorFile))
      Logger.verbose("\t\t\tLOAD: BEHAVIORS [%s] %s...", type, behaviorName)
      local loader            = require(behaviorPath)
      local behaviorListeners = self:_getLoader(loader, srcPath).listeners

      for eventName, listener in pairs(behaviorListeners) do
        manager:addListener(behaviorName, eventName, listener(state))
      end
      ::continue::

    end
  end

  loadEntityBehaviors("area", self.state.AreaBehaviorManager, self.state)
  loadEntityBehaviors("npc", self.state.MobBehaviorManager, self.state)
  loadEntityBehaviors("item", self.state.ItemBehaviorManager, self.state)
  loadEntityBehaviors("room", self.state.RoomBehaviorManager, self.state)

  Logger.verbose("\tENDLOAD: Behaviors...")
end

function M:loadEffects(bundle, effectsDir)
  Logger.verbose("\tLOAD: Effects...")
  local files = fs.getallfiles(effectsDir)

  for _, effectFile in ipairs(files) do
    local effectPath = effectsDir .. effectFile
    if not Data.isScriptFile(effectPath, effectFile) then goto continue end

    local effectName = fs.basename(effectFile, fs.extension(effectFile))
    local loader     = require(effectPath)

    Logger.verbose("\t\t%s", effectName)
    self.state.EffectFactory.add(effectName, self:_getLoader(loader, srcPath),
                                 self.state)
    ::continue::
  end

  Logger.verbose("\tENDLOAD: Effects...")
end

function M:loadSkills(bundle, skillsDir)
  Logger.verbose("\tLOAD: Skills...")
  local files = fs.getallfiles(skillsDir)

  for _, skillFile in ipairs(files) do
    local skillPath   = skillsDir .. skillFile
    if not Data.isScriptFile(skillPath, skillFile) then goto continue end
    local skillName   = fs.basename(skillFile, fs.extension(skillFile))
    local loader      = require(skillPath)
    local skillImport = self:_getLoader(loader, srcPath)
    if skillImport.run then skillImport.run = skillImport.run(self.state) end

    Logger.verbose("\t\t%s", skillName)
    local skill       = Skill(skillName, skillImport, self.state)

    if skill.type == SkillType.SKILL then
      self.state.SkillManager:add(skill)
    else
      self.state.SpellManager:add(skill)
    end

    ::continue::
  end
  Logger.verbose("\tENDLOAD: Skills...")
end

function M:loadServerEvents(bundle, serverEventsDir)
  Logger.verbose("\tLOAD: Server Events...")
  local files = fs.getallfiles(serverEventsDir)

  for _, eventsFile in ipairs(files) do
    local eventsPath      = serverEventsDir .. eventsFile
    if not Data.isScriptFile(eventsPath, eventsFile) then goto continue end
    local eventsName      = fs.basename(eventsFile, fs.extension(eventsFile))
    Logger.verbose("\t\t\tLOAD: SERVER-EVENTS %s...", eventsName)
    local loader          = require(eventsPath)
    local eventsListeners = self:_getLoader(loader, srcPath).listeners

    for eventName, listener in pairs(eventsListeners) do
      self.state.ServerEventManager:add(eventName, listener(self.state))
    end
    ::continue::
  end
  Logger.verbose("\tENDLOAD: Server Events...")
end

function M:_getLoader(loader, ...)
  if type(loader) == "function" then return loader(...) end
  return loader
end

function M:_getAreaScriptPath(bundle, areaName)
  return sfmt("%s/%s/areas/%s/scripts", self.bundlesPath, bundle, areaName)
end

return M

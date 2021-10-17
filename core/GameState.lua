local luaenv               = require("luaenv")

local AccountManager       = require("core.AccountManager")
local BehaviorManager      = require("core.BehaviorManager")
local AreaFactory          = require("core.AreaFactory")
local AreaManager          = require("core.AreaManager")
local AttributeFactory     = require("core.AttributeFactory")
local ChannelManager       = require("core.ChannelManager")
local CommandManager       = require("core.CommandManager")
local EffectFactory        = require("core.EffectFactory")
local HelpManager          = require("core.HelpManager")
local EventManager         = require("core.EventManager")
local ItemFactory          = require("core.ItemFactory")
local ItemManager          = require("core.ItemManager")
local MobFactory           = require("core.MobFactory")
local MobManager           = require("core.MobManager")
local PartyManager         = require("core.PartyManager")
local PlayerManager        = require("core.PlayerManager")
local QuestFactory         = require("core.QuestFactory")
local QuestGoalManager     = require("core.QuestGoalManager")
local QuestRewardManager   = require("core.QuestRewardManager")
local RoomFactory          = require("core.RoomFactory")
local RoomManager          = require("core.RoomManager")
local SkillManager         = require("core.SkillManager")
local GameServer           = require("core.GameServer")

local EntityLoaderRegistry = require("core.EntityLoaderRegistry")
local DataSourceRegistry   = require("core.DataSourceRegistry")
local Config               = require("core.Config")
local Data                 = require("core.Data")
local Logger               = require("core.Logger")
local BundleManager        = require("core.BundleManager")

---@class GameState : Class
---@field AccountManager  AccountManager
---@field AreaBehaviorManager  BehaviorManager
---@field AreaFactory  AreaFactory
---@field AreaManager  AreaManager
---@field AttributeFactory  AttributeFactory
---@field ChannelManager  ChannelManager
---@field CommandManager  CommandManager
---@field Config  Config
---@field EffectFactory  EffectFactory
---@field HelpManager  HelpManager
---@field InputEventManager  EventManager
---@field ItemBehaviorManager  BehaviorManager
---@field ItemFactory  ItemFactory
---@field ItemManager  ItemManager
---@field MobBehaviorManager  BehaviorManager
---@field MobFactory  MobFactory
---@field MobManager  MobManager
---@field PartyManager  PartyManager
---@field PlayerManager  PlayerManager
---@field QuestFactory  QuestFactory
---@field QuestGoalManager  QuestGoalManager
---@field QuestRewardManager  QuestRewardManager
---@field RoomBehaviorManager  BehaviorManager
---@field RoomFactory  RoomFactory
---@field RoomManager  RoomManager
---@field SkillManager  SkillManager
---@field SpellManager  SkillManager
---@field ServerEventManager  EventManager
---@field GameServer  GameServer
---@field DataLoader  Data
---@field EntityLoaderRegistry  EntityLoaderRegistry
---@field DataSourceRegistry  DataSourceRegistry
---@field BundleManager  BundleManager
local M                    = class()

---@param config string|table #config module or file
---@param dirname? string work dir default .
function M:_init(config, dirname)
  assert(config, "Need config module")
  if type(config) == "string" then
    config = require(config)
  else
    assert(type(config) == "table", "config must a string or a table")
  end
  Logger.verbose("INIT - GameState")
  Config.load(config)
  restartServer = restartServer or true
  self.dirname = dirname or "."
  self.AccountManager = AccountManager()
  self.AreaBehaviorManager = BehaviorManager()
  self.AreaFactory = AreaFactory()
  self.AreaManager = AreaManager()
  self.AttributeFactory = AttributeFactory()
  self.ChannelManager = ChannelManager()
  self.CommandManager = CommandManager()
  self.Config = Config
  self.EffectFactory = EffectFactory()
  self.HelpManager = HelpManager()
  self.InputEventManager = EventManager()
  self.ItemBehaviorManager = BehaviorManager()
  self.ItemFactory = ItemFactory()
  self.ItemManager = ItemManager()
  self.MobBehaviorManager = BehaviorManager()
  self.MobFactory = MobFactory()
  self.MobManager = MobManager()
  self.PartyManager = PartyManager()
  self.PlayerManager = PlayerManager()
  self.QuestFactory = QuestFactory()
  self.QuestGoalManager = QuestGoalManager()
  self.QuestRewardManager = QuestRewardManager()
  self.RoomBehaviorManager = BehaviorManager()
  self.RoomFactory = RoomFactory()
  self.RoomManager = RoomManager()
  self.SkillManager = SkillManager()
  self.SpellManager = SkillManager()
  self.ServerEventManager = EventManager()
  self.GameServer = GameServer()
  self.DataLoader = Data
  self.EntityLoaderRegistry = EntityLoaderRegistry()
  self.DataSourceRegistry = DataSourceRegistry()
  self.BundleManager = BundleManager(self.dirname .. "/bundles/", self);
end

function M:start()
  Logger.verbose("START - Starting server");
  self.GameServer:startup();
  self.AreaManager:tickAll(self);
  self.ItemManager:tickAll();
  self.PlayerManager:emit("updateTick");
end
function M:load()
  Logger.verbose("LOAD")
  self.DataSourceRegistry:load(require, self.dirname, Config.get("dataSources"))
  self.EntityLoaderRegistry:load(self.DataSourceRegistry,
                                 Config.get("entityLoaders"))
  self.AccountManager:setLoader(self.EntityLoaderRegistry:get("accounts"));
  self.PlayerManager:setLoader(self.EntityLoaderRegistry:get("players"));

  self.BundleManager:loadBundles();
  self.ServerEventManager:attach(self.GameServer);
end

return M

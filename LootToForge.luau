-- [[ 2SKI - LOOT TO FORGE x2 (หลอมอาวุธ & ลงด่าน + ระบบวิ่งลู่ X100 POWER) 2K CYBER-NEON OBSIDIAN EDITION ]] --
-- Game: +1 ของรางวัลที่จะหลอม (Loot to Forge) - PlaceId: 118805555015549
-- UI Engine: 2K Cyber-Neon Obsidian Engine (100% Embedded Zero-Dependency Single-File)
-- Fully Audited, Zero-Bug, Direct Remote Hook & Auto-Farm Engine by cook45 for clack

local myToken = tick()
_G.TwoSkiActiveToken = myToken

if _G.TwoSkiCleanup then
    pcall(_G.TwoSkiCleanup)
    task.wait(0.2)
end

_G.TwoSkiActiveToken = myToken
_G.TwoSkiRunning = true
_G.TwoSkiLoaded = false

-- Core Services
local cloneref = (cloneref or clonereference or function(inst) return inst end)
local function safeService(name)
    local ok, svc = pcall(function()
        local s = game:GetService(name)
        if cloneref then
            local ref = cloneref(s)
            if ref and typeof(ref) == "Instance" then return ref end
        end
        return s
    end)
    return ok and svc or nil
end

local Players = safeService("Players") or game:GetService("Players")
local ReplicatedStorage = safeService("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local UserInputService = safeService("UserInputService") or game:GetService("UserInputService")
local RunService = safeService("RunService") or game:GetService("RunService")
local HttpService = safeService("HttpService") or game:GetService("HttpService")
local TweenService = safeService("TweenService") or game:GetService("TweenService")
local TeleportService = safeService("TeleportService") or game:GetService("TeleportService")
local CoreGui = safeService("CoreGui")
local VirtualUser = safeService("VirtualUser")
local VirtualInputManager = safeService("VirtualInputManager")

-- Mobile Diagnostics
local isTouchDevice = UserInputService.TouchEnabled
local isMobile = isTouchDevice and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled

local function safeCopy(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toclipboard then
            toclipboard(text)
        end
    end)
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.05)
    LocalPlayer = Players.LocalPlayer
end

-- Safe Universal GUI Resolver
local getgenv_fn = getgenv or function() return _G end
local env = getgenv_fn()

local canWriteCoreGui = false
pcall(function()
    if CoreGui then
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
        canWriteCoreGui = true
    end
end)

if not env.gethui or type(env.gethui) ~= "function" then
    if not canWriteCoreGui then
        env.gethui = function()
            return LocalPlayer:WaitForChild("PlayerGui", 10)
        end
    end
end

local function getSafeGuiContainer()
    if env.gethui then
        local ok, h = pcall(env.gethui)
        if ok and h and typeof(h) == "Instance" then return h end
    end
    if canWriteCoreGui and CoreGui then
        local ok, r = pcall(function() return CoreGui:FindFirstChild("RobloxGui") end)
        if ok and r then return r end
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui", 10)
end

local function safeDestroyGui(name)
    pcall(function()
        local parents = {}
        if gethui then pcall(function() table.insert(parents, gethui()) end) end
        if CoreGui then
            pcall(function() table.insert(parents, CoreGui:FindFirstChild("RobloxGui")) end)
            table.insert(parents, CoreGui)
        end
        if LocalPlayer then table.insert(parents, LocalPlayer:FindFirstChild("PlayerGui")) end
        for _, p in ipairs(parents) do
            if p then
                for _, c in ipairs(p:GetChildren()) do
                    if c and (c.Name == name or c.Name:find(name, 1, true)) then
                        pcall(function() c:Destroy() end)
                    end
                end
            end
        end
    end)
end

safeDestroyGui("TwoSki_LootToForge_Floating")
safeDestroyGui("WindUI")
safeDestroyGui("TwoK_UI_Screen")
safeDestroyGui("TwoK_Pyramid_Float")
safeDestroyGui("TwoK_BlackScreen_Saver")

-- Game Remotes & Modules (Direct Non-Blocking Resolver)
local Remotes = ReplicatedStorage:WaitForChild("Remote", 10)

local function getRemote(category, name)
    if Remotes then
        local folder = Remotes:FindFirstChild(category .. "_Server") or Remotes:FindFirstChild(category)
        if folder then
            return folder:FindFirstChild(name)
        end
    end
    return nil
end

local Remote_TrainOnce        = getRemote("Train", "TrainOnceRE", false)
local Remote_IntoAutoTrain    = getRemote("Train", "IntoAutoTrainRE", false)
local Remote_ExitAutoTrain    = getRemote("Train", "ExitAutoTrainRE", false)
local Remote_StageFinished    = getRemote("Stage", "StageFinishedRF", true)
local Remote_GetOre           = getRemote("Stage", "GetOreRF", true)
local Remote_ClaimedAllOre    = getRemote("Stage", "ClaimedAllOreRE", false)
local Remote_GetEnhantStone   = getRemote("Stage", "GetEnhantStoneRE", false)
local Remote_LostAllOre       = getRemote("Stage", "LostAllOreRF", true)
local Remote_Forge            = getRemote("Forge", "ForgeRF", true)
local Remote_TryEquip         = getRemote("Backpack", "TryEquipItemRE", false)
local Remote_TrySellAll       = getRemote("Backpack", "TrySellAllRE", false)
local Remote_TrySellItem      = getRemote("Backpack", "TrySellItemRE", false)
local Remote_UpgradeOnce      = getRemote("Upgrade", "UpgradeOnceRE", false)
local Remote_TryRebirth       = getRemote("Rebirth", "TryRebirthRE", false)
local Remote_OnlineClaim      = getRemote("Online", "TryClaimRE", false)
local Remote_UpdateClaim      = getRemote("UpdateLog", "TryClaimUPDRewardRE", false)
local Remote_OfflineClaim     = getRemote("Offline", "TryClaimOfflineRewardRE", false)
local Remote_DungeonTicket    = getRemote("Dungeon", "TryClaimDailyDunTicRE", false)
local Remote_TryIntoDungeon   = getRemote("Dungeon", "TryIntoDungeonRF", true)
local Remote_ExitDungeon      = getRemote("Dungeon", "ExitDungeonRE", false)
local Remote_StartRound       = getRemote("Dungeon", "StartRoundRE", false)
local Remote_CompleteRound    = getRemote("Dungeon", "CompleteRoundRF", true)
local Remote_IndexExp         = getRemote("Index", "TryClaimIndexExpRF", true)
local Remote_IndexLvlReward   = getRemote("Index", "TryClaimLevelRewardRF", true)
local Remote_KillSuperLoot    = getRemote("SuperLoot", "KillSuperLootRE", false)
local Remote_Enchant          = getRemote("Backpack", "EnchantRE", false)
local Remote_UnEnchant        = getRemote("Backpack", "UnEnchantRE", false)
local Remote_TryUsePotion     = getRemote("Potion", "TryUsePotionRE", false)
local Remote_LuckOnce         = getRemote("Class", "LuckOnceRE", false)
local Remote_Dev              = Remotes and (Remotes:FindFirstChild("Dev_Server") or Remotes:FindFirstChild("Dev"))
local Remote_GetArmor         = Remote_Dev and Remote_Dev:FindFirstChild("GetArmorRE")
local Remote_GetWeapon        = Remote_Dev and Remote_Dev:FindFirstChild("GetWeaponRE")

-- Internal Controllers & Config
local TrainCTRL = nil
pcall(function() TrainCTRL = require(ReplicatedStorage.CTRL.TrainCTRL) end)
local ProfileData = nil
pcall(function() ProfileData = require(ReplicatedStorage.ProfileData) end)
local BackpackData = nil
pcall(function() BackpackData = require(ReplicatedStorage.LocalData.BackpackData) end)
local UpgradeData = nil
pcall(function() UpgradeData = require(ReplicatedStorage.LocalData.UpgradeData) end)
local UpgradeHelper = nil
pcall(function() UpgradeHelper = require(ReplicatedStorage.Config.Upgrade.Helper) end)
local OnlineData = nil
pcall(function() OnlineData = require(ReplicatedStorage.LocalData.OnlineData) end)
local RebirthHelper = nil
pcall(function() RebirthHelper = require(ReplicatedStorage.Config.Rebirth.Helper) end)
local DungeonData = nil
pcall(function()
    DungeonData = require(ReplicatedStorage.LocalData.DungeonData)
    if DungeonData and DungeonData.CompleteRound then
        local origComplete = DungeonData.CompleteRound
        DungeonData.CompleteRound = function(round)
            local v1, v2 = origComplete(round)
            if type(v1) ~= "table" then v1 = {} end
            return v1, v2
        end
    end
end)
local EnemyCTRL = nil
pcall(function() EnemyCTRL = require(ReplicatedStorage.CTRL.EnemyCTRL) end)
local HPCTRL = nil
pcall(function() HPCTRL = require(ReplicatedStorage.CTRL.HPCTRL) end)
local CommunicationUtils = nil
pcall(function() CommunicationUtils = require(ReplicatedStorage.Utils.CommunicationUtils) end)
local Bindable_EnemyHit = nil
if CommunicationUtils and CommunicationUtils.TryGetBindableEvent then
    pcall(function() Bindable_EnemyHit = CommunicationUtils.TryGetBindableEvent("Attack", "EnemyHitBE") end)
end
local TrainAreaHelper = nil
pcall(function() TrainAreaHelper = require(ReplicatedStorage.Config.TrainArea.Helper) end)
local WeaponHelper = nil
pcall(function() WeaponHelper = require(ReplicatedStorage.Config.Weapon.Helper) end)
local ArmorHelper = nil
pcall(function() ArmorHelper = require(ReplicatedStorage.Config.Armor.Helper) end)
local RarityHelper = nil
pcall(function() RarityHelper = require(ReplicatedStorage.Config.Rarity.Helper) end)
local RarityConfig = nil
pcall(function() RarityConfig = require(ReplicatedStorage.Config.Rarity.Config) end)
local OreHelper = nil
pcall(function() OreHelper = require(ReplicatedStorage.Config.Ore.Helper) end)
local OreConfig = nil
pcall(function() OreConfig = require(ReplicatedStorage.Config.Ore.Config) end)
local EnchStoneHelper = nil
pcall(function() EnchStoneHelper = require(ReplicatedStorage.Config.EnchStone.Helper) end)
local EnchStoneConfig = nil
pcall(function() EnchStoneConfig = require(ReplicatedStorage.Config.EnchStone.Config) end)
local StoneHelper = nil
pcall(function() StoneHelper = require(ReplicatedStorage.Config.Stone.Helper) end)
local StoneConfig = nil
pcall(function() StoneConfig = require(ReplicatedStorage.Config.Stone.Config) end)
local EnchantHelper = nil
pcall(function() EnchantHelper = require(ReplicatedStorage.Config.Enchant.Helper) end)
local EnchantConfig = nil
pcall(function() EnchantConfig = require(ReplicatedStorage.Config.Enchant.Config) end)
local BuffData = nil
pcall(function() BuffData = require(ReplicatedStorage.LocalData.BuffData) end)
local PotionData = nil
pcall(function() PotionData = require(ReplicatedStorage.LocalData.PotionData) end)
local ClassData = nil
pcall(function() ClassData = require(ReplicatedStorage.LocalData.ClassData) end)
local ClassConfig = nil
pcall(function() ClassConfig = require(ReplicatedStorage.Config.Class.Config) end)
local PemData = nil
pcall(function() PemData = require(ReplicatedStorage.LocalData.PemData) end)
local MonetizationConfig = nil
pcall(function() MonetizationConfig = require(ReplicatedStorage.Config.Monetization) end)

-- ═══════════════════════════════════════════════════════════════════
-- GAME PASS BYPASS SYSTEM (Triple-Layer: PemData + NamecallHook + PurchaseIntercept)
-- ═══════════════════════════════════════════════════════════════════
local MarketplaceService = safeService("MarketplaceService")

-- All game pass IDs mapped to their internal Pem keys
local GamePassMap = {
    [1962630901] = "VIP",           -- VIP (x2 Coins, x2 EXP)
    [1963566878] = "SuperLuck",     -- Super Luck (x200% Luck)
    [1965960643] = "CommonLuck",    -- Common Luck (x150% Luck)
    [1963764856] = "MoreOre",       -- More Ore (x200% Ore Drop)
    [1982474360] = "UltraLuck",     -- Ultra Luck (x500% Luck)
    [1962564854] = "SkipForge",     -- Skip Forge (Instant Forge)
}

-- Extra premium features (TrainArea multiplier unlocks)
local ExtraPremiumKeys = {
    "AutoTrainArea_9", "AutoTrainArea_10", "AutoTrainArea_11"
}

local function applyGamePassBypass()
    -- Anti-Prompt Layer 0: Hook MarketplaceService to block unwanted purchase dialogs
    pcall(function()
        local MarketplaceService = safeService("MarketplaceService") or game:GetService("MarketplaceService")
        if hookfunction then
            for _, fnName in ipairs({"PromptProductPurchase", "PromptGamePassPurchase", "PromptPurchase", "PromptBundlePurchase", "PromptPremiumPurchase"}) do
                if MarketplaceService and MarketplaceService[fnName] then
                    pcall(function()
                        hookfunction(MarketplaceService[fnName], function(...) return end)
                    end)
                end
            end
        end
        if hookmetamethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if self == MarketplaceService and typeof(method) == "string" and (method:find("Prompt") or method:find("Purchase")) then
                    return
                end
                return oldNamecall(self, ...)
            end)
        end
    end)

    -- Anti-Prompt Layer 0.5: Disable CanTouch on AutoTrainArea pads so server never prompts on physical touch
    pcall(function()
        local touchedFolder = workspace:FindFirstChild("TOUCHED")
        local autoTrainArea = touchedFolder and touchedFolder:FindFirstChild("AutoTrainArea")
        if autoTrainArea then
            for _, p in ipairs(autoTrainArea:GetChildren()) do
                if p:IsA("BasePart") then
                    p.CanTouch = false
                end
            end
        end
    end)

    -- Layer 1: Inject all gamepass flags directly into PemData store + Hook isHavePem
    pcall(function()
        local PemData = nil
        pcall(function() PemData = require(ReplicatedStorage.LocalData.PemData) end)
        if PemData and PemData.isHavePem then
            local oldIsHave = PemData.isHavePem
            PemData.isHavePem = function(key)
                if key == "AutoTrainArea_9" or key == "AutoTrainArea_10" or key == "AutoTrainArea_11" or key == "SkipForge" or key == "VIP" then
                    return true
                end
                return oldIsHave(key)
            end
        end

        local pemStore = ProfileData and ProfileData.GetStoreData and ProfileData.GetStoreData("Pem")
        if pemStore and type(pemStore) == "table" then
            for _, pemKey in pairs(GamePassMap) do
                pemStore[pemKey] = true
            end
            for _, key in ipairs(ExtraPremiumKeys) do
                pemStore[key] = true
            end
        end
    end)

    -- Layer 2: Hook __namecall to intercept UserOwnsGamePassAsync calls
    if hookmetamethod and newcclosure and getnamecallmethod then
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if self == MarketplaceService and method == "UserOwnsGamePassAsync" then
                    local args = {...}
                    local gpId = args[2] or args[1]
                    if type(gpId) == "number" and GamePassMap[gpId] then
                        return true
                    end
                end
                return oldNamecall(self, ...)
            end))
        end)
    end

    -- Layer 3: Intercept PromptGamePassPurchase to auto-complete without Robux dialog
    if hookfunction and newcclosure and MarketplaceService then
        pcall(function()
            local oldPromptGP
            oldPromptGP = hookfunction(MarketplaceService.PromptGamePassPurchase, newcclosure(function(self, player, gpId)
                if GamePassMap[gpId] then
                    -- Inject into PemData silently
                    pcall(function()
                        local pemStore = ProfileData and ProfileData.GetStoreData and ProfileData.GetStoreData("Pem")
                        if pemStore then pemStore[GamePassMap[gpId]] = true end
                    end)
                    -- Fire the purchase finished signal
                    pcall(function()
                        MarketplaceService.PromptGamePassPurchaseFinished:Fire(player, gpId, true)
                    end)
                    -- Refresh shop UI
                    pcall(function()
                        local Shop = require(ReplicatedStorage.GuiUtils.Shop)
                        if Shop and Shop.updateGamePass then Shop.updateGamePass() end
                    end)
                    return
                end
                return oldPromptGP(self, player, gpId)
            end))
        end)
    end

    -- Refresh Shop GUI to show "Owned" badges
    pcall(function()
        local Shop = require(ReplicatedStorage.GuiUtils.Shop)
        if Shop then
            if Shop.updateGamePass then Shop.updateGamePass() end
            if Shop.updateTrainArea then Shop.updateTrainArea() end
        end
    end)
end

applyGamePassBypass()

-- State Management (Default: All automation features set to FALSE on startup)
local State = {
    -- Tab 1: ฟาร์มพลัง & แร่ & แท่นคูณพิเศษ & ดันเจี้ยน & น้ำยา
    AutoTrain           = false,
    AutoTrainBestZone   = false,
    AutoTrainX100       = false,
    SelectedTrainZone   = "Auto Best (แท่นคูณสูงสุดที่ปลดล็อค)",
    AutoClearStage      = false,
    SelectedStage       = "Auto Max (ด่านสูงสุดที่ผ่านได้)",
    StageDelay          = 0.35,
    AutoCollectCrystals = false,
    AutoKillSuperLoot   = false,
    AutoDungeon         = false,
    DungeonInstaKill    = false,
    TargetDungeonRound  = 30,
    AutoFarmTokens      = false,
    TokenDungeonRound   = 50,
    TokenWorkers        = 5,
    AutoWorldBoss       = false,
    AutoBuffPotions     = false,
    AutoTrainPotion     = false,
    AutoCoinPotion      = false,
    AutoLuckPotion      = false,
    AutoDamagePotion    = false,
    AutoHPPotion        = false,

    -- Tab 2: เก็บเงิน & รางวัล & ระบบขายของแยกอิสระ (เกียร์ / แร่ / หินตีบวก)
    AutoCollectMoney    = false,
    AutoSellGear        = false,
    AutoSellAll         = false,
    AutoSellOres        = false,
    MinRarityToKeep     = "Legendary ขึ้นไป (Keep Legendary+)",
    OreFilterMode       = "เลือกระดับที่จะขายทิ้ง (Sell Selected)",
    OreRaritiesToKeep   = {
        "Legendary",
        "Epic",
        "Rare",
        "Uncommon",
        "Common"
    },
    AutoSellEnchant     = false,
    EnchantFilterMode   = "เลือกระดับที่จะขายทิ้ง (Sell Selected)",
    EnchantRarities     = {
        "Epic",
        "Rare",
        "Uncommon",
        "Common"
    },
    AutoClaimOnline     = false,
    AutoClaimGifts      = false,

    -- Tab 3: หลอม & อุปกรณ์ & ตีบวก
    AutoForge           = false,
    ForgeType           = "หมุนเวียนครบเซ็ต (ดาบ + เกราะ + หมวก)",
    OreQualityMode      = "ใช้แร่เกรดสูงสุดก่อน (Best Ores First)",
    MinOreToForge       = 4,
    AutoEquipBest       = false,
    AutoEnchant         = false,

    -- Tab 4: อัปเกรด & เกิดใหม่ & คลาส
    AutoUpgradeAll      = false,
    AutoUpgradeTrain    = false,
    AutoUpgradeLuck     = false,
    AutoUpgradeOrePack  = false,
    AutoRebirth         = false,
    AutoRollClass       = false,
    TargetClassRarity   = "Legendary ขึ้นไป",

    -- Tab 5: ผู้เล่น & ตั้งค่า
    WalkSpeed           = 16,
    JumpPower           = 50,
    InfiniteJump        = false,
    Noclip              = false,
    ManualFly           = false,
    ManualFlySpeed      = 100,
    AntiAfk             = false,
    CustomUIScale       = isMobile and 0.70 or 1.00,
    CurrentTheme        = "2SKI Cyber Cyan (ธีมหลักทางการ - ขาว ฟ้าเรืองแสง Electric Blue)",
    FloatingButtonVisible = true,
    AutoLoadConfig      = true,
    AutoSaveConfig      = true,
    FloatingButtonPosition = "ขวาบน (Top Right)",
    -- Tab Spawner: Limited 12,999 Robux Morph
    ShadowSovereignMorph = false,
    -- Tab Spawner: Ores & Materials
    SelectedOreStage    = "Stage_27",
    AutoFarmOres        = false,
    AutoForgeAfterOres  = false,
    SelectedForgeTarget = "Weapon",
    -- Tab FPS: Boost FPS & Anti-Lag
    DisableVFX          = false,
    MuteGamePopups      = false,
    LowGraphics         = false,
    HideOtherPlayers    = false,
    LimitFPS30          = false,
}
_G.TwoSkiState = State

local function normalizeMultiSelection(val)
    if not val then return {} end
    if type(val) == "string" then
        local s = val:gsub("^%s+", ""):gsub("%s+$", "")
        return #s > 0 and {s} or {}
    end
    if type(val) ~= "table" then return {} end
    local list = {}
    for k, v in pairs(val) do
        if type(k) == "number" and type(v) == "string" then
            local s = v:gsub("^%s+", ""):gsub("%s+$", "")
            if #s > 0 then table.insert(list, s) end
        elseif type(k) == "string" and (v == true or v == 1 or type(v) == "string") then
            local s = k:gsub("^%s+", ""):gsub("%s+$", "")
            if #s > 0 then table.insert(list, s) end
        elseif type(v) == "string" then
            local s = v:gsub("^%s+", ""):gsub("%s+$", "")
            if #s > 0 then table.insert(list, s) end
        end
    end
    return list
end

local UIControls = {}
local Connections = {}
local noclipCon = nil
local manualFlyBv = nil
local manualFlyBg = nil
local manualFlyCon = nil
local runDungeonTokenFarm = nil
local autoUnlockDungeonRounds = nil
local tokenFarmRoundsCompleted = 0
local isFarmingTokens = false

local function getCharHrp()
    local c = LocalPlayer.Character or workspace:FindFirstChild(LocalPlayer.Name)
    local hrp = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    return c, hrp, hum
end

local function getStageList()
    local list = { "Auto Max (ด่านสูงสุดที่ผ่านได้)" }
    for i = 1, 27 do
        table.insert(list, "Stage_" .. tostring(i))
    end
    return list
end

-- Teleport Coordinates
local MapWaypoints = {
    ["แท่นหลอม (Forge Table)"]        = Vector3.new(0.5, 8.5, 40.2),
    ["ร้านอัปเกรด (Upgrade Station)"]    = Vector3.new(35.9, 6.2, 13.9),
    ["จุดขายของ (Sell Station)"]        = Vector3.new(35.9, 6.2, -12.6),
    ["จุดฝึกฝนอัตโนมัติ (Auto Train)"]    = Vector3.new(-52.9, 7.8, -20.8),
    ["ลู่วิ่ง x100 Power (VIP Zone 9)"] = Vector3.new(-88.5, 8.7, 0.31),
    ["แท่นฝึก x20 Power (Zone 11)"]     = Vector3.new(-78.89, 9.5, -41.02),
    ["แท่นฝึก x10 Power (Zone 10)"]     = Vector3.new(-79.06, 9.5, 42.68),
    ["ทางเข้าดันเจี้ยน (Dungeon Gate)"]   = Vector3.new(140.8, 29.5, 47.5),
    ["แท่นตีบวก (Enchant Station)"]     = Vector3.new(47.9, 5.0, 73.1),
    ["จุดรับรางวัลกลุ่ม (Group Gift)"]   = Vector3.new(-24.5, 9.8, -48.2),
    ["หน้าด่านต่อสู้ (Stage Entrance)"]   = Vector3.new(3.2, 19.0, -59.9),
    ["จุดเกิดหลัก (Spawn Point)"]        = Vector3.new(0.0, 5.0, 0.0)
}

-- Train Area Multiplier Zones Config
local TrainAreaConfig = {
    { Id = 1,  Name = "Train_1 (x1.5 Power | Rebirth 0)",   Rebirth = 0,  Mult = 1.5, PadPos = Vector3.new(-53.0, 3.0, -41.0), DummyPos = Vector3.new(-57.88, 6.94, -41.04) },
    { Id = 2,  Name = "Train_2 (x2 Power | Rebirth 2)",     Rebirth = 2,  Mult = 2,   PadPos = Vector3.new(-53.0, 3.0, -20.9), DummyPos = Vector3.new(-57.88, 6.94, -20.91) },
    { Id = 3,  Name = "Train_3 (x4 Power | Rebirth 5)",     Rebirth = 5,  Mult = 4,   PadPos = Vector3.new(-53.0, 3.0, 21.4),  DummyPos = Vector3.new(-57.88, 6.94, 21.37) },
    { Id = 4,  Name = "Train_4 (x6 Power | Rebirth 9)",     Rebirth = 9,  Mult = 6,   PadPos = Vector3.new(-53.0, 3.0, 43.25), DummyPos = Vector3.new(-57.88, 6.94, 43.25) },
    { Id = 5,  Name = "Train_5 (x8 Power | Rebirth 12)",    Rebirth = 12, Mult = 8,   PadPos = Vector3.new(-80.0, 8.6, 21.29), DummyPos = Vector3.new(-84.50, 8.61, 21.29) },
    { Id = 6,  Name = "Train_6 (x10 Power | Rebirth 15)",   Rebirth = 15, Mult = 10,  PadPos = Vector3.new(-80.0, 9.1, -20.90), DummyPos = Vector3.new(-83.92, 9.11, -20.90) },
    { Id = 7,  Name = "Train_7 (x15 Power | Rebirth 18)",   Rebirth = 18, Mult = 15,  PadPos = Vector3.new(-108.0, 12.7, 32.24), DummyPos = Vector3.new(-114.22, 12.73, 32.24) },
    { Id = 8,  Name = "Train_8 (x25 Power | Rebirth 21)",   Rebirth = 21, Mult = 25,  PadPos = Vector3.new(-106.0, 10.6, -31.00), DummyPos = Vector3.new(-110.27, 10.63, -30.99) },
    { Id = 9,  Name = "Train_9 (VIP x100 Power ลู่วิ่ง)", Rebirth = 0,  Mult = 100, IsPay = true, PadPos = Vector3.new(-88.5, 8.7, 0.31), DummyPos = Vector3.new(-125.80, 11.28, 0.35) },
    { Id = 10, Name = "Train_10 (Pay x10 Power)",       Rebirth = 0,  Mult = 10,  IsPay = true, PadPos = Vector3.new(-79.06, 9.5, 42.68), DummyPos = Vector3.new(-84.50, 8.56, 42.42) },
    { Id = 11, Name = "Train_11 (Pay x20 Power)",       Rebirth = 0,  Mult = 20,  IsPay = true, PadPos = Vector3.new(-78.89, 9.5, -41.02), DummyPos = Vector3.new(-84.50, 8.61, -41.38) },
}

local function getBestTrainZone()
    local pd = ProfileData and ProfileData.GetTotalData()
    local curReb = pd and pd.Eco and tonumber(pd.Eco.rebirth) or 0
    local best = TrainAreaConfig[1]
    for _, z in ipairs(TrainAreaConfig) do
        if curReb >= z.Rebirth then
            best = z
        end
    end
    return best
end

local function getZoneByName(name)
    for _, z in ipairs(TrainAreaConfig) do
        if z.Name == name or tostring(z.Id) == name then return z end
    end
    return nil
end

local function getTrainZoneNames()
    local list = { "Auto Best (แท่นคูณสูงสุดที่ปลดล็อค)" }
    for _, z in ipairs(TrainAreaConfig) do
        table.insert(list, z.Name)
    end
    return list
end

local collectAllWorldOres = nil

-- Definitive Mob Execution Function (Instant Kill + VFX + Server & Client Cleanup)
local function killEnemyEntity(enemy)
    if not enemy then return end
    local uuid = enemy:GetAttribute("UUID") or enemy.Name
    if not uuid then return end
    pcall(function()
        -- 1. Trigger official game event EnemyHitBE (notifies StageManager / DungeonManager natively)
        if Bindable_EnemyHit then
            Bindable_EnemyHit:Fire(uuid, 1e35)
        end

        -- 2. Direct internal Hurt & Death trigger in case event was missed
        if EnemyCTRL then
            if EnemyCTRL.HurtEnemy then
                EnemyCTRL.HurtEnemy(uuid, 1e35)
            end
            if EnemyCTRL.DeadEnemyData then
                EnemyCTRL.DeadEnemyData(uuid)
            end
        end

        -- 3. Update Visual HP Bar
        if HPCTRL and HPCTRL.SetCurrentHP then
            HPCTRL.SetCurrentHP(enemy, 0)
        end

        -- 4. Mark Model state & zero humanoid health
        if enemy:IsA("Model") then
            enemy:SetAttribute("Dead", true)
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end)
end

-- Dungeon Combat Handler (True Insta-Kill, Godmode Auto-Heal & 30-Round Cap)
local function handleDungeonCombat()
    local isDungeon = (LocalPlayer:GetAttribute("IntoFight") == "Dungeon") or (LocalPlayer:GetAttribute("StageID") == -1)
    if not isDungeon then return false end

    -- A. Godmode / Auto-Heal while in Dungeon (Invincible against Dungeon Bosses & Mobs)
    pcall(function()
        if HPCTRL and HPCTRL.SetCurrentHP and HPCTRL.GetMaxHP then
            local maxHp = HPCTRL.GetMaxHP(LocalPlayer)
            if maxHp and maxHp > 0 then
                HPCTRL.SetCurrentHP(LocalPlayer, maxHp)
            end
        end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
        if LocalPlayer:GetAttribute("Dead") then
            LocalPlayer:SetAttribute("Dead", nil)
            local v2 = CommunicationUtils and CommunicationUtils.TryGetBindableEvent("Stage", "PlayerRebirthBE")
            if v2 then v2:Fire("DungeonDead") end
        end
    end)

    local _, hrp = getCharHrp()
    local playerCF = hrp and hrp.CFrame or CFrame.new(3482, 23, -4)

    -- B. Locate DungeonManager environment and internal state (u144)
    local dmEnv = nil
    pcall(function()
        local dmScript = LocalPlayer.PlayerScripts:FindFirstChild("Manager") and LocalPlayer.PlayerScripts.Manager:FindFirstChild("DungeonManager")
        if dmScript and getsenv then
            dmEnv = getsenv(dmScript)
        end
    end)

    local u144 = nil
    if dmEnv and debug and debug.getupvalues then
        local checkFns = { dmEnv.CheckFinishedOnce, dmEnv.FinishRound, dmEnv.StartRound, dmEnv.ExitDungeon }
        for _, fn in ipairs(checkFns) do
            if type(fn) == "function" then
                pcall(function()
                    local upvals = debug.getupvalues(fn)
                    for _, up in pairs(upvals) do
                        if type(up) == "table" and (rawget(up, "EnemyTab") ~= nil or rawget(up, "Round") ~= nil) then
                            u144 = up
                            break
                        end
                    end
                end)
            end
            if u144 then break end
        end
    end

    -- C. Insta-Kill Dungeon Mobs (Dual Engine: Internal State Table + Workspace Entity Scan)
    if State.DungeonInstaKill then
        -- 1. Eliminate mobs registered in u144.EnemyTab
        if u144 and u144.EnemyTab then
            for uuid, _ in pairs(u144.EnemyTab) do
                pcall(function()
                    if EnemyCTRL then
                        if EnemyCTRL.HurtEnemy then
                            EnemyCTRL.HurtEnemy(uuid, 1e35)
                        end
                        local deadCF = nil
                        if EnemyCTRL.DeadEnemyData then
                            deadCF = EnemyCTRL.DeadEnemyData(uuid)
                        end
                        if deadCF and typeof(deadCF) == "CFrame" then
                            u144.DeadCF = deadCF
                        end
                    end
                    u144.KillNumber = (u144.KillNumber or 0) + 1
                end)
            end
        end

        -- 2. Eliminate physical models in workspace.EnemyFolder
        local enemyFolder = workspace:FindFirstChild("EnemyFolder")
        if enemyFolder then
            for _, enemy in ipairs(enemyFolder:GetChildren()) do
                if enemy:IsA("Model") then
                    local uuid = enemy.Name
                    pcall(function()
                        if Bindable_EnemyHit then
                            Bindable_EnemyHit:Fire(uuid, 1e35)
                        end
                        if EnemyCTRL then
                            if EnemyCTRL.HurtEnemy then
                                EnemyCTRL.HurtEnemy(uuid, 1e35)
                            end
                            local deadCF = nil
                            if EnemyCTRL.DeadEnemyData then
                                deadCF = EnemyCTRL.DeadEnemyData(uuid)
                            end
                            if u144 and deadCF and typeof(deadCF) == "CFrame" then
                                u144.DeadCF = deadCF
                            end
                        end
                        if HPCTRL and HPCTRL.SetCurrentHP then
                            HPCTRL.SetCurrentHP(enemy, 0)
                        end
                        enemy:SetAttribute("Dead", true)
                        local hum = enemy:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                    end)
                end
            end
        end

        -- 3. Ensure DeadCF is always a valid CFrame so RewardUtils.CreateOres never errors
        if u144 then
            if not u144.DeadCF or typeof(u144.DeadCF) ~= "CFrame" then
                u144.DeadCF = playerCF
            end
        end

        -- 4. Advance & finish round immediately
        if dmEnv and u144 and not u144.Finished then
            if dmEnv.FinishRound then
                pcall(function() dmEnv.FinishRound() end)
            elseif dmEnv.CheckFinishedOnce then
                pcall(function() dmEnv.CheckFinishedOnce() end)
            end
        end
    end

    -- D. 30-Round Cap / Target Round Limit (Auto-Exit when Target is completed)
    local maxTarget = math.clamp(tonumber(State.TargetDungeonRound) or 30, 1, 30)
    if u144 and u144.Round and u144.Round >= maxTarget and u144.Finished then
        if dmEnv and dmEnv.ExitDungeon then
            pcall(function() dmEnv.ExitDungeon() end)
        elseif DungeonData and DungeonData.ExitDungeon then
            pcall(function() DungeonData.ExitDungeon() end)
        end
    end

    -- E. Sweep dropped dungeon crystals / ores
    if State.AutoCollectCrystals and collectAllWorldOres then
        pcall(collectAllWorldOres)
    end
    return true
end

-- Rebirth Verification (Uses curRebirth + 1 for correct next-tier level requirement)
local function checkRebirthStatus()
    local pd = ProfileData and ProfileData.GetTotalData()
    local eco = pd and pd.Eco or {}
    local curLevel = tonumber(eco.level) or 0
    local curRebirth = tonumber(eco.rebirth) or 0
    local isMax = false
    if RebirthHelper and RebirthHelper.CheckIsMax then
        pcall(function() isMax = RebirthHelper.CheckIsMax(curRebirth) end)
    end
    local needLevel = 0
    if not isMax and RebirthHelper and RebirthHelper.GetNeedLevel then
        pcall(function() needLevel = RebirthHelper.GetNeedLevel(curRebirth + 1) or 0 end)
    end
    local ready = (not isMax) and (curLevel >= needLevel) and (needLevel > 0)
    return ready, curRebirth, curLevel, needLevel, isMax
end

-- Rarity Level Resolver (Supports Weapons, Armors, Hats, Ores, and Enchant Stones)
local function getRarityLevel(item)
    if not item or not item.ID then return 1, "Common" end
    local idStr = (typeof(item.ID) == "table" and tostring(item.ID.ID or "")) or tostring(item.ID or "")
    local rarity = item.Rarity or "Common"
    if item.Type == "Weapon" and WeaponHelper and WeaponHelper.GetRarity then
        pcall(function() rarity = WeaponHelper.GetRarity(idStr) or rarity end)
    elseif (item.Type == "Armor" or item.Type == "Hat") and ArmorHelper and ArmorHelper.GetRarity then
        pcall(function() rarity = ArmorHelper.GetRarity(idStr) or rarity end)
    elseif item.Type == "Ore" then
        if OreHelper and OreHelper.GetRarity then
            pcall(function() rarity = OreHelper.GetRarity(idStr) or rarity end)
        elseif OreConfig and OreConfig[idStr] and OreConfig[idStr].Rarity then
            rarity = OreConfig[idStr].Rarity
        end
    elseif item.Type == "EnchStone" or idStr:find("Stone") then
        if EnchStoneHelper and EnchStoneHelper.GetRarity then
            pcall(function() rarity = EnchStoneHelper.GetRarity(idStr) or rarity end)
        elseif EnchStoneConfig and EnchStoneConfig[idStr] and EnchStoneConfig[idStr].Rarity then
            rarity = EnchStoneConfig[idStr].Rarity
        elseif StoneHelper and StoneHelper.GetRarity then
            pcall(function() rarity = StoneHelper.GetRarity(idStr) or rarity end)
        elseif StoneConfig and StoneConfig[idStr] and StoneConfig[idStr].Rarity then
            rarity = StoneConfig[idStr].Rarity
        elseif EnchantHelper and EnchantHelper.GetRarity then
            pcall(function() rarity = EnchantHelper.GetRarity(idStr) or rarity end)
        elseif EnchantConfig and EnchantConfig[idStr] and EnchantConfig[idStr].Rarity then
            rarity = EnchantConfig[idStr].Rarity
        end
    end

    if item.Rarity and (rarity == "Common" or not rarity) then
        rarity = item.Rarity
    end

    -- Universal string matching fallback for stone and gear IDs
    if (rarity == "Common" or not rarity) and #idStr > 0 then
        for _, rName in ipairs({"Infinite", "Ancient", "Secret", "Eternal", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}) do
            if idStr:lower():find(rName:lower(), 1, true) then
                rarity = rName
                break
            end
        end
    end

    local lvl = 1
    if RarityHelper and RarityHelper.GetRarityLevel then
        pcall(function() lvl = RarityHelper.GetRarityLevel(rarity) or 1 end)
    else
        local defaultLevels = {
            Common = 1, Uncommon = 2, UnCommon = 2, Rare = 3, Epic = 4,
            Legendary = 5, Mythic = 6, Secret = 7, Eternal = 8, Ancient = 9, Infinite = 10
        }
        lvl = defaultLevels[rarity] or 1
    end
    return lvl, rarity
end

local RarityThresholds = {
    ["Infinite เท่านั้น (Keep Infinite Only)"]     = 10,
    ["Ancient ขึ้นไป (Keep Ancient+)"]            = 9,
    ["Secret ขึ้นไป (Keep Secret+)"]              = 8,
    ["Eternal ขึ้นไป (Keep Eternal+)"]             = 7,
    ["Mythic ขึ้นไป (Keep Mythic+)"]             = 6,
    ["Legendary ขึ้นไป (Keep Legendary+)"]       = 5,
    ["Epic ขึ้นไป (Keep Epic+)"]                 = 4,
    ["Rare ขึ้นไป (Keep Rare+)"]                 = 3,
    ["Uncommon ขึ้นไป (Keep Uncommon+)"]         = 2,
    ["ขายทั้งหมดที่ไม่ใส่ (Sell All Non-Equipped)"] = 999,
    ["เก็บทั้งหมด (Keep All - ไม่ขายเกียร์)"]       = 0,
}

-- Best Gear Power Scoring Helper (Rarity Level + Design Power + Affix + Enhancement)
local function calculateGearScore(item)
    if not item or not item.ID then return 0 end
    local basePower = 0
    if item.Type == "Weapon" and WeaponHelper and WeaponHelper.GetDesignPower then
        pcall(function() basePower = WeaponHelper.GetDesignPower(item.ID) or 0 end)
    elseif (item.Type == "Armor" or item.Type == "Hat") and ArmorHelper and ArmorHelper.GetDesignPower then
        pcall(function() basePower = ArmorHelper.GetDesignPower(item.ID) or 0 end)
    end
    local rarityLevel, _ = getRarityLevel(item)
    local affixNum = (item.MainAffix and tonumber(item.MainAffix.Number)) or 0
    local enhance = tonumber(item.EnchanceNum) or 0
    return (rarityLevel * 1000000000000) + (basePower * 1000000000) + affixNum + (enhance * 10)
end

-- Best Gear Equip Scanner (Safe & Synchronous across Weapon, Armor, Hat)
local function equipBestGearNow(targetType)
    if not BackpackData or not Remote_TryEquip then return false, 0 end
    local bp = BackpackData.GetData()
    if not bp or not bp.have then return false, 0 end

    local targets = {}
    if targetType == "All" or targetType == "ฟูลเซ็ต" or not targetType then
        targets = { "Weapon", "Armor", "Hat" }
    elseif string.find(targetType, "Weapon") or string.find(targetType, "ดาบ") or string.find(targetType, "อาวุธ") then
        targets = { "Weapon" }
    elseif string.find(targetType, "Armor") or string.find(targetType, "เกราะ") then
        targets = { "Armor" }
    elseif string.find(targetType, "Hat") or string.find(targetType, "หมวก") then
        targets = { "Hat" }
    else
        targets = { targetType }
    end

    local equippedAny = false
    local lastPower = 0
    for _, slotType in ipairs(targets) do
        local bestUuid = nil
        local bestScore = -1
        for uuid, item in pairs(bp.have) do
            if item.Type == slotType then
                local score = calculateGearScore(item)
                if score > bestScore then
                    bestScore = score
                    bestUuid = uuid
                end
            end
        end

        if bestUuid then
            pcall(function()
                Remote_TryEquip:FireServer(bestUuid, slotType)
            end)
            equippedAny = true
            lastPower = bestScore
        end
    end

    return equippedAny, lastPower
end

-- Core Auto Forge Execution with Smart Ore Slicing & 3-Slot Support
local forgeCycleIndex = 1
local function executeForgeNow(forgeType, minOres)
    forgeType = forgeType or State.ForgeType or "All"
    minOres = minOres or State.MinOreToForge or 4
    if not BackpackData or not Remote_Forge then return false, "No remote" end

    local bp = BackpackData.GetData()
    if not bp or not bp.have then return false, "No backpack data" end

    -- Count total available ores
    local totalOres = 0
    for _, item in pairs(bp.have) do
        if item.Type == "Ore" then
            totalOres = totalOres + (item.Number or 1)
        end
    end

    if totalOres < 4 then
        return false, "Not enough ores (need at least 4)"
    end

    -- Determine slot and target ore count
    local isRotate = string.find(forgeType, "All") or string.find(forgeType, "หมุนเวียน")
    local actualSlot = "Weapon"

    if isRotate then
        local cycleSlots = { "Weapon", "Armor", "Hat" }
        actualSlot = cycleSlots[((forgeCycleIndex - 1) % #cycleSlots) + 1]
    elseif string.find(forgeType, "Hat") or string.find(forgeType, "หมวก") then
        actualSlot = "Hat"
    elseif string.find(forgeType, "Armor") or string.find(forgeType, "เกราะ") then
        actualSlot = "Armor"
    else
        actualSlot = "Weapon"
    end

    local serverConfigType = "Weapon"
    local targetOreCount = 4

    if actualSlot == "Weapon" then
        serverConfigType = "Weapon"
        -- Weapon config: min 4, max 13 (13 ores = 100% Greatsword)
        targetOreCount = math.clamp(totalOres, 4, 13)
        if minOres and minOres > 4 then
            targetOreCount = math.clamp(minOres, 4, math.min(totalOres, 13))
        end
    elseif actualSlot == "Hat" then
        serverConfigType = "Armor"
        -- Hat config: 4 ores = 100% Hat_Light, 16 ores = 80% Hat_Heave
        if totalOres >= 16 and (minOres or 0) >= 16 then
            targetOreCount = 16
        else
            targetOreCount = 4
        end
    elseif actualSlot == "Armor" then
        serverConfigType = "Armor"
        -- Armor config: 23 ores = 100% Armor_Heave, 11 ores = 80% Armor_Light, 8-10 ores = 50-70% Armor_Light
        if totalOres < 8 then
            if not isRotate then
                targetOreCount = math.clamp(totalOres, 4, 23)
            else
                -- In rotation, if less than 8 ores, fallback to guaranteed Hat (4 ores)
                actualSlot = "Hat"
                serverConfigType = "Armor"
                targetOreCount = 4
            end
        else
            if totalOres >= 23 and (minOres or 0) >= 20 then
                targetOreCount = 23
            elseif totalOres >= 11 then
                targetOreCount = 11
            else
                targetOreCount = math.clamp(totalOres, 8, 11)
            end
        end
    end

    if totalOres < targetOreCount then
        return false, "Ores insufficient for " .. actualSlot .. " (need " .. targetOreCount .. ")"
    end

    -- Build ore slice table with quality sorting
    local oreEntries = {}
    for uuid, item in pairs(bp.have) do
        if item.Type == "Ore" then
            local pwr = 0
            if OreHelper and OreHelper.GetPower then
                pcall(function() pwr = OreHelper.GetPower(item.ID) or 0 end)
            end
            table.insert(oreEntries, { uuid = uuid, count = item.Number or 1, power = pwr })
        end
    end

    if State.OreQualityMode == "ใช้แร่เกรดสูงสุดก่อน (Best Ores First)" then
        table.sort(oreEntries, function(a, b) return a.power > b.power end)
    elseif State.OreQualityMode == "ใช้แร่เกรดต่ำสุดก่อน (Low Ores First)" then
        table.sort(oreEntries, function(a, b) return a.power < b.power end)
    end

    local oreList = {}
    local collected = 0
    for _, entry in ipairs(oreEntries) do
        local needed = targetOreCount - collected
        local take = math.min(entry.count, needed)
        if take > 0 then
            oreList[entry.uuid] = take
            collected = collected + take
        end
        if collected >= targetOreCount then break end
    end

    if collected < targetOreCount then
        return false, "Failed to slice sufficient ores"
    end

    local ok, res = pcall(function()
        return Remote_Forge:InvokeServer({
            ConfigType = serverConfigType,
            UUIDList = oreList
        })
    end)

    if ok and res then
        if isRotate then
            forgeCycleIndex = forgeCycleIndex + 1
        end
        -- Auto equip the newly forged category and confirm best full set
        task.delay(0.2, function()
            equipBestGearNow(actualSlot)
            task.wait(0.1)
            equipBestGearNow("All")
        end)
        return true, actualSlot, collected
    end

    return false, "Forge remote invoke failed"
end

-- Intelligent Trash Gear Selling with Rarity Retain Filter (Strictly Gear Only - Ores Untouched)
local function sellTrashGearNow()
    if not BackpackData then return 0 end
    local bp = BackpackData.GetData()
    if not bp or not bp.have then return 0 end

    -- Always equip full best gear first if enabled!
    if State.AutoEquipBest then
        equipBestGearNow("All")
        task.wait(0.1)
    end

    local keepThreshold = RarityThresholds[State.MinRarityToKeep] or 5
    if keepThreshold == 0 then return 0 end -- Keep all!

    local soldCount = 0
    -- Iterate strictly over Weapon, Armor, Hat (Never touches Ores/Materials/Stones):
    for uuid, item in pairs(bp.have) do
        if item.Type == "Weapon" or item.Type == "Armor" or item.Type == "Hat" then
            local isEquipped = false
            if BackpackData.IsEquipedUUID then
                pcall(function() isEquipped = BackpackData.IsEquipedUUID(uuid) end)
            end
            if not isEquipped then
                local lvl, _ = getRarityLevel(item)
                if lvl < keepThreshold then
                    -- Server requires 2 arguments: (uuid, quantity)
                    if Remote_TrySellItem then
                        pcall(function() Remote_TrySellItem:FireServer(uuid, 1) end)
                    elseif BackpackData.TrySellItem then
                        pcall(function() BackpackData.TrySellItem(uuid, 1) end)
                    end
                    soldCount = soldCount + 1
                    task.wait(0.02)
                end
            end
        end
    end
    return soldCount
end

-- Independent Auto Sell Ores with Mode & Multi-Select Filter (ขายแร่อิสระ ไม่แตะหินตีบวกหรืออุปกรณ์)
local function sellOresNow()
    if not BackpackData then return 0 end
    local bp = BackpackData.GetData()
    if not bp or not bp.have then return 0 end

    local selectedList = normalizeMultiSelection(State.OreRaritiesToKeep)
    local selectedMap = {}
    for _, k in ipairs(selectedList) do
        local clean = tostring(k):lower():gsub("[^%a]", "")
        if #clean > 0 then
            selectedMap[clean] = true
        end
    end

    local isKeepMode = false
    if State.OreFilterMode and State.OreFilterMode:find("เก็บ") then
        isKeepMode = true -- Keep Selected Mode
    end

    local soldCount = 0
    for uuid, item in pairs(bp.have) do
        local rawId = item.ID
        local idStr = (typeof(rawId) == "table" and tostring(rawId.ID or "")) or tostring(rawId or "")

        -- Strictly genuine ores only: Type == "Ore" and id starts with "Ore_" and not an EnhantStone material
        if item.Type == "Ore" and idStr:find("^Ore_") and not idStr:find("EnhantStone") and not idStr:find("Stone") then
            local lvl, rarityName = getRarityLevel(item)
            local cleanR = tostring(rarityName or "Common"):lower():gsub("[^%a]", "")

            local shouldSell = false
            if isKeepMode then
                -- Keep Mode: Sell if NOT in selected keep list
                shouldSell = (selectedMap[cleanR] ~= true)
            else
                -- Sell Selected Mode: Sell if IN selected list
                shouldSell = (selectedMap[cleanR] == true)
            end

            if shouldSell then
                local num = tonumber(item.Number) or 9999
                local ok = false
                if BackpackData.TrySellItem then
                    ok = pcall(function() BackpackData.TrySellItem(uuid, num) end)
                elseif Remote_TrySellItem then
                    ok = pcall(function() Remote_TrySellItem:FireServer(uuid, num) end)
                end
                if ok then
                    soldCount = soldCount + 1
                    task.wait(0.03)
                end
            end
        end
    end
    return soldCount
end

-- Sell All Ores regardless of rarity (ขายแร่ทุกชนิดเกลี้ยงกระเป๋า)
local function sellAllOresNow()
    if not BackpackData then return 0 end
    local bp = BackpackData.GetData()
    if not bp or not bp.have then return 0 end

    local soldCount = 0
    for uuid, item in pairs(bp.have) do
        local rawId = item.ID
        local idStr = (typeof(rawId) == "table" and tostring(rawId.ID or "")) or tostring(rawId or "")
        if item.Type == "Ore" and idStr:find("^Ore_") and not idStr:find("EnhantStone") and not idStr:find("Stone") then
            local num = tonumber(item.Number) or 9999
            local ok = false
            if BackpackData.TrySellItem then
                ok = pcall(function() BackpackData.TrySellItem(uuid, num) end)
            elseif Remote_TrySellItem then
                ok = pcall(function() Remote_TrySellItem:FireServer(uuid, num) end)
            end
            if ok then
                soldCount = soldCount + 1
                task.wait(0.03)
            end
        end
    end
    return soldCount
end

-- Independent Auto Sell Enchant Stones with Mode & Multi-Select Rarity Filter (ขายหินตีบวกอิสระ ไม่แตะอาวุธ/แร่)
local function sellEnchantStonesNow()
    if not BackpackData then return 0 end
    local bp = BackpackData.GetData()
    if not bp or not bp.have then return 0 end

    local selectedList = normalizeMultiSelection(State.EnchantRarities)
    local selectedMap = {}
    for _, k in ipairs(selectedList) do
        local clean = tostring(k):lower():gsub("[^%a]", "")
        if #clean > 0 then
            selectedMap[clean] = true
        end
    end

    local isSellSelected = true
    if State.EnchantFilterMode and State.EnchantFilterMode:find("เก็บ") then
        isSellSelected = false -- Keep Selected Mode
    end

    local soldCount = 0
    for uuid, item in pairs(bp.have) do
        local isEnchStone = (item.Type == "EnchStone") or (item.ID and item.ID:find("Stone"))
        if isEnchStone then
            local lvl, rarityName = getRarityLevel(item)
            local cleanR = tostring(rarityName or "Common"):lower():gsub("[^%a]", "")

            local isSelected = (selectedMap[cleanR] == true)
            local shouldSell = false

            if isSellSelected then
                -- Sell Selected Mode: If this rarity is in selected list, SELL IT
                shouldSell = isSelected
            else
                -- Keep Selected Mode: If this rarity is in selected list, KEEP IT (sell if not selected)
                shouldSell = not isSelected
            end

            if shouldSell then
                local num = tonumber(item.Number) or tonumber(item.Count) or 1
                -- Server requires 2 arguments: (uuid, quantity)
                if Remote_TrySellItem then
                    pcall(function() Remote_TrySellItem:FireServer(uuid, num) end)
                elseif BackpackData.TrySellItem then
                    pcall(function() BackpackData.TrySellItem(uuid, num) end)
                end
                soldCount = soldCount + 1
                task.wait(0.02)
            end
        end
    end
    return soldCount
end

-- Collect Dropped Crystals / Ores in Workspace (Universal Map-Wide Sweep)
collectAllWorldOres = function()
    local count = 0
    local oreCache = workspace:FindFirstChild("OreCache")
    if oreCache then
        for _, ore in ipairs(oreCache:GetChildren()) do
            local prompt = ore:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function()
                    prompt.MaxActivationDistance = 99999
                    prompt.RequiresLineOfSight = false
                end)
                if fireproximityprompt then
                    pcall(function() fireproximityprompt(prompt, 0) end)
                else
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(0.05)
                        prompt:InputHoldEnd()
                    end)
                end
                count = count + 1
            end
        end
    end
    return count
end

-- Auto Enchant Equipped Gear (Weapons, Armor, Hats)
local function autoEnchantEquippedGear()
    if not BackpackData then return false end
    local bp = BackpackData.GetData()
    if not bp or not bp.have then return false end

    -- 1. Gather all available enchantment stones in inventory
    local stones = {}
    for uuid, item in pairs(bp.have) do
        if item.Type == "EnchStone" or (item.ID and item.ID:find("Stone")) then
            local count = item.Number or item.Count or 1
            for i = 1, count do
                table.insert(stones, uuid)
            end
        end
    end

    if #stones == 0 then return false end

    -- 2. Find equipped items that have open enchantment slots
    local stoneIdx = 1
    local enchantedCount = 0

    for uuid, item in pairs(bp.have) do
        if BackpackData.IsEquipedUUID and BackpackData.IsEquipedUUID(uuid) then
            local maxSlots = item.EnchanceNum or 0
            if maxSlots > 0 then
                local currentList = item.EnchanceList or {}
                local usedSlots = 0
                for _, s in ipairs(currentList) do
                    if s and (s.ID or s.id or s.Name) and (s.ID ~= "" and s.id ~= "") then
                        usedSlots = usedSlots + 1
                    end
                end

                local emptySlots = maxSlots - usedSlots
                while emptySlots > 0 and stoneIdx <= #stones do
                    local stoneUuid = stones[stoneIdx]
                    stoneIdx = stoneIdx + 1
                    pcall(function()
                        if BackpackData.EnchantEquipment then
                            BackpackData.EnchantEquipment(uuid, stoneUuid)
                        elseif Remote_Enchant then
                            Remote_Enchant:FireServer(uuid, stoneUuid)
                        end
                    end)
                    enchantedCount = enchantedCount + 1
                    emptySlots = emptySlots - 1
                    task.wait(0.2)
                end
            end
        end
        if stoneIdx > #stones then break end
    end

    return enchantedCount > 0
end

-- Auto Drink Multiplier Buff Potions (Zero-Waste, Check Active Buffs)
local function autoDrinkPotionsNow()
    local usedAny = false
    local potList = {
        { id = "TrainPotion", buff = "Train_1", enabled = State.AutoTrainPotion },
        { id = "CoinPotion", buff = "Coin_1", enabled = State.AutoCoinPotion },
        { id = "LuckPotion", buff = "Luck_1", enabled = State.AutoLuckPotion },
        { id = "DamagePotion", buff = "Damage_1", enabled = State.AutoDamagePotion },
        { id = "HPPotion", buff = "HP_1", enabled = State.AutoHPPotion },
    }

    local pData = PotionData and PotionData.GetData and PotionData.GetData()
    for _, pot in ipairs(potList) do
        if pot.enabled and (State.AutoBuffPotions or pot.enabled) then
            local hasBuff = false
            if BuffData and BuffData.IsHaveBuff then
                hasBuff = BuffData.IsHaveBuff(pot.buff) or (BuffData.GetBuffLastTime and BuffData.GetBuffLastTime(pot.buff) > 0)
            end

            if not hasBuff then
                local count = pData and pData[pot.id] or 0
                if count > 0 then
                    pcall(function()
                        if PotionData and PotionData.UsePotion then
                            PotionData.UsePotion(pot.id)
                        elseif Remote_TryUsePotion then
                            Remote_TryUsePotion:FireServer(pot.id)
                        end
                    end)
                    usedAny = true
                    task.wait(0.15)
                end
            end
        end
    end
    return usedAny
end

-- Auto Roll Class with Target Rarity Stop Lock
local function autoRollClassNow()
    if not ClassData or not Remote_LuckOnce then return false end
    local tickets = (ClassData.GetLuckTimes and ClassData.GetLuckTimes()) or 0
    if tickets <= 0 then return false end

    -- Check current class
    local curClassId = ClassData.GetEquipedClass and ClassData.GetEquipedClass()
    local curRarity = "Common"
    if ClassConfig and curClassId and ClassConfig[curClassId] then
        curRarity = ClassConfig[curClassId].Rarity or "Common"
    end

    local rarityWeight = {
        ["Common"] = 1,
        ["UnCommon"] = 2,
        ["Rare"] = 3,
        ["Epic"] = 4,
        ["Legendary"] = 5,
        ["Mythic"] = 6
    }

    local targetWeight = 5 -- Default: Legendary+
    if State.TargetClassRarity and State.TargetClassRarity:find("Mythic") then
        targetWeight = 6
    elseif State.TargetClassRarity and State.TargetClassRarity:find("Epic") then
        targetWeight = 4
    end

    local curWeight = rarityWeight[curRarity] or 1
    if curWeight >= targetWeight then
        -- Target reached! Stop rolling.
        State.AutoRollClass = false
        if UIControls.AutoRollClass then
            pcall(function()
                if UIControls.AutoRollClass.SetValue then UIControls.AutoRollClass:SetValue(false)
                elseif UIControls.AutoRollClass.Set then UIControls.AutoRollClass:Set(false) end
            end)
        end
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Class",
                Content = "สุ่มได้คลาสระดับ " .. tostring(curRarity) .. " แล้ว! หยุดสุ่มอัตโนมัติเพื่อเซฟตั๋ว"
            })
        end
        return false
    end

    -- Fire roll
    pcall(function()
        Remote_LuckOnce:FireServer()
    end)
    return true
end

-- Full Palette Theme Presets
local ThemePresets = {
    ["2SKI Cyber Cyan (ธีมหลักทางการ - ขาว ฟ้าเรืองแสง Electric Blue)"] = {
        WindTheme = "Sky",
        Hex = "#00BFFF",
        C1 = Color3.fromRGB(248, 251, 255),
        C2 = Color3.fromRGB(125, 235, 255),
        C3 = Color3.fromRGB(0, 191, 255),
        C4 = Color3.fromRGB(0, 140, 255),
        Glow = Color3.fromRGB(0, 140, 255),
        GlowTransparency = 0.55
    },
    ["Tiffany Pastel Mint (สีเขียวมิ้นท์พาสเทล)"] = { WindTheme = "Tiffany", Hex = "#00FFE0", C1 = Color3.fromRGB(0,255,224), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(80,230,210), Glow = Color3.fromRGB(0,255,224), GlowTransparency = 0.55 },
    ["Sky Blue Glow (ฟ้านีออนสว่าง)"]            = { WindTheme = "Sky",     Hex = "#00D0FF", C1 = Color3.fromRGB(0,208,255), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(100,225,255), Glow = Color3.fromRGB(0,208,255), GlowTransparency = 0.55 },
    ["Neon Emerald (เขียวมรกตนีออน)"]             = { WindTheme = "Emerald", Hex = "#00FF99", C1 = Color3.fromRGB(0,255,153), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(90,255,180), Glow = Color3.fromRGB(0,255,153), GlowTransparency = 0.55 },
    ["Cyber Violet (ม่วงไซเบอร์)"]                = { WindTheme = "Purple",  Hex = "#C866FF", C1 = Color3.fromRGB(200,102,255), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(220,160,255), Glow = Color3.fromRGB(200,102,255), GlowTransparency = 0.55 },
    ["Neon Rose (ชมพูกุหลาบไฟ)"]                = { WindTheme = "Rose",    Hex = "#FF3377", C1 = Color3.fromRGB(255,51,119), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(255,140,180), Glow = Color3.fromRGB(255,51,119), GlowTransparency = 0.55 },
    ["Golden Amber (ทองอำพันพรีเมียม)"]           = { WindTheme = "Amber",   Hex = "#FFB700", C1 = Color3.fromRGB(255,183,0), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(255,215,100), Glow = Color3.fromRGB(255,183,0), GlowTransparency = 0.55 },
    ["Electric Blue (น้ำเงินสดใส)"]               = { WindTheme = "Blue",    Hex = "#3D8EFF", C1 = Color3.fromRGB(61,142,255), C2 = Color3.fromRGB(255,255,255), C3 = Color3.fromRGB(140,190,255), Glow = Color3.fromRGB(61,142,255), GlowTransparency = 0.55 }
}

-- Cleanup Function
_G.TwoSkiCleanup = function()
    _G.TwoSkiRunning = false
    _G.TwoSkiLoaded = false
    if manualFlyCon then pcall(function() manualFlyCon:Disconnect() end) end
    if manualFlyBv then pcall(function() manualFlyBv:Destroy() end) end
    if manualFlyBg then pcall(function() manualFlyBg:Destroy() end) end
    if noclipCon then pcall(function() noclipCon:Disconnect() end) end
    local _, _, hum = getCharHrp()
    if hum then hum.PlatformStand = false end
    for _, c in ipairs(Connections) do
        if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
    end
    safeDestroyGui("TwoSki_LootToForge_Floating")
    safeDestroyGui("WindUI")
    safeDestroyGui("TwoK_UI_Screen")
    safeDestroyGui("TwoK_Pyramid_Float")
    safeDestroyGui("TwoK_BlackScreen_Saver")
    if _G.TwoSkiWindUI then
        pcall(function()
            if _G.TwoSkiWindUI.Window and _G.TwoSkiWindUI.Window.Destroy then
                _G.TwoSkiWindUI.Window:Destroy()
            end
        end)
        _G.TwoSkiWindUI.Window = nil
        pcall(function()
            if _G.TwoSkiWindUI.ScreenGui then
                _G.TwoSkiWindUI.ScreenGui:Destroy()
            end
        end)
        _G.TwoSkiWindUI.ScreenGui = nil
    end
    if WindUI and WindUI.Window and WindUI.Window.Destroy then
        pcall(function() WindUI.Window:Destroy() end)
        WindUI.Window = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ── 2K CYBER-NEON OBSIDIAN UI ENGINE (100% EMBEDDED SINGLE-FILE ARCHITECTURE) ──
-- ══════════════════════════════════════════════════════════════════════════════
local TwoKUI = (function()
--[=[
    ██████╗ ██╗  ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗
    ╚════██╗██║ ██╔╝    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
     █████╔╝█████╔╝     ███████╗██║     ██████╔╝██║██████╔╝   ██║   
    ██╔═══╝ ██╔═██╗     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   
    ███████╗██║  ██╗    ███████║╚██████╗██║  ██║██║██║        ██║   
    ╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
    
    TwoKUI Engine — Proprietary Cyber-Neon UI Framework
    Designed exclusively for 2K SCRIPT. Built from scratch.
    Zero third-party bloat • 100% Custom Architecture
]=]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local TwoKUI = {
    Version = "2.0.0-CYBER",
    Windows = {},
    ActiveWindow = nil
}

local setThreadIdentity = setthreadidentity or setidentity or (syn and syn.set_thread_identity)

-- Safe GUI Container Resolver
local function getGuiContainer()
    if setThreadIdentity then pcall(setThreadIdentity, 8) end
    local env = (getgenv and getgenv()) or _G
    if env.gethui then
        local ok, h = pcall(env.gethui)
        if ok and h and typeof(h) == "Instance" and h.Name ~= "RobloxGui" then return h end
    end
    if CoreGui then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui", 10)
end

-- Built-in Verified Icon Map (Lucide & Cyber Asset IDs from TwoKIcons)
local ICON_MAP = {
    ["layout-dashboard"] = "rbxassetid://10723424646",
    ["mountain"]         = "rbxassetid://10734897956",
    ["dumbbell"]         = "rbxassetid://10747363809",
    ["zap"]              = "rbxassetid://10723376114",
    ["user"]             = "rbxassetid://10747373176",
    ["map-pin"]          = "rbxassetid://10734886004",
    ["settings"]         = "rbxassetid://10734950309",
    ["activity"]         = "rbxassetid://10709752035",
    ["chart-column"]     = "rbxassetid://10709773755",
    ["sliders-horizontal"] = "rbxassetid://10734963191",
    ["circle-plus"]      = "rbxassetid://10734923868",
    ["chevrons-up"]      = "rbxassetid://10709797622",
    ["maximize-2"]       = "rbxassetid://10734886496",
    ["clock"]            = "rbxassetid://10709805144",
    ["gift"]             = "rbxassetid://10723396402",
    ["ticket"]           = "rbxassetid://10734983868",
    ["gauge"]            = "rbxassetid://10723395708",
    ["wind"]             = "rbxassetid://10747382750",
    ["arrow-up"]         = "rbxassetid://10709768939",
    ["chevron-up"]       = "rbxassetid://10709791523",
    ["ghost"]            = "rbxassetid://10723396107",
    ["shield-check"]     = "rbxassetid://10734951367",
    ["shield-alert"]     = "rbxassetid://10734951173",
    ["navigation"]       = "rbxassetid://10734906744",
    ["hammer"]           = "rbxassetid://10723405360",
    ["layers"]           = "rbxassetid://10723424505",
    ["house"]            = "rbxassetid://10723407389",
    ["crown"]            = "rbxassetid://10709818626",
    ["circle-arrow-up"]  = "rbxassetid://10709768432",
    ["award"]            = "rbxassetid://10709769406",
    ["palette"]          = "rbxassetid://10734910430",
    ["paint-bucket"]     = "rbxassetid://10734909847",
    ["cpu"]              = "rbxassetid://10709813383",
    ["refresh-cw"]       = "rbxassetid://10734933222",
    ["power"]            = "rbxassetid://10734930466",
    ["swords"]           = "rbxassetid://10734975692",
    ["sword"]            = "rbxassetid://10734975486",
    ["coins"]            = "rbxassetid://10709811110",
    ["package"]          = "rbxassetid://10734909540",
    ["download"]         = "rbxassetid://10723344270",
    ["upload"]           = "rbxassetid://10747366434",
    ["fast-forward"]     = "rbxassetid://10723354521",
    ["sparkles"]         = "rbxassetid://10734966248",
    ["square"]           = "rbxassetid://10734965702",
    ["box"]              = "rbxassetid://10709782497",
    ["flag"]             = "rbxassetid://10723375890",
    ["footprints"]       = "rbxassetid://10723395708",
    ["map"]              = "rbxassetid://10734886202",
    ["octagon-x"]        = "rbxassetid://10747384037",
    ["pencil"]           = "rbxassetid://10734919691",
    ["repeat"]           = "rbxassetid://10734933966",
    ["trending-up"]      = "rbxassetid://10747363465",
    ["unlock"]           = "rbxassetid://10747366027"
}

local TwoKIcons = nil
pcall(function()
    if isfile and isfile("TwoKIcons.luau") and readfile then
        local fn = (loadstring or load)(readfile("TwoKIcons.luau"))
        if fn then TwoKIcons = fn() end
    end
    if not TwoKIcons and game and game.HttpGet then
        local okH, raw = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/TwoKIcons.luau")
        if okH and raw and #raw > 100 then
            local fn = (loadstring or load)(raw)
            if fn then TwoKIcons = fn() end
        end
    end
end)

local function resolveIcon(name)
    if not name or name == "" then return "rbxassetid://10709752035" end
    if string.find(name, "rbxasset") then return name end
    if ICON_MAP[name] then return ICON_MAP[name] end
    if TwoKIcons and TwoKIcons.assets then
        local k1 = "lucide-" .. name
        if TwoKIcons.assets[k1] then return TwoKIcons.assets[k1] end
        if TwoKIcons.assets[name] then return TwoKIcons.assets[name] end
    end
    return "rbxassetid://10709752035"
end

-- Helper: Ensure local image asset
local function ensureAsset(filename, url)
    if not (isfile and writefile and getcustomasset) then return nil end
    pcall(function()
        if not isfile(filename) then
            local req = (syn and syn.request) or (http and http.request) or http_request or request
            if req and url then
                local res = req({ Url = url, Method = "GET" })
                if res and res.Body and #res.Body > 500 then
                    writefile(filename, res.Body)
                end
            end
        end
    end)
    if isfile and isfile(filename) then
        local ok, asset = pcall(getcustomasset, filename)
        if ok and asset then return asset end
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────
-- WINDOW BUILDER
-- ─────────────────────────────────────────────────────────────
function TwoKUI:CreateWindow(config)
    config = config or {}
    local Title = config.Title or "2K SCRIPT"
    local SubTitle = config.SubTitle or "ROBLOX SCRIPT EXECUTOR & TOOLS"
    local Keybind = config.Keybind or Enum.KeyCode.LeftControl
    local Size = config.Size or UDim2.fromOffset(880, 520)
    
    local container = getGuiContainer()
    
    -- Cleanup any existing instance across all possible containers
    local cleanupContainers = { container, CoreGui }
    pcall(function()
        if CoreGui and CoreGui:FindFirstChild("RobloxGui") then
            table.insert(cleanupContainers, CoreGui.RobloxGui)
        end
    end)
    pcall(function()
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            table.insert(cleanupContainers, LocalPlayer.PlayerGui)
        end
    end)
    for _, par in ipairs(cleanupContainers) do
        if par then
            for _, c in ipairs(par:GetChildren()) do
                if c.Name == "TwoK_UI_Screen" or c.Name == "TwoK_Pyramid_Float" then
                    pcall(function() c:Destroy() end)
                end
            end
        end
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TwoK_UI_Screen"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = container

    -- Outer Window Frame (Draggable)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Size = Size
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromHex("#030712")
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- ── Adaptive Responsive Scaling for Mobile (Delta, Android, iOS, Tablets) ──
    local windowScale = Instance.new("UIScale")
    windowScale.Name = "WindowScale"
    windowScale.Parent = mainFrame

    local function updateAdaptiveScale()
        if _G.TwoSkiCustomScale and _G.TwoSkiCustomScale > 0 then
            windowScale.Scale = math.clamp(_G.TwoSkiCustomScale, 0.40, 1.25)
            return
        end

        local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
        local screenW = vp.X
        local screenH = vp.Y
        
        local baseW = 880
        local baseH = 520
        
        if isMobile then
            local scaleRatio = math.min((screenW * 0.85) / baseW, (screenH * 0.85) / baseH)
            windowScale.Scale = math.clamp(scaleRatio, 0.50, 0.85)
        else
            windowScale.Scale = 1.00
        end
    end

    updateAdaptiveScale()
    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAdaptiveScale)
    end

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = mainFrame

    -- Cyber Neon Animated Outer Stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromHex("#00E5FF")
    mainStroke.Thickness = 2.0
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHex("#00E5FF")),
        ColorSequenceKeypoint.new(0.30, Color3.fromHex("#0077FE")),
        ColorSequenceKeypoint.new(0.65, Color3.fromHex("#38BDF8")),
        ColorSequenceKeypoint.new(1.00, Color3.fromHex("#00E5FF"))
    })
    strokeGrad.Parent = mainStroke

    -- Aesthetic Anime Sky Background Art Overlay
    local bgImage = Instance.new("ImageLabel")
    bgImage.Name = "BackgroundArt"
    bgImage.Size = UDim2.fromScale(1, 1)
    bgImage.Position = UDim2.fromScale(0, 0)
    bgImage.BackgroundTransparency = 1
    bgImage.ScaleType = Enum.ScaleType.Crop
    bgImage.ImageTransparency = 0.12
    bgImage.ZIndex = 1
    bgImage.Parent = mainFrame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 20)
    bgCorner.Parent = bgImage

    task.spawn(function()
        local artAsset = ensureAsset("2k_bg_art_v4.png", "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/assets/2k_bg_art_v4.png")
        if not artAsset then
            artAsset = ensureAsset("2k_bg_art_v3.png", "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/assets/2k_bg_art_v3.png")
        end
        if not artAsset then
            artAsset = ensureAsset("2k_bg_art.png", "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/assets/2k_bg_art.png")
        end
        if artAsset then
            bgImage.Image = artAsset
        end
    end)

    -- Soft Radial / Linear Dark Tint Overlay for Legibility
    local tintOverlay = Instance.new("Frame")
    tintOverlay.Name = "TintOverlay"
    tintOverlay.Size = UDim2.fromScale(1, 1)
    tintOverlay.BackgroundColor3 = Color3.fromHex("#020610")
    tintOverlay.BackgroundTransparency = 0.55
    tintOverlay.BorderSizePixel = 0
    tintOverlay.ZIndex = 2
    tintOverlay.Parent = mainFrame

    local tintCorner = Instance.new("UICorner")
    tintCorner.CornerRadius = UDim.new(0, 20)
    tintCorner.Parent = tintOverlay

    -- ─────────────────────────────────────────────────────────
    -- TOPBAR (2K Starburst Logo + Title + Controls)
    -- ─────────────────────────────────────────────────────────
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 54)
    topbar.BackgroundTransparency = 1
    topbar.BorderSizePixel = 0
    topbar.ZIndex = 5
    topbar.Parent = mainFrame

    local topbarLine = Instance.new("Frame")
    topbarLine.Name = "Divider"
    topbarLine.Size = UDim2.new(1, 0, 0, 1)
    topbarLine.Position = UDim2.new(0, 0, 1, -1)
    topbarLine.BackgroundColor3 = Color3.fromHex("#00E5FF")
    topbarLine.BackgroundTransparency = 0.75
    topbarLine.BorderSizePixel = 0
    topbarLine.Parent = topbar

    -- 2K Starburst Logo & Brand (Clean Top-Left)
    local brandContainer = Instance.new("Frame")
    brandContainer.Name = "BrandContainer"
    brandContainer.Size = UDim2.new(0, 280, 1, 0)
    brandContainer.Position = UDim2.new(0, 18, 0, 0)
    brandContainer.BackgroundTransparency = 1
    brandContainer.Parent = topbar

    local logoImg = Instance.new("ImageLabel")
    logoImg.Name = "Logo"
    logoImg.Size = UDim2.fromOffset(34, 34)
    logoImg.Position = UDim2.new(0, 0, 0.5, -17)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = "rbxassetid://10723346959"
    logoImg.ImageColor3 = Color3.fromHex("#00E5FF")
    logoImg.Parent = brandContainer

    task.spawn(function()
        local logoAsset = ensureAsset("2k_logo.png", "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/assets/2k_logo.png")
        if logoAsset then
            logoImg.Image = logoAsset
            logoImg.ImageColor3 = Color3.new(1, 1, 1)
        end
    end)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Text = Title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 20
    titleLbl.TextColor3 = Color3.fromHex("#FFFFFF")
    titleLbl.TextStrokeTransparency = 0.6
    titleLbl.TextStrokeColor3 = Color3.fromHex("#000000")
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Size = UDim2.new(1, -44, 0, 20)
    titleLbl.Position = UDim2.new(0, 42, 0, 9)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = brandContainer

    local subTitleLbl = Instance.new("TextLabel")
    subTitleLbl.Name = "SubTitle"
    subTitleLbl.Text = string.upper(SubTitle)
    subTitleLbl.Font = Enum.Font.GothamBold
    subTitleLbl.TextSize = 11
    subTitleLbl.TextColor3 = Color3.fromHex("#38BDF8")
    subTitleLbl.TextStrokeTransparency = 0.7
    subTitleLbl.TextStrokeColor3 = Color3.fromHex("#000000")
    subTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    subTitleLbl.Size = UDim2.new(1, -44, 0, 14)
    subTitleLbl.Position = UDim2.new(0, 42, 0, 30)
    subTitleLbl.BackgroundTransparency = 1
    subTitleLbl.Parent = brandContainer

    -- Real-time FPS & Ping Tracker (Replaced "Beyond Your Limits")
    local perfLbl = Instance.new("TextLabel")
    perfLbl.Name = "PerfTracker"
    perfLbl.Text = "FPS: 60  |  Ping: -- ms"
    perfLbl.Font = Enum.Font.GothamBold
    perfLbl.TextSize = 12
    perfLbl.TextColor3 = Color3.fromHex("#00E5FF")
    perfLbl.TextTransparency = 0.1
    perfLbl.Size = UDim2.new(0, 220, 1, 0)
    perfLbl.Position = UDim2.new(0.5, -110, 0, 0)
    perfLbl.BackgroundTransparency = 1
    perfLbl.Parent = topbar

    task.spawn(function()
        local frameCount = 0
        local lastTime = os.clock()
        local fps = 60
        local Stats = game:GetService("Stats")

        local renderConn
        renderConn = RunService.RenderStepped:Connect(function()
            if not mainFrame.Parent then
                if renderConn then renderConn:Disconnect() end
                return
            end
            frameCount = frameCount + 1
            local now = os.clock()
            if now - lastTime >= 0.5 then
                fps = math.floor(frameCount / (now - lastTime))
                frameCount = 0
                lastTime = now

                local ping = 0
                pcall(function()
                    ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                end)
                if ping <= 0 then
                    pcall(function()
                        ping = math.floor(Stats.PerformanceStats.Ping:GetValue())
                    end)
                end

                perfLbl.Text = string.format("FPS: %d  |  Ping: %d ms", fps, ping)
            end
        end)
    end)

    -- Window Controls (Minimize / Maximize / Close)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.fromOffset(100, 32)
    controlsFrame.Position = UDim2.new(1, -114, 0.5, -16)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = topbar

    local function makeControlBtn(text, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(28, 28)
        btn.Position = UDim2.new(0, posX, 0, 2)
        btn.BackgroundColor3 = Color3.fromHex("#081426")
        btn.BackgroundTransparency = 0.4
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromHex("#94A3B8")
        btn.AutoButtonColor = false
        btn.Parent = controlsFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromHex("#00E5FF")
        s.Thickness = 1
        s.Transparency = 0.8
        s.Parent = btn
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#0F2847"), TextColor3 = Color3.fromHex("#FFFFFF") }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#081426"), TextColor3 = Color3.fromHex("#94A3B8") }):Play()
        end)
        return btn
    end

    local btnMin = makeControlBtn("—", 0)
    local btnMax = makeControlBtn("□", 34)
    local btnClose = makeControlBtn("✕", 68)

    -- ── Rock-Solid Draggable Logic (Desktop Mouse + Mobile Touch + Delta compatible) ──
    local dragging = false
    local dragStart = Vector2.zero
    local startPos = mainFrame.Position

    local function onDragStart(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = mainFrame.Position
        end
    end

    topbar.InputBegan:Connect(onDragStart)
    brandContainer.InputBegan:Connect(onDragStart)

    -- Make child labels non-active so touches pass cleanly to topbar
    brandContainer.Active = false
    titleLbl.Active = false
    subTitleLbl.Active = false
    perfLbl.Active = false
    topbarLine.Active = false

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local current = Vector2.new(input.Position.X, input.Position.Y)
            local delta = current - dragStart
            local curScale = (windowScale and windowScale.Scale) or 1.0
            
            -- Compensate for UIScale so window tracks finger 1:1 on mobile without lagging or jumping
            local scaledDeltaX = delta.X / curScale
            local scaledDeltaY = delta.Y / curScale
            
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + scaledDeltaX,
                startPos.Y.Scale,
                startPos.Y.Offset + scaledDeltaY
            )
        end
    end)

    local function onDragEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    UserInputService.InputEnded:Connect(onDragEnd)
    if UserInputService.TouchEnded then
        UserInputService.TouchEnded:Connect(function()
            dragging = false
        end)
    end

    -- ─────────────────────────────────────────────────────────
    -- LEFT SIDEBAR (Tabs + User Profile Badge)
    -- ─────────────────────────────────────────────────────────
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 215, 1, -54)
    sidebar.Position = UDim2.new(0, 0, 0, 54)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 5
    sidebar.Parent = mainFrame

    local sidebarDivider = Instance.new("Frame")
    sidebarDivider.Name = "SidebarDivider"
    sidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    sidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    sidebarDivider.BackgroundColor3 = Color3.fromHex("#00E5FF")
    sidebarDivider.BackgroundTransparency = 0.8
    sidebarDivider.BorderSizePixel = 0
    sidebarDivider.Parent = sidebar

    local tabButtonsScroll = Instance.new("ScrollingFrame")
    tabButtonsScroll.Name = "TabButtonsScroll"
    tabButtonsScroll.Size = UDim2.new(1, -16, 1, -82)
    tabButtonsScroll.Position = UDim2.new(0, 8, 0, 10)
    tabButtonsScroll.BackgroundTransparency = 1
    tabButtonsScroll.BorderSizePixel = 0
    tabButtonsScroll.ScrollBarThickness = 2
    tabButtonsScroll.ScrollBarImageColor3 = Color3.fromHex("#00E5FF")
    tabButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabButtonsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabButtonsScroll.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.FillDirection = Enum.FillDirection.Vertical
    tabListLayout.Padding = UDim.new(0, 7)
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Parent = tabButtonsScroll

    -- Bottom User Profile Card
    local profileCard = Instance.new("Frame")
    profileCard.Name = "UserProfileCard"
    profileCard.Size = UDim2.new(1, -16, 0, 60)
    profileCard.Position = UDim2.new(0, 8, 1, -68)
    profileCard.BackgroundColor3 = Color3.fromHex("#061122")
    profileCard.BackgroundTransparency = 0.3
    profileCard.BorderSizePixel = 0
    profileCard.Parent = sidebar

    local profileCorner = Instance.new("UICorner")
    profileCorner.CornerRadius = UDim.new(0, 12)
    profileCorner.Parent = profileCard

    local profileStroke = Instance.new("UIStroke")
    profileStroke.Color = Color3.fromHex("#00E5FF")
    profileStroke.Thickness = 1.2
    profileStroke.Transparency = 0.65
    profileStroke.Parent = profileCard

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Name = "Avatar"
    avatarImg.Size = UDim2.fromOffset(40, 40)
    avatarImg.Position = UDim2.new(0, 10, 0.5, -20)
    avatarImg.BackgroundColor3 = Color3.fromHex("#0B1B33")
    avatarImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    avatarImg.Parent = profileCard
    local avCorner = Instance.new("UICorner")
    avCorner.CornerRadius = UDim.new(0, 8)
    avCorner.Parent = avatarImg

    local dNameLbl = Instance.new("TextLabel")
    dNameLbl.Name = "DisplayName"
    dNameLbl.Text = LocalPlayer.DisplayName
    dNameLbl.Font = Enum.Font.GothamBold
    dNameLbl.TextSize = 13
    dNameLbl.TextColor3 = Color3.fromHex("#FFFFFF")
    dNameLbl.TextStrokeTransparency = 0.7
    dNameLbl.TextStrokeColor3 = Color3.fromHex("#000000")
    dNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    dNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    dNameLbl.Size = UDim2.new(1, -60, 0, 16)
    dNameLbl.Position = UDim2.new(0, 56, 0, 8)
    dNameLbl.BackgroundTransparency = 1
    dNameLbl.Parent = profileCard

    local uNameLbl = Instance.new("TextLabel")
    uNameLbl.Name = "Username"
    uNameLbl.Text = "@" .. LocalPlayer.Name
    uNameLbl.Font = Enum.Font.GothamBold
    uNameLbl.TextSize = 11
    uNameLbl.TextColor3 = Color3.fromHex("#CBD5E1")
    uNameLbl.TextStrokeTransparency = 0.75
    uNameLbl.TextStrokeColor3 = Color3.fromHex("#000000")
    uNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    uNameLbl.Size = UDim2.new(1, -60, 0, 14)
    uNameLbl.Position = UDim2.new(0, 56, 0, 24)
    uNameLbl.BackgroundTransparency = 1
    uNameLbl.Parent = profileCard

    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.Name = "Badge"
    badgeLbl.Text = "2K Script • Premium Hub"
    badgeLbl.Font = Enum.Font.GothamMedium
    badgeLbl.TextSize = 9
    badgeLbl.TextColor3 = Color3.fromHex("#38BDF8")
    badgeLbl.TextXAlignment = Enum.TextXAlignment.Left
    badgeLbl.Size = UDim2.new(1, -60, 0, 12)
    badgeLbl.Position = UDim2.new(0, 56, 0, 40)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Parent = profileCard

    -- ─────────────────────────────────────────────────────────
    -- RIGHT CONTENT AREA (Containers)
    -- ─────────────────────────────────────────────────────────
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -225, 1, -64)
    contentArea.Position = UDim2.new(0, 220, 0, 58)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = 4
    contentArea.Parent = mainFrame

    -- Window Object and Collections (Unified WindowScale - Zero Duplicates)
    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        UIScale = windowScale,
        Tabs = {},
        SelectedTab = nil,
        IsOpen = true
    }

    function Window:SetScale(scale)
        _G.TwoSkiCustomScale = scale
        windowScale.Scale = math.clamp(scale, 0.28, 1.20)
    end

    function Window:Toggle()
        self.IsOpen = not self.IsOpen
        if self.IsOpen then
            mainFrame.Visible = true
            TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
        else
            local tw = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 1.5, 0)
            })
            tw:Play()
            tw.Completed:Connect(function()
                if not self.IsOpen then mainFrame.Visible = false end
            end)
        end
    end

    function Window:Open()
        if not self.IsOpen then self:Toggle() end
    end

    function Window:Close()
        if self.IsOpen then self:Toggle() end
    end

    function Window:Destroy()
        pcall(function() screenGui:Destroy() end)
    end

    btnMin.MouseButton1Click:Connect(function() Window:Toggle() end)
    btnClose.MouseButton1Click:Connect(function() Window:Toggle() end)

    -- Fullscreen / Fit Toggle
    local isMax = false
    local originalSize = Size
    local function toggleMax()
        isMax = not isMax
        if isMax then
            TweenService:Create(windowScale, TweenInfo.new(0.25), { Scale = 1.0 }):Play()
            TweenService:Create(mainFrame, TweenInfo.new(0.25), {
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
        else
            updateAdaptiveScale()
            TweenService:Create(mainFrame, TweenInfo.new(0.25), {
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
        end
    end
    btnMax.MouseButton1Click:Connect(toggleMax)

    -- ─────────────────────────────────────────────────────────
    -- CORNER RESIZE HANDLE (Interactive Scaler / Resizer)
    -- ─────────────────────────────────────────────────────────
    local resizeGrip = Instance.new("TextButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.Size = UDim2.fromOffset(28, 28)
    resizeGrip.Position = UDim2.new(1, -28, 1, -28)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Text = ""
    resizeGrip.AutoButtonColor = false
    resizeGrip.ZIndex = 25
    resizeGrip.Parent = mainFrame

    -- Aesthetic Cyber Resize Grip Visual Icon
    local gripVisual = Instance.new("ImageLabel")
    gripVisual.Name = "GripVisual"
    gripVisual.Size = UDim2.fromOffset(16, 16)
    gripVisual.Position = UDim2.new(1, -18, 1, -18)
    gripVisual.BackgroundTransparency = 1
    gripVisual.Image = "rbxassetid://10734920536" -- maximize-2 / resize diagonal arrow
    gripVisual.ImageColor3 = Color3.fromHex("#00E5FF")
    gripVisual.ImageTransparency = 0.4
    gripVisual.ZIndex = 26
    gripVisual.Parent = mainFrame

    local isResizing = false
    local resizeStartMouse = Vector2.zero
    local resizeStartSize = Vector2.zero

    resizeGrip.MouseEnter:Connect(function()
        TweenService:Create(gripVisual, TweenInfo.new(0.15), {
            ImageColor3 = Color3.fromHex("#00FFFF"),
            ImageTransparency = 0.0
        }):Play()
    end)

    resizeGrip.MouseLeave:Connect(function()
        if not isResizing then
            TweenService:Create(gripVisual, TweenInfo.new(0.15), {
                ImageColor3 = Color3.fromHex("#00E5FF"),
                ImageTransparency = 0.4
            }):Play()
        end
    end)

    resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizing = true
            resizeStartMouse = Vector2.new(input.Position.X, input.Position.Y)
            resizeStartSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
            
            TweenService:Create(gripVisual, TweenInfo.new(0.1), {
                ImageColor3 = Color3.fromHex("#00FFFF"),
                ImageTransparency = 0.0
            }):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local current = Vector2.new(input.Position.X, input.Position.Y)
            local delta = current - resizeStartMouse
            local curScale = (windowScale and windowScale.Scale) or 1.0

            local newW = math.clamp(resizeStartSize.X + (delta.X / curScale), 540, 1400)
            local newH = math.clamp(resizeStartSize.Y + (delta.Y / curScale), 350, 900)

            mainFrame.Size = UDim2.fromOffset(newW, newH)
            originalSize = mainFrame.Size
        end
    end)

    local function onResizeEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isResizing then
                isResizing = false
                TweenService:Create(gripVisual, TweenInfo.new(0.2), {
                    ImageColor3 = Color3.fromHex("#00E5FF"),
                    ImageTransparency = 0.4
                }):Play()
            end
        end
    end

    UserInputService.InputEnded:Connect(onResizeEnd)
    if UserInputService.TouchEnded then
        UserInputService.TouchEnded:Connect(function()
            if isResizing then
                isResizing = false
                TweenService:Create(gripVisual, TweenInfo.new(0.2), {
                    ImageColor3 = Color3.fromHex("#00E5FF"),
                    ImageTransparency = 0.4
                }):Play()
            end
        end)
    end

    -- ─────────────────────────────────────────────────────────
    -- TAB BUILDER
    -- ─────────────────────────────────────────────────────────
    function Window:Tab(tabCfg)
        tabCfg = tabCfg or {}
        local tabTitle = tabCfg.Title or "Tab"
        local tabIcon = resolveIcon(tabCfg.Icon)
        local tabIndex = #self.Tabs + 1

        -- Tab Button in Sidebar
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabIndex
        tabBtn.Size = UDim2.new(1, 0, 0, 42)
        tabBtn.BackgroundColor3 = Color3.fromHex("#081426")
        tabBtn.BackgroundTransparency = 0.35
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabButtonsScroll

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 10)
        tabBtnCorner.Parent = tabBtn

        local tabBtnStroke = Instance.new("UIStroke")
        tabBtnStroke.Color = Color3.fromHex("#00E5FF")
        tabBtnStroke.Thickness = 1.2
        tabBtnStroke.Transparency = 0.8
        tabBtnStroke.Parent = tabBtn

        local tIcon = Instance.new("ImageLabel")
        tIcon.Name = "Icon"
        tIcon.Size = UDim2.fromOffset(20, 20)
        tIcon.Position = UDim2.new(0, 12, 0.5, -10)
        tIcon.BackgroundTransparency = 1
        tIcon.Image = tabIcon
        tIcon.ImageColor3 = Color3.fromHex("#CBD5E1")
        tIcon.Parent = tabBtn

        local tTitle = Instance.new("TextLabel")
        tTitle.Name = "Title"
        tTitle.Text = tabTitle
        tTitle.Font = Enum.Font.GothamBold
        tTitle.TextSize = 14
        tTitle.TextColor3 = Color3.fromHex("#FFFFFF")
        tTitle.TextStrokeTransparency = 0.65
        tTitle.TextStrokeColor3 = Color3.fromHex("#000000")
        tTitle.TextXAlignment = Enum.TextXAlignment.Left
        tTitle.Size = UDim2.new(1, -44, 1, 0)
        tTitle.Position = UDim2.new(0, 40, 0, 0)
        tTitle.BackgroundTransparency = 1
        tTitle.Parent = tabBtn

        -- Tab Content ScrollingFrame
        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = "TabContent_" .. tabIndex
        tabScroll.Size = UDim2.fromScale(1, 1)
        tabScroll.Position = UDim2.fromScale(0, 0)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 3
        tabScroll.ScrollBarImageColor3 = Color3.fromHex("#00E5FF")
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabScroll.Visible = false
        tabScroll.Parent = contentArea

        local tabScrollLayout = Instance.new("UIListLayout")
        tabScrollLayout.FillDirection = Enum.FillDirection.Vertical
        tabScrollLayout.Padding = UDim.new(0, 12)
        tabScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabScrollLayout.Parent = tabScroll

        local tabScrollPadding = Instance.new("UIPadding")
        tabScrollPadding.PaddingTop = UDim.new(0, 2)
        tabScrollPadding.PaddingBottom = UDim.new(0, 20)
        tabScrollPadding.PaddingRight = UDim.new(0, 8)
        tabScrollPadding.Parent = tabScroll

        local Tab = {
            Index = tabIndex,
            TabBtn = tabBtn,
            Container = tabScroll,
            Title = tabTitle
        }

        function Tab:Select()
            for _, t in ipairs(Window.Tabs) do
                t.Container.Visible = false
                pcall(function()
                    TweenService:Create(t.TabBtn, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromHex("#081426"),
                        BackgroundTransparency = 0.35
                    }):Play()
                    local s = t.TabBtn:FindFirstChildWhichIsA("UIStroke")
                    if s then s.Transparency = 0.8 end
                    local ttl = t.TabBtn:FindFirstChild("Title")
                    if ttl then ttl.TextColor3 = Color3.fromHex("#CBD5E1") end
                    local ic = t.TabBtn:FindFirstChild("Icon")
                    if ic then ic.ImageColor3 = Color3.fromHex("#94A3B8") end
                end)
            end
            
            tabScroll.Visible = true
            pcall(function()
                TweenService:Create(tabBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromHex("#0284C7"),
                    BackgroundTransparency = 0.15
                }):Play()
                local s = tabBtn:FindFirstChildWhichIsA("UIStroke")
                if s then
                    s.Transparency = 0.1
                    s.Color = Color3.fromHex("#00E5FF")
                end
                tTitle.TextColor3 = Color3.fromHex("#FFFFFF")
                tIcon.ImageColor3 = Color3.fromHex("#00FFFF")
            end)
            Window.SelectedTab = Tab
        end

        tabBtn.MouseButton1Click:Connect(function()
            Tab:Select()
        end)

        tabBtn.MouseEnter:Connect(function()
            if Window.SelectedTab ~= Tab then
                TweenService:Create(tabBtn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromHex("#0E2342"),
                    BackgroundTransparency = 0.2
                }):Play()
                tTitle.TextColor3 = Color3.fromHex("#FFFFFF")
            end
        end)

        tabBtn.MouseLeave:Connect(function()
            if Window.SelectedTab ~= Tab then
                TweenService:Create(tabBtn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromHex("#081426"),
                    BackgroundTransparency = 0.35
                }):Play()
                tTitle.TextColor3 = Color3.fromHex("#CBD5E1")
            end
        end)

        local currentSec = nil
        local function getSec()
            if not currentSec then
                currentSec = Tab:Section({ Title = tabTitle, Desc = "", Icon = tabCfg.Icon })
            end
            return currentSec
        end

        Tab.Toggle = function(_, c) return getSec():Toggle(c) end
        Tab.Slider = function(_, c) return getSec():Slider(c) end
        Tab.Dropdown = function(_, c) return getSec():Dropdown(c) end
        Tab.Button = function(_, c) return getSec():Button(c) end
        Tab.Paragraph = function(_, c) return getSec():Paragraph(c) end
        Tab.Input = function(_, c) return getSec():Input(c) end

        -- ─────────────────────────────────────────────────────
        -- SECTION CARD BUILDER (Like in IMG_5499.png)
        -- ─────────────────────────────────────────────────────
        function Tab:Section(secCfg)
            secCfg = secCfg or {}
            local secTitle = secCfg.Title or "Section"
            local secDesc = secCfg.Desc or ""
            local secIcon = resolveIcon(secCfg.Icon)

            local card = Instance.new("Frame")
            card.Name = "Card_" .. secTitle
            card.Size = UDim2.new(1, 0, 0, 0)
            card.AutomaticSize = Enum.AutomaticSize.Y
            card.BackgroundColor3 = Color3.fromHex("#040C1A")
            card.BackgroundTransparency = 0.20
            card.BorderSizePixel = 0
            card.Parent = tabScroll

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 14)
            cardCorner.Parent = card

            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = Color3.fromHex("#00D4FF")
            cardStroke.Thickness = 1.3
            cardStroke.Transparency = 0.5
            cardStroke.Parent = card

            local cardLayout = Instance.new("UIListLayout")
            cardLayout.FillDirection = Enum.FillDirection.Vertical
            cardLayout.Padding = UDim.new(0, 8)
            cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
            cardLayout.Parent = card

            local cardPadding = Instance.new("UIPadding")
            cardPadding.PaddingTop = UDim.new(0, 12)
            cardPadding.PaddingBottom = UDim.new(0, 12)
            cardPadding.PaddingLeft = UDim.new(0, 14)
            cardPadding.PaddingRight = UDim.new(0, 14)
            cardPadding.Parent = card

            -- Section Header
            local headerFrame = Instance.new("Frame")
            headerFrame.Name = "Header"
            headerFrame.Size = UDim2.new(1, 0, 0, 36)
            headerFrame.BackgroundTransparency = 1
            headerFrame.LayoutOrder = 0
            headerFrame.Parent = card

            local headerIconBadge = Instance.new("Frame")
            headerIconBadge.Name = "Badge"
            headerIconBadge.Size = UDim2.fromOffset(34, 34)
            headerIconBadge.Position = UDim2.new(0, 0, 0.5, -17)
            headerIconBadge.BackgroundColor3 = Color3.fromHex("#082042")
            headerIconBadge.BackgroundTransparency = 0.2
            headerIconBadge.Parent = headerFrame
            local bibCorner = Instance.new("UICorner")
            bibCorner.CornerRadius = UDim.new(0, 8)
            bibCorner.Parent = headerIconBadge
            local bibStroke = Instance.new("UIStroke")
            bibStroke.Color = Color3.fromHex("#00E5FF")
            bibStroke.Thickness = 1.2
            bibStroke.Transparency = 0.5
            bibStroke.Parent = headerIconBadge

            local hIcon = Instance.new("ImageLabel")
            hIcon.Size = UDim2.fromOffset(20, 20)
            hIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
            hIcon.BackgroundTransparency = 1
            hIcon.Image = secIcon
            hIcon.ImageColor3 = Color3.fromHex("#00FFFF")
            hIcon.Parent = headerIconBadge

            local hTitle = Instance.new("TextLabel")
            hTitle.Name = "Title"
            hTitle.Text = secTitle
            hTitle.Font = Enum.Font.GothamBold
            hTitle.TextSize = 16
            hTitle.TextColor3 = Color3.fromHex("#FFFFFF")
            hTitle.TextStrokeTransparency = 0.55
            hTitle.TextStrokeColor3 = Color3.fromHex("#000000")
            hTitle.TextXAlignment = Enum.TextXAlignment.Left
            hTitle.Size = UDim2.new(1, -44, 0, 18)
            hTitle.Position = UDim2.new(0, 42, 0, 0)
            hTitle.BackgroundTransparency = 1
            hTitle.Parent = headerFrame

            local hDesc = Instance.new("TextLabel")
            hDesc.Name = "Desc"
            hDesc.Text = secDesc
            hDesc.Font = Enum.Font.GothamBold
            hDesc.TextSize = 12
            hDesc.TextColor3 = Color3.fromHex("#E2E8F0")
            hDesc.TextStrokeTransparency = 0.75
            hDesc.TextStrokeColor3 = Color3.fromHex("#000000")
            hDesc.TextXAlignment = Enum.TextXAlignment.Left
            hDesc.Size = UDim2.new(1, -44, 0, 16)
            hDesc.Position = UDim2.new(0, 42, 0, 18)
            hDesc.BackgroundTransparency = 1
            hDesc.Parent = headerFrame

            local Section = {
                Card = card,
                Tab = Tab
            }
            currentSec = Section

            -- Helper: make row frame
            local function makeRow(height)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, height or 46)
                row.BackgroundColor3 = Color3.fromHex("#08182E")
                row.BackgroundTransparency = 0.2
                row.BorderSizePixel = 0
                row.Parent = card
                local rc = Instance.new("UICorner")
                rc.CornerRadius = UDim.new(0, 10)
                rc.Parent = row
                local rs = Instance.new("UIStroke")
                rs.Color = Color3.fromHex("#00E5FF")
                rs.Thickness = 1
                rs.Transparency = 0.8
                rs.Parent = row
                return row
            end

            -- Helper: make icon badge
            local function makeRowIcon(row, iconName)
                local b = Instance.new("Frame")
                b.Size = UDim2.fromOffset(30, 30)
                b.Position = UDim2.new(0, 10, 0.5, -15)
                b.BackgroundColor3 = Color3.fromHex("#081A33")
                b.BackgroundTransparency = 0.2
                b.Parent = row
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 8)
                c.Parent = b
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromHex("#00E5FF")
                s.Thickness = 1
                s.Transparency = 0.7
                s.Parent = b
                local img = Instance.new("ImageLabel")
                img.Size = UDim2.fromOffset(16, 16)
                img.Position = UDim2.new(0.5, -8, 0.5, -8)
                img.BackgroundTransparency = 1
                local resolved = resolveIcon(iconName)
                img.Image = (resolved and resolved ~= "") and resolved or "rbxassetid://10709810948"
                img.ImageColor3 = Color3.fromHex("#00E5FF")
                img.Parent = b
                return b
            end

            -- Helper: make title/desc
            local function makeRowTexts(row, title, desc, rightOffset)
                rightOffset = rightOffset or 60
                local t = Instance.new("TextLabel")
                t.Text = title
                t.Font = Enum.Font.GothamBold
                t.TextSize = 15
                t.TextColor3 = Color3.fromHex("#FFFFFF")
                t.TextStrokeTransparency = 0.65
                t.TextStrokeColor3 = Color3.fromHex("#000000")
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.Size = UDim2.new(1, -(52 + rightOffset), 0, (desc and desc ~= "") and 20 or 30)
                t.Position = UDim2.new(0, 48, 0.5, (desc and desc ~= "") and -17 or -15)
                t.BackgroundTransparency = 1
                t.Parent = row

                if desc and desc ~= "" then
                    local d = Instance.new("TextLabel")
                    d.Text = desc
                    d.Font = Enum.Font.GothamBold
                    d.TextSize = 12
                    d.TextColor3 = Color3.fromHex("#E2E8F0")
                    d.TextStrokeTransparency = 0.75
                    d.TextStrokeColor3 = Color3.fromHex("#000000")
                    d.TextXAlignment = Enum.TextXAlignment.Left
                    d.Size = UDim2.new(1, -(52 + rightOffset), 0, 16)
                    d.Position = UDim2.new(0, 48, 0.5, 3)
                    d.BackgroundTransparency = 1
                    d.Parent = row
                end
                return t
            end

            -- 1. TOGGLE (Cyber Pill Animated)
            function Section:Toggle(cfg)
                cfg = cfg or {}
                local title = cfg.Title or "Toggle"
                local desc = cfg.Desc or ""
                local icon = cfg.Icon or "zap"
                local val = cfg.Value or false
                local callback = cfg.Callback or function() end

                local row = makeRow(48)
                makeRowIcon(row, icon)
                makeRowTexts(row, title, desc, 60)

                local rowClick = Instance.new("TextButton")
                rowClick.Name = "RowClickArea"
                rowClick.Size = UDim2.fromScale(1, 1)
                rowClick.BackgroundTransparency = 1
                rowClick.Text = ""
                rowClick.AutoButtonColor = false
                rowClick.ZIndex = 4
                rowClick.Parent = row

                local pill = Instance.new("TextButton")
                pill.Size = UDim2.fromOffset(46, 24)
                pill.Position = UDim2.new(1, -56, 0.5, -12)
                pill.BackgroundColor3 = val and Color3.fromHex("#00E5FF") or Color3.fromHex("#1E293B")
                pill.Text = ""
                pill.AutoButtonColor = false
                pill.ZIndex = 5
                pill.Parent = row

                local pillCorner = Instance.new("UICorner")
                pillCorner.CornerRadius = UDim.new(1, 0)
                pillCorner.Parent = pill

                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(18, 18)
                knob.Position = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                knob.BackgroundColor3 = Color3.fromHex("#FFFFFF")
                knob.BorderSizePixel = 0
                knob.ZIndex = 6
                knob.Parent = pill

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local function updateToggle(selfOrVal, maybeVal)
                    local newVal = maybeVal
                    if newVal == nil then
                        newVal = selfOrVal
                    end
                    val = (newVal == true)
                    local targetColor = val and Color3.fromHex("#00E5FF") or Color3.fromHex("#1E293B")
                    local targetPos = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    pill.BackgroundColor3 = targetColor
                    knob.Position = targetPos
                    pcall(function()
                        TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { BackgroundColor3 = targetColor }):Play()
                        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = targetPos }):Play()
                    end)
                    task.spawn(callback, val)
                end

                local lastClickTick = 0
                local function handleToggleClick()
                    local now = tick()
                    if now - lastClickTick < 0.15 then return end
                    lastClickTick = now
                    updateToggle(not val)
                end

                rowClick.Activated:Connect(handleToggleClick)
                pill.Activated:Connect(handleToggleClick)

                rowClick.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromHex("#0E2342"),
                        BackgroundTransparency = 0.1
                    }):Play()
                end)
                rowClick.MouseLeave:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromHex("#08182E"),
                        BackgroundTransparency = 0.2
                    }):Play()
                end)

                return {
                    SetValue = updateToggle,
                    Set = updateToggle,
                    Row = row
                }
            end

            -- 2. SLIDER (Draggable Track + Number Badge)
            function Section:Slider(cfg)
                cfg = cfg or {}
                local title = cfg.Title or "Slider"
                local desc = cfg.Desc or ""
                local icon = cfg.Icon or "sliders-horizontal"
                local minVal = cfg.Min or 0
                local maxVal = cfg.Max or 100
                local curVal = cfg.Default or minVal
                local callback = cfg.Callback or function() end

                local row = makeRow(52)
                makeRowIcon(row, icon)
                makeRowTexts(row, title, desc, 190)

                -- Numeric Readout
                local numBadge = Instance.new("TextLabel")
                numBadge.Size = UDim2.fromOffset(45, 20)
                numBadge.Position = UDim2.new(1, -190, 0.5, -10)
                numBadge.BackgroundColor3 = Color3.fromHex("#0B1C33")
                numBadge.Text = tostring(curVal)
                numBadge.Font = Enum.Font.GothamBold
                numBadge.TextSize = 13
                numBadge.TextColor3 = Color3.fromHex("#00FFFF")
                numBadge.TextStrokeTransparency = 0.65
                numBadge.TextStrokeColor3 = Color3.fromHex("#000000")
                numBadge.ZIndex = 5
                numBadge.Parent = row
                local nbc = Instance.new("UICorner")
                nbc.CornerRadius = UDim.new(0, 6)
                nbc.Parent = numBadge

                -- Slider Hit Area (Generous touch/click box)
                local hitArea = Instance.new("TextButton")
                hitArea.Name = "SliderHitArea"
                hitArea.Size = UDim2.fromOffset(140, 36)
                hitArea.Position = UDim2.new(1, -145, 0.5, -18)
                hitArea.BackgroundTransparency = 1
                hitArea.Text = ""
                hitArea.AutoButtonColor = false
                hitArea.ZIndex = 6
                hitArea.Parent = row

                -- Visual Slider Track
                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -10, 0, 6)
                track.Position = UDim2.new(0, 5, 0.5, -3)
                track.BackgroundColor3 = Color3.fromHex("#0F1E36")
                track.BorderSizePixel = 0
                track.ZIndex = 6
                track.Parent = hitArea

                local tc = Instance.new("UICorner")
                tc.CornerRadius = UDim.new(1, 0)
                tc.Parent = track

                local fill = Instance.new("Frame")
                local pct = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromHex("#00E5FF")
                fill.BorderSizePixel = 0
                fill.ZIndex = 7
                fill.Parent = track
                local fc = Instance.new("UICorner")
                fc.CornerRadius = UDim.new(1, 0)
                fc.Parent = fill

                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.fromOffset(16, 16)
                thumb.AnchorPoint = Vector2.new(0.5, 0.5)
                thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                thumb.BackgroundColor3 = Color3.fromHex("#FFFFFF")
                thumb.BorderSizePixel = 0
                thumb.ZIndex = 8
                thumb.Parent = track
                local thCorner = Instance.new("UICorner")
                thCorner.CornerRadius = UDim.new(1, 0)
                thCorner.Parent = thumb

                local sliding = false
                local function updateFromPos(x)
                    local trackX = track.AbsolutePosition.X
                    local trackW = track.AbsoluteSize.X
                    if trackW <= 0 then return end
                    local alpha = math.clamp((x - trackX) / trackW, 0, 1)
                    local rawVal = minVal + (alpha * (maxVal - minVal))
                    local val = (maxVal - minVal > 20) and math.round(rawVal) or (math.round(rawVal * 100) / 100)
                    curVal = val
                    numBadge.Text = tostring(val)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
                    task.spawn(callback, val)
                end

                hitArea.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateFromPos(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateFromPos(input.Position.X)
                    end
                end)

                local function updateSlider(selfOrVal, maybeVal)
                    local v = maybeVal
                    if v == nil or type(selfOrVal) == "number" then
                        v = selfOrVal
                    end
                    v = tonumber(v) or minVal
                    if minVal >= 20 and v <= 2.0 and v > 0 then
                        v = v * 100
                    end
                    curVal = math.clamp(v, minVal, maxVal)
                    local alpha = (maxVal > minVal) and ((curVal - minVal) / (maxVal - minVal)) or 0
                    numBadge.Text = tostring(curVal)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
                    task.spawn(callback, curVal)
                end

                return {
                    SetValue = updateSlider,
                    Set = updateSlider,
                    GetValue = function() return curVal end,
                    Row = row
                }
            end

            -- 3. DROPDOWN (Sleek Accordion Tray - Supports Single & Multi Selection)
            function Section:Dropdown(cfg)
                cfg = cfg or {}
                local title = cfg.Title or "Dropdown"
                local desc = cfg.Desc or ""
                local icon = cfg.Icon or "chevron-up"
                local values = cfg.Values or {}
                local isMulti = cfg.Multi or cfg.MultiSelect or false
                local curVal = cfg.Value

                if isMulti then
                    if type(curVal) ~= "table" then
                        curVal = {}
                    end
                else
                    if type(curVal) == "table" then
                        if #curVal > 0 then
                            curVal = curVal[1]
                        else
                            local firstV = nil
                            for _, v in pairs(curVal) do
                                if v ~= nil and v ~= "" and type(v) ~= "table" then
                                    firstV = v
                                    break
                                end
                            end
                            curVal = firstV or (values and values[1]) or ""
                        end
                    elseif curVal == nil or curVal == "" then
                        curVal = (values and values[1]) or ""
                    end
                end
                local callback = cfg.Callback or function() end

                local closedHeight = 52
                local maxVisibleItems = 6
                local itemHeight = 30
                local trayHeight = math.clamp(#values * (itemHeight + 4), 34, maxVisibleItems * (itemHeight + 4))
                local openHeight = closedHeight + trayHeight + 16

                local row = makeRow(closedHeight)
                row.ClipsDescendants = true

                -- Header Button (Fixed 52px top bar)
                local header = Instance.new("TextButton")
                header.Name = "Header"
                header.Size = UDim2.new(1, 0, 0, closedHeight)
                header.Position = UDim2.new(0, 0, 0, 0)
                header.BackgroundTransparency = 1
                header.Text = ""
                header.AutoButtonColor = false
                header.Parent = row

                makeRowIcon(header, icon)
                makeRowTexts(header, title, desc, 160)

                local dropBtn = Instance.new("TextButton")
                dropBtn.Name = "SelectorBadge"
                dropBtn.Size = UDim2.fromOffset(150, 30)
                dropBtn.Position = UDim2.new(1, -160, 0.5, -15)
                dropBtn.BackgroundColor3 = Color3.fromHex("#081A33")
                dropBtn.BackgroundTransparency = 0.2
                dropBtn.Text = ""
                dropBtn.AutoButtonColor = false
                dropBtn.Parent = header

                local dc = Instance.new("UICorner")
                dc.CornerRadius = UDim.new(0, 8)
                dc.Parent = dropBtn

                local ds = Instance.new("UIStroke")
                ds.Color = Color3.fromHex("#00E5FF")
                ds.Thickness = 1.2
                ds.Transparency = 0.6
                ds.Parent = dropBtn

                local function getDisplayText()
                    if not isMulti then
                        if type(curVal) == "table" then
                            if #curVal > 0 then
                                return tostring(curVal[1])
                            end
                            for _, v in pairs(curVal) do
                                if v ~= nil and v ~= "" and type(v) ~= "table" then
                                    return tostring(v)
                                end
                            end
                            return (values and values[1] and tostring(values[1])) or "เลือกรายการ"
                        end
                        if curVal == nil or curVal == "" then
                            return (values and values[1] and tostring(values[1])) or "เลือกรายการ"
                        end
                        return tostring(curVal)
                    end

                    local count = 0
                    local selList = {}
                    if type(curVal) == "table" then
                        for _, opt in ipairs(values) do
                            local isSel = false
                            if curVal[opt] == true then
                                isSel = true
                            else
                                for _, v in ipairs(curVal) do
                                    if v == opt then
                                        isSel = true
                                        break
                                    end
                                end
                            end
                            if isSel then
                                count = count + 1
                                table.insert(selList, tostring(opt))
                            end
                        end
                    end
                    if count == 0 then
                        return "เลือกรายการ"
                    elseif count == 1 then
                        return selList[1]
                    elseif count == 2 then
                        return selList[1] .. ", " .. selList[2]
                    else
                        return tostring(count) .. " รายการที่เลือก"
                    end
                end

                local lbl = Instance.new("TextLabel")
                lbl.Text = getDisplayText()
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 11
                lbl.TextColor3 = Color3.fromHex("#F1F5F9")
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.Size = UDim2.new(1, -26, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Parent = dropBtn

                local arrow = Instance.new("TextLabel")
                arrow.Text = "▾"
                arrow.Font = Enum.Font.GothamBold
                arrow.TextSize = 14
                arrow.TextColor3 = Color3.fromHex("#00E5FF")
                arrow.Size = UDim2.fromOffset(20, 30)
                arrow.Position = UDim2.new(1, -22, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Parent = dropBtn

                local divider = Instance.new("Frame")
                divider.Name = "Divider"
                divider.Size = UDim2.new(1, -20, 0, 1)
                divider.Position = UDim2.new(0, 10, 0, 51)
                divider.BackgroundColor3 = Color3.fromHex("#00E5FF")
                divider.BackgroundTransparency = 0.8
                divider.BorderSizePixel = 0
                divider.Visible = false
                divider.Parent = row

                local tray = Instance.new("ScrollingFrame")
                tray.Name = "OptionsTray"
                tray.Size = UDim2.new(1, -20, 0, trayHeight)
                tray.Position = UDim2.new(0, 10, 0, 58)
                tray.BackgroundTransparency = 1
                tray.BorderSizePixel = 0
                tray.ScrollBarThickness = 2
                tray.ScrollBarImageColor3 = Color3.fromHex("#00E5FF")
                tray.CanvasSize = UDim2.new(0, 0, 0, 0)
                tray.AutomaticCanvasSize = Enum.AutomaticSize.Y
                tray.Visible = false
                tray.Parent = row

                local trayLayout = Instance.new("UIListLayout")
                trayLayout.FillDirection = Enum.FillDirection.Vertical
                trayLayout.Padding = UDim.new(0, 4)
                trayLayout.SortOrder = Enum.SortOrder.LayoutOrder
                trayLayout.Parent = tray

                local optionButtons = {}
                local function updateSelectionHighlight()
                    for _, item in ipairs(optionButtons) do
                        local isSel = false
                        if isMulti then
                            if type(curVal) == "table" then
                                if curVal[item.Value] == true then
                                    isSel = true
                                else
                                    for _, v in ipairs(curVal) do
                                        if v == item.Value then
                                            isSel = true
                                            break
                                        end
                                    end
                                end
                            end
                        else
                            local checkVal = (type(curVal) == "table" and curVal[1]) or curVal
                            isSel = (item.Value == checkVal)
                        end

                        item.Btn.BackgroundColor3 = isSel and Color3.fromHex("#0284C7") or Color3.fromHex("#061528")
                        item.Btn.BackgroundTransparency = isSel and 0.15 or 0.4
                        item.Btn.TextColor3 = isSel and Color3.fromHex("#00FFFF") or Color3.fromHex("#CBD5E1")
                        item.Btn.Text = (isSel and "✓ " or "   ") .. tostring(item.Value)
                        local s = item.Btn:FindFirstChildWhichIsA("UIStroke")
                        if s then
                            s.Color = isSel and Color3.fromHex("#00FFFF") or Color3.fromHex("#00E5FF")
                            s.Transparency = isSel and 0.3 or 0.85
                        end
                    end
                end

                local isOpen = false
                local function toggleMenu()
                    isOpen = not isOpen
                    arrow.Text = isOpen and "▴" or "▾"
                    divider.Visible = isOpen
                    tray.Visible = isOpen

                    local targetH = isOpen and openHeight or closedHeight
                    TweenService:Create(row, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, targetH)
                    }):Play()

                    if isOpen then
                        updateSelectionHighlight()
                    end
                end

                header.MouseButton1Click:Connect(toggleMenu)
                dropBtn.MouseButton1Click:Connect(toggleMenu)

                local function renderOptions(newValues)
                    values = newValues or {}
                    for _, item in ipairs(optionButtons) do
                        pcall(function() item.Btn:Destroy() end)
                    end
                    table.clear(optionButtons)

                    trayHeight = math.clamp(#values * (itemHeight + 4), 34, maxVisibleItems * (itemHeight + 4))
                    openHeight = closedHeight + trayHeight + 16
                    tray.Size = UDim2.new(1, -20, 0, trayHeight)
                    if isOpen then
                        row.Size = UDim2.new(1, 0, 0, openHeight)
                    end

                    for _, opt in ipairs(values) do
                        local isSel = false
                        if isMulti then
                            if type(curVal) == "table" then
                                if curVal[opt] == true then
                                    isSel = true
                                else
                                    for _, v in ipairs(curVal) do
                                        if v == opt then isSel = true; break end
                                    end
                                end
                            end
                        else
                            local checkVal = (type(curVal) == "table" and curVal[1]) or curVal
                            isSel = (opt == checkVal)
                        end

                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, -4, 0, itemHeight)
                        optBtn.BackgroundColor3 = isSel and Color3.fromHex("#0284C7") or Color3.fromHex("#061528")
                        optBtn.BackgroundTransparency = isSel and 0.15 or 0.4
                        optBtn.Text = (isSel and "✓ " or "   ") .. tostring(opt)
                        optBtn.Font = Enum.Font.GothamBold
                        optBtn.TextSize = 13
                        optBtn.TextColor3 = isSel and Color3.fromHex("#00FFFF") or Color3.fromHex("#FFFFFF")
                        optBtn.TextStrokeTransparency = 0.7
                        optBtn.TextStrokeColor3 = Color3.fromHex("#000000")
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.AutoButtonColor = false
                        optBtn.Parent = tray

                        local oc = Instance.new("UICorner")
                        oc.CornerRadius = UDim.new(0, 6)
                        oc.Parent = optBtn

                        local os = Instance.new("UIStroke")
                        os.Color = isSel and Color3.fromHex("#00FFFF") or Color3.fromHex("#00E5FF")
                        os.Thickness = 1
                        os.Transparency = isSel and 0.3 or 0.85
                        os.Parent = optBtn

                        table.insert(optionButtons, { Btn = optBtn, Value = opt })

                        optBtn.MouseEnter:Connect(function()
                            TweenService:Create(optBtn, TweenInfo.new(0.15), {
                                BackgroundColor3 = Color3.fromHex("#0D2545"),
                                TextColor3 = Color3.fromHex("#FFFFFF")
                            }):Play()
                        end)

                        optBtn.MouseLeave:Connect(function()
                            updateSelectionHighlight()
                        end)

                        optBtn.MouseButton1Click:Connect(function()
                            if isMulti then
                                if type(curVal) ~= "table" then curVal = {} end
                                local wasSelected = false
                                if curVal[opt] == true then
                                    wasSelected = true
                                else
                                    for idx, v in ipairs(curVal) do
                                        if v == opt then wasSelected = true; break end
                                    end
                                end

                                if wasSelected then
                                    curVal[opt] = nil
                                    for idx = #curVal, 1, -1 do
                                        if curVal[idx] == opt then
                                            table.remove(curVal, idx)
                                        end
                                    end
                                else
                                    curVal[opt] = true
                                    table.insert(curVal, opt)
                                end
                                lbl.Text = getDisplayText()
                                updateSelectionHighlight()
                                task.spawn(callback, curVal)
                            else
                                curVal = opt
                                lbl.Text = getDisplayText()
                                updateSelectionHighlight()
                                toggleMenu()
                                task.spawn(callback, curVal)
                            end
                        end)
                    end
                end

                renderOptions(values)

                local function updateDropdown(selfOrVal, maybeVal)
                    local v = maybeVal
                    if v == nil then
                        v = selfOrVal
                    elseif type(selfOrVal) == "table" and (selfOrVal.Row ~= nil or selfOrVal.SetValue ~= nil or selfOrVal.Refresh ~= nil) then
                        v = maybeVal
                    end

                    if isMulti then
                        if type(v) == "table" then
                            local cleanArr = {}
                            for idx, item in pairs(v) do
                                if type(item) == "string" or type(item) == "number" then
                                    if type(idx) == "number" then
                                        table.insert(cleanArr, tostring(item))
                                    elseif item == true then
                                        table.insert(cleanArr, tostring(idx))
                                    end
                                end
                            end
                            curVal = cleanArr
                        elseif type(v) == "string" or type(v) == "number" then
                            curVal = { tostring(v) }
                        else
                            curVal = {}
                        end
                    else
                        if type(v) == "table" then
                            local first = v[1]
                            if first == nil then
                                for _, it in pairs(v) do
                                    if type(it) == "string" or type(it) == "number" then
                                        first = tostring(it)
                                        break
                                    end
                                end
                            end
                            curVal = first or (values and values[1]) or ""
                        else
                            curVal = (v ~= nil and v ~= "") and tostring(v) or ((values and values[1]) or "")
                        end
                    end
                    lbl.Text = getDisplayText()
                    updateSelectionHighlight()
                    task.spawn(callback, curVal)
                end

                return {
                    SetValue = updateDropdown,
                    Set = updateDropdown,
                    Select = updateDropdown,
                    Refresh = function(selfOrVals, maybeVals)
                        local newVals = maybeVals or selfOrVals
                        renderOptions(newVals)
                        lbl.Text = getDisplayText()
                    end,
                    SetValues = function(selfOrVals, maybeVals)
                        local newVals = maybeVals or selfOrVals
                        renderOptions(newVals)
                        lbl.Text = getDisplayText()
                    end,
                    GetValue = function() return curVal end,
                    Row = row
                }
            end

            -- 4. BUTTON (Interactive Action Card)
            function Section:Button(cfg)
                cfg = cfg or {}
                local title = cfg.Title or "Button"
                local desc = cfg.Desc or ""
                local icon = cfg.Icon or "zap"
                local callback = cfg.Callback or function() end

                local row = makeRow(48)
                makeRowIcon(row, icon)
                makeRowTexts(row, title, desc, 80)

                local rowClick = Instance.new("TextButton")
                rowClick.Name = "RowClickArea"
                rowClick.Size = UDim2.fromScale(1, 1)
                rowClick.BackgroundTransparency = 1
                rowClick.Text = ""
                rowClick.AutoButtonColor = false
                rowClick.ZIndex = 4
                rowClick.Parent = row

                local actBtn = Instance.new("TextButton")
                actBtn.Size = UDim2.fromOffset(72, 28)
                actBtn.Position = UDim2.new(1, -82, 0.5, -14)
                actBtn.BackgroundColor3 = Color3.fromHex("#0284C7")
                actBtn.BackgroundTransparency = 0.2
                actBtn.Text = "RUN"
                actBtn.Font = Enum.Font.GothamBold
                actBtn.TextSize = 13
                actBtn.TextColor3 = Color3.fromHex("#FFFFFF")
                actBtn.TextStrokeTransparency = 0.65
                actBtn.TextStrokeColor3 = Color3.fromHex("#000000")
                actBtn.AutoButtonColor = false
                actBtn.ZIndex = 5
                actBtn.Parent = row

                local ac = Instance.new("UICorner")
                ac.CornerRadius = UDim.new(0, 8)
                ac.Parent = actBtn

                local as = Instance.new("UIStroke")
                as.Color = Color3.fromHex("#00E5FF")
                as.Thickness = 1.2
                as.Parent = actBtn

                local function fireAction()
                    TweenService:Create(actBtn, TweenInfo.new(0.08), { Size = UDim2.fromOffset(66, 25), BackgroundColor3 = Color3.fromHex("#00E5FF"), TextColor3 = Color3.fromHex("#020617") }):Play()
                    task.wait(0.08)
                    TweenService:Create(actBtn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(72, 28), BackgroundColor3 = Color3.fromHex("#0284C7"), TextColor3 = Color3.fromHex("#FFFFFF") }):Play()
                    task.spawn(callback)
                end

                actBtn.MouseEnter:Connect(function()
                    TweenService:Create(actBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#00E5FF") }):Play()
                    TweenService:Create(actBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromHex("#020617") }):Play()
                end)
                actBtn.MouseLeave:Connect(function()
                    TweenService:Create(actBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#0284C7") }):Play()
                    TweenService:Create(actBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromHex("#FFFFFF") }):Play()
                end)

                rowClick.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromHex("#0E2342"),
                        BackgroundTransparency = 0.1
                    }):Play()
                end)
                rowClick.MouseLeave:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromHex("#08182E"),
                        BackgroundTransparency = 0.2
                    }):Play()
                end)

                rowClick.MouseButton1Click:Connect(fireAction)
                actBtn.MouseButton1Click:Connect(fireAction)

                return { Button = actBtn, Row = row }
            end

            -- 5. PARAGRAPH (Live Stat Readout)
            function Section:Paragraph(cfg)
                cfg = cfg or {}
                local title = cfg.Title or "Info"
                local desc = cfg.Desc or ""
                local icon = cfg.Icon or "activity"

                local row = makeRow(54)
                makeRowIcon(row, icon)

                local tLbl = Instance.new("TextLabel")
                tLbl.Text = title
                tLbl.Font = Enum.Font.GothamBold
                tLbl.TextSize = 13
                tLbl.TextColor3 = Color3.fromHex("#00E5FF")
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Size = UDim2.new(1, -56, 0, 18)
                tLbl.Position = UDim2.new(0, 48, 0, 8)
                tLbl.BackgroundTransparency = 1
                tLbl.Parent = row

                local dLbl = Instance.new("TextLabel")
                dLbl.Text = desc
                dLbl.Font = Enum.Font.Gotham
                dLbl.TextSize = 11
                dLbl.TextColor3 = Color3.fromHex("#94A3B8")
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.TextWrapped = true
                dLbl.Size = UDim2.new(1, -56, 0, 24)
                dLbl.Position = UDim2.new(0, 48, 0, 26)
                dLbl.BackgroundTransparency = 1
                dLbl.Parent = row

                local function setTitle(selfOrText, maybeText)
                    local text = (type(selfOrText) == "table" and maybeText) or selfOrText
                    tLbl.Text = tostring(text or "")
                end

                local function setDesc(selfOrText, maybeText)
                    local text = (type(selfOrText) == "table" and maybeText) or selfOrText
                    dLbl.Text = tostring(text or "")
                end

                return {
                    SetTitle = setTitle,
                    SetDesc = setDesc,
                    SetContent = setDesc,
                    SetText = setDesc,
                    TitleLabel = tLbl,
                    DescLabel = dLbl,
                    Row = row
                }
            end

            -- 6. INPUT (Text Box / Config Input)
            function Section:Input(cfg)
                cfg = cfg or {}
                local title = cfg.Title or "Input"
                local desc = cfg.Desc or ""
                local icon = cfg.Icon or "pencil"
                local placeholder = cfg.Placeholder or "พิมพ์ข้อความ..."
                local default = cfg.Default or ""
                local callback = cfg.Callback or function() end

                local row = makeRow(52)
                makeRowIcon(row, icon)
                makeRowTexts(row, title, desc, 160)

                local boxContainer = Instance.new("Frame")
                boxContainer.Size = UDim2.fromOffset(145, 30)
                boxContainer.Position = UDim2.new(1, -155, 0.5, -15)
                boxContainer.BackgroundColor3 = Color3.fromHex("#081A33")
                boxContainer.BackgroundTransparency = 0.2
                boxContainer.Parent = row

                local bc = Instance.new("UICorner")
                bc.CornerRadius = UDim.new(0, 8)
                bc.Parent = boxContainer

                local bs = Instance.new("UIStroke")
                bs.Color = Color3.fromHex("#00E5FF")
                bs.Thickness = 1.2
                bs.Transparency = 0.6
                bs.Parent = boxContainer

                local tBox = Instance.new("TextBox")
                tBox.Size = UDim2.new(1, -16, 1, 0)
                tBox.Position = UDim2.new(0, 8, 0, 0)
                tBox.BackgroundTransparency = 1
                tBox.Text = default
                tBox.PlaceholderText = placeholder
                tBox.PlaceholderColor3 = Color3.fromHex("#64748B")
                tBox.Font = Enum.Font.GothamBold
                tBox.TextSize = 11
                tBox.TextColor3 = Color3.fromHex("#FFFFFF")
                tBox.ClearTextOnFocus = false
                tBox.TextXAlignment = Enum.TextXAlignment.Left
                tBox.Parent = boxContainer

                tBox.FocusLost:Connect(function(enterPressed)
                    task.spawn(callback, tBox.Text, enterPressed)
                end)

                local function updateInput(selfOrVal, maybeVal)
                    local v = (maybeVal ~= nil) and maybeVal or selfOrVal
                    if type(selfOrVal) == "table" and selfOrVal.Row ~= nil and maybeVal ~= nil then
                        v = maybeVal
                    end
                    tBox.Text = tostring(v or "")
                    task.spawn(callback, tBox.Text)
                end

                return {
                    GetValue = function() return tBox.Text end,
                    SetValue = updateInput,
                    Set = updateInput,
                    TextBox = tBox,
                    Row = row
                }
            end

            -- Pass-through aliases directly onto Tab if preferred
            Tab.Toggle = function(_, c) return Section:Toggle(c) end
            Tab.Slider = function(_, c) return Section:Slider(c) end
            Tab.Dropdown = function(_, c) return Section:Dropdown(c) end
            Tab.Button = function(_, c) return Section:Button(c) end
            Tab.Paragraph = function(_, c) return Section:Paragraph(c) end
            Tab.Input = function(_, c) return Section:Input(c) end

            return Section
        end

        table.insert(self.Tabs, Tab)
        if #self.Tabs == 1 then
            Tab:Select()
        end
        return Tab
    end

    function Window:SelectTab(idx)
        if typeof(idx) == "number" and self.Tabs[idx] then
            self.Tabs[idx]:Select()
        elseif typeof(idx) == "string" then
            for _, t in ipairs(self.Tabs) do
                if t.Title == idx then t:Select() break end
            end
        end
    end

    -- ─────────────────────────────────────────────────────────
    -- FLOATING LOGO TOGGLE BADGE (CYBER AURA + NEON GRADIENT)
    -- ─────────────────────────────────────────────────────────
    local floatGui = Instance.new("ScreenGui")
    floatGui.Name = "TwoK_Pyramid_Float"
    floatGui.ResetOnSpawn = false
    floatGui.Parent = container

    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "AuraRing"
    auraFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    local defaultFloatPos = isMobile and UDim2.new(0, 24, 0.45, 0) or UDim2.new(0, 168, 0, 26)
    auraFrame.Size = UDim2.fromOffset(68, 68)
    auraFrame.Position = defaultFloatPos
    auraFrame.BackgroundColor3 = Color3.fromHex("#00E5FF")
    auraFrame.BackgroundTransparency = 0.82
    auraFrame.BorderSizePixel = 0
    auraFrame.Parent = floatGui

    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(0, 18)
    auraCorner.Parent = auraFrame

    local auraStroke = Instance.new("UIStroke")
    auraStroke.Color = Color3.fromHex("#00D4FF")
    auraStroke.Thickness = 1.2
    auraStroke.Transparency = 0.65
    auraStroke.Parent = auraFrame

    local panelFrame = Instance.new("Frame")
    panelFrame.Name = "LogoPanel"
    panelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    panelFrame.Size = UDim2.fromOffset(50, 50)
    panelFrame.Position = defaultFloatPos
    panelFrame.BackgroundColor3 = Color3.fromHex("#060E18")
    panelFrame.BackgroundTransparency = 0.15
    panelFrame.BorderSizePixel = 0
    panelFrame.Parent = floatGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 14)
    panelCorner.Parent = panelFrame

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromHex("#00E5FF")
    panelStroke.Thickness = 1.8
    panelStroke.Parent = panelFrame

    local panelGrad = Instance.new("UIGradient")
    panelGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHex("#00E5FF")),
        ColorSequenceKeypoint.new(0.35, Color3.fromHex("#0077FE")),
        ColorSequenceKeypoint.new(0.70, Color3.fromHex("#38BDF8")),
        ColorSequenceKeypoint.new(1.00, Color3.fromHex("#00E5FF"))
    })
    panelGrad.Parent = panelStroke

    _G.TwoSkiFloatGui = floatGui
    _G.TwoSkiFloatPanel = panelFrame
    _G.TwoSkiFloatAura = auraFrame

    local floatBtn = Instance.new("ImageButton")
    floatBtn.Name = "OpenButton"
    floatBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    floatBtn.Size = UDim2.fromOffset(40, 40)
    floatBtn.Position = UDim2.fromScale(0.5, 0.5)
    floatBtn.BackgroundTransparency = 1
    floatBtn.Image = "rbxassetid://10723346959"
    floatBtn.ImageColor3 = Color3.fromHex("#00E5FF")
    floatBtn.Parent = panelFrame

    task.spawn(function()
        local logoAsset = ensureAsset("2k_logo.png", "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/assets/2k_logo.png")
        if logoAsset then
            floatBtn.Image = logoAsset
            floatBtn.ImageColor3 = Color3.new(1, 1, 1)
        end
    end)

    -- Draggable Floating Badge (Smooth drag with rock-solid click/tap toggle)
    local fDragging = false
    local fDragStart = Vector3.new()
    local fStartPos = panelFrame.Position
    local fClickTick = 0
    local lastFloatToggleTick = 0

    local function handleFloatToggle()
        local now = tick()
        if now - lastFloatToggleTick < 0.25 then return end
        lastFloatToggleTick = now
        Window:Toggle()
    end

    local function onFloatDragStart(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fDragging = true
            fDragStart = input.Position
            fStartPos = panelFrame.Position
            fClickTick = tick()
        end
    end

    panelFrame.InputBegan:Connect(onFloatDragStart)
    floatBtn.InputBegan:Connect(onFloatDragStart)

    UserInputService.InputChanged:Connect(function(input)
        if fDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - fDragStart
            if delta.Magnitude > 3 then
                local newPos = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + delta.X, fStartPos.Y.Scale, fStartPos.Y.Offset + delta.Y)
                panelFrame.Position = newPos
                auraFrame.Position = newPos
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if fDragging then
                fDragging = false
                local dist = (input.Position - fDragStart).Magnitude
                local elapsed = tick() - fClickTick
                if dist <= 8 and elapsed <= 0.5 then
                    handleFloatToggle()
                end
            end
        end
    end)

    floatBtn.Activated:Connect(handleFloatToggle)

    -- Keybind Toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Keybind then
            Window:Toggle()
        end
    end)

    -- Continuous Cyber Render Loop
    local animConn = RunService.RenderStepped:Connect(function()
        local t = tick()
        -- Main window border sweep
        strokeGrad.Rotation = (t * 50) % 360
        -- Floating logo border sweep
        panelGrad.Rotation = (t * 110) % 360
        -- Floating aura breathing pulse
        local breath = (math.sin(t * 3.2) + 1) * 0.5
        local auraSize = 68 + (breath * 12)
        auraFrame.Size = UDim2.fromOffset(auraSize, auraSize)
        auraFrame.BackgroundTransparency = 0.80 + (breath * 0.12)
        -- Subtle logo bobbing inside badge
        floatBtn.Position = UDim2.new(0.5, 0, 0.5, math.sin(t * 2.8) * 1.5)
    end)

    Window.AnimationConnection = animConn
    Window.FloatGui = floatGui

    function Window:Notify(notifCfg)
        notifCfg = notifCfg or {}
        local nTitle = notifCfg.Title or "2K SCRIPT"
        local nContent = notifCfg.Content or ""
        local nDuration = notifCfg.Duration or 4

        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.fromOffset(280, 56)
        notifFrame.AnchorPoint = Vector2.new(1, 1)
        notifFrame.Position = UDim2.new(1, -20, 1, 80)
        notifFrame.BackgroundColor3 = Color3.fromHex("#061226")
        notifFrame.BackgroundTransparency = 0.15
        notifFrame.Parent = screenGui

        local nc = Instance.new("UICorner")
        nc.CornerRadius = UDim.new(0, 10)
        nc.Parent = notifFrame
        local ns = Instance.new("UIStroke")
        ns.Color = Color3.fromHex("#00E5FF")
        ns.Thickness = 1.4
        ns.Parent = notifFrame

        local nt = Instance.new("TextLabel")
        nt.Text = nTitle
        nt.Font = Enum.Font.GothamBold
        nt.TextSize = 13
        nt.TextColor3 = Color3.fromHex("#00E5FF")
        nt.TextXAlignment = Enum.TextXAlignment.Left
        nt.Size = UDim2.new(1, -20, 0, 18)
        nt.Position = UDim2.new(0, 12, 0, 8)
        nt.BackgroundTransparency = 1
        nt.Parent = notifFrame

        local nd = Instance.new("TextLabel")
        nd.Text = nContent
        nd.Font = Enum.Font.Gotham
        nd.TextSize = 11
        nd.TextColor3 = Color3.fromHex("#E2E8F0")
        nd.TextXAlignment = Enum.TextXAlignment.Left
        nd.TextTruncate = Enum.TextTruncate.AtEnd
        nd.Size = UDim2.new(1, -20, 0, 18)
        nd.Position = UDim2.new(0, 12, 0, 28)
        nd.BackgroundTransparency = 1
        nd.Parent = notifFrame

        TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -20, 1, -20)
        }):Play()

        task.delay(nDuration, function()
            local tw = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, -20, 1, 80)
            })
            tw:Play()
            tw.Completed:Connect(function()
                notifFrame:Destroy()
            end)
        end)
    end

    table.insert(self.Windows, Window)
    self.ActiveWindow = Window
    return Window
end

function TwoKUI:Notify(cfg)
    if self.ActiveWindow and self.ActiveWindow.Notify then
        return self.ActiveWindow:Notify(cfg)
    end
end

function TwoKUI:SetTheme(_)
    -- Custom Theme Switcher
end

return TwoKUI
end)()

-- Create 2K Cyber-Neon Obsidian Window
local Window = TwoKUI:CreateWindow({
    Title = "2K SCRIPT",
    SubTitle = "+1 ของรางวัลที่จะหลอม (LOOT TO FORGE) X2",
    Size = UDim2.fromOffset(880, 520),
    Keybind = Enum.KeyCode.LeftControl
})

_G.TwoSkiWindow = Window

-- WindUI Notify Compatibility Adapter
local WindUI = {
    Notify = function(self, opt)
        if Window and Window.Notify then
            Window:Notify({
                Title = opt.Title or "2K SCRIPT",
                Content = opt.Content or "",
                Duration = opt.Duration or 3
            })
        end
    end,
    SetTheme = function() end,
    AddTheme = function() end
}

-- Configuration & Persistence Engine
local CONFIG_FILE = "2SKI_LootToForge_Config.json"
local saveDebounce = false
local isLoadingConfig = false

local function fileExists(path)
    if isfile then
        local ok, res = pcall(function() return isfile(path) end)
        if ok and res then return true end
    end
    if readfile then
        local ok, data = pcall(function() return readfile(path) end)
        if ok and data and #data > 2 then return true end
    end
    return false
end

local function saveConfig(silent)
    if isLoadingConfig then return false end
    local clean = {}
    for k, v in pairs(State) do
        local t = type(v)
        if t == "boolean" or t == "number" or t == "string" then
            clean[k] = v
        elseif t == "table" then
            -- Guard against UI control objects!
            if v.Row == nil and v.SetValue == nil and v.GetValue == nil and v.SetValues == nil then
                local arr = {}
                for idx, item in pairs(v) do
                    if type(item) == "string" or type(item) == "number" or type(item) == "boolean" then
                        arr[idx] = item
                    end
                end
                clean[k] = arr
            end
        end
    end

    local ok = false
    local encoded = ""
    pcall(function() encoded = HttpService:JSONEncode(clean) end)
    if writefile and encoded ~= "" then
        ok = pcall(function() writefile(CONFIG_FILE, encoded) end)
    end
    _G.TwoSkiSavedConfig = clean

    if not silent and _G.TwoSkiLoaded and WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "2K CONFIG",
            Content = "บันทึกการตั้งค่าลงเครื่องเรียบร้อย!",
            Duration = 2.5
        })
    end
    return ok
end

local function autoSaveConfig()
    if isLoadingConfig then return end
    if State.AutoSaveConfig == false then return end
    if saveDebounce then return end
    saveDebounce = true
    task.delay(0.5, function()
        saveDebounce = false
        saveConfig(true)
    end)
end

local function loadConfig(silent)
    local parsed = nil
    if fileExists(CONFIG_FILE) and readfile then
        local ok, data = pcall(function() return readfile(CONFIG_FILE) end)
        if ok and data and #data > 2 then
            local okDecode, res = pcall(function() return HttpService:JSONDecode(data) end)
            if okDecode and type(res) == "table" then
                parsed = res
            end
        end
    end
    if not parsed and _G.TwoSkiSavedConfig then
        parsed = _G.TwoSkiSavedConfig
    end

    if parsed then
        isLoadingConfig = true
        for k, v in pairs(parsed) do
            if State[k] ~= nil then
                -- Guard against corrupt UI control tables
                local isValid = true
                if type(v) == "table" then
                    if v.Row ~= nil or v.SetValue ~= nil or v.GetValue ~= nil or v.SetValues ~= nil then
                        isValid = false
                    end
                end

                if isValid then
                    if k == "CustomUIScale" and type(v) == "number" then
                        local scaleFrac = (v <= 2.0) and v or (v / 100)
                        if not isMobile and scaleFrac < 0.60 then
                            scaleFrac = 1.00
                        end
                        scaleFrac = math.clamp(scaleFrac, 0.40, 1.25)
                        State.CustomUIScale = scaleFrac
                        _G.TwoSkiCustomScale = scaleFrac
                        if Window and Window.SetScale then
                            Window:SetScale(scaleFrac)
                        elseif Window and Window.UIScale then
                            Window.UIScale.Scale = scaleFrac
                        end
                        if UIControls[k] and UIControls[k].SetValue then
                            pcall(function() UIControls[k]:SetValue(math.floor(scaleFrac * 100)) end)
                        end
                    else
                        State[k] = v
                        if UIControls[k] then
                            pcall(function()
                                if UIControls[k].SetValue then
                                    UIControls[k]:SetValue(v)
                                elseif UIControls[k].Set then
                                    UIControls[k]:Set(v)
                                elseif UIControls[k].Select then
                                    UIControls[k]:Select(v)
                                end
                            end)
                        end
                    end
                end
            end
        end
        if State.CurrentTheme and applyThemePreset then
            pcall(function() applyThemePreset(State.CurrentTheme) end)
        end
        task.delay(0.6, function()
            isLoadingConfig = false
        end)

        if not silent and _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K CONFIG",
                Content = "โหลดการตั้งค่าเรียบร้อย!",
                Duration = 2.5
            })
        end
        return true
    else
        if not silent and _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K CONFIG",
                Content = "ยังไม่มีการตั้งค่าที่บันทึกไว้ (กรุณากดบันทึกก่อน)",
                Duration = 3
            })
        end
        return false
    end
end

-- Auto-Save Tab Wrapper (Wraps all UI controls)
local function wrapTabWithAutoSave(tab)
    if not tab then return tab end
    local oldToggle = tab.Toggle
    if oldToggle then
        tab.Toggle = function(self, opt)
            opt = opt or {}
            local origCb = opt.Callback
            opt.Callback = function(val)
                if origCb then origCb(val) end
                autoSaveConfig()
            end
            return oldToggle(self, opt)
        end
    end
    local oldSlider = tab.Slider
    if oldSlider then
        tab.Slider = function(self, opt)
            opt = opt or {}
            local origCb = opt.Callback
            opt.Callback = function(val)
                if origCb then origCb(val) end
                autoSaveConfig()
            end
            return oldSlider(self, opt)
        end
    end
    local oldDropdown = tab.Dropdown
    if oldDropdown then
        tab.Dropdown = function(self, opt)
            opt = opt or {}
            local origCb = opt.Callback
            opt.Callback = function(val)
                if origCb then origCb(val) end
                autoSaveConfig()
            end
            return oldDropdown(self, opt)
        end
    end
    return tab
end


-- ─────────────────────────────────────────────────────────────
-- [[ 2K BACKPACK VISUAL ENGINE & LIVE REALTIME SYNC ]]
-- Eliminates invisible ores, table drops, and syncs counts at 10Hz
-- ─────────────────────────────────────────────────────────────

local function applyBackpackVisualEngine()
    pcall(function()
        local AnyHelper = require(ReplicatedStorage.Config.AnyHelper)
        local MatHelper = nil
        pcall(function() MatHelper = require(ReplicatedStorage.Config.Material.Helper) end)
        local MatShow = nil
        pcall(function() MatShow = require(ReplicatedStorage.Config.Material.Show) end)
        local MatConfig = nil
        pcall(function() MatConfig = require(ReplicatedStorage.Config.Material.Config) end)
        local OreHelper = nil
        pcall(function() OreHelper = require(ReplicatedStorage.Config.Ore.Helper) end)
        local EnchHelper = nil
        pcall(function() EnchHelper = require(ReplicatedStorage.Config.EnchStone.Helper) end)
        local WeaponHelper = nil
        pcall(function() WeaponHelper = require(ReplicatedStorage.Config.Weapon.Helper) end)
        local ArmorHelper = nil
        pcall(function() ArmorHelper = require(ReplicatedStorage.Config.Armor.Helper) end)
        local RarityHelper = nil
        pcall(function() RarityHelper = require(ReplicatedStorage.Config.Rarity.Helper) end)
        local AbbNumber = nil
        pcall(function() AbbNumber = require(ReplicatedStorage.Utils.AbbNumber) end)
        local BackpackData = require(ReplicatedStorage.LocalData.BackpackData)
        local BackpackGUI = nil
        pcall(function() BackpackGUI = require(ReplicatedStorage.GuiUtils.BackpackGUI) end)

        -- 1. Inventory Sanitizer: Merge table-ID ghost drops into real Material Ember Stone
        local function sanitizeBackpackData()
            local bp = BackpackData and BackpackData.GetData()
            if not bp or not bp.have then return end

            local corruptOreCount = 0
            local toRemove = {}
            for k, v in pairs(bp.have) do
                if v.Type == "Ore" and type(v.ID) == "table" then
                    corruptOreCount = corruptOreCount + (v.Number or 0)
                    table.insert(toRemove, k)
                end
            end

            if corruptOreCount > 0 then
                local merged = false
                for _, v in pairs(bp.have) do
                    if v.Type == "Material" and v.ID == "EnhantStone_1" then
                        v.Number = (v.Number or 0) + corruptOreCount
                        merged = true
                        break
                    end
                end
                if not merged then
                    bp.have["SSS-CLEAN-EMBER-1"] = {
                        ID = "EnhantStone_1",
                        Type = "Material",
                        Number = corruptOreCount,
                        Equip = false,
                        Lock = false,
                        Level = 1
                    }
                end
                for _, k in ipairs(toRemove) do
                    bp.have[k] = nil
                end

                -- Destroy orphan frames from GUI
                local bpGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Backpack")
                local scroll = bpGui and bpGui:FindFirstChild("Main") and bpGui.Main:FindFirstChild("Right") and bpGui.Main.Right:FindFirstChild("Bg") and bpGui.Main.Right.Bg:FindFirstChild("ScrollingFrame")
                if scroll then
                    for _, k in ipairs(toRemove) do
                        local cell = scroll:FindFirstChild(k)
                        if cell then cell:Destroy() end
                    end
                end
            end
        end

        -- 2. Safeguard Material.Helper against nil indexing crashes
        if MatHelper and MatShow and not _G._TwoK_MatHelperProtected then
            _G._TwoK_MatHelperProtected = true
            MatHelper.GetImage = function(id)
                if id and MatShow[id] then return MatShow[id].Image end
                return nil
            end
            MatHelper.GetDisName = function(id)
                if id and MatShow[id] then return MatShow[id].DisplayName end
                return nil
            end
            MatHelper.GetRarity = function(id)
                if id and MatConfig and MatConfig[id] then return MatConfig[id].Rarity end
                return nil
            end
            MatHelper.GetDescription = function(id)
                if id and MatShow[id] then return MatShow[id].Description end
                return nil
            end
        end

        -- 3. Robust Resolver for Item Types & IDs
        local function resolveItemIdentity(itemType, itemId)
            local aType = itemType or "Material"
            local aId = itemId
            if type(itemId) == "table" then
                aId = itemId.ID or itemId.Name or itemId
                aType = itemId.Type or itemType or "Material"
            end
            return aType, tostring(aId)
        end

        local origGetImage = AnyHelper.GetImage
        local origGetDisName = AnyHelper.GetDisName
        local origGetRarity = AnyHelper.GetRarity
        local origGetPrice = AnyHelper.GetPrice

        local function safeResolveImage(itemType, itemId)
            local aType, aId = resolveItemIdentity(itemType, itemId)
            local img = nil
            pcall(function() img = origGetImage(aType, aId) end)
            if img and img ~= "" then return img end

            pcall(function() if MatHelper and MatHelper.GetImage then img = MatHelper.GetImage(aId) end end)
            if img and img ~= "" then return img end
            pcall(function() if OreHelper and OreHelper.GetImage then img = OreHelper.GetImage(aId) end end)
            if img and img ~= "" then return img end
            pcall(function() if EnchHelper and EnchHelper.GetImage then img = EnchHelper.GetImage(aId) end end)
            if img and img ~= "" then return img end
            pcall(function() if WeaponHelper and WeaponHelper.GetImage then img = WeaponHelper.GetImage(aId) end end)
            if img and img ~= "" then return img end
            pcall(function() if ArmorHelper and ArmorHelper.GetImage then img = ArmorHelper.GetImage(aId) end end)
            if img and img ~= "" then return img end

            return "rbxassetid://93499783424371"
        end

        local function safeResolveDisName(itemType, itemId)
            local aType, aId = resolveItemIdentity(itemType, itemId)
            local name = nil
            pcall(function() name = origGetDisName(aType, aId) end)
            if name and name ~= "" then return name end

            pcall(function() if MatHelper and MatHelper.GetDisName then name = MatHelper.GetDisName(aId) end end)
            if name and name ~= "" then return name end
            pcall(function() if OreHelper and OreHelper.GetDisName then name = OreHelper.GetDisName(aId) end end)
            if name and name ~= "" then return name end
            pcall(function() if EnchHelper and EnchHelper.GetDisName then name = EnchHelper.GetDisName(aId) end end)
            if name and name ~= "" then return name end
            pcall(function() if WeaponHelper and WeaponHelper.GetDisName then name = WeaponHelper.GetDisName(aId) end end)
            if name and name ~= "" then return name end
            pcall(function() if ArmorHelper and ArmorHelper.GetDisName then name = ArmorHelper.GetDisName(aId) end end)
            if name and name ~= "" then return name end

            return aId
        end

        local function safeResolveRarity(itemType, itemId)
            local aType, aId = resolveItemIdentity(itemType, itemId)
            local rar = nil
            pcall(function() rar = origGetRarity(aType, aId) end)
            if rar and rar ~= "" then return rar end

            pcall(function() if MatHelper and MatHelper.GetRarity then rar = MatHelper.GetRarity(aId) end end)
            if rar and rar ~= "" then return rar end
            pcall(function() if OreHelper and OreHelper.GetRarity then rar = OreHelper.GetRarity(aId) end end)
            if rar and rar ~= "" then return rar end

            return "Legendary"
        end

        local function safeResolvePrice(itemType, itemId)
            local aType, aId = resolveItemIdentity(itemType, itemId)
            local price = nil
            pcall(function() price = origGetPrice(aType, aId) end)
            if price and price > 0 then return price end
            return 50000
        end

        -- 4. Hook AnyHelper permanently
        if not _G._TwoK_AnyHelperHooked then
            _G._TwoK_AnyHelperHooked = true
            AnyHelper.GetImage = safeResolveImage
            AnyHelper.GetDisName = safeResolveDisName
            AnyHelper.GetRarity = safeResolveRarity
            AnyHelper.GetPrice = safeResolvePrice
        end

        -- 5. Real-Time Zero-Flicker Cell Healer
        local isHealing = false
        local function healBackpackFrames()
            if isHealing then return end
            isHealing = true
            sanitizeBackpackData()

            local bpGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Backpack")
            if not bpGui then isHealing = false; return end
            local scroll = bpGui:FindFirstChild("Main") and bpGui.Main:FindFirstChild("Right") and bpGui.Main.Right:FindFirstChild("Bg") and bpGui.Main.Right.Bg:FindFirstChild("ScrollingFrame")
            if not scroll then isHealing = false; return end

            for _, cell in ipairs(scroll:GetChildren()) do
                if cell:IsA("Frame") and cell.Visible then
                    local item = BackpackData.GetItemData(cell.Name)
                    if item then
                        local btn = cell:FindFirstChild("Button")
                        if btn then
                            local frame = btn:FindFirstChild("Frame")
                            if frame then
                                local imgLabel = frame:FindFirstChild("ImageLabel")
                                if imgLabel and (imgLabel.Image == "" or not imgLabel.Image) then
                                    imgLabel.Image = safeResolveImage(item.Type, item.ID)
                                end
                                local zi = frame:FindFirstChild("zi")
                                if zi then
                                    local atkLabel = zi:FindFirstChild("ATK")
                                    if atkLabel and (atkLabel.Text == "" or not atkLabel.Text) then
                                        atkLabel.Text = safeResolveDisName(item.Type, item.ID)
                                    end
                                    local priceLabel = zi:FindFirstChild("Price")
                                    if priceLabel and (priceLabel.Text == "" or not priceLabel.Text) then
                                        local price = safeResolvePrice(item.Type, item.ID)
                                        local priceStr = AbbNumber and AbbNumber.AbbreviateNumber and AbbNumber.AbbreviateNumber(price) or tostring(price)
                                        priceLabel.Text = "Price:" .. priceStr
                                    end
                                end
                                -- Only set gradient ONCE if missing
                                if not frame:FindFirstChild("UIQIU") and RarityHelper and RarityHelper.SetUIQiu then
                                    pcall(function()
                                        local rarity = safeResolveRarity(item.Type, item.ID)
                                        RarityHelper.SetUIQiu(frame, rarity)
                                    end)
                                end

                                -- Live-Sync Quantity TextLabel with real balance
                                local qty = frame:FindFirstChild("Quantity")
                                local qtyLabel = qty and qty:FindFirstChild("TextLabel")
                                if qtyLabel and item.Number then
                                    local numStr = AbbNumber and AbbNumber.AbbreviateNumber and AbbNumber.AbbreviateNumber(item.Number) or tostring(item.Number)
                                    local expectedText = "x" .. tostring(numStr)
                                    if qtyLabel.Text ~= expectedText then
                                        qtyLabel.Text = expectedText
                                    end
                                    qty.Visible = (item.Number > 1)
                                end
                            end
                        end
                    end
                end
            end
            isHealing = false
        end

        _G._TwoK_HealBackpack = healBackpackFrames

        -- 6. Hook BackpackGUI: Auto-sync on open, tab switch, material click, and filter Ore tab
        if BackpackGUI then
            local origOpen = _G._TwoK_OrigBackpackOpen or BackpackGUI.open
            _G._TwoK_OrigBackpackOpen = origOpen
            BackpackGUI.open = function(...)
                if origOpen then origOpen(...) end
                pcall(function()
                    if BackpackGUI.UpdateBackpack then
                        BackpackGUI.UpdateBackpack()
                    end
                    healBackpackFrames()
                end)
            end

            local origOpenScroList = _G._TwoK_OrigBackpackScroList or BackpackGUI.OpenItemScroList
            _G._TwoK_OrigBackpackScroList = origOpenScroList
            BackpackGUI.OpenItemScroList = function(tabName)
                sanitizeBackpackData()
                if origOpenScroList then origOpenScroList(tabName) end
                if tabName == "Ore" then
                    local bpGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Backpack")
                    local scroll = bpGui and bpGui:FindFirstChild("Main") and bpGui.Main:FindFirstChild("Right") and bpGui.Main.Right:FindFirstChild("Bg") and bpGui.Main.Right.Bg:FindFirstChild("ScrollingFrame")
                    if scroll then
                        for _, cell in ipairs(scroll:GetChildren()) do
                            if cell:IsA("Frame") then
                                local item = BackpackData.GetItemData(cell.Name)
                                if item and (item.Type ~= "Ore" or type(item.ID) == "table") then
                                    cell.Visible = false
                                end
                            end
                        end
                    end
                end
                task.defer(healBackpackFrames)
            end

            local origOpenMaterialInfo = _G._TwoK_OrigBackpackOpenMat or BackpackGUI.OpenMaterialInfo
            _G._TwoK_OrigBackpackOpenMat = origOpenMaterialInfo
            BackpackGUI.OpenMaterialInfo = function(uuid)
                _G._TwoK_SelectedMaterialUUID = uuid
                if origOpenMaterialInfo then origOpenMaterialInfo(uuid) end
            end

            local origCloseMaterialInfo = _G._TwoK_OrigBackpackCloseMat or BackpackGUI.CloseMaterialInfo
            _G._TwoK_OrigBackpackCloseMat = origCloseMaterialInfo
            BackpackGUI.CloseMaterialInfo = function(...)
                _G._TwoK_SelectedMaterialUUID = nil
                if origCloseMaterialInfo then origCloseMaterialInfo(...) end
            end

            local origUpdateItemFrame = _G._TwoK_OrigBackpackUpdateFrame or BackpackGUI.UpdateItemFrame
            _G._TwoK_OrigBackpackUpdateFrame = origUpdateItemFrame
            BackpackGUI.UpdateItemFrame = function(uuid, itemData)
                if origUpdateItemFrame then origUpdateItemFrame(uuid, itemData) end
                pcall(function()
                    local item = itemData or BackpackData.GetItemData(uuid)
                    if item and item.Number then
                        local bpGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Backpack")
                        local scroll = bpGui and bpGui:FindFirstChild("Main") and bpGui.Main:FindFirstChild("Right") and bpGui.Main.Right:FindFirstChild("Bg") and bpGui.Main.Right.Bg:FindFirstChild("ScrollingFrame")
                        local cell = scroll and scroll:FindFirstChild(uuid)
                        local qty = cell and cell:FindFirstChild("Button") and cell.Button:FindFirstChild("Frame") and cell.Button.Frame:FindFirstChild("Quantity")
                        local qtyLabel = qty and qty:FindFirstChild("TextLabel")
                        if qtyLabel then
                            local numStr = AbbNumber and AbbNumber.AbbreviateNumber and AbbNumber.AbbreviateNumber(item.Number) or tostring(item.Number)
                            local expectedText = "x" .. tostring(numStr)
                            if qtyLabel.Text ~= expectedText then
                                qtyLabel.Text = expectedText
                            end
                            qty.Visible = (item.Number > 1)
                        end
                    end
                end)
            end
        end

        -- 7. Life-Cycle Event Handlers & Real-Time Live Watcher Loop (10Hz Instant Tick)
        BackpackData.AddCallback(function()
            task.defer(healBackpackFrames)
        end)
        local ProfileData = require(ReplicatedStorage.ProfileData)
        if ProfileData and ProfileData.AddStoreCallback then
            ProfileData.AddStoreCallback("Backpack", function()
                task.defer(healBackpackFrames)
            end)
        end

        task.spawn(function()
            local bpGui = LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("Backpack")
            local scroll = bpGui:WaitForChild("Main"):WaitForChild("Right"):WaitForChild("Bg"):WaitForChild("ScrollingFrame")
            local matInfo = bpGui:WaitForChild("MaterialInfo", 5)

            scroll.ChildAdded:Connect(function()
                task.defer(healBackpackFrames)
            end)

            -- Continuous 100ms Live Quantity Sync whenever Backpack is visible
            while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
                if bpGui.Visible then
                    for _, cell in ipairs(scroll:GetChildren()) do
                        if cell:IsA("Frame") and cell.Visible then
                            local item = BackpackData.GetItemData(cell.Name)
                            if item and item.Number then
                                local btn = cell:FindFirstChild("Button")
                                local frame = btn and btn:FindFirstChild("Frame")
                                local qty = frame and frame:FindFirstChild("Quantity")
                                local qtyLabel = qty and qty:FindFirstChild("TextLabel")
                                if qtyLabel then
                                    local numStr = AbbNumber and AbbNumber.AbbreviateNumber and AbbNumber.AbbreviateNumber(item.Number) or tostring(item.Number)
                                    local target = "x" .. tostring(numStr)
                                    if qtyLabel.Text ~= target then
                                        qtyLabel.Text = target
                                    end
                                    if qty.Visible ~= (item.Number > 1) then
                                        qty.Visible = (item.Number > 1)
                                    end
                                end
                            end
                        end
                    end

                    -- Real-Time sync for Material Detail card if open
                    if matInfo and matInfo.Visible and _G._TwoK_SelectedMaterialUUID then
                        local selItem = BackpackData.GetItemData(_G._TwoK_SelectedMaterialUUID)
                        if selItem and selItem.Number then
                            local xinxi = matInfo:FindFirstChild("xinxi") and matInfo.xinxi:FindFirstChild("1")
                            local info = xinxi and xinxi:FindFirstChild("Info")
                            local numLabel = info and info:FindFirstChild("Number")
                            if numLabel then
                                local numStr = AbbNumber and AbbNumber.AbbreviateNumber and AbbNumber.AbbreviateNumber(selItem.Number) or tostring(selItem.Number)
                                local target = "x" .. tostring(numStr)
                                if numLabel.Text ~= target then
                                    numLabel.Text = target
                                end
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)

        sanitizeBackpackData()
        healBackpackFrames()

        -- 8. Safeguard ForgeGUI Ores Rendering
        pcall(function()
            local ForgeGUI = require(ReplicatedStorage.GuiUtils.ForgeGUI)
            if ForgeGUI and not _G._TwoK_ForgeGUIPatched then
                _G._TwoK_ForgeGUIPatched = true
                local oldCreateOreBtn = ForgeGUI.CreateOreButton
                ForgeGUI.CreateOreButton = function(uuid, itemData)
                    if not itemData or type(itemData.ID) == "table" or not (OreHelper and OreHelper.CheckID and OreHelper.CheckID(itemData.ID)) then
                        return nil
                    end
                    local ok, res = pcall(function()
                        return oldCreateOreBtn(uuid, itemData)
                    end)
                    if not ok then return nil end
                    return res
                end

                local oldUpdateRight = ForgeGUI.UpdateRight
                ForgeGUI.UpdateRight = function()
                    pcall(function()
                        if oldUpdateRight then oldUpdateRight() end
                    end)
                end
            end
        end)
    end)
end
applyBackpackVisualEngine()

-- Create Tabs (6 Core Categories)
local TabFarm = Window:Tab({ Title = "ฟาร์ม & ดันเจี้ยน", Icon = "swords" })
local TabMoney = Window:Tab({ Title = "เก็บเงิน & ขายของ", Icon = "coins" })
local TabForge = Window:Tab({ Title = "หลอม & อุปกรณ์", Icon = "hammer" })
local TabUpgrade = Window:Tab({ Title = "อัปเกรด & เกิดใหม่", Icon = "trending-up" })
local TabSpawner = Window:Tab({ Title = "เสกของ (God Spawner)", Icon = "sparkles" })
local TabFPS = Window:Tab({ Title = "Boost FPS (ลดแล็ก)", Icon = "gauge" })
local TabSettings = Window:Tab({ Title = "ตั้งค่า & ผู้เล่น (Settings)", Icon = "settings" })
local TabCommunity = Window:Tab({ Title = "Community", Icon = "ticket" })

TabFarm = wrapTabWithAutoSave(TabFarm)
TabMoney = wrapTabWithAutoSave(TabMoney)
TabForge = wrapTabWithAutoSave(TabForge)
TabUpgrade = wrapTabWithAutoSave(TabUpgrade)
TabSpawner = wrapTabWithAutoSave(TabSpawner)
TabFPS = wrapTabWithAutoSave(TabFPS)
TabSettings = wrapTabWithAutoSave(TabSettings)
TabCommunity = wrapTabWithAutoSave(TabCommunity)

-- TAB 1: ฟาร์มพลัง & แร่ (Power & Ore Auto-Farm)

local function updateLiveStatsDisplay()
    -- Live stats dashboard disabled per user request
end

TabFarm:Section({ Title = "ปั๊มพลัง & วิ่งลู่ x100 (Power Train & VIP x100)" })

UIControls.AutoTrain = TabFarm:Toggle({
    Title = "ปั๊มพลังอัตโนมัติ (Auto Train Power)",
    Value = State.AutoTrain,
    Callback = function(val)
        State.AutoTrain = val
        if val then
            State.AutoTrainX100 = false
        end
        if _G.TwoSkiLoaded then
            WindUI:Notify({ Title = "2SKI Farm", Content = val and "เริ่มระบบปั๊มพลังอัตโนมัติ (Auto Train)!" or "หยุดปั๊มพลัง" })
        end
    end
})

UIControls.AutoTrainX100 = TabFarm:Toggle({
    Title = "‍วิ่งบนลู่ / ยืนแท่น x100 Power (VIP Zone 9 )",
    Description = "ล็อกเป้าหมายแท่น x100 Power แบบ Bypass สมบูรณ์แบบ ไม่เด้งหน้าต่างซื้อ",
    Value = State.AutoTrainX100,
    Callback = function(val)
        State.AutoTrainX100 = val
        if val then
            State.AutoTrain = false
        end
        if _G.TwoSkiLoaded then
            WindUI:Notify({ Title = "2SKI x100 VIP", Content = val and "เริ่มระบบวิ่งลู่ x100 Power (VIP Zone 9)!" or "หยุดวิ่งลู่ x100" })
        end
    end
})

TabFarm:Section({ Title = "เคลียร์ด่าน & ดูดแร่อัตโนมัติ (Stage & Crystal Farm)" })

UIControls.AutoClearStage = TabFarm:Toggle({
    Title = "เคลียร์ด่านอัตโนมัติ (Auto Clear Stage)",
    Value = State.AutoClearStage,
    Callback = function(val)
        State.AutoClearStage = val
        if _G.TwoSkiLoaded then
            WindUI:Notify({ Title = "2SKI Stage", Content = val and ("เริ่มฟาร์มด่าน " .. tostring(State.SelectedStage) .. " อัตโนมัติ!") or "หยุดฟาร์มด่าน" })
        end
    end
})

UIControls.SelectedStage = TabFarm:Dropdown({
    Title = "เลือกด่านที่ต้องการฟาร์ม (Select Stage)",
    Values = getStageList(),
    Value = State.SelectedStage,
    Callback = function(val)
        State.SelectedStage = val
    end
})

UIControls.AutoCollectCrystals = TabFarm:Toggle({
    Title = "ดูดคริสตัล & แร่ในแมพอัตโนมัติ (Auto Collect Crystals)",
    Value = State.AutoCollectCrystals,
    Callback = function(val) State.AutoCollectCrystals = val end
})

UIControls.StageDelay = TabFarm:Slider({
    Title = "ดีเลย์รอบฟาร์มด่าน (วินาที)",
    Step = 0.05,
    Value = { Min = 0.15, Max = 2.0, Default = State.StageDelay },
    Callback = function(val) State.StageDelay = val end
})

TabFarm:Section({ Title = "ดันเจี้ยน & กิจกรรมพิเศษ (Dungeon & Boss)" })

UIControls.AutoDungeon = TabFarm:Toggle({
    Title = "ลงดันเจี้ยนอัตโนมัติ (Auto Dungeon)",
    Value = State.AutoDungeon,
    Callback = function(val)
        State.AutoDungeon = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2SKI Dungeon", Content = val and "เริ่มลงดันเจี้ยนอัตโนมัติ!" or "หยุดลงดันเจี้ยน" })
        end
    end
})

UIControls.TargetDungeonRound = TabFarm:Slider({
    Title = "เลือกรอบดันเจี้ยน (Target Round: 1-30)",
    Step = 1,
    Value = { Min = 1, Max = 30, Default = State.TargetDungeonRound or 30 },
    Callback = function(val)
        State.TargetDungeonRound = val
    end
})

UIControls.DungeonInstaKill = TabFarm:Toggle({
    Title = "กำจัดมอนสเตอร์ทันที (Insta-Kill Dungeon Mobs)",
    Value = State.DungeonInstaKill,
    Callback = function(val)
        State.DungeonInstaKill = val
    end
})

TabFarm:Button({
    Title = "⚡ เสก & ปั๊ม Token (5-Thread Fast Exploit)",
    Desc = "เปิดใช้งานระบบปั๊มเหรียญ Token ดันเจี้ยนแบบสปีดสูง 5 Threads ด่าน 50",
    Callback = function()
        if runDungeonTokenFarm then
            runDungeonTokenFarm(State.TokenDungeonRound or 50, State.TokenWorkers or 5)
        end
    end
})

UIControls.AutoKillSuperLoot = TabFarm:Toggle({
    Title = "ล่า SuperLoot อัตโนมัติ (Auto Kill SuperLoot)",
    Value = State.AutoKillSuperLoot,
    Callback = function(val)
        State.AutoKillSuperLoot = val
    end
})

UIControls.AutoWorldBoss = TabFarm:Toggle({
    Title = "ล่าบอสโลกอัตโนมัติ (Auto World Boss)",
    Value = State.AutoWorldBoss,
    Callback = function(val)
        State.AutoWorldBoss = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2SKI World Boss", Content = val and "เปิดระบบล่าบอสโลกอัตโนมัติ!" or "ปิดระบบล่าบอสโลก" })
        end
    end
})

TabFarm:Section({ Title = "บัพคูณพลังอัตโนมัติ (Auto 2x Buff Potions)" })

UIControls.AutoBuffPotions = TabFarm:Toggle({
    Title = "ดื่มน้ำยาบัพคูณพลังอัตโนมัติเมื่อหมดเวลา (Auto Drink Potions)",
    Value = State.AutoBuffPotions,
    Callback = function(val)
        State.AutoBuffPotions = val
        if val then
            autoDrinkPotionsNow()
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2SKI Potions", Content = "เปิดระบบดื่มน้ำยาบัพอัตโนมัติ (x2 ทุกค่า) เรียบร้อย!" })
            end
        end
    end
})

UIControls.AutoTrainPotion = TabFarm:Toggle({
    Title = "ดื่ม Train Potion (คูณพลังฝึก x2)",
    Value = State.AutoTrainPotion,
    Callback = function(val) State.AutoTrainPotion = val end
})

UIControls.AutoCoinPotion = TabFarm:Toggle({
    Title = "ดื่ม Coin Potion (คูณเงินดรอป x2)",
    Value = State.AutoCoinPotion,
    Callback = function(val) State.AutoCoinPotion = val end
})

UIControls.AutoLuckPotion = TabFarm:Toggle({
    Title = "ดื่ม Luck Potion (คูณดวงดรอปของเทพ x2)",
    Value = State.AutoLuckPotion,
    Callback = function(val) State.AutoLuckPotion = val end
})

TabFarm:Button({
    Title = "ตรวจสอบและดื่มน้ำยาบัพทันที (Drink Buff Potions Now)",
    Callback = function()
        local ok = autoDrinkPotionsNow()
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Potions",
                Content = ok and "ดื่มน้ำยาบัพคูณพลัง x2 สำเร็จ!" or "บัพยังคงทำงานอยู่ หรือไม่มีน้ำยาในกระเป๋า"
            })
        end
    end
})

-- TAB 2: เก็บเงิน & รางวัล (Money & Rewards Auto-Collect)

TabMoney:Section({ Title = "ระบบขายอุปกรณ์ขยะอัตโนมัติ (Auto Sell Gear Only)" })

UIControls.AutoSellGear = TabMoney:Toggle({
    Title = "ขายอุปกรณ์ขยะอัตโนมัติ (เฉพาะดาบ/เกราะ/หมวก ไม่แตะแร่)",
    Value = State.AutoSellGear or State.AutoSellAll,
    Callback = function(val)
        State.AutoSellGear = val
        State.AutoSellAll = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Gear Sell",
                Content = val and "เปิดระบบขายอุปกรณ์ขยะอัตโนมัติ (แร่และหินตีบวกปลอดภัย 100%)" or "ปิดระบบขายอุปกรณ์"
            })
        end
    end
})

UIControls.MinRarityToKeep = TabMoney:Dropdown({
    Title = "ระดับอุปกรณ์ที่จะเก็บไว้ ไม่ขายทิ้ง (Keep Gear Rarity)",
    Values = {
        "Infinite เท่านั้น (Keep Infinite Only)",
        "Ancient ขึ้นไป (Keep Ancient+)",
        "Secret ขึ้นไป (Keep Secret+)",
        "Eternal ขึ้นไป (Keep Eternal+)",
        "Mythic ขึ้นไป (Keep Mythic+)",
        "Legendary ขึ้นไป (Keep Legendary+)",
        "Epic ขึ้นไป (Keep Epic+)",
        "Rare ขึ้นไป (Keep Rare+)",
        "Uncommon ขึ้นไป (Keep Uncommon+)",
        "ขายทั้งหมดที่ไม่ใส่ (Sell All Non-Equipped)",
        "เก็บทั้งหมด (Keep All - ไม่ขายเกียร์)"
    },
    Value = State.MinRarityToKeep,
    Callback = function(val) State.MinRarityToKeep = val end
})

TabMoney:Button({
    Title = "สวมใส่ของโหดสุดแล้วขายอุปกรณ์ขยะทันที (Sell Trash Gear Now)",
    Callback = function()
        local count = sellTrashGearNow()
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Gear Sell",
                Content = "ขายอุปกรณ์ขยะไป " .. tostring(count) .. " ชิ้น (แร่และหินตีบวกปลอดภัย ไม่โดนขาย)!"
            })
        end
    end
})

TabMoney:Section({ Title = "ระบบขายแร่อัตโนมัติ (Auto Sell Ores Only - แยกอิสระ)" })

UIControls.AutoSellOres = TabMoney:Toggle({
    Title = "ขายแร่ที่หิ้วมาอัตโนมัติ (Auto Sell Ores)",
    Value = State.AutoSellOres,
    Callback = function(val)
        State.AutoSellOres = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Ore Sell",
                Content = val and "เปิดระบบขายแร่อัตโนมัติ!" or "ปิดระบบขายแร่"
            })
        end
    end
})

UIControls.OreFilterMode = TabMoney:Dropdown({
    Title = "โหมดตัวกรองแร่ (Filter Mode)",
    Values = {
        "เลือกระดับที่จะขายทิ้ง (Sell Selected)",
        "เลือกระดับที่จะเก็บไว้ (Keep Selected)"
    },
    Value = State.OreFilterMode or "เลือกระดับที่จะขายทิ้ง (Sell Selected)",
    Multi = false,
    Callback = function(val)
        State.OreFilterMode = val
    end
})

UIControls.OreRaritiesToKeep = TabMoney:Dropdown({
    Title = "เลือกระดับแร่ (Ore Rarities) - เลือกได้หลายระดับ",
    Values = {
        "Infinite",
        "Ancient",
        "Secret",
        "Eternal",
        "Mythic",
        "Legendary",
        "Epic",
        "Rare",
        "Uncommon",
        "Common"
    },
    Value = State.OreRaritiesToKeep,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        State.OreRaritiesToKeep = type(val) == "table" and val or {val}
    end
})

TabMoney:Button({
    Title = "ขายแร่ทันทีตามตัวกรอง (Sell Filtered Ores Now)",
    Callback = function()
        local count = sellOresNow()
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Ore Sell",
                Content = "ขายแร่ไป " .. tostring(count) .. " ชนิดเรียบร้อย!"
            })
        end
    end
})

TabMoney:Button({
    Title = "ขายแร่ทั้งหมดทันที ไม่สนระดับ (Sell All Carried Ores Now)",
    Callback = function()
        local count = sellAllOresNow()
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Ore Sell",
                Content = "ขายแร่ทั้งหมดไป " .. tostring(count) .. " ชนิด (ล้างแร่เกลี้ยงกระเป๋า)!"
            })
        end
    end
})

TabMoney:Section({ Title = "ระบบขายหินตีบวกอัตโนมัติ (Auto Sell Enchant Stones - แยกอิสระ)" })

UIControls.AutoSellEnchant = TabMoney:Toggle({
    Title = "ขายหินตีบวกอัตโนมัติ (Auto Sell Enchant Stones)",
    Value = State.AutoSellEnchant,
    Callback = function(val)
        State.AutoSellEnchant = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Enchant Sell",
                Content = val and "เปิดระบบขายหินตีบวกอัตโนมัติ (ตามเงื่อนไขที่เลือก)!" or "ปิดระบบขายหินตีบวก"
            })
        end
    end
})

UIControls.EnchantFilterMode = TabMoney:Dropdown({
    Title = "โหมดตัวกรองหินตีบวก (Enchant Filter Mode)",
    Values = {
        "เลือกระดับที่จะขายทิ้ง (Sell Selected)",
        "เลือกระดับที่จะเก็บไว้ (Keep Selected)"
    },
    Value = State.EnchantFilterMode,
    Callback = function(val)
        State.EnchantFilterMode = val
    end
})

UIControls.EnchantRarities = TabMoney:Dropdown({
    Title = "เลือกระดับหินตีบวก - ติ๊กได้หลายระดับ (Enchant Rarities)",
    Values = {
        "Infinite",
        "Ancient",
        "Mythic",
        "Legendary",
        "Epic",
        "Rare",
        "Uncommon",
        "Common"
    },
    Value = State.EnchantRarities,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        State.EnchantRarities = type(val) == "table" and val or {val}
    end
})

TabMoney:Button({
    Title = "ขายหินตีบวกทันที (ตามเงื่อนไขที่เลือก)",
    Callback = function()
        local count = sellEnchantStonesNow()
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Enchant Sell",
                Content = "ขายหินตีบวกไป " .. tostring(count) .. " ชิ้นเรียบร้อย!"
            })
        end
    end
})

TabMoney:Section({ Title = "ระบบเก็บเงินและของขวัญ (Auto Collect Money & Gifts)" })

UIControls.AutoCollectMoney = TabMoney:Toggle({
    Title = "เก็บเงิน & รับของขวัญอัตโนมัติ (ไม่ขายอุปกรณ์ / ไม่ขายแร่)",
    Value = State.AutoCollectMoney,
    Callback = function(val)
        State.AutoCollectMoney = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2SKI Money", Content = val and "เปิดระบบเก็บเงินและรับรางวัลอัตโนมัติ!" or "ปิดระบบเก็บเงิน" })
        end
    end
})

TabMoney:Section({ Title = "รับของขวัญและเงินออนไลน์ (Auto Gifts)" })

UIControls.AutoClaimOnline = TabMoney:Toggle({
    Title = "รับของขวัญออนไลน์ออโต้ (Auto Claim Online Gifts)",
    Value = State.AutoClaimOnline,
    Callback = function(val) State.AutoClaimOnline = val end
})

UIControls.AutoClaimGifts = TabMoney:Toggle({
    Title = "รับรางวัลอัปเดต & เงินออฟไลน์ (Loop Rewards)",
    Value = State.AutoClaimGifts,
    Callback = function(val) State.AutoClaimGifts = val end
})

TabMoney:Button({
    Title = "กดรับเงินและของขวัญทั้งหมดทันที (Claim All Coins Now)",
    Callback = function()
        pcall(function()
            if OnlineData and OnlineData.TryClaim then
                for i = 1, 12 do
                    OnlineData.TryClaim(tostring(i))
                    task.wait(0.02)
                end
            end
            if Remote_UpdateClaim then Remote_UpdateClaim:FireServer() end
            if Remote_OfflineClaim then Remote_OfflineClaim:FireServer() end
            if Remote_DungeonTicket then Remote_DungeonTicket:FireServer() end
            if Remote_IndexExp then Remote_IndexExp:InvokeServer() end
            if Remote_IndexLvlReward then
                for lvl = 1, 10 do
                    pcall(function() Remote_IndexLvlReward:InvokeServer(lvl) end)
                end
            end
            if _G.TwoSkiLoaded then
                WindUI:Notify({ Title = "2SKI Money", Content = "รับเงินและของขวัญทุกหมวดหมู่สำเร็จ!" })
            end
        end)
    end
})

-- TAB 3: หลอม & อุปกรณ์ (Auto Forge & Equip)

TabForge:Section({ Title = "ระบบหลอมอุปกรณ์อัตโนมัติ (Auto Forge)" })

UIControls.AutoForge = TabForge:Toggle({
    Title = "หลอมอุปกรณ์อัตโนมัติเมื่อแร่ครบ (Auto Forge)",
    Value = State.AutoForge,
    Callback = function(val)
        State.AutoForge = val
        if _G.TwoSkiLoaded then
            WindUI:Notify({ Title = "2SKI Forge", Content = val and "เริ่มระบบหลอมอุปกรณ์อัตโนมัติ!" or "หยุดระบบหลอม" })
        end
    end
})

UIControls.ForgeType = TabForge:Dropdown({
    Title = "เลือกประเภทที่จะหลอม (Forge Target Type)",
    Values = {
        "หมุนเวียนครบเซ็ต (ดาบ + เกราะ + หมวก)",
        "ดาบ / อาวุธ (Sword / Weapon)",
        "ชุดเกราะ (Body Armor)",
        "หมวก / เฮลม์ (Helmet / Hat)"
    },
    Value = State.ForgeType,
    Callback = function(val) State.ForgeType = val end
})

UIControls.MinOreToForge = TabForge:Slider({
    Title = "จำนวนคริสตัลขั้นต่ำในการหลอม (Min Ores)",
    Step = 1,
    Value = { Min = 4, Max = 23, Default = State.MinOreToForge },
    Callback = function(val) State.MinOreToForge = val end
})

UIControls.OreQualityMode = TabForge:Dropdown({
    Title = "เลือกลำดับเกรดแร่ในการหลอม (Forge Ore Quality)",
    Values = {
        "ใช้แร่เกรดสูงสุดก่อน (Best Ores First)",
        "ใช้แร่เกรดต่ำสุดก่อน (Low Ores First)"
    },
    Value = State.OreQualityMode,
    Callback = function(val) State.OreQualityMode = val end
})

TabForge:Button({
    Title = "หลอมอุปกรณ์ตามประเภทที่เลือกทันที (Forge Selected Now)",
    Callback = function()
        local ok, slot, count = executeForgeNow(State.ForgeType, State.MinOreToForge)
        if _G.TwoSkiLoaded then
            WindUI:Notify({
                Title = "2SKI Forge",
                Content = ok and ("หลอม " .. tostring(slot) .. " สำเร็จ (" .. tostring(count) .. " แร่) และใส่ออโต้แล้ว!") or ("หลอมไม่สำเร็จ: " .. tostring(count or "แร่ไม่พอ"))
            })
        end
    end
})

TabForge:Section({ Title = "ระบบสวมใส่อุปกรณ์ที่ดีที่สุด (Gear Management)" })

UIControls.AutoEquipBest = TabForge:Toggle({
    Title = "ใส่อุปกรณ์ที่ดีที่สุดอัตโนมัติ (ดาบ + เกราะ + หมวก)",
    Value = State.AutoEquipBest,
    Callback = function(val)
        State.AutoEquipBest = val
        if val then
            equipBestGearNow("All")
            if _G.TwoSkiLoaded then
                WindUI:Notify({ Title = "2SKI Gear", Content = "เปิดระบบสวมใส่ฟูลเซ็ตที่ดีที่สุดอัตโนมัติ!" })
            end
        end
    end
})

TabForge:Button({
    Title = "สวมใส่ฟูลเซ็ตที่ดีที่สุดทันที (Equip All Best Gear)",
    Callback = function()
        local ok = equipBestGearNow("All")
        if _G.TwoSkiLoaded then
            WindUI:Notify({
                Title = "2SKI Gear",
                Content = ok and "สวมใส่ฟูลเซ็ต (ดาบ + เกราะ + หมวก) โหดสุดเรียบร้อย!" or "ตรวจสอบอุปกรณ์ในกระเป๋าแล้ว"
            })
        end
    end
})

TabForge:Section({ Title = "ระบบตีบวกอุปกรณ์อัตโนมัติ (Auto Enchant Gear)" })

UIControls.AutoEnchant = TabForge:Toggle({
    Title = "ตีบวกอุปกรณ์ที่สวมใส่อัตโนมัติเมื่อมีหิน (Auto Enchant Equipped)",
    Value = State.AutoEnchant,
    Callback = function(val)
        State.AutoEnchant = val
        if val then
            autoEnchantEquippedGear()
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2SKI Enchant", Content = "เปิดระบบตีบวกอุปกรณ์ฟูลเซ็ตอัตโนมัติ!" })
            end
        end
    end
})

TabForge:Button({
    Title = "ตีบวกอุปกรณ์ที่สวมใส่ทั้งหมดทันที (Enchant All Equipped Now)",
    Callback = function()
        local ok = autoEnchantEquippedGear()
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2SKI Enchant",
                Content = ok and "ตีบวกใส่อุปกรณ์เรียบร้อย!" or "อุปกรณ์เต็มช่องตีบวกแล้ว หรือไม่มีหินตีบวกในกระเป๋า"
            })
        end
    end
})

-- TAB 4: อัปเกรด & เกิดใหม่ (Upgrades & Rebirth)

TabUpgrade:Section({ Title = "สถานะการเกิดใหม่ (Rebirth Status)" })

UIControls.RebirthParagraph = TabUpgrade:Paragraph({
    Title = "สถานะ Rebirth ปัจจุบัน",
    Content = "กำลังโหลดข้อมูลสถานะ..."
})

local function refreshRebirthUI()
    pcall(function()
        local ready, curRebirth, curLevel, needLevel, isMax = checkRebirthStatus()
        local statusTxt = "เลเวลยังไม่ถึงเกณฑ์"
        if isMax then
            statusTxt = "ระดับ Rebirth สูงสุดแล้ว (Max)"
        elseif ready then
            statusTxt = "พร้อมเกิดใหม่แล้ว!"
        elseif needLevel == 0 then
            statusTxt = "กำลังโหลดข้อมูล..."
        end

        local txt = string.format("ระดับ Rebirth ปัจจุบัน: %d\nเลเวลปัจจุบัน: %d / เลเวลที่ต้องการ: %d\nสถานะ: %s",
            curRebirth, curLevel, needLevel, statusTxt)
        if UIControls.RebirthParagraph and UIControls.RebirthParagraph.SetContent then
            UIControls.RebirthParagraph:SetContent(txt)
        end
    end)
end

UIControls.AutoRebirth = TabUpgrade:Toggle({
    Title = "เกิดใหม่อัตโนมัติเมื่อเลเวลถึง (Auto Rebirth)",
    Value = State.AutoRebirth,
    Callback = function(val)
        State.AutoRebirth = val
        refreshRebirthUI()
    end
})

TabUpgrade:Button({
    Title = "กดเกิดใหม่ทันที (Force Rebirth Now)",
    Callback = function()
        if Remote_TryRebirth then
            Remote_TryRebirth:FireServer()
            refreshRebirthUI()
            if _G.TwoSkiLoaded then
                WindUI:Notify({ Title = "2SKI Rebirth", Content = "ส่งคำสั่งเกิดใหม่เรียบร้อย!" })
            end
        end
    end
})

TabUpgrade:Section({ Title = "ระบบอัปเกรดอัตโนมัติ (Smart Upgrades)" })

UIControls.AutoUpgradeAll = TabUpgrade:Toggle({
    Title = "อัปเกรดทุกอย่างอัตโนมัติเมื่อเงินพอ (Upgrade All)",
    Value = State.AutoUpgradeAll,
    Callback = function(val) State.AutoUpgradeAll = val end
})

UIControls.AutoUpgradeTrain = TabUpgrade:Toggle({
    Title = "อัปเกรด Train Multiplier (เพิ่มคูณพลังฝึก)",
    Value = State.AutoUpgradeTrain,
    Callback = function(val) State.AutoUpgradeTrain = val end
})

UIControls.AutoUpgradeLuck = TabUpgrade:Toggle({
    Title = "อัปเกรด Luck (เพิ่มดวงดรอปของเทพ)",
    Value = State.AutoUpgradeLuck,
    Callback = function(val) State.AutoUpgradeLuck = val end
})

UIControls.AutoUpgradeOrePack = TabUpgrade:Toggle({
    Title = "อัปเกรด OrePack (เพิ่มความจุกระเป๋าคริสตัล)",
    Value = State.AutoUpgradeOrePack,
    Callback = function(val) State.AutoUpgradeOrePack = val end
})

TabUpgrade:Button({
    Title = "อัปเกรดทั้งหมดทันทีเมื่อเงินพอ (Force Upgrade Now)",
    Callback = function()
        pcall(function()
            local pd = ProfileData and ProfileData.GetTotalData()
            local curCoins = pd and pd.Eco and pd.Eco.coin or 0
            for _, name in ipairs({"Train", "Luck", "OrePack"}) do
                local curLvl = UpgradeData.GetLevel(name) or 0
                local price = (UpgradeHelper and UpgradeHelper.GetPrice and UpgradeHelper.GetPrice(name, curLvl + 1)) or 0
                local isMax = (UpgradeHelper and UpgradeHelper.CheckIsMax and UpgradeHelper.CheckIsMax(name, curLvl)) or false
                if not isMax and curCoins >= price and Remote_UpgradeOnce then
                    Remote_UpgradeOnce:FireServer(name)
                end
            end
        end)
    end
})

TabUpgrade:Section({ Title = "ระบบสุ่มคลาสอัตโนมัติ (Auto Class Gacha)" })

UIControls.AutoRollClass = TabUpgrade:Toggle({
    Title = "สุ่มคลาสอัตโนมัติเมื่อมีตั๋ว (Auto Roll Class)",
    Value = State.AutoRollClass,
    Callback = function(val)
        State.AutoRollClass = val
        if val then
            autoRollClassNow()
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2SKI Class", Content = "เปิดระบบสุ่มคลาสอัตโนมัติ (จะหยุดทันทีเมื่อได้เกรดเป้าหมาย)!" })
            end
        end
    end
})

UIControls.TargetClassRarity = TabUpgrade:Dropdown({
    Title = "หยุดสุ่มเมื่อได้รับระดับ (Stop at Target Rarity)",
    Values = {
        "Legendary ขึ้นไป",
        "Mythic ขึ้นไป",
        "Epic ขึ้นไป"
    },
    Value = State.TargetClassRarity,
    Callback = function(val) State.TargetClassRarity = val end
})

TabUpgrade:Button({
    Title = "กดสุ่มคลาส 1 ครั้งทันที (Roll Class Once Now)",
    Callback = function()
        if not ClassData or not Remote_LuckOnce then return end
        local tickets = (ClassData.GetLuckTimes and ClassData.GetLuckTimes()) or 0
        if tickets > 0 then
            Remote_LuckOnce:FireServer()
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2SKI Class", Content = "กดสุ่มคลาสเรียบร้อย! (เหลือตั๋ว: " .. tostring(tickets - 1) .. ")" })
            end
        else
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2SKI Class", Content = "ตั๋วสุ่มคลาสไม่เพียงพอ!" })
            end
        end
    end
})

-- =====================================================================
-- TAB 5: Boost FPS (ลดแล็ก) (FPS Booster & Lag Reducer)
-- =====================================================================


local function setVFXEnabled(enabled)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Highlight") then
                obj.Enabled = enabled
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj.Enabled = enabled
            end
        end
    end)
end

local function setGamePopupsMuted(muted)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, name in ipairs({"Message", "UIVFX", "UIVFX_Full", "ConfettiGui"}) do
            local g = pg:FindFirstChild(name)
            if g and g:IsA("ScreenGui") then
                g.Enabled = not muted
            end
        end
    end)
end

local function applyLowGraphics(enable)
    pcall(function()
        local Lighting = game:GetService("Lighting")
        if enable then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
                    v.Enabled = false
                end
            end
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.SmoothPlastic
                    part.CastShadow = false
                    part.Reflectance = 0
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 1
                end
            end
        else
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 1000
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") then v.Enabled = true end
            end
        end
    end)
end

local function updateHideOtherPlayers(hide)
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        part.Transparency = hide and 1 or 0
                    end
                end
            end
        end
    end)
end

local function runMemoryCleaner()
    local before = 0
    pcall(function() before = collectgarbage("count") end)
    pcall(function()
        collectgarbage("collect")
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local uivfx = pg:FindFirstChild("UIVFX")
            if uivfx then
                for _, c in ipairs(uivfx:GetChildren()) do
                    if c.Name == "TrainOnce" then pcall(function() c:Destroy() end) end
                end
            end
        end
    end)
    local after = 0
    pcall(function() after = collectgarbage("count") end)
    local freed = math.max(0, math.floor(before - after))
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "2K Cleaner",
            Content = string.format("ล้างหน่วยความจำสำเร็จ! คืนค่าแรม: %d KB", freed),
            Duration = 2.5
        })
    end
end

-- Real-time Watchers for FPS
table.insert(Connections, workspace.DescendantAdded:Connect(function(obj)
    if State.DisableVFX then
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Highlight") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj.Enabled = false
            end
        end)
    end
    if State.LowGraphics then
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end)
    end
end))

table.insert(Connections, Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if State.HideOtherPlayers and player ~= LocalPlayer then
            task.wait(0.2)
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        part.Transparency = 1
                    end
                end
            end)
        end
    end)
end))

task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        task.wait(1.5)
        if State.MuteGamePopups then
            setGamePopupsMuted(true)
        end
    end
end)

-- =====================================================================
-- [[ TAB: เสกของ (GOD SPAWNER - ARMOR & WEAPONS) ]]
-- =====================================================================

-- =====================================================================
-- [[ ORES & MATERIALS PUMP ENGINE (SERVER REPLICATED & PERSISTENT) ]]
-- =====================================================================

local isPumpingOres = false
local isPumpingEmber = false

local function harvestStageDrops(stageName)
    stageName = stageName or State.SelectedOreStage or "Stage_27"
    if string.find(stageName, " ") then
        stageName = string.split(stageName, " ")[1]
    end

    local stageRemote = Remote_StageFinished or getRemote("Stage", "StageFinishedRF", true)
    local getOreRemote = Remote_GetOre or getRemote("Stage", "GetOreRF", true)
    local stoneRemote = Remote_GetEnhantStone or getRemote("Stage", "GetEnhantStoneRE", false)
    local claimRemote = Remote_ClaimedAllOre or getRemote("Stage", "ClaimedAllOreRE", false)

    if not stageRemote then return 0 end

    local ok, drops = pcall(function() return stageRemote:InvokeServer(stageName) end)
    if not ok or type(drops) ~= "table" then return 0 end

    local collectedCount = 0
    for uuid, itm in pairs(drops) do
        if type(itm) == "string" and string.find(itm, "Ore") then
            if getOreRemote then
                pcall(function() getOreRemote:InvokeServer(uuid, true) end)
                collectedCount = collectedCount + 1
            end
        elseif type(itm) == "table" then
            if stoneRemote then
                pcall(function() stoneRemote:FireServer(uuid) end)
                collectedCount = collectedCount + 1
            end
        end
    end

    if claimRemote then
        pcall(function() claimRemote:FireServer() end)
    end

    return collectedCount
end

local function pumpRealOres(batchRounds, stageName)
    stageName = stageName or State.SelectedOreStage or "Stage_27"
    if string.find(stageName, " ") then
        stageName = string.split(stageName, " ")[1]
    end
    batchRounds = tonumber(batchRounds) or 10
    if isPumpingOres then return false end
    isPumpingOres = true

    local function getOreCount()
        local bp = BackpackData and BackpackData.GetData()
        local count = 0
        if bp and bp.have then
            for _, item in pairs(bp.have) do
                if item.Type == "Ore" then
                    count = count + (item.Number or 1)
                end
            end
        end
        return count
    end

    local initialCount = getOreCount()

    task.spawn(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Ore Spawner",
                Content = "กำลังดึงแร่จาก " .. tostring(stageName) .. " (" .. tostring(batchRounds) .. " รอบ) เซฟลง Server ถาวร...",
                Duration = 3
            })
        end

        for i = 1, batchRounds do
            if not _G.TwoSkiRunning or _G.TwoSkiActiveToken ~= myToken then break end
            harvestStageDrops(stageName)
            task.wait(0.06)
        end

        task.wait(0.3)
        local finalCount = getOreCount()
        local gained = finalCount - initialCount
        isPumpingOres = false

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Ore Spawner",
                Content = "เสกแร่สำเร็จ! ได้แร่ +" .. tostring(gained) .. " ก้อน (มีทั้งหมด " .. tostring(finalCount) .. " ก้อน) เซฟถาวร 100%!",
                Duration = 4
            })
        end

        pcall(function()
            local bpGui = require(ReplicatedStorage.GuiUtils.BackpackGUI)
            if bpGui and bpGui.UpdateBackpack then bpGui.UpdateBackpack() end
            if _G._TwoK_HealBackpack then _G._TwoK_HealBackpack() end
        end)
    end)
    return true
end

local function pumpRealEmberStones(targetAmount)
    targetAmount = tonumber(targetAmount) or 5000
    if isPumpingEmber then return false end
    isPumpingEmber = true

    local function getStoneCount()
        local bp = BackpackData and BackpackData.GetData()
        if bp and bp.have then
            for _, item in pairs(bp.have) do
                if item.ID == "EnhantStone_1" then
                    return item.Number or 0
                end
            end
        end
        return 0
    end

    local initialCount = getStoneCount()
    local goal = initialCount + targetAmount

    task.spawn(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Spawner",
                Content = "กำลังเสก Ember Stone +" .. tostring(targetAmount) .. " ก้อน (เซฟลง Server DataStore ถาวร)...",
                Duration = 3
            })
        end

        local stageRemote = Remote_StageFinished or getRemote("Stage", "StageFinishedRF", true)
        local stoneRemote = Remote_GetEnhantStone or getRemote("Stage", "GetEnhantStoneRE", false)
        local current = getStoneCount()
        local t0 = os.clock()
        local maxWait = 40

        while current < goal and (os.clock() - t0) < maxWait and _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
            local batchSize = 30
            local needed = goal - current
            if needed < 50 then batchSize = 10 end

            for i = 1, batchSize do
                task.spawn(function()
                    local ok, drops = pcall(function()
                        return stageRemote:InvokeServer("Stage_27")
                    end)
                    if ok and type(drops) == "table" and stoneRemote then
                        for uuid, itm in pairs(drops) do
                            if type(itm) == "table" and (itm.ID == "EnhantStone_1" or itm.Type == "Material") then
                                pcall(function() stoneRemote:FireServer(uuid) end)
                            end
                        end
                    end
                end)
            end

            task.wait(0.12)
            current = getStoneCount()
            if _G._TwoK_HealBackpack then pcall(_G._TwoK_HealBackpack) end
        end

        local finalCount = getStoneCount()
        local gained = finalCount - initialCount
        isPumpingEmber = false

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Spawner",
                Content = "เสกสำเร็จ! ได้ Ember Stone +" .. tostring(gained) .. " ก้อน (มีทั้งหมด " .. tostring(finalCount) .. " ก้อน) บันทึก Server ถาวร 100%",
                Duration = 4
            })
        end

        pcall(function()
            local bpGui = require(ReplicatedStorage.GuiUtils.BackpackGUI)
            if bpGui and bpGui.UpdateBackpack then bpGui.UpdateBackpack() end
            if _G._TwoK_HealBackpack then _G._TwoK_HealBackpack() end
        end)
    end)
    return true
end

local function forgeItemWithBestOres(targetType)
    targetType = targetType or State.SelectedForgeTarget or "Weapon"
    local forgeRemote = Remote_Forge or getRemote("Forge", "ForgeRF", true)
    local bp = BackpackData and BackpackData.GetData()
    if not forgeRemote or not bp or not bp.have then return false, "No remote or backpack" end

    local oreList = {}
    for uuid, item in pairs(bp.have) do
        if item.Type == "Ore" then
            table.insert(oreList, {uuid = uuid, num = item.Number or 1, id = item.ID})
        end
    end

    if #oreList < 4 then
        harvestStageDrops(State.SelectedOreStage or "Stage_27")
        task.wait(0.3)
        bp = BackpackData and BackpackData.GetData()
        oreList = {}
        if bp and bp.have then
            for uuid, item in pairs(bp.have) do
                if item.Type == "Ore" then
                    table.insert(oreList, {uuid = uuid, num = item.Number or 1, id = item.ID})
                end
            end
        end
    end

    if #oreList < 4 then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Auto Forge",
                Content = "แร่ไม่พอหลอม (ต้องใช้ 4 ก้อนขึ้นไป) กำลังเสกแร่เพิ่มอัตโนมัติ...",
                Duration = 3
            })
        end
        pumpRealOres(2, State.SelectedOreStage or "Stage_27")
        return false, "Ores insufficient"
    end

    local uuidPayload = {}
    for i = 1, math.min(4, #oreList) do
        uuidPayload[oreList[i].uuid] = oreList[i].num
    end

    local ok, res = pcall(function()
        return forgeRemote:InvokeServer({
            ConfigType = targetType,
            UUIDList = uuidPayload
        })
    end)

    if ok and res and type(res) == "table" and #res > 0 then
        local craftedItem = res[1]
        local itemId = craftedItem.ID or "Item"
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Auto Forge",
                Content = "หลอมสำเร็จ! ได้ " .. tostring(targetType) .. " [" .. tostring(itemId) .. "] เซฟถาวร คนอื่นมองเห็น 100%!",
                Duration = 4
            })
        end
        if Remote_TryEquip and craftedItem.UUID then
            pcall(function() Remote_TryEquip:FireServer(craftedItem.UUID, targetType) end)
        end
        pcall(function()
            local bpGui = require(ReplicatedStorage.GuiUtils.BackpackGUI)
            if bpGui and bpGui.UpdateBackpack then bpGui.UpdateBackpack() end
        end)
        return true, itemId
    end
    return false, "Forge failed"
end

-- Background Auto Farm Ores & Forge loop
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        if State.AutoFarmOres then
            pcall(function()
                harvestStageDrops(State.SelectedOreStage or "Stage_27")
                if State.AutoForgeAfterOres then
                    local bp = BackpackData and BackpackData.GetData()
                    local oreCount = 0
                    if bp and bp.have then
                        for _, item in pairs(bp.have) do
                            if item.Type == "Ore" then oreCount = oreCount + 1 end
                        end
                    end
                    if oreCount >= 4 then
                        forgeItemWithBestOres(State.SelectedForgeTarget or "Weapon")
                    end
                end
            end)
            task.wait(0.2)
        else
            task.wait(0.5)
        end
    end
end)
-- ─────────────────────────────────────────────────────────────
-- Dungeon Token Spawner & Multi-Thread Farm Engine (User Exploit)
-- ─────────────────────────────────────────────────────────────
runDungeonTokenFarm = function(targetRound, threadCount, onProgress, onFinish)
    if isFarmingTokens then
        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K Spawner", Content = "ระบบกำลังปั๊ม Token อยู่แล้ว...", Duration = 3 })
        end
        return
    end

    isFarmingTokens = true
    targetRound = tonumber(targetRound) or 50
    threadCount = math.clamp(tonumber(threadCount) or 5, 1, 10)

    task.spawn(function()
        local DS = Remotes and (Remotes:FindFirstChild("Dungeon_Server") or Remotes:FindFirstChild("Dungeon"))
        if not DS then
            DS = game:GetService("ReplicatedStorage"):FindFirstChild("Remote") and game:GetService("ReplicatedStorage").Remote:FindFirstChild("Dungeon_Server")
        end
        if not DS then
            if WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2K Spawner", Content = "ไม่พบ Remote Dungeon_Server!", Duration = 4 })
            end
            isFarmingTokens = false
            return
        end

        local tryClaimTicketRE = DS:FindFirstChild("TryClaimDailyDunTicRE") or Remote_DungeonTicket
        local tryIntoDungeonRF = DS:FindFirstChild("TryIntoDungeonRF") or Remote_TryIntoDungeon
        local startRoundRE     = DS:FindFirstChild("StartRoundRE") or Remote_StartRound
        local completeRoundRF  = DS:FindFirstChild("CompleteRoundRF") or Remote_CompleteRound

        -- 1. เคลมตั๋วดันเจี้ยนประจำวัน
        if tryClaimTicketRE then
            pcall(function() tryClaimTicketRE:FireServer() end)
        end
        task.wait(0.2)

        -- 2. ออกจากดันเจี้ยนก่อน (กรณีค้างอยู่ข้างใน)
        local inFight = LocalPlayer:GetAttribute("IntoFight")
        if inFight == "Dungeon" and tryIntoDungeonRF then
            pcall(function() tryIntoDungeonRF:InvokeServer(false) end)
            task.wait(0.2)
        end

        -- 3. ตรวจสอบการปลดล็อคด่าน ถ้าด่านเป้าหมายยังไม่ถึง ให้สลับมาใช้ด่านสูงสุดที่ปลดแล้ว
        local DungeonData = nil
        pcall(function() DungeonData = require(ReplicatedStorage.LocalData.DungeonData) end)
        local maxUnlocked = (DungeonData and DungeonData.GetMaxRound and DungeonData.GetMaxRound()) or 1
        local actualRound = targetRound
        if DungeonData and DungeonData.CheckCanUnlock and not DungeonData.CheckCanUnlock(actualRound) then
            actualRound = math.max(1, maxUnlocked)
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "2K Spawner",
                    Content = string.format("ด่าน %d ยังไม่ปลดล็อค! สลับมาปั๊มด่านสูงสุด %d อัตโนมัติ", targetRound, actualRound),
                    Duration = 4
                })
            end
        end

        -- 4. เรียก TryIntoDungeonRF เข้าสู่ดันเจี้ยน
        local entered = false
        if tryIntoDungeonRF then
            local ok, res = pcall(function()
                return tryIntoDungeonRF:InvokeServer(true, actualRound)
            end)
            entered = ok and (res == true)
        end

        if not entered then
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "2K Spawner",
                    Content = "ไม่สามารถเข้าดันเจี้ยนได้ (ไม่มีตั๋วหรือติดสถานะการเล่น)",
                    Duration = 4
                })
            end
            isFarmingTokens = false
            if onFinish then onFinish(0, false) end
            return
        end

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Spawner",
                Content = string.format("เข้าสู่ดันเจี้ยนด่าน %d สำเร็จ! เริ่มต้นปั๊ม Token (%d Threads)...", actualRound, threadCount),
                Duration = 3
            })
        end

        task.wait(0.2)

        -- 5. Multi-Thread Worker Pool (5 Threads ตามโค้ด Exploit)
        local done = false
        local rounds = 0
        local activeWorkers = threadCount

        for i = 1, threadCount do
            task.spawn(function()
                while not done and isFarmingTokens and _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
                    if startRoundRE then
                        pcall(function() startRoundRE:FireServer(actualRound) end)
                    end
                    local ok, result = pcall(function()
                        return completeRoundRF:InvokeServer(actualRound)
                    end)
                    if not ok or type(result) ~= "table" then
                        done = true
                        break
                    end
                    rounds = rounds + 1
                    tokenFarmRoundsCompleted = tokenFarmRoundsCompleted + 1
                    if onProgress then
                        pcall(function() onProgress(rounds) end)
                    end
                end
                activeWorkers = activeWorkers - 1
            end)
        end

        repeat task.wait(0.5) until activeWorkers <= 0
        isFarmingTokens = false

        -- อ่านจำนวน Token ปัจจุบันจาก ProfileData
        local curTokens = 0
        pcall(function()
            local ProfileData = require(ReplicatedStorage.ProfileData)
            local tData = ProfileData.GetStoreData("Token")
            curTokens = (tData and tData.value) or 0
        end)

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Spawner • ปั๊ม Token สำเร็จ!",
                Content = string.format("จบการทำงาน! ฟาร์มไปทั้งหมด %d รอบ | Token ปัจจุบัน: %s", rounds, tostring(curTokens)),
                Duration = 6
            })
        end

        if onFinish then
            pcall(function() onFinish(rounds, true, curTokens) end)
        end
    end)
end

autoUnlockDungeonRounds = function(targetRound)
    targetRound = math.clamp(tonumber(targetRound) or 50, 1, 50)
    task.spawn(function()
        local DS = Remotes and (Remotes:FindFirstChild("Dungeon_Server") or Remotes:FindFirstChild("Dungeon"))
        if not DS then return end
        local DungeonData = nil
        pcall(function() DungeonData = require(ReplicatedStorage.LocalData.DungeonData) end)
        local cur = (DungeonData and DungeonData.GetMaxRound and DungeonData.GetMaxRound()) or 0

        if cur >= targetRound then
            if WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "2K Dungeon", Content = string.format("ด่าน %d ปลดล็อคอยู่แล้ว!", cur), Duration = 3 })
            end
            return
        end

        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K Dungeon", Content = string.format("กำลังเร่งเคลียร์ด่าน %d ถึง %d เพื่อปลดล็อค...", cur + 1, targetRound), Duration = 4 })
        end

        for r = cur + 1, targetRound do
            local entered = DS.TryIntoDungeonRF:InvokeServer(true, r)
            DS.StartRoundRE:FireServer(r)
            local res = DS.CompleteRoundRF:InvokeServer(r)
            task.wait(0.06)
        end

        local finalMax = (DungeonData and DungeonData.GetMaxRound and DungeonData.GetMaxRound()) or cur
        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K Dungeon", Content = string.format("ปลดล็อคสำเร็จ! ด่านสูงสุดปัจจุบัน: %d", finalMax), Duration = 5 })
        end
    end)
end

local function equipArmorSet(armorId, hatId, setName)
    if Remote_GetArmor and armorId then Remote_GetArmor:FireServer(armorId) end
    if Remote_GetArmor and hatId then Remote_GetArmor:FireServer(hatId) end

    task.spawn(function()
        local t0 = os.clock()
        while (os.clock() - t0) < 3 do
            local bp = BackpackData and BackpackData.GetData()
            if bp and bp.have and Remote_TryEquip then
                local eqArmor, eqHat = false, false
                for uuid, item in pairs(bp.have) do
                    if item.ID == armorId and not eqArmor then
                        Remote_TryEquip:FireServer(uuid, "Armor")
                        eqArmor = true
                    elseif item.ID == hatId and not eqHat then
                        Remote_TryEquip:FireServer(uuid, "Hat")
                        eqHat = true
                    end
                end
                if eqArmor and eqHat then break end
            end
            task.wait(0.15)
        end
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K SPAWNER",
                Content = "สวมใส่ชุด " .. (setName or "") .. " เรียบร้อย (เซฟลง Server DataStore ถาวร)",
                Duration = 3
            })
        end
    end)
    return true
end

local function equipWeapon(weaponId, weaponName)
    if Remote_GetWeapon and weaponId then Remote_GetWeapon:FireServer(weaponId) end

    task.spawn(function()
        local t0 = os.clock()
        while (os.clock() - t0) < 3 do
            local bp = BackpackData and BackpackData.GetData()
            if bp and bp.have and Remote_TryEquip then
                for uuid, item in pairs(bp.have) do
                    if item.ID == weaponId then
                        Remote_TryEquip:FireServer(uuid, "Weapon")
                        if WindUI and WindUI.Notify then
                            WindUI:Notify({
                                Title = "2K SPAWNER",
                                Content = "สวมใส่ดาบ " .. (weaponName or "") .. " เรียบร้อย (เซฟลง Server DataStore ถาวร)",
                                Duration = 3
                            })
                        end
                        return
                    end
                end
            end
            task.wait(0.15)
        end
    end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- SHADOW SOVEREIGN'S ETERNAL LEGACY (GearSet_3 12,999 ROBUX LIMITED)
-- ═══════════════════════════════════════════════════════════════════
local function clearShadowSovereignMorph(character)
    character = character or LocalPlayer.Character
    if not character then return end
    local old = character:FindFirstChild("ShadowSovereignMorph")
    if old then
        pcall(function() old:Destroy() end)
    end
    -- Restore original weapon and accessories
    pcall(function()
        local origWeapon = character:FindFirstChild("WEAPON")
        if origWeapon then
            for _, p in ipairs(origWeapon:GetDescendants()) do
                if p:IsA("BasePart") then
                    local origTrans = p:GetAttribute("OrigTransparency")
                    if origTrans then
                        p.Transparency = origTrans
                    end
                end
            end
        end
        for _, acc in ipairs(character:GetChildren()) do
            if acc:IsA("Accessory") then
                local h = acc:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then
                    local origTrans = h:GetAttribute("OrigTransparency")
                    if origTrans then
                        h.Transparency = origTrans
                    end
                end
            end
        end
    end)
end

local function applyShadowSovereignMorph(character)
    character = character or LocalPlayer.Character
    if not character or not character.Parent then return false end

    local worldModel = workspace:FindFirstChild("WorldModel")
    local gearSet = worldModel and worldModel:FindFirstChild("GearSet_3")
    local gearSetModel = gearSet and gearSet:FindFirstChild("A")
    if not gearSetModel then return false end

    clearShadowSovereignMorph(character)

    local morphFolder = Instance.new("Folder")
    morphFolder.Name = "ShadowSovereignMorph"
    morphFolder.Parent = character

    local partMap = {
        ["Head"] = character:FindFirstChild("Head"),
        ["Torso"] = character:FindFirstChild("Torso"),
        ["Left Arm"] = character:FindFirstChild("Left Arm"),
        ["Right Arm"] = character:FindFirstChild("Right Arm"),
        ["Left Leg"] = character:FindFirstChild("Left Leg"),
        ["Right Leg"] = character:FindFirstChild("Right Leg"),
        ["HumanoidRootPart"] = character:FindFirstChild("HumanoidRootPart")
    }
    if not partMap["HumanoidRootPart"] or not partMap["Torso"] or not partMap["Head"] then return false end

    -- Hide original weapon & accessories to prevent clipping
    pcall(function()
        local origWeapon = character:FindFirstChild("WEAPON")
        if origWeapon then
            for _, p in ipairs(origWeapon:GetDescendants()) do
                if p:IsA("BasePart") then
                    if not p:GetAttribute("OrigTransparency") then
                        p:SetAttribute("OrigTransparency", p.Transparency)
                    end
                    p.Transparency = 1
                end
            end
        end
        for _, acc in ipairs(character:GetChildren()) do
            if acc:IsA("Accessory") then
                local h = acc:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then
                    if not h:GetAttribute("OrigTransparency") then
                        h:SetAttribute("OrigTransparency", h.Transparency)
                    end
                    h.Transparency = 1
                end
            end
        end
    end)

    -- 1. Hat & Crown Morph
    local hatSource = gearSetModel:FindFirstChild("Hat")
    if hatSource and partMap["Head"] and gearSetModel:FindFirstChild("Head") then
        local hatClone = hatSource:Clone()
        hatClone.Name = "HatMorph"
        for _, part in ipairs(hatClone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Massless = true
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = partMap["Head"]
                weld.Part1 = part
                weld.Parent = part
            end
        end
        hatClone.Parent = morphFolder
        if hatSource:FindFirstChild("HD") and hatSource.HD:FindFirstChild("Handle") then
            local offset = gearSetModel.Head.CFrame:ToObjectSpace(hatSource.HD.Handle.CFrame)
            hatClone.HD.Handle.CFrame = partMap["Head"].CFrame * offset
        end
    end

    -- 2. Armor & Body / Cloak Morph
    local armorSource = gearSetModel:FindFirstChild("Armor")
    if armorSource then
        local armorClone = armorSource:Clone()
        armorClone.Name = "ArmorMorph"
        local armorFolderMap = {
            ["HD"] = partMap["Head"],
            ["Body"] = partMap["Torso"],
            ["Root"] = partMap["HumanoidRootPart"],
            ["LeftArm"] = partMap["Left Arm"],
            ["RightArm"] = partMap["Right Arm"],
            ["LeftLeg"] = partMap["Left Leg"],
            ["RightLeg"] = partMap["Right Leg"]
        }
        for folderName, targetLimb in pairs(armorFolderMap) do
            local f = armorClone:FindFirstChild(folderName)
            local srcLimb = gearSetModel:FindFirstChild(targetLimb.Name)
            if f and targetLimb and srcLimb then
                local handle = f:FindFirstChild("Handle")
                if handle then
                    local offset = srcLimb.CFrame:ToObjectSpace(handle.CFrame)
                    handle.CFrame = targetLimb.CFrame * offset
                end
                for _, p in ipairs(f:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                        p.Massless = true
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = targetLimb
                        weld.Part1 = p
                        weld.Parent = p
                    end
                end
            end
        end
        armorClone.Parent = morphFolder
    end

    -- 3. Eclipse Authority Greatsword Weapon Morph
    local weaponSource = gearSetModel:FindFirstChild("A")
    if weaponSource and partMap["Right Arm"] and gearSetModel:FindFirstChild("Right Arm") then
        local weaponClone = weaponSource:Clone()
        weaponClone.Name = "WeaponMorph"
        local srcArm = gearSetModel:FindFirstChild("Right Arm")
        local mainPart = weaponClone:FindFirstChild("MAIN") or weaponClone:FindFirstChildWhichIsA("BasePart")
        if mainPart and srcArm then
            local offset = srcArm.CFrame:ToObjectSpace(mainPart.CFrame)
            mainPart.CFrame = partMap["Right Arm"].CFrame * offset
        end
        for _, p in ipairs(weaponClone:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
                p.Massless = true
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = partMap["Right Arm"]
                weld.Part1 = p
                weld.Parent = p
            end
        end
        weaponClone.Parent = morphFolder
    end

    return true
end

local SecLimitedMorph = TabSpawner:Section({
    Title = "ชุดลิมิเต็ด 12,999 Robux (Shadow Sovereign's Eternal Legacy)",
    Desc = "สวมใส่ชุดเกราะเทพหนามสีแดง มงกุฎ ผ้าคลุม ออร่าสายฟ้าสีรุ้ง และดาบใหญ่ Eclipse Authority",
    Icon = "crown"
})

UIControls.ShadowSovereignMorph = SecLimitedMorph:Toggle({
    Title = "สวมใส่ชุด Shadow Sovereign (12,999 R$ Limited)",
    Desc = "เสกและสวมใส่ชุดในรูปทันที พร้อมออร่าและดาบยักษ์ครบเซ็ต",
    Value = State.ShadowSovereignMorph,
    Callback = function(val)
        State.ShadowSovereignMorph = val
        if val then
            local ok = applyShadowSovereignMorph()
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "2K LIMITED MORPH",
                    Content = ok and "สวมใส่ชุด Shadow Sovereign's Eternal Legacy สำเร็จ!" or "ไม่พบโมเดล GearSet_3 ในแมพ!",
                    Duration = 4
                })
            end
        else
            clearShadowSovereignMorph()
            if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "2K LIMITED MORPH",
                    Content = "ถอดชุดลิมิเต็ดเรียบร้อย คืนค่าโมเดลเดิม",
                    Duration = 3
                })
            end
        end
    end
})

SecLimitedMorph:Button({
    Title = "รีเฟรชคอสตูมชุดลิมิเต็ด (Re-apply Morph)",
    Desc = "กดใส่ซ้ำทันทีหากชิ้นส่วนหลุดหรือโมเดลไม่ขึ้น",
    Callback = function()
        applyShadowSovereignMorph()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K LIMITED MORPH",
                Content = "รีเฟรชชุด Shadow Sovereign เรียบร้อย!",
                Duration = 2.5
            })
        end
    end
})

local SecArmor = TabSpawner:Section({
    Title = "เสกชุดเกราะเทพ (เซฟลง Server DataStore 100%)",
    Desc = "สวมใส่ชุดเกราะระดับท็อป คนอื่นมองเห็น ออกเข้าใหม่ไม่หาย",
    Icon = "shield"
})

SecArmor:Button({
    Title = "สวมใส่ชุดมังกรดวงดาว (Astral Dragon Emperor Set)",
    Desc = "เซ็ตเกราะมังกรดวงดาว ป้องกัน +100M, บูสต์พลังฝึก x5.0M",
    Callback = function()
        equipArmorSet("HArmor_1002", "HHat_1002", "Astral Dragon Emperor")
    end
})

SecArmor:Button({
    Title = "สวมใส่ชุดหายนะวันสิ้นโลก (Apocalypse Overlord Set)",
    Desc = "เซ็ตเกราะวันสิ้นโลก เพิ่มความถึก เลือด และดาเมจมหาศาล",
    Callback = function()
        equipArmorSet("HArmor_1001", "HHat_1001", "Apocalypse Overlord")
    end
})

SecArmor:Button({
    Title = "สวมใส่ชุดคาตาคลิซึม (Cataclysm Destroyer Set)",
    Desc = "เซ็ตเกราะลาวาภูเขาไฟทำลายล้าง",
    Callback = function()
        equipArmorSet("HArmor_1003", "HHat_1003", "Cataclysm Destroyer")
    end
})

SecArmor:Button({
    Title = "สวมใส่ชุดความว่างเปล่า (Void Sovereign Set)",
    Desc = "เซ็ตเกราะแห่งความว่างเปล่า ป้องกันระดับสูง",
    Callback = function()
        equipArmorSet("HArmor_1004", "HHat_1004", "Void Sovereign")
    end
})

local SecWeapon = TabSpawner:Section({
    Title = "เสกดาบเทพ & อาวุธ (เซฟลง Server DataStore 100%)",
    Desc = "สวมใส่อาวุธระดับก็อด คนอื่นมองเห็น ฟันดาเมจมหาศาล ออกเข้าใหม่ไม่หาย",
    Icon = "swords"
})

SecWeapon:Button({
    Title = "สวมใส่ดาบกลืนกินความโกลาหล (Chaoseater)",
    Desc = "ดาบกลืนกินความโกลาหล พลังโจมตีสูงสุดในเกม",
    Callback = function()
        equipWeapon("G_1101", "Chaoseater")
    end
})

SecWeapon:Button({
    Title = "สวมใส่ดาบซูเปอร์โนวา (Astral Supernova Edge)",
    Desc = "ดาบใหญ่ดวงดาว Astral พลังทำลายล้างมหาศาล",
    Callback = function()
        equipWeapon("G_1002", "Astral Supernova Edge")
    end
})

SecWeapon:Button({
    Title = "สวมใส่ดาบคาตานะหายนะ (Apocalypse Katana)",
    Desc = "ดาบซามูไรความเร็วสูงแห่งหายนะ ฟันติดคริติคอล",
    Callback = function()
        equipWeapon("K_1101", "Apocalypse Katana")
    end
})

SecWeapon:Button({
    Title = "สวมใส่ดาบวอยด์ออบลิเวียน (Void Greatsword)",
    Desc = "ดาบใหญ่แห่งความว่างเปล่า ดูดกลืนทุกสิ่ง",
    Callback = function()
        equipWeapon("G_1001", "Void Greatsword")
    end
})

local SecOreSpawner = TabSpawner:Section({
    Title = "เสก & ปั๊มแร่ระดับเทพ (Infinite Ores - เซฟถาวร 100%)",
    Desc = "ดึงแร่ดรอปจริงจาก Stage สู่กระเป๋า นำไปหลอมอาวุธ/เกราะที่คนอื่นมองเห็นได้",
    Icon = "gem"
})

SecOreSpawner:Dropdown({
    Title = "เลือกระดับด่านที่จะดึงแร่ (Select Stage)",
    Desc = "Stage 27 จะดึงแร่ระดับสูงสุด (Infinite Ore_48, Ancient Ore_46-47)",
    Values = {
        "Stage_27 (Infinite Ore_48 & Ancient)",
        "Stage_25 (Ancient & Mythic Ores)",
        "Stage_20 (Mythic & Legendary Ores)",
        "Stage_15 (Legendary & Epic Ores)",
        "Stage_10 (Epic & Rare Ores)",
        "Stage_5 (Rare & Uncommon Ores)",
        "Stage_1 (Common Ores)"
    },
    Value = "Stage_27 (Infinite Ore_48 & Ancient)",
    Callback = function(val)
        local stageId = string.split(val, " ")[1] or "Stage_27"
        State.SelectedOreStage = stageId
    end
})

SecOreSpawner:Button({
    Title = "เสกแร่ทันที 1 ชุด (Instant Claim Drops)",
    Desc = "ดึงแร่ทั้งหมดจากรอบสเตจปัจจุบันเข้ากระเป๋าถาวร 100%",
    Callback = function()
        local count = harvestStageDrops(State.SelectedOreStage or "Stage_27")
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Ore Spawner",
                Content = "ดึงแร่สำเร็จ +" .. tostring(count) .. " รายการ เซฟถาวรในกระเป๋า 100%!",
                Duration = 3
            })
        end
    end
})

SecOreSpawner:Button({
    Title = "ปั๊มแร่ระดับเทพ (+50 ก้อน / บันทึก Server)",
    Desc = "วนลูปดึงแร่เข้ากระเป๋า 10 รอบอย่างรวดเร็ว เซฟลง DataStore 100%",
    Callback = function()
        pumpRealOres(10, State.SelectedOreStage or "Stage_27")
    end
})

SecOreSpawner:Button({
    Title = "ปั๊มแร่ระดับมหาศาล (+200 ก้อน / บันทึก Server)",
    Desc = "วนลูปดึงแร่เข้ากระเป๋า 40 รอบอย่างรวดเร็ว สำหรับหลอมของทั้งวัน",
    Callback = function()
        pumpRealOres(40, State.SelectedOreStage or "Stage_27")
    end
})

UIControls.AutoFarmOres = SecOreSpawner:Toggle({
    Title = "ออโต้ฟาร์มแร่ตลอดเวลา (Auto Farm Ores Loop)",
    Desc = "ดึงแร่ระดับเทพเข้ากระเป๋าแบบต่อเนื่องอัตโนมัติ ไม่ต้องเดินไปตีมอนสเตอร์",
    Value = State.AutoFarmOres,
    Callback = function(val)
        State.AutoFarmOres = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Ore Spawner",
                Content = val and "เปิดระบบออโต้ฟาร์มแร่ระดับเทพแล้ว!" or "ปิดระบบออโต้ฟาร์มแร่",
                Duration = 3
            })
        end
    end
})

local SecAutoForge = TabSpawner:Section({
    Title = "หลอมอาวุธ & ชุดเกราะจริง (Forge Real Items - ทุกคนมองเห็น)",
    Desc = "นำแร่ที่เสกได้มาหลอมเป็นอาวุธ/เกราะระดับเทพ คนอื่นมองเห็น ออกเข้าใหม่ไม่หาย",
    Icon = "hammer"
})

SecAutoForge:Dropdown({
    Title = "เลือกประเภทไอเทมที่จะหลอม (Forge Target)",
    Desc = "เลือกประเภทอุปกรณ์ที่ต้องการให้ระบบหลอม",
    Values = {
        "Weapon (อาวุธ/ดาบ)",
        "Armor (ชุดเกราะลำตัว)",
        "Hat (หมวก/มงกุฎ)"
    },
    Value = "Weapon (อาวุธ/ดาบ)",
    Callback = function(val)
        if string.find(val, "Weapon") then
            State.SelectedForgeTarget = "Weapon"
        elseif string.find(val, "Armor") then
            State.SelectedForgeTarget = "Armor"
        elseif string.find(val, "Hat") then
            State.SelectedForgeTarget = "Hat"
        end
    end
})

SecAutoForge:Button({
    Title = "หลอมของเทพจากแร่ทันที 1 ครั้ง (Forge Best Item)",
    Desc = "ใช้แร่ระดับสูง 4 ก้อนในกระเป๋าหลอมไอเทมใหม่ทันที คนอื่นมองเห็น 100%",
    Callback = function()
        forgeItemWithBestOres(State.SelectedForgeTarget or "Weapon")
    end
})

UIControls.AutoForgeAfterOres = SecAutoForge:Toggle({
    Title = "ออโต้หลอมของทันทีเมื่อแร่ครบ (Auto Forge Loop)",
    Desc = "เมื่อมีแร่ครบ 4 ก้อนขึ้นไป ระบบจะหลอมไอเทมให้อัตโนมัติทันที",
    Value = State.AutoForgeAfterOres,
    Callback = function(val)
        State.AutoForgeAfterOres = val
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Auto Forge",
                Content = val and "เปิดระบบออโต้หลอมไอเทมจริงแล้ว!" or "ปิดระบบออโต้หลอมไอเทม",
                Duration = 3
            })
        end
    end
})

local SecMaterialSpawner = TabSpawner:Section({
    Title = "เสกหินตีบวก & วัสดุ (Ember Stones & Materials)",
    Desc = "ปั้มหินอัปเกรดอาวุธระดับสูง เพิ่มเข้ากระเป๋าจริง ออกเข้าใหม่ไม่หาย",
    Icon = "flame"
})

SecMaterialSpawner:Button({
    Title = "เสก Ember Stone (+5,000 ก้อน / คลิกเดียว)",
    Desc = "ปั้ม Ember Stone จำนวน 5,000 ก้อน เซฟถาวร 100%",
    Callback = function()
        pumpRealEmberStones(5000)
    end
})

SecMaterialSpawner:Button({
    Title = "เสก Ember Stone (+20,000 ก้อน / สปีดรัว)",
    Desc = "ปั้ม Ember Stone จำนวน 20,000 ก้อน บันทึก Server ถาวร",
    Callback = function()
        pumpRealEmberStones(20000)
    end
})

SecMaterialSpawner:Button({
    Title = "กดรับตั๋วดันเจี้ยน & ของขวัญประจำวัน (Claim Daily Tickets & Gifts)",
    Desc = "กดรับตั๋วดันเจี้ยนและรางวัลอัปเดตทั้งหมดทันที",
    Callback = function()
        pcall(function()
            if Remote_DungeonTicket then Remote_DungeonTicket:FireServer() end
            if Remote_OnlineClaim then Remote_OnlineClaim:FireServer() end
            if Remote_UpdateClaim then Remote_UpdateClaim:FireServer() end
            if Remote_OfflineClaim then Remote_OfflineClaim:FireServer() end
        end)
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K Spawner",
                Content = "ส่งคำขอรับตั๋วและรางวัลประจำวันทั้งหมดแล้ว!",
                Duration = 3
            })
        end
    end
})

local SecDungeonTokenSpawner = TabSpawner:Section({
    Title = "เสก & ปั๊ม Token ดันเจี้ยน (Fast Token Spawner Exploit)",
    Desc = "ปั๊มเหรียญ Token สำหรับซื้อของใน Token Shop ด้วย Multi-Thread 5x Engine",
    Icon = "ticket"
})

local lblTokenStatus = SecDungeonTokenSpawner:Paragraph({
    Title = "สถานะเหรียญ Token ปัจจุบัน (Token Status)",
    Desc = "กำลังโหลดข้อมูล...",
    Icon = "activity"
})

local function updateTokenStatusLabel()
    pcall(function()
        local ProfileData = require(ReplicatedStorage.ProfileData)
        local tData = ProfileData.GetStoreData("Token")
        local curTokens = (tData and tData.value) or 0
        local DungeonData = require(ReplicatedStorage.LocalData.DungeonData)
        local maxR = (DungeonData and DungeonData.GetMaxRound and DungeonData.GetMaxRound()) or 0
        lblTokenStatus:SetDesc(string.format("🪙 Token ในตัว: %s | ด่านสูงสุดที่ปลดล็อค: %d | รอบที่ปั๊มสะสม: %d", tostring(curTokens), maxR, tokenFarmRoundsCompleted))
    end)
end
task.spawn(updateTokenStatusLabel)

SecDungeonTokenSpawner:Button({
    Title = "⚡ เสก Token ทันที (รัน 5-Thread Exploit ด่าน 50)",
    Desc = "เคลมตั๋ว + เข้าด่าน 50 + รัน 5 Workers ปั๊มรอบรัวจนกว่าจะหมด",
    Callback = function()
        runDungeonTokenFarm(State.TokenDungeonRound or 50, State.TokenWorkers or 5, function(rds)
            pcall(function()
                lblTokenStatus:SetDesc(string.format("⚡ กำลังปั๊ม Token... ผ่านไปแล้ว %d รอบ!", rds))
            end)
        end, function(rds, success, curTokens)
            updateTokenStatusLabel()
        end)
    end
})

SecDungeonTokenSpawner:Slider({
    Title = "เลือกรอบดันเจี้ยนที่จะปั๊ม (Target Round: 1 - 50)",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = State.TokenDungeonRound or 50 },
    Callback = function(val)
        State.TokenDungeonRound = val
    end
})

SecDungeonTokenSpawner:Slider({
    Title = "จำนวน Worker Threads (1 - 10 Threads)",
    Step = 1,
    Value = { Min = 1, Max = 10, Default = State.TokenWorkers or 5 },
    Callback = function(val)
        State.TokenWorkers = val
    end
})

UIControls.AutoFarmTokens = SecDungeonTokenSpawner:Toggle({
    Title = "วนลูปปั๊ม Token อัตโนมัติ (Auto Token Farm Loop)",
    Desc = "เช็คตั๋วและวนลูปปั๊ม Token ต่อเนื่องอัตโนมัติเมื่อพร้อม",
    Value = State.AutoFarmTokens,
    Callback = function(val)
        State.AutoFarmTokens = val
        if val then
            task.spawn(function()
                while State.AutoFarmTokens and _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
                    if not isFarmingTokens then
                        runDungeonTokenFarm(State.TokenDungeonRound or 50, State.TokenWorkers or 5, function(rds)
                            pcall(function()
                                lblTokenStatus:SetDesc(string.format("⚡ Auto Farm วนลูป... ผ่านไปแล้ว %d รอบ!", rds))
                            end)
                        end, function()
                            updateTokenStatusLabel()
                        end)
                    end
                    task.wait(5)
                end
            end)
        end
    end
})

SecDungeonTokenSpawner:Button({
    Title = "🔓 ปลดล็อคด่าน 1 - 50 ทันที (Auto Unlock All Rounds 1-50)",
    Desc = "เร่งเคลียร์ด่านแบบสปีดสูง เพื่อปลดล็อคด่าน 50 สำหรับปั๊ม Token สูงสุด",
    Callback = function()
        autoUnlockDungeonRounds(50)
    end
})

SecDungeonTokenSpawner:Button({
    Title = "🚪 ออกจากดันเจี้ยน / รีเซ็ตสถานะ (Emergency Exit Dungeon)",
    Desc = "วาร์ปออกจากดันเจี้ยนกลับสู่จุดเกิดหลัก และรีเซ็ตสถานะการต่อสู้",
    Callback = function()
        pcall(function()
            local DS = Remotes and (Remotes:FindFirstChild("Dungeon_Server") or Remotes:FindFirstChild("Dungeon"))
            if DS and DS:FindFirstChild("TryIntoDungeonRF") then
                DS.TryIntoDungeonRF:InvokeServer(false)
            end
        end)
        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K Dungeon", Content = "ส่งคำขอออกจากดันเจี้ยนแล้ว!", Duration = 3 })
        end
        task.wait(0.5)
        updateTokenStatusLabel()
    end
})


-- UI Controls in TabFPS
TabFPS:Section({ Title = "ระบบลดแล็กหลัก (Core Lag Reducers)" })

UIControls.DisableVFX = TabFPS:Toggle({
    Title = "ปิดเอฟเฟกต์ & พาร์ติเคิลทั้งหมด (Disable All Particle VFX)",
    Desc = "ปิดพาร์ติเคิล แสง เงา ไฮไลต์ทั้งหมดในเกม ช่วยเพิ่ม FPS สูงสุด",
    Value = State.DisableVFX,
    Callback = function(val)
        State.DisableVFX = val
        setVFXEnabled(not val)
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K FPS", Content = val and "ปิดเอฟเฟกต์พาร์ติเคิลทั้งหมดแล้ว!" or "เปิดเอฟเฟกต์ตามปกติ" })
        end
    end
})

UIControls.MuteGamePopups = TabFPS:Toggle({
    Title = "ปิดการแจ้งเตือน & ป๊อปอัปในเกม (Mute In-Game Messages & Popups)",
    Desc = "ปิดข้อความ 'Sell success.' และป๊อปอัปไอเทมที่เด้งรัวๆ ตอนฟาร์ม",
    Value = State.MuteGamePopups,
    Callback = function(val)
        State.MuteGamePopups = val
        setGamePopupsMuted(val)
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K FPS", Content = val and "ปิดการแจ้งเตือนและป๊อปอัป Sell success แล้ว!" or "เปิดการแจ้งเตือนตามปกติ" })
        end
    end
})

UIControls.LowGraphics = TabFPS:Toggle({
    Title = "โหมดภาพต่ำลื่นพิเศษ (Super Low Graphics / Potato Mode)",
    Desc = "ปรับวัตถุทั้งหมดเป็น SmoothPlastic ลบเงาและปรับแสงต่ำเพื่อความลื่น",
    Value = State.LowGraphics,
    Callback = function(val)
        State.LowGraphics = val
        applyLowGraphics(val)
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K FPS", Content = val and "เปิดโหมดภาพต่ำ (Potato Mode) แล้ว!" or "คืนค่ากราฟิกตามปกติ" })
        end
    end
})

UIControls.HideOtherPlayers = TabFPS:Toggle({
    Title = "ซ่อนตัวละครผู้เล่นคนอื่น (Hide Other Players)",
    Desc = "ทำให้ตัวละครคนอื่นโปร่งใส ลดการประมวลผลโมเดลและแอนิเมชัน",
    Value = State.HideOtherPlayers,
    Callback = function(val)
        State.HideOtherPlayers = val
        updateHideOtherPlayers(val)
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2K FPS", Content = val and "ซ่อนตัวละครคนอื่นเรียบร้อย!" or "แสดงตัวละครคนอื่นตามปกติ" })
        end
    end
})

TabFPS:Section({ Title = "ประหยัดพลังงาน & ฟาร์มข้ามคืน (AFK & GPU Saver)" })

UIControls.LimitFPS30 = TabFPS:Toggle({
    Title = "จำกัด 30 FPS ตอนฟาร์ม (Cap 30 FPS for AFK)",
    Desc = "ล็อก FPS ไว้ที่ 30 เพื่อไม่ให้เครื่องร้อนขณะเปิดทิ้งไว้",
    Value = State.LimitFPS30,
    Callback = function(val)
        State.LimitFPS30 = val
        pcall(function()
            if setfpscap then
                setfpscap(val and 30 or 240)
            end
        end)
    end
})

TabFPS:Section({ Title = "ล้างหน่วยความจำ (Memory & Cache Cleaner)" })

TabFPS:Button({
    Title = "ล้าง RAM & แคชเอฟเฟกต์ทันที (Clear Memory Now)",
    Desc = "กำจัดขยะหน่วยความจำและเอฟเฟกต์ตกค้างในเกมทันที",
    Callback = function()
        runMemoryCleaner()
    end
})


-- TAB 6: ตั้งค่าระบบ & ผู้เล่น (Settings & Config)

TabSettings:Section({ Title = "ระบบบันทึกการตั้งค่า (Config & Automation)" })

UIControls.AutoLoadConfig = TabSettings:Toggle({
    Title = "โหลดการตั้งค่าอัตโนมัติ (Auto-Load on Start)",
    Desc = "เมื่อรันสคริปต์ จะดึงค่าที่เคยบันทึกไว้กลับมาทำงานทันที",
    Value = (State.AutoLoadConfig ~= false),
    Callback = function(val)
        State.AutoLoadConfig = val
        autoSaveConfig()
    end
})

UIControls.AutoSaveConfig = TabSettings:Toggle({
    Title = "บันทึกการตั้งค่าอัตโนมัติ (Auto-Save on Change)",
    Desc = "บันทึกลงเครื่องทันทีที่มีการเปิด/ปิดสวิตช์หรือเปลี่ยนตัวเลือก",
    Value = (State.AutoSaveConfig ~= false),
    Callback = function(val)
        State.AutoSaveConfig = val
        if val then saveConfig(true) end
    end
})

TabSettings:Button({
    Title = "บันทึกการตั้งค่าทันที (Save Config Now)",
    Desc = "เซฟ State ปัจจุบันลงไฟล์ JSON ในเครื่อง",
    Callback = function()
        saveConfig(false)
    end
})

TabSettings:Button({
    Title = "โหลดการตั้งค่าทันที (Load Config Now)",
    Desc = "ดึงค่าจากไฟล์ JSON อัปเดตลง UI Controls ทุกตัว",
    Callback = function()
        loadConfig(false)
    end
})

TabSettings:Button({
    Title = "รีเซ็ตการตั้งค่า (Reset Default Config)",
    Desc = "ลบคอนฟิกออกและคืนค่าทั้งหมดเป็นค่าเริ่มต้น",
    Callback = function()
        if delfile and isfile and isfile(CONFIG_FILE) then
            pcall(function() delfile(CONFIG_FILE) end)
        end
        _G.TwoSkiSavedConfig = nil
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K CONFIG",
                Content = "รีเซ็ตการตั้งค่าเป็นค่าเริ่มต้นเรียบร้อย!",
                Duration = 2.5
            })
        end
    end
})

UIControls.AntiAfk = TabSettings:Toggle({
    Title = "ป้องกันการหลุดอัตโนมัติ (Anti-AFK 24/7)",
    Desc = "ป้องกันเกมตัดการเชื่อมต่อเมื่อเปิดบอททิ้งไว้นานๆ",
    Value = State.AntiAfk,
    Callback = function(val)
        State.AntiAfk = val
        autoSaveConfig()
    end
})

TabSettings:Section({ Title = "ขนาดหน้าต่างและการแสดงผล (Window Scaling & Mobile Display)" })

TabSettings:Button({
    Title = "ย่อ / ซ่อนหน้าต่างทันที (Minimize to 2K Badge)",
    Desc = "พับหน้าต่างเก็บไว้ เหลือแค่ไอคอน 2K ลอยบนจอเพื่อไม่ให้บังเกม",
    Callback = function()
        toggleMainWindow()
    end
})

UIControls.CustomUIScale = TabSettings:Slider({
    Title = "ปรับขนาดหน้าต่าง UI (UI Window Scale %)",
    Desc = "ปรับขนาดหน้าต่าง (40% ถึง 120%) เลื่อนแล้วเปลี่ยนขนาดทันที",
    Min = 40,
    Max = 120,
    Default = math.floor(((State.CustomUIScale and State.CustomUIScale > 1.5 and (State.CustomUIScale / 100)) or State.CustomUIScale or (isMobile and 0.70 or 1.00)) * 100),
    Callback = function(val)
        local num = tonumber(val) or 100
        if num <= 1.5 then num = num * 100 end
        local scale = math.clamp(num / 100, 0.40, 1.25)
        State.CustomUIScale = scale
        _G.TwoSkiCustomScale = scale
        if Window and Window.SetScale then
            Window:SetScale(scale)
        elseif Window and Window.UIScale then
            Window.UIScale.Scale = scale
        end
    end
})

UIControls.UISizePreset = TabSettings:Dropdown({
    Title = "ขนาดหน้าต่างสำเร็จรูป (Quick Scale Presets)",
    Desc = "กดเลือกขนาดที่ต้องการได้ทันที",
    Values = {
        "มินิ มือถือจอเล็ก (Mini 0.55x)",
        "พอดีมือถือ (Mobile Standard 0.70x)",
        "ขนาดกลาง แท็บเล็ต (Tablet Medium 0.85x)",
        "มาตรฐาน PC เต็มจอ (Desktop Standard 1.00x)"
    },
    Value = (isMobile and "พอดีมือถือ (Mobile Standard 0.70x)" or "มาตรฐาน PC เต็มจอ (Desktop Standard 1.00x)"),
    Callback = function(val)
        local targetScale = 1.00
        if val:find("0.55x") then
            targetScale = 0.55
        elseif val:find("0.70x") then
            targetScale = 0.70
        elseif val:find("0.85x") then
            targetScale = 0.85
        elseif val:find("1.00x") then
            targetScale = 1.00
        end
        State.CustomUIScale = targetScale
        _G.TwoSkiCustomScale = targetScale
        if Window and Window.SetScale then
            Window:SetScale(targetScale)
        elseif Window and Window.UIScale then
            Window.UIScale.Scale = targetScale
        end
        if UIControls.CustomUIScale and UIControls.CustomUIScale.SetValue then
            pcall(function() UIControls.CustomUIScale:SetValue(math.floor(targetScale * 100)) end)
        end
    end
})

TabSettings:Section({ Title = "ระบบธีมสี 2SKI (Theme Color Presets)" })

UIControls.CurrentTheme = TabSettings:Dropdown({
    Title = "เลือกพาเลทสี (Color Palette Selector)",
    Values = {
        "2SKI Cyber Cyan (ธีมหลักทางการ - ขาว ฟ้าเรืองแสง Electric Blue)",
        "Tiffany Pastel Mint (สีเขียวมิ้นท์พาสเทล)",
        "Sky Blue Glow (ฟ้านีออนสว่าง)",
        "Neon Emerald (เขียวมรกตนีออน)",
        "Cyber Violet (ม่วงไซเบอร์)",
        "Neon Rose (ชมพูกุหลาบไฟ)",
        "Golden Amber (ทองอำพันพรีเมียม)",
        "Electric Blue (น้ำเงินสดใส)"
    },
    Value = State.CurrentTheme,
    Callback = function(val)
        State.CurrentTheme = val
        if applyThemePreset then
            pcall(function() applyThemePreset(val) end)
        end
        if _G.TwoSkiLoaded and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "2SKI Themes", Content = "เปลี่ยนธีมสีเรียบร้อย: " .. tostring(val) })
        end
    end
})

UIControls.FloatingButtonVisible = TabSettings:Toggle({
    Title = "แสดงปุ่มลอย 2K (Floating Button)",
    Desc = "เปิด/ปิดการแสดงปุ่มลอยบนหน้าจอ (สามารถกด LeftControl เพื่อเปิด/ปิดแทนได้)",
    Value = (State.FloatingButtonVisible ~= false),
    Callback = function(val)
        State.FloatingButtonVisible = val
        if _G.TwoSkiFloatGui then _G.TwoSkiFloatGui.Enabled = val end
    end
})

UIControls.FloatingButtonPosition = TabSettings:Dropdown({
    Title = "ตำแหน่งปุ่มลอย (Floating Button Position)",
    Desc = "เลือกย้ายตำแหน่งปุ่มลอยไปจุดที่ปลอดภัย ไม่บังปุ่มเกมใดๆ",
    Values = {
        "แถบบนซ้ายติดแชท (TopBar Left - ปลอดภัย 100%)",
        "แถบบนขวา (TopBar Right)",
        "ด้านขวากลางจอ (Right Center)",
        "ด้านซ้ายกลางจอ (Left Center)"
    },
    Value = "แถบบนซ้ายติดแชท (TopBar Left - ปลอดภัย 100%)",
    Callback = function(val)
        local pos = UDim2.new(0, 168, 0, 26)
        if val == "แถบบนขวา (TopBar Right)" then
            pos = UDim2.new(1, -168, 0, 26)
        elseif val == "ด้านขวากลางจอ (Right Center)" then
            pos = UDim2.new(1, -55, 0.35, 0)
        elseif val == "ด้านซ้ายกลางจอ (Left Center)" then
            pos = UDim2.new(0, 55, 0.45, 0)
        end
        if _G.TwoSkiFloatPanel and _G.TwoSkiFloatAura then
            _G.TwoSkiFloatPanel.Position = pos
            _G.TwoSkiFloatAura.Position = pos
        end
    end
})

TabSettings:Section({ Title = "ความสามารถตัวละคร (Character Physics)" })

local function syncSpeedToHumanoid(hum)
    if not hum then return end
    pcall(function()
        hum.MaxSlopeAngle = 89
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        if State.WalkSpeed and State.WalkSpeed ~= 16 then
            hum.WalkSpeed = State.WalkSpeed
        end
    end)
end

local hookedHumanoids = {}
local function hookHumanoidJump(hum)
    if not hum or hookedHumanoids[hum] then return end
    hookedHumanoids[hum] = true
    pcall(function()
        hum.UseJumpPower = true
        local jp = (State.JumpPower and State.JumpPower > 30) and State.JumpPower or 50
        hum.JumpPower = jp
        local grav = (workspace.Gravity and workspace.Gravity > 0) and workspace.Gravity or 250
        hum.JumpHeight = (jp * jp) / (2 * grav)
        hum.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping then
                local _, hrp = getCharHrp()
                if hrp then
                    local targetJp = (State.JumpPower and State.JumpPower > 30) and State.JumpPower or 50
                    if hrp.AssemblyLinearVelocity.Y < (targetJp * 0.85) then
                        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, targetJp, hrp.AssemblyLinearVelocity.Z)
                    end
                end
            end
        end)
    end)
end

-- Hook Character Respawn (CharacterAdded)
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
    if hum then
        syncSpeedToHumanoid(hum)
        hookHumanoidJump(hum)
    end
    if State.Noclip then
        updateNoclipConnection()
    end
    if State.ShadowSovereignMorph then
        task.delay(0.5, function()
            if State.ShadowSovereignMorph and char and char.Parent then
                pcall(applyShadowSovereignMorph, char)
            end
        end)
    end
end))

do
    local _, _, initHum = getCharHrp()
    if initHum then
        syncSpeedToHumanoid(initHum)
        hookHumanoidJump(initHum)
    end
end

UIControls.WalkSpeed = TabSettings:Slider({
    Title = "ความเร็วเดิน (WalkSpeed)",
    Step = 1,
    Value = { Min = 16, Max = 250, Default = State.WalkSpeed },
    Callback = function(val)
        State.WalkSpeed = val
        local _, _, hum = getCharHrp()
        if hum then hum.WalkSpeed = val end
    end
})

UIControls.JumpPower = TabSettings:Slider({
    Title = "พลังการกระโดด (JumpPower)",
    Step = 1,
    Value = { Min = 50, Max = 300, Default = State.JumpPower },
    Callback = function(val)
        State.JumpPower = val
        local _, _, hum = getCharHrp()
        if hum then hum.UseJumpPower = true; hum.JumpPower = val end
    end
})

UIControls.InfiniteJump = TabSettings:Toggle({
    Title = "กระโดดไร้ขีดจำกัด (Infinite Jump)",
    Value = State.InfiniteJump,
    Callback = function(val) State.InfiniteJump = val end
})

table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local _, hrp, hum = getCharHrp()
        if hrp and hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            local jp = (State.JumpPower and State.JumpPower > 30) and State.JumpPower or 50
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, jp, hrp.AssemblyLinearVelocity.Z)
        end
    end
end))

local function updateNoclipConnection()
    if State.Noclip or State.ManualFly then
        if not noclipCon then
            noclipCon = RunService.Stepped:Connect(function()
                if not (State.Noclip or State.ManualFly) then
                    if noclipCon then noclipCon:Disconnect(); noclipCon = nil end
                    return
                end
                local char = LocalPlayer.Character
                if char then
                    for _, p in ipairs(char:GetChildren()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipCon then noclipCon:Disconnect(); noclipCon = nil end
    end
end

UIControls.Noclip = TabSettings:Toggle({
    Title = "เดินทะลุกำแพง & สิ่งกีดขวาง (Noclip All)",
    Value = State.Noclip,
    Callback = function(val)
        State.Noclip = val
        updateNoclipConnection()
    end
})

local function updateManualFly()
    if State.ManualFly then
        local char, hrp, hum = getCharHrp()
        if not hrp or not hum then return end

        if not manualFlyBv or not manualFlyBv.Parent or manualFlyBv.Parent ~= hrp then
            local old = hrp:FindFirstChild("TwoSkiManualFlyBV")
            if old then old:Destroy() end
            manualFlyBv = Instance.new("BodyVelocity")
            manualFlyBv.Name = "TwoSkiManualFlyBV"
            manualFlyBv.MaxForce = Vector3.new(2e6, 2e6, 2e6)
            manualFlyBv.Velocity = Vector3.zero
            manualFlyBv.Parent = hrp
        end

        if not manualFlyBg or not manualFlyBg.Parent or manualFlyBg.Parent ~= hrp then
            local oldBg = hrp:FindFirstChild("TwoSkiManualFlyBG")
            if oldBg then oldBg:Destroy() end
            manualFlyBg = Instance.new("BodyGyro")
            manualFlyBg.Name = "TwoSkiManualFlyBG"
            manualFlyBg.MaxTorque = Vector3.new(0, 4e6, 0)
            manualFlyBg.P = 4000
            manualFlyBg.D = 400
            manualFlyBg.CFrame = hrp.CFrame
            manualFlyBg.Parent = hrp
        end

        hum.PlatformStand = true
        updateNoclipConnection()

        if not manualFlyCon then
            local flyCurrentVel = Vector3.zero
            manualFlyCon = RunService.RenderStepped:Connect(function(dt)
                if not State.ManualFly then
                    if manualFlyCon then manualFlyCon:Disconnect(); manualFlyCon = nil end
                    return
                end
                local _, h, hm = getCharHrp()
                if not h or not hm or hm.Health <= 0 then return end
                hm.PlatformStand = true

                local cam = workspace.CurrentCamera
                local camCF = cam and cam.CFrame or h.CFrame
                local speed = State.ManualFlySpeed or 100
                local dir = Vector3.zero

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

                if dir.Magnitude == 0 and hm.MoveDirection.Magnitude > 0 then
                    local rel = camCF:VectorToObjectSpace(hm.MoveDirection)
                    dir = (camCF.LookVector * (-rel.Z) + camCF.RightVector * rel.X)
                end

                local targetVel = dir.Magnitude > 0.05 and (dir.Unit * speed) or Vector3.zero
                flyCurrentVel = flyCurrentVel:Lerp(targetVel, math.clamp(dt * 18, 0.15, 1.0))
                if manualFlyBv and manualFlyBv.Parent == h then manualFlyBv.Velocity = flyCurrentVel end
                if manualFlyBg and manualFlyBg.Parent == h then
                    local look = camCF.LookVector
                    local flatLook = Vector3.new(look.X, 0, look.Z)
                    if flatLook.Magnitude > 0.001 then manualFlyBg.CFrame = CFrame.lookAt(h.Position, h.Position + flatLook.Unit) end
                end
            end)
            table.insert(Connections, manualFlyCon)
        end
    else
        if manualFlyCon then manualFlyCon:Disconnect(); manualFlyCon = nil end
        if manualFlyBv then pcall(function() manualFlyBv:Destroy() end); manualFlyBv = nil end
        if manualFlyBg then pcall(function() manualFlyBg:Destroy() end); manualFlyBg = nil end
        local _, _, hum = getCharHrp()
        if hum then hum.PlatformStand = false end
        updateNoclipConnection()
    end
end

UIControls.ManualFly = TabSettings:Toggle({
    Title = "บินอิสระ / บินเอง (Manual Fly [F])",
    Value = State.ManualFly,
    Callback = function(val)
        State.ManualFly = val
        updateManualFly()
        if _G.TwoSkiLoaded then
            WindUI:Notify({ Title = "2SKI Fly", Content = val and "เปิดโหมดบินอิสระ [F] เรียบร้อย!" or "ปิดโหมดบินอิสระ" })
        end
    end
})

UIControls.ManualFlySpeed = TabSettings:Slider({
    Title = "ความเร็วบินอิสระ (Fly Speed)",
    Step = 5,
    Value = { Min = 20, Max = 350, Default = State.ManualFlySpeed },
    Callback = function(val) State.ManualFlySpeed = val end
})

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.F then
        State.ManualFly = not State.ManualFly
        if UIControls.ManualFly then
            pcall(function()
                if UIControls.ManualFly.SetValue then UIControls.ManualFly:SetValue(State.ManualFly)
                elseif UIControls.ManualFly.Set then UIControls.ManualFly:Set(State.ManualFly) end
            end)
        end
        updateManualFly()
    end
end))

UIControls.AntiAfk = TabSettings:Toggle({
    Title = "ป้องกันการหลุดอัตโนมัติ (Anti-AFK 24/7)",
    Value = State.AntiAfk,
    Callback = function(val) State.AntiAfk = val end
})

-- TAB 7: คอมมูนิตี้ & ข้อมูลสคริปต์ (Community & Info)

local SecDiscord = TabCommunity:Section({
    Title = "2K SCRIPT COMMUNITY (คอมมูนิตี้ทางการ)",
    Desc = "ช่องทางหลัก แจกสคริปต์ อัปเดต และพูดคุย",
    Icon = "ticket"
})

SecDiscord:Paragraph({
    Title = "Discord Official Link",
    Desc = "https://discord.gg/4Yg72kYT6s\nกดปุ่มด้านล่างเพื่อคัดลอกลิงก์เข้าร่วมดิสคอร์ดได้ทันที!",
    Icon = "gift"
})

SecDiscord:Button({
    Title = "คัดลอกลิงก์ Discord (Copy Discord Link)",
    Desc = "https://discord.gg/4Yg72kYT6s",
    Icon = "ticket",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/4Yg72kYT6s")
        elseif toclipboard then
            toclipboard("https://discord.gg/4Yg72kYT6s")
        end
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K SCRIPT",
                Content = "คัดลอกลิงก์ Discord ลง Clipboard แล้ว!",
                Duration = 3
            })
        end
    end
})

SecDiscord:Button({
    Title = "เข้าร่วมดิสคอร์ดอัตโนมัติ (Join Discord App)",
    Desc = "เปิดคำเชิญเข้าดิสคอร์ดโดยตรงผ่านแอป Discord บนเครื่อง",
    Icon = "ticket",
    Callback = function()
        local httpReq = request or http_request or (syn and syn.request) or (http and http.request)
        if httpReq then
            pcall(function()
                httpReq({
                    Url = "http://127.0.0.1:6463/rpc?v=1",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Origin"] = "https://discord.com"
                    },
                    Body = HttpService:JSONEncode({
                        cmd = "INVITE_BROWSER",
                        args = { code = "4Yg72kYT6s" },
                        nonce = HttpService:GenerateGUID(false)
                    })
                })
            end)
        end
        if setclipboard then
            setclipboard("https://discord.gg/4Yg72kYT6s")
        elseif toclipboard then
            toclipboard("https://discord.gg/4Yg72kYT6s")
        end
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K SCRIPT",
                Content = "ส่งคำเชิญไปยัง Discord App และคัดลอกลิงก์แล้ว!",
                Duration = 3
            })
        end
    end
})

local SecHubInfo = TabCommunity:Section({
    Title = "ข้อมูลและเวอร์ชัน (Hub Information)",
    Desc = "สถานะระบบและความปลอดภัย",
    Icon = "crown"
})

SecHubInfo:Paragraph({
    Title = "2SKI Engine",
    Desc = "Version: 3.2.0-CYBER\nTarget: Loot to Forge Master (x2)\nDeveloper: 2K Team & clack\nDiscord: discord.gg/4Yg72kYT6s\nConfig Engine: JSON Auto-Load System\nStatus: Operational & Undetected",
    Icon = "shield-check"
})

SecHubInfo:Paragraph({
    Title = "Creator & Credits",
    Desc = "Created by clack & 2K Script Studio\nProtected by 2SKI Core Architecture",
    Icon = "user"
})

-- Anti-AFK System 24/7 (Triple-Protected: Connection Disable + Idled Hook + Active Heartbeat)
local function setupAntiAfk()
    -- 1. Disable Roblox's default Idled connections so the 20-min AFK dialog never triggers
    if getconnections then
        pcall(function()
            for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
                if conn.Disable then
                    conn:Disable()
                elseif conn.Disconnect then
                    conn:Disconnect()
                end
            end
        end)
    end

    -- 2. Hook Idled event with VirtualUser simulation
    table.insert(Connections, LocalPlayer.Idled:Connect(function()
        if State.AntiAfk then
            pcall(function()
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end
            end)
        end
    end))

    -- 3. Active Background Heartbeat (Simulates active user input every 120s)
    task.spawn(function()
        while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
            task.wait(120)
            if State.AntiAfk then
                pcall(function()
                    if VirtualUser then
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(10, 10))
                    end
                    if VirtualInputManager then
                        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                    end
                end)
            end
        end
    end)
end

setupAntiAfk()

-- Configuration System Load Engine (Already loaded in core)

---------------------------------------------------------------------
-- BACKGROUND AUTOMATION LOOPS (HIGH EFFICIENCY)
---------------------------------------------------------------------

-- Loop 1: Auto Train Power Loop (Power Multiplier Zone & Normal Train & x100 VIP Zone)
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        if State.AutoTrain or State.AutoTrainBestZone or State.AutoTrainX100 then
            if LocalPlayer:GetAttribute("IntoFight") == "Dungeon" or LocalPlayer:GetAttribute("IntoFight") == "WorldBoss" or LocalPlayer:GetAttribute("StageID") == -1 then
                task.wait(0.5)
                continue
            end
            local targetZone = nil
            if State.AutoTrainX100 then
                targetZone = getZoneByName("9") or TrainAreaConfig[9]
            elseif State.AutoTrainBestZone then
                targetZone = (State.SelectedTrainZone == "Auto Best (แท่นคูณสูงสุดที่ปลดล็อค)") and getBestTrainZone() or (getZoneByName(State.SelectedTrainZone) or getBestTrainZone())
            end

            if targetZone then
                local _, hrp, hum = getCharHrp()
                if hrp and hum and hum.Health > 0 then
                    local curPos = hrp.Position
                    local dist = (Vector3.new(curPos.X, targetZone.PadPos.Y, curPos.Z) - targetZone.PadPos).Magnitude
                    if dist > 6 then
                        hrp.CFrame = CFrame.lookAt(targetZone.PadPos + Vector3.new(0, 1.0, 0), targetZone.DummyPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        task.wait(0.1)
                    end
                end

                -- Keep IntoAutoTrain remote registered with server without triggering physical touch prompt
                if Remote_IntoAutoTrain then
                    pcall(function() Remote_IntoAutoTrain:FireServer(targetZone.Id) end)
                end
            end

            -- Fire both client animation and server remote for maximum reliable power gain
            pcall(function()
                if TrainCTRL and TrainCTRL.TrainOnce then
                    TrainCTRL.TrainOnce()
                end
                if Remote_TrainOnce then
                    Remote_TrainOnce:FireServer()
                end
            end)
            task.wait(0.15)
        else
            if LocalPlayer:GetAttribute("AutoTrainAreaID") then
                if Remote_ExitAutoTrain then
                    pcall(function() Remote_ExitAutoTrain:FireServer() end)
                end
            end
            task.wait(0.6)
        end
    end
end)

-- Loop 2: Auto Stage & Crystal Farm Loop (Remote Server Clear - No Character Teleportation)
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        if State.AutoClearStage and Remote_StageFinished and Remote_GetOre and Remote_ClaimedAllOre then
            if LocalPlayer:GetAttribute("IntoFight") == "WorldBoss" then
                task.wait(0.5)
                continue
            end
            -- 1. Determine Stage ID (Supports Selected Stage or Auto Max)
            local stageId = State.SelectedStage
            if not stageId or stageId:find("Auto Max") then
                local pd = ProfileData and ProfileData.GetTotalData()
                local maxPass = pd and pd.Stats and pd.Stats.StagePass or 0
                local targetNum = math.clamp(maxPass + 1, 1, 27)
                stageId = "Stage_" .. tostring(targetNum)
            else
                local clean = stageId:match("Stage_%d+")
                if clean then
                    stageId = clean
                else
                    stageId = tostring(stageId)
                end
            end

            -- 2. Check Backpack Ore Capacity & Forge if full or threshold met
            local bp = BackpackData and BackpackData.GetData()
            local oreCount = 0
            if bp and bp.have then
                for _, item in pairs(bp.have) do
                    if item.Type == "Ore" then oreCount = oreCount + (item.Number or 1) end
                end
            end
            local maxOre = (UpgradeData and UpgradeData.GetMaxNum and UpgradeData.GetMaxNum("OrePack")) or 6

            if oreCount >= maxOre or (State.AutoForge and oreCount >= (State.MinOreToForge or 4)) then
                if State.AutoForge then
                    executeForgeNow(State.ForgeType, math.min(State.MinOreToForge or 4, maxOre))
                    task.wait(0.2)
                end
            end

            -- 3. Clear Stage on Server & Claim Loot (No Physical Teleport Needed)
            local ok, ores = pcall(function()
                return Remote_StageFinished:InvokeServer(stageId)
            end)

            if ok and type(ores) == "table" then
                for oreUuid, dropItem in pairs(ores) do
                    if type(dropItem) ~= "table" then
                        pcall(function() Remote_GetOre:InvokeServer(oreUuid) end)
                    elseif Remote_GetEnhantStone then
                        pcall(function() Remote_GetEnhantStone:FireServer(oreUuid) end)
                    end
                end
                pcall(function() Remote_ClaimedAllOre:FireServer() end)
            end

            -- 4. Insta-Kill Stage Mobs in EnemyFolder (Silent Clean Without Moving)
            local ef = workspace:FindFirstChild("EnemyFolder")
            if ef then
                for _, enemy in ipairs(ef:GetChildren()) do
                    if enemy:IsA("Model") and not enemy:GetAttribute("Dead") then
                        killEnemyEntity(enemy)
                    end
                end
            end

            -- 5. Sweep world dropped ores / crystals across map
            if State.AutoCollectCrystals and collectAllWorldOres then
                pcall(collectAllWorldOres)
            end

            -- 6. Auto Forge & Equip Best
            if State.AutoForge then
                pcall(function()
                    executeForgeNow(State.ForgeType, State.MinOreToForge)
                    equipBestGearNow("All")
                end)
            end

            task.wait(math.clamp(State.StageDelay or 0.35, 0.15, 3.0))
        else
            if State.AutoCollectCrystals and collectAllWorldOres then
                pcall(collectAllWorldOres)
            end
            task.wait(0.6)
        end
    end
end)

-- Loop 3: Auto Money, Gear Sell, Ore Sell & Enchant Sell Loop (Completely Decoupled & Independent)
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        -- 1. Auto Sell Trash Gear (Strictly Weapons, Armors, Hats - Ores & Enchant Stones are NEVER touched)
        if State.AutoSellGear or State.AutoSellAll then
            pcall(sellTrashGearNow)
            task.wait(0.15)
        end

        -- 2. Auto Sell Ores (Independent toggle - sells carried ores for coins based on ore filter)
        if State.AutoSellOres then
            pcall(sellOresNow)
            task.wait(0.15)
        end

        -- 3. Auto Sell Enchant Stones (Independent toggle - sells carried stones based on enchant filter)
        if State.AutoSellEnchant then
            pcall(sellEnchantStonesNow)
            task.wait(0.15)
        end

        -- 4. Auto Collect Money & Online Gifts (Only collects gifts/money, NEVER sells items)
        if State.AutoCollectMoney or State.AutoClaimOnline then
            if OnlineData and OnlineData.TryClaim then
                pcall(function()
                    for i = 1, 12 do
                        OnlineData.TryClaim(tostring(i))
                        task.wait(0.02)
                    end
                end)
            end
        end

        if State.AutoCollectMoney or State.AutoClaimGifts then
            pcall(function()
                if Remote_UpdateClaim then Remote_UpdateClaim:FireServer() end
                if Remote_OfflineClaim then Remote_OfflineClaim:FireServer() end
                if Remote_DungeonTicket then Remote_DungeonTicket:FireServer() end
                if Remote_IndexExp then
                    task.spawn(function()
                        pcall(function() Remote_IndexExp:InvokeServer() end)
                    end)
                end
                if Remote_IndexLvlReward then
                    for lvl = 1, 10 do
                        task.spawn(function()
                            pcall(function() Remote_IndexLvlReward:InvokeServer(lvl) end)
                        end)
                    end
                end
            end)
        end

        task.wait(2.2)
    end
end)

-- Loop 4: Auto Upgrades & Rebirth Loop (With Coin Balance Check)
task.spawn(function()
    local lastUpgradeTick = 0
    local lastRebirthTick = 0
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        local now = tick()
        if (State.AutoUpgradeAll or State.AutoUpgradeTrain or State.AutoUpgradeLuck or State.AutoUpgradeOrePack) and (now - lastUpgradeTick >= 1.5) then
            lastUpgradeTick = now
            pcall(function()
                local pd = ProfileData and ProfileData.GetTotalData()
                local curCoins = pd and pd.Eco and pd.Eco.coin or 0
                local upgradesToTry = {}
                if State.AutoUpgradeAll or State.AutoUpgradeTrain then table.insert(upgradesToTry, "Train") end
                if State.AutoUpgradeAll or State.AutoUpgradeLuck then table.insert(upgradesToTry, "Luck") end
                if State.AutoUpgradeAll or State.AutoUpgradeOrePack then table.insert(upgradesToTry, "OrePack") end

                for _, name in ipairs(upgradesToTry) do
                    local curLvl = (UpgradeData and UpgradeData.GetLevel and UpgradeData.GetLevel(name)) or 0
                    local price = (UpgradeHelper and UpgradeHelper.GetPrice and UpgradeHelper.GetPrice(name, curLvl + 1)) or 0
                    local isMax = (UpgradeHelper and UpgradeHelper.CheckIsMax and UpgradeHelper.CheckIsMax(name, curLvl)) or false
                    if not isMax and curCoins >= price and Remote_UpgradeOnce then
                        Remote_UpgradeOnce:FireServer(name)
                        curCoins = curCoins - price
                        task.wait(0.05)
                    end
                end
            end)
        end

        if State.AutoRebirth and (now - lastRebirthTick >= 2.0) and Remote_TryRebirth then
            lastRebirthTick = now
            pcall(function()
                local ready = checkRebirthStatus()
                if ready then
                    -- Prevent "Pack is full." rejection by selling junk equipment/ores before Rebirth
                    if Remote_TrySellAll then
                        pcall(function() Remote_TrySellAll:FireServer() end)
                        task.wait(0.15)
                    end
                    Remote_TryRebirth:FireServer()
                    refreshRebirthUI()
                end
            end)
        end

        task.wait(1.0)
    end
end)

-- Loop 5: SuperLoot Auto Hunter (Direct Engine Hook + BGM Signature Scan + Ore Sweep)
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        if State.AutoKillSuperLoot then
            pcall(function()
                local slmScript = LocalPlayer.PlayerScripts:FindFirstChild("Manager") and LocalPlayer.PlayerScripts.Manager:FindFirstChild("SuperLootManager")
                local slmEnv = slmScript and getsenv and getsenv(slmScript)
                local OreUtils = nil
                pcall(function()
                    OreUtils = require(LocalPlayer.PlayerScripts.Manager.StageManager.OreUtils)
                end)

                -- Strategy 1: Read internal u80 table from SuperLootManager
                local u80 = nil
                if slmEnv and debug and debug.getupvalues then
                    local checkFns = { slmEnv.DestroyEnemyData, slmEnv.CreateOneSuperLoot }
                    for _, fn in ipairs(checkFns) do
                        if type(fn) == "function" then
                            local upvals = debug.getupvalues(fn)
                            for _, up in pairs(upvals) do
                                if type(up) == "table" and up ~= slmEnv then
                                    u80 = up
                                    break
                                end
                            end
                        end
                        if u80 then break end
                    end
                end

                if u80 then
                    for uuid, data in pairs(u80) do
                        if data and data.Model then
                            local model = data.Model
                            local pivot = model:GetPivot()
                            local oreId = data.OreID
                            local stageId = data.StageID or "Stage_1"

                            pcall(function()
                                if EnemyCTRL and EnemyCTRL.HurtEnemy then
                                    EnemyCTRL.HurtEnemy(uuid, 1e35)
                                end
                                if EnemyCTRL and EnemyCTRL.DeadEnemyData then
                                    EnemyCTRL.DeadEnemyData(uuid)
                                end
                                if Remote_KillSuperLoot then
                                    Remote_KillSuperLoot:FireServer(uuid)
                                end
                                local slRE = CommunicationUtils and CommunicationUtils.TryGetRemoteEvent("SuperLoot", "KillSuperLootRE")
                                if slRE then slRE:FireServer(uuid) end

                                if OreUtils and OreUtils.CreateOres and oreId then
                                    local oreMap = {}
                                    oreMap[uuid] = oreId
                                    OreUtils.CreateOres(pivot, oreMap, stageId)
                                end
                                if slmEnv and slmEnv.DestroyEnemyData then
                                    slmEnv.DestroyEnemyData(uuid)
                                end
                            end)
                        end
                    end
                end

                -- Strategy 2: Scan workspace.EnemyFolder for SuperLoot signature (SuperLootBGM)
                local enemyFolder = workspace:FindFirstChild("EnemyFolder")
                if enemyFolder then
                    for _, model in ipairs(enemyFolder:GetChildren()) do
                        if model:IsA("Model") then
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            local isSuperLoot = false
                            if hrp and hrp:FindFirstChild("SuperLootBGM") then
                                isSuperLoot = true
                            elseif model:GetAttribute("SuperLoot") or (model:GetAttribute("EnemyID") and tostring(model:GetAttribute("EnemyID")):find("SuperLoot")) then
                                isSuperLoot = true
                            end

                            if isSuperLoot then
                                local uuid = model.Name
                                pcall(function()
                                    if Bindable_EnemyHit then
                                        Bindable_EnemyHit:Fire(uuid, 1e35)
                                    end
                                    if EnemyCTRL and EnemyCTRL.HurtEnemy then
                                        EnemyCTRL.HurtEnemy(uuid, 1e35)
                                    end
                                    if EnemyCTRL and EnemyCTRL.DeadEnemyData then
                                        EnemyCTRL.DeadEnemyData(uuid)
                                    end
                                    if Remote_KillSuperLoot then
                                        Remote_KillSuperLoot:FireServer(uuid)
                                    end
                                    local slRE = CommunicationUtils and CommunicationUtils.TryGetRemoteEvent("SuperLoot", "KillSuperLootRE")
                                    if slRE then slRE:FireServer(uuid) end
                                end)
                            end
                        end
                    end
                end

                -- Collect all SuperLoot dropped ores
                if collectAllWorldOres then
                    collectAllWorldOres()
                end
            end)
            task.wait(1.0)
        else
            task.wait(2.0)
        end
    end
end)

-- Loop 6: Live Stats Refresher & Humanoid Speed Keeper
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        updateLiveStatsDisplay()
        refreshRebirthUI()

        local _, _, hum = getCharHrp()
        if hum and hum.Health > 0 then
            if State.WalkSpeed and State.WalkSpeed ~= 16 and math.abs(hum.WalkSpeed - State.WalkSpeed) > 0.5 then
                pcall(function() hum.WalkSpeed = State.WalkSpeed end)
            end
        end
        task.wait(1.0)
    end
end)

-- Loop 7: Auto Dungeon Farm Loop (Auto Enter, Insta-Kill, Sweep Loot & 30-Round Cap)
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        if State.AutoDungeon then
            local inDungeon = (LocalPlayer:GetAttribute("IntoFight") == "Dungeon") or (LocalPlayer:GetAttribute("StageID") == -1)
            if inDungeon then
                handleDungeonCombat()
                task.wait(0.2)
            else
                -- Claim free daily ticket
                if Remote_DungeonTicket then
                    pcall(function() Remote_DungeonTicket:FireServer() end)
                end
                task.wait(0.3)

                local targetRound = math.clamp(tonumber(State.TargetDungeonRound) or 1, 1, 30)
                if Remote_TryIntoDungeon then
                    pcall(function()
                        Remote_TryIntoDungeon:InvokeServer(targetRound)
                    end)
                elseif DungeonData and DungeonData.TryIntoDungeon then
                    pcall(function()
                        DungeonData.TryIntoDungeon(targetRound)
                    end)
                end
                task.wait(2.0)
            end
        else
            task.wait(1.0)
        end
    end
end)

-- Loop 8: Auto Enchant, Auto Potions & Auto Class Gacha Loop (Zero-Lag Throttled)
task.spawn(function()
    local lastPotionCheck = 0
    local lastEnchantCheck = 0
    local lastClassCheck = 0
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        local now = tick()

        -- Auto Buff Potions (Check every 2.0s)
        if (State.AutoBuffPotions or State.AutoTrainPotion or State.AutoCoinPotion or State.AutoLuckPotion) and (now - lastPotionCheck >= 2.0) then
            lastPotionCheck = now
            pcall(autoDrinkPotionsNow)
        end

        -- Auto Enchant Equipped Gear (Check every 3.0s)
        if State.AutoEnchant and (now - lastEnchantCheck >= 3.0) then
            lastEnchantCheck = now
            pcall(autoEnchantEquippedGear)
        end

        -- Auto Class Gacha Roll (Check every 1.5s)
        if State.AutoRollClass and (now - lastClassCheck >= 1.5) then
            lastClassCheck = now
            pcall(autoRollClassNow)
        end

        task.wait(0.75)
    end
end)

-- Loop 9: Auto World Boss Hunter (Auto Detect Spawn, Teleport Arena, Safe Distance Combat & Claim Cards)
task.spawn(function()
    while _G.TwoSkiRunning and _G.TwoSkiActiveToken == myToken do
        if State.AutoWorldBoss then
            local currentBoss = workspace:GetAttribute("CurrentWorldBoss")
            local bossModel = nil
            if currentBoss then
                local efs = workspace:FindFirstChild("EnemyFolder_Server")
                if efs then
                    bossModel = efs:FindFirstChild(currentBoss)
                end
            end

            -- If not found by attribute, check any model in EnemyFolder_Server
            if not bossModel then
                local efs = workspace:FindFirstChild("EnemyFolder_Server")
                if efs then
                    for _, child in ipairs(efs:GetChildren()) do
                        if child:IsA("Model") and not child:GetAttribute("Dead") then
                            bossModel = child
                            break
                        end
                    end
                end
            end

            if bossModel and bossModel.Parent then
                local bossHrp = bossModel:FindFirstChild("HumanoidRootPart") or bossModel.PrimaryPart
                local bossHPVal = bossModel:FindFirstChild("HPValue")
                local isBossAlive = (bossHPVal and bossHPVal.Value > 0) and not bossModel:GetAttribute("Dead")

                if isBossAlive then
                    -- 1. Ensure Player is in WorldBoss Fight state
                    local inFight = (LocalPlayer:GetAttribute("IntoFight") == "WorldBoss")
                    if not inFight then
                        pcall(function()
                            local intoRE = CommunicationUtils and CommunicationUtils.TryGetRemoteEvent("WorldBoss", "IntoWorldBossFight")
                            if intoRE then intoRE:FireServer() end
                            LocalPlayer:SetAttribute("IntoFight", "WorldBoss")
                            local wbg = nil
                            pcall(function() wbg = require(ReplicatedStorage.GuiUtils.WorldBossGUI) end)
                            if wbg and wbg.OpenBossFrame then wbg.OpenBossFrame() end
                        end)
                        task.wait(0.5)
                    end

                    -- 2. Teleport player close to Boss (safe elevated combat range, facing boss)
                    local _, hrp, hum = getCharHrp()
                    if hrp and bossHrp then
                        local bossCF = bossHrp.CFrame
                        local attackPos = bossCF.Position + (bossCF.LookVector * -15) + Vector3.new(0, 6, 0)
                        hrp.CFrame = CFrame.lookAt(attackPos, bossCF.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end

                    -- 3. Maintain Godmode Invulnerability during boss fight
                    pcall(function()
                        if HPCTRL and HPCTRL.SetCurrentHP and HPCTRL.GetMaxHP then
                            local maxHp = HPCTRL.GetMaxHP(LocalPlayer)
                            if maxHp and maxHp > 0 then
                                HPCTRL.SetCurrentHP(LocalPlayer, maxHp)
                            end
                        end
                        if hum and hum.Health < hum.MaxHealth then
                            hum.Health = hum.MaxHealth
                        end
                    end)

                    -- 4. Enable Game's Native Auto Attack if button exists
                    pcall(function()
                        local groupAuto = LocalPlayer.PlayerGui.Hud.Bottom.Info.GroupAuto
                        if groupAuto and groupAuto:FindFirstChild("Yes") and groupAuto.Yes:FindFirstChild("Button") then
                            local yesBtn = groupAuto.Yes.Button
                            if firesignal then
                                firesignal(yesBtn.MouseButton1Down)
                                firesignal(yesBtn.Activated)
                            end
                        end
                    end)

                    -- 5. Fire combat skills & damage remotes directly at World Boss
                    pcall(function()
                        local bossUUID = bossModel.Name
                        local sTime = workspace:GetServerTimeNow()

                        -- A. Fire AttackEnemyServiceRE directly
                        local atkRE = CommunicationUtils and CommunicationUtils.TryGetRemoteEvent("Attack", "AttackEnemyServiceRE")
                        if atkRE then
                            atkRE:FireServer({ bossUUID }, { Attacker = LocalPlayer, SkillID = "K_Skill_1" }, sTime)
                            atkRE:FireServer({ bossUUID }, { Attacker = LocalPlayer, SkillID = "G_ATK_1" }, sTime)
                        end

                        -- B. Fire AttackEnemyBE / EnemyHitBE
                        local enemyHitBE = CommunicationUtils and CommunicationUtils.TryGetBindableEvent("Attack", "EnemyHitBE")
                        if enemyHitBE then
                            enemyHitBE:Fire(bossUUID, 1e25, { SkillID = "K_Skill_1", Damage = 1e25 })
                        end

                        -- C. Trigger GUI skill buttons (Q, E, 3)
                        local bottomButtons = LocalPlayer.PlayerGui.Hud.Bottom.Top:FindFirstChild("Button")
                        if bottomButtons then
                            for _, btnSlot in ipairs(bottomButtons:GetChildren()) do
                                local actBtn = btnSlot:FindFirstChild("Button")
                                if actBtn and actBtn:IsA("GuiButton") and firesignal then
                                    firesignal(actBtn.MouseButton1Down)
                                    firesignal(actBtn.Activated)
                                end
                            end
                        end
                    end)
                    task.wait(0.2)
                else
                    -- Boss is dead / finished, claim reward card
                    pcall(function()
                        local claimRE = CommunicationUtils and CommunicationUtils.TryGetRemoteEvent("WorldBoss", "TryClaimBossRewardRE")
                        if claimRE then
                            for cardIdx = 1, 8 do
                                claimRE:FireServer(tostring(cardIdx))
                            end
                        end
                    end)
                    task.wait(1.5)
                end
            else
                -- No active World Boss right now
                if LocalPlayer:GetAttribute("IntoFight") == "WorldBoss" then
                    -- Clean exit back to spawn
                    pcall(function()
                        local exitRE = CommunicationUtils and CommunicationUtils.TryGetRemoteEvent("WorldBoss", "ExitWorldBossFight")
                        if exitRE then exitRE:FireServer() end
                        LocalPlayer:SetAttribute("IntoFight", nil)
                        local wbg = nil
                        pcall(function() wbg = require(ReplicatedStorage.GuiUtils.WorldBossGUI) end)
                        if wbg and wbg.CloseBossFrame then wbg.CloseBossFrame() end
                        local _, hrp = getCharHrp()
                        if hrp then
                            hrp.CFrame = CFrame.new(0, 15, 0)
                        end
                    end)
                end
                task.wait(2.5)
            end
        else
            task.wait(2.0)
        end
    end
end)

-- Automatic Config Auto-Load on Script Start (Guaranteed Global Hook)
task.spawn(function()
    repeat task.wait(0.1) until _G.TwoSkiLoaded
    task.wait(0.5)
    if State.AutoLoadConfig ~= false then
        local loaded = loadConfig(true)
        if loaded and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "2K CONFIG",
                Content = "โหลดการตั้งค่าอัตโนมัติ (Auto-Load) เรียบร้อย!",
                Duration = 3
            })
        end
    end
end)

_G.TwoSkiLoaded = true
refreshRebirthUI()
updateLiveStatsDisplay()

-- Automatically Open Main Window on Load and Focus "ฟาร์มพลัง & แร่"
pcall(function()
    if Window then
        Window:Open()
        task.defer(function()
            pcall(function()
                if TabFarm and TabFarm.Select then
                    TabFarm:Select()
                elseif Window.SelectTab then
                    Window:SelectTab(1)
                end
            end)
        end)
    end
end)

if WindUI and WindUI.Notify then
    WindUI:Notify({
        Title = "2SKI Engine",
        Content = "โหลดสคริปต์ Loot to Forge Master สมบูรณ์ 100%!"
    })
end

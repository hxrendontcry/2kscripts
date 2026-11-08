-- ==============================================================================
-- 2K PRISM // RobloxZ - 1000z Comprehensive Master Automation & Combat Hub
-- PlaceId: 131081687658776 | Experience: RobloxZ - 1000z (by CoderTH - Studio)
-- Architecture: 2K Script Cyber-Neon Obsidian // Zero-Prompt Auto-Guard & Anti-Cheat Bypass
-- ==============================================================================

-- [[ 1. ZERO-PROMPT AUTO-GUARD & MULTI-LAYER ANTI-CHEAT BYPASS ]]
pcall(function()
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")

    -- 1.1 Kick & Namecall Interception
    local orig_nc
    orig_nc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }

        -- Kick suppression
        if method == "Kick" and self == lp then
            warn("[2K PRISM] Server/Client Kick suppressed!")
            return nil
        end

        -- GuiSync Anti-Cheat Report Suppression:
        -- WarZGuiGuardian fires GuiSync with GUI inspection reports, ESP detections, and keyword scans.
        -- It ALSO fires a heartbeat ("hb:...") which the server requires.
        -- We allow the heartbeat to pass while completely dropping all cheat detection reports!
        if method == "FireServer" and self and self.Name == "GuiSync" then
            local firstArg = args[1]
            local isHeartbeat = false
            if type(firstArg) == "table" and type(firstArg[1]) == "string" then
                if string.sub(firstArg[1], 1, 3) == "hb:" then
                    isHeartbeat = true
                end
            end
            if not isHeartbeat then
                -- Silently block detection payload from reaching server
                return nil
            end
        end

        -- BanPlayer suppression
        if method == "FireServer" and self and self.Name == "BanPlayer" then
            warn("[2K PRISM] BanPlayer remote suppressed!")
            return nil
        end

        return orig_nc(self, ...)
    end))

    -- 1.2 Disconnect Kicked Signal
    if getconnections and lp and lp.Kicked then
        for _, c in ipairs(getconnections(lp.Kicked)) do
            if c.Disable then c:Disable() end
        end
    end

    -- 1.3 WarZCheatTrap Neutralization
    -- Reset and continuously suppress WarZCheatTrapped attribute
    if lp then
        pcall(function()
            if lp:GetAttribute("WarZCheatTrapped") then
                lp:SetAttribute("WarZCheatTrapped", false)
            end
            lp:GetAttributeChangedSignal("WarZCheatTrapped"):Connect(function()
                if lp:GetAttribute("WarZCheatTrapped") == true then
                    pcall(function() lp:SetAttribute("WarZCheatTrapped", false) end)
                end
            end)
        end)

        -- Clean up any trap overlays if they ever get created
        RunService.RenderStepped:Connect(function()
            local pGui = lp:FindFirstChildOfClass("PlayerGui")
            if pGui then
                local trapOverlay = pGui:FindFirstChild("WarZCheatTrapOverlay")
                if trapOverlay then trapOverlay:Destroy() end
            end
            local trapColor = Lighting:FindFirstChild("WarZCheatTrapColor")
            if trapColor then trapColor:Destroy() end
            local trapBlur = Lighting:FindFirstChild("WarZCheatTrapBlur")
            if trapBlur then trapBlur:Destroy() end
        end)
    end

    -- 1.4 Anti-AFK Routine
    pcall(function()
        local vu = game:GetService("VirtualUser")
        lp.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end)

-- [[ 2. SAFE GAME LOADING & SINGLETON CLEANUP ]]
if not game:IsLoaded() then
    local loaded = false
    local conn
    conn = game.Loaded:Connect(function() loaded = true end)
    local t0 = tick()
    while not game:IsLoaded() and not loaded and (tick() - t0 < 15) do
        task.wait(0.2)
    end
    if conn then conn:Disconnect() end
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
if not localPlayer then
    local t0 = tick()
    repeat
        task.wait(0.1)
        localPlayer = Players.LocalPlayer
    until localPlayer or (tick() - t0 > 15)
end

local genv = (getgenv and getgenv()) or _G
if genv.__TwoKPrismWarZ then
    pcall(function()
        genv.__TwoKPrismWarZ:Destroy()
    end)
    genv.__TwoKPrismWarZ = nil
end

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local guiInset = GuiService:GetGuiInset()

local PlayerGui = nil
if localPlayer then
    PlayerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 15)
end

-- Stealth UI Cleanup: The ScreenGui MUST use the "WarZ_" prefix so WarZGuiGuardian considers it native!
local GUI_NAME = "WarZ_2K_Prism"

pcall(function()
    local core = nil
    pcall(function() core = game:GetService("CoreGui") end)
    if core then
        for _, child in ipairs(core:GetChildren()) do
            if (child.Name == GUI_NAME or child.Name == "TwoKPrism") and child:IsA("ScreenGui") then
                child:Destroy()
            end
        end
    end
end)

if PlayerGui then
    pcall(function()
        for _, child in ipairs(PlayerGui:GetChildren()) do
            if (child.Name == GUI_NAME or child.Name == "TwoKPrism") and child:IsA("ScreenGui") then
                child:Destroy()
            end
        end
    end)
end

pcall(function()
    local oldBlur = Lighting:FindFirstChild("WarZPrismFrost")
    if oldBlur then oldBlur:Destroy() end
end)

-- [[ 3. GAME SERVICES & MODULE CACHING ]]
local BloxZFolder = ReplicatedStorage:WaitForChild("BloxZ", 20)
local NetworkFolder = BloxZFolder and BloxZFolder:WaitForChild("Network", 20)
local ItemsFolder = BloxZFolder and BloxZFolder:WaitForChild("Items", 20)
local WeaponsFolder = BloxZFolder and BloxZFolder:WaitForChild("Weapons", 20)

local WarZActionRequest = NetworkFolder and NetworkFolder:WaitForChild("WarZActionRequest", 20)
local WarZDevFlight = NetworkFolder and NetworkFolder:WaitForChild("WarZDevFlight", 20)
local WarZDailyReward = NetworkFolder and NetworkFolder:WaitForChild("WarZDailyReward", 20)
local WarZBattlePass = NetworkFolder and NetworkFolder:WaitForChild("WarZBattlePass", 20)

local ItemDBModule = nil
pcall(function()
    ItemDBModule = require(ItemsFolder:WaitForChild("ItemDB", 20))
end)

local WeaponBallistics = nil
pcall(function()
    WeaponBallistics = require(WeaponsFolder:WaitForChild("WeaponBallistics", 20))
end)

local ReplayTokenModule = nil
pcall(function()
    ReplayTokenModule = require(NetworkFolder:WaitForChild("ReplayToken", 20))
end)

-- Helper to safely resolve item names & kinds by ItemId
local itemNameCache = {}
local itemKindCache = {}
local function getItemInfo(itemId)
    if not itemId then return "Unknown Item", "misc" end
    if itemNameCache[itemId] then return itemNameCache[itemId], itemKindCache[itemId] end
    local name = "Item #" .. tostring(itemId)
    local kind = "misc"
    if ItemDBModule and ItemDBModule.Get then
        pcall(function()
            local info = ItemDBModule.Get(itemId)
            if info then
                if info.name then name = info.name end
                if info.kind then kind = info.kind end
            end
        end)
    end
    itemNameCache[itemId] = name
    itemKindCache[itemId] = kind
    return name, kind
end

local function getItemName(itemId)
    local name, _ = getItemInfo(itemId)
    return name
end

-- [[ 4. MAID CLEANUP PATTERN ]]
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(taskItem)
    table.insert(self._tasks, taskItem)
    return taskItem
end

function Maid:DoCleaning()
    for i = #self._tasks, 1, -1 do
        local taskItem = self._tasks[i]
        self._tasks[i] = nil
        if typeof(taskItem) == "RBXScriptConnection" then
            taskItem:Disconnect()
        elseif typeof(taskItem) == "Instance" then
            taskItem:Destroy()
        elseif typeof(taskItem) == "function" then
            pcall(taskItem)
        elseif typeof(taskItem) == "thread" then
            pcall(task.cancel, taskItem)
        elseif typeof(taskItem) == "table" and type(taskItem.Destroy) == "function" then
            pcall(function() taskItem:Destroy() end)
        end
    end
end

function Maid:Destroy()
    self:DoCleaning()
end

local mainMaid = Maid.new()

-- [[ 5. SCREEN GUI INITIALIZATION ]]
local targetParent = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
    targetParent = PlayerGui or (localPlayer and localPlayer:WaitForChild("PlayerGui", 15))
else
    if gethui then
        pcall(function()
            local h = gethui()
            -- Avoid parenting ScreenGui inside an existing ScreenGui like CoreGui.RobloxGui
            if h and not h:IsA("ScreenGui") and not h:IsA("LayerCollector") then
                targetParent = h
            end
        end)
    end
    if not targetParent then
        pcall(function()
            local core = game:GetService("CoreGui")
            if core then
                local testProbe = Instance.new("Folder")
                testProbe.Parent = core
                testProbe:Destroy()
                targetParent = core
            end
        end)
    end
    if not targetParent then
        targetParent = PlayerGui or (localPlayer and localPlayer:WaitForChild("PlayerGui", 15))
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999
screenGui.Parent = targetParent
mainMaid:GiveTask(screenGui)

-- Dedicated ESP Parent: BillboardGuis MUST be parented to PlayerGui or CoreGui directly to render in 3D
local espParent = PlayerGui or targetParent
local espFolder = Instance.new("Folder")
espFolder.Name = "WarZ_ESP_Holders"
espFolder.Parent = espParent
mainMaid:GiveTask(espFolder)

local camera = workspace.CurrentCamera

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "WarZPrismFrost"
blurEffect.Size = 0
blurEffect.Parent = Lighting
mainMaid:GiveTask(blurEffect)

-- [[ 6. THEMES & PERSISTENT SETTINGS ]]
local SAVE_FOLDER = "2KPrism_WarZ"
local SAVE_PATH = SAVE_FOLDER .. "/settings.json"

local saved = {}
pcall(function()
    if isfile and isfile(SAVE_PATH) then
        saved = HttpService:JSONDecode(readfile(SAVE_PATH))
    end
end)

local CONFIG = {
    Title = "2K PRISM",
    Sub = "ROBLOXZ - 1000z MASTER HUB",
    Theme = "Ice",
    ToggleKey = Enum.KeyCode.RightControl,
}

local Themes = {
    Ice = {
        C1 = Color3.fromRGB(120, 230, 255),
        C2 = Color3.fromRGB(165, 135, 255),
        C3 = Color3.fromRGB(255, 135, 205),
    },
    Aurora = {
        C1 = Color3.fromRGB(90, 255, 190),
        C2 = Color3.fromRGB(90, 190, 255),
        C3 = Color3.fromRGB(170, 120, 255),
    },
    Ember = {
        C1 = Color3.fromRGB(255, 190, 90),
        C2 = Color3.fromRGB(255, 110, 110),
        C3 = Color3.fromRGB(255, 90, 190),
    },
    Mono = {
        C1 = Color3.fromRGB(255, 255, 255),
        C2 = Color3.fromRGB(190, 205, 225),
        C3 = Color3.fromRGB(255, 255, 255),
    },
}

local function buildColorSequence(theme)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.C1),
        ColorSequenceKeypoint.new(0.5, theme.C2),
        ColorSequenceKeypoint.new(1, theme.C3),
    })
end

local UI = {
    Visible = false,
    Frost = tonumber(saved.Frost) or 6,
    TintAlpha = tonumber(saved.TintAlpha) or 0.18,
    Parallax = saved.Parallax ~= false,
    ToggleKey = (saved.ToggleKey and Enum.KeyCode:FromName(saved.ToggleKey)) or CONFIG.ToggleKey,
    CurrentThemeName = Themes[saved.Theme] and saved.Theme or CONFIG.Theme,
}

local currentTheme = Themes[UI.CurrentThemeName]
local saveQueued = false
local containerPos = Vector2.new(tonumber(saved.PosX) or 0, tonumber(saved.PosY) or 0)
local orbPos = Vector2.new(tonumber(saved.OrbX) or 74, tonumber(saved.OrbY) or 190)

local function saveSettings()
    if saveQueued or not writefile then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        pcall(function()
            if makefolder and isfolder and not isfolder(SAVE_FOLDER) then
                makefolder(SAVE_FOLDER)
            end
            writefile(SAVE_PATH, HttpService:JSONEncode({
                Theme = UI.CurrentThemeName,
                Frost = UI.Frost,
                TintAlpha = UI.TintAlpha,
                Parallax = UI.Parallax,
                ToggleKey = UI.ToggleKey.Name,
                PosX = containerPos.X,
                PosY = containerPos.Y,
                OrbX = orbPos.X,
                OrbY = orbPos.Y,
            }))
        end)
    end)
end

local currentColorSequence = buildColorSequence(currentTheme)
local accentCallbacks = {}

local function RegisterAccent(callback)
    table.insert(accentCallbacks, callback)
    pcall(callback, currentTheme, currentColorSequence)
    return function()
        local at = table.find(accentCallbacks, callback)
        if at then table.remove(accentCallbacks, at) end
    end
end

function UI:SetAccent(themeName)
    local selected = Themes[themeName]
    if not selected then return end
    UI.CurrentThemeName = themeName
    currentTheme = selected
    currentColorSequence = buildColorSequence(selected)
    for _, cb in ipairs(accentCallbacks) do
        pcall(cb, currentTheme, currentColorSequence)
    end
    saveSettings()
end

local function safeSpawn(fn, ...)
    if type(fn) ~= "function" then return end
    local params = { ... }
    task.spawn(function()
        local success, result = pcall(fn, unpack(params))
        if not success then
            warn("[2K PRISM Error]: " .. tostring(result) .. "\n" .. debug.traceback())
        end
    end)
end

-- [[ 7. GLASS SLAB GENERATOR ]]
local allSlabs = {}
local allSurfaces = {}

local function makeGlass(parent, opts)
    opts = opts or {}
    local radius = opts.Radius or 10

    local root = Instance.new("Frame")
    root.Name = "SlabRoot"
    root.Size = opts.Size or UDim2.fromOffset(100, 100)
    root.Position = opts.Position or UDim2.fromOffset(0, 0)
    root.BackgroundTransparency = 1
    root.ClipsDescendants = false
    root.Parent = parent

    local slabScale = Instance.new("UIScale")
    slabScale.Scale = 1
    slabScale.Parent = root

    local surface = Instance.new("Frame")
    surface.Name = "Surface"
    surface.Size = UDim2.new(1, 0, 1, 0)
    surface.Position = UDim2.new(0, 0, 0, 0)
    surface.BackgroundColor3 = Color3.fromRGB(13, 17, 27)
    surface.BackgroundTransparency = UI.TintAlpha
    surface.BorderSizePixel = 0
    surface.Active = true
    surface.Parent = root

    local surfaceCorner = Instance.new("UICorner")
    surfaceCorner.CornerRadius = UDim.new(0, radius)
    surfaceCorner.Parent = surface

    local noise = Instance.new("ImageLabel")
    noise.Name = "Noise"
    noise.Size = UDim2.new(1, 0, 1, 0)
    noise.BackgroundTransparency = 1
    noise.Image = "rbxassetid://9968344227"
    noise.ScaleType = Enum.ScaleType.Tile
    noise.TileSize = UDim2.fromOffset(128, 128)
    noise.ImageTransparency = 0.93
    noise.Parent = surface

    local noiseCorner = Instance.new("UICorner")
    noiseCorner.CornerRadius = UDim.new(0, radius)
    noiseCorner.Parent = noise

    local sheen = Instance.new("Frame")
    sheen.Name = "Sheen"
    sheen.Size = UDim2.new(1, 0, 1, 0)
    sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sheen.BorderSizePixel = 0
    sheen.Parent = surface

    local sheenCorner = Instance.new("UICorner")
    sheenCorner.CornerRadius = UDim.new(0, radius)
    sheenCorner.Parent = sheen

    local sheenGrad = Instance.new("UIGradient")
    sheenGrad.Rotation = 75
    sheenGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.86),
        NumberSequenceKeypoint.new(0.45, 0.97),
        NumberSequenceKeypoint.new(1, 1),
    })
    sheenGrad.Parent = sheen

    local specular = Instance.new("Frame")
    specular.Name = "Specular"
    specular.Size = UDim2.new(1, 0, 1, 0)
    specular.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    specular.BorderSizePixel = 0
    specular.Parent = surface

    local specularCorner = Instance.new("UICorner")
    specularCorner.CornerRadius = UDim.new(0, radius)
    specularCorner.Parent = specular

    local specularGrad = Instance.new("UIGradient")
    specularGrad.Rotation = 115
    specularGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.42, 1),
        NumberSequenceKeypoint.new(0.50, 0.70),
        NumberSequenceKeypoint.new(0.58, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    specularGrad.Parent = specular

    local rim = Instance.new("Frame")
    rim.Name = "Rim"
    rim.Size = UDim2.new(1, 0, 1, 0)
    rim.BackgroundTransparency = 1
    rim.Parent = root

    local rimCorner = Instance.new("UICorner")
    rimCorner.CornerRadius = UDim.new(0, radius)
    rimCorner.Parent = rim

    local rimStroke = Instance.new("UIStroke")
    rimStroke.Thickness = 1.2
    rimStroke.Color = Color3.fromRGB(255, 255, 255)
    rimStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rimStroke.Parent = rim

    local rimGrad = Instance.new("UIGradient")
    rimGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.35, 0.75),
        NumberSequenceKeypoint.new(0.65, 0.90),
        NumberSequenceKeypoint.new(1, 0.45),
    })
    rimGrad.Parent = rimStroke

    local fringeGrads = {}
    local fringeStrokes = {}
    local fringeOffsets = { Vector2.new(1, 1), Vector2.new(-1, -1) }

    for idx, offsetVec in ipairs(fringeOffsets) do
        local fringeFrame = Instance.new("Frame")
        fringeFrame.Name = "Fringe_" .. idx
        fringeFrame.Size = UDim2.new(1, 0, 1, 0)
        fringeFrame.Position = UDim2.fromOffset(offsetVec.X, offsetVec.Y)
        fringeFrame.BackgroundTransparency = 1
        fringeFrame.Parent = root

        local fringeCorner = Instance.new("UICorner")
        fringeCorner.CornerRadius = UDim.new(0, radius)
        fringeCorner.Parent = fringeFrame

        local fringeStroke = Instance.new("UIStroke")
        fringeStroke.Thickness = 1
        fringeStroke.Transparency = 0.72
        fringeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        fringeStroke.Color = (idx == 1 and currentTheme.C1) or currentTheme.C3
        fringeStroke.Parent = fringeFrame

        local fGrad = Instance.new("UIGradient")
        fGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.35, 0.75),
            NumberSequenceKeypoint.new(0.65, 0.90),
            NumberSequenceKeypoint.new(1, 0.45),
        })
        fGrad.Parent = fringeStroke

        table.insert(fringeGrads, fGrad)
        table.insert(fringeStrokes, fringeStroke)
    end

    local unregisterFringe = RegisterAccent(function(theme)
        if fringeStrokes[1] then fringeStrokes[1].Color = theme.C1 end
        if fringeStrokes[2] then fringeStrokes[2].Color = theme.C3 end
    end)

    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.Position = UDim2.fromOffset(1, 1)
    inner.Size = UDim2.new(1, -2, 1, -2)
    inner.BackgroundTransparency = 1
    inner.Parent = root

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, math.max(0, radius - 1))
    innerCorner.Parent = inner

    local innerStroke = Instance.new("UIStroke")
    innerStroke.Thickness = 1
    innerStroke.Color = Color3.fromRGB(255, 255, 255)
    innerStroke.Transparency = 0.93
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    innerStroke.Parent = inner

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = root

    local slab = {
        Root = root,
        Scale = slabScale,
        Surface = surface,
        Content = content,
        Rim = rimGrad,
        RimStroke = rimStroke,
        Fringe = fringeGrads,
        FringeStrokes = fringeStrokes,
        Specular = specularGrad,
        Layers = { noise, sheen, specular },
        InnerStroke = innerStroke,
        Unaccent = unregisterFringe,
        Locked = true,
        Sweeping = false,
        Blend = 0,
        Depth = opts.Depth or 0,
        Lag = opts.Lag or 0,
        Base = opts.Position or UDim2.fromOffset(0, 0),
        Follow = Vector2.new(0, 0),
        LastOffset = Vector2.new(9999, 9999),
    }

    if opts.Track ~= false then
        table.insert(allSlabs, slab)
    end
    table.insert(allSurfaces, surface)
    return slab
end

-- [[ 8. UI CONTAINER & SLAB LAYOUT ]]
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.fromOffset(680, 440)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.BackgroundTransparency = 1
container.ClipsDescendants = false
container.Parent = screenGui

local containerScale = Instance.new("UIScale")
containerScale.Scale = 1
containerScale.Parent = container

local function updateViewportScaling()
    local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local calculated = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.70, 1.15)
    containerScale.Scale = calculated
end

mainMaid:GiveTask(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateViewportScaling))
updateViewportScaling()

local splinterLayer = Instance.new("Folder")
splinterLayer.Name = "SplinterLayer"
splinterLayer.Parent = screenGui

local toastContainer = Instance.new("Frame")
toastContainer.Name = "ToastStack"
toastContainer.Size = UDim2.fromOffset(280, 440)
toastContainer.AnchorPoint = Vector2.new(1, 1)
toastContainer.Position = UDim2.new(1, -20, 1, -20)
toastContainer.BackgroundTransparency = 1
toastContainer.ClipsDescendants = false
toastContainer.Parent = screenGui

local topSlab = makeGlass(container, {
    Size = UDim2.fromOffset(680, 62),
    Position = UDim2.fromOffset(0, 0),
    Radius = 10,
    Depth = 2,
    Lag = 0.32,
})

local dockSlab = makeGlass(container, {
    Size = UDim2.fromOffset(130, 370),
    Position = UDim2.fromOffset(0, 70),
    Radius = 10,
    Depth = 4,
    Lag = 0.22,
})

local mainSlab = makeGlass(container, {
    Size = UDim2.fromOffset(542, 330),
    Position = UDim2.fromOffset(138, 70),
    Radius = 10,
    Depth = 3,
    Lag = 0.27,
})

local statusSlab = makeGlass(container, {
    Size = UDim2.fromOffset(542, 32),
    Position = UDim2.fromOffset(138, 408),
    Radius = 8,
    Depth = 3,
    Lag = 0.17,
})

-- Geometric Prism Icon
local function makePrismMark(parent, size, pos)
    local wrapper = Instance.new("Frame")
    wrapper.Name = "PrismMark"
    wrapper.Size = size or UDim2.fromOffset(26, 26)
    wrapper.Position = pos or UDim2.fromOffset(0, 0)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = parent

    local diamond1 = Instance.new("Frame")
    diamond1.Size = UDim2.fromOffset(15, 15)
    diamond1.AnchorPoint = Vector2.new(0.5, 0.5)
    diamond1.Position = UDim2.new(0.40, 0, 0.50, 0)
    diamond1.Rotation = 45
    diamond1.BackgroundTransparency = 1
    diamond1.Parent = wrapper

    local d1Corner = Instance.new("UICorner")
    d1Corner.CornerRadius = UDim.new(0, 2)
    d1Corner.Parent = diamond1

    local d1Stroke = Instance.new("UIStroke")
    d1Stroke.Thickness = 1.2
    d1Stroke.Color = currentTheme.C1
    d1Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    d1Stroke.Parent = diamond1

    local diamond2 = Instance.new("Frame")
    diamond2.Size = UDim2.fromOffset(12, 12)
    diamond2.AnchorPoint = Vector2.new(0.5, 0.5)
    diamond2.Position = UDim2.new(0.60, 0, 0.50, 0)
    diamond2.Rotation = 45
    diamond2.BackgroundTransparency = 1
    diamond2.Parent = wrapper

    local d2Corner = Instance.new("UICorner")
    d2Corner.CornerRadius = UDim.new(0, 2)
    d2Corner.Parent = diamond2

    local d2Stroke = Instance.new("UIStroke")
    d2Stroke.Thickness = 1.2
    d2Stroke.Color = currentTheme.C2
    d2Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    d2Stroke.Parent = diamond2

    RegisterAccent(function(theme)
        d1Stroke.Color = theme.C1
        d2Stroke.Color = theme.C2
    end)

    return wrapper
end

makePrismMark(topSlab.Content, UDim2.fromOffset(26, 26), UDim2.fromOffset(16, 18))

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.fromOffset(260, 22)
titleLabel.Position = UDim2.fromOffset(50, 11)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.Michroma
titleLabel.Text = CONFIG.Title
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topSlab.Content

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = currentColorSequence
titleGrad.Parent = titleLabel
RegisterAccent(function(_, seq)
    titleGrad.Color = seq
end)

local subLabel = Instance.new("TextLabel")
subLabel.Name = "Subtitle"
subLabel.Size = UDim2.fromOffset(260, 16)
subLabel.Position = UDim2.fromOffset(50, 34)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.GothamMedium
subLabel.Text = CONFIG.Sub
subLabel.TextSize = 10
subLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Parent = topSlab.Content

local rightControls = Instance.new("Frame")
rightControls.Name = "RightControls"
rightControls.Size = UDim2.fromOffset(260, 36)
rightControls.AnchorPoint = Vector2.new(1, 0.5)
rightControls.Position = UDim2.new(1, -12, 0.5, 0)
rightControls.BackgroundTransparency = 1
rightControls.Parent = topSlab.Content

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Horizontal
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Padding = UDim.new(0, 8)
rightLayout.Parent = rightControls

local function makeChip(name, initialText, order)
    local chip = Instance.new("Frame")
    chip.Name = name
    chip.Size = UDim2.fromOffset(68, 24)
    chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    chip.BackgroundTransparency = 0.95
    chip.LayoutOrder = order
    chip.Parent = rightControls

    local chipCorner = Instance.new("UICorner")
    chipCorner.CornerRadius = UDim.new(0, 6)
    chipCorner.Parent = chip

    local chipStroke = Instance.new("UIStroke")
    chipStroke.Thickness = 1
    chipStroke.Color = Color3.fromRGB(255, 255, 255)
    chipStroke.Transparency = 0.90
    chipStroke.Parent = chip

    local chipLabel = Instance.new("TextLabel")
    chipLabel.Name = "Label"
    chipLabel.Size = UDim2.new(1, 0, 1, 0)
    chipLabel.BackgroundTransparency = 1
    chipLabel.Font = Enum.Font.GothamMedium
    chipLabel.Text = initialText
    chipLabel.TextSize = 11
    chipLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
    chipLabel.Parent = chip

    return chipLabel
end

local fpsChip = makeChip("FPSChip", "FPS 060", 1)
local pingChip = makeChip("PingChip", "PING 00", 2)

local function makeTopButton(textChar, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. textChar
    btn.Size = UDim2.fromOffset(26, 26)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.95
    btn.Font = Enum.Font.GothamMedium
    btn.Text = textChar
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(186, 198, 220)
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = rightControls

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Transparency = 0.90
    btnStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.88, TextColor3 = Color3.fromRGB(236, 243, 255) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.95, TextColor3 = Color3.fromRGB(186, 198, 220) }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        safeSpawn(onClick)
    end)

    return btn
end

makeTopButton("-", 3, function() UI:Toggle(false) end)
makeTopButton("x", 4, function() UI:Destroy() end)

-- Window Drag System
local function clampContainer(wanted)
    local vp = camera.ViewportSize
    local s = containerScale.Scale
    local halfW, halfH = 340 * s, 220 * s
    return Vector2.new(
        math.clamp(wanted.X, -vp.X / 2 - halfW + 90, vp.X / 2 + halfW - 90),
        math.clamp(wanted.Y, -vp.Y / 2 + halfH, vp.Y / 2 + halfH - 62 * s)
    )
end

containerPos = clampContainer(containerPos)
container.Position = UDim2.new(0.5, containerPos.X, 0.5, containerPos.Y)
for _, slab in ipairs(allSlabs) do
    slab.Follow = containerPos
end

local isDraggingContainer = false
local dragOrigin = Vector2.new(0, 0)
local containerOrigin = Vector2.new(0, 0)

topSlab.Surface.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingContainer = true
        dragOrigin = Vector2.new(input.Position.X, input.Position.Y)
        containerOrigin = containerPos
    end
end)

mainMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
    if isDraggingContainer and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMouse = Vector2.new(input.Position.X, input.Position.Y)
        containerPos = clampContainer(containerOrigin + (currentMouse - dragOrigin))
        container.Position = UDim2.new(0.5, containerPos.X, 0.5, containerPos.Y)
    end
end))

mainMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
    if isDraggingContainer and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDraggingContainer = false
        saveSettings()
    end
end))

-- [[ 9. DOCK SLAB & LENS ]]
local dockLens = Instance.new("Frame")
dockLens.Name = "DockLens"
dockLens.Size = UDim2.new(1, -16, 0, 30)
dockLens.Position = UDim2.fromOffset(8, 14)
dockLens.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dockLens.BackgroundTransparency = 0.94
dockLens.Parent = dockSlab.Content

local lensCorner = Instance.new("UICorner")
lensCorner.CornerRadius = UDim.new(0, 6)
lensCorner.Parent = dockLens

local lensStroke = Instance.new("UIStroke")
lensStroke.Thickness = 1.2
lensStroke.Color = currentTheme.C1
lensStroke.Transparency = 0.35
lensStroke.Parent = dockLens
RegisterAccent(function(theme)
    lensStroke.Color = theme.C1
end)

local sessionStart = os.clock()

local dockPlayer = Instance.new("TextLabel")
dockPlayer.Name = "DockPlayer"
dockPlayer.AnchorPoint = Vector2.new(0, 1)
dockPlayer.Position = UDim2.new(0, 10, 1, -28)
dockPlayer.Size = UDim2.new(1, -20, 0, 16)
dockPlayer.BackgroundTransparency = 1
dockPlayer.Font = Enum.Font.GothamMedium
dockPlayer.Text = localPlayer and localPlayer.DisplayName or ""
dockPlayer.TextSize = 11
dockPlayer.TextColor3 = Color3.fromRGB(236, 243, 255)
dockPlayer.TextXAlignment = Enum.TextXAlignment.Left
dockPlayer.TextTruncate = Enum.TextTruncate.AtEnd
dockPlayer.Parent = dockSlab.Content

local dockClock = Instance.new("TextLabel")
dockClock.Name = "DockClock"
dockClock.AnchorPoint = Vector2.new(0, 1)
dockClock.Position = UDim2.new(0, 10, 1, -10)
dockClock.Size = UDim2.new(1, -20, 0, 16)
dockClock.BackgroundTransparency = 1
dockClock.Font = Enum.Font.Michroma
dockClock.Text = "00:00:00"
dockClock.TextSize = 11
dockClock.TextColor3 = currentTheme.C1
dockClock.TextXAlignment = Enum.TextXAlignment.Left
dockClock.Parent = dockSlab.Content
RegisterAccent(function(theme)
    dockClock.TextColor3 = theme.C1
end)

local registeredTabs = {}
local activeTab = nil

-- [[ 10. STATUS SLAB & INDICATORS ]]
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusText"
statusLabel.Size = UDim2.new(0.65, 0, 1, 0)
statusLabel.Position = UDim2.fromOffset(14, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "READY // ROBLOXZ - 1000z"
statusLabel.TextSize = 11
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusSlab.Content

function UI:SetStatus(message)
    statusLabel.Text = tostring(message)
end

local activeCounterFrame = Instance.new("Frame")
activeCounterFrame.Name = "ActiveCounter"
activeCounterFrame.Size = UDim2.new(0.32, 0, 1, 0)
activeCounterFrame.AnchorPoint = Vector2.new(1, 0)
activeCounterFrame.Position = UDim2.new(1, -14, 0, 0)
activeCounterFrame.BackgroundTransparency = 1
activeCounterFrame.Parent = statusSlab.Content

local activeCounterLayout = Instance.new("UIListLayout")
activeCounterLayout.FillDirection = Enum.FillDirection.Horizontal
activeCounterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
activeCounterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
activeCounterLayout.SortOrder = Enum.SortOrder.LayoutOrder
activeCounterLayout.Padding = UDim.new(0, 8)
activeCounterLayout.Parent = activeCounterFrame

local pulseDot = Instance.new("Frame")
pulseDot.Name = "PulseDot"
pulseDot.Size = UDim2.fromOffset(7, 7)
pulseDot.BackgroundColor3 = currentTheme.C1
pulseDot.BackgroundTransparency = 0.2
pulseDot.LayoutOrder = 1
pulseDot.Parent = activeCounterFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = pulseDot

RegisterAccent(function(theme)
    pulseDot.BackgroundColor3 = theme.C1
end)

local activeCountLabel = Instance.new("TextLabel")
activeCountLabel.Name = "CountLabel"
activeCountLabel.Size = UDim2.fromOffset(80, 20)
activeCountLabel.BackgroundTransparency = 1
activeCountLabel.Font = Enum.Font.Michroma
activeCountLabel.Text = "0 ACTIVE"
activeCountLabel.TextSize = 10
activeCountLabel.TextColor3 = Color3.fromRGB(236, 243, 255)
activeCountLabel.TextXAlignment = Enum.TextXAlignment.Right
activeCountLabel.LayoutOrder = 2
activeCountLabel.Parent = activeCounterFrame

local rimState = "Idle"
local function applyRimState()
    local color = Color3.fromRGB(255, 255, 255)
    if rimState == "Running" then
        color = currentTheme.C1
    elseif rimState == "Error" then
        color = Color3.fromRGB(255, 80, 90)
    end
    for _, slab in ipairs(allSlabs) do
        slab.RimStroke.Color = color
        if rimState == "Idle" and not slab.Locked then
            slab.RimStroke.Transparency = 0
        end
    end
end
RegisterAccent(applyRimState)

function UI:SetState(stateName)
    rimState = stateName
    applyRimState()
end

local totalActiveToggles = 0
local function updateActiveCounter(delta)
    totalActiveToggles = math.max(0, totalActiveToggles + delta)
    activeCountLabel.Text = string.format("%d ACTIVE", totalActiveToggles)
    if rimState ~= "Error" then
        UI:SetState(totalActiveToggles > 0 and "Running" or "Idle")
    end
end

-- [[ 11. FLOATING 2K ORB & CRACK EFFECT ]]
local crackBurst
local ORB_SIZE = 42

local orb = Instance.new("Frame")
orb.Name = "PrismOrb"
orb.Size = UDim2.fromOffset(ORB_SIZE, ORB_SIZE)
orb.AnchorPoint = Vector2.new(0.5, 0.5)
orb.BackgroundColor3 = Color3.fromRGB(8, 11, 19)
orb.BackgroundTransparency = 0.10
orb.Active = true
orb.ZIndex = 40
orb.Parent = screenGui
mainMaid:GiveTask(orb)

local function placeOrb(wanted)
    local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
    orbPos = Vector2.new(math.clamp(wanted.X, 24, vp.X - 24), math.clamp(wanted.Y, 24, vp.Y - 24))
    orb.Position = UDim2.fromOffset(orbPos.X, orbPos.Y)
end
placeOrb(orbPos)

local orbCorner = Instance.new("UICorner")
orbCorner.CornerRadius = UDim.new(1, 0)
orbCorner.Parent = orb

local orbScale = Instance.new("UIScale")
orbScale.Parent = orb

local orbRings = {}
for index = 1, 2 do
    local ring = Instance.new("Frame")
    ring.Name = "Ring" .. index
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.fromOffset(ORB_SIZE, ORB_SIZE)
    ring.BackgroundTransparency = 1
    ring.Parent = orb

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Thickness = 1.5
    ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ringStroke.Parent = ring

    orbRings[index] = { Frame = ring, Stroke = ringStroke, Phase = (index - 1) / 2 }
end

RegisterAccent(function(theme)
    if orbRings[1] then orbRings[1].Stroke.Color = theme.C1 end
    if orbRings[2] then orbRings[2].Stroke.Color = theme.C3 end
end)

local orbNoise = Instance.new("ImageLabel")
orbNoise.Name = "OrbNoise"
orbNoise.Size = UDim2.new(1, 0, 1, 0)
orbNoise.BackgroundTransparency = 1
orbNoise.Image = "rbxassetid://9968344227"
orbNoise.ScaleType = Enum.ScaleType.Tile
orbNoise.TileSize = UDim2.fromOffset(48, 48)
orbNoise.ImageTransparency = 0.90
orbNoise.Parent = orb

local orbNoiseCorner = Instance.new("UICorner")
orbNoiseCorner.CornerRadius = UDim.new(1, 0)
orbNoiseCorner.Parent = orbNoise

local orbShine = Instance.new("Frame")
orbShine.Name = "Shine"
orbShine.Size = UDim2.new(1, 0, 1, 0)
orbShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
orbShine.BorderSizePixel = 0
orbShine.Parent = orb

local orbShineCorner = Instance.new("UICorner")
orbShineCorner.CornerRadius = UDim.new(1, 0)
orbShineCorner.Parent = orbShine

local orbShineGrad = Instance.new("UIGradient")
orbShineGrad.Rotation = 35
orbShineGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.42, 1),
    NumberSequenceKeypoint.new(0.50, 0.55),
    NumberSequenceKeypoint.new(0.58, 1),
    NumberSequenceKeypoint.new(1, 1),
})
orbShineGrad.Parent = orbShine

local orbStroke = Instance.new("UIStroke")
orbStroke.Thickness = 2
orbStroke.Color = Color3.fromRGB(255, 255, 255)
orbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
orbStroke.Parent = orb

local orbStrokeGrad = Instance.new("UIGradient")
orbStrokeGrad.Color = currentColorSequence
orbStrokeGrad.Parent = orbStroke
RegisterAccent(function(_, seq)
    orbStrokeGrad.Color = seq
end)

local function makeOrbText(name, transparency)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Michroma
    label.Text = "2K"
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextTransparency = transparency
    label.Parent = orb
    return label
end

local orbSplitA = makeOrbText("SplitA", 0.30)
local orbSplitB = makeOrbText("SplitB", 0.30)
local orbFace = makeOrbText("Face", 0)

local orbFaceGrad = Instance.new("UIGradient")
orbFaceGrad.Parent = orbFace

RegisterAccent(function(theme)
    orbSplitA.TextColor3 = theme.C1
    orbSplitB.TextColor3 = theme.C3
    orbFaceGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, theme.C1),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
end)

local orbOrbit = Instance.new("Frame")
orbOrbit.Name = "Orbit"
orbOrbit.Size = UDim2.new(1, 0, 1, 0)
orbOrbit.BackgroundTransparency = 1
orbOrbit.Parent = orb

local orbSpark = Instance.new("Frame")
orbSpark.Name = "Spark"
orbSpark.AnchorPoint = Vector2.new(0.5, 0.5)
orbSpark.Position = UDim2.new(0.5, 0, 0, 0)
orbSpark.Size = UDim2.fromOffset(5, 5)
orbSpark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
orbSpark.BorderSizePixel = 0
orbSpark.Parent = orbOrbit

local orbSparkCorner = Instance.new("UICorner")
orbSparkCorner.CornerRadius = UDim.new(1, 0)
orbSparkCorner.Parent = orbSpark

local orbSparkStroke = Instance.new("UIStroke")
orbSparkStroke.Thickness = 2
orbSparkStroke.Transparency = 0.45
orbSparkStroke.Parent = orbSpark
RegisterAccent(function(theme)
    orbSparkStroke.Color = theme.C1
end)

local function updateOrb(dt)
    local clock = os.clock()
    orbStrokeGrad.Rotation = (orbStrokeGrad.Rotation + dt * 120) % 360
    orbFaceGrad.Rotation = (orbFaceGrad.Rotation + dt * 90) % 360
    orbOrbit.Rotation = (orbOrbit.Rotation + dt * 150) % 360
    orbShineGrad.Offset = Vector2.new(((clock * 0.35) % 1) * 4 - 2, 0)

    for _, ring in ipairs(orbRings) do
        local phase = (clock / 1.9 + ring.Phase) % 1
        local size = ORB_SIZE + 22 * phase
        ring.Frame.Size = UDim2.fromOffset(size, size)
        ring.Stroke.Transparency = 0.25 + 0.75 * phase
    end

    local glitching = (clock % 3.2) < 0.14
    local split = glitching and (2 + math.random() * 2) or 1
    local lift = glitching and 1 or 0
    orbSplitA.Position = UDim2.fromOffset(-split, lift)
    orbSplitB.Position = UDim2.fromOffset(split, -lift)
end

local function tweenOrbScale(value)
    TweenService:Create(orbScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = value,
    }):Play()
end

local isDraggingOrb = false
local isHoveringOrb = false
local orbDragStart = Vector2.new(0, 0)
local orbOrigin = Vector2.new(0, 0)
local orbTravelDist = 0

orb.MouseEnter:Connect(function()
    isHoveringOrb = true
    if not isDraggingOrb then tweenOrbScale(1.12) end
end)

orb.MouseLeave:Connect(function()
    isHoveringOrb = false
    if not isDraggingOrb then tweenOrbScale(1) end
end)

orb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingOrb = true
        orbTravelDist = 0
        orbDragStart = Vector2.new(input.Position.X, input.Position.Y)
        orbOrigin = orbPos
        tweenOrbScale(0.9)
    end
end)

mainMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
    if isDraggingOrb and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local diff = Vector2.new(input.Position.X, input.Position.Y) - orbDragStart
        orbTravelDist = math.max(orbTravelDist, diff.Magnitude)
        if orbTravelDist > 6 then
            placeOrb(orbOrigin + diff)
        end
    end
end))

mainMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
    if isDraggingOrb and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDraggingOrb = false
        tweenOrbScale(isHoveringOrb and 1.12 or 1)
        if orbTravelDist <= 6 then
            crackBurst(orb.AbsolutePosition + orb.AbsoluteSize / 2)
            UI:Toggle()
        else
            saveSettings()
        end
    end
end))

crackBurst = function(origin)
    for _ = 1, 4 do
        local pos = origin
        local angle = math.random() * math.pi * 2
        for step = 1, 6 do
            angle = angle + (math.random() - 0.5) * 1.1
            local length = math.random(18, 46)
            local nextPos = pos + Vector2.new(math.cos(angle), math.sin(angle)) * length
            local mid = (pos + nextPos) / 2

            local seg = Instance.new("Frame")
            seg.Name = "Crack"
            seg.AnchorPoint = Vector2.new(0.5, 0.5)
            seg.Size = UDim2.fromOffset(length, 2)
            seg.Position = UDim2.fromOffset(mid.X, mid.Y + guiInset.Y)
            seg.Rotation = math.deg(angle)
            seg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            seg.BackgroundTransparency = 1
            seg.BorderSizePixel = 0
            seg.ZIndex = 50
            seg.Parent = splinterLayer

            local grad = Instance.new("UIGradient")
            grad.Color = currentColorSequence
            grad.Parent = seg

            task.delay(step * 0.018, function()
                seg.BackgroundTransparency = 0.05
                local fade = TweenService:Create(seg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1,
                })
                fade.Completed:Connect(function() seg:Destroy() end)
                fade:Play()
            end)

            pos = nextPos
        end
    end
end

-- [[ 12. TOAST NOTIFICATION STACK ]]
local activeToasts = {}

local function reflowToastStack()
    for index, toastRecord in ipairs(activeToasts) do
        local targetY = 440 - (#activeToasts - index + 1) * 72
        TweenService:Create(toastRecord.Slab.Root, TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(0, targetY)
        }):Play()
    end
end

local function removeToast(toastRecord)
    local foundIndex = table.find(activeToasts, toastRecord)
    if not foundIndex then return end
    table.remove(activeToasts, foundIndex)

    local exitTween = TweenService:Create(toastRecord.Slab.Root, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.fromOffset(320, toastRecord.Slab.Root.Position.Y.Offset)
    })
    exitTween:Play()
    exitTween.Completed:Connect(function()
        local slab = toastRecord.Slab
        slab.Unaccent()
        toastRecord.Unaccent()
        local at = table.find(allSurfaces, slab.Surface)
        if at then table.remove(allSurfaces, at) end
        slab.Root:Destroy()
    end)

    reflowToastStack()
end

function UI:Notify(options)
    options = options or {}
    local toastTitle = string.upper(options.Title or "SYSTEM")
    local toastDesc = options.Text or ""
    local duration = options.Duration or 3

    if #activeToasts >= 4 then
        removeToast(activeToasts[1])
    end

    local toastSlab = makeGlass(toastContainer, {
        Size = UDim2.fromOffset(280, 64),
        Position = UDim2.fromOffset(320, 368),
        Radius = 8,
        Depth = 0,
        Lag = 0,
        Track = false,
    })

    toastSlab.Content.Visible = true
    toastSlab.Specular.Offset = Vector2.new(-1, 0)

    local toastTitleLabel = Instance.new("TextLabel")
    toastTitleLabel.Size = UDim2.new(1, -24, 0, 18)
    toastTitleLabel.Position = UDim2.fromOffset(12, 10)
    toastTitleLabel.BackgroundTransparency = 1
    toastTitleLabel.Font = Enum.Font.Michroma
    toastTitleLabel.Text = toastTitle
    toastTitleLabel.TextSize = 12
    toastTitleLabel.TextColor3 = Color3.fromRGB(236, 243, 255)
    toastTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toastTitleLabel.Parent = toastSlab.Content

    local toastBodyLabel = Instance.new("TextLabel")
    toastBodyLabel.Size = UDim2.new(1, -24, 0, 24)
    toastBodyLabel.Position = UDim2.fromOffset(12, 28)
    toastBodyLabel.BackgroundTransparency = 1
    toastBodyLabel.Font = Enum.Font.GothamMedium
    toastBodyLabel.Text = toastDesc
    toastBodyLabel.TextSize = 12
    toastBodyLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
    toastBodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    toastBodyLabel.TextWrapped = true
    toastBodyLabel.Parent = toastSlab.Content

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = currentTheme.C1
    progressBar.BorderSizePixel = 0
    progressBar.Parent = toastSlab.Content

    local unregisterBar = RegisterAccent(function(theme)
        progressBar.BackgroundColor3 = theme.C1
    end)

    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    TweenService:Create(toastSlab.Specular, TweenInfo.new(0.50, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Offset = Vector2.new(1, 0)
    }):Play()

    local record = { Slab = toastSlab, Unaccent = unregisterBar }
    table.insert(activeToasts, record)
    reflowToastStack()

    task.delay(duration, function()
        removeToast(record)
    end)
end

-- [[ 13. TAB SWITCHING & WIDGET GENERATOR ]]
local isKeybindListeningGlobal = false

local function switchTab(tabRecord)
    if activeTab == tabRecord then return end
    local previousTab = activeTab
    activeTab = tabRecord

    local targetY = tabRecord.Button.Position.Y.Offset
    TweenService:Create(dockLens, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(8, targetY)
    }):Play()

    TweenService:Create(dockLens, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, -16, 0, 40)
    }):Play()

    task.delay(0.18, function()
        TweenService:Create(dockLens, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, 30)
        }):Play()
    end)

    for _, registered in ipairs(registeredTabs) do
        local isCurrent = (registered == tabRecord)
        TweenService:Create(registered.Button, TweenInfo.new(0.2), {
            TextColor3 = isCurrent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(214, 224, 240)
        }):Play()
    end

    if previousTab then
        previousTab.Page.Visible = false
    end
    tabRecord.Page.Visible = true

    local rowCount = math.min(#tabRecord.Rows, 8)
    for idx = 1, rowCount do
        local row = tabRecord.Rows[idx]
        row.Wrapper.Position = UDim2.new(0, 0, 0, 8)
        row.Wrapper.BackgroundTransparency = 1
        row.Stroke.Transparency = 1
        if row.Title then row.Title.TextTransparency = 1 end
        if row.Desc then row.Desc.TextTransparency = 1 end

        task.delay((idx - 1) * 0.02, function()
            TweenService:Create(row.Wrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 0.95,
            }):Play()
            TweenService:Create(row.Stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = 0.93,
            }):Play()
            if row.Title then
                TweenService:Create(row.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
            end
            if row.Desc then
                TweenService:Create(row.Desc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
            end
        end)
    end

    for idx = 9, #tabRecord.Rows do
        local row = tabRecord.Rows[idx]
        row.Wrapper.Position = UDim2.new(0, 0, 0, 0)
        row.Wrapper.BackgroundTransparency = 0.95
        row.Stroke.Transparency = 0.93
        if row.Title then row.Title.TextTransparency = 0 end
        if row.Desc then row.Desc.TextTransparency = 0 end
    end
end

local function createRowBase(parent, hasDesc, customHeight)
    local baseHeight = customHeight or (hasDesc and 52 or 40)

    local rowContainer = Instance.new("Frame")
    rowContainer.Name = "RowContainer"
    rowContainer.Size = UDim2.new(1, 0, 0, baseHeight)
    rowContainer.BackgroundTransparency = 1
    rowContainer.ClipsDescendants = false
    rowContainer.Parent = parent

    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inner.BackgroundTransparency = 0.95
    inner.Parent = rowContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = inner

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.93
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = inner

    inner.MouseEnter:Connect(function()
        TweenService:Create(inner, TweenInfo.new(0.15), { BackgroundTransparency = 0.90 }):Play()
    end)
    inner.MouseLeave:Connect(function()
        TweenService:Create(inner, TweenInfo.new(0.15), { BackgroundTransparency = 0.95 }):Play()
    end)

    return rowContainer, inner, stroke
end

local function attachLabels(inner, nameText, descText)
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamMedium
    title.Text = nameText or ""
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(236, 243, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = inner

    local desc = nil
    if descText and descText ~= "" then
        title.Size = UDim2.new(0.65, 0, 0, 18)
        title.Position = UDim2.fromOffset(12, 8)

        desc = Instance.new("TextLabel")
        desc.Name = "Desc"
        desc.Size = UDim2.new(0.65, 0, 0, 16)
        desc.Position = UDim2.fromOffset(12, 28)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = descText
        desc.TextSize = 11
        desc.TextColor3 = Color3.fromRGB(186, 198, 220)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = inner
    else
        title.Size = UDim2.new(0.65, 0, 1, 0)
        title.Position = UDim2.fromOffset(12, 0)
    end

    return title, desc
end

function UI:Tab(tabTitle)
    tabTitle = string.upper(tabTitle or "TAB")
    local tabIndex = #registeredTabs + 1

    local tabButton = Instance.new("TextButton")
    tabButton.Name = "TabBtn_" .. tabTitle
    tabButton.Size = UDim2.new(1, -16, 0, 30)
    tabButton.Position = UDim2.fromOffset(8, 14 + (tabIndex - 1) * 36)
    tabButton.BackgroundTransparency = 1
    tabButton.Font = Enum.Font.Michroma
    tabButton.Text = tabTitle
    tabButton.TextSize = 11
    tabButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tabButton.TextStrokeTransparency = 0.55
    tabButton.TextColor3 = Color3.fromRGB(214, 224, 240)
    tabButton.AutoButtonColor = false
    tabButton.Parent = dockSlab.Content

    local pageFrame = Instance.new("ScrollingFrame")
    pageFrame.Name = "Page_" .. tabTitle
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.BorderSizePixel = 0
    pageFrame.ScrollBarThickness = 2
    pageFrame.ScrollBarImageColor3 = Color3.fromRGB(186, 198, 220)
    pageFrame.ScrollBarImageTransparency = 0.50
    pageFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    pageFrame.Visible = false
    pageFrame.Parent = mainSlab.Content

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.FillDirection = Enum.FillDirection.Vertical
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = pageFrame

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 12)
    pagePadding.PaddingBottom = UDim.new(0, 12)
    pagePadding.PaddingLeft = UDim.new(0, 12)
    pagePadding.PaddingRight = UDim.new(0, 12)
    pagePadding.Parent = pageFrame

    local tabRecord = {
        Button = tabButton,
        Page = pageFrame,
        Rows = {},
    }

    table.insert(registeredTabs, tabRecord)

    tabButton.MouseButton1Click:Connect(function()
        switchTab(tabRecord)
    end)

    if #registeredTabs == 1 then
        switchTab(tabRecord)
    end

    local TabApi = {}

    function TabApi:Section(sectionTitle)
        sectionTitle = string.upper(sectionTitle or "SECTION")

        local secFrame = Instance.new("Frame")
        secFrame.Name = "Section_" .. sectionTitle
        secFrame.Size = UDim2.new(1, 0, 0, 22)
        secFrame.BackgroundTransparency = 1
        secFrame.Parent = pageFrame

        local secLabel = Instance.new("TextLabel")
        secLabel.Name = "SecLabel"
        secLabel.Size = UDim2.fromOffset(200, 22)
        secLabel.BackgroundTransparency = 1
        secLabel.Font = Enum.Font.Michroma
        secLabel.Text = sectionTitle
        secLabel.TextSize = 10
        secLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
        secLabel.TextXAlignment = Enum.TextXAlignment.Left
        secLabel.Parent = secFrame

        local hairline = Instance.new("Frame")
        hairline.Name = "Hairline"
        hairline.AnchorPoint = Vector2.new(0, 0.5)
        hairline.Position = UDim2.new(0, 204, 0.5, 0)
        hairline.Size = UDim2.new(1, -208, 0, 1)
        hairline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hairline.BorderSizePixel = 0
        hairline.Parent = secFrame

        local hairGrad = Instance.new("UIGradient")
        hairGrad.Color = currentColorSequence
        hairGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.85),
        })
        hairGrad.Parent = hairline
        RegisterAccent(function(_, seq)
            hairGrad.Color = seq
        end)

        local SecApi = {}

        local function registerRow(wrapper, stroke, titleObj, descObj)
            table.insert(tabRecord.Rows, {
                Wrapper = wrapper,
                Stroke = stroke,
                Title = titleObj,
                Desc = descObj,
            })
        end

        function SecApi:Toggle(opts)
            opts = opts or {}
            local state = (opts.Default == true)
            local hasDesc = (opts.Desc and opts.Desc ~= "")
            local row, inner, stroke = createRowBase(pageFrame, hasDesc)
            local titleObj, descObj = attachLabels(inner, opts.Name, opts.Desc)
            registerRow(inner, stroke, titleObj, descObj)

            local capsule = Instance.new("Frame")
            capsule.Name = "Capsule"
            capsule.Size = UDim2.fromOffset(44, 22)
            capsule.AnchorPoint = Vector2.new(1, 0.5)
            capsule.Position = UDim2.new(1, -12, 0.5, 0)
            capsule.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
            capsule.BackgroundTransparency = 0.30
            capsule.Parent = inner

            local capCorner = Instance.new("UICorner")
            capCorner.CornerRadius = UDim.new(0, 11)
            capCorner.Parent = capsule

            local capStroke = Instance.new("UIStroke")
            capStroke.Thickness = 1
            capStroke.Color = Color3.fromRGB(255, 255, 255)
            capStroke.Transparency = 0.88
            capStroke.Parent = capsule

            local capFill = Instance.new("Frame")
            capFill.Name = "Fill"
            capFill.Size = UDim2.new(1, 0, 1, 0)
            capFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            capFill.BackgroundTransparency = state and 0 or 1
            capFill.BorderSizePixel = 0
            capFill.Parent = capsule

            local capFillCorner = Instance.new("UICorner")
            capFillCorner.CornerRadius = UDim.new(0, 11)
            capFillCorner.Parent = capFill

            local capFillGrad = Instance.new("UIGradient")
            capFillGrad.Color = currentColorSequence
            capFillGrad.Parent = capFill
            RegisterAccent(function(_, seq)
                capFillGrad.Color = seq
            end)

            local bead = Instance.new("Frame")
            bead.Name = "Bead"
            bead.Size = UDim2.fromOffset(16, 16)
            bead.AnchorPoint = Vector2.new(0, 0.5)
            bead.Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            bead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            bead.BorderSizePixel = 0
            bead.Parent = capsule

            local beadCorner = Instance.new("UICorner")
            beadCorner.CornerRadius = UDim.new(0, 8)
            beadCorner.Parent = bead

            local counts = opts.Count ~= false
            if state and counts then
                updateActiveCounter(1)
            end

            local function applyToggleVisual(isOn)
                TweenService:Create(capFill, TweenInfo.new(0.20), { BackgroundTransparency = isOn and 0 or 1 }):Play()
                TweenService:Create(bead, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(24, 16) }):Play()
                local targetPos = isOn and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                TweenService:Create(bead, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = targetPos }):Play()
                task.delay(0.10, function()
                    TweenService:Create(bead, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(16, 16) }):Play()
                end)
            end

            local toggleApi = {}
            function toggleApi:Set(val, suppressCallback)
                val = (val == true)
                if state == val then return end
                state = val
                if counts then updateActiveCounter(state and 1 or -1) end
                applyToggleVisual(state)
                if state and opts.Crack ~= false then
                    crackBurst(capsule.AbsolutePosition + capsule.AbsoluteSize / 2)
                end
                if not suppressCallback then
                    safeSpawn(opts.Callback, state)
                end
            end

            function toggleApi:Get() return state end

            local clickDetector = Instance.new("TextButton")
            clickDetector.Size = UDim2.new(1, 0, 1, 0)
            clickDetector.BackgroundTransparency = 1
            clickDetector.Text = ""
            clickDetector.Parent = inner
            clickDetector.MouseButton1Click:Connect(function()
                toggleApi:Set(not state)
            end)

            return toggleApi
        end

        function SecApi:Slider(opts)
            opts = opts or {}
            local minVal = opts.Min or 0
            local maxVal = opts.Max or 100
            local step = opts.Step or 1
            local suffix = opts.Suffix or ""
            local currentVal = math.clamp(opts.Default or minVal, minVal, maxVal)

            local row, inner, stroke = createRowBase(pageFrame, false, 50)
            local titleObj = attachLabels(inner, opts.Name, nil)
            titleObj.Size = UDim2.new(0.60, 0, 0, 20)
            titleObj.Position = UDim2.fromOffset(12, 6)
            registerRow(inner, stroke, titleObj, nil)

            local valLabel = Instance.new("TextLabel")
            valLabel.Name = "ValueLabel"
            valLabel.Size = UDim2.fromOffset(120, 20)
            valLabel.AnchorPoint = Vector2.new(1, 0)
            valLabel.Position = UDim2.new(1, -12, 0, 6)
            valLabel.BackgroundTransparency = 1
            valLabel.Font = Enum.Font.GothamMedium
            valLabel.Text = tostring(currentVal) .. suffix
            valLabel.TextSize = 12
            valLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.Parent = inner

            local tube = Instance.new("Frame")
            tube.Name = "Tube"
            tube.Size = UDim2.new(1, -24, 0, 6)
            tube.Position = UDim2.fromOffset(12, 32)
            tube.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
            tube.BackgroundTransparency = 0.50
            tube.Parent = inner

            local tubeCorner = Instance.new("UICorner")
            tubeCorner.CornerRadius = UDim.new(0, 3)
            tubeCorner.Parent = tube

            local tubeStroke = Instance.new("UIStroke")
            tubeStroke.Thickness = 1
            tubeStroke.Color = Color3.fromRGB(255, 255, 255)
            tubeStroke.Transparency = 0.94
            tubeStroke.Parent = tube

            local range = (maxVal > minVal) and (maxVal - minVal) or 1
            local initialPct = (currentVal - minVal) / range

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new(initialPct, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            fill.BorderSizePixel = 0
            fill.Parent = tube

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 3)
            fillCorner.Parent = fill

            local fillGrad = Instance.new("UIGradient")
            fillGrad.Color = currentColorSequence
            fillGrad.Parent = fill
            RegisterAccent(function(_, seq)
                fillGrad.Color = seq
            end)

            local thumb = Instance.new("Frame")
            thumb.Name = "Thumb"
            thumb.Size = UDim2.fromOffset(14, 14)
            thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            thumb.Position = UDim2.new(initialPct, 0, 0.5, 0)
            thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            thumb.BackgroundTransparency = 0.15
            thumb.Parent = tube

            local thumbCorner = Instance.new("UICorner")
            thumbCorner.CornerRadius = UDim.new(0, 7)
            thumbCorner.Parent = thumb

            local thumbStroke = Instance.new("UIStroke")
            thumbStroke.Thickness = 1.2
            thumbStroke.Color = currentTheme.C1
            thumbStroke.Transparency = 0.35
            thumbStroke.Parent = thumb
            RegisterAccent(function(theme)
                thumbStroke.Color = theme.C1
            end)

            local isDraggingSlider = false
            local function updateSliderPct(pct, suppressCallback)
                pct = math.clamp(pct, 0, 1)
                local snapped = minVal + math.floor(pct * range / step + 0.5) * step
                snapped = math.clamp(tonumber(string.format("%.4f", snapped)), minVal, maxVal)
                local changed = snapped ~= currentVal
                currentVal = snapped

                local clampedPct = (currentVal - minVal) / range
                valLabel.Text = tostring(currentVal) .. suffix

                TweenService:Create(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(clampedPct, 0, 1, 0)
                }):Play()
                TweenService:Create(thumb, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(clampedPct, 0, 0.5, 0)
                }):Play()

                if changed and not suppressCallback then
                    safeSpawn(opts.Callback, currentVal)
                end
            end

            inner.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingSlider = true
                    pageFrame.ScrollingEnabled = false
                    local mouseX = input.Position.X
                    local tubeLeft = tube.AbsolutePosition.X
                    local tubeWidth = tube.AbsoluteSize.X
                    updateSliderPct((mouseX - tubeLeft) / tubeWidth)
                end
            end)

            mainMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
                if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mouseX = input.Position.X
                    local tubeLeft = tube.AbsolutePosition.X
                    local tubeWidth = tube.AbsoluteSize.X
                    updateSliderPct((mouseX - tubeLeft) / tubeWidth)
                end
            end))

            mainMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
                if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    isDraggingSlider = false
                    pageFrame.ScrollingEnabled = true
                end
            end))

            local sliderApi = {}
            function sliderApi:Set(val, suppressCallback)
                val = math.clamp(val, minVal, maxVal)
                local pct = (val - minVal) / range
                updateSliderPct(pct, suppressCallback)
            end
            function sliderApi:Get() return currentVal end

            return sliderApi
        end

        function SecApi:Button(opts)
            opts = opts or {}
            local hasDesc = (opts.Desc and opts.Desc ~= "")
            local row, inner, stroke = createRowBase(pageFrame, hasDesc)
            local titleObj, descObj = attachLabels(inner, opts.Name, opts.Desc)
            registerRow(inner, stroke, titleObj, descObj)

            local sweepFrame = Instance.new("Frame")
            sweepFrame.Name = "Sweep"
            sweepFrame.Size = UDim2.new(1, 0, 1, 0)
            sweepFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sweepFrame.BackgroundTransparency = 0
            sweepFrame.BorderSizePixel = 0
            sweepFrame.Parent = inner

            local sweepCorner = Instance.new("UICorner")
            sweepCorner.CornerRadius = UDim.new(0, 6)
            sweepCorner.Parent = sweepFrame

            local sweepGrad = Instance.new("UIGradient")
            sweepGrad.Offset = Vector2.new(-1, 0)
            sweepGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.40, 1),
                NumberSequenceKeypoint.new(0.50, 0.75),
                NumberSequenceKeypoint.new(0.60, 1),
                NumberSequenceKeypoint.new(1, 1),
            })
            sweepGrad.Parent = sweepFrame

            local btnClick = Instance.new("TextButton")
            btnClick.Size = UDim2.new(1, 0, 1, 0)
            btnClick.BackgroundTransparency = 1
            btnClick.Text = ""
            btnClick.Parent = inner

            btnClick.MouseButton1Click:Connect(function()
                inner.Position = UDim2.fromOffset(0, 1)
                task.delay(0.08, function() inner.Position = UDim2.fromOffset(0, 0) end)

                sweepGrad.Offset = Vector2.new(-1, 0)
                local sweepTween = TweenService:Create(sweepGrad, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(1, 0)
                })
                sweepTween:Play()
                sweepTween.Completed:Connect(function() sweepGrad.Offset = Vector2.new(-1, 0) end)

                safeSpawn(opts.Callback)
            end)
        end

        function SecApi:Dropdown(opts)
            opts = opts or {}
            local optionsList = opts.Options or {}
            local selectedVal = opts.Default or optionsList[1] or ""
            local isOpen = false
            local baseHeight = 40

            local row, inner, stroke = createRowBase(pageFrame, false, baseHeight)
            row.ClipsDescendants = true
            inner.ClipsDescendants = true

            local titleObj = attachLabels(inner, opts.Name, nil)
            titleObj.Size = UDim2.new(0.50, 0, 0, baseHeight)
            registerRow(inner, stroke, titleObj, nil)

            local dropdownDisplay = Instance.new("Frame")
            dropdownDisplay.Name = "DropdownDisplay"
            dropdownDisplay.Size = UDim2.new(0.46, 0, 0, baseHeight)
            dropdownDisplay.AnchorPoint = Vector2.new(1, 0)
            dropdownDisplay.Position = UDim2.new(1, -12, 0, 0)
            dropdownDisplay.BackgroundTransparency = 1
            dropdownDisplay.Parent = inner

            local selectedLabel = Instance.new("TextLabel")
            selectedLabel.Name = "SelectedLabel"
            selectedLabel.Size = UDim2.new(1, -22, 1, 0)
            selectedLabel.BackgroundTransparency = 1
            selectedLabel.Font = Enum.Font.GothamMedium
            selectedLabel.Text = tostring(selectedVal)
            selectedLabel.TextSize = 12
            selectedLabel.TextColor3 = Color3.fromRGB(236, 243, 255)
            selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
            selectedLabel.Parent = dropdownDisplay

            local arrowLabel = Instance.new("TextLabel")
            arrowLabel.Name = "Arrow"
            arrowLabel.Size = UDim2.fromOffset(16, 16)
            arrowLabel.AnchorPoint = Vector2.new(1, 0.5)
            arrowLabel.Position = UDim2.new(1, 0, 0.5, 0)
            arrowLabel.BackgroundTransparency = 1
            arrowLabel.Font = Enum.Font.GothamMedium
            arrowLabel.Text = "v"
            arrowLabel.TextSize = 11
            arrowLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
            arrowLabel.Parent = dropdownDisplay

            local optionsHolder = Instance.new("Frame")
            optionsHolder.Name = "OptionsHolder"
            optionsHolder.Position = UDim2.fromOffset(8, baseHeight + 4)
            optionsHolder.Size = UDim2.new(1, -16, 0, #optionsList * 30)
            optionsHolder.BackgroundTransparency = 1
            optionsHolder.Parent = inner

            local optionsLayout = Instance.new("UIListLayout")
            optionsLayout.FillDirection = Enum.FillDirection.Vertical
            optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optionsLayout.Padding = UDim.new(0, 2)
            optionsLayout.Parent = optionsHolder

            local function toggleDropdown(openState)
                isOpen = openState
                local expandedHeight = baseHeight + 8 + (#optionsList * 30)
                local targetHeight = isOpen and expandedHeight or baseHeight

                TweenService:Create(row, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, targetHeight)
                }):Play()

                TweenService:Create(arrowLabel, TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Rotation = isOpen and 180 or 0
                }):Play()
            end

            local dropdownApi = {}

            local function rebuildOptionButtons()
                for _, child in ipairs(optionsHolder:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for idx, optName in ipairs(optionsList) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = "Opt_" .. tostring(optName)
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    optBtn.BackgroundTransparency = 0.97
                    optBtn.Font = Enum.Font.GothamMedium
                    optBtn.Text = "   " .. tostring(optName)
                    optBtn.TextSize = 12
                    optBtn.TextColor3 = (optName == selectedVal) and Color3.fromRGB(236, 243, 255) or Color3.fromRGB(186, 198, 220)
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left
                    optBtn.AutoButtonColor = false
                    optBtn.LayoutOrder = idx
                    optBtn.Parent = optionsHolder

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optBtn

                    optBtn.MouseEnter:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.90 }):Play()
                    end)
                    optBtn.MouseLeave:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.97 }):Play()
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        dropdownApi:Set(optName)
                        toggleDropdown(false)
                    end)
                end
            end

            rebuildOptionButtons()

            local headerClick = Instance.new("TextButton")
            headerClick.Size = UDim2.new(1, 0, 0, baseHeight)
            headerClick.BackgroundTransparency = 1
            headerClick.Text = ""
            headerClick.Parent = inner
            headerClick.MouseButton1Click:Connect(function()
                toggleDropdown(not isOpen)
            end)

            function dropdownApi:Set(val, suppressCallback)
                selectedVal = val
                selectedLabel.Text = tostring(val)
                rebuildOptionButtons()
                if not suppressCallback then
                    safeSpawn(opts.Callback, selectedVal)
                end
            end

            function dropdownApi:Get() return selectedVal end

            function dropdownApi:SetOptions(newOpts)
                optionsList = newOpts or {}
                if not table.find(optionsList, selectedVal) then
                    selectedVal = optionsList[1] or ""
                    selectedLabel.Text = tostring(selectedVal)
                end
                optionsHolder.Size = UDim2.new(1, -16, 0, #optionsList * 30)
                rebuildOptionButtons()
                if isOpen then toggleDropdown(true) end
            end

            return dropdownApi
        end

        function SecApi:Keybind(opts)
            opts = opts or {}
            local boundKey = opts.Default or Enum.KeyCode.F
            local isListening = false

            local row, inner, stroke = createRowBase(pageFrame, false)
            local titleObj = attachLabels(inner, opts.Name, nil)
            registerRow(inner, stroke, titleObj, nil)

            local chip = Instance.new("Frame")
            chip.Name = "KeyChip"
            chip.Size = UDim2.fromOffset(78, 24)
            chip.AnchorPoint = Vector2.new(1, 0.5)
            chip.Position = UDim2.new(1, -12, 0.5, 0)
            chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            chip.BackgroundTransparency = 0.95
            chip.Parent = inner

            local chipCorner = Instance.new("UICorner")
            chipCorner.CornerRadius = UDim.new(0, 6)
            chipCorner.Parent = chip

            local chipStroke = Instance.new("UIStroke")
            chipStroke.Thickness = 1
            chipStroke.Color = Color3.fromRGB(255, 255, 255)
            chipStroke.Transparency = 0.88
            chipStroke.Parent = chip

            local chipLabel = Instance.new("TextLabel")
            chipLabel.Size = UDim2.new(1, 0, 1, 0)
            chipLabel.BackgroundTransparency = 1
            chipLabel.Font = Enum.Font.GothamMedium
            chipLabel.Text = boundKey.Name
            chipLabel.TextSize = 11
            chipLabel.TextColor3 = Color3.fromRGB(236, 243, 255)
            chipLabel.Parent = chip

            local chipButton = Instance.new("TextButton")
            chipButton.Size = UDim2.new(1, 0, 1, 0)
            chipButton.BackgroundTransparency = 1
            chipButton.Text = ""
            chipButton.Parent = chip

            chipButton.MouseButton1Click:Connect(function()
                if isListening then return end
                isListening = true
                isKeybindListeningGlobal = true
                chipLabel.Text = "..."
                TweenService:Create(chipStroke, TweenInfo.new(0.2), { Color = currentTheme.C1, Transparency = 0.3 }):Play()
            end)

            mainMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gpe)
                if isListening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            chipLabel.Text = boundKey.Name
                        else
                            boundKey = input.KeyCode
                            chipLabel.Text = boundKey.Name
                            safeSpawn(opts.Changed, boundKey)
                        end
                        isListening = false
                        task.defer(function() isKeybindListeningGlobal = false end)
                        TweenService:Create(chipStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88 }):Play()
                    end
                else
                    if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == boundKey then
                        safeSpawn(opts.Callback, boundKey)
                    end
                end
            end))

            local keybindApi = {}
            function keybindApi:Set(newKey)
                boundKey = newKey
                chipLabel.Text = boundKey.Name
            end
            function keybindApi:Get() return boundKey end

            return keybindApi
        end

        function SecApi:Label(textString)
            local row, inner, stroke = createRowBase(pageFrame, false)
            local titleObj = attachLabels(inner, textString, nil)
            titleObj.TextColor3 = Color3.fromRGB(186, 198, 220)
            registerRow(inner, stroke, titleObj, nil)
        end

        return SecApi
    end

    return TabApi
end

-- [[ 14. OPEN / CLOSE ANIMATIONS ]]
local isAnimatingTransition = false

function UI:Toggle(targetState)
    if isAnimatingTransition then return end
    if targetState == nil then targetState = not UI.Visible end
    if targetState == UI.Visible then return end

    isAnimatingTransition = true

    if targetState then
        UI.Visible = true
        container.Visible = true

        TweenService:Create(blurEffect, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UI.Frost
        }):Play()

        local containerCenter = Vector2.new(340, 220)
        local totalSlabs = #allSlabs
        local landedCount = 0

        for idx, slab in ipairs(allSlabs) do
            local slabCenter = Vector2.new(slab.Base.X.Offset + slab.Root.Size.X.Offset / 2, slab.Base.Y.Offset + slab.Root.Size.Y.Offset / 2)
            local outward = slabCenter - containerCenter
            outward = (outward.Magnitude < 1) and Vector2.new(0, -1) or outward.Unit

            local startOffset = outward * 220
            local rotSign = (idx % 2 == 1) and 1 or -1

            slab.Locked = true
            slab.Sweeping = true
            slab.Root.Position = UDim2.new(slab.Base.X.Scale, slab.Base.X.Offset + startOffset.X, slab.Base.Y.Scale, slab.Base.Y.Offset + startOffset.Y)
            slab.Root.Rotation = rotSign * 14
            slab.Scale.Scale = 0.90
            slab.Surface.BackgroundTransparency = UI.TintAlpha
            for _, layer in ipairs(slab.Layers) do layer.Visible = true end
            slab.Content.Visible = false
            slab.RimStroke.Transparency = 0
            slab.InnerStroke.Transparency = 0.93
            for _, fStroke in ipairs(slab.FringeStrokes) do fStroke.Transparency = 0.72 end
            slab.Specular.Offset = Vector2.new(-1, 0)

            task.delay((idx - 1) * 0.06, function()
                local moveTween = TweenService:Create(slab.Root, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = slab.Base,
                    Rotation = 0,
                })
                TweenService:Create(slab.Scale, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Scale = 1,
                }):Play()

                moveTween.Completed:Connect(function()
                    slab.Content.Visible = true
                    slab.Locked = false
                    slab.Blend = 0
                    slab.LastOffset = Vector2.new(9999, 9999)

                    local sweep = TweenService:Create(slab.Specular, TweenInfo.new(0.50, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    })
                    sweep.Completed:Connect(function() slab.Sweeping = false end)
                    sweep:Play()

                    landedCount = landedCount + 1
                    if landedCount == totalSlabs then
                        isAnimatingTransition = false
                    end
                end)
                moveTween:Play()
            end)
        end
    else
        for sIdx = 1, 26 do
            local randomSlab = allSlabs[math.random(1, #allSlabs)]
            local absP = randomSlab.Root.AbsolutePosition
            local absS = randomSlab.Root.AbsoluteSize

            local randX = absP.X + math.random(8, math.max(10, absS.X - 8))
            local randY = absP.Y + math.random(8, math.max(10, absS.Y - 8))

            local splinter = Instance.new("Frame")
            splinter.Name = "Splinter"
            splinter.AnchorPoint = Vector2.new(0.5, 0.5)
            splinter.Size = UDim2.fromOffset(math.random(3, 7), math.random(18, 60))
            splinter.Position = UDim2.fromOffset(randX, randY + guiInset.Y)
            splinter.ZIndex = 50
            splinter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            splinter.BackgroundTransparency = 0.50
            splinter.Rotation = math.random(-180, 180)
            splinter.BorderSizePixel = 0
            splinter.Parent = splinterLayer

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 2)
            sCorner.Parent = splinter

            local sStroke = Instance.new("UIStroke")
            sStroke.Thickness = 1
            sStroke.Color = currentTheme.C1
            sStroke.Transparency = 0.50
            sStroke.Parent = splinter

            local scatterAngle = math.rad(math.random(0, 360))
            local scatterDist = math.random(180, 340)
            local endPos = UDim2.fromOffset(randX + math.cos(scatterAngle) * scatterDist, randY + guiInset.Y + math.sin(scatterAngle) * scatterDist)
            local endRot = splinter.Rotation + math.random(-180, 180)

            local spinTween = TweenService:Create(splinter, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = endPos,
                Rotation = endRot,
                BackgroundTransparency = 1,
            })
            local strokeFade = TweenService:Create(sStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Transparency = 1,
            })

            spinTween:Play()
            strokeFade:Play()
            spinTween.Completed:Connect(function() splinter:Destroy() end)
        end

        local fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, slab in ipairs(allSlabs) do
            slab.Locked = true
            slab.Content.Visible = false
            for _, layer in ipairs(slab.Layers) do layer.Visible = false end
            TweenService:Create(slab.Surface, fade, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(slab.RimStroke, fade, { Transparency = 1 }):Play()
            TweenService:Create(slab.InnerStroke, fade, { Transparency = 1 }):Play()
            for _, fStroke in ipairs(slab.FringeStrokes) do TweenService:Create(fStroke, fade, { Transparency = 1 }):Play() end
        end

        TweenService:Create(blurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 }):Play()

        task.delay(0.26, function()
            container.Visible = false
            UI.Visible = false
            isAnimatingTransition = false
        end)
    end
end

mainMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isKeybindListeningGlobal then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == UI.ToggleKey or input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
        UI:Toggle()
    end
end))

-- [[ 15. MAIN RENDER LOOP ]]
local virtualLight = Vector2.new(0, 0)
local fpsFrameCount = 0
local fpsTimeElapsed = 0

mainMaid:GiveTask(RunService.RenderStepped:Connect(function(dt)
    updateOrb(dt)
    if not UI.Visible then return end

    local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if vp.X <= 0 or vp.Y <= 0 then return end

    fpsFrameCount = fpsFrameCount + 1
    fpsTimeElapsed = fpsTimeElapsed + dt
    if fpsTimeElapsed >= 0.50 then
        local currentFPS = math.floor(fpsFrameCount / fpsTimeElapsed)
        fpsFrameCount = 0
        fpsTimeElapsed = 0

        local currentPing = 0
        pcall(function()
            currentPing = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        fpsChip.Text = string.format("FPS %03d", math.clamp(currentFPS, 0, 999))
        pingChip.Text = string.format("PING %02d", math.clamp(currentPing, 0, 999))

        local up = math.floor(os.clock() - sessionStart)
        dockClock.Text = string.format("%02d:%02d:%02d", up // 3600, (up % 3600) // 60, up % 60)
    end

    local mousePos = UserInputService:GetMouseLocation() - guiInset
    local clampedDt = math.clamp(dt, 0, 0.10)
    local lightLerpFactor = 1 - (1 - 0.18) ^ (clampedDt * 60)
    virtualLight = virtualLight:Lerp(mousePos, lightLerpFactor)

    local vpCenter = vp / 2
    local norm = Vector2.new((mousePos.X - vpCenter.X) / vpCenter.X, (mousePos.Y - vpCenter.Y) / vpCenter.Y)
    local activeScale = containerScale.Scale

    local wave = 0.50 + 0.50 * math.sin(os.clock() * 4.5)
    pulseDot.BackgroundTransparency = 0.20 + 0.55 * wave

    for _, slab in ipairs(allSlabs) do
        local lagAlpha = 1 - (1 - slab.Lag) ^ (clampedDt * 60)
        slab.Follow = slab.Follow:Lerp(containerPos, lagAlpha)

        if not slab.Locked then
            if rimState ~= "Idle" then
                slab.RimStroke.Transparency = 0.05 + 0.45 * wave
            end
            slab.Blend = math.min(1, slab.Blend + clampedDt * 5)
            local inertia = (slab.Follow - containerPos) / activeScale
            local parallax = UI.Parallax and (norm * slab.Depth) or Vector2.new(0, 0)
            local totalOffset = (parallax + inertia) * slab.Blend

            if (totalOffset - slab.LastOffset).Magnitude >= 0.05 then
                slab.LastOffset = totalOffset
                slab.Root.Position = UDim2.new(
                    slab.Base.X.Scale,
                    slab.Base.X.Offset + totalOffset.X,
                    slab.Base.Y.Scale,
                    slab.Base.Y.Offset + totalOffset.Y
                )
            end
        end

        local slabAbsCentre = slab.Root.AbsolutePosition + slab.Root.AbsoluteSize / 2
        local slabAbsWidth = math.max(1, slab.Root.AbsoluteSize.X)

        if not slab.Sweeping then
            local specOffset = math.clamp((virtualLight.X - slabAbsCentre.X) / slabAbsWidth, -1, 1)
            slab.Specular.Offset = Vector2.new(specOffset, 0)
        end

        local deltaX = virtualLight.X - slabAbsCentre.X
        local deltaY = virtualLight.Y - slabAbsCentre.Y
        local angleDeg = math.deg(math.atan2(deltaY, deltaX))

        slab.Rim.Rotation = angleDeg
        for _, fGrad in ipairs(slab.Fringe) do
            fGrad.Rotation = angleDeg
        end
    end
end))

function UI:Destroy()
    mainMaid:Destroy()
    genv.__TwoKPrismWarZ = nil
end

genv.__TwoKPrismWarZ = UI
container.Visible = false

-- ==============================================================================
-- AUTOMATION & COMBAT ENGINE FOR ROBLOXZ - 1000Z
-- ==============================================================================

local Bot = {
    -- Combat Settings
    SilentAim = false,
    AimbotFOV = 120,
    ShowFOVCircle = true,
    TargetHitbox = "Head",
    TargetPriority = "Closest Distance",
    NoSpread = true,
    NoRecoil = true,
    TriggerBot = false,
    TriggerBotDelay = 0.05,
    FastMelee = false,
    AutoReload = false,
    KillAura = false,
    KillAuraRange = 16,

    -- Visuals / ESP Settings
    PlayerESP = true,
    PlayerBox = true,
    PlayerName = true,
    PlayerHealth = true,
    PlayerHeadDot = true,
    PlayerWeapon = false,
    PlayerChams = true,
    PlayerTracers = false,
    ESPMaxDistance = 1500,
    LootESP = true,
    LootFilter = "All Items",
    SafeZoneESP = true,

    -- Loot Automation Settings
    AutoVacuumLoot = false,
    VacuumRadius = 150,
    VacuumFilter = "All Items",
    AutoClaimDaily = true,
    AutoClaimPass = true,
    AutoBandage = false,
    AutoBandageThreshold = 40,

    -- Player & Movement Settings
    WalkSpeedEnabled = false,
    WalkSpeedValue = 24,
    JumpPowerEnabled = false,
    JumpPowerValue = 50,
    InfJump = false,
    Noclip = false,
    FlyEnabled = false,
    FlySpeed = 50,
    Fullbright = false,
    DevRunBoost = false,
    DevRunMultiplier = 3,
}

local function getRootPart()
    local char = localPlayer and localPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    local char = localPlayer and localPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Weapon Ballistics Recoil & Spread Hooks
pcall(function()
    if WeaponBallistics then
        local origSpread = WeaponBallistics.Spread
        WeaponBallistics.Spread = function(a1, a2, a3, a4)
            if Bot.NoSpread then
                return 0, 0
            end
            if origSpread then return origSpread(a1, a2, a3, a4) end
        end

        local origRecoil = WeaponBallistics.RecoilKick
        WeaponBallistics.RecoilKick = function(a1, a2, a3, a4)
            if Bot.NoRecoil then
                return 0, 0
            end
            if origRecoil then return origRecoil(a1, a2, a3, a4) end
        end
    end
end)

-- FOV Circle Screen Frame (100% Reliable In-Engine Rendering)
local fovFrame = Instance.new("Frame")
fovFrame.Name = "WarZ_FOVCircle"
fovFrame.BackgroundTransparency = 1
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Visible = false
fovFrame.Parent = screenGui
mainMaid:GiveTask(fovFrame)

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.2
fovStroke.Color = currentTheme.C1
fovStroke.Transparency = 0.25
fovStroke.Parent = fovFrame

RegisterAccent(function(theme)
    if fovStroke then
        fovStroke.Color = theme.C1
    end
end)

mainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if fovFrame then
        local diameter = (Bot.AimbotFOV or 120) * 2
        fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        fovFrame.Size = UDim2.fromOffset(diameter, diameter)
        fovFrame.Visible = Bot.ShowFOVCircle and (Bot.SilentAim or Bot.TriggerBot or (UI and UI.Visible))
    end
end))

-- Aimbot Target Resolution (Locked to Screen Center / Crosshair)
local function getClosestTarget()
    local myHrp = getRootPart()
    if not myHrp then return nil end

    local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)
    local bestTarget = nil
    local bestMetric = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local head = char:FindFirstChild("Head")

            if hum and hum.Health > 0 and hrp and head then
                local chosenPart = (Bot.TargetHitbox == "Head" and head) or hrp
                local screenPoint, onScreen = camera:WorldToViewportPoint(chosenPart.Position)

                if onScreen and screenPoint.Z > 0 then
                    local dist2D = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                    local dist3D = (hrp.Position - myHrp.Position).Magnitude

                    if dist2D <= (Bot.AimbotFOV or 120) then
                        local metric = dist2D
                        if Bot.TargetPriority == "Closest Distance" then
                            metric = dist3D
                        elseif Bot.TargetPriority == "Lowest Health" then
                            metric = hum.Health
                        end

                        if metric < bestMetric then
                            bestMetric = metric
                            bestTarget = {
                                Player = p,
                                Character = char,
                                Humanoid = hum,
                                Part = chosenPart,
                                Distance = dist3D,
                            }
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Silent Aim Camera LookVector alignment (Supports both ADS aiming and Hipfire)
mainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if Bot.SilentAim then
        local target = getClosestTarget()
        if target and target.Part then
            local aimPos = target.Part.Position
            local char = localPlayer.Character
            local isAiming = (char and char:GetAttribute("WarZAiming") == true) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            if isAiming then
                local camPos = camera.CFrame.Position
                camera.CFrame = CFrame.lookAt(camPos, aimPos)
            end
        end
    end
end))

-- TriggerBot Routine
mainMaid:GiveTask(task.spawn(function()
    while true do
        if Bot.TriggerBot then
            pcall(function()
                local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
                local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)
                local unitRay = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
                local rayParams = RaycastParams.new()
                rayParams.FilterType = RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { localPlayer.Character }

                local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 800, rayParams)
                if result and result.Instance then
                    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
                    if hitModel and hitModel ~= localPlayer.Character then
                        local hum = hitModel:FindFirstChildOfClass("Humanoid")
                        local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
                        if hum and hum.Health > 0 and hitPlayer then
                            -- Auto fire mouse click
                            if mouse1click then
                                mouse1click()
                            end
                            task.wait(Bot.TriggerBotDelay)
                        end
                    end
                end
            end)
            task.wait(0.03)
        else
            task.wait(0.2)
        end
    end
end))

-- Kill Aura / Melee Aura Routine
mainMaid:GiveTask(task.spawn(function()
    while true do
        if Bot.KillAura then
            pcall(function()
                local myHrp = getRootPart()
                if not myHrp then return end

                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= localPlayer and p.Character then
                        local char = p.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local hrp = char:FindFirstChild("HumanoidRootPart")

                        if hum and hum.Health > 0 and hrp then
                            local dist = (hrp.Position - myHrp.Position).Magnitude
                            if dist <= Bot.KillAuraRange then
                                if WarZActionRequest then
                                    WarZActionRequest:FireServer("Fire", {
                                        targetPosition = hrp.Position,
                                        direction = (hrp.Position - myHrp.Position).Unit,
                                        inputType = "Mouse",
                                    })
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.15)
        else
            task.wait(0.3)
        end
    end
end))

-- [[ 16. TACTICAL COMPETITIVE ESP SYSTEM ]]
-- Minimalist Tactical Style matching user reference:
-- Orange 2D Box + Vertical Neon Green Health Bar + Hot Pink Head Dot + Clean White Name/Dist + White Chams Outline
-- Evades WarZGuiGuardian via "WarZ_" prefix and namecall interception

local espScreenGui = Instance.new("ScreenGui")
espScreenGui.Name = "WarZ_TacticalESP"
espScreenGui.ResetOnSpawn = false
espScreenGui.DisplayOrder = 9998
espScreenGui.Parent = PlayerGui or targetParent
mainMaid:GiveTask(espScreenGui)

local activeTacticalESP = {}

local function createPlayerESP(player)
    if player == localPlayer then return end
    if activeTacticalESP[player] then return end

    local box = Instance.new("Frame")
    box.Name = "WarZ_Box_" .. player.Name
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espScreenGui

    local bStroke = Instance.new("UIStroke")
    bStroke.Name = "Stroke"
    bStroke.Thickness = 1.2
    bStroke.Color = Color3.fromRGB(255, 170, 0) -- Tactical Orange
    bStroke.Parent = box

    local hpBg = Instance.new("Frame")
    hpBg.Name = "WarZ_HPBg_" .. player.Name
    hpBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    hpBg.BorderSizePixel = 0
    hpBg.Visible = false
    hpBg.Parent = espScreenGui

    local hpFill = Instance.new("Frame")
    hpFill.Name = "HPFill"
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 60) -- Neon Green
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg

    local headDot = Instance.new("Frame")
    headDot.Name = "WarZ_Dot_" .. player.Name
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Size = UDim2.fromOffset(7, 7)
    headDot.BackgroundColor3 = Color3.fromRGB(255, 35, 155) -- Vivid Hot Pink
    headDot.BorderSizePixel = 0
    headDot.Visible = false
    headDot.Parent = espScreenGui

    local dotCr = Instance.new("UICorner")
    dotCr.CornerRadius = UDim.new(1, 0)
    dotCr.Parent = headDot

    local dotStr = Instance.new("UIStroke")
    dotStr.Thickness = 0.8
    dotStr.Color = Color3.fromRGB(0, 0, 0)
    dotStr.Parent = headDot

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "WarZ_Name_" .. player.Name
    nameLbl.AnchorPoint = Vector2.new(0.5, 1)
    nameLbl.Size = UDim2.fromOffset(260, 15)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Font = Enum.Font.SourceSansBold
    nameLbl.TextSize = 13
    nameLbl.Visible = false
    nameLbl.Parent = espScreenGui

    local espData = {
        Player = player,
        Box = box,
        BoxStroke = bStroke,
        HpBg = hpBg,
        HpFill = hpFill,
        Dot = headDot,
        Name = nameLbl,
        Chams = nil,
        Connections = {},
    }

    local function setupChams(char)
        if not char then return end
        if espData.Chams then pcall(function() espData.Chams:Destroy() end) end
        local chams = Instance.new("Highlight")
        chams.Name = "WarZ_Chams_" .. player.Name
        chams.FillTransparency = 1
        chams.OutlineColor = Color3.fromRGB(255, 255, 255) -- Pure White
        chams.OutlineTransparency = 0
        chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chams.Adornee = char
        chams.Parent = char
        espData.Chams = chams
    end

    if player.Character then
        setupChams(player.Character)
    end

    local cAdded = player.CharacterAdded:Connect(function(newChar)
        setupChams(newChar)
    end)
    local cRemoving = player.CharacterRemoving:Connect(function()
        if espData.Chams then pcall(function() espData.Chams:Destroy() end); espData.Chams = nil end
    end)

    table.insert(espData.Connections, cAdded)
    table.insert(espData.Connections, cRemoving)
    activeTacticalESP[player] = espData
end

local function removePlayerESP(player)
    local espData = activeTacticalESP[player]
    if espData then
        for _, c in ipairs(espData.Connections) do
            pcall(function() c:Disconnect() end)
        end
        if espData.Box then espData.Box:Destroy() end
        if espData.HpBg then espData.HpBg:Destroy() end
        if espData.Dot then espData.Dot:Destroy() end
        if espData.Name then espData.Name:Destroy() end
        if espData.Chams then pcall(function() espData.Chams:Destroy() end) end
        activeTacticalESP[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    createPlayerESP(p)
end
mainMaid:GiveTask(Players.PlayerAdded:Connect(createPlayerESP))
mainMaid:GiveTask(Players.PlayerRemoving:Connect(removePlayerESP))

mainMaid:GiveTask(function()
    for p, _ in pairs(activeTacticalESP) do
        removePlayerESP(p)
    end
end)

-- Main RenderStepped update loop for Tactical ESP
mainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if not Bot.PlayerESP then
        for _, esp in pairs(activeTacticalESP) do
            esp.Box.Visible = false
            esp.HpBg.Visible = false
            esp.Dot.Visible = false
            esp.Name.Visible = false
            if esp.Chams then esp.Chams.Enabled = false end
        end
        return
    end

    local myHrp = getRootPart()
    local myPos = myHrp and myHrp.Position or camera.CFrame.Position
    local maxDist = Bot.ESPMaxDistance or 1500

    for p, esp in pairs(activeTacticalESP) do
        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if char and hrp and hum and hum.Health > 0 and char.Parent then
            local dist = math.floor((hrp.Position - myPos).Magnitude)
            if dist <= maxDist then
                local rootPos = hrp.Position
                local top = head and (head.Position + Vector3.new(0, 0.7, 0)) or (rootPos + Vector3.new(0, 2.4, 0))
                local bottom = rootPos - Vector3.new(0, 3.0, 0)

                local topScreen, topVis = camera:WorldToViewportPoint(top)
                local botScreen, botVis = camera:WorldToViewportPoint(bottom)
                local hrpScreen, hrpVis = camera:WorldToViewportPoint(rootPos)

                if hrpVis and topScreen.Z > 0 and botScreen.Z > 0 then
                    local height = math.max(12, math.abs(botScreen.Y - topScreen.Y))
                    local width = math.max(8, height * 0.58)
                    local boxX = hrpScreen.X - width / 2
                    local boxY = topScreen.Y

                    -- 1. Orange 2D Box
                    esp.Box.Visible = Bot.PlayerBox
                    if Bot.PlayerBox then
                        esp.Box.Position = UDim2.fromOffset(boxX, boxY)
                        esp.Box.Size = UDim2.fromOffset(width, height)
                    end

                    -- 2. Vertical Health Bar
                    esp.HpBg.Visible = Bot.PlayerHealth
                    if Bot.PlayerHealth then
                        local hpPct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                        esp.HpBg.Position = UDim2.fromOffset(boxX - 4, boxY)
                        esp.HpBg.Size = UDim2.fromOffset(2, height)
                        esp.HpFill.Position = UDim2.fromOffset(0, height * (1 - hpPct))
                        esp.HpFill.Size = UDim2.fromOffset(2, height * hpPct)
                    end

                    -- 3. Pink Head Dot
                    if head and Bot.PlayerHeadDot then
                        local headScreen, headVis = camera:WorldToViewportPoint(head.Position)
                        if headVis and headScreen.Z > 0 then
                            esp.Dot.Visible = true
                            esp.Dot.Position = UDim2.fromOffset(headScreen.X, headScreen.Y)
                        else
                            esp.Dot.Visible = false
                        end
                    else
                        esp.Dot.Visible = false
                    end

                    -- 4. Name & Distance Text
                    esp.Name.Visible = Bot.PlayerName
                    if Bot.PlayerName then
                        esp.Name.Position = UDim2.fromOffset(hrpScreen.X, boxY - 2)
                        local label = string.format("%s [%dm]", p.DisplayName, dist)
                        if Bot.PlayerWeapon then
                            local wName = getItemName(p:GetAttribute("BloxZEquippedWeaponId"))
                            if wName and wName ~= "" and wName ~= "Unknown Item" then
                                label = label .. " | " .. wName
                            end
                        end
                        esp.Name.Text = label
                    end

                    -- 5. White Chams Outline
                    if esp.Chams then
                        esp.Chams.Enabled = Bot.PlayerChams
                    end
                else
                    esp.Box.Visible = false
                    esp.HpBg.Visible = false
                    esp.Dot.Visible = false
                    esp.Name.Visible = false
                    if esp.Chams then esp.Chams.Enabled = false end
                end
            else
                esp.Box.Visible = false
                esp.HpBg.Visible = false
                esp.Dot.Visible = false
                esp.Name.Visible = false
                if esp.Chams then esp.Chams.Enabled = false end
            end
        else
            esp.Box.Visible = false
            esp.HpBg.Visible = false
            esp.Dot.Visible = false
            esp.Name.Visible = false
            if esp.Chams then esp.Chams.Enabled = false end
        end
    end
end))

-- [[ 17. WORLD LOOT ESP SYSTEM ]]
local activeLootBillboards = {}

local function clearAllLootESP()
    for _, b in pairs(activeLootBillboards) do
        pcall(function() b:Destroy() end)
    end
    table.clear(activeLootBillboards)
end
mainMaid:GiveTask(clearAllLootESP)

mainMaid:GiveTask(task.spawn(function()
    while true do
        if Bot.LootESP then
            pcall(function()
                local lootFolder = workspace:FindFirstChild("BloxZWorldLoot")
                local myHrp = getRootPart()
                local myPos = myHrp and myHrp.Position or camera.CFrame.Position

                if lootFolder then
                    local validIds = {}
                    local drops = lootFolder:GetChildren()

                    for _, drop in ipairs(drops) do
                        local pickupId = drop:GetAttribute("WarZPickupId")
                        local itemId = drop:GetAttribute("BloxZItemId")
                        local amount = drop:GetAttribute("BloxZAmount") or 1

                        if pickupId and itemId then
                            validIds[pickupId] = true
                            local dropPart = drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")
                            local dropPos = dropPart and dropPart.Position or drop:GetPivot().Position
                            local dist = math.floor((dropPos - myPos).Magnitude)

                            if dist <= (Bot.ESPMaxDistance or 1000) then
                                local bBillboard = activeLootBillboards[pickupId]
                                local name, kind = getItemInfo(itemId)

                                -- Rarity color scheme
                                local themeColor = Color3.fromRGB(220, 230, 245)
                                if kind == "weapon" then
                                    themeColor = Color3.fromRGB(255, 170, 40) -- Gold
                                elseif kind == "consumable" then
                                    themeColor = Color3.fromRGB(50, 240, 120) -- Emerald
                                elseif kind == "deployable" or kind == "barricade" then
                                    themeColor = Color3.fromRGB(0, 220, 255) -- Cyan
                                elseif kind == "attachment" then
                                    themeColor = Color3.fromRGB(255, 230, 80) -- Yellow
                                end

                                if not bBillboard or not bBillboard.Parent then
                                    bBillboard = Instance.new("BillboardGui")
                                    bBillboard.Name = "WarZ_Loot_" .. tostring(pickupId)
                                    bBillboard.AlwaysOnTop = true
                                    bBillboard.Size = UDim2.fromOffset(140, 26)
                                    bBillboard.StudsOffset = Vector3.new(0, 1.2, 0)
                                    bBillboard.Adornee = dropPart or drop
                                    bBillboard.Parent = espFolder

                                    local lFrame = Instance.new("Frame")
                                    lFrame.Name = "Frame"
                                    lFrame.Size = UDim2.fromScale(1, 1)
                                    lFrame.BackgroundColor3 = Color3.fromRGB(15, 14, 24)
                                    lFrame.BackgroundTransparency = 0.25
                                    lFrame.BorderSizePixel = 0
                                    lFrame.Parent = bBillboard

                                    local lCorner = Instance.new("UICorner")
                                    lCorner.CornerRadius = UDim.new(0, 4)
                                    lCorner.Parent = lFrame

                                    local lStroke = Instance.new("UIStroke")
                                    lStroke.Name = "Stroke"
                                    lStroke.Thickness = 1
                                    lStroke.Color = themeColor
                                    lStroke.Parent = lFrame

                                    local lText = Instance.new("TextLabel")
                                    lText.Name = "Label"
                                    lText.Size = UDim2.fromScale(1, 1)
                                    lText.BackgroundTransparency = 1
                                    lText.TextColor3 = themeColor
                                    lText.Font = Enum.Font.GothamBold
                                    lText.TextSize = 10
                                    lText.Parent = lFrame

                                    activeLootBillboards[pickupId] = bBillboard
                                end

                                local lFrame = bBillboard:FindFirstChild("Frame")
                                if lFrame then
                                    local lText = lFrame:FindFirstChild("Label")
                                    if lText then
                                        lText.Text = string.format("%s (x%d) [%dm]", name, amount, dist)
                                    end
                                end
                            else
                                if activeLootBillboards[pickupId] then
                                    activeLootBillboards[pickupId]:Destroy()
                                    activeLootBillboards[pickupId] = nil
                                end
                            end
                        end
                    end

                    for id, b in pairs(activeLootBillboards) do
                        if not validIds[id] then
                            b:Destroy()
                            activeLootBillboards[id] = nil
                        end
                    end
                end
            end)
            task.wait(0.25)
        else
            if next(activeLootBillboards) ~= nil then
                clearAllLootESP()
            end
            task.wait(0.8)
        end
    end
end))

-- [[ 18. AUTO VACUUM LOOT & REWARDS ]]
local function vacuumLootDrops(force)
    if not force and not Bot.AutoVacuumLoot then return end
    pcall(function()
        local lootFolder = workspace:FindFirstChild("BloxZWorldLoot")
        local myHrp = getRootPart()
        if not lootFolder or not myHrp or not WarZActionRequest then return end

        for _, drop in ipairs(lootFolder:GetChildren()) do
            local pickupId = drop:GetAttribute("WarZPickupId")
            local itemId = drop:GetAttribute("BloxZItemId")
            if pickupId then
                local dropPos = drop:GetPivot().Position
                local dist = (dropPos - myHrp.Position).Magnitude

                if force or dist <= Bot.VacuumRadius then
                    local allowed = true
                    if Bot.VacuumFilter == "Guns & Weapons" then
                        local info = ItemDBModule and ItemDBModule.Get and ItemDBModule.Get(itemId)
                        allowed = (info and info.kind == "weapon")
                    elseif Bot.VacuumFilter == "Medicals" then
                        local info = ItemDBModule and ItemDBModule.Get and ItemDBModule.Get(itemId)
                        allowed = (info and info.kind == "consumable")
                    elseif Bot.VacuumFilter == "Barricades & Shields" then
                        local info = ItemDBModule and ItemDBModule.Get and ItemDBModule.Get(itemId)
                        allowed = (info and (info.kind == "barricade" or tostring(info.name):find("Shield")))
                    end

                    if allowed then
                        WarZActionRequest:FireServer("Pickup", { pickupId = pickupId })
                        task.wait(0.04)
                    end
                end
            end
        end
    end)
end

mainMaid:GiveTask(task.spawn(function()
    while true do
        if Bot.AutoVacuumLoot then
            vacuumLootDrops()
            task.wait(0.25)
        else
            task.wait(0.8)
        end
    end
end))

-- Auto Claim Daily & BattlePass
mainMaid:GiveTask(task.spawn(function()
    while true do
        if Bot.AutoClaimDaily and WarZDailyReward then
            pcall(function()
                WarZDailyReward:InvokeServer("Claim")
            end)
        end
        if Bot.AutoClaimPass and WarZBattlePass then
            pcall(function()
                for tier = 0, 30 do
                    WarZBattlePass:InvokeServer("ClaimTier", tier, false)
                end
                for mission = 1, 10 do
                    WarZBattlePass:InvokeServer("ClaimMission", mission)
                end
            end)
        end
        task.wait(15)
    end
end))

-- Auto Bandage / Heal Routine
mainMaid:GiveTask(task.spawn(function()
    while true do
        if Bot.AutoBandage then
            pcall(function()
                local hum = getHumanoid()
                if hum and hum.Health > 0 and hum.Health <= Bot.AutoBandageThreshold then
                    if WarZActionRequest then
                        WarZActionRequest:FireServer("UseItem", { itemId = 101262 }) -- Bandages DX
                    end
                end
            end)
            task.wait(2.5)
        else
            task.wait(1.5)
        end
    end
end))

-- [[ 19. PLAYER MODIFIERS & FLY ENGINE ]]
mainMaid:GiveTask(RunService.Stepped:Connect(function()
    local char = localPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Bot.WalkSpeedEnabled then
            hum.WalkSpeed = Bot.WalkSpeedValue
        end
        if Bot.JumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = Bot.JumpPowerValue
        end
    end

    if Bot.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

mainMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
    if Bot.InfJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- Smooth WASD Flight Controller
local flyBV = nil
local flyBG = nil

local function setFlyMode(enable)
    local char = localPlayer.Character
    local hrp = getRootPart()
    if not char or not hrp then return end

    if enable then
        if not flyBV then
            flyBV = Instance.new("BodyVelocity")
            flyBV.Name = "WarZ_FlyBV"
            flyBV.MaxForce = Vector3.new(9e5, 9e5, 9e5)
            flyBV.Velocity = Vector3.zero
            flyBV.Parent = hrp
        end
        if not flyBG then
            flyBG = Instance.new("BodyGyro")
            flyBG.Name = "WarZ_FlyBG"
            flyBG.MaxTorque = Vector3.new(9e5, 9e5, 9e5)
            flyBG.CFrame = hrp.CFrame
            flyBG.Parent = hrp
        end
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        local hum = getHumanoid()
        if hum then hum.PlatformStand = false end
    end
end

mainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if Bot.FlyEnabled and flyBV and flyBG then
        local hrp = getRootPart()
        local hum = getHumanoid()
        if not hrp or not hum then return end

        hum.PlatformStand = true
        flyBG.CFrame = camera.CFrame

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        flyBV.Velocity = moveDir.Unit * Bot.FlySpeed
        if moveDir.Magnitude < 0.1 then
            flyBV.Velocity = Vector3.zero
        end
    end
end))

mainMaid:GiveTask(function() setFlyMode(false) end)

-- Fullbright state
local origLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
}

local function applyFullbright(val)
    if val then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = origLighting.Brightness
        Lighting.ClockTime = origLighting.ClockTime
        Lighting.FogEnd = origLighting.FogEnd
        Lighting.GlobalShadows = origLighting.GlobalShadows
        Lighting.Ambient = origLighting.Ambient
    end
end

mainMaid:GiveTask(function() applyFullbright(false) end)

-- Teleport helper
local function teleportTo(targetCFrame)
    local root = getRootPart()
    if root then
        if root.Anchored then root.Anchored = false end
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ==============================================================================
-- 2K PRISM UI PAGE REGISTRATIONS
-- ==============================================================================

local combatTab = UI:Tab("COMBAT")
local visualsTab = UI:Tab("VISUALS")
local lootTab = UI:Tab("LOOT/FARM")
local playerTab = UI:Tab("PLAYER")
local teleportTab = UI:Tab("TELEPORT")
local settingsTab = UI:Tab("SETTINGS")

-- ------------------------------------------------------------------------------
-- Tab: COMBAT
-- ------------------------------------------------------------------------------
local aimSec = combatTab:Section("AIMBOT & SILENT AIM")

aimSec:Toggle({
    Name = "ระบบเล็งเป้าอัตโนมัติ (SILENT AIM)",
    Desc = "คำนวณและล็อกเป้าหมายเข้าจุดอ่อน (Head/Torso) อัตโนมัติเมื่อเล็งหรือกดยิง",
    Default = false,
    Callback = function(val)
        Bot.SilentAim = val
        UI:SetStatus("Silent Aim: " .. (val and "เปิดใช้งาน" or "ปิด"))
    end,
})

aimSec:Toggle({
    Name = "แสดงวงกลมระยะเล็ง (SHOW FOV CIRCLE)",
    Desc = "แสดงเส้นวงกลมบอกขอบเขตการทำงานของ Aimbot บนหน้าจอ",
    Default = true,
    Callback = function(val)
        Bot.ShowFOVCircle = val
    end,
})

aimSec:Slider({
    Name = "รัศมีขอบเขตเล็ง (AIMBOT FOV)",
    Min = 40,
    Max = 450,
    Step = 10,
    Default = 120,
    Suffix = " px",
    Callback = function(val)
        Bot.AimbotFOV = val
    end,
})

aimSec:Dropdown({
    Name = "ตำแหน่งล็อกเป้า (TARGET HITBOX)",
    Options = { "Head", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(choice)
        Bot.TargetHitbox = choice
    end,
})

aimSec:Dropdown({
    Name = "ลำดับความสำคัญเป้าหมาย (PRIORITY)",
    Options = { "Closest Distance", "Lowest Health", "Crosshair Nearest" },
    Default = "Closest Distance",
    Callback = function(choice)
        Bot.TargetPriority = choice
    end,
})

local wepSec = combatTab:Section("WEAPON MODS & BYPASS")

wepSec:Toggle({
    Name = "ไร้ระยะกระจาย (NO SPREAD)",
    Desc = "Bypass ฟังก์ชัน WeaponBallistics.Spread วิถีกระสุนพุ่งตรงจุดกึ่งกลาง 100%",
    Default = true,
    Callback = function(val)
        Bot.NoSpread = val
        UI:Notify({ Title = "NO SPREAD", Text = val and "เปิดใช้งานกระสุนตรง 100%" or "ปิด", Duration = 2.5 })
    end,
})

wepSec:Toggle({
    Name = "ไร้แรงดีดปืน (NO RECOIL)",
    Desc = "Bypass ฟังก์ชัน WeaponBallistics.RecoilKick ปืนนิ่งสนิทเวลายิงต่อเนื่อง",
    Default = true,
    Callback = function(val)
        Bot.NoRecoil = val
        UI:Notify({ Title = "NO RECOIL", Text = val and "เปิดใช้งานไร้แรงดีดปืน" or "ปิด", Duration = 2.5 })
    end,
})

wepSec:Toggle({
    Name = "ยิงอัตโนมัติเมื่อเป้าตรงศัตรู (TRIGGERBOT)",
    Desc = "ส่งคำสั่งกดยิงทันทีเมื่อเป้าเล็งทาบลงบนตัวผู้เล่นหรือศัตรู",
    Default = false,
    Callback = function(val)
        Bot.TriggerBot = val
        UI:SetStatus("TriggerBot: " .. (val and "เปิดใช้งาน" or "ปิด"))
    end,
})

wepSec:Toggle({
    Name = "ออร่าโจมตีระยะประชิด (KILL AURA)",
    Desc = "โจมตีผู้เล่นและศัตรูรอบตัวอัตโนมัติในรัศมี 16 สตั๊ด",
    Default = false,
    Callback = function(val)
        Bot.KillAura = val
        UI:SetStatus("Kill Aura: " .. (val and "เปิดใช้งาน" or "ปิด"))
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: VISUALS
-- ------------------------------------------------------------------------------
local espSec = visualsTab:Section("TACTICAL PLAYER ESP")

espSec:Toggle({
    Name = "เปิดระบบมองทะลุผู้เล่น (TACTICAL ESP)",
    Desc = "สไตล์การแข่งขัน: กรอบส้ม + หลอดเลือดเขียว + จุดหัวชมพู + เส้นขาว",
    Default = true,
    Callback = function(val)
        Bot.PlayerESP = val
        UI:SetStatus("Tactical ESP: " .. (val and "เปิด" or "ปิด"))
    end,
})

espSec:Toggle({
    Name = "กรอบตัวละครสีส้ม (ORANGE 2D BOX)",
    Default = true,
    Callback = function(val) Bot.PlayerBox = val end,
})

espSec:Toggle({
    Name = "หลอดเลือดแนวตั้งด้านข้าง (VERTICAL HP BAR)",
    Default = true,
    Callback = function(val) Bot.PlayerHealth = val end,
})

espSec:Toggle({
    Name = "จุดเล็งหัวสีชมพู (PINK HEAD DOT)",
    Desc = "แสดงจุดสีชมพูตรงหัวผู้เล่น ช่วยเล็ง Headshot ได้แม่นยำขึ้น",
    Default = true,
    Callback = function(val) Bot.PlayerHeadDot = val end,
})

espSec:Toggle({
    Name = "ชื่อและระยะทาง (NAME & DISTANCE)",
    Default = true,
    Callback = function(val) Bot.PlayerName = val end,
})

espSec:Toggle({
    Name = "ชื่ออาวุธที่ถือ (WEAPON NAME)",
    Default = false,
    Callback = function(val) Bot.PlayerWeapon = val end,
})

espSec:Toggle({
    Name = "เส้นขอบตัวละครสีขาว (WHITE CHAMS OUTLINE)",
    Desc = "แสดงโครงร่างตัวละครสีขาวเรืองแสงทะลุกำแพง",
    Default = true,
    Callback = function(val) Bot.PlayerChams = val end,
})

espSec:Slider({
    Name = "ระยะแสดงผลสูงสุด (MAX DISTANCE)",
    Min = 100,
    Max = 2500,
    Step = 50,
    Default = 1500,
    Suffix = " studs",
    Callback = function(val) Bot.ESPMaxDistance = val end,
})

local lootEspSec = visualsTab:Section("WORLD LOOT ESP")

lootEspSec:Toggle({
    Name = "มองเห็นไอเทมบนพื้น (LOOT ESP)",
    Desc = "สแกน BloxZWorldLoot แยกสีตามชนิดอาวุธ/ยา/เกราะ/กระสุน",
    Default = true,
    Callback = function(val)
        Bot.LootESP = val
        UI:SetStatus("Loot ESP: " .. (val and "เปิด" or "ปิด"))
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: LOOT/FARM
-- ------------------------------------------------------------------------------
local vacSec = lootTab:Section("AUTO VACUUM LOOT")

vacSec:Toggle({
    Name = "ดูดไอเทมบนพื้นอัตโนมัติ (AUTO VACUUM LOOT)",
    Desc = "ส่งคำสั่ง Pickup ดึงไอเทมและกล่องดรอปรอบตัวเข้ากระเป๋าต่อเนื่อง",
    Default = false,
    Callback = function(val)
        Bot.AutoVacuumLoot = val
        UI:SetStatus("Auto Vacuum: " .. (val and "เปิด" or "ปิด"))
    end,
})

vacSec:Slider({
    Name = "ระยะดูดไอเทม (VACUUM RADIUS)",
    Min = 20,
    Max = 500,
    Step = 10,
    Default = 150,
    Suffix = " studs",
    Callback = function(val)
        Bot.VacuumRadius = val
    end,
})

vacSec:Dropdown({
    Name = "คัดกรองไอเทมที่จะดูด (FILTER)",
    Options = { "All Items", "Guns & Weapons", "Medicals", "Barricades & Shields" },
    Default = "All Items",
    Callback = function(val)
        Bot.VacuumFilter = val
    end,
})

vacSec:Button({
    Name = "ดูดไอเทมรอบตัวทันที (VACUUM ALL NOW)",
    Desc = "กดดูดไอเทมทั้งหมดบนพื้นในแผนที่เข้ากระเป๋าทันที 1 ครั้ง",
    Callback = function()
        vacuumLootDrops(true)
        UI:Notify({ Title = "VACUUM", Text = "ส่งคำสั่งเก็บไอเทมรอบตัวเรียบร้อย", Duration = 2.5 })
    end,
})

local healSec = lootTab:Section("SURVIVAL & REWARDS")

healSec:Toggle({
    Name = "พันแผลอัตโนมัติเมื่อเลือดต่ำ (AUTO BANDAGE)",
    Desc = "ใช้ผ้าพันแผลอัตโนมัติเมื่อเลือดต่ำกว่าเกณฑ์ที่กำหนด",
    Default = false,
    Callback = function(val)
        Bot.AutoBandage = val
    end,
})

healSec:Slider({
    Name = "เลือดขั้นต่ำที่จะใช้ยา (THRESHOLD)",
    Min = 10,
    Max = 80,
    Step = 5,
    Default = 40,
    Suffix = " HP",
    Callback = function(val)
        Bot.AutoBandageThreshold = val
    end,
})

healSec:Button({
    Name = "กดรับรางวัลรายวันและ BattlePass (CLAIM REWARDS NOW)",
    Desc = "ส่งคำสั่งรับของรางวัล Daily Reward และ BattlePass Tiers ทันที",
    Callback = function()
        pcall(function()
            if WarZDailyReward then WarZDailyReward:InvokeServer("Claim") end
            if WarZBattlePass then
                for tier = 0, 30 do WarZBattlePass:InvokeServer("ClaimTier", tier, false) end
                for mission = 1, 10 do WarZBattlePass:InvokeServer("ClaimMission", mission) end
            end
        end)
        UI:Notify({ Title = "REWARDS", Text = "ส่งคำสั่งรับรางวัลทั้งหมดสำเร็จ!", Duration = 3 })
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: PLAYER
-- ------------------------------------------------------------------------------
local moveSec = playerTab:Section("MOVEMENT & PHYSICS")

moveSec:Toggle({
    Name = "เปิดความเร็วเดิน (WALKSPEED)",
    Desc = "ปรับความเร็วเดินของตัวละคร",
    Default = false,
    Callback = function(val)
        Bot.WalkSpeedEnabled = val
        if not val then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

moveSec:Slider({
    Name = "ความเร็วเดิน (SPEED VALUE)",
    Min = 16,
    Max = 120,
    Step = 2,
    Default = 28,
    Suffix = " studs/s",
    Callback = function(val)
        Bot.WalkSpeedValue = val
        local hum = getHumanoid()
        if hum and Bot.WalkSpeedEnabled then
            hum.WalkSpeed = val
        end
    end,
})

moveSec:Toggle({
    Name = "เปิดพลังกระโดด (JUMPPOWER)",
    Default = false,
    Callback = function(val)
        Bot.JumpPowerEnabled = val
        if not val then
            local hum = getHumanoid()
            if hum then hum.JumpPower = 50 end
        end
    end,
})

moveSec:Slider({
    Name = "พลังกระโดด (JUMP VALUE)",
    Min = 50,
    Max = 180,
    Step = 5,
    Default = 70,
    Suffix = " power",
    Callback = function(val)
        Bot.JumpPowerValue = val
    end,
})

moveSec:Toggle({
    Name = "กระโดดกลางอากาศไม่จำกัด (INFINITE JUMP)",
    Default = false,
    Callback = function(val) Bot.InfJump = val end,
})

moveSec:Toggle({
    Name = "เดินทะลุกำแพงและสิ่งกีดขวาง (NOCLIP)",
    Desc = "ปลดล็อกการชนของชิ้นส่วนตัวละคร ทำให้เดินทะลุกำแพงและโล่ได้",
    Default = false,
    Callback = function(val)
        Bot.Noclip = val
        pcall(function() localPlayer:SetAttribute("WarZDevNoClip", val) end)
        UI:Notify({ Title = "NOCLIP", Text = val and "เปิดใช้งาน Noclip" or "ปิด Noclip", Duration = 2.5 })
    end,
})

moveSec:Toggle({
    Name = "บินอิสระ (FLIGHT MODE)",
    Desc = "บินได้อย่างอิสระควบคุมด้วยปุ่ม WASD + Space/Shift",
    Default = false,
    Callback = function(val)
        Bot.FlyEnabled = val
        setFlyMode(val)
        pcall(function() localPlayer:SetAttribute("WarZDevFlightActive", val) end)
        UI:Notify({ Title = "FLIGHT", Text = val and "เปิดโหมดบิน (WASD + Space/Shift)" or "ปิดโหมดบิน", Duration = 2.5 })
    end,
})

moveSec:Slider({
    Name = "ความเร็วบิน (FLY SPEED)",
    Min = 20,
    Max = 160,
    Step = 5,
    Default = 50,
    Suffix = " studs/s",
    Callback = function(val) Bot.FlySpeed = val end,
})

local envSec = playerTab:Section("ENVIRONMENT")

envSec:Toggle({
    Name = "สว่างจ้า / กลางวันตลอดกาล (FULLBRIGHT)",
    Desc = "ปิดหมอกและเพิ่มแสงสว่าง มองเห็นชัดเจนในที่มืด",
    Default = false,
    Callback = function(val)
        Bot.Fullbright = val
        applyFullbright(val)
    end,
})

envSec:Toggle({
    Name = "บูสต์ความเร็ววิ่งทางการของเกม (DEV RUN BOOST)",
    Desc = "เปิดใช้งาน WarZDevRunMultiplier ซึ่งเป็นฟังก์ชันภายในของเกม",
    Default = false,
    Callback = function(val)
        Bot.DevRunBoost = val
        pcall(function()
            localPlayer:SetAttribute("WarZDevRunMultiplier", val and 6 or 1)
        end)
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: TELEPORT
-- ------------------------------------------------------------------------------
local warpSec = teleportTab:Section("WARP LOCATIONS")

warpSec:Button({
    Name = "วาร์ปไปตลาด / เซฟโซน (SAFE ZONE & MARKET)",
    Desc = "พิกัดจุดซื้อขาย คลังเก็บของ (Vault) และจุดปลอดภัย Safe Zone",
    Callback = function()
        teleportTo(CFrame.new(472.0, 304.5, -385.0))
        UI:Notify({ Title = "TELEPORT", Text = "วาร์ปไป Safe Zone สำเร็จ", Duration = 3 })
    end,
})

warpSec:Button({
    Name = "วาร์ปไปโซนบอส (FARMBOSS ARENA)",
    Desc = "พิกัดโซนต่อสู้และฟาร์มบอส Server-7",
    Callback = function()
        teleportTo(CFrame.new(40235.0, 305.0, -367.0))
        UI:Notify({ Title = "TELEPORT", Text = "วาร์ปไปโซนบอสสำเร็จ", Duration = 3 })
    end,
})

warpSec:Button({
    Name = "วาร์ปไปหาไอเทมบนพื้นที่ใกล้ที่สุด (NEAREST LOOT)",
    Desc = "ค้นหากองไอเทมที่ใกล้ตัวที่สุดและวาร์ปไปอยู่บนกองไอเทมทันที",
    Callback = function()
        local lootFolder = workspace:FindFirstChild("BloxZWorldLoot")
        local myHrp = getRootPart()
        if lootFolder and myHrp then
            local nearestDrop = nil
            local minDistance = math.huge
            for _, d in ipairs(lootFolder:GetChildren()) do
                local dPos = d:GetPivot().Position
                local dist = (dPos - myHrp.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestDrop = d
                end
            end
            if nearestDrop then
                teleportTo(CFrame.new(nearestDrop:GetPivot().Position + Vector3.new(0, 3, 0)))
                UI:Notify({ Title = "TELEPORT", Text = "วาร์ปไปหากองไอเทมสำเร็จ", Duration = 2.5 })
            else
                UI:Notify({ Title = "TELEPORT", Text = "ไม่พบไอเทมตกบนพื้น", Duration = 2.5 })
            end
        end
    end,
})

local playerWarpSec = teleportTab:Section("PLAYER TELEPORT")

local playerDropdownList = { "Select Player..." }
local selectedTargetPlayer = nil

local playerDropdownApi = playerWarpSec:Dropdown({
    Name = "เลือกผู้เล่นเป้าหมาย (TARGET PLAYER)",
    Options = playerDropdownList,
    Default = playerDropdownList[1],
    Callback = function(choice)
        selectedTargetPlayer = choice
    end,
})

playerWarpSec:Button({
    Name = "รีเฟรชรายชื่อผู้เล่น (REFRESH PLAYERS)",
    Desc = "อัปเดตรายชื่อผู้เล่นที่อยู่ในเซิร์ฟเวอร์ลงในช่องเลือก",
    Callback = function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                table.insert(list, p.Name)
            end
        end
        if #list == 0 then table.insert(list, "No other players") end
        playerDropdownApi:SetOptions(list)
        UI:Notify({ Title = "PLAYER LIST", Text = "อัปเดตรายชื่อผู้เล่น " .. #list .. " คน", Duration = 2 })
    end,
})

playerWarpSec:Button({
    Name = "วาร์ปไปหาผู้เล่นที่เลือก (WARP TO PLAYER)",
    Callback = function()
        if not selectedTargetPlayer or selectedTargetPlayer == "Select Player..." then
            UI:Notify({ Title = "TELEPORT", Text = "กรุณาเลือกผู้เล่นก่อน", Duration = 2.5 })
            return
        end
        local targetP = Players:FindFirstChild(selectedTargetPlayer)
        local targetChar = targetP and targetP.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            teleportTo(CFrame.new(targetHrp.Position + Vector3.new(0, 3, 0)))
            UI:Notify({ Title = "TELEPORT", Text = "วาร์ปไปหา " .. selectedTargetPlayer .. " สำเร็จ", Duration = 3 })
        else
            UI:Notify({ Title = "TELEPORT", Text = "ไม่พบตัวละครของผู้เล่นเป้าหมาย", Duration = 2.5 })
        end
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: SETTINGS
-- ------------------------------------------------------------------------------
local setSec = settingsTab:Section("THEME & INTERFACE")

setSec:Dropdown({
    Name = "ธีมสีอินเทอร์เฟซ (UI THEME)",
    Options = { "Ice", "Aurora", "Ember", "Mono" },
    Default = UI.CurrentThemeName,
    Callback = function(themeName)
        UI:SetAccent(themeName)
    end,
})

setSec:Slider({
    Name = "ความเบลอกระจก (FROST BLUR)",
    Min = 0,
    Max = 18,
    Step = 1,
    Default = UI.Frost,
    Suffix = " px",
    Callback = function(val)
        UI.Frost = val
        if UI.Visible then
            blurEffect.Size = val
        end
        saveSettings()
    end,
})

setSec:Slider({
    Name = "ความโปร่งใสกระจก (TINT ALPHA)",
    Min = 0.05,
    Max = 0.50,
    Step = 0.02,
    Default = UI.TintAlpha,
    Callback = function(val)
        UI.TintAlpha = val
        for _, surf in ipairs(allSurfaces) do
            surf.BackgroundTransparency = val
        end
        saveSettings()
    end,
})

setSec:Toggle({
    Name = "เอฟเฟกต์ 3D มิติแสง (PARALLAX 3D)",
    Desc = "เปิด/ปิดมิติการเอียงตามตำแหน่งเมาส์และแรงเฉื่อยการเคลื่อนไหว",
    Default = UI.Parallax,
    Callback = function(val)
        UI.Parallax = val
        saveSettings()
    end,
})

setSec:Keybind({
    Name = "ปุ่มคีย์ลัดเปิด/ปิดเมนู (TOGGLE KEY)",
    Default = UI.ToggleKey,
    Changed = function(newKey)
        UI.ToggleKey = newKey
        saveSettings()
    end,
})

local antiSec = settingsTab:Section("SECURITY & BYPASS STATUS")

antiSec:Label("GuiSync Hook: ACTIVE (Heartbeat Pass, Reports Blocked)")
antiSec:Label("WarZCheatTrap: NEUTRALIZED (Overlay/Blur Suppressed)")
antiSec:Label("Anti-Kick Metamethod: ACTIVE")
antiSec:Label("Anti-AFK VirtualUser: CONNECTED")

antiSec:Button({
    Name = "ปิดสคริปต์และล้างความจำ (UNLOAD SCRIPT)",
    Desc = "ตัดการทำงานของลูปทั้งหมดและล้าง UI ออกจากหน้าจออย่างปลอดภัย",
    Callback = function()
        UI:Destroy()
    end,
})

-- Welcome Notification
task.delay(0.6, function()
    UI:Notify({
        Title = "2K PRISM LOADED",
        Text = "RobloxZ - 1000z Master Hub ทำงานสมบูรณ์! พร้อมระบบ Bypass Anti-Cheat",
        Duration = 4,
    })
end)

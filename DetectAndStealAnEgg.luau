local UI, mainMaid, CONFIG, Themes, makeSequence, accentListeners, blurEffect, allSurfaces, currentTheme, currentColorSequence = (function()
-- ==============================================================================
-- 2K PRISM // Shattered Prism Glass UI System for Roblox (Luau)
-- ==============================================================================

local genv = (getgenv and getgenv()) or _G
if genv.__TwoKPrism then
    pcall(function()
        genv.__TwoKPrism:Destroy()
    end)
    genv.__TwoKPrism = nil
end

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local guiInset = game:GetService("GuiService"):GetGuiInset()

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")

pcall(function()
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name == "TwoKPrism" and child:IsA("ScreenGui") then
            child:Destroy()
        end
    end
end)

if PlayerGui then
    pcall(function()
        for _, child in ipairs(PlayerGui:GetChildren()) do
            if child.Name == "TwoKPrism" and child:IsA("ScreenGui") then
                child:Destroy()
            end
        end
    end)
end

pcall(function()
    local oldBlur = Lighting:FindFirstChild("TwoKPrismFrost")
    if oldBlur then
        oldBlur:Destroy()
    end
end)

-- ------------------------------------------------------------------------------
-- Maid Utility
-- ------------------------------------------------------------------------------
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
            pcall(function()
                taskItem:Destroy()
            end)
        end
    end
end

function Maid:Destroy()
    self:DoCleaning()
end

local mainMaid = Maid.new()

-- ------------------------------------------------------------------------------
-- Parent Selection & ScreenGui Initialization
-- ------------------------------------------------------------------------------
local targetParent = nil
local canCoreGui = pcall(function()
    local testProbe = Instance.new("Folder")
    testProbe.Parent = CoreGui
    testProbe:Destroy()
    targetParent = CoreGui
end)

if not canCoreGui or not targetParent then
    targetParent = PlayerGui
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TwoKPrism"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999
screenGui.Parent = targetParent
mainMaid:GiveTask(screenGui)

local camera = workspace.CurrentCamera

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "TwoKPrismFrost"
blurEffect.Size = 0
blurEffect.Parent = Lighting
mainMaid:GiveTask(blurEffect)

-- ------------------------------------------------------------------------------
-- Themes and Palette Configuration
-- ------------------------------------------------------------------------------
local SAVE_FOLDER = "2KPrism"
local SAVE_PATH = SAVE_FOLDER .. "/settings.json"

local saved = {}
pcall(function()
    if isfile and isfile(SAVE_PATH) then
        saved = HttpService:JSONDecode(readfile(SAVE_PATH))
    end
end)

local CONFIG = {
    Title = "DETECT & STEAL AN EGG",
    Sub = "2K PRISM GLASS HUB",
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
    ToggleKey = (type(saved.ToggleKey) == "string" and Enum.KeyCode:FromName(saved.ToggleKey)) or CONFIG.ToggleKey,
    CurrentThemeName = Themes[saved.Theme] and saved.Theme or CONFIG.Theme,
}

local currentTheme = Themes[UI.CurrentThemeName]

local saveQueued = false
local containerPos = Vector2.new(tonumber(saved.PosX) or 0, tonumber(saved.PosY) or 0)
local orbPos = Vector2.new(tonumber(saved.OrbX) or 74, tonumber(saved.OrbY) or 190)
local userScaleMultiplier = tonumber(saved.Scale) or 1.0

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
                Scale = userScaleMultiplier,
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
            warn("[2K PRISM Error]: " .. tostring(result))
        end
    end)
end

-- ------------------------------------------------------------------------------
-- Glass Slab Generator
-- ------------------------------------------------------------------------------
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
    surface.Active = true -- sinks clicks so they never reach the game behind the glass
    surface.Parent = root

    local surfaceCorner = Instance.new("UICorner")
    surfaceCorner.CornerRadius = UDim.new(0, radius)
    surfaceCorner.Parent = surface

    local noise = Instance.new("ImageLabel")
    noise.Name = "Noise"
    noise.Size = UDim2.new(1, 0, 1, 0)
    noise.Position = UDim2.new(0, 0, 0, 0)
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
    sheen.Position = UDim2.new(0, 0, 0, 0)
    sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sheen.BackgroundTransparency = 0
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
    specular.Position = UDim2.new(0, 0, 0, 0)
    specular.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    specular.BackgroundTransparency = 0
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
    rim.Position = UDim2.new(0, 0, 0, 0)
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
    content.Position = UDim2.new(0, 0, 0, 0)
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

-- ------------------------------------------------------------------------------
-- UI Layout Construction
-- ------------------------------------------------------------------------------
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

local clampContainer = nil -- Forward declaration

local function updateViewportScaling()
    local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if vp.X <= 0 or vp.Y <= 0 then return end

    local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    -- On touch / mobile screens: avoid covering full screen!
    -- Target max coverage: 65% width and 60% height on touch mobile (85% on desktop)
    local targetRatioW = isTouch and 0.65 or 0.85
    local targetRatioH = isTouch and 0.60 or 0.84

    local maxFitW = (vp.X * targetRatioW) / 680
    local maxFitH = (vp.Y * targetRatioH) / 440
    local baseFit = math.min(maxFitW, maxFitH)

    local minScale = isTouch and 0.35 or 0.50
    local maxScale = isTouch and 0.70 or 1.15
    local baseScale = math.clamp(baseFit, minScale, maxScale)

    local finalScale = math.clamp(baseScale * userScaleMultiplier, 0.35, 1.45)
    containerScale.Scale = finalScale

    if clampContainer then
        containerPos = clampContainer(containerPos)
        container.Position = UDim2.new(0.5, containerPos.X, 0.5, containerPos.Y)
    end
end

function UI:SetScale(multiplier)
    userScaleMultiplier = math.clamp(multiplier, 0.40, 1.60)
    updateViewportScaling()
    saveSettings()
end

function UI:GetScale()
    return containerScale.Scale, userScaleMultiplier
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
    Size = UDim2.fromOffset(112, 370),
    Position = UDim2.fromOffset(0, 70),
    Radius = 10,
    Depth = 4,
    Lag = 0.22,
})

local mainSlab = makeGlass(container, {
    Size = UDim2.fromOffset(560, 330),
    Position = UDim2.fromOffset(120, 70),
    Radius = 10,
    Depth = 3,
    Lag = 0.27,
})

local statusSlab = makeGlass(container, {
    Size = UDim2.fromOffset(560, 32),
    Position = UDim2.fromOffset(120, 408),
    Radius = 8,
    Depth = 3,
    Lag = 0.17,
})

-- ------------------------------------------------------------------------------
-- Geometry Helpers
-- ------------------------------------------------------------------------------
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

-- ------------------------------------------------------------------------------
-- TOP Slab Elements & Drag Mechanism
-- ------------------------------------------------------------------------------
makePrismMark(topSlab.Content, UDim2.fromOffset(26, 26), UDim2.fromOffset(16, 18))

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.AnchorPoint = Vector2.new(0, 0.5)
titleLabel.Size = UDim2.fromOffset(240, 26)
titleLabel.Position = UDim2.new(0, 50, 0.5, 0)
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

makeTopButton("−", 1, function()
    userScaleMultiplier = math.clamp(userScaleMultiplier - 0.10, 0.40, 1.50)
    updateViewportScaling()
    saveSettings()
    UI:SetStatus("ปรับขนาดหน้าต่าง: " .. math.round(userScaleMultiplier * 100) .. "%")
end)

makeTopButton("+", 2, function()
    userScaleMultiplier = math.clamp(userScaleMultiplier + 0.10, 0.40, 1.50)
    updateViewportScaling()
    saveSettings()
    UI:SetStatus("ปรับขนาดหน้าต่าง: " .. math.round(userScaleMultiplier * 100) .. "%")
end)

makeTopButton("▾", 3, function()
    UI:Toggle(false)
end)

makeTopButton("✕", 4, function()
    UI:Destroy()
end)

-- Container Drag Logic via TOP slab
clampContainer = function(wanted)
    local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local s = containerScale.Scale
    local halfW, halfH = 340 * s, 220 * s
    local maxX = math.max(10, (vp.X / 2) - halfW - 10)
    local maxY = math.max(10, (vp.Y / 2) - halfH - 10)
    return Vector2.new(
        math.clamp(wanted.X, -maxX, maxX),
        math.clamp(wanted.Y, -maxY, maxY)
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

-- ------------------------------------------------------------------------------
-- Interactive Corner Resize Grip Handle & Touch Pinch
-- ------------------------------------------------------------------------------
local resizeGrip = Instance.new("Frame")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.fromOffset(32, 32)
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.Position = UDim2.new(1, 0, 1, 0)
resizeGrip.BackgroundTransparency = 1
resizeGrip.ZIndex = 80
resizeGrip.Parent = container

local gripLabel = Instance.new("TextLabel")
gripLabel.Name = "GripIcon"
gripLabel.Size = UDim2.new(1, 0, 1, 0)
gripLabel.BackgroundTransparency = 1
gripLabel.Text = "◢"
gripLabel.TextColor3 = Color3.fromRGB(180, 200, 230)
gripLabel.TextTransparency = 0.50
gripLabel.Font = Enum.Font.GothamBold
gripLabel.TextSize = 18
gripLabel.TextXAlignment = Enum.TextXAlignment.Right
gripLabel.TextYAlignment = Enum.TextYAlignment.Bottom
gripLabel.ZIndex = 81
gripLabel.Parent = resizeGrip

local isResizing = false
local resizeStartPos = Vector2.zero
local resizeStartMultiplier = 1.0

resizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        resizeStartPos = Vector2.new(input.Position.X, input.Position.Y)
        resizeStartMultiplier = userScaleMultiplier
        gripLabel.TextColor3 = currentTheme.C2
        gripLabel.TextTransparency = 0.10
    end
end)

mainMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local curPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = curPos - resizeStartPos
        local scaleDelta = (delta.X + delta.Y) / 450
        userScaleMultiplier = math.clamp(resizeStartMultiplier + scaleDelta, 0.40, 1.50)
        updateViewportScaling()
    end
end))

mainMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isResizing = false
        gripLabel.TextColor3 = Color3.fromRGB(180, 200, 230)
        gripLabel.TextTransparency = 0.50
        saveSettings()
        UI:SetStatus("ปรับขนาดหน้าต่าง: " .. math.round(userScaleMultiplier * 100) .. "%")
    end
end))

-- Mobile Two-Finger Pinch to Zoom
mainMaid:GiveTask(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
    if not UI.Visible then return end
    if state == Enum.UserInputState.Change then
        local delta = (scale - 1) * 0.05
        userScaleMultiplier = math.clamp(userScaleMultiplier + delta, 0.40, 1.50)
        updateViewportScaling()
    elseif state == Enum.UserInputState.End then
        saveSettings()
        UI:SetStatus("ปรับขนาดหน้าต่าง: " .. math.round(userScaleMultiplier * 100) .. "%")
    end
end))

-- ------------------------------------------------------------------------------
-- DOCK Slab & Lens Mechanism
-- ------------------------------------------------------------------------------
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
dockPlayer.TextSize = 12
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

local tabButtonsList = {}
local registeredTabs = {}
local activeTab = nil

-- ------------------------------------------------------------------------------
-- STATUS Slab Elements
-- ------------------------------------------------------------------------------
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusText"
statusLabel.Size = UDim2.new(0.65, 0, 1, 0)
statusLabel.Position = UDim2.fromOffset(14, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "IDLE"
statusLabel.TextSize = 12
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.TextColor3 = Color3.fromRGB(186, 198, 220)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusSlab.Content

function UI:SetStatus(message)
    pcall(function()
        if setthreadidentity then setthreadidentity(8)
        elseif setidentity then setidentity(8)
        elseif set_thread_identity then set_thread_identity(8)
        end
        statusLabel.Text = tostring(message)
    end)
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

-- "Idle", "Running" or "Error". Toggles drive Idle/Running; Error sticks until cleared.
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

-- ------------------------------------------------------------------------------
-- Floating 2K Button (always on screen, opens and closes the menu)
-- ------------------------------------------------------------------------------
local crackBurst -- assigned below, the button fires it on press

local ORB_SIZE = 60

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
    local vp = camera.ViewportSize
    orbPos = Vector2.new(math.clamp(wanted.X, 34, vp.X - 34), math.clamp(wanted.Y, 34, vp.Y - 34))
    orb.Position = UDim2.fromOffset(orbPos.X, orbPos.Y)
end
placeOrb(orbPos)

local orbCorner = Instance.new("UICorner")
orbCorner.CornerRadius = UDim.new(1, 0)
orbCorner.Parent = orb

local orbScale = Instance.new("UIScale")
orbScale.Parent = orb

-- Shockwave rings
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
    orbRings[1].Stroke.Color = theme.C1
    orbRings[2].Stroke.Color = theme.C3
end)

local orbNoise = Instance.new("ImageLabel")
orbNoise.Name = "OrbNoise"
orbNoise.Size = UDim2.new(1, 0, 1, 0)
orbNoise.BackgroundTransparency = 1
orbNoise.Image = "rbxassetid://9968344227"
orbNoise.ScaleType = Enum.ScaleType.Tile
orbNoise.TileSize = UDim2.fromOffset(64, 64)
orbNoise.ImageTransparency = 0.90
orbNoise.Parent = orb

local orbNoiseCorner = Instance.new("UICorner")
orbNoiseCorner.CornerRadius = UDim.new(1, 0)
orbNoiseCorner.Parent = orbNoise

-- Diagonal shine that crosses the glass
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

-- "2K": two colour-split copies behind a metallic face
local function makeOrbText(name, transparency)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Michroma
    label.Text = "2K"
    label.TextSize = 20
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

-- Spark circling the rim
local orbOrbit = Instance.new("Frame")
orbOrbit.Name = "Orbit"
orbOrbit.Size = UDim2.new(1, 0, 1, 0)
orbOrbit.BackgroundTransparency = 1
orbOrbit.Parent = orb

local orbSpark = Instance.new("Frame")
orbSpark.Name = "Spark"
orbSpark.AnchorPoint = Vector2.new(0.5, 0.5)
orbSpark.Position = UDim2.new(0.5, 0, 0, 0)
orbSpark.Size = UDim2.fromOffset(7, 7)
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
        local size = ORB_SIZE + 34 * phase
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

-- ------------------------------------------------------------------------------
-- Glass Crack Burst
-- ------------------------------------------------------------------------------
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
                fade.Completed:Connect(function()
                    seg:Destroy()
                end)
                fade:Play()
            end)

            pos = nextPos
        end
    end
end

-- ------------------------------------------------------------------------------
-- Toast Notification System
-- ------------------------------------------------------------------------------
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
    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) elseif set_thread_identity then set_thread_identity(8) end
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

-- ------------------------------------------------------------------------------
-- Tab Switching & Row Entry Transition
-- ------------------------------------------------------------------------------
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
                TweenService:Create(row.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                }):Play()
            end
            if row.Desc then
                TweenService:Create(row.Desc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                }):Play()
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

-- ------------------------------------------------------------------------------
-- Widget Builder Implementation
-- ------------------------------------------------------------------------------
local function createRowBase(parent, hasDesc, customHeight)
    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) elseif set_thread_identity then set_thread_identity(8) end
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
    title.TextSize = 14
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
        desc.TextSize = 12
        desc.TextColor3 = Color3.fromRGB(186, 198, 220)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = inner
    else
        title.Size = UDim2.new(0.65, 0, 1, 0)
        title.Position = UDim2.fromOffset(12, 0)
    end

    return title, desc
end

-- ------------------------------------------------------------------------------
-- Tab / Section Construction
-- ------------------------------------------------------------------------------
function UI:Tab(tabTitle)
    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) elseif set_thread_identity then set_thread_identity(8) end
    tabTitle = string.upper(tabTitle or "TAB")
    local tabIndex = #registeredTabs + 1

    local tabButton = Instance.new("TextButton")
    tabButton.Name = "TabBtn_" .. tabTitle
    tabButton.Size = UDim2.new(1, -16, 0, 30)
    tabButton.Position = UDim2.fromOffset(8, 14 + (tabIndex - 1) * 36)
    tabButton.BackgroundTransparency = 1
    tabButton.Font = Enum.Font.Michroma
    tabButton.Text = tabTitle
    tabButton.TextSize = 12
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
        if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) elseif set_thread_identity then set_thread_identity(8) end
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

        -- Widget: Toggle
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
                TweenService:Create(capFill, TweenInfo.new(0.20), {
                    BackgroundTransparency = isOn and 0 or 1
                }):Play()

                TweenService:Create(bead, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(24, 16)
                }):Play()

                local targetPos = isOn and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                TweenService:Create(bead, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = targetPos
                }):Play()

                task.delay(0.10, function()
                    TweenService:Create(bead, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(16, 16)
                    }):Play()
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

            function toggleApi:Get()
                return state
            end

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

        -- Widget: Slider
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

            function sliderApi:Get()
                return currentVal
            end

            return sliderApi
        end

        -- Widget: Button
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
                task.delay(0.08, function()
                    inner.Position = UDim2.fromOffset(0, 0)
                end)

                sweepGrad.Offset = Vector2.new(-1, 0)
                local sweepTween = TweenService:Create(sweepGrad, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(1, 0)
                })
                sweepTween:Play()
                sweepTween.Completed:Connect(function()
                    sweepGrad.Offset = Vector2.new(-1, 0)
                end)

                safeSpawn(opts.Callback)
            end)
        end

        -- Widget: Dropdown (Supports Single & Multi-Select)
        function SecApi:Dropdown(opts)
            opts = opts or {}
            local isMulti = opts.Multi == true or opts.MultiSelect == true
            local optionsList = opts.Options or {}
            local selectedVal = opts.Default
            local isOpen = false
            local baseHeight = 40

            local selectedMap = {}
            if isMulti then
                if type(selectedVal) == "table" then
                    for k, v in pairs(selectedVal) do
                        if type(k) == "number" then
                            selectedMap[v] = true
                        elseif v == true then
                            selectedMap[k] = true
                        end
                    end
                elseif selectedVal ~= nil then
                    selectedMap[selectedVal] = true
                end
            else
                selectedVal = selectedVal or optionsList[1] or ""
            end

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

            local function getDisplaySummary()
                if isMulti then
                    local count = 0
                    local firstPicked = nil
                    for _, opt in ipairs(optionsList) do
                        if selectedMap[opt] then
                            count = count + 1
                            if not firstPicked then
                                local shortName = opt:match("^%d+%.%s*(.-)%s*%(") or opt:match("^%d+%.%s*(.+)") or opt
                                firstPicked = shortName
                            end
                        end
                    end
                    if count == 0 then
                        return "None"
                    elseif count == 1 then
                        return firstPicked or "1 Selected"
                    elseif count == #optionsList and #optionsList > 1 then
                        return "All (" .. count .. ")"
                    else
                        return count .. " Selected"
                    end
                else
                    return tostring(selectedVal)
                end
            end

            local selectedLabel = Instance.new("TextLabel")
            selectedLabel.Name = "SelectedLabel"
            selectedLabel.Size = UDim2.new(1, -22, 1, 0)
            selectedLabel.BackgroundTransparency = 1
            selectedLabel.Font = Enum.Font.GothamMedium
            selectedLabel.Text = getDisplaySummary()
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

            local function updateOptionButtonVisual(optBtn, optName)
                if isMulti then
                    local isSel = selectedMap[optName] == true
                    optBtn.Text = (isSel and "  [✓]  " or "  [  ]  ") .. tostring(optName)
                    optBtn.TextColor3 = isSel and Color3.fromRGB(120, 235, 120) or Color3.fromRGB(186, 198, 220)
                    optBtn.BackgroundTransparency = isSel and 0.88 or 0.97
                    optBtn.BackgroundColor3 = isSel and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(255, 255, 255)
                else
                    optBtn.Text = "   " .. tostring(optName)
                    optBtn.TextColor3 = (optName == selectedVal) and Color3.fromRGB(236, 243, 255) or Color3.fromRGB(186, 198, 220)
                    optBtn.BackgroundTransparency = (optName == selectedVal) and 0.90 or 0.97
                    optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end
            end

            local function rebuildOptionButtons()
                for _, child in ipairs(optionsHolder:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for idx, optName in ipairs(optionsList) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = "Opt_" .. tostring(optName)
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.Font = Enum.Font.GothamMedium
                    optBtn.TextSize = 12
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left
                    optBtn.AutoButtonColor = false
                    optBtn.LayoutOrder = idx
                    optBtn.Parent = optionsHolder

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optBtn

                    updateOptionButtonVisual(optBtn, optName)

                    optBtn.MouseEnter:Connect(function()
                        local isSel = isMulti and (selectedMap[optName] == true)
                        TweenService:Create(optBtn, TweenInfo.new(0.15), {
                            BackgroundTransparency = isSel and 0.80 or 0.90
                        }):Play()
                    end)

                    optBtn.MouseLeave:Connect(function()
                        local isSel = isMulti and (selectedMap[optName] == true)
                        TweenService:Create(optBtn, TweenInfo.new(0.15), {
                            BackgroundTransparency = isSel and 0.88 or 0.97
                        }):Play()
                    end)

                    optBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            selectedMap[optName] = not selectedMap[optName]
                            updateOptionButtonVisual(optBtn, optName)
                            selectedLabel.Text = getDisplaySummary()
                            safeSpawn(opts.Callback, selectedMap, optName)
                        else
                            dropdownApi:Set(optName)
                            toggleDropdown(false)
                        end
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
                if isMulti then
                    if type(val) == "table" then
                        selectedMap = {}
                        for k, v in pairs(val) do
                            if type(k) == "number" then
                                selectedMap[v] = true
                            elseif v == true then
                                selectedMap[k] = true
                            end
                        end
                    end
                    selectedLabel.Text = getDisplaySummary()
                    for _, child in ipairs(optionsHolder:GetChildren()) do
                        if child:IsA("TextButton") then
                            local name = child.Name:sub(5)
                            updateOptionButtonVisual(child, name)
                        end
                    end
                    if not suppressCallback then
                        safeSpawn(opts.Callback, selectedMap)
                    end
                else
                    selectedVal = val
                    selectedLabel.Text = tostring(val)
                    rebuildOptionButtons()
                    if not suppressCallback then
                        safeSpawn(opts.Callback, selectedVal)
                    end
                end
            end

            function dropdownApi:Get()
                return isMulti and selectedMap or selectedVal
            end

            function dropdownApi:SetOptions(newOpts)
                optionsList = newOpts or {}
                if not isMulti then
                    if not table.find(optionsList, selectedVal) then
                        selectedVal = optionsList[1] or ""
                        selectedLabel.Text = tostring(selectedVal)
                    end
                else
                    selectedLabel.Text = getDisplaySummary()
                end
                optionsHolder.Size = UDim2.new(1, -16, 0, #optionsList * 30)
                rebuildOptionButtons()
                if isOpen then
                    toggleDropdown(true)
                end
            end

            return dropdownApi
        end

        -- Widget: Keybind
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
                        task.defer(function()
                            isKeybindListeningGlobal = false
                        end)
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

            function keybindApi:Get()
                return boundKey
            end

            return keybindApi
        end

        -- Widget: Input (TextBox)
        function SecApi:Input(opts)
            opts = opts or {}
            local currentVal = tostring(opts.Default or "")
            local placeholder = opts.Placeholder or "พิมพ์ที่นี่..."
            local hasDesc = (opts.Desc and opts.Desc ~= "")
            local row, inner, stroke = createRowBase(pageFrame, hasDesc)
            local titleObj, descObj = attachLabels(inner, opts.Name, opts.Desc)
            if not hasDesc then
                titleObj.Size = UDim2.new(0.50, 0, 1, 0)
            end
            registerRow(inner, stroke, titleObj, descObj)

            local boxFrame = Instance.new("Frame")
            boxFrame.Name = "InputBoxFrame"
            boxFrame.Size = UDim2.new(0, 160, 0, 26)
            boxFrame.AnchorPoint = Vector2.new(1, 0.5)
            boxFrame.Position = UDim2.new(1, -12, 0.5, 0)
            boxFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
            boxFrame.BackgroundTransparency = 0.40
            boxFrame.Parent = inner

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 6)
            boxCorner.Parent = boxFrame

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Thickness = 1
            boxStroke.Color = Color3.fromRGB(255, 255, 255)
            boxStroke.Transparency = 0.85
            boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            boxStroke.Parent = boxFrame

            local textBox = Instance.new("TextBox")
            textBox.Name = "TextBox"
            textBox.Size = UDim2.new(1, -16, 1, 0)
            textBox.Position = UDim2.fromOffset(8, 0)
            textBox.BackgroundTransparency = 1
            textBox.Font = Enum.Font.GothamMedium
            textBox.Text = currentVal
            textBox.PlaceholderText = placeholder
            textBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 160)
            textBox.TextColor3 = Color3.fromRGB(240, 246, 255)
            textBox.TextSize = 12
            textBox.TextXAlignment = Enum.TextXAlignment.Left
            textBox.ClearTextOnFocus = false
            textBox.Parent = boxFrame

            textBox.Focused:Connect(function()
                TweenService:Create(boxStroke, TweenInfo.new(0.2), { Transparency = 0.3 }):Play()
            end)

            textBox.FocusLost:Connect(function(enterPressed)
                TweenService:Create(boxStroke, TweenInfo.new(0.2), { Transparency = 0.85 }):Play()
                currentVal = textBox.Text
                if opts.Callback then
                    safeSpawn(opts.Callback, currentVal, enterPressed)
                end
            end)

            local inputApi = {}
            function inputApi:Set(val)
                currentVal = tostring(val or "")
                textBox.Text = currentVal
            end
            function inputApi:Get()
                return textBox.Text
            end
            return inputApi
        end

        -- Widget: Label
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

-- ------------------------------------------------------------------------------
-- Open / Close Transition & Splinter Physics
-- ------------------------------------------------------------------------------
local isAnimatingTransition = false

function UI:Toggle(targetState)
    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) elseif set_thread_identity then set_thread_identity(8) end
    if isAnimatingTransition then return end
    if targetState == nil then
        targetState = not UI.Visible
    end
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
            for _, layer in ipairs(slab.Layers) do
                layer.Visible = true
            end
            slab.Content.Visible = false
            slab.RimStroke.Transparency = 0
            slab.InnerStroke.Transparency = 0.93
            for _, fStroke in ipairs(slab.FringeStrokes) do
                fStroke.Transparency = 0.72
            end
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
                    sweep.Completed:Connect(function()
                        slab.Sweeping = false
                    end)
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

            spinTween.Completed:Connect(function()
                splinter:Destroy()
            end)
        end

        local fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, slab in ipairs(allSlabs) do
            slab.Locked = true
            slab.Content.Visible = false
            for _, layer in ipairs(slab.Layers) do
                layer.Visible = false
            end
            TweenService:Create(slab.Surface, fade, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(slab.RimStroke, fade, { Transparency = 1 }):Play()
            TweenService:Create(slab.InnerStroke, fade, { Transparency = 1 }):Play()
            for _, fStroke in ipairs(slab.FringeStrokes) do
                TweenService:Create(fStroke, fade, { Transparency = 1 }):Play()
            end
        end

        TweenService:Create(blurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = 0
        }):Play()

        task.delay(0.26, function()
            container.Visible = false
            UI.Visible = false
            isAnimatingTransition = false
        end)
    end
end

-- ------------------------------------------------------------------------------
-- Toggle Key Listener
-- ------------------------------------------------------------------------------
mainMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or isKeybindListeningGlobal then return end
    if input.KeyCode == UI.ToggleKey then
        UI:Toggle()
    end
end))

-- ------------------------------------------------------------------------------
-- Per-Frame Update (RenderStepped)
-- ------------------------------------------------------------------------------
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

-- ------------------------------------------------------------------------------
-- Teardown API
-- ------------------------------------------------------------------------------
function UI:Destroy()
    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) elseif set_thread_identity then set_thread_identity(8) end
    mainMaid:Destroy()
    genv.__TwoKPrism = nil
end

genv.__TwoKPrism = UI

container.Visible = false
return UI, mainMaid, CONFIG, Themes, makeSequence, accentListeners, blurEffect, allSurfaces, currentTheme, currentColorSequence
end)()


-- ==============================================================================
-- 2K PRISM // DETECT AND STEAL AN EGG - VERIFIED FULL AUTOMATION ENGINE
-- Universe: 10769407594 // Place: 135069647210029
-- Anti-Cheat Safe (Zero 267 Kicks) // Full Auto Dig, Steal, Hatch & Treadmill
-- Discord: https://discord.gg/4Yg72kYT6s
-- Authors: cook45 & clack // 2K Scripts
-- ==============================================================================

local function elevate()
    if setthreadidentity then setthreadidentity(8)
    elseif setidentity then setidentity(8)
    elseif set_thread_identity then set_thread_identity(8)
    end
end

elevate()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Script Instance Guard (Kills old zombie loops on re-execute)
local RUN_ID = HttpService:GenerateGUID(false)
if _G.__2K_DETECTEGG_CLEANUP then
    pcall(_G.__2K_DETECTEGG_CLEANUP)
end
_G.__2K_DETECTEGG_RUN_ID = RUN_ID
local function isScriptAlive()
    return _G.__2K_DETECTEGG_RUN_ID == RUN_ID
end

_G.__2K_DETECTEGG_CLEANUP = function()
    _G.__2K_DETECTEGG_RUN_ID = nil
    pcall(function()
        if mainMaid then mainMaid:Destroy() end
    end)
end

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScanStart = Remotes:WaitForChild("ScanStart")
local ScanStop = Remotes:WaitForChild("ScanStop")
local DigRemote = Remotes:WaitForChild("Dig")
local DropRemote = Remotes:WaitForChild("Drop")
local SetSlowModeRemote = Remotes:FindFirstChild("SetSlowMode")
local LeaveTreadmill = Remotes:WaitForChild("LeaveTreadmill")
local SwingRemote = Remotes:WaitForChild("Swing")
local PlaceEggRemote = Remotes:WaitForChild("PlaceEgg")
local PlacePetRemote = Remotes:WaitForChild("PlacePet")
local HoldItemRemote = Remotes:WaitForChild("HoldItem")
local HatchEggRemote = Remotes:WaitForChild("HatchEgg")
local HatchAllRemote = Remotes:WaitForChild("HatchAll")
local EquipPetRemote = Remotes:WaitForChild("EquipPet")
local EquipBestRemote = Remotes:WaitForChild("EquipBest")
local SellItemsRemote = Remotes:WaitForChild("SellItems")
local UpgradePenRemote = Remotes:WaitForChild("UpgradePen")
local UpgradeStorageRemote = Remotes:WaitForChild("UpgradeStorage")
local UpgradeTreadmillRemote = Remotes:WaitForChild("UpgradeTreadmill")
local ShopBuyRemote = Remotes:WaitForChild("ShopBuy")
local ShopEquipRemote = Remotes:WaitForChild("ShopEquip")
local FreeRewardClaimRemote = Remotes:WaitForChild("FreeRewardClaim")
local CommunityClaimRemote = Remotes:WaitForChild("CommunityClaim")
local ClaimOfflineRemote = Remotes:WaitForChild("ClaimOffline")

-- Client Modules
local ClientControllers = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
local Store = require(LocalPlayer.PlayerScripts.Client.Store)
local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))
local DetectorController = nil
pcall(function()
    DetectorController = require(ClientControllers:WaitForChild("Detector"))
end)

-- ------------------------------------------------------------------------------
-- Persistent Settings (All OFF by default for clean start)
-- ------------------------------------------------------------------------------
local S = {
    -- FARM
    AutoTreadmill = false,
    AutoDig = false,
    FastDig = false,
    AutoStealReturn = true,
    AutoSwing = false,
    TargetStage = "Stage 1 (Beach Zone)",
    TravelSpeed = 100,
    AntiGuardian = false,

    -- PETS & EGGS
    AutoHatch = false,
    AutoEquipBest = false,
    AutoPlaceEggs = false,
    AutoSell = false,
    SellRarity = "Common & Uncommon",

    -- UPGRADES & SHOP
    AutoUpgradePen = false,
    AutoUpgradeTreadmill = false,
    AutoUpgradeStorage = false,
    AutoBuyShovel = false,
    AutoBuyDetector = false,
    AutoBuyTrail = false,
    AutoClaimRewards = false,

    -- ESP & VISUALS
    EggESP = false,
    GuardianESP = false,

    -- MOVEMENT
    WalkSpeedOn = false,
    WalkSpeed = 16,
    JumpPowerOn = false,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
}

local STAGE_DATA = {
    ["Stage 1 (Beach Zone)"] = { index = 1, minZ = 0, maxZ = 120, z = 60, name = "Beach Zone" },
    ["Stage 2 (Jungle)"] = { index = 2, minZ = 120, maxZ = 255, z = 187, name = "Jungle" },
    ["Stage 3 (Ice & Frost)"] = { index = 3, minZ = 255, maxZ = 420, z = 337, name = "Ice & Frost" },
    ["Stage 4 (Swamp)"] = { index = 4, minZ = 420, maxZ = 595, z = 507, name = "Swamp" },
    ["Stage 5 (Sea / Kraken)"] = { index = 5, minZ = 595, maxZ = 795, z = 695, name = "Sea / Kraken" },
    ["Stage 6 (Spike Wasteland)"] = { index = 6, minZ = 795, maxZ = 1035, z = 915, name = "Spike Wasteland" },
    ["Stage 7 (Volcano)"] = { index = 7, minZ = 1035, maxZ = 1355, z = 1195, name = "Volcano" },
    ["Stage 8 (Jade Forest)"] = { index = 8, minZ = 1355, maxZ = 1695, z = 1525, name = "Jade Forest" },
    ["Stage 9 (Astral Dragon)"] = { index = 9, minZ = 1695, maxZ = 2115, z = 1905, name = "Astral Dragon" },
    ["Stage 10 (Olympus Zeus)"] = { index = 10, minZ = 2115, maxZ = 2555, z = 2335, name = "Olympus Zeus" },
}

local STAGE_OPTIONS = {
    "Stage 1 (Beach Zone)",
    "Stage 2 (Jungle)",
    "Stage 3 (Ice & Frost)",
    "Stage 4 (Swamp)",
    "Stage 5 (Sea / Kraken)",
    "Stage 6 (Spike Wasteland)",
    "Stage 7 (Volcano)",
    "Stage 8 (Jade Forest)",
    "Stage 9 (Astral Dragon)",
    "Stage 10 (Olympus Zeus)",
}

local RARITY_SELL_OPTIONS = {
    "Common Only",
    "Common & Uncommon",
    "Rare and Below",
    "Epic and Below",
}

-- ------------------------------------------------------------------------------
-- Config Management (Save, Load, Overwrite, Delete, Refresh, Auto-load)
-- ------------------------------------------------------------------------------
local CONFIG_FOLDER = "2KSCRIPT/DetectAndStealAnEgg_Configs"
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/__autoload.txt"

local function ensureFolder()
    pcall(function()
        if makefolder then
            if not isfolder("2KSCRIPT") then makefolder("2KSCRIPT") end
            if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        end
    end)
end

local function saveConfigFile(name)
    ensureFolder()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(S)
    end)
    if not ok then return false, "JSON Encode failed" end
    local filePath = CONFIG_FOLDER .. "/" .. name .. ".json"
    local writeOk, err = pcall(function()
        writefile(filePath, encoded)
    end)
    if writeOk then return true, name else return false, err end
end

local function listConfigFiles()
    ensureFolder()
    local results = {}
    local ok = pcall(function()
        if listfiles then
            local files = listfiles(CONFIG_FOLDER)
            for _, f in ipairs(files) do
                if f:sub(-5) == ".json" and not f:find("__autoload") then
                    local base = f:match("([^/\\]+)%.json$")
                    if base then
                        table.insert(results, base)
                    end
                end
            end
        end
    end)
    return results
end

local function loadConfigData(name)
    local filePath = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not (isfile and isfile(filePath)) then return false, "File not found" end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(filePath))
    end)
    if not ok or type(decoded) ~= "table" then return false, "Decode error" end
    for k, v in pairs(decoded) do
        if S[k] ~= nil then
            S[k] = v
        end
    end
    return true, name
end

local function deleteConfigFile(name)
    local filePath = CONFIG_FOLDER .. "/" .. name .. ".json"
    if isfile and isfile(filePath) then
        pcall(delfile, filePath)
        return true, name
    end
    return false, "File not found"
end

local function getAutoloadConfig()
    ensureFolder()
    if isfile and isfile(AUTOLOAD_FILE) then
        local content = readfile(AUTOLOAD_FILE)
        if content and #content > 0 then
            return content:gsub("%s+", "")
        end
    end
    return nil
end

local function setAutoloadConfig(name)
    ensureFolder()
    pcall(function()
        if name and #name > 0 then
            writefile(AUTOLOAD_FILE, name)
        else
            if isfile and isfile(AUTOLOAD_FILE) then
                delfile(AUTOLOAD_FILE)
            end
        end
    end)
end

-- ------------------------------------------------------------------------------
-- Game Helpers & Detection Engine
-- ------------------------------------------------------------------------------
local function getMyPen()
    local penIndex = LocalPlayer:GetAttribute("PenIndex")
    local pens = workspace.Map:FindFirstChild("Pens")
    if penIndex and pens then
        local p = pens:FindFirstChild("Pen" .. tostring(penIndex))
        if p then return p end
    end
    if pens then
        for _, p in ipairs(pens:GetChildren()) do
            local owner = p:GetAttribute("Owner") or p:GetAttribute("UserId")
            if owner == LocalPlayer.UserId then
                return p
            end
        end
    end
    return pens and pens:FindFirstChild("Pen2") or (pens and pens:GetChildren()[1])
end

local function getMyPenSpawn()
    local pen = getMyPen()
    if pen then
        local spawnPart = pen:FindFirstChild("SpawnPoint")
        if spawnPart and spawnPart:IsA("BasePart") then
            return spawnPart.Position + Vector3.new(0, 3, 0)
        end
        return pen:GetPivot().Position + Vector3.new(0, 3, 0)
    end
    return Vector3.new(0, 3, -60)
end

local function getMyPenBoxCenter()
    local pen = getMyPen()
    if pen then
        local penLvl = tonumber(LocalPlayer:GetAttribute("PenLevel")) or 1
        local ok, _, v2, v3 = pcall(Formulas.penBox, penLvl)
        if ok and v2 and v3 then
            return (pen:GetPivot() * CFrame.new(0, 0, (v2 + v3) / 2)).Position
        end
        return pen:GetPivot().Position
    end
    return Vector3.new(0, 0, -110)
end

local function getMyTreadmillMount()
    local pen = getMyPen()
    if pen then
        local tm = pen:FindFirstChild("Treadmill")
        if tm then
            local mount = tm:FindFirstChild("Mount")
            if mount and mount:IsA("BasePart") then
                return mount.Position + Vector3.new(0, 1.2, 0)
            end
            local belt = tm:FindFirstChild("Belt")
            if belt and belt:IsA("BasePart") then
                return belt.Position + Vector3.new(0, 1.2, 0)
            end
        end
    end
    return nil
end

local function equipToolKind(kind)
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and currentTool:GetAttribute("Kind") == kind then
        return true
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local targetTool = nil
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("Kind") == kind then
                targetTool = t
                break
            end
        end
        if targetTool then
            hum:EquipTool(targetTool)
            return true
        end
    end
    return false
end

-- Safely leave treadmill without CFrame teleports (100% immune to Error 267)
local function exitTreadmillIfOn()
    if LocalPlayer:GetAttribute("OnTreadmill") == true then
        LeaveTreadmill:FireServer()
        local t0 = os.clock()
        while LocalPlayer:GetAttribute("OnTreadmill") == true and (os.clock() - t0) < 1.5 do
            task.wait(0.05)
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            -- Walk straight out in +Z away from the treadmill mount
            local escapePos = Vector3.new(hrp.Position.X - 7, hrp.Position.Y, -35)
            local t1 = os.clock()
            while (os.clock() - t1) < 0.8 and hrp.Position.Z < -45 do
                hum:MoveTo(escapePos)
                task.wait(0.1)
            end
        end
    end
end

-- Safe Movement Function (100% Server-Synced Speed & Smart Waypoint Routing / Zero Error 267)
local function safeMoveTowards(targetPos, _, arriveDistance)
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end

    arriveDistance = arriveDistance or 6

    -- Ensure SlowMode is disabled so the server grants full physical speed
    if LocalPlayer:GetAttribute("SlowMode") == true and SetSlowModeRemote then
        pcall(function()
            SetSlowModeRemote:FireServer(false)
        end)
    end

    local delta = targetPos - hrp.Position
    local dist2D = math.sqrt(delta.X * delta.X + delta.Z * delta.Z)
    if dist2D <= arriveDistance then
        return true
    end

    -- Smart routing to avoid Treadmill re-lock and Hub Boundary Walls (|X| > 78 at Z = 0)
    local nextWaypoint = targetPos
    if not S.AutoTreadmill and hrp.Position.Z < -45 and targetPos.Z > -40 then
        nextWaypoint = Vector3.new(hrp.Position.X - 7, hrp.Position.Y, -35)
    elseif hrp.Position.Z < -5 and targetPos.Z >= 0 and math.abs(hrp.Position.X) > 62 then
        nextWaypoint = Vector3.new(0, hrp.Position.Y, -15)
    elseif hrp.Position.Z > 0 and targetPos.Z < -15 and math.abs(targetPos.X) > 62 then
        nextWaypoint = Vector3.new(0, hrp.Position.Y, -15)
    end

    hum:MoveTo(Vector3.new(nextWaypoint.X, hrp.Position.Y, nextWaypoint.Z))
    return false
end

-- Active Buried Egg Markers Tracking
local activeDiscoveredEggs = {}

mainMaid:GiveTask(Remotes.Discovered.OnClientEvent:Connect(function(id, info)
    if type(id) == "string" and type(info) == "table" and info.position then
        activeDiscoveredEggs[id] = {
            id = id,
            pos = info.position,
            rarity = tonumber(info.rarity) or 1,
            hp = tonumber(info.hp) or 10,
            maxHp = tonumber(info.maxHp) or 10,
            t = os.clock()
        }
    end
end))

mainMaid:GiveTask(Remotes.DiscoveryLost.OnClientEvent:Connect(function(id)
    if type(id) == "string" then
        activeDiscoveredEggs[id] = nil
    end
end))

-- ------------------------------------------------------------------------------
-- ESP Engine (Eggs, Markers, Guardians)
-- ------------------------------------------------------------------------------
local espFolder = Instance.new("Folder")
espFolder.Name = "TwoKPrism_ESP"
espFolder.Parent = CoreGui

local activeBillboards = {}

local function clearESP()
    for _, b in pairs(activeBillboards) do
        pcall(function() b:Destroy() end)
    end
    table.clear(activeBillboards)
end

local function createBillboard(adornee, text, subtext, color)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 150, 0, 45)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 600

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(0, 255, 200)
    stroke.Thickness = 1.2
    stroke.Parent = frame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -6, 0.55, 0)
    titleLbl.Position = UDim2.new(0, 3, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = text or ""
    titleLbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    titleLbl.TextScaled = true
    titleLbl.Parent = frame

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -6, 0.4, 0)
    subLbl.Position = UDim2.new(0, 3, 0.55, 0)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.Gotham
    subLbl.Text = subtext or ""
    subLbl.TextColor3 = Color3.fromRGB(200, 220, 240)
    subLbl.TextScaled = true
    subLbl.Parent = frame

    bb.Parent = espFolder
    return bb
end

local function updateESP()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if S.EggESP then
        local cfx = workspace:FindFirstChild("ClientFx")
        if cfx then
            for _, m in ipairs(cfx:GetChildren()) do
                if m.Name == "Marker" and m:IsA("Model") and m.PrimaryPart then
                    local key = "Marker_" .. m:GetDebugId()
                    if not activeBillboards[key] then
                        activeBillboards[key] = createBillboard(m.PrimaryPart, "BURIED EGG", "Found Spot", Color3.fromRGB(255, 215, 0))
                    end
                end
            end
        end

        local we = workspace:FindFirstChild("WorldEggs")
        if we then
            for _, egg in ipairs(we:GetChildren()) do
                if egg.Name == "Egg" and egg:IsA("Model") then
                    local primary = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
                    local key = "Egg_" .. tostring(egg:GetAttribute("EggId") or egg:GetDebugId())
                    if primary and not activeBillboards[key] then
                        local species = egg:GetAttribute("Species") or "Rare Egg"
                        local dist = math.floor((primary.Position - hrp.Position).Magnitude)
                        activeBillboards[key] = createBillboard(primary, "STEAL: " .. tostring(species), tostring(dist) .. " studs", Color3.fromRGB(0, 255, 120))
                    end
                end
            end
        end
    end

    if S.GuardianESP then
        local gFolder = workspace:FindFirstChild("Guardians")
        if gFolder then
            for _, guardian in ipairs(gFolder:GetChildren()) do
                local key = "Guardian_" .. guardian.Name
                if not activeBillboards[key] and guardian:IsA("Model") then
                    local primary = guardian.PrimaryPart or guardian:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        local dist = math.floor((primary.Position - hrp.Position).Magnitude)
                        activeBillboards[key] = createBillboard(primary, "BOSS: " .. guardian.Name:upper(), tostring(dist) .. " studs", Color3.fromRGB(255, 60, 60))
                    end
                end
            end
        end
    end
end

-- ------------------------------------------------------------------------------
-- Main Farming Engine (Auto Treadmill & Auto Dig/Steal)
-- ------------------------------------------------------------------------------
local lastDigActionTime = 0
local scoutDirection = 1

local function runAutomationStep()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- 1. Auto Treadmill (Speed Farming)
    if S.AutoTreadmill then
        local onTM = LocalPlayer:GetAttribute("OnTreadmill") == true
        if not onTM then
            local mountPos = getMyTreadmillMount()
            if mountPos then
                safeMoveTowards(mountPos, S.TravelSpeed or 125, 2)
            end
        end
        return
    end

    -- 2. Auto Dig & Steal Eggs
    if S.AutoDig then
        exitTreadmillIfOn()

        local moveSpd = S.TravelSpeed or 125
        local chosen = STAGE_DATA[S.TargetStage] or STAGE_DATA["Stage 1 (Beach Zone)"]
        local minZ = chosen.minZ or 0
        local maxZ = chosen.maxZ or 120

        local function isInTargetStage(pos)
            return pos and pos.Z >= minZ and pos.Z <= maxZ
        end

        -- Check if carrying an egg
        local carryingEgg = LocalPlayer:GetAttribute("CarryingEggId")
        if carryingEgg then
            UI:SetStatus("กำลังถือไข่! วิ่งกลับข้ามเส้น Safe Line เข้าเล้า...")
            local safeHubTarget = Vector3.new(0, hrp.Position.Y, -12)
            local arrived = safeMoveTowards(safeHubTarget, moveSpd, 4)
            if arrived or hrp.Position.Z <= -5 then
                local penBoxPos = getMyPenBoxCenter()
                safeMoveTowards(penBoxPos, moveSpd, 6)
                pcall(function()
                    PlaceEggRemote:FireServer(carryingEgg, penBoxPos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))
                end)
                task.wait(0.25)
            end
            return
        end

        -- Sync live markers from game's DetectorController.markers
        local now = os.clock()
        if DetectorController and type(DetectorController.markers) == "table" then
            for id, m in pairs(DetectorController.markers) do
                if m and m.position and isInTargetStage(m.position) then
                    activeDiscoveredEggs[id] = {
                        id = id,
                        pos = m.position,
                        t = now,
                    }
                end
            end
        end

        -- Purge any discovered markers outside the selected stage or expired (>15s)
        for id, m in pairs(activeDiscoveredEggs) do
            local stillExists = (DetectorController and DetectorController.markers and DetectorController.markers[id] ~= nil)
            if not isInTargetStage(m.pos) or (not stillExists and m.t and (now - m.t > 12)) then
                activeDiscoveredEggs[id] = nil
            end
        end

        -- If player is not yet inside the selected stage bounds, travel straight to the selected stage first!
        if hrp.Position.Z < (minZ - 12) or hrp.Position.Z > (maxZ + 12) then
            UI:SetStatus("กำลังวิ่งตรงไปยัง " .. chosen.name .. " (ข้ามโซนอื่น)...")
            safeMoveTowards(Vector3.new(0, hrp.Position.Y, chosen.z), moveSpd, 10)
            return
        end

        -- Check if an egg in the SELECTED STAGE is waiting to be picked up in WorldEggs
        local we = workspace:FindFirstChild("WorldEggs")
        local eggToSteal = nil
        local bestEggDist = math.huge
        if we then
            for _, egg in ipairs(we:GetChildren()) do
                if egg.Name == "Egg" and egg:IsA("Model") then
                    local prompt = egg:FindFirstChild("PickUp", true)
                    local primary = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
                    if prompt and primary and isInTargetStage(primary.Position) then
                        local d = (primary.Position - hrp.Position).Magnitude
                        if d < bestEggDist then
                            bestEggDist = d
                            eggToSteal = { model = egg, prompt = prompt, pos = primary.Position }
                        end
                    end
                end
            end
        end

        if eggToSteal then
            UI:SetStatus("พบไข่ใน " .. chosen.name .. "! กำลังพุ่งไปขโมย...")
            local arrived = safeMoveTowards(eggToSteal.pos, moveSpd, 6)
            if arrived or (hrp.Position - eggToSteal.pos).Magnitude <= 9 then
                if fireproximityprompt then
                    fireproximityprompt(eggToSteal.prompt)
                else
                    eggToSteal.prompt:InputHoldBegin()
                    task.wait(eggToSteal.prompt.HoldDuration + 0.1)
                    eggToSteal.prompt:InputHoldEnd()
                end
                task.wait(0.35)
            end
            return
        end

        -- Check active discovered egg markers strictly inside the SELECTED STAGE
        local nearestMarker = nil
        local nearestDist = math.huge
        for id, m in pairs(activeDiscoveredEggs) do
            if m.pos and isInTargetStage(m.pos) then
                local dist = (m.pos - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestMarker = m
                end
            end
        end

        -- Fallback: check workspace.ClientFx.Marker only if inside target stage
        if not nearestMarker then
            local cfx = workspace:FindFirstChild("ClientFx")
            if cfx then
                for _, m in ipairs(cfx:GetChildren()) do
                    if m.Name == "Marker" and m.PrimaryPart and isInTargetStage(m.PrimaryPart.Position) then
                        local d = (m.PrimaryPart.Position - hrp.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            nearestMarker = { id = m:GetAttribute("EggId") or "Marker", pos = m.PrimaryPart.Position }
                        end
                    end
                end
            end
        end

        if nearestMarker then
            -- Move to marker in target stage and dig!
            local arrived = safeMoveTowards(nearestMarker.pos, moveSpd, 7)
            if arrived or (hrp.Position - nearestMarker.pos).Magnitude <= 10 then
                equipToolKind("Shovel")
                local delayTime = S.FastDig and 0.14 or 0.28
                if now - lastDigActionTime >= delayTime then
                    lastDigActionTime = now
                    pcall(function()
                        DigRemote:FireServer(nearestMarker.id)
                    end)
                end
            end
        else
            -- No marker in target stage: Equip Detector and patrol target stage!
            equipToolKind("Detector")
            pcall(function()
                ScanStart:FireServer()
            end)

            local targetZ = chosen.z
            local patrolX = scoutDirection * 28

            UI:SetStatus("กำลังสแกนหาไข่เฉพาะใน " .. chosen.name .. "...")
            local arrived = safeMoveTowards(Vector3.new(patrolX, hrp.Position.Y, targetZ), moveSpd, 8)
            if arrived then
                scoutDirection = -scoutDirection
            end
        end
    end
end

-- Periodic Upgrades, Hatching, and Selling
local function runMaintenanceStep()
    pcall(function()
        -- Auto Hatch
        if S.AutoHatch then
            HatchAllRemote:FireServer()
        end

        -- Auto Equip Best
        if S.AutoEquipBest then
            EquipBestRemote:FireServer()
        end

        -- Auto Upgrades
        if S.AutoUpgradePen then
            UpgradePenRemote:FireServer()
        end
        if S.AutoUpgradeTreadmill then
            UpgradeTreadmillRemote:FireServer()
        end
        if S.AutoUpgradeStorage then
            UpgradeStorageRemote:FireServer()
        end

        -- Auto Claims
        if S.AutoClaimRewards then
            ClaimOfflineRemote:FireServer()
            FreeRewardClaimRemote:FireServer()
            CommunityClaimRemote:FireServer()
        end

        -- Auto Buy Tools & Trails
        if S.AutoBuyShovel then
            local shop = Store and Store.data and Store.data.shop
            local tier = shop and shop.shovelTier or 0
            ShopBuyRemote:FireServer("Shovel", tier + 1)
            ShopEquipRemote:FireServer("Shovel", tier + 1)
        end
        if S.AutoBuyDetector then
            local shop = Store and Store.data and Store.data.shop
            local tier = shop and shop.detectorTier or 0
            ShopBuyRemote:FireServer("Detector", tier + 1)
            ShopEquipRemote:FireServer("Detector", tier + 1)
        end
        if S.AutoBuyTrail then
            local shop = Store and Store.data and Store.data.shop
            local tier = shop and shop.trail or 1
            ShopBuyRemote:FireServer("Trail", tier + 1)
            ShopEquipRemote:FireServer("Trail", tier + 1)
        end

        -- Auto Place Eggs in Pen (Uses HoldItem + PenBoxCenter for 100% pad placement)
        if S.AutoPlaceEggs then
            local items = Store and Store.data and Store.data.items
            if items then
                local penBoxPos = getMyPenBoxCenter()
                for _, it in ipairs(items) do
                    if it.kind == "egg" and not it.pad then
                        HoldItemRemote:FireServer(it.id)
                        task.wait(0.2)
                        PlaceEggRemote:FireServer(it.id, penBoxPos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))
                        task.wait(0.25)
                        break
                    end
                end
            end
        end

        -- Auto Sell Pets
        if S.AutoSell then
            local items = Store and Store.data and Store.data.items
            if items then
                local maxR = 2
                if S.SellRarity == "Common Only" then maxR = 1
                elseif S.SellRarity == "Common & Uncommon" then maxR = 2
                elseif S.SellRarity == "Rare and Below" then maxR = 3
                elseif S.SellRarity == "Epic and Below" then maxR = 4
                end

                local ids = {}
                for _, it in ipairs(items) do
                    if it.kind == "pet" and not it.equipped and not it.favorite and not it.pad then
                        if (tonumber(it.rarity) or 1) <= maxR then
                            table.insert(ids, it.id)
                        end
                    end
                end
                if #ids > 0 then
                    SellItemsRemote:FireServer(ids)
                end
            end
        end
    end)
end

-- ------------------------------------------------------------------------------
-- Movement Mechanics (Fly, Noclip, Speed, Jump)
-- ------------------------------------------------------------------------------
local flyBodyVelocity, flyBodyGyro

local function setFly(enabled)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enabled then
        if not flyBodyVelocity then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyVelocity.Parent = hrp
        end
        if not flyBodyGyro then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.CFrame = hrp.CFrame
            flyBodyGyro.Parent = hrp
        end
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    end
end

mainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if S.Fly and flyBodyVelocity and flyBodyGyro then
        local cam = workspace.CurrentCamera
        if not cam then return end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDir.Unit * S.FlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end
        flyBodyGyro.CFrame = cam.CFrame
    end
end))

mainMaid:GiveTask(RunService.Stepped:Connect(function()
    if S.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
end))

mainMaid:GiveTask(RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if S.WalkSpeedOn and hum.WalkSpeed ~= S.WalkSpeed then
            hum.WalkSpeed = S.WalkSpeed
        end
        if S.JumpPowerOn and hum.JumpPower ~= S.JumpPower then
            hum.JumpPower = S.JumpPower
        end
    end
end))

mainMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
    if S.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- ------------------------------------------------------------------------------
-- UI INTERFACE CREATION (2K PRISM Shattered Prism Glass)
-- ------------------------------------------------------------------------------
do
local farmTab = UI:Tab("FARM")
local petsTab = UI:Tab("PETS")
local upgradesTab = UI:Tab("UPGRADES")
local teleportTab = UI:Tab("TELEPORT")
local espTab = UI:Tab("ESP & MISC")
local settingsTab = UI:Tab("SETTINGS")

local UIControls = {}

-- ==============================================================================
-- Tab: FARM
-- ==============================================================================
local farmSec = farmTab:Section("AUTOMATION & SPEED FARM (ระบบฟาร์มอัตโนมัติ)")

UIControls.AutoTreadmill = farmSec:Toggle({
    Name = "ฟาร์มความเร็วบนลู่วิ่งอัตโนมัติ (AUTO TREADMILL SPEED)",
    Default = S.AutoTreadmill,
    Callback = function(val)
        S.AutoTreadmill = val
        if val and S.AutoDig then
            S.AutoDig = false
            if UIControls.AutoDig and UIControls.AutoDig.Set then
                UIControls.AutoDig:Set(false, true)
            end
        end
        UI:SetStatus("ฟาร์มลู่วิ่งอัตโนมัติ: " .. (val and "เปิดทำงาน (ปั๊ม Speed ในเล้า)" or "ปิด"))
    end,
})

UIControls.AutoDig = farmSec:Toggle({
    Name = "ขุดไข่และขโมยกลับเล้าอัตโนมัติ (AUTO DIG & STEAL EGGS)",
    Default = S.AutoDig,
    Callback = function(val)
        S.AutoDig = val
        if val and S.AutoTreadmill then
            S.AutoTreadmill = false
            if UIControls.AutoTreadmill and UIControls.AutoTreadmill.Set then
                UIControls.AutoTreadmill:Set(false, true)
            end
        end
        UI:SetStatus("ขุดไข่อัตโนมัติ: " .. (val and "เปิดทำงาน (สแกน & ขุด & ขโมยกลับเล้า)" or "ปิด"))
    end,
})

UIControls.FastDig = farmSec:Toggle({
    Name = "โหมดขุดไวข้ามดีเลย์ (FAST INSTANT DIG)",
    Default = S.FastDig,
    Callback = function(val)
        S.FastDig = val
        UI:SetStatus("โหมดขุดไว: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoStealReturn = farmSec:Toggle({
    Name = "ขโมยไข่แล้ววาร์ปกลับเล้าทันที (AUTO STEAL & RETURN TO PEN)",
    Default = S.AutoStealReturn,
    Callback = function(val)
        S.AutoStealReturn = val
        UI:SetStatus("นำไข่กลับเล้า: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.TargetStage = farmSec:Dropdown({
    Name = "เลือกโซนที่จะขุด (TARGET STAGE)",
    Options = STAGE_OPTIONS,
    Default = S.TargetStage,
    Callback = function(choice)
        S.TargetStage = choice
        table.clear(activeDiscoveredEggs)
        UI:SetStatus("ตั้งโซนเป้าหมาย: " .. tostring(choice))
    end,
})

UIControls.TravelSpeed = farmSec:Slider({
    Name = "ความเร็ววิ่งฟาร์ม (FARM TRAVEL SPEED)",
    Min = 50,
    Max = 160,
    Default = S.TravelSpeed or 125,
    Precision = 0,
    Callback = function(val)
        S.TravelSpeed = val
        UI:SetStatus("ความเร็ววิ่งฟาร์ม: " .. tostring(val) .. " studs/s")
    end,
})

local combatSec = farmTab:Section("COMBAT & DEFENSE (การต่อสู้ & ป้องกันตัว)")

UIControls.AutoSwing = combatSec:Toggle({
    Name = "ฟาดกระบองป้องกันตัวอัตโนมัติ (AUTO SWING BAT)",
    Default = S.AutoSwing,
    Callback = function(val)
        S.AutoSwing = val
        UI:SetStatus("ฟาดกระบองอัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

-- ==============================================================================
-- Tab: PETS & EGGS
-- ==============================================================================
local petSec = petsTab:Section("PET & EGG MANAGEMENT (จัดการไข่และสัตว์เลี้ยง)")

UIControls.AutoHatch = petSec:Toggle({
    Name = "ฟักไข่ที่โตแล้วอัตโนมัติ (AUTO HATCH ALL READY EGGS)",
    Default = S.AutoHatch,
    Callback = function(val)
        S.AutoHatch = val
        UI:SetStatus("ฟักไข่อัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoEquipBest = petSec:Toggle({
    Name = "สวมใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (AUTO EQUIP BEST PETS)",
    Default = S.AutoEquipBest,
    Callback = function(val)
        S.AutoEquipBest = val
        UI:SetStatus("สวมใส่สัตว์เทพสุด: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoPlaceEggs = petSec:Toggle({
    Name = "นำไข่ในตัวมาวางในเล้าอัตโนมัติ (AUTO PLACE EGGS IN PEN)",
    Default = S.AutoPlaceEggs,
    Callback = function(val)
        S.AutoPlaceEggs = val
        UI:SetStatus("วางไข่ในเล้าอัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

local sellSec = petsTab:Section("SELL ANIMALS (ระบบขายสัตว์เลี้ยง)")

UIControls.AutoSell = sellSec:Toggle({
    Name = "ขายสัตว์เลี้ยงที่ไม่ได้สวมใส่อัตโนมัติ (AUTO SELL UNUSED PETS)",
    Default = S.AutoSell,
    Callback = function(val)
        S.AutoSell = val
        UI:SetStatus("ขายสัตว์เลี้ยงอัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.SellRarity = sellSec:Dropdown({
    Name = "เลือกความหายากที่จะขาย (SELL RARITY FILTER)",
    Options = RARITY_SELL_OPTIONS,
    Default = S.SellRarity,
    Callback = function(choice)
        S.SellRarity = choice
        UI:SetStatus("ตั้งค่าความหายากที่จะขาย: " .. tostring(choice))
    end,
})

sellSec:Button({
    Name = "ขายสัตว์เลี้ยงทันที 1 ครั้ง (SELL NOW ONCE)",
    Callback = function()
        pcall(function()
            local items = Store and Store.data and Store.data.items
            if items then
                local maxR = 2
                if S.SellRarity == "Common Only" then maxR = 1
                elseif S.SellRarity == "Common & Uncommon" then maxR = 2
                elseif S.SellRarity == "Rare and Below" then maxR = 3
                elseif S.SellRarity == "Epic and Below" then maxR = 4
                end
                local ids = {}
                for _, it in ipairs(items) do
                    if it.kind == "pet" and not it.equipped and not it.favorite and not it.pad then
                        if (tonumber(it.rarity) or 1) <= maxR then
                            table.insert(ids, it.id)
                        end
                    end
                end
                if #ids > 0 then
                    SellItemsRemote:FireServer(ids)
                end
            end
        end)
        UI:Notify({
            Title = "SELL COMPLETE",
            Text = "ขายสัตว์เลี้ยงตามเงื่อนไขเรียบร้อยแล้ว!",
            Duration = 3,
        })
    end,
})

-- ==============================================================================
-- Tab: UPGRADES
-- ==============================================================================
local upSec = upgradesTab:Section("AUTO UPGRADES & SHOP (อัปเกรด & ซื้อของอัตโนมัติ)")

UIControls.AutoUpgradePen = upSec:Toggle({
    Name = "อัปเกรดเล้าสัตว์อัตโนมัติ (AUTO UPGRADE PEN)",
    Default = S.AutoUpgradePen,
    Callback = function(val)
        S.AutoUpgradePen = val
        UI:SetStatus("อัปเกรดเล้า: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoUpgradeTreadmill = upSec:Toggle({
    Name = "อัปเกรดลู่วิ่งอัตโนมัติ (AUTO UPGRADE TREADMILL)",
    Default = S.AutoUpgradeTreadmill,
    Callback = function(val)
        S.AutoUpgradeTreadmill = val
        UI:SetStatus("อัปเกรดลู่วิ่ง: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoUpgradeStorage = upSec:Toggle({
    Name = "อัปเกรดความจุกระเป๋าอัตโนมัติ (AUTO UPGRADE STORAGE)",
    Default = S.AutoUpgradeStorage,
    Callback = function(val)
        S.AutoUpgradeStorage = val
        UI:SetStatus("อัปเกรดความจุกระเป๋า: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoBuyShovel = upSec:Toggle({
    Name = "ซื้อพลั่วที่ดีที่สุดอัตโนมัติ (AUTO BUY BEST SHOVEL)",
    Default = S.AutoBuyShovel,
    Callback = function(val)
        S.AutoBuyShovel = val
        UI:SetStatus("ซื้อพลั่วอัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoBuyDetector = upSec:Toggle({
    Name = "ซื้อเครื่องตรวจจับที่ดีที่สุดอัตโนมัติ (AUTO BUY BEST DETECTOR)",
    Default = S.AutoBuyDetector,
    Callback = function(val)
        S.AutoBuyDetector = val
        UI:SetStatus("ซื้อเครื่องสแกนอัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoBuyTrail = upSec:Toggle({
    Name = "ซื้อและสวมใส่ Trail เพิ่มตัวคูณความเร็วอัตโนมัติ (AUTO BUY BEST TRAIL)",
    Default = S.AutoBuyTrail,
    Callback = function(val)
        S.AutoBuyTrail = val
        UI:SetStatus("ซื้อ Trail อัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.AutoClaimRewards = upSec:Toggle({
    Name = "รับของขวัญฟรี & เงินออฟไลน์อัตโนมัติ (AUTO CLAIM ALL REWARDS)",
    Default = S.AutoClaimRewards,
    Callback = function(val)
        S.AutoClaimRewards = val
        UI:SetStatus("รับของขวัญอัตโนมัติ: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

-- ==============================================================================
-- Tab: TELEPORT
-- ==============================================================================
local tpSec = teleportTab:Section("TELEPORTS (จุดวาร์ปสำคัญ)")

tpSec:Button({
    Name = "เดินกลับเล้าของตัวเอง (WALK TO MY PEN)",
    Callback = function()
        exitTreadmillIfOn()
        safeMoveTowards(getMyPenSpawn(), S.TravelSpeed or 125, 4)
        UI:SetStatus("เดินกลับเล้าเรียบร้อย")
    end,
})

tpSec:Button({
    Name = "เดินไปลู่วิ่งของตัวเอง (WALK TO TREADMILL)",
    Callback = function()
        local mount = getMyTreadmillMount()
        if mount then
            safeMoveTowards(mount, S.TravelSpeed or 125, 2)
            UI:SetStatus("เดินไปลู่วิ่งเรียบร้อย")
        end
    end,
})

local selectedTpStage = "Stage 1 (Beach Zone)"
tpSec:Dropdown({
    Name = "เลือกโซนที่จะเดินไป (SELECT ZONE TO WALK)",
    Options = STAGE_OPTIONS,
    Default = selectedTpStage,
    Callback = function(choice)
        selectedTpStage = choice
    end,
})

tpSec:Button({
    Name = "เดินทางไปยังโซนที่เลือก (WALK TO SELECTED STAGE)",
    Callback = function()
        exitTreadmillIfOn()
        local chosen = STAGE_DATA[selectedTpStage]
        if chosen then
            safeMoveTowards(Vector3.new(0, 3, chosen.z), S.TravelSpeed or 125, 8)
            UI:SetStatus("เดินทางไป " .. chosen.name .. " เรียบร้อย")
        end
    end,
})

-- ==============================================================================
-- Tab: ESP & MISC
-- ==============================================================================
local espSec = espTab:Section("VISUALS & ESP (การมองเห็น)")

UIControls.EggESP = espSec:Toggle({
    Name = "เปิด ESP แสดงตำแหน่งไข่และจุดขุด (EGG & DIG ESP)",
    Default = S.EggESP,
    Callback = function(val)
        S.EggESP = val
        if not val then
            clearESP()
        end
        UI:SetStatus("Egg ESP: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

UIControls.GuardianESP = espSec:Toggle({
    Name = "เปิด ESP แสดงมอนสเตอร์การ์เดี้ยน (GUARDIAN BOSS ESP)",
    Default = S.GuardianESP,
    Callback = function(val)
        S.GuardianESP = val
        if not val then
            clearESP()
        end
        UI:SetStatus("Guardian ESP: " .. (val and "เปิดทำงาน" or "ปิด"))
    end,
})

local moveSec = espTab:Section("PLAYER MOVEMENT (การเคลื่อนที่)")

UIControls.WalkSpeedOn = moveSec:Toggle({
    Name = "เปิดใช้งานปรับความเร็วเดิน (WALKSPEED TOGGLE)",
    Default = S.WalkSpeedOn,
    Callback = function(val)
        S.WalkSpeedOn = val
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not val then
            local spd = tonumber(LocalPlayer:GetAttribute("Speed")) or 10
            local ok, phys = pcall(Formulas.physicalSpeed, spd)
            hum.WalkSpeed = (ok and phys) or 32
        end
    end,
})

UIControls.WalkSpeed = moveSec:Slider({
    Name = "ความเร็วเดิน (WALKSPEED SLIDER)",
    Min = 16,
    Max = 120,
    Default = S.WalkSpeed,
    Precision = 0,
    Callback = function(val)
        S.WalkSpeed = val
    end,
})

UIControls.JumpPowerOn = moveSec:Toggle({
    Name = "เปิดใช้งานปรับความสูงกระโดด (JUMPPOWER TOGGLE)",
    Default = S.JumpPowerOn,
    Callback = function(val)
        S.JumpPowerOn = val
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not val then
            hum.JumpPower = 50
        end
    end,
})

UIControls.JumpPower = moveSec:Slider({
    Name = "ความสูงกระโดด (JUMPPOWER SLIDER)",
    Min = 50,
    Max = 250,
    Default = S.JumpPower,
    Precision = 0,
    Callback = function(val)
        S.JumpPower = val
    end,
})

UIControls.InfiniteJump = moveSec:Toggle({
    Name = "กระโดดลอยได้ไม่จำกัด (INFINITE JUMP)",
    Default = S.InfiniteJump,
    Callback = function(val)
        S.InfiniteJump = val
    end,
})

UIControls.Noclip = moveSec:Toggle({
    Name = "เดินทะลุกำแพงและสิ่งกีดขวาง (NOCLIP)",
    Default = S.Noclip,
    Callback = function(val)
        S.Noclip = val
    end,
})

UIControls.Fly = moveSec:Toggle({
    Name = "บินอิสระ (FLY MODE - WASD + Space/Shift)",
    Default = S.Fly,
    Callback = function(val)
        S.Fly = val
        setFly(val)
    end,
})

UIControls.FlySpeed = moveSec:Slider({
    Name = "ความเร็วการบิน (FLY SPEED)",
    Min = 20,
    Max = 120,
    Default = S.FlySpeed,
    Precision = 0,
    Callback = function(val)
        S.FlySpeed = val
    end,
})

-- ==============================================================================
-- Tab: SETTINGS
-- ==============================================================================
local themeSec = settingsTab:Section("UI THEME (ธีมหน้าต่าง)")

local THEME_CHOICES = {"Ice", "Aurora", "Ember", "Neon", "Cyber", "Midnight", "Glass"}
themeSec:Dropdown({
    Name = "เลือกธีมหน้าต่าง (THEME SELECTOR)",
    Options = THEME_CHOICES,
    Default = CONFIG.Theme or "Ice",
    Callback = function(themeName)
        if Themes and Themes[themeName] then
            currentTheme = Themes[themeName]
            currentColorSequence = makeSequence(currentTheme)
            for _, listener in ipairs(accentListeners) do
                pcall(listener, currentTheme, currentColorSequence)
            end
            for _, s in ipairs(allSurfaces) do
                pcall(function()
                    s.ImageColor3 = currentTheme.C1
                end)
            end
            UI:SetStatus("เปลี่ยนธีมเป็น: " .. tostring(themeName))
        end
    end,
})

local discordSec = settingsTab:Section("COMMUNITY & SUPPORT (คอมมูนิตี้)")

discordSec:Button({
    Name = "คัดลอกลิงก์ดิสคอร์ด (COPY DISCORD INVITE)",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/4Yg72kYT6s")
            elseif toclipboard then
                toclipboard("https://discord.gg/4Yg72kYT6s")
            end
        end)
        UI:Notify({
            Title = "DISCORD INVITE COPIED",
            Text = "คัดลอกลิงก์ Discord เข้าคลิปบอร์ดแล้ว! (https://discord.gg/4Yg72kYT6s)",
            Duration = 4,
        })
        UI:SetStatus("คัดลอกลิงก์ Discord เรียบร้อย")
    end,
})

local configSec = settingsTab:Section("CONFIG MANAGER (ระบบบันทึกและโหลดคอนฟิก)")

local currentAutoload = getAutoloadConfig()
local selectedConfigChoice = nil
local currentConfigInput = "Default"

UIControls.AutoLoadConfig = configSec:Toggle({
    Name = "โหลดคอนฟิกอัตโนมัติเมื่อเปิดสคริปต์ (AUTO LOAD CONFIG)",
    Default = (currentAutoload ~= nil and currentAutoload ~= ""),
    Callback = function(val)
        if val then
            local target = selectedConfigChoice or currentConfigInput
            if target and target ~= "" then
                setAutoloadConfig(target)
                currentAutoload = target
                UI:Notify({
                    Title = "AUTO LOAD SET",
                    Text = "ตั้งให้โหลด [" .. target .. "] อัตโนมัติทุกครั้งที่รัน",
                    Duration = 3,
                })
                UI:SetStatus("เปิด Auto Load: " .. target)
            else
                UI:Notify({
                    Title = "NO CONFIG SELECTED",
                    Text = "กรุณาเลือกหรือสร้างคอนฟิกก่อนเปิด Auto Load",
                    Duration = 3,
                })
            end
        else
            setAutoloadConfig(nil)
            currentAutoload = nil
            UI:Notify({
                Title = "AUTO LOAD DISABLED",
                Text = "ปิดการโหลดคอนฟิกอัตโนมัติแล้ว",
                Duration = 3,
            })
            UI:SetStatus("ปิด Auto Load Config")
        end
    end,
})

configSec:Button({
    Name = "ตั้งคอนฟิกนี้เป็น Auto Load (SET AS AUTO LOAD)",
    Callback = function()
        local target = selectedConfigChoice or currentConfigInput
        if target and target ~= "" then
            setAutoloadConfig(target)
            currentAutoload = target
            if UIControls.AutoLoadConfig and UIControls.AutoLoadConfig.Set then
                UIControls.AutoLoadConfig:Set(true, true)
            end
            UI:Notify({
                Title = "AUTO LOAD SAVED",
                Text = "คอนฟิก [" .. target .. "] จะถูกโหลดอัตโนมัติเมื่อรันสคริปต์ครั้งถัดไป!",
                Duration = 4,
            })
            UI:SetStatus("บันทึก Auto Load: " .. target)
        end
    end,
})

configSec:Input({
    Name = "ชื่อคอนฟิก (CONFIG NAME)",
    Default = "Default",
    Placeholder = "พิมพ์ชื่อคอนฟิกที่ต้องการ...",
    Callback = function(txt)
        currentConfigInput = txt
    end,
})

configSec:Button({
    Name = "สร้างคอนฟิกใหม่ (CREATE CONFIG)",
    Callback = function()
        if not currentConfigInput or currentConfigInput:gsub("%s+", "") == "" then
            UI:Notify({ Title = "ERROR", Text = "กรุณากรอกชื่อคอนฟิกก่อนบันทึก!", Duration = 3 })
            return
        end
        local ok, res = saveConfigFile(currentConfigInput)
        if ok then
            UI:Notify({ Title = "CONFIG SAVED", Text = "สร้างคอนฟิก [" .. res .. "] เรียบร้อย!", Duration = 3 })
            UI:SetStatus("สร้างคอนฟิก: " .. res .. " สำเร็จ")
        else
            UI:Notify({ Title = "SAVE FAILED", Text = "เกิดข้อผิดพลาด: " .. tostring(res), Duration = 4 })
        end
    end,
})

local configDropdownRef = nil
local function refreshConfigDropdown(selectedName)
    local list = listConfigFiles()
    if #list == 0 then
        table.insert(list, "No Configs")
    end
    if configDropdownRef and configDropdownRef.SetOptions then
        configDropdownRef:SetOptions(list, selectedName or list[1])
    end
end

local existingList = listConfigFiles()
if #existingList == 0 then table.insert(existingList, "No Configs") end

configDropdownRef = configSec:Dropdown({
    Name = "เลือกคอนฟิก (SELECT CONFIG)",
    Options = existingList,
    Default = existingList[1],
    Callback = function(choice)
        if choice ~= "No Configs" then
            selectedConfigChoice = choice
            currentConfigInput = choice
            UI:SetStatus("เลือกคอนฟิก: " .. choice)
        end
    end,
})

configSec:Button({
    Name = "โหลดคอนฟิก (LOAD CONFIG)",
    Callback = function()
        local nameToLoad = selectedConfigChoice or currentConfigInput
        if not nameToLoad or nameToLoad == "No Configs" then return end
        local ok, res = loadConfigData(nameToLoad)
        if ok then
            for k, ctrl in pairs(UIControls) do
                if ctrl and ctrl.Set and S[k] ~= nil then
                    pcall(function() ctrl:Set(S[k], true) end)
                end
            end
            UI:Notify({ Title = "CONFIG LOADED", Text = "โหลดคอนฟิก [" .. res .. "] เรียบร้อย!", Duration = 3 })
            UI:SetStatus("โหลดคอนฟิก: " .. res .. " สำเร็จ")
        else
            UI:Notify({ Title = "LOAD FAILED", Text = "เกิดข้อผิดพลาด: " .. tostring(res), Duration = 4 })
        end
    end,
})

configSec:Button({
    Name = "โอเวอร์ไรท์ / เซฟทับ (OVERWRITE CONFIG)",
    Callback = function()
        local nameToSave = selectedConfigChoice or currentConfigInput
        if not nameToSave or nameToSave == "No Configs" then return end
        local ok, res = saveConfigFile(nameToSave)
        if ok then
            UI:Notify({ Title = "CONFIG OVERWRITTEN", Text = "เซฟทับคอนฟิก [" .. res .. "] เรียบร้อย!", Duration = 3 })
            UI:SetStatus("เซฟทับ: " .. res .. " สำเร็จ")
        else
            UI:Notify({ Title = "OVERWRITE FAILED", Text = "เกิดข้อผิดพลาด: " .. tostring(res), Duration = 4 })
        end
    end,
})

configSec:Button({
    Name = "ลบคอนฟิก (DELETE CONFIG)",
    Callback = function()
        local nameToDelete = selectedConfigChoice or currentConfigInput
        if not nameToDelete or nameToDelete == "No Configs" then return end
        local ok, res = deleteConfigFile(nameToDelete)
        if ok then
            if currentAutoload == nameToDelete then
                setAutoloadConfig(nil)
                currentAutoload = nil
            end
            refreshConfigDropdown()
            UI:Notify({ Title = "CONFIG DELETED", Text = "ลบคอนฟิก [" .. res .. "] ออกจากเครื่องแล้ว!", Duration = 3 })
            UI:SetStatus("ลบคอนฟิก: " .. res)
        end
    end,
})

configSec:Button({
    Name = "รีเฟรชรายชื่อคอนฟิก (REFRESH LIST)",
    Callback = function()
        refreshConfigDropdown(selectedConfigChoice)
        UI:SetStatus("รีเฟรชรายชื่อคอนฟิกเรียบร้อย")
    end,
})

end

UI:Toggle(true)

-- ------------------------------------------------------------------------------
-- Auto-Load on Startup if configured
-- ------------------------------------------------------------------------------
pcall(function()
    local autoTarget = getAutoloadConfig()
    if autoTarget and autoTarget ~= "" then
        task.spawn(function()
            task.wait(0.3)
            local ok, res = loadConfigData(autoTarget)
            if ok then
                UI:Notify({
                    Title = "AUTO LOAD // 2K PRISM",
                    Text = "โหลดคอนฟิกเริ่มต้น [" .. res .. "] อัตโนมัติสำเร็จแล้ว!",
                    Duration = 4,
                })
                UI:SetStatus("Auto Load คอนฟิก " .. res .. " เรียบร้อย")
            end
        end)
    end
end)

UI:Notify({
    Title = "DETECT & STEAL AN EGG // 2K PRISM",
    Text = "สคริปต์พร้อมใช้งาน! Auto Treadmill + Auto Dig & Steal ปลอดภัย 100%",
    Duration = 5,
})

-- ------------------------------------------------------------------------------
-- Main Background Automation Orchestrator
-- ------------------------------------------------------------------------------
mainMaid:GiveTask(task.spawn(function()
    local lastMaint = 0
    while isScriptAlive() do
        pcall(function()
            elevate()

            -- Core Action Loop
            runAutomationStep()

            -- Maintenance Loop (Every 0.8s)
            local now = os.clock()
            if now - lastMaint >= 0.8 then
                lastMaint = now
                runMaintenanceStep()
            end

            -- Visuals
            updateESP()
        end)
        task.wait(0.2)
    end
    clearESP()
end))

return UI

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
    Title = "2K PRISM",
    Sub = "GLASS INTERFACE",
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

makeTopButton("-", 3, function()
    UI:Toggle(false)
end)

makeTopButton("x", 4, function()
    UI:Destroy()
end)

-- Container Drag Logic via TOP slab
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
    mainMaid:Destroy()
    genv.__TwoKPrism = nil
end

genv.__TwoKPrism = UI

container.Visible = false
return UI, mainMaid, CONFIG, Themes, makeSequence, accentListeners, blurEffect, allSurfaces, currentTheme, currentColorSequence
end)()



-- ==============================================================================
-- 2K PRISM // CHOP AND STEAL AN EGG - HARDCORE BEAST AUTOMATION HUB
-- Universe: 10771778398 // Place: 135361740992273
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

-- Remotes
local ChopRemotes = ReplicatedStorage:WaitForChild("ChopRemotes")
local ChopEggs = ChopRemotes:WaitForChild("ChopEggs")
local ChopInventory = ChopRemotes:WaitForChild("ChopInventory")
local AxeShop = ChopRemotes:WaitForChild("AxeShop")
local ChopBaseUpgrade = ChopRemotes:FindFirstChild("ChopBaseUpgrade")
local ChopShredderUpgrade = ChopRemotes:FindFirstChild("ChopShredderUpgrade")
local ChopRebirth = ChopRemotes:FindFirstChild("ChopRebirth")
local ChopShred = ChopRemotes:WaitForChild("ChopShred")
local ChopTrees = ChopRemotes:WaitForChild("ChopTrees")
local ChopEggEvents = ChopRemotes:FindFirstChild("ChopEggEvents")
local ChopTutorialSkip = ChopRemotes:FindFirstChild("ChopTutorialSkip")

-- Shared Modules
local ChopShared = ReplicatedStorage:WaitForChild("ChopShared")
local TreeConfig = require(ChopShared:WaitForChild("TreeConfig"))
local AxeCatalog = require(ChopShared:WaitForChild("AxeCatalog"))
local AreaConfig = require(ChopShared:WaitForChild("AreaConfig"))
local EggCatalog = require(ChopShared:WaitForChild("EggCatalog"))
local FreeGift = ChopShared:FindFirstChild("FreeGift")

-- Workspace Spots & Folders
local ChopTreeSpots = ReplicatedStorage:WaitForChild("ChopTreeSpots")
local Bases = workspace:WaitForChild("ChopMap"):WaitForChild("Spawn"):WaitForChild("Bases")

-- Script Instance Guard (Kills old zombie loops on re-execute)
local RUN_ID = HttpService:GenerateGUID(false)
if _G.__2K_CHOP_CLEANUP then
    pcall(_G.__2K_CHOP_CLEANUP)
end
_G.__2K_CHOP_RUN_ID = RUN_ID
local function isScriptAlive()
    return _G.__2K_CHOP_RUN_ID == RUN_ID
end

-- Unlock Native Client AutoSwing in ChopTreesClient
pcall(function()
    local AutoSwingRules = require(ChopShared:WaitForChild("AutoSwingRules", 5))
    if AutoSwingRules then
        AutoSwingRules.CanUse = function() return true end
    end
end)

-- Try Skip Tutorial on startup
pcall(function()
    if ChopTutorialSkip then
        ChopTutorialSkip:FireServer()
    end
end)

-- ------------------------------------------------------------------------------
-- Persistent Settings
-- ------------------------------------------------------------------------------
local SETTINGS_FILE = "2KSCRIPT/ChopAndStealAnEgg_Settings.json"

local S = {
    -- FARM
    AutoChop = false,
    SelectedAreas = {
        Forest = true,
        Autumn = false,
        Sakura = false,
        Snow = false,
        Desert = false,
        Water = false,
        Vulcano = false,
        Celestial = false,
        Void = false,
        Ghost = false,
    },
    AutoBestArea = true,
    ChopDelay = 0.33,

    -- EGGS & HATCH
    AutoPickupWild = false,
    AutoDeposit = true,
    SelectedEggRarities = {
        Common = true,
        Rare = true,
        Epic = true,
        Legendary = true,
        Mythic = true,
        Secret = true,
        Divine = true,
        Eternal = true,
    },
    AutoHatch = true,
    AutoEquipBest = true,

    -- UPGRADES
    AutoBuyAxe = false,
    AutoUpgradeShredder = false,
    AutoUpgradeBase = false,
    AutoRebirth = false,
    AutoClaimGift = true,

    -- PLAYER
    WalkSpeedOn = false,
    WalkSpeed = 45,
    JumpPowerOn = false,
    JumpPower = 80,
    InfiniteJump = false,
    Noclip = false,
    FlyOn = false,
    FlySpeed = 50,
}

local function safeReadJson(path, defaultVal)
    elevate()
    if isfile and isfile(path) then
        local content = readfile(path)
        local success, res = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if success and type(res) == "table" then
            return res
        end
    end
    return defaultVal
end

local function safeWriteJson(path, data)
    elevate()
    if writefile then
        if makefolder and not isfolder("2KSCRIPT") then
            pcall(makefolder, "2KSCRIPT")
        end
        pcall(function()
            writefile(path, HttpService:JSONEncode(data))
        end)
    end
end

local loadedSettings = safeReadJson(SETTINGS_FILE, {})
for k, v in pairs(loadedSettings) do
    if S[k] ~= nil then
        if type(v) == "table" and type(S[k]) == "table" then
            for subK, subV in pairs(v) do
                S[k][subK] = subV
            end
        else
            S[k] = v
        end
    end
end
if S.ChopDelay and S.ChopDelay < 0.30 then
    S.ChopDelay = 0.33
end
do
    local anyArea = false
    if type(S.SelectedAreas) == "table" then
        for _, v in pairs(S.SelectedAreas) do
            if v == true then anyArea = true break end
        end
    end
    if not anyArea and not S.AutoBestArea then
        S.AutoBestArea = true
    end
end

_G.__2K_CHOP_CLEANUP = function()
    S.AutoChop = false
    S.AutoPickupWild = false
    S.AutoDeposit = false
    S.AutoHatch = false
    S.AutoEquipBest = false
    S.AutoBuyAxe = false
    S.AutoUpgradeShredder = false
    S.AutoUpgradeBase = false
    S.AutoRebirth = false
    pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", false) end)
    pcall(function() mainMaid:Cleanup() end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        local oldGui = cg:FindFirstChild("TwoKPrism")
        if oldGui then oldGui:Destroy() end
    end)
end

local function saveSettings()
    safeWriteJson(SETTINGS_FILE, S)
end

-- ------------------------------------------------------------------------------
-- Coordinates & Constants
-- ------------------------------------------------------------------------------
local AREA_COORDS = {
    Forest = Vector3.new(-5, 4, -60),
    Autumn = Vector3.new(11, 4, -203),
    Sakura = Vector3.new(-5, 4, -419),
    Snow = Vector3.new(0, 4, -728),
    Desert = Vector3.new(-9, 4, -1083),
    Water = Vector3.new(-2, 4, -1511),
    Vulcano = Vector3.new(-2, 4, -2004),
    Celestial = Vector3.new(1, 4, -2630),
    Void = Vector3.new(3, 4, -3338),
    Ghost = Vector3.new(3, 4, -4132),
}

local AREA_ORDER = {
    "Forest", "Autumn", "Sakura", "Snow", "Desert",
    "Water", "Vulcano", "Celestial", "Void", "Ghost"
}

local ZONE_DISPLAY = {
    Forest = "1. Forest (ป่าไม้)",
    Autumn = "2. Autumn (ป่าใบไม้เปลี่ยนสี)",
    Sakura = "3. Sakura (ป่าซากุระ)",
    Snow = "4. Snow (ป่าหิมะ)",
    Desert = "5. Desert (ทะเลทราย)",
    Water = "6. Water (ดินแดนน้ำ)",
    Vulcano = "7. Vulcano (ภูเขาไฟ)",
    Celestial = "8. Celestial (สรวงสวรรค์)",
    Void = "9. Void (ความว่างเปล่า)",
    Ghost = "10. Ghost (สุสานวิญญาณ)",
}

-- ------------------------------------------------------------------------------
-- Core Helper Functions
-- ------------------------------------------------------------------------------
local function getRoot(char)
    char = char or LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(dest)
    local root = getRoot()
    if not root then return end
    if typeof(dest) == "Vector3" then
        root.CFrame = CFrame.new(dest)
    elseif typeof(dest) == "CFrame" then
        root.CFrame = dest
    end
end

local function getMyBase()
    local baseName = LocalPlayer:GetAttribute("BaseName")
    if baseName and Bases then
        return Bases:FindFirstChild(baseName)
    end
    return nil
end

local function getMyShredderDropZone()
    local base = getMyBase()
    if base then
        local shredder = base:FindFirstChild("Shredder")
        if shredder then
            return shredder:FindFirstChild("DropZone")
        end
    end
    return nil
end

local hatchReadyEggs = nil
local isDepositing = false
local isChopping = false
local function depositAndShred()
    if isDepositing then return end
    isDepositing = true
    pcall(function()
        local dropZone = getMyShredderDropZone()
        if not dropZone then return end

        pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", false) end)
        UI:SetStatus("กำลังวาร์ปกลับไปฝากและบดไข่ที่ Shredder...")

        for attempt = 1, 6 do
            if not isScriptAlive() then break end
            if (LocalPlayer:GetAttribute("CarryCount") or 0) <= 0 then
                break
            end
            teleportTo(dropZone.Position + Vector3.new(0, 3, 0))
            task.wait(0.22)
            pcall(function() ChopShred:FireServer("Drop") end)
            pcall(function() ChopEggs:InvokeServer("Drop") end)
            task.wait(0.12)
        end

        pcall(function() ChopShred:FireServer("Shred") end)
        task.wait(0.15)
        UI:SetStatus("บดไข่เสร็จสิ้น!")
        if S.AutoHatch then
            task.delay(3, function()
                if isScriptAlive() then
                    task.spawn(hatchReadyEggs)
                end
            end)
        end
    end)
    isDepositing = false
end

local isHatching = false
function hatchReadyEggs()
    if isHatching then return end
    isHatching = true
    pcall(function()
        elevate()
        if not ChopInventory then return end


        local baseName = LocalPlayer:GetAttribute("BaseName")
        local chopBaseEggs = workspace:FindFirstChild("ChopBaseEggs")
        local myBaseFolder = chopBaseEggs and baseName and chopBaseEggs:FindFirstChild(baseName)

        local readyIds = {}
        if myBaseFolder then
            for _, eggInst in ipairs(myBaseFolder:GetChildren()) do
                local eggId = eggInst:GetAttribute("EggId") or eggInst.Name
                local isReady = eggInst:GetAttribute("Ready") == true
                local readyAt = eggInst:GetAttribute("ReadyAt")
                if not isReady and readyAt and workspace:GetServerTimeNow() >= readyAt then
                    isReady = true
                end
                if isReady and eggId then
                    table.insert(readyIds, eggId)
                end
            end
        end

        local success, res = pcall(function()
            return ChopInventory:InvokeServer("List")
        end)
        if success and type(res) == "table" and res.eggs then
            for _, egg in ipairs(res.eggs) do
                if (egg.ready or (egg.left or 0) <= 0) and egg.id then
                    if not table.find(readyIds, egg.id) then
                        table.insert(readyIds, egg.id)
                    end
                end
            end
        end

        local hatchedCount = 0
        for _, eggId in ipairs(readyIds) do
            local hOk, hRes = pcall(function()
                return ChopInventory:InvokeServer("Hatch", eggId)
            end)
            if hOk and hRes and hRes.ok then
                hatchedCount = hatchedCount + 1
            end
            task.wait(0.06)
        end

        if hatchedCount > 0 then
            UI:SetStatus("เปิดไข่อัตโนมัติสำเร็จ: " .. hatchedCount .. " ฟอง!")
            if S.AutoEquipBest then
                pcall(function()
                    ChopInventory:InvokeServer("EquipBest")
                end)
            end
        end
    end)
    isHatching = false
end

-- Fast instant reaction: Whenever CarryCount reaches max, teleport back to shredder immediately!
mainMaid:GiveTask(LocalPlayer:GetAttributeChangedSignal("CarryCount"):Connect(function()
    if S.AutoDeposit and not isChopping then
        local carry = LocalPlayer:GetAttribute("CarryCount") or 0
        local carryMax = LocalPlayer:GetAttribute("CarryMax") or 2
        if carry >= carryMax and carry > 0 then
            task.spawn(depositAndShred)
        end
    end
end))

local function equipBestAxe()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local equippedTool = char:FindFirstChildOfClass("Tool")
    if equippedTool and equippedTool:GetAttribute("Kind") == "Axe" then
        return equippedTool
    end

    local bestTool = nil
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("Kind") == "Axe" then
            bestTool = tool
            break
        end
    end

    if bestTool then
        hum:EquipTool(bestTool)
        return bestTool
    end

    local fists = LocalPlayer.Backpack:FindFirstChild("Fists") or char:FindFirstChild("Fists")
    if fists and not equippedTool then
        hum:EquipTool(fists)
    end
    return nil
end

local function getBestAreaForAxe()
    local power = LocalPlayer:GetAttribute("AxePower") or 1
    local best = "Forest"
    for _, areaName in ipairs(AREA_ORDER) do
        local reqHp = TreeConfig.AreaHP[areaName] or 10
        if power * 8 >= reqHp then
            best = areaName
        else
            break
        end
    end
    return best
end

local function getActiveAreas()
    local list = {}
    if S.AutoBestArea then
        local best = getBestAreaForAxe()
        table.insert(list, best)
    end
    for _, areaName in ipairs(AREA_ORDER) do
        if S.SelectedAreas[areaName] and not (S.AutoBestArea and areaName == list[1]) then
            table.insert(list, areaName)
        end
    end
    if #list == 0 then
        table.insert(list, getBestAreaForAxe())
    end
    return list
end

local EGG_RARITY_ORDER = {
    "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Eternal"
}

local EGG_RARITY_DISPLAY = {
    Common = "1. Common (ทั่วไป)",
    Rare = "2. Rare (หายาก)",
    Epic = "3. Epic (มหากาพย์)",
    Legendary = "4. Legendary (ตำนาน)",
    Mythic = "5. Mythic (มายา)",
    Secret = "6. Secret (ความลับ)",
    Divine = "7. Divine (เทวะ)",
    Eternal = "8. Eternal (นิรันดร์)",
}

local function getEggRarity(egg)
    local rLabel = egg:FindFirstChild("Rarity", true)
    if rLabel and rLabel:IsA("TextLabel") and rLabel.Text ~= "" then
        return rLabel.Text
    end

    local kind = egg:GetAttribute("EggKind")
    if kind and EggCatalog.ById and EggCatalog.ById[kind] then
        local rNum = EggCatalog.ById[kind].rarity
        if rNum and EggCatalog.Rarities and EggCatalog.Rarities[rNum] then
            return EggCatalog.Rarities[rNum].name
        end
    end

    local lk = egg:GetAttribute("Luck")
    if lk and EggCatalog.RarityFor then
        local rObj = EggCatalog.RarityFor(lk)
        if rObj and rObj.name then
            return rObj.name
        end
    end

    return "Common"
end

local function isEggRarityAllowed(egg)
    if not S.SelectedEggRarities then return true end
    local rarity = getEggRarity(egg)
    return S.SelectedEggRarities[rarity] == true
end

local function pickupNearbyEggs(center, radius)
    local myEggs = workspace:FindFirstChild("MyEggs")
    if not myEggs then return end
    local carryMax = LocalPlayer:GetAttribute("CarryMax") or 2
    local carry = LocalPlayer:GetAttribute("CarryCount") or 0
    if carry >= carryMax then
        if S.AutoDeposit then
            depositAndShred()
        end
        return
    end

    for _, egg in ipairs(myEggs:GetChildren()) do
        if not egg:GetAttribute("Breaking") then
            if not isEggRarityAllowed(egg) then
                continue
            end
            local ePos = egg:GetPivot().Position
            if (ePos - center).Magnitude <= (radius or 45) then
                local eggId = egg:GetAttribute("EggId")
                if eggId then
                    teleportTo(ePos + Vector3.new(0, 2, 0))
                    task.wait(0.22)
                    pcall(function() ChopEggs:InvokeServer("Pickup", eggId) end)
                    task.wait(0.12)
                    carry = LocalPlayer:GetAttribute("CarryCount") or 0
                    if carry >= carryMax then
                        if S.AutoDeposit then
                            depositAndShred()
                        end
                        break
                    end
                end
            end
        end
    end
end

local function autoBuyBestAxe()
    local cash = LocalPlayer:GetAttribute("Cash") or 0
    local snap = nil
    pcall(function() snap = AxeShop:InvokeServer("GetSnapshot", nil) end)
    local owned = snap and snap.state and snap.state.owned or {}
    local equipped = snap and snap.state and snap.state.equipped or ""

    local bestBuy = nil
    local bestOwned = nil

    for _, entry in ipairs(AxeCatalog.Entries) do
        if owned[entry.id] then
            bestOwned = entry
        end
        if entry.cashPrice and entry.cashPrice > 0 and cash >= entry.cashPrice and not owned[entry.id] then
            bestBuy = entry
        end
    end

    if bestBuy then
        local res = nil
        pcall(function() res = AxeShop:InvokeServer("BuyCash", bestBuy.id) end)
        if res and res.ok then
            UI:Notify({
                Title = "ซื้อขวานใหม่สำเร็จ!",
                Text = "ซื้อและสวมใส่ " .. bestBuy.name .. " (Power: " .. tostring(bestBuy.power) .. ")",
                Duration = 4,
            })
            UI:SetStatus("ซื้อขวานใหม่: " .. bestBuy.name)
        end
    elseif bestOwned and bestOwned.id ~= equipped then
        pcall(function() AxeShop:InvokeServer("Equip", bestOwned.id) end)
    end
end

local function autoUpgradeShredder()
    if ChopShredderUpgrade then
        pcall(function() ChopShredderUpgrade:InvokeServer("Cash") end)
    end
end

local function autoUpgradeBase()
    if ChopBaseUpgrade then
        pcall(function() ChopBaseUpgrade:InvokeServer("Upgrade") end)
    end
end

local function autoRebirth()
    if not ChopRebirth then return end
    pcall(function()
        local infoRes = ChopRebirth:InvokeServer("Info")
        if infoRes and infoRes.ok and infoRes.info then
            local info = infoRes.info
            local canRebirth = LocalPlayer:GetAttribute("CanRebirth")
            if canRebirth or info.ready then
                local rRes = ChopRebirth:InvokeServer("Rebirth")
                if rRes and rRes.ok then
                    UI:Notify({
                        Title = "REBIRTH สำเร็จ!",
                        Text = "รีเบิร์ธเพิ่มตัวคูณสำเร็จ! (Rebirths: " .. tostring(LocalPlayer:GetAttribute("Rebirths") or 0) .. ")",
                        Duration = 4,
                    })
                end
            end
        end
    end)
end

local function autoClaimGift()
    if FreeGift and not LocalPlayer:GetAttribute("FreeGiftClaimed") then
        pcall(function() FreeGift:FireServer({ kind = "claim" }) end)
    end
end

-- ------------------------------------------------------------------------------
-- Fly System
-- ------------------------------------------------------------------------------
local flyBodyGyro = nil
local flyBodyVelocity = nil

local function toggleFly(enable)
    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if enable then
        if not flyBodyGyro then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.P = 9e4
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.CFrame = root.CFrame
            flyBodyGyro.Parent = root
        end

        if not flyBodyVelocity then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVelocity.Parent = root
        end

        hum.PlatformStand = true
    else
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        hum.PlatformStand = false
    end
end

mainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if S.FlyOn and flyBodyVelocity and flyBodyGyro then
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDir.Unit * S.FlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end
        flyBodyGyro.CFrame = cam.CFrame
    end
end))

-- ------------------------------------------------------------------------------
-- Physics & Movement Watchers (Noclip, Speed, Jump)
-- ------------------------------------------------------------------------------
mainMaid:GiveTask(RunService.Stepped:Connect(function()
    if S.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
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
-- Dead Trees Cache & Area Mapper from Z Coordinate
-- ------------------------------------------------------------------------------
local deadTrees = {}

pcall(function()
    ChopTrees.OnClientEvent:Connect(function(action, area, treeId)
        if action == "Fell" then
            deadTrees[tostring(area) .. "#" .. tostring(treeId)] = os.clock() + 20
        elseif action == "Regrow" then
            deadTrees[tostring(area) .. "#" .. tostring(treeId)] = nil
        end
    end)
end)

local function getAreaFromZ(z)
    if z >= -125 then return "Forest"
    elseif z >= -275 then return "Autumn"
    elseif z >= -560 then return "Sakura"
    elseif z >= -890 then return "Snow"
    elseif z >= -1280 then return "Desert"
    elseif z >= -1730 then return "Water"
    elseif z >= -2290 then return "Vulcano"
    elseif z >= -2940 then return "Celestial"
    elseif z >= -3740 then return "Void"
    else return "Ghost"
    end
end

local function isTreeStanding(t)
    if not t or not t.Parent then return false end
    local upper = t:FindFirstChild("Upper")
    local trunk = upper and upper:FindFirstChild("Trunk")
    return trunk ~= nil and trunk:IsA("BasePart") and trunk.CollisionGroup == "ChopTrees"
end

local function getClosestAliveTree()
    local activeAreas = getActiveAreas()
    local activeAreaSet = {}
    for _, a in ipairs(activeAreas) do
        activeAreaSet[a] = true
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local myTrees = workspace:FindFirstChild("MyTrees")
    if not myTrees then return nil end

    local best = nil
    local bestDist = math.huge
    local now = os.clock()

    for _, t in ipairs(myTrees:GetChildren()) do
        if isTreeStanding(t) then
            local z = t:GetPivot().Position.Z
            local area = getAreaFromZ(z)
            if activeAreaSet[area] then
                local treeId = t:GetAttribute("TreeId")
                local key = area .. "#" .. tostring(treeId)
                local isDead = (deadTrees[key] and now < deadTrees[key])
                if not isDead then
                    local tPos = t:GetPivot().Position
                    local dist = (tPos - hrp.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = {
                            model = t,
                            area = area,
                            treeId = treeId,
                            key = key,
                            pos = tPos,
                            radius = t:GetAttribute("TrunkRadius") or 2,
                            dist = dist
                        }
                    end
                end
            end
        end
    end

    return best
end

local function getAllowedWildEggs()
    local list = {}
    local myEggs = workspace:FindFirstChild("MyEggs")
    if not myEggs then return list end
    for _, egg in ipairs(myEggs:GetChildren()) do
        local eggId = egg:GetAttribute("EggId")
        if eggId and not egg:GetAttribute("Breaking") and isEggRarityAllowed(egg) then
            table.insert(list, egg)
        end
    end
    return list
end

local function collectAllowedEggsBatch()
    local carryMax = LocalPlayer:GetAttribute("CarryMax") or 2
    local carry = LocalPlayer:GetAttribute("CarryCount") or 0
    if carry >= carryMax then return end

    local allowed = getAllowedWildEggs()
    if #allowed == 0 then return end

    pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", false) end)

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        table.sort(allowed, function(a, b)
            return (a:GetPivot().Position - hrp.Position).Magnitude < (b:GetPivot().Position - hrp.Position).Magnitude
        end)
    end

    for _, egg in ipairs(allowed) do
        if not isScriptAlive() then break end
        carry = LocalPlayer:GetAttribute("CarryCount") or 0
        if carry >= carryMax then break end
        if egg.Parent and not egg:GetAttribute("Breaking") then
            local eggId = egg:GetAttribute("EggId")
            local ePos = egg:GetPivot().Position
            teleportTo(ePos + Vector3.new(0, 2, 0))
            task.wait(0.22)
            pcall(function() ChopEggs:InvokeServer("Pickup", eggId) end)
            task.wait(0.12)
        end
    end
end

-- ------------------------------------------------------------------------------
-- Background Loops: Auto Chop Trees (Native AutoSwing + Locked Standing Check)
-- ------------------------------------------------------------------------------
task.spawn(function()
    while isScriptAlive() do
        if S.AutoChop then
            pcall(function()
                elevate()

                local carryMax = LocalPlayer:GetAttribute("CarryMax") or 2
                local carry = LocalPlayer:GetAttribute("CarryCount") or 0

                -- IMPORTANT: CarryNoTools unequips all tools whenever CarryCount > 0!
                -- If CarryCount > 0, top off with any allowed eggs on ground and deposit immediately so hands are free!
                if carry > 0 then
                    if carry < carryMax then
                        collectAllowedEggsBatch()
                    end
                    depositAndShred()
                    task.wait(0.2)
                    return
                end

                -- If hands are empty, check if enough allowed eggs have accumulated on ground to do a pickup+deposit sweep
                local allowedEggs = getAllowedWildEggs()
                if #allowedEggs > 0 then
                    local srvNow = os.time()
                    pcall(function() srvNow = workspace:GetServerTimeNow() end)
                    local urgentEgg = false
                    for _, e in ipairs(allowedEggs) do
                        local exp = tonumber(e:GetAttribute("ExpireAt"))
                        if exp and (exp - srvNow) < 42 then
                            urgentEgg = true
                            break
                        end
                    end
                    if #allowedEggs >= carryMax or urgentEgg then
                        collectAllowedEggsBatch()
                        if (LocalPlayer:GetAttribute("CarryCount") or 0) > 0 then
                            depositAndShred()
                            task.wait(0.2)
                        end
                        return
                    end
                end

                -- Guarantee Axe is equipped in hand (CarryCount is 0 here!)
                equipBestAxe()

                -- Select the single closest standing tree
                local target = getClosestAliveTree()
                if not target then
                    pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", false) end)
                    task.wait(0.3)
                    return
                end

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- Stand outside trunk collision, within Reach (radius + 3.2 studs) facing the trunk
                local standDist = math.clamp((target.radius or 2) + 3.2, 4.2, 6.8)
                local standPos = target.pos + Vector3.new(0, 2, standDist)
                local lookAtPos = Vector3.new(target.pos.X, standPos.Y, target.pos.Z)

                isChopping = true
                teleportTo(standPos)
                if hrp and hrp.Parent then
                    hrp.CFrame = CFrame.new(standPos, lookAtPos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end

                -- Activate native client AutoSwing so ChopTreesClient carves, animates, fells, and spawns eggs!
                pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", true) end)

                local t0 = os.clock()
                local felled = false
                while isScriptAlive() and S.AutoChop and (os.clock() - t0 < 35) do
                    -- If player picked up an egg mid-chop, break out to deposit so axe can be re-equipped
                    if (LocalPlayer:GetAttribute("CarryCount") or 0) > 0 then
                        break
                    end

                    if not isTreeStanding(target.model) then
                        felled = true
                        deadTrees[target.key] = os.clock() + 18
                        break
                    end

                    equipBestAxe()
                    pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", true) end)

                    char = LocalPlayer.Character
                    hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.Parent then
                        hrp.CFrame = CFrame.new(standPos, lookAtPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end

                    task.wait(0.1)
                end

                if not felled and not isTreeStanding(target.model) then
                    felled = true
                    deadTrees[target.key] = os.clock() + 18
                elseif not felled then
                    -- Timed out on this tree
                    deadTrees[target.key] = os.clock() + 12
                end

                isChopping = false
            end)
        else
            pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", false) end)
        end
        task.wait(0.08)
    end
end)

-- ------------------------------------------------------------------------------
-- Background Loops: Auto Pickup Wild Eggs in Map
-- ------------------------------------------------------------------------------
task.spawn(function()
    while isScriptAlive() do
        if S.AutoPickupWild then
            if S.AutoChop then
                task.wait(0.5)
            else
                pcall(function()
                elevate()
                local carry = LocalPlayer:GetAttribute("CarryCount") or 0
                local carryMax = LocalPlayer:GetAttribute("CarryMax") or 2
                if carry >= carryMax then
                    if S.AutoDeposit then
                        depositAndShred()
                    end
                    task.wait(0.3)
                    return
                end

                local myEggs = workspace:FindFirstChild("MyEggs")
                if myEggs then
                    local eggs = myEggs:GetChildren()
                    for _, egg in ipairs(eggs) do
                        if not S.AutoPickupWild then break end
                        carry = LocalPlayer:GetAttribute("CarryCount") or 0
                        if carry >= carryMax then
                            if S.AutoDeposit then
                                depositAndShred()
                            end
                            break
                        end

                        local eggId = egg:GetAttribute("EggId")
                        if eggId and not egg:GetAttribute("Breaking") then
                            if not isEggRarityAllowed(egg) then
                                continue
                            end
                            local ePos = egg:GetPivot().Position
                            teleportTo(ePos + Vector3.new(0, 2, 0))
                            task.wait(0.14)
                            pcall(function() ChopEggs:InvokeServer("Pickup", eggId) end)
                            task.wait(0.1)
                            carry = LocalPlayer:GetAttribute("CarryCount") or 0
                            if carry >= carryMax then
                                if S.AutoDeposit then
                                    depositAndShred()
                                end
                                break
                            end
                        end
                    end
                end
            end)
            end
        end
        task.wait(0.5)
    end
end)

-- ------------------------------------------------------------------------------
-- Background Loops: Auto Hatch & Base Eggs Listener
-- ------------------------------------------------------------------------------
pcall(function()
    local chopBaseEggs = workspace:WaitForChild("ChopBaseEggs", 5)
    if chopBaseEggs then
        local function bindBaseFolder(folder)
            if folder.Name == (LocalPlayer:GetAttribute("BaseName") or "") then
                local function bindEgg(child)
                    mainMaid:GiveTask(child:GetAttributeChangedSignal("Ready"):Connect(function()
                        if child:GetAttribute("Ready") == true and S.AutoHatch then
                            task.spawn(hatchReadyEggs)
                        end
                    end))
                end
                mainMaid:GiveTask(folder.ChildAdded:Connect(function(child)
                    bindEgg(child)
                    if S.AutoHatch and child:GetAttribute("Ready") == true then
                        task.spawn(hatchReadyEggs)
                    end
                end))
                for _, child in ipairs(folder:GetChildren()) do
                    bindEgg(child)
                end
            end
        end

        mainMaid:GiveTask(chopBaseEggs.ChildAdded:Connect(bindBaseFolder))
        for _, f in ipairs(chopBaseEggs:GetChildren()) do
            bindBaseFolder(f)
        end
    end
end)

mainMaid:GiveTask(task.spawn(function()
    while isScriptAlive() do
        pcall(function()
            if S.AutoHatch then
                hatchReadyEggs()
            end
        end)
        task.wait(1.5)
    end
end))

-- ------------------------------------------------------------------------------
-- Background Loops: Auto Upgrades & Progression
-- ------------------------------------------------------------------------------
task.spawn(function()
    while isScriptAlive() do
        pcall(function()
            elevate()
            if S.AutoBuyAxe then
                autoBuyBestAxe()
            end
            if S.AutoUpgradeShredder then
                autoUpgradeShredder()
            end
            if S.AutoUpgradeBase then
                autoUpgradeBase()
            end
            if S.AutoRebirth then
                autoRebirth()
            end
            if S.AutoClaimGift then
                autoClaimGift()
            end
        end)
        task.wait(1.5)
    end
end)

do
-- ------------------------------------------------------------------------------
-- UI INTERFACE CREATION (2K PRISM Shattered Prism Glass)
-- ------------------------------------------------------------------------------
local farmTab = UI:Tab("FARM")
local eggsTab = UI:Tab("EGGS")
local upgradesTab = UI:Tab("UPGRADES")
local teleportTab = UI:Tab("TELEPORT")
local playerTab = UI:Tab("PLAYER")
local settingsTab = UI:Tab("SETTINGS")

-- ------------------------------------------------------------------------------
-- Tab: FARM
-- ------------------------------------------------------------------------------
local farmSection = farmTab:Section("AUTO CHOPPING")

farmSection:Toggle({
    Name = "ตัดต้นไม้อัตโนมัติ (AUTO CHOP TREES)",
    Default = S.AutoChop,
    Callback = function(val)
        S.AutoChop = val
        if not val then
            pcall(function() LocalPlayer:SetAttribute("AutoSwingEnabled", false) end)
        end
        saveSettings()
        UI:SetStatus("ระบบตัดต้นไม้อัตโนมัติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

farmSection:Toggle({
    Name = "เลือกโซนที่ดีที่สุดอัตโนมัติ (AUTO BEST AREA)",
    Default = S.AutoBestArea,
    Callback = function(val)
        S.AutoBestArea = val
        saveSettings()
        UI:SetStatus("ระบบ Auto Best Area: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

farmSection:Slider({
    Name = "ความเร็วการตี (CHOP DELAY)",
    Min = 30,
    Max = 100,
    Step = 5,
    Default = math.floor(math.max(S.ChopDelay or 0.33, 0.33) * 100),
    Suffix = " cs",
    Callback = function(val)
        S.ChopDelay = math.max(val / 100, 0.30)
        saveSettings()
        UI:SetStatus("ปรับความเร็วการตี: " .. string.format("%.2f", S.ChopDelay) .. " วินาที")
    end,
})

farmSection:Button({
    Name = "วาร์ปไปโซนฟาร์มที่ดีที่สุด (TELEPORT BEST AREA)",
    Callback = function()
        local area = getBestAreaForAxe()
        local coord = AREA_COORDS[area] or AREA_COORDS.Forest
        teleportTo(coord)
        UI:SetStatus("วาร์ปไปยังโซน " .. area .. " สำเร็จ")
    end,
})

local zoneOptions = {}
for _, areaName in ipairs(AREA_ORDER) do
    table.insert(zoneOptions, ZONE_DISPLAY[areaName] or areaName)
end

farmSection:Dropdown({
    Name = "เลือกโซนฟาร์ม (SELECT FARM ZONES)",
    Multi = true,
    Options = zoneOptions,
    Default = (function()
        local def = {}
        for _, areaName in ipairs(AREA_ORDER) do
            local disp = ZONE_DISPLAY[areaName] or areaName
            if S.SelectedAreas[areaName] then
                def[disp] = true
            end
        end
        return def
    end)(),
    Callback = function(selectedMap)
        for _, areaName in ipairs(AREA_ORDER) do
            local disp = ZONE_DISPLAY[areaName] or areaName
            S.SelectedAreas[areaName] = (selectedMap[disp] == true)
        end
        saveSettings()
        local count = 0
        for _, v in pairs(S.SelectedAreas) do if v then count = count + 1 end end
        UI:SetStatus("เลือกโซนฟาร์มแล้ว " .. count .. " โซน")
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: EGGS
-- ------------------------------------------------------------------------------
local eggsSection = eggsTab:Section("COLLECT & DEPOSIT EGGS")

eggsSection:Toggle({
    Name = "เก็บไข่ดรอปในแมพ (AUTO PICKUP WILD EGGS)",
    Default = S.AutoPickupWild,
    Callback = function(val)
        S.AutoPickupWild = val
        saveSettings()
        UI:SetStatus("ระบบเก็บไข่ดรอปในแมพ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

local eggRarityOptions = {}
for _, rName in ipairs(EGG_RARITY_ORDER) do
    table.insert(eggRarityOptions, EGG_RARITY_DISPLAY[rName] or rName)
end

eggsSection:Dropdown({
    Name = "เลือกระดับไข่ที่เก็บ (SELECT EGG RARITIES)",
    Multi = true,
    Options = eggRarityOptions,
    Default = (function()
        local def = {}
        for _, rName in ipairs(EGG_RARITY_ORDER) do
            local disp = EGG_RARITY_DISPLAY[rName] or rName
            if S.SelectedEggRarities and S.SelectedEggRarities[rName] ~= false then
                def[disp] = true
            end
        end
        return def
    end)(),
    Callback = function(selectedMap)
        for _, rName in ipairs(EGG_RARITY_ORDER) do
            local disp = EGG_RARITY_DISPLAY[rName] or rName
            S.SelectedEggRarities[rName] = (selectedMap[disp] == true)
        end
        saveSettings()
        local count = 0
        for _, v in pairs(S.SelectedEggRarities) do if v then count = count + 1 end end
        UI:SetStatus("เลือกระดับไข่ที่เก็บ: " .. count .. " ระดับ")
    end,
})

eggsSection:Toggle({
    Name = "นำไข่เข้าเครื่องบดอัตโนมัติ (AUTO DEPOSIT TO SHREDDER)",
    Default = S.AutoDeposit,
    Callback = function(val)
        S.AutoDeposit = val
        saveSettings()
        UI:SetStatus("ระบบนำไข่เข้าเครื่องบด: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

eggsSection:Button({
    Name = "เทเลพอร์ตกลับบ้านทันที (TELEPORT TO BASE)",
    Callback = function()
        local dropZone = getMyShredderDropZone()
        if dropZone then
            teleportTo(dropZone.Position + Vector3.new(0, 3, 0))
            UI:SetStatus("วาร์ปกลับมายัง Shredder ของบ้านตนเองแล้ว")
        else
            teleportTo(Vector3.new(114, 3, 117))
            UI:SetStatus("วาร์ปกลับฐานแล้ว")
        end
    end,
})

local hatchSection = eggsTab:Section("AUTO HATCH & PETS (ระบบเปิดไข่)")

hatchSection:Toggle({
    Name = "เปิดไข่อัตโนมัติเมื่อพร้อม (AUTO HATCH READY EGGS)",
    Default = S.AutoHatch,
    Callback = function(val)
        S.AutoHatch = val
        saveSettings()
        UI:SetStatus("ระบบเปิดไข่อัตโนมัติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
        if val then
            task.spawn(hatchReadyEggs)
        end
    end,
})

hatchSection:Toggle({
    Name = "สวมใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (AUTO EQUIP BEST)",
    Default = S.AutoEquipBest,
    Callback = function(val)
        S.AutoEquipBest = val
        saveSettings()
        UI:SetStatus("สวมใส่สัตว์เลี้ยงที่ดีที่สุด: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
        if val and ChopInventory then
            pcall(function() ChopInventory:InvokeServer("EquipBest") end)
        end
    end,
})

hatchSection:Button({
    Name = "เปิดไข่ที่พร้อมทั้งหมดทันที (HATCH ALL NOW)",
    Callback = function()
        UI:SetStatus("กำลังเปิดไข่ที่พร้อมทั้งหมด...")
        task.spawn(function()
            hatchReadyEggs()
        end)
    end,
})

hatchSection:Button({
    Name = "สวมใส่สัตว์เลี้ยงที่ดีที่สุดทันที (EQUIP BEST PETS)",
    Callback = function()
        if ChopInventory then
            pcall(function() ChopInventory:InvokeServer("EquipBest") end)
            UI:SetStatus("สวมใส่สัตว์เลี้ยงที่ดีที่สุดเรียบร้อย")
        end
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: UPGRADES
-- ------------------------------------------------------------------------------
local upgradesSection = upgradesTab:Section("AUTO UPGRADE & PROGRESSION")

upgradesSection:Toggle({
    Name = "ซื้อขวานที่ดีที่สุดอัตโนมัติ (AUTO BUY BEST AXE)",
    Default = S.AutoBuyAxe,
    Callback = function(val)
        S.AutoBuyAxe = val
        saveSettings()
        UI:SetStatus("ระบบซื้อขวานอัตโนมัติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
        if val then
            task.spawn(autoBuyBestAxe)
        end
    end,
})

upgradesSection:Toggle({
    Name = "อัปเกรดเครื่องบดอัตโนมัติ (AUTO UPGRADE SHREDDER)",
    Default = S.AutoUpgradeShredder,
    Callback = function(val)
        S.AutoUpgradeShredder = val
        saveSettings()
        UI:SetStatus("ระบบอัปเกรดเครื่องบดอัตโนมัติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

upgradesSection:Toggle({
    Name = "อัปเกรดคอกสัตว์อัตโนมัติ (AUTO UPGRADE PEN / BASE)",
    Default = S.AutoUpgradeBase,
    Callback = function(val)
        S.AutoUpgradeBase = val
        saveSettings()
        UI:SetStatus("ระบบอัปเกรดคอกสัตว์อัตโนมัติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

upgradesSection:Toggle({
    Name = "รีเบิร์ธอัตโนมัติ (AUTO REBIRTH)",
    Default = S.AutoRebirth,
    Callback = function(val)
        S.AutoRebirth = val
        saveSettings()
        UI:SetStatus("ระบบรีเบิร์ธอัตโนมัติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

upgradesSection:Toggle({
    Name = "รับของขวัญฟรีอัตโนมัติ (AUTO CLAIM FREE GIFT)",
    Default = S.AutoClaimGift,
    Callback = function(val)
        S.AutoClaimGift = val
        saveSettings()
        UI:SetStatus("ระบบรับของขวัญฟรี: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

upgradesSection:Button({
    Name = "เช็คสถานะรีเบิร์ธ (CHECK REBIRTH INFO)",
    Callback = function()
        pcall(function()
            local infoRes = ChopRebirth:InvokeServer("Info")
            if infoRes and infoRes.ok and infoRes.info then
                local inf = infoRes.info
                UI:Notify({
                    Title = "REBIRTH STATUS",
                    Text = "Rebirths: " .. tostring(inf.rebirths or 0) .. "/" .. tostring(inf.max or 10) .. " | สัตว์ที่ต้องการ: " .. tostring(inf.areaName or "Forest"),
                    Duration = 5,
                })
            end
        end)
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: TELEPORT
-- ------------------------------------------------------------------------------
local teleportSection = teleportTab:Section("WORLD & BASE TELEPORTS")

local chosenTeleport = "บ้านของฉัน (My Base)"

local TELEPORT_LOCATIONS = {
    ["บ้านของฉัน (My Base)"] = function()
        local dropZone = getMyShredderDropZone()
        return dropZone and (dropZone.Position + Vector3.new(0, 3, 0)) or Vector3.new(114, 3, 117)
    end,
    ["ป่าไม้ (Forest)"] = Vector3.new(-5, 4, -60),
    ["ป่าใบไม้เปลี่ยนสี (Autumn Woods)"] = Vector3.new(11, 4, -203),
    ["ป่าซากุระ (Sakura Forest)"] = Vector3.new(-5, 4, -419),
    ["ป่าหิมะ (Snow Forest)"] = Vector3.new(0, 4, -728),
    ["ทะเลทราย (Desert)"] = Vector3.new(-9, 4, -1083),
    ["ดินแดนแห่งน้ำ (Water World)"] = Vector3.new(-2, 4, -1511),
    ["ภูเขาไฟ (Vulcano)"] = Vector3.new(-2, 4, -2004),
    ["สรวงสวรรค์ (Celestial)"] = Vector3.new(1, 4, -2630),
    ["แดนความว่างเปล่า (Void)"] = Vector3.new(3, 4, -3338),
    ["สุสานวิญญาณ (Ghost Graveyard)"] = Vector3.new(3, 4, -4132),
    ["ฐาน Base 1"] = Vector3.new(-114, 3, 117),
    ["ฐาน Base 2"] = Vector3.new(-68, 3, 117),
    ["ฐาน Base 3"] = Vector3.new(-23, 3, 117),
    ["ฐาน Base 4"] = Vector3.new(23, 3, 117),
    ["ฐาน Base 5"] = Vector3.new(68, 3, 117),
    ["ฐาน Base 6"] = Vector3.new(114, 3, 117),
    ["ฐาน Base 7"] = Vector3.new(160, 3, 117),
    ["ฐาน Base 8"] = Vector3.new(206, 3, 117),
}

teleportSection:Dropdown({
    Name = "เลือกสถานที่วาร์ป (SELECT DESTINATION)",
    Options = {
        "บ้านของฉัน (My Base)",
        "ป่าไม้ (Forest)",
        "ป่าใบไม้เปลี่ยนสี (Autumn Woods)",
        "ป่าซากุระ (Sakura Forest)",
        "ป่าหิมะ (Snow Forest)",
        "ทะเลทราย (Desert)",
        "ดินแดนแห่งน้ำ (Water World)",
        "ภูเขาไฟ (Vulcano)",
        "สรวงสวรรค์ (Celestial)",
        "แดนความว่างเปล่า (Void)",
        "สุสานวิญญาณ (Ghost Graveyard)",
        "ฐาน Base 1",
        "ฐาน Base 2",
        "ฐาน Base 3",
        "ฐาน Base 4",
        "ฐาน Base 5",
        "ฐาน Base 6",
        "ฐาน Base 7",
        "ฐาน Base 8",
    },
    Default = chosenTeleport,
    Callback = function(choice)
        chosenTeleport = choice
        UI:SetStatus("เลือกสถานที่: " .. choice)
    end,
})

teleportSection:Button({
    Name = "วาร์ปทันที (TELEPORT NOW)",
    Callback = function()
        local dest = TELEPORT_LOCATIONS[chosenTeleport]
        if type(dest) == "function" then
            dest = dest()
        end
        if dest then
            teleportTo(dest)
            UI:SetStatus("วาร์ปไปยัง " .. chosenTeleport .. " สำเร็จ")
        end
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: PLAYER
-- ------------------------------------------------------------------------------
local playerSection = playerTab:Section("PLAYER MODIFICATIONS")

playerSection:Toggle({
    Name = "เปิดใช้ความเร็วพิเศษ (ENABLE WALKSPEED)",
    Default = S.WalkSpeedOn,
    Callback = function(val)
        S.WalkSpeedOn = val
        saveSettings()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = val and S.WalkSpeed or 16
        end
        UI:SetStatus("ระบบความเร็วพิเศษ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

playerSection:Slider({
    Name = "ระดับความเร็ว (WALKSPEED)",
    Min = 16,
    Max = 150,
    Step = 2,
    Default = S.WalkSpeed,
    Suffix = " spd",
    Callback = function(val)
        S.WalkSpeed = val
        saveSettings()
        if S.WalkSpeedOn then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = val
            end
        end
        UI:SetStatus("ปรับค่า WalkSpeed เป็น: " .. val)
    end,
})

playerSection:Toggle({
    Name = "เปิดใช้พลังกระโดด (ENABLE JUMPPOWER)",
    Default = S.JumpPowerOn,
    Callback = function(val)
        S.JumpPowerOn = val
        saveSettings()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = val and S.JumpPower or 50
        end
        UI:SetStatus("ระบบพลังกระโดด: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

playerSection:Slider({
    Name = "ระดับพลังกระโดด (JUMPPOWER)",
    Min = 50,
    Max = 250,
    Step = 5,
    Default = S.JumpPower,
    Suffix = " pwr",
    Callback = function(val)
        S.JumpPower = val
        saveSettings()
        if S.JumpPowerOn then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = val
            end
        end
        UI:SetStatus("ปรับค่า JumpPower เป็น: " .. val)
    end,
})

playerSection:Toggle({
    Name = "กระโดดไม่จำกัด (INFINITE JUMP)",
    Default = S.InfiniteJump,
    Callback = function(val)
        S.InfiniteJump = val
        saveSettings()
        UI:SetStatus("ระบบ Infinite Jump: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

playerSection:Toggle({
    Name = "เดินทะลุกำแพง (NOCLIP)",
    Default = S.Noclip,
    Callback = function(val)
        S.Noclip = val
        saveSettings()
        UI:SetStatus("ระบบ Noclip: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

playerSection:Toggle({
    Name = "บินอิสระ (FLY MODE)",
    Default = S.FlyOn,
    Callback = function(val)
        S.FlyOn = val
        saveSettings()
        toggleFly(val)
        UI:SetStatus("ระบบ Fly Mode: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

playerSection:Slider({
    Name = "ความเร็วการบิน (FLY SPEED)",
    Min = 20,
    Max = 200,
    Step = 5,
    Default = S.FlySpeed,
    Suffix = " spd",
    Callback = function(val)
        S.FlySpeed = val
        saveSettings()
        UI:SetStatus("ปรับความเร็วการบินเป็น: " .. val)
    end,
})

-- ------------------------------------------------------------------------------
-- Tab: SETTINGS
-- ------------------------------------------------------------------------------
local settingsSection = settingsTab:Section("INTERFACE SETTINGS")

settingsSection:Dropdown({
    Name = "ธีมสี (THEME)",
    Options = { "Ice", "Aurora", "Amethyst", "Magma", "Toxic" },
    Default = CONFIG.Theme,
    Callback = function(themeName)
        if Themes[themeName] then
            CONFIG.Theme = themeName
            currentTheme = Themes[themeName]
            currentColorSequence = makeSequence(currentTheme)
            saveSettings()
            for _, fn in ipairs(accentListeners) do
                pcall(fn, currentTheme, currentColorSequence)
            end
            UI:SetStatus("เปลี่ยนธีมเป็น: " .. themeName)
        end
    end,
})

settingsSection:Slider({
    Name = "ระดับความเบลอ (FROST)",
    Min = 0,
    Max = 24,
    Step = 1,
    Default = UI.Frost,
    Suffix = " px",
    Callback = function(val)
        UI.Frost = val
        saveSettings()
        if blurEffect and UI.Visible then
            blurEffect.Size = val
        end
        UI:SetStatus("ปรับค่าความเบลอพื้นหลังเป็น: " .. val .. " px")
    end,
})

settingsSection:Slider({
    Name = "ความโปร่งใสกระจก (GLASS)",
    Min = 5,
    Max = 70,
    Step = 1,
    Default = math.floor(UI.TintAlpha * 100 + 0.5),
    Suffix = "%",
    Callback = function(val)
        UI.TintAlpha = val / 100
        saveSettings()
        for _, surf in ipairs(allSurfaces) do
            surf.BackgroundTransparency = UI.TintAlpha
        end
        UI:SetStatus("ปรับระดับความเข้มกระจกเป็น: " .. val .. "%")
    end,
})

settingsSection:Toggle({
    Name = "เอฟเฟกต์พารัลแลกซ์ 3 มิติ (PARALLAX)",
    Default = UI.Parallax,
    Callback = function(val)
        UI.Parallax = val
        saveSettings()
        UI:SetStatus("ระบบพารัลแลกซ์ 3 มิติ: " .. (val and "เปิดใช้งาน" or "ปิดการทำงาน"))
    end,
})

settingsSection:Keybind({
    Name = "ปุ่มเปิด/ปิดเมนู (TOGGLE KEY)",
    Default = UI.ToggleKey,
    Changed = function(newKey)
        UI.ToggleKey = newKey
        saveSettings()
        UI:Notify({
            Title = "TOGGLE KEY",
            Text = "เปลี่ยนปุ่มเปิด/ปิดเมนูเป็น " .. newKey.Name,
            Duration = 3,
        })
    end,
})

settingsSection:Button({
    Name = "ทำลายสคริปต์ (DESTROY UI)",
    Callback = function()
        UI:Destroy()
    end,
})
end

UI:Toggle(true)

-- Welcome Toast
UI:Notify({
    Title = "CHOP AND STEAL AN EGG // 2K PRISM",
    Text = "อัปเดต: เอาฟังก์ชันขโมยไข่ออก + วาร์ปกลับ Shredder ทันทีที่ไข่เต็มมือ!",
    Duration = 5,
})

return UI

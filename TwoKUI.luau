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
    titleLbl.TextSize = 18
    titleLbl.TextColor3 = Color3.fromHex("#FFFFFF")
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Size = UDim2.new(1, -44, 0, 20)
    titleLbl.Position = UDim2.new(0, 42, 0, 9)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = brandContainer

    local subTitleLbl = Instance.new("TextLabel")
    subTitleLbl.Name = "SubTitle"
    subTitleLbl.Text = string.upper(SubTitle)
    subTitleLbl.Font = Enum.Font.GothamMedium
    subTitleLbl.TextSize = 9
    subTitleLbl.TextColor3 = Color3.fromHex("#38BDF8")
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

    -- Draggable Logic for Topbar
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

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
    dNameLbl.TextSize = 12
    dNameLbl.TextColor3 = Color3.fromHex("#FFFFFF")
    dNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    dNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    dNameLbl.Size = UDim2.new(1, -60, 0, 16)
    dNameLbl.Position = UDim2.new(0, 56, 0, 8)
    dNameLbl.BackgroundTransparency = 1
    dNameLbl.Parent = profileCard

    local uNameLbl = Instance.new("TextLabel")
    uNameLbl.Name = "Username"
    uNameLbl.Text = "@" .. LocalPlayer.Name
    uNameLbl.Font = Enum.Font.Gotham
    uNameLbl.TextSize = 10
    uNameLbl.TextColor3 = Color3.fromHex("#94A3B8")
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

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = mainFrame

    -- Window Object and Collections
    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        UIScale = uiScale,
        Tabs = {},
        SelectedTab = nil,
        IsOpen = true
    }

    function Window:SetScale(scale)
        uiScale.Scale = math.clamp(scale, 0.5, 1.5)
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

    -- Fullscreen Toggle
    local isMax = false
    local originalSize = Size
    local function toggleMax()
        isMax = not isMax
        if isMax then
            TweenService:Create(mainFrame, TweenInfo.new(0.25), {
                Size = UDim2.new(0.96, 0, 0.94, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.25), {
                Size = originalSize,
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

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isResizing = false
                    TweenService:Create(gripVisual, TweenInfo.new(0.2), {
                        ImageColor3 = Color3.fromHex("#00E5FF"),
                        ImageTransparency = 0.4
                    }):Play()
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local deltaX = input.Position.X - resizeStartMouse.X
            local deltaY = input.Position.Y - resizeStartMouse.Y

            local newW = math.clamp(resizeStartSize.X + deltaX, 620, 1400)
            local newH = math.clamp(resizeStartSize.Y + deltaY, 390, 900)

            mainFrame.Size = UDim2.fromOffset(newW, newH)
            originalSize = mainFrame.Size
        end
    end)

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
        tTitle.TextSize = 13
        tTitle.TextColor3 = Color3.fromHex("#CBD5E1")
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
            hTitle.TextSize = 14
            hTitle.TextColor3 = Color3.fromHex("#FFFFFF")
            hTitle.TextXAlignment = Enum.TextXAlignment.Left
            hTitle.Size = UDim2.new(1, -44, 0, 18)
            hTitle.Position = UDim2.new(0, 42, 0, 0)
            hTitle.BackgroundTransparency = 1
            hTitle.Parent = headerFrame

            local hDesc = Instance.new("TextLabel")
            hDesc.Name = "Desc"
            hDesc.Text = secDesc
            hDesc.Font = Enum.Font.Gotham
            hDesc.TextSize = 11
            hDesc.TextColor3 = Color3.fromHex("#94A3B8")
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
                t.TextSize = 13
                t.TextColor3 = Color3.fromHex("#FFFFFF")
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.Size = UDim2.new(1, -(52 + rightOffset), 0, desc and 18 or 28)
                t.Position = UDim2.new(0, 48, 0.5, desc and -16 or -14)
                t.BackgroundTransparency = 1
                t.Parent = row

                if desc and desc ~= "" then
                    local d = Instance.new("TextLabel")
                    d.Text = desc
                    d.Font = Enum.Font.GothamBold
                    d.TextSize = 10
                    d.TextColor3 = Color3.fromHex("#CBD5E1")
                    d.TextXAlignment = Enum.TextXAlignment.Left
                    d.Size = UDim2.new(1, -(52 + rightOffset), 0, 14)
                    d.Position = UDim2.new(0, 48, 0.5, 2)
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

                local function updateToggle(newVal)
                    val = newVal
                    local targetColor = val and Color3.fromHex("#00E5FF") or Color3.fromHex("#1E293B")
                    local targetPos = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { BackgroundColor3 = targetColor }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = targetPos }):Play()
                    task.spawn(callback, val)
                end

                rowClick.MouseButton1Click:Connect(function()
                    updateToggle(not val)
                end)
                pill.MouseButton1Click:Connect(function()
                    updateToggle(not val)
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

                return {
                    SetValue = updateToggle,
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
                numBadge.TextSize = 11
                numBadge.TextColor3 = Color3.fromHex("#00E5FF")
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

                return {
                    SetValue = function(v)
                        curVal = math.clamp(v, minVal, maxVal)
                        local alpha = (curVal - minVal) / (maxVal - minVal)
                        numBadge.Text = tostring(curVal)
                        fill.Size = UDim2.new(alpha, 0, 1, 0)
                        thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
                        task.spawn(callback, curVal)
                    end
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
                    curVal = curVal or values[1] or ""
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
                    if not isMulti then return tostring(curVal) end
                    local count = 0
                    local selList = {}
                    for _, opt in ipairs(values) do
                        if curVal[opt] == true then
                            count = count + 1
                            table.insert(selList, opt)
                        end
                    end
                    if count == 0 then
                        return "None Selected"
                    elseif count == 1 then
                        return selList[1]
                    elseif count == 2 then
                        return selList[1] .. ", " .. selList[2]
                    else
                        return tostring(count) .. " Selected"
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

                -- Subtle Divider Line when opened
                local divider = Instance.new("Frame")
                divider.Name = "Divider"
                divider.Size = UDim2.new(1, -20, 0, 1)
                divider.Position = UDim2.new(0, 10, 0, 51)
                divider.BackgroundColor3 = Color3.fromHex("#00E5FF")
                divider.BackgroundTransparency = 0.8
                divider.BorderSizePixel = 0
                divider.Visible = false
                divider.Parent = row

                -- In-flow Options Tray (ScrollingFrame)
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
                            isSel = (curVal[item.Value] == true)
                        else
                            isSel = (item.Value == curVal)
                        end

                        item.Btn.BackgroundColor3 = isSel and Color3.fromHex("#0284C7") or Color3.fromHex("#061528")
                        item.Btn.BackgroundTransparency = isSel and 0.15 or 0.4
                        item.Btn.TextColor3 = isSel and Color3.fromHex("#00FFFF") or Color3.fromHex("#CBD5E1")
                        item.Btn.Text = (isSel and " ✓  " or "    ") .. tostring(item.Value)
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
                            isSel = (curVal[opt] == true)
                        else
                            isSel = (opt == curVal)
                        end

                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, -4, 0, itemHeight)
                        optBtn.BackgroundColor3 = isSel and Color3.fromHex("#0284C7") or Color3.fromHex("#061528")
                        optBtn.BackgroundTransparency = isSel and 0.15 or 0.4
                        optBtn.Text = (isSel and " ✓  " or "    ") .. tostring(opt)
                        optBtn.Font = Enum.Font.GothamMedium
                        optBtn.TextSize = 12
                        optBtn.TextColor3 = isSel and Color3.fromHex("#00FFFF") or Color3.fromHex("#CBD5E1")
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
                            local currentlySel = isMulti and (curVal[opt] == true) or (opt == curVal)
                            if not currentlySel then
                                TweenService:Create(optBtn, TweenInfo.new(0.15), {
                                    BackgroundColor3 = Color3.fromHex("#0D2545"),
                                    TextColor3 = Color3.fromHex("#FFFFFF")
                                }):Play()
                            end
                        end)

                        optBtn.MouseLeave:Connect(function()
                            local currentlySel = isMulti and (curVal[opt] == true) or (opt == curVal)
                            if not currentlySel then
                                TweenService:Create(optBtn, TweenInfo.new(0.15), {
                                    BackgroundColor3 = Color3.fromHex("#061528"),
                                    TextColor3 = Color3.fromHex("#CBD5E1")
                                }):Play()
                            end
                        end)

                        optBtn.MouseButton1Click:Connect(function()
                            if isMulti then
                                curVal[opt] = not curVal[opt]
                                lbl.Text = getDisplayText()
                                updateSelectionHighlight()
                                task.spawn(callback, curVal)
                            else
                                curVal = opt
                                lbl.Text = tostring(curVal)
                                updateSelectionHighlight()
                                toggleMenu()
                                task.spawn(callback, curVal)
                            end
                        end)
                    end
                end

                renderOptions(values)

                return {
                    SetValue = function(v)
                        if isMulti then
                            if type(v) == "table" then
                                curVal = v
                            end
                            lbl.Text = getDisplayText()
                        else
                            curVal = v
                            lbl.Text = tostring(v)
                        end
                        updateSelectionHighlight()
                        task.spawn(callback, curVal)
                    end,
                    SetValues = renderOptions,
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
                actBtn.TextSize = 11
                actBtn.TextColor3 = Color3.fromHex("#FFFFFF")
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

                return {
                    GetValue = function() return tBox.Text end,
                    SetValue = function(v) tBox.Text = tostring(v) end,
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
    auraFrame.Size = UDim2.fromOffset(62, 62)
    auraFrame.Position = UDim2.new(0, 46, 0.45, 0)
    auraFrame.BackgroundColor3 = Color3.fromHex("#00E5FF")
    auraFrame.BackgroundTransparency = 0.82
    auraFrame.BorderSizePixel = 0
    auraFrame.Parent = floatGui

    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(0, 20)
    auraCorner.Parent = auraFrame

    local auraStroke = Instance.new("UIStroke")
    auraStroke.Color = Color3.fromHex("#00D4FF")
    auraStroke.Thickness = 1.2
    auraStroke.Transparency = 0.65
    auraStroke.Parent = auraFrame

    local panelFrame = Instance.new("Frame")
    panelFrame.Name = "LogoPanel"
    panelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    panelFrame.Size = UDim2.fromOffset(52, 52)
    panelFrame.Position = UDim2.new(0, 46, 0.45, 0)
    panelFrame.BackgroundColor3 = Color3.fromHex("#060E18")
    panelFrame.BackgroundTransparency = 0.15
    panelFrame.BorderSizePixel = 0
    panelFrame.Parent = floatGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 16)
    panelCorner.Parent = panelFrame

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromHex("#00E5FF")
    panelStroke.Thickness = 2.2
    panelStroke.Parent = panelFrame

    local panelGrad = Instance.new("UIGradient")
    panelGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHex("#00E5FF")),
        ColorSequenceKeypoint.new(0.35, Color3.fromHex("#0077FE")),
        ColorSequenceKeypoint.new(0.70, Color3.fromHex("#38BDF8")),
        ColorSequenceKeypoint.new(1.00, Color3.fromHex("#00E5FF"))
    })
    panelGrad.Parent = panelStroke

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

    -- Draggable Floating Badge
    local fDragging, fDragStart, fStartPos
    local function onFloatDragStart(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fDragging = true
            fDragStart = input.Position
            fStartPos = panelFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then fDragging = false end
            end)
        end
    end
    panelFrame.InputBegan:Connect(onFloatDragStart)
    floatBtn.InputBegan:Connect(onFloatDragStart)

    UserInputService.InputChanged:Connect(function(input)
        if fDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - fDragStart
            local newPos = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + delta.X, fStartPos.Y.Scale, fStartPos.Y.Offset + delta.Y)
            panelFrame.Position = newPos
            auraFrame.Position = newPos
        end
    end)

    floatBtn.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)

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
        local auraSize = 60 + (breath * 10)
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

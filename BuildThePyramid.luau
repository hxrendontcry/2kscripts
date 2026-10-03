-- [[ 2K SCRIPT - BUILD THE PYRAMID MASTER AUTO FARM & GYM HUB ]] --
-- Game: Build the Pyramid! - PlaceId: 123720558354386
-- UI Engine: WindUI Amber Gold (Desert Pharaoh Edition) + macOS 3-Dots + Responsive Mobile & PC Layout
-- Developed by cook45 for clack

local myToken = tick()
_G.TwoSkiActivePyramidToken = myToken

if _G.TwoSkiPyramidCleanup then
    pcall(_G.TwoSkiPyramidCleanup)
    task.wait(0.2)
end

_G.TwoSkiActivePyramidToken = myToken
_G.TwoSkiPyramidRunning = true
_G.TwoSkiPyramidLoaded = false

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

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.05)
    LocalPlayer = Players.LocalPlayer
end

-- Mobile Diagnostics
local isTouchDevice = UserInputService.TouchEnabled
local isMobile = isTouchDevice and (not UserInputService.KeyboardEnabled or isTouchDevice)

-- ─────────────────────────────────────────────────────────────
-- TELEMETRY & EXECUTION LOGGER (2K SCRIPT LIVE DASHBOARD)
-- ─────────────────────────────────────────────────────────────
local SCRIPT_START_TICK = tick()
local SCRIPT_START_TIME = os.time()

local function sendTelemetry(action, details)
    task.spawn(function()
        pcall(function()
            local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
            if not requestFunc then return end

            local execName = "Unknown"
            pcall(function()
                execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Executor"
            end)

            local currentUptime = math.max(0, math.floor(tick() - SCRIPT_START_TICK))

            local payload = {
                userId = LocalPlayer.UserId,
                username = LocalPlayer.Name,
                displayName = LocalPlayer.DisplayName,
                placeId = game.PlaceId or 123720558354386,
                gameName = "Build the Pyramid!",
                executor = execName,
                action = action or "execute",
                uptime = currentUptime,
                sessionStart = math.floor(SCRIPT_START_TIME * 1000),
                details = details or {}
            }

            local endpoints = {
                "https://2k-telemetry-dashboard.vercel.app/api/telemetry",
                "http://localhost:3000/api/telemetry"
            }

            for _, ep in ipairs(endpoints) do
                pcall(function()
                    requestFunc({
                        Url = ep,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["x-2k-signature"] = "2k-sec-v3-e8a9f2"
                        },
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
            end
        end)
    end)
end

-- Fire initial execute event
sendTelemetry("execute", { title = "Build the Pyramid!", version = "1.0", firstLaunch = tick() })

-- Heartbeat Watchdog: ping dashboard every 30s to maintain ONLINE status & history
task.spawn(function()
    while task.wait(30) do
        if not _G.TwoSkiPyramidRunning or _G.TwoSkiActivePyramidToken ~= myToken then break end
        sendTelemetry("heartbeat", { ping = true })
    end
end)

-- Knit Client Services Resolver
local KnitClientServices = nil
pcall(function()
    KnitClientServices = require(ReplicatedStorage.Shared.KnitClientServices)
end)

local function getServices()
    if KnitClientServices and KnitClientServices.get then
        return KnitClientServices.get()
    end
    return nil
end

-- Safe Module Require Helper
local function safeRequire(pathTbl)
    local cur = ReplicatedStorage
    for _, name in ipairs(pathTbl) do
        if not cur or not cur:FindFirstChild(name) then return nil end
        cur = cur:FindFirstChild(name)
    end
    if cur and cur:IsA("ModuleScript") then
        local ok, mod = pcall(require, cur)
        if ok then return mod end
    end
    return nil
end

local RegionRegistry   = safeRequire({"Shared", "RegionRegistry"}) or {}
local PyramidRuntime   = safeRequire({"Shared", "Placement", "PyramidRuntime"}) or {}
local PyramidConfig    = safeRequire({"Shared", "Config", "PyramidConfig"}) or {}
local CarryState       = safeRequire({"Shared", "Books", "CarryState"}) or {}
local PlacementRange   = safeRequire({"Shared", "Placement", "PlacementRange"}) or {}
local PyramidState     = safeRequire({"Shared", "Placement", "PyramidState"}) or safeRequire({"Shared", "Config", "PyramidRollPolicyConfig"}) or {}
local CompletionConfig = safeRequire({"Shared", "Config", "PyramidCompletionConfig"}) or safeRequire({"Shared", "Config", "CompletionConfig"}) or {}

-- Knit Remote Function / Remote Event direct reference fallbacks
local KnitPackages = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index")
local KnitFolder = KnitPackages and KnitPackages:FindFirstChild("sleitnick_knit@1.7.0") and KnitPackages["sleitnick_knit@1.7.0"].knit.Services

local function getRF(serviceName, methodName)
    local s = getServices()
    if s and s[serviceName] and s[serviceName][methodName] then
        return s[serviceName]
    end
    if KnitFolder and KnitFolder:FindFirstChild(serviceName) then
        local rfFolder = KnitFolder[serviceName]:FindFirstChild("RF")
        if rfFolder and rfFolder:FindFirstChild(methodName) then
            return rfFolder[methodName]
        end
    end
    return nil
end

-- Client Interaction Runtime & Policies
local InteractionRuntime = nil
local function runtimeInstance()
    local ok, Knit = pcall(require, ReplicatedStorage.Packages.Knit)
    if not ok then return nil, nil end
    local okG, ctrl = pcall(Knit.GetController, "InteractionController")
    if not InteractionRuntime then
        pcall(function()
            InteractionRuntime = require(LocalPlayer.PlayerScripts.Utils.Interaction.InteractionRuntime)
        end)
    end
    if not okG or type(ctrl) ~= "table" then return nil, InteractionRuntime end
    return ctrl._runtime, InteractionRuntime
end

-- Accurate Live Carry State & Inventory Detection
local canonCarry, canonAt = nil, 0
local function refreshCanonCarry()
    if os.clock() - canonAt < 0.25 then return canonCarry end
    canonAt = os.clock()
    local ok, snap = pcall(CarryState.read, LocalPlayer)
    if ok and type(snap) == "table" and type(snap.count) == "number" then canonCarry = snap.count end
    return canonCarry
end

local function getCarryCount()
    local n = refreshCanonCarry()
    if type(n) == "number" then return n end
    local raw = LocalPlayer:GetAttribute("CarryState")
    if type(raw) == "string" and CarryState and type(CarryState.decode) == "function" then
        local ok, dec = pcall(CarryState.decode, raw)
        if ok and type(dec) == "table" and type(dec.count) == "number" then return dec.count end
    end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local b = ls and ls:FindFirstChild("Blocks")
    if b and type(b.Value) == "number" then return b.Value end
    return LocalPlayer:GetAttribute("CarriedCount") or 0
end

local function getCarryCapacity()
    local rt, irt = runtimeInstance()
    if irt and type(irt.getCarryCapacityPolicy) == "function" then
        local ok, policy = pcall(irt.getCarryCapacityPolicy, LocalPlayer)
        if ok and type(policy) == "table" then
            if policy.isUnlimited then return 9999 end
            if type(policy.capacity) == "number" and policy.capacity > 0 then return policy.capacity end
        end
    end
    local str = LocalPlayer:GetAttribute("StrengthLevel") or 1
    return math.clamp(str + 2, 2, 60)
end

local function isPyramidComplete()
    if PyramidState and type(PyramidState.get) == "function" then
        local ok, s = pcall(PyramidState.get)
        if ok and s == "Complete" then return true end
    end
    return false
end

local function getPoolInfo()
    if not CompletionConfig or not CompletionConfig.CompletedDisplayName then return nil end
    local model = workspace:FindFirstChild(CompletionConfig.CompletedDisplayName)
    if not model then return nil end
    local remaining = model:GetAttribute(CompletionConfig.BoostAttribute)
    if type(remaining) ~= "number" or remaining <= 0 then return nil end
    local part = model:FindFirstChildWhichIsA("BasePart")
    return { position = part and part.Position or model:GetPivot().Position, remaining = remaining }
end

-- Key Locations in Map
local LOCATIONS = {
    Quarry = Vector3.new(-234.75, 4.0, 38.25),
    PyramidBase = Vector3.new(351.0, 4.5, 42.0),
    PyramidTop = Vector3.new(351.0, 380.0, 42.0),
    Gym = Vector3.new(-12.75, 4.0, -112.0),
    Spawn = Vector3.new(-7.9, 3.5, 49.1),
    Upgrades = Vector3.new(-15.0, 3.5, 75.0),
    Pharaoh = Vector3.new(5.0, 4.0, 10.0),
    Leaderboards = Vector3.new(-60.0, 4.0, 50.0)
}

-- Gym Bench Multiplier Stations
local GYM_STATIONS = {
    ["1x Bench"]   = Vector3.new(-12.75, 4.0, -112.0),
    ["2x Bench"]   = Vector3.new(-32.0, 4.0, -112.0),
    ["5x Bench"]   = Vector3.new(-52.0, 4.0, -112.0),
    ["10x Bench"]  = Vector3.new(-72.0, 4.0, -112.0),
    ["25x Bench"]  = Vector3.new(-92.0, 4.0, -112.0),
    ["50x Bench"]  = Vector3.new(-112.0, 4.0, -112.0),
    ["100x Bench"] = Vector3.new(-132.0, 4.0, -112.0),
    ["250x Bench"] = Vector3.new(-152.0, 4.0, -112.0)
}

-- Character Helpers
local function getCharHrp()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum, hrp
end

-- Safe Teleport / Movement
local function safeTeleport(targetPos)
    local hum, hrp = getCharHrp()
    if not hrp then return false end
    hrp.Velocity = Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2.5, 0))
    return true
end

-- Smooth Tween Teleport
local function smoothTweenTo(targetPos, speed)
    local hum, hrp = getCharHrp()
    if not hrp then return false end
    local distance = (hrp.Position - targetPos).Magnitude
    local dur = distance / (speed or 85)
    dur = math.clamp(dur, 0.2, 5.0)

    local tweenInfo = TweenInfo.new(dur, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, { CFrame = CFrame.new(targetPos + Vector3.new(0, 2.5, 0)) })
    tween:Play()
    tween.Completed:Wait()
    return true
end

-- Spatial & Placement Helpers
local function partPos(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    return inst:GetPivot().Position
end

local function resolvePyramidSlot(rangeDist)
    local hum, hrp = getCharHrp()
    if not hrp then return nil end

    local range = rangeDist or 50
    if PlacementRange and type(PlacementRange.forPlayer) == "function" and PyramidConfig and PyramidConfig.PlaceDistance then
        pcall(function() range = PlacementRange.forPlayer(LocalPlayer, PyramidConfig.PlaceDistance) end)
    end

    if PyramidRuntime and type(PyramidRuntime.resolveSlot) == "function" then
        local ok, slot = pcall(PyramidRuntime.resolveSlot, hrp.Position, workspace, nil, range)
        if ok and slot and slot.part then return slot end

        local pyrModel = (PyramidConfig and PyramidConfig.ModelName and workspace:FindFirstChild(PyramidConfig.ModelName))
            or workspace:FindFirstChild("Pyramid")
        local pyrCenter = (pyrModel and (pyrModel:IsA("BasePart") and pyrModel.Position or pyrModel:GetPivot().Position))
            or LOCATIONS.PyramidBase
        
        local ok2, slot2 = pcall(PyramidRuntime.resolveSlot, pyrCenter, workspace, nil, 600)
        if ok2 and slot2 and slot2.part then return slot2 end
    end

    -- Fallback: iterate pyramid descendants for target slot
    local pyrModel = (PyramidConfig and PyramidConfig.ModelName and workspace:FindFirstChild(PyramidConfig.ModelName))
        or workspace:FindFirstChild("Pyramid")
    if pyrModel then
        for _, part in ipairs(pyrModel:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:find("Slot") or part:GetAttribute("SlotIndex") or part:GetAttribute("Layer")) then
                return {
                    part = part,
                    layer = part:GetAttribute("Layer") or 1,
                    slotIndex = part:GetAttribute("SlotIndex") or 1,
                    generation = part:GetAttribute("Generation") or 0
                }
            end
        end
    end

    return nil
end

local function rpcPickup(quarryPart)
    local svc = getServices()
    if svc and svc.BookService then
        pcall(function()
            local p = svc.BookService:Pickup(quarryPart)
            if type(p) == "table" and type(p.catch) == "function" then p:catch(function() end) end
        end)
        return
    end
    local bs = getRF("BookService", "Pickup")
    if bs then
        pcall(function()
            if bs:IsA("RemoteFunction") then
                bs:InvokeServer(quarryPart)
            elseif type(bs.Pickup) == "function" then
                bs:Pickup(quarryPart)
            end
        end)
    end
end

local function rpcPlace(slot)
    if not slot then return false end
    local svc = getServices()
    if svc and svc.PyramidService then
        pcall(function()
            local p = svc.PyramidService:Place(slot.layer, slot.slotIndex, slot.generation)
            if type(p) == "table" and type(p.catch) == "function" then p:catch(function() end) end
        end)
        return true
    end
    local ps = getRF("PyramidService", "Place")
    if ps then
        pcall(function()
            if ps:IsA("RemoteFunction") then
                ps:InvokeServer(slot.layer, slot.slotIndex, slot.generation)
            elseif type(ps.Place) == "function" then
                ps:Place(slot.layer, slot.slotIndex, slot.generation)
            end
        end)
        return true
    end
    return false
end

-- State Management
local State = {
    -- Auto Pyramid Farm
    AutoBuildLoop          = false,
    FarmMovementMode       = "Fast Teleport",
    FarmDelay              = 0.4,
    AutoPickupOnly         = false,
    AutoPlaceOnly          = false,
    InstantPlaceRange      = true,
    
    -- Auto Gym & Training
    AutoGymTrain           = false,
    SelectedGymStation     = "1x Bench",
    AutoSwitchBestBench    = true,

    -- Auto Upgrades & Rewards
    AutoUpgradePickup      = false,
    AutoUpgradePlace       = false,
    AutoUpgradeRange       = false,
    AutoSpendBanked        = false,
    AutoClaimGifts         = false,
    AutoRedeemCodes        = false,

    -- Character & Movement
    WalkSpeedEnabled       = false,
    CustomWalkSpeed        = 32,
    JumpPowerEnabled       = false,
    CustomJumpPower        = 75,
    InfiniteJump           = false,
    Noclip                 = false,
    AntiFall               = true,
    AntiAFK                = true
}

-- Safe GUI Container Resolver
local getgenv_fn = getgenv or function() return _G end
local env = getgenv_fn()
local function getSafeGuiContainer()
    if env.gethui then
        local ok, h = pcall(env.gethui)
        if ok and h and typeof(h) == "Instance" then return h end
    end
    if CoreGui then
        local ok, r = pcall(function() return CoreGui:FindFirstChild("RobloxGui") end)
        if ok and r then return r end
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui", 10)
end

-- Clean up any previous Window and leftover ScreenGuis safely before loading
pcall(function()
    local container = getSafeGuiContainer()
    if container then
        for _, c in ipairs(container:GetChildren()) do
            if c.Name == "WindUI" or c.Name == "TwoK_UI_Screen" or c.Name == "TwoK_Pyramid_Float" then
                pcall(function() c:Destroy() end)
            end
        end
    end
end)

-- Load TwoKUI Proprietary Cyber-Neon Engine
local TwoKUI = nil
pcall(function()
    if isfile and isfile("TwoKUI.luau") and readfile then
        local code = readfile("TwoKUI.luau")
        if code and #code > 1000 then
            TwoKUI = loadstring(code)()
            return
        end
    end

    local code = game:HttpGet("https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/TwoKUI.luau")
    if code and #code > 1000 then
        if writefile then pcall(function() writefile("TwoKUI.luau", code) end) end
        TwoKUI = loadstring(code)()
    end
end)

if not TwoKUI then
    warn("[2K SCRIPT] Failed to initialize TwoKUI engine.")
    return
end

-- Backward compatibility alias
local WindUI = TwoKUI

-- Calculate responsive UI window dimensions
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
local winWidth = isMobile and math.clamp(math.floor(vp.X * 0.95), 360, 720) or 880
local winHeight = isMobile and math.clamp(math.floor(vp.Y * 0.90), 280, 480) or 520

local Window = TwoKUI:CreateWindow({
    Title = "2K Script",
    SubTitle = "Build the Pyramid! Edition",
    Size = UDim2.fromOffset(winWidth, winHeight),
    Keybind = Enum.KeyCode.LeftControl
})

-- ─────────────────────────────────────────────────────────────
-- TABS CREATION (PURE SVG LUCIDE ICONS)
-- ─────────────────────────────────────────────────────────────

local TabDashboard = Window:Tab({ Title = "แดชบอร์ด", Icon = "layout-dashboard" })
local TabPyramid   = Window:Tab({ Title = "สร้างพีระมิด", Icon = "mountain" })
local TabGym       = Window:Tab({ Title = "ยิม & พลัง", Icon = "dumbbell" })
local TabUpgrades  = Window:Tab({ Title = "อัปเกรด & โค้ด", Icon = "zap" })
local TabPlayer    = Window:Tab({ Title = "ตัวละคร", Icon = "user" })
local TabTeleport  = Window:Tab({ Title = "จุดวาร์ป", Icon = "map-pin" })
local TabSettings  = Window:Tab({ Title = "ตั้งค่า", Icon = "settings" })

-- ─────────────────────────────────────────────────────────────
-- TAB 1: แดชบอร์ด & สถิติสด (DASHBOARD)
-- ─────────────────────────────────────────────────────────────
TabDashboard:Section({ Title = "สถิติตัวละครสด (Live Stats)", Icon = "activity" })

local statParagraph = TabDashboard:Paragraph({
    Title = "กำลังโหลดข้อมูลตัวละคร...",
    Desc = "รอซิงค์ข้อมูลจากเซิร์ฟเวอร์สักครู่",
    Icon = "chart-column"
})

task.spawn(function()
    while task.wait(1.5) do
        if not _G.TwoSkiPyramidRunning or _G.TwoSkiActivePyramidToken ~= myToken then break end
        pcall(function()
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            local strength = (ls and ls:FindFirstChild("Strength") and ls.Strength.Value) or LocalPlayer:GetAttribute("StrengthLevel") or 0
            local speed = (ls and ls:FindFirstChild("Speed") and ls.Speed.Value) or LocalPlayer:GetAttribute("SpeedLevel") or 0
            local blocks = getCarryCount()
            local cap = getCarryCapacity()
            local pyramids = (ls and ls:FindFirstChild("Pyramids") and ls.Pyramids.Value) or 0
            local bankedSec = LocalPlayer:GetAttribute("BankedSeconds") or 0

            statParagraph:SetTitle(string.format("บล็อกที่ถือ: %s / %s | พีระมิดที่สร้าง: %s", tostring(blocks), tostring(cap), tostring(pyramids)))
            statParagraph:SetDesc(string.format("Strength: %s  |  Speed: %s  |  เวลาสะสม: %s วิ", tostring(strength), tostring(speed), tostring(bankedSec)))
        end)
    end
end)

TabDashboard:Section({ Title = "ทางลัดด่วน (Quick Actions)", Icon = "sparkles" })

TabDashboard:Button({
    Title = "หยิบหินเต็มความจุทันที (Instant Max Pickup)",
    Desc = "วาร์ปไป Quarry แล้วดูดหินจนเต็มอัตโนมัติ",
    Icon = "box",
    Callback = function()
        task.spawn(function()
            safeTeleport(LOCATIONS.Quarry)
            task.wait(0.2)
            local qPart = (RegionRegistry and RegionRegistry.getPart and RegionRegistry.getPart("Quarry"))
                or workspace:FindFirstChild("Quarry")
            if not qPart and RegionRegistry and RegionRegistry.Ids and RegionRegistry.Ids.Quarry then
                local reg = workspace:FindFirstChild(RegionRegistry.Ids.Quarry)
                qPart = reg and reg:FindFirstChildWhichIsA("BasePart")
            end
            local cap = getCarryCapacity()
            for i = 1, 25 do
                if getCarryCount() >= cap then break end
                rpcPickup(qPart)
                task.wait(0.08)
            end
            WindUI:Notify({ Title = "2K SCRIPT", Content = "หยิบหินเรียบร้อยแล้ว!" })
        end)
    end
})

TabDashboard:Button({
    Title = "วางหินลงพีระมิดทันที (Instant Place Blocks)",
    Desc = "วาร์ปไปจุดสร้างพีระมิดแล้ววางหินทั้งหมด",
    Icon = "layers",
    Callback = function()
        task.spawn(function()
            local rt, irt = runtimeInstance()
            local holding = false
            for i = 1, 35 do
                if getCarryCount() <= 0 or isPyramidComplete() then break end
                local slot = resolvePyramidSlot(120)
                if slot and slot.part then
                    safeTeleport(slot.part.Position + Vector3.new(0, 3, 0))
                    if rt and irt and type(irt.beginPlaceHold) == "function" and not holding then
                        pcall(function() irt.beginPlaceHold(rt) end)
                        holding = true
                    end
                    rpcPlace(slot)
                else
                    safeTeleport(LOCATIONS.PyramidBase)
                    if rt and irt and type(irt.beginPlaceHold) == "function" and not holding then
                        pcall(function() irt.beginPlaceHold(rt) end)
                        holding = true
                    end
                end
                task.wait(0.12)
            end
            if holding and rt and irt and type(irt.endPlaceHold) == "function" then
                pcall(function() irt.endPlaceHold(rt) end)
            end
            WindUI:Notify({ Title = "2K SCRIPT", Content = "วางหินลงพีระมิดเรียบร้อย!" })
        end)
    end
})

-- ─────────────────────────────────────────────────────────────
-- TAB 2: ออโต้สร้างพีระมิด (AUTO BUILD PYRAMID)
-- ─────────────────────────────────────────────────────────────
TabPyramid:Section({ Title = "ระบบลูปฟาร์มอัตโนมัติ (Auto Farm Loop)", Icon = "repeat" })

TabPyramid:Toggle({
    Title = "ออโต้ฟาร์ม & สร้างพีระมิดอัตโนมัติ (Auto Farm & Build)",
    Desc = "หยิบหินจนเต็ม -> เดินทางไปสร้างพีระมิด -> วางหินจนหมด -> วนลูปไม่หยุด",
    Icon = "hammer",
    Value = State.AutoBuildLoop,
    Callback = function(val)
        State.AutoBuildLoop = val
    end
})

TabPyramid:Dropdown({
    Title = "โหมดการเดินทาง (Travel Mode)",
    Icon = "navigation",
    Values = {
        "Fast Teleport (วาร์ปทันที)",
        "Smooth Walk/Tween (เดินนุ่มนวล กันตรวจจับ)"
    },
    Value = State.FarmMovementMode,
    Callback = function(val)
        State.FarmMovementMode = val
    end
})

TabPyramid:Slider({
    Title = "ดีเลย์ระหว่างหยิบ/วาง (Delay Seconds)",
    Icon = "clock",
    Min = 0.1,
    Max = 1.5,
    Default = State.FarmDelay,
    Callback = function(val)
        State.FarmDelay = val
    end
})

TabPyramid:Section({ Title = "ฟังก์ชันเสริม (Auxiliary)", Icon = "sliders-horizontal" })

TabPyramid:Toggle({
    Title = "ออโต้หยิบหินอย่างเดียว (Auto Pickup Only)",
    Desc = "ยืนที่ Quarry แล้วดูดหินตลอดเวลา",
    Icon = "download",
    Value = State.AutoPickupOnly,
    Callback = function(val)
        State.AutoPickupOnly = val
    end
})

TabPyramid:Toggle({
    Title = "ออโต้วางหินอย่างเดียว (Auto Place Only)",
    Desc = "ยืนที่พีระมิดแล้ววางหินอัตโนมัติ",
    Icon = "upload",
    Value = State.AutoPlaceOnly,
    Callback = function(val)
        State.AutoPlaceOnly = val
    end
})

-- Core Auto Farm Background Thread
task.spawn(function()
    while task.wait(0.15) do
        if not _G.TwoSkiPyramidRunning or _G.TwoSkiActivePyramidToken ~= myToken then break end

        if State.AutoBuildLoop then
            pcall(function()
                local qPart = (RegionRegistry and RegionRegistry.getPart and RegionRegistry.getPart("Quarry"))
                    or workspace:FindFirstChild("Quarry")
                if not qPart and RegionRegistry and RegionRegistry.Ids and RegionRegistry.Ids.Quarry then
                    local reg = workspace:FindFirstChild(RegionRegistry.Ids.Quarry)
                    qPart = reg and reg:FindFirstChildWhichIsA("BasePart")
                end

                local carried = getCarryCount()
                local capacity = getCarryCapacity()

                -- Step 1: Pickup blocks if not full
                if carried < capacity and not isPyramidComplete() then
                    if State.FarmMovementMode:find("Teleport") then
                        safeTeleport(LOCATIONS.Quarry)
                    else
                        smoothTweenTo(LOCATIONS.Quarry, 95)
                    end
                    task.wait(State.FarmDelay)

                    local attempts = 0
                    while State.AutoBuildLoop and attempts < 35 do
                        carried = getCarryCount()
                        if carried >= capacity then break end
                        rpcPickup(qPart)
                        attempts = attempts + 1
                        task.wait(0.08)
                    end
                end

                -- Step 2: Place blocks on Pyramid
                carried = getCarryCount()
                if carried > 0 and State.AutoBuildLoop and not isPyramidComplete() then
                    local rt, irt = runtimeInstance()
                    local holding = false
                    local placeAttempts = 0

                    while State.AutoBuildLoop and placeAttempts < 40 do
                        carried = getCarryCount()
                        if carried <= 0 or isPyramidComplete() then break end

                        local slot = resolvePyramidSlot(120)
                        if slot and slot.part then
                            local slotPos = slot.part.Position
                            if State.FarmMovementMode:find("Teleport") then
                                safeTeleport(slotPos + Vector3.new(0, 3, 0))
                            else
                                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and (hrp.Position - slotPos).Magnitude > 35 then
                                    safeTeleport(slotPos + Vector3.new(0, 3, 0))
                                end
                            end

                            if rt and irt and type(irt.beginPlaceHold) == "function" and not holding then
                                pcall(function() irt.beginPlaceHold(rt) end)
                                holding = true
                            end

                            rpcPlace(slot)
                        else
                            safeTeleport(LOCATIONS.PyramidBase)
                            if rt and irt and type(irt.beginPlaceHold) == "function" and not holding then
                                pcall(function() irt.beginPlaceHold(rt) end)
                                holding = true
                            end
                        end

                        placeAttempts = placeAttempts + 1
                        task.wait(State.FarmDelay)
                    end

                    if holding and rt and irt and type(irt.endPlaceHold) == "function" then
                        pcall(function() irt.endPlaceHold(rt) end)
                    end
                end
            end)
        end

        -- Standalone Auto Pickup
        if State.AutoPickupOnly and not State.AutoBuildLoop then
            pcall(function()
                local qPart = (RegionRegistry and RegionRegistry.getPart and RegionRegistry.getPart("Quarry"))
                    or workspace:FindFirstChild("Quarry")
                if not qPart and RegionRegistry and RegionRegistry.Ids and RegionRegistry.Ids.Quarry then
                    local reg = workspace:FindFirstChild(RegionRegistry.Ids.Quarry)
                    qPart = reg and reg:FindFirstChildWhichIsA("BasePart")
                end
                rpcPickup(qPart)
            end)
            task.wait(State.FarmDelay)
        end

        -- Standalone Auto Place
        if State.AutoPlaceOnly and not State.AutoBuildLoop then
            pcall(function()
                local rt, irt = runtimeInstance()
                local slot = resolvePyramidSlot(120)
                if slot and slot.part then
                    safeTeleport(slot.part.Position + Vector3.new(0, 3, 0))
                    if rt and irt and type(irt.beginPlaceHold) == "function" then
                        pcall(function() irt.beginPlaceHold(rt) end)
                    end
                    rpcPlace(slot)
                else
                    safeTeleport(LOCATIONS.PyramidBase)
                    if rt and irt and type(irt.beginPlaceHold) == "function" then
                        pcall(function() irt.beginPlaceHold(rt) end)
                    end
                end
            end)
            task.wait(State.FarmDelay)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- TAB 3: ยิม & เทรนพลัง (GYM & STRENGTH)
-- ─────────────────────────────────────────────────────────────
TabGym:Section({ Title = "ฝึกพลังกล้ามเนื้อ (Strength Training)", Icon = "dumbbell" })

TabGym:Toggle({
    Title = "ออโต้เทรนยกน้ำหนักในยิม (Auto Bench Press)",
    Desc = "วาร์ปไปแท่นยกน้ำหนักแล้วเริ่มเทรนพลัง Strength อัตโนมัติ",
    Icon = "activity",
    Value = State.AutoGymTrain,
    Callback = function(val)
        State.AutoGymTrain = val
        if val then
            task.spawn(function()
                local targetPos = GYM_STATIONS[State.SelectedGymStation] or LOCATIONS.Gym
                safeTeleport(targetPos)
                task.wait(0.3)
                local gs = getRF("GymService", "StartBench")
                if gs then pcall(function() gs:StartBench() end) end
            end)
        else
            local gs = getRF("GymService", "StopBench")
            if gs then pcall(function() gs:StopBench() end) end
        end
    end
})

TabGym:Dropdown({
    Title = "เลือกแท่นยกน้ำหนัก (Bench Multiplier Station)",
    Icon = "trending-up",
    Values = {
        "1x Bench", "2x Bench", "5x Bench", "10x Bench",
        "25x Bench", "50x Bench", "100x Bench", "250x Bench"
    },
    Value = State.SelectedGymStation,
    Callback = function(val)
        State.SelectedGymStation = val
        if State.AutoGymTrain then
            local targetPos = GYM_STATIONS[val] or LOCATIONS.Gym
            safeTeleport(targetPos)
            task.wait(0.2)
            local gs = getRF("GymService", "StartBench")
            if gs then pcall(function() gs:StartBench() end) end
        end
    end
})

TabGym:Button({
    Title = "หยุดยกน้ำหนักทันที (Stop Bench Press)",
    Icon = "square",
    Callback = function()
        State.AutoGymTrain = false
        local gs = getRF("GymService", "StopBench")
        if gs then pcall(function() gs:StopBench() end) end
        WindUI:Notify({ Title = "2K SCRIPT", Content = "หยุดเทรนพลังเรียบร้อย!" })
    end
})

-- ─────────────────────────────────────────────────────────────
-- TAB 4: อัปเกรด & โค้ดฟรี (UPGRADES & CODES)
-- ─────────────────────────────────────────────────────────────
TabUpgrades:Section({ Title = "อัปเกรดอัตโนมัติ (Auto Upgrades)", Icon = "zap" })

TabUpgrades:Toggle({
    Title = "ออโต้อัปเกรด Bulk Pickup (หยิบหินทีละเยอะขึ้น)",
    Icon = "circle-plus",
    Value = State.AutoUpgradePickup,
    Callback = function(val) State.AutoUpgradePickup = val end
})

TabUpgrades:Toggle({
    Title = "ออโต้อัปเกรด Bulk Place (วางหินทีละเยอะขึ้น)",
    Icon = "chevrons-up",
    Value = State.AutoUpgradePlace,
    Callback = function(val) State.AutoUpgradePlace = val end
})

TabUpgrades:Toggle({
    Title = "ออโต้อัปเกรด Placement Range (ระยะวางหินไกลขึ้น)",
    Icon = "maximize-2",
    Value = State.AutoUpgradeRange,
    Callback = function(val) State.AutoUpgradeRange = val end
})

TabUpgrades:Toggle({
    Title = "ออโต้ใช้เวลาและบล็อกสะสม (Spend Banked Resources)",
    Desc = "นำวินาทีสะสมและบล็อกสำรองมาเปลี่ยนเป็นพลังอัตโนมัติ",
    Icon = "clock",
    Value = State.AutoSpendBanked,
    Callback = function(val) State.AutoSpendBanked = val end
})

TabUpgrades:Section({ Title = "ของขวัญ & โค้ดฟรี (Free Gifts & Codes)", Icon = "gift" })

TabUpgrades:Toggle({
    Title = "ออโต้รับของขวัญตามเวลา (Auto Claim Free Gifts)",
    Icon = "package",
    Value = State.AutoClaimGifts,
    Callback = function(val) State.AutoClaimGifts = val end
})

TabUpgrades:Button({
    Title = "รับโค้ดฟรีทั้งหมดของเกม (Redeem All Codes)",
    Desc = "กดรับโค้ดแจกเหรียญและบูสต์ทั้งหมด",
    Icon = "ticket",
    Callback = function()
        task.spawn(function()
            local codes = {
                "RELEASE", "PYRAMID", "BUILD", "UPDATE", "LIKE", "FAVORITE", "DESERT", "PHARAOH"
            }
            local cs = getRF("CodesService", "Redeem")
            local count = 0
            if cs then
                for _, code in ipairs(codes) do
                    pcall(function()
                        cs:Redeem(code)
                        count = count + 1
                    end)
                    task.wait(0.2)
                end
            end
            WindUI:Notify({ Title = "2K SCRIPT", Content = "กดเคลมโค้ดเรียบร้อยแล้ว!" })
        end)
    end
})

-- Upgrades Background Worker
task.spawn(function()
    while task.wait(3.0) do
        if not _G.TwoSkiPyramidRunning or _G.TwoSkiActivePyramidToken ~= myToken then break end

        pcall(function()
            local ds = getRF("DataService", "PurchaseUpgrade")
            if ds then
                if State.AutoUpgradePickup then pcall(function() ds:PurchaseUpgrade("BulkPickup") end) end
                if State.AutoUpgradePlace then pcall(function() ds:PurchaseUpgrade("BulkPlace") end) end
                if State.AutoUpgradeRange then pcall(function() ds:PurchaseUpgrade("PlacementRange") end) end
            end

            local ps = getRF("PyramidService", "SpendBankedSeconds")
            if ps and State.AutoSpendBanked then
                pcall(function() ps:SpendBankedSeconds() end)
                local psBlocks = getRF("PyramidService", "SpendBankedBlocks")
                if psBlocks then pcall(function() psBlocks:SpendBankedBlocks() end) end
            end

            local fg = getRF("FreeGiftService", "Claim")
            if fg and State.AutoClaimGifts then
                for step = 1, 12 do
                    pcall(function() fg:Claim(step) end)
                    task.wait(0.1)
                end
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- TAB 5: ตัวละคร & เคลื่อนที่ (PLAYER & MOVEMENT)
-- ─────────────────────────────────────────────────────────────
TabPlayer:Section({ Title = "ความเร็ว & พลังกระโดด", Icon = "gauge" })

TabPlayer:Toggle({
    Title = "เปิดใช้งานความเร็วเดิน (WalkSpeed Hack)",
    Icon = "wind",
    Value = State.WalkSpeedEnabled,
    Callback = function(val)
        State.WalkSpeedEnabled = val
        local hum = getCharHrp()
        if hum then hum.WalkSpeed = val and State.CustomWalkSpeed or 16 end
    end
})

TabPlayer:Slider({
    Title = "ปรับความเร็วเดิน (WalkSpeed)",
    Icon = "fast-forward",
    Min = 16,
    Max = 250,
    Default = State.CustomWalkSpeed,
    Callback = function(val)
        State.CustomWalkSpeed = val
        if State.WalkSpeedEnabled then
            local hum = getCharHrp()
            if hum then hum.WalkSpeed = val end
        end
    end
})

TabPlayer:Toggle({
    Title = "เปิดใช้งานพลังกระโดด (JumpPower Hack)",
    Icon = "arrow-up",
    Value = State.JumpPowerEnabled,
    Callback = function(val)
        State.JumpPowerEnabled = val
        local hum = getCharHrp()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val and State.CustomJumpPower or 50
        end
    end
})

TabPlayer:Slider({
    Title = "ปรับพลังกระโดด (JumpPower)",
    Icon = "chevron-up",
    Min = 50,
    Max = 300,
    Default = State.CustomJumpPower,
    Callback = function(val)
        State.CustomJumpPower = val
        if State.JumpPowerEnabled then
            local hum = getCharHrp()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = val
            end
        end
    end
})

TabPlayer:Section({ Title = "ฟังก์ชันพิเศษ (Special Exploits)", Icon = "shield-alert" })

TabPlayer:Toggle({
    Title = "กระโดดกลางอากาศไม่จำกัด (Infinite Jump)",
    Icon = "chevrons-up",
    Value = State.InfiniteJump,
    Callback = function(val) State.InfiniteJump = val end
})

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getCharHrp()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

TabPlayer:Toggle({
    Title = "เดินทะลุกำแพง (Noclip)",
    Icon = "ghost",
    Value = State.Noclip,
    Callback = function(val) State.Noclip = val end
})

RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

TabPlayer:Toggle({
    Title = "กันตกแมพและตกพีระมิดตาย (Anti-Fall Guard)",
    Desc = "ถ้าตกลงไปต่ำกว่าระดับพื้น จะดีดกลับขึ้นมาทันที",
    Icon = "shield-check",
    Value = State.AntiFall,
    Callback = function(val) State.AntiFall = val end
})

task.spawn(function()
    while task.wait(0.5) do
        if not _G.TwoSkiPyramidRunning or _G.TwoSkiActivePyramidToken ~= myToken then break end
        if State.AntiFall then
            local _, hrp = getCharHrp()
            if hrp and hrp.Position.Y < -5.0 then
                safeTeleport(LOCATIONS.Spawn)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- TAB 6: จุดวาร์ปสำคัญ (TELEPORTS)
-- ─────────────────────────────────────────────────────────────
TabTeleport:Section({ Title = "วาร์ปสถานที่ต่างๆ ในแมพ", Icon = "map" })

TabTeleport:Button({
    Title = "วาร์ปไป Quarry (จุดหยิบหิน)",
    Icon = "box",
    Callback = function() safeTeleport(LOCATIONS.Quarry) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Pyramid Base (ฐานพีระมิด)",
    Icon = "mountain",
    Callback = function() safeTeleport(LOCATIONS.PyramidBase) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Pyramid Top (ยอดพีระมิด)",
    Icon = "flag",
    Callback = function() safeTeleport(LOCATIONS.PyramidTop) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Gym (ยิมยกน้ำหนัก)",
    Icon = "dumbbell",
    Callback = function() safeTeleport(LOCATIONS.Gym) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Spawn (จุดเกิด)",
    Icon = "house",
    Callback = function() safeTeleport(LOCATIONS.Spawn) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Pharaoh (รูปปั้นฟาโรห์)",
    Icon = "crown",
    Callback = function() safeTeleport(LOCATIONS.Pharaoh) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Upgrades Area (แท่นซื้ออัปเกรด)",
    Icon = "circle-arrow-up",
    Callback = function() safeTeleport(LOCATIONS.Upgrades) end
})

TabTeleport:Button({
    Title = "วาร์ปไป Leaderboards (กระดานอันดับ)",
    Icon = "award",
    Callback = function() safeTeleport(LOCATIONS.Leaderboards) end
})

-- ─────────────────────────────────────────────────────────────
-- TAB 7: ตั้งค่า & ธีม (SETTINGS)
-- ─────────────────────────────────────────────────────────────
TabSettings:Section({ Title = "ปรับแต่งธีม UI (Theme Settings)", Icon = "palette" })

TabSettings:Dropdown({
    Title = "เลือกสไตล์สี UI (Select Theme)",
    Icon = "paint-bucket",
    Values = { "Sky", "Midnight", "Indigo", "Amber", "Emerald", "Dark", "Rose" },
    Value = "Sky",
    Callback = function(themeName)
        pcall(function()
            if WindUI and WindUI.SetTheme then
                WindUI:SetTheme(themeName)
            end
        end)
    end
})

TabSettings:Slider({
    Title = "สเกลขนาดหน้าต่าง UI (UI Scale)",
    Desc = "ปรับขนาดอัตราส่วนของหน้าต่าง UI ให้พอดีหน้าจอ (70% - 130%)",
    Icon = "maximize-2",
    Min = 70,
    Max = 130,
    Default = 100,
    Step = 5,
    Callback = function(val)
        pcall(function()
            if Window and Window.SetScale then
                Window:SetScale(val / 100)
            end
        end)
    end
})

-- ─────────────────────────────────────────────────────────────
-- CONFIG MANAGER (ระบบสร้าง, บันทึก, โหลด, และ AUTOLOAD)
-- ─────────────────────────────────────────────────────────────
local CONFIG_FOLDER = "2kscripts_config"
local GAME_CONFIG_FOLDER = "2kscripts_config/pyramid"
local AUTOLOAD_FILE = GAME_CONFIG_FOLDER .. "/autoload.json"

local function ensureConfigDir()
    pcall(function()
        if makefolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        if makefolder and not isfolder(GAME_CONFIG_FOLDER) then makefolder(GAME_CONFIG_FOLDER) end
    end)
end
ensureConfigDir()

local currentConfigName = "default"

local function saveConfig(name)
    name = (name and name ~= "") and name or "default"
    ensureConfigDir()
    local data = {
        AutoBuildLoop = State.AutoBuildLoop,
        AutoPickupOnly = State.AutoPickupOnly,
        AutoPlaceOnly = State.AutoPlaceOnly,
        FarmDelay = State.FarmDelay,
        TravelMode = State.TravelMode,
        SelectedGymStation = State.SelectedGymStation,
        AutoGymTrain = State.AutoGymTrain,
        AutoUpgradePickup = State.AutoUpgradePickup,
        AutoUpgradePlace = State.AutoUpgradePlace,
        AutoUpgradeRange = State.AutoUpgradeRange,
        WalkSpeed = State.WalkSpeed,
        JumpPower = State.JumpPower,
        AntiAFK = State.AntiAFK
    }
    local json = HttpService:JSONEncode(data)
    local path = GAME_CONFIG_FOLDER .. "/" .. name .. ".json"
    if writefile then
        writefile(path, json)
        WindUI:Notify({ Title = "2K SCRIPT", Content = "บันทึก Config '" .. name .. "' สำเร็จ!" })
        return true
    end
    return false
end

local function loadConfig(name)
    name = (name and name ~= "") and name or "default"
    local path = GAME_CONFIG_FOLDER .. "/" .. name .. ".json"
    if isfile and isfile(path) and readfile then
        local raw = readfile(path)
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if State[k] ~= nil then
                    State[k] = v
                end
            end
            WindUI:Notify({ Title = "2K SCRIPT", Content = "โหลด Config '" .. name .. "' สำเร็จ!" })
            return true
        end
    end
    WindUI:Notify({ Title = "2K SCRIPT", Content = "ไม่พบไฟล์ Config '" .. name .. "'!" })
    return false
end

local function getAutoloadConfig()
    if isfile and isfile(AUTOLOAD_FILE) and readfile then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(AUTOLOAD_FILE)) end)
        if ok and type(data) == "table" and data.enabled then
            return data.config or "default"
        end
    end
    return nil
end

local function setAutoload(enabled, name)
    ensureConfigDir()
    local data = { enabled = enabled, config = name or "default" }
    if writefile then
        writefile(AUTOLOAD_FILE, HttpService:JSONEncode(data))
    end
end

-- Check Autoload on execution
task.spawn(function()
    task.wait(0.6)
    local autoCfg = getAutoloadConfig()
    if autoCfg then
        loadConfig(autoCfg)
    end
end)

TabSettings:Section({ Title = "ระบบจัดการคอนฟิก (Config Manager)", Icon = "package" })

local configInput = TabSettings:Input({
    Title = "ชื่อไฟล์ Config (Config Name)",
    Desc = "พิมพ์ชื่อ Config ที่ต้องการสร้าง บันทึก หรือโหลด",
    Icon = "pencil",
    Placeholder = "เช่น default, fast_farm...",
    Default = "default",
    Callback = function(val)
        if val and val ~= "" then currentConfigName = val end
    end
})

TabSettings:Button({
    Title = "บันทึก Config ปัจจุบัน (Save Config)",
    Desc = "บันทึกการตั้งค่าทั้งหมดลงในไฟล์ตามชื่อข้างต้น",
    Icon = "download",
    Callback = function()
        local name = configInput and configInput.GetValue and configInput:GetValue() or currentConfigName
        saveConfig(name)
    end
})

TabSettings:Button({
    Title = "โหลด Config ที่เลือก (Load Config)",
    Desc = "ดึงการตั้งค่าจากไฟล์ Config มาใช้งานทันที",
    Icon = "upload",
    Callback = function()
        local name = configInput and configInput.GetValue and configInput:GetValue() or currentConfigName
        loadConfig(name)
    end
})

local isAutoLoadOn = (getAutoloadConfig() ~= nil)
TabSettings:Toggle({
    Title = "เปิดใช้งาน Autoload อัตโนมัติ (Autoload on Startup)",
    Desc = "โหลด Config ชื่อนี้อัตโนมัติทุกครั้งเมื่อเปิดสคริปต์",
    Icon = "refresh-cw",
    Value = isAutoLoadOn,
    Callback = function(val)
        local name = configInput and configInput.GetValue and configInput:GetValue() or currentConfigName
        setAutoload(val, name)
        WindUI:Notify({
            Title = "2K SCRIPT",
            Content = val and ("เปิด Autoload: '" .. name .. "'") or "ปิด Autoload เรียบร้อย"
        })
    end
})

TabSettings:Section({ Title = "ความปลอดภัย & ระบบ (System)", Icon = "cpu" })

TabSettings:Toggle({
    Title = "ระบบกันหลุดอัตโนมัติ (Anti-AFK)",
    Desc = "ป้องกัน Roblox เตะออกเมื่อเปิดฟาร์มทิ้งไว้นานกว่า 20 นาที",
    Icon = "clock",
    Value = State.AntiAFK,
    Callback = function(val) State.AntiAFK = val end
})

LocalPlayer.Idled:Connect(function()
    if State.AntiAFK and VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

TabSettings:Button({
    Title = "รีเซิร์ฟเวอร์ใหม่ (Rejoin Server)",
    Icon = "refresh-cw",
    Callback = function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
})

TabSettings:Button({
    Title = "ปิดการทำงานสคริปต์ (Unload Hub)",
    Icon = "power",
    Callback = function()
        pcall(function()
            _G.TwoSkiPyramidRunning = false
            if Window and Window.Destroy then Window:Destroy() end
            if Window and Window.FloatGui then Window.FloatGui:Destroy() end
            if Window and Window.AnimationConnection then Window.AnimationConnection:Disconnect() end
        end)
    end
})

-- Cleanup Handler
_G.TwoSkiPyramidCleanup = function()
    pcall(function()
        _G.TwoSkiPyramidRunning = false
        if Window and Window.Destroy then Window:Destroy() end
        if Window and Window.FloatGui then Window.FloatGui:Destroy() end
        if Window and Window.AnimationConnection then Window.AnimationConnection:Disconnect() end
    end)
end

pcall(function()
    if TabDashboard and TabDashboard.Select then
        TabDashboard:Select()
    elseif Window and Window.SelectTab then
        Window:SelectTab(1)
    end
end)

_G.TwoSkiPyramidLoaded = true

WindUI:Notify({
    Title = "2K SCRIPT",
    Content = "โหลดสคริปต์ Build the Pyramid! สำเร็จเรียบร้อย!",
    Duration = 5
})

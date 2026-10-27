--[[
    2K SCRIPT | Durian Garden (สวนทุเรียน)
    PlaceId 91350038154849
    ซ่อน/แสดงเมนู: RightShift หรือปุ่ม 2K
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local lp = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local VERSION = "2.0"

if env.TwoK_DurianGarden then
    pcall(env.TwoK_DurianGarden.Stop)
end

local alive = true
local conns = {}
local function track(c) conns[#conns + 1] = c return c end

----------------------------------------------------------------
-- ตั้งค่า (บันทึกอัตโนมัติ)
----------------------------------------------------------------
local FILE = "2KSCRIPT/DurianGarden.json"
local S = {
    autoHarvest = false,
    autoSell = false,
    sellPercent = 80,
    autoPlant = false,
    plantSeed = "Any",
    autoWater = false,
    waterEvery = 20,
    fruitEsp = false,
    autoBuy = false,
    buySeed = "Kradumthong",
    buyQty = 5,
    buyEvery = 10,
    fertType = "Basic",
    autoUnlock = false,
    gardener = "UncleBoon",
    autoPay = false,
    autoRebirth = false,
    speedOn = false,
    speed = 32,
    jumpOn = false,
    jump = 70,
    infJump = false,
    noclip = false,
    fly = false,
    flySpeed = 60,
    antiAfk = true,
    fullbright = false,
    lowGfx = false,
}

local function loadSettings()
    if not (isfile and readfile) then return end
    local ok, data = pcall(function()
        if isfile(FILE) then return HttpService:JSONDecode(readfile(FILE)) end
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if S[k] ~= nil and type(v) == type(S[k]) then S[k] = v end
        end
    end
    S.autoRebirth = false -- ไม่เปิดการรีเซ็ตความคืบหน้าให้เองตอนเริ่ม
    S.fly = false
end

local saveQueued = false
local function saveSettings()
    if not writefile or saveQueued then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        pcall(function()
            if makefolder and isfolder and not isfolder("2KSCRIPT") then makefolder("2KSCRIPT") end
            writefile(FILE, HttpService:JSONEncode(S))
        end)
    end)
end
loadSettings()

----------------------------------------------------------------
-- ข้อมูลเกม
----------------------------------------------------------------
local Remotes = RS:WaitForChild("Remotes")
local Map = workspace:WaitForChild("Map")
local Shared = RS:WaitForChild("Shared")

local SEEDS = { "Kradumthong", "Chanee", "Puangmanee", "Kanyao", "Nokyip", "Monthong", "OilPalm" }
local SEED_OPTIONS = { "Any", table.unpack(SEEDS) }
local FERTS = { "Basic", "Super", "Mega", "TonicBasic", "TonicSuper", "TonicMega" }
local GARDENERS = { "UncleBoon", "Noi", "BigTong", "Mali" }

local function safeRequire(name)
    local m = Shared:FindFirstChild(name)
    if not m then return end
    local ok, r = pcall(require, m)
    return ok and r or nil
end
local RebirthConfig = safeRequire("RebirthConfig")
local GardenerConfig = safeRequire("GardenerConfig")
if GardenerConfig and GardenerConfig.List then
    local ids = {}
    for _, g in ipairs(GardenerConfig.List) do
        if g.Id then ids[#ids + 1] = g.Id end
    end
    if #ids > 0 then GARDENERS = ids end
end

local function root()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function myBase()
    local id = lp:GetAttribute("BaseId")
    local bases = Map:FindFirstChild("Bases")
    return id and bases and bases:FindFirstChild("Base" .. id)
end

local function posOf(inst)
    if not inst then return end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Attachment") then return inst.WorldPosition end
    if inst:IsA("Model") then return inst:GetPivot().Position end
    local p = inst:FindFirstAncestorWhichIsA("BasePart")
    if p then return p.Position end
    local m = inst:FindFirstAncestorWhichIsA("Model")
    return m and m:GetPivot().Position
end

local function bag()
    return lp:GetAttribute("BagCount") or 0, lp:GetAttribute("BagMax") or 10
end

local function cash()
    local ls = lp:FindFirstChild("leaderstats")
    local c = ls and ls:FindFirstChild("Cash")
    return c and c.Value or 0
end

local function comma(n)
    local s = tostring(math.floor(n))
    local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end

local function firePrompt(p)
    if fireproximityprompt then
        fireproximityprompt(p)
    else
        p:InputHoldBegin()
        task.wait(p.HoldDuration + 0.05)
        p:InputHoldEnd()
    end
end

local status = "ว่าง"
local notify -- กำหนดตอนสร้าง UI

-- ทำงานที่ต้องวาร์ปทีละอย่าง แล้วกลับที่เดิมเสมอ
local busy = false
local function exclusive(fn)
    while busy and alive do task.wait(0.1) end
    if not alive then return false end
    busy = true
    local r = root()
    local home = r and r.CFrame
    local ok, err = pcall(fn)
    local r2 = root()
    if r2 and r2 == r and home then
        r2.CFrame = home
        r2.AssemblyLinearVelocity = Vector3.zero
    end
    busy = false
    if not ok then warn("[2K] " .. tostring(err)) end
    return ok
end

local function tp(pos)
    local r = root()
    if r then
        r.CFrame = CFrame.new(pos)
        r.AssemblyLinearVelocity = Vector3.zero
    end
end

local function itemsRoot()
    local b = myBase()
    return b and (b:FindFirstChild("Items") or b)
end

local function promptsOf(actionText)
    local list, items = {}, itemsRoot()
    if not items then return list end
    for _, d in ipairs(items:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.ActionText == actionText and d.Enabled then
            list[#list + 1] = d
        end
    end
    return list
end
local function ripePrompts() return promptsOf("Harvest") end
local function emptySpots() return promptsOf("Plant Seed") end

local function grownSpots()
    local list, items = {}, itemsRoot()
    if not items then return list end
    for _, d in ipairs(items:GetDescendants()) do
        if d.Name == "PlantSpot" and d:IsA("BasePart") and d.Parent
            and (d.Parent:FindFirstChild("Tree") or d.Parent:FindFirstChild("Seed")) then
            list[#list + 1] = d
        end
    end
    return list
end

local function findTool(pred)
    local c = lp.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and pred(t) then return t end
        end
    end
    for _, t in ipairs(lp.Backpack:GetChildren()) do
        if t:IsA("Tool") and pred(t) then return t end
    end
end

local function equip(tool)
    local h = humanoid()
    if tool and h and tool.Parent ~= lp.Character then
        h:EquipTool(tool)
        task.wait(0.3)
    end
    return tool
end

local function seedTool(id)
    return findTool(function(t)
        if not t.Name:find("Seed") then return false end
        if id == "Any" then return true end
        return t:GetAttribute("SeedId") == id or t.Name:find(id, 1, true) ~= nil
    end)
end

local function warehouse(name)
    local w = Map:FindFirstChild("DurianWarehouse")
    return posOf(w and w:FindFirstChild(name))
end
local function sellSpot() return warehouse("BuyerMarker") end
local function seedSpot() return warehouse("SeedMarker") end

----------------------------------------------------------------
-- การทำงานหลัก
----------------------------------------------------------------
local function sellAll()
    local spot = sellSpot()
    if not spot then return end
    status = "กำลังขาย"
    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.9)
        Remotes.SellDurians:FireServer("All")
        task.wait(1.2)
    end)
end

local function harvestBatch()
    local count, max = bag()
    local free = max - count
    if free <= 0 then return false end
    local list = ripePrompts()
    if #list == 0 then return false end
    status = "กำลังเก็บเกี่ยว"
    exclusive(function()
        for i = 1, math.min(#list, free) do
            if not (alive and S.autoHarvest) then break end
            local p = list[i]
            local pos = p.Parent and posOf(p.Parent)
            if pos and p.Enabled then
                local before = bag()
                tp(pos + Vector3.new(3, -2, 0))
                task.wait(0.4)
                Remotes.HarvestFruit:FireServer(p)
                local t = 0
                while t < 4 and alive do
                    task.wait(0.2)
                    t += 0.2
                    if bag() > before or not p:IsDescendantOf(workspace) then break end
                end
                task.wait(0.3)
            end
        end
    end)
    return true
end

local function plantBatch()
    local spots = emptySpots()
    if #spots == 0 then return end
    status = "กำลังปลูก"
    exclusive(function()
        for _, p in ipairs(spots) do
            if not (alive and S.autoPlant) then break end
            local tool = seedTool(S.plantSeed)
            if not tool then status = "ไม่มีเมล็ด" break end
            equip(tool)
            local pos = posOf(p.Parent)
            if pos and p.Enabled then
                tp(pos + Vector3.new(0, 3, 0))
                task.wait(0.4)
                firePrompt(p)
                task.wait(0.6)
            end
        end
    end)
end

local function waterUses()
    return lp:GetAttribute("WaterUses") or 0
end

-- เติมน้ำที่บ่อ (ต้องอยู่ใน exclusive) เซิร์ฟเวอร์เช็คระยะ จึงต้องไปยืนใกล้บ่อ
local function refillWater()
    local items = itemsRoot()
    local well = items and items:FindFirstChild("Well")
    if not well then return false end
    local prompt
    for _, d in ipairs(well:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            prompt = d
            if d.ActionText:find("Fill") then break end
        end
    end
    if not prompt then return false end
    tp((posOf(prompt.Parent) or posOf(well)) + Vector3.new(0, 3, 3))
    task.wait(0.4)
    for _ = 1, 3 do
        firePrompt(prompt)
        local t = 0
        while t < 1.5 and waterUses() <= 0 do
            task.wait(0.1)
            t += 0.1
        end
        if waterUses() > 0 then return true end
    end
    return false
end

-- รดทุกต้น: ไม่ต้องถือกระป๋อง และรดได้ในระยะ ~35 studs จึงเดินเฉพาะเมื่อไกลเกิน
local function waterBatch(force)
    local spots = grownSpots()
    if #spots == 0 then return end
    status = "กำลังรดน้ำ"
    exclusive(function()
        for _, spot in ipairs(spots) do
            if not (alive and (force or S.autoWater)) then break end
            if env.TwoK_DEBUG then warn("[2K] water spot", spot:GetFullName(), "uses", waterUses()) end
            if waterUses() <= 0 and not refillWater() then
                status = "เติมน้ำไม่ได้"
                if env.TwoK_DEBUG then warn("[2K] refill failed") end
                break
            end
            local r = root()
            if r and (r.Position - spot.Position).Magnitude > 30 then
                tp(spot.Position + Vector3.new(0, 3, 0))
                task.wait(0.5) -- ให้เซิร์ฟเวอร์เห็นตำแหน่งใหม่ก่อน ไม่งั้นรดไม่ติด
            end
            -- ยิงแล้วรอให้ค่าน้ำลดลงจริง ถ้าไม่ลดให้ยิงซ้ำอีกครั้ง
            for _ = 1, 2 do
                local before = waterUses()
                Remotes.Water:FireServer("Water", spot.Position)
                local t = 0
                while t < 0.9 and alive and waterUses() == before do
                    task.wait(0.05)
                    t += 0.05
                end
                if waterUses() ~= before then break end
                task.wait(0.3)
            end
            task.wait(0.15)
        end
    end)
end

local function buySeeds(id, qty)
    local spot = seedSpot()
    if not spot then return end
    status = "กำลังซื้อเมล็ด"
    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.8)
        Remotes.SeedShop:FireServer("Refresh")
        task.wait(0.3)
        for _ = 1, qty do
            Remotes.SeedShop:FireServer("Buy", id)
            task.wait(0.2)
        end
        task.wait(0.4)
    end)
end

local function buyFert(id)
    local spot = seedSpot()
    if not spot then return end
    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.8)
        Remotes.SeedShop:FireServer("BuyFert", id)
        task.wait(0.5)
    end)
end

local function padCost(pad)
    for _, d in ipairs(pad:GetDescendants()) do
        if d:IsA("TextLabel") then
            if d.Text == "FREE" then return 0 end
            local n = d.Text:match("^%$([%d,]+)$")
            if n then return tonumber((n:gsub(",", ""))) end
        end
    end
end

local function unlockPads()
    local b = myBase()
    if not b then return end
    local list = {}
    for _, c in ipairs(b:GetChildren()) do
        if (c.Name:sub(1, 7) == "BuyPad_" or c.Name == "BuildPad") and c:GetAttribute("Active") then
            local cost = padCost(c)
            if cost then list[#list + 1] = { c, cost } end
        end
    end
    table.sort(list, function(a, z) return a[2] < z[2] end)
    for _, e in ipairs(list) do
        if cash() >= e[2] then
            local hit = e[1]:FindFirstChild("Hitbox") or e[1]:FindFirstChild("Pad")
            if hit then
                status = "กำลังปลดล็อก"
                exclusive(function()
                    tp(hit.Position + Vector3.new(0, 3, 0))
                    task.wait(0.9)
                    local g = lp.PlayerGui:FindFirstChild("PadConfirmGui")
                    local yes = g and g:FindFirstChild("Frame") and g.Frame:FindFirstChild("Yes")
                    if yes and firesignal then firesignal(yes.Activated) end
                    task.wait(1)
                end)
                if notify then notify("ปลดล็อก", e[1].Name) end
            end
            return
        end
    end
end

local function rebirthCost()
    local n = lp:GetAttribute("Rebirths") or 0
    if RebirthConfig and RebirthConfig.Cost then
        local ok, c = pcall(RebirthConfig.Cost, n)
        if ok then return tonumber(c) end
    end
end

local function doRebirth()
    local ok, res = pcall(function() return Remotes.Rebirth:InvokeServer() end)
    if notify then notify("รีเบิร์ธ", ok and tostring(res) or "ไม่สำเร็จ") end
end

local function goto(pos)
    if pos then exclusive(function() tp(pos + Vector3.new(0, 3, 0)) end) end
end

----------------------------------------------------------------
-- ลูปทำงานเบื้องหลัง
----------------------------------------------------------------
local function loop(interval, fn)
    task.spawn(function()
        while alive do
            local ok, err = pcall(fn)
            if not ok then warn("[2K] " .. tostring(err)) end
            task.wait(type(interval) == "function" and interval() or interval)
        end
    end)
end

loop(1, function()
    if not S.autoHarvest then return end
    local count, max = bag()
    if count >= max then
        if S.autoSell then sellAll() else status = "ถุงเต็ม" end
        return
    end
    if not harvestBatch() then status = "รอผลสุก" end
end)

loop(2, function()
    if not S.autoSell then return end
    local count, max = bag()
    if count > 0 and count >= math.max(1, math.floor(max * S.sellPercent / 100)) then
        sellAll()
    end
end)

loop(3, function() if S.autoPlant then plantBatch() end end)
loop(function() return S.waterEvery end, function() if S.autoWater then waterBatch() end end)
loop(function() return S.buyEvery end, function() if S.autoBuy then buySeeds(S.buySeed, S.buyQty) end end)
loop(6, function() if S.autoUnlock then unlockPads() end end)
loop(60, function()
    if S.autoPay then Remotes.Gardener:FireServer("Pay", nil) end
end)

loop(10, function()
    if not S.autoRebirth then return end
    local n = lp:GetAttribute("Rebirths") or 0
    local cost = rebirthCost()
    local max = RebirthConfig and RebirthConfig.MaxRebirths or 25
    if n < max and cost and cash() >= cost then doRebirth() end
end)

loop(2, function()
    if alive and not busy and status ~= "ว่าง" then status = "ว่าง" end
end)

-- ESP ผลสุก
local espFolder = Instance.new("Folder")
espFolder.Name = "TwoK_ESP"
espFolder.Parent = workspace
loop(1.5, function()
    espFolder:ClearAllChildren()
    if not S.fruitEsp then return end
    for _, p in ipairs(ripePrompts()) do
        local a = p.Parent
        if a and (a:IsA("BasePart") or a:IsA("Model")) then
            local h = Instance.new("Highlight")
            h.Adornee = a
            h.FillColor = Color3.new(1, 1, 1)
            h.FillTransparency = 0.5
            h.OutlineColor = Color3.new(1, 1, 1)
            h.Parent = espFolder
        end
    end
end)

-- ผู้เล่น
track(RunService.Heartbeat:Connect(function()
    local h = humanoid()
    if not h then return end
    if S.speedOn then h.WalkSpeed = S.speed end
    if S.jumpOn then
        h.UseJumpPower = true
        h.JumpPower = S.jump
    end
    if S.fly and not busy then
        local r = root()
        local cam = workspace.CurrentCamera
        if r and cam then
            local dir = h.MoveDirection
            local up = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space) then up += 1 end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then up -= 1 end
            r.AssemblyLinearVelocity = dir * S.flySpeed + Vector3.new(0, up * S.flySpeed, 0)
        end
    end
end))

track(RunService.Stepped:Connect(function()
    if not (S.noclip or S.fly) or busy then return end
    local c = lp.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

track(UIS.JumpRequest:Connect(function()
    if S.infJump then
        local h = humanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

track(lp.Idled:Connect(function()
    if S.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

local lightBackup = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
}
local function applyFullbright()
    if S.fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        for k, v in pairs(lightBackup) do Lighting[k] = v end
    end
end

local gfxBackup
local function applyLowGfx()
    pcall(function()
        if S.lowGfx then
            gfxBackup = gfxBackup or settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            workspace.Terrain.Decoration = false
            Lighting.GlobalShadows = false
        else
            if gfxBackup then settings().Rendering.QualityLevel = gfxBackup end
            workspace.Terrain.Decoration = true
            Lighting.GlobalShadows = lightBackup.GlobalShadows
        end
    end)
end

local function serverHop()
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if not req then return notify("เปลี่ยนเซิร์ฟเวอร์", "executor ไม่รองรับ") end
    local ok, res = pcall(req, { Url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId), Method = "GET" })
    if not ok or not res or not res.Body then return notify("เปลี่ยนเซิร์ฟเวอร์", "ดึงรายชื่อเซิร์ฟเวอร์ไม่ได้") end
    local data = HttpService:JSONDecode(res.Body)
    for _, s in ipairs(data.data or {}) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
            return
        end
    end
    notify("เปลี่ยนเซิร์ฟเวอร์", "ไม่พบเซิร์ฟเวอร์ว่าง")
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local C = {
    bg = Color3.fromRGB(9, 9, 9),
    panel = Color3.fromRGB(14, 14, 14),
    card = Color3.fromRGB(20, 20, 20),
    hover = Color3.fromRGB(30, 30, 30),
    stroke = Color3.fromRGB(38, 38, 38),
    text = Color3.fromRGB(244, 244, 244),
    muted = Color3.fromRGB(135, 135, 135),
    white = Color3.fromRGB(250, 250, 250),
    black = Color3.fromRGB(9, 9, 9),
}

local FONT = "rbxasset://fonts/families/Sarabun.json"
local function font(w) return Font.new(FONT, w or Enum.FontWeight.Medium) end
local BOLD, MED = Enum.FontWeight.Bold, Enum.FontWeight.Medium

local function new(class, props, children)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then i[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stroke(color, t) return new("UIStroke", { Color = color or C.stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
local function pad(l, t, r, b)
    return new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or l), PaddingBottom = UDim.new(0, b or t) })
end
local function tween(o, t, p, style)
    TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end
local function label(props)
    props.BackgroundTransparency = 1
    props.FontFace = font(props.Weight)
    props.Weight = nil
    props.TextColor3 = props.TextColor3 or C.text
    props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props)
end
local function sheen(parent)
    return new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1) }),
        Color = ColorSequence.new(Color3.new(1, 1, 1)),
        Parent = parent,
    })
end

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    local old = guiParent:FindFirstChild("TwoKScript_DG")
    if old then old:Destroy() end
end)
local gui = new("ScreenGui", {
    Name = "TwoKScript_DG",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})
if not pcall(function() gui.Parent = guiParent end) then
    gui.Parent = lp:WaitForChild("PlayerGui")
end
if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 600)
local W = math.min(660, view.X - 24)
local H = math.min(430, view.Y - 50)
local SIDE = W < 520 and 112 or 150

local main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(W, H),
    Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = gui,
}, { corner(14), stroke() })
local scale = new("UIScale", { Scale = 0.92, Parent = main })

-- หัวเมนู
local top = new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = main })
sheen(top)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, Parent = top })

local logo = new("Frame", { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(14, 11), BackgroundColor3 = C.white, Parent = top }, { corner(9) })
label({ Text = "2K", Weight = BOLD, TextSize = 15, TextColor3 = C.black, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = logo })
label({ Text = "2K SCRIPT", Weight = BOLD, TextSize = 16, Size = UDim2.fromOffset(120, 20), Position = UDim2.fromOffset(54, 9), Parent = top })
label({ Text = "สวนทุเรียน  ·  v" .. VERSION, TextColor3 = C.muted, TextSize = 12, Size = UDim2.fromOffset(160, 16), Position = UDim2.fromOffset(54, 28), Parent = top })

local function topButton(txt, x, cb)
    local b = new("TextButton", {
        Text = txt, FontFace = font(BOLD), TextSize = 16, TextColor3 = C.muted,
        Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, x, 0.5, -15),
        BackgroundColor3 = C.card, AutoButtonColor = false, Parent = top,
    }, { corner(8) })
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.hover, TextColor3 = C.text }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.card, TextColor3 = C.muted }) end)
    b.MouseButton1Click:Connect(cb)
end

-- ป้ายสถานะ
local pill = new("Frame", {
    Size = UDim2.fromOffset(150, 28), Position = UDim2.new(1, -224, 0.5, -14),
    BackgroundColor3 = C.card, Parent = top,
}, { corner(14), stroke() })
local dot = new("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = C.muted, Parent = pill }, { corner(4) })
local pillText = label({ Text = "ว่าง", TextSize = 13, TextColor3 = C.text, Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(28, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill })
if W < 560 then pill.Visible = false end

local visible = true
local function setVisible(v)
    visible = v
    if v then
        main.Visible = true
        tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
    else
        tween(scale, 0.15, { Scale = 0.92 })
        task.delay(0.15, function() if not visible then main.Visible = false end end)
    end
end
topButton("–", -76, function() setVisible(false) end)
topButton("×", -40, function() if env.TwoK_DurianGarden then env.TwoK_DurianGarden.Stop() end end)

-- ลากหน้าต่าง
do
    local dragging, startPos, startMouse
    top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startMouse, startPos = true, i.Position, main.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startMouse
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- แถบข้าง + เนื้อหา
local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDE, 1, -55), Position = UDim2.fromOffset(0, 55),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = main,
})
local tabList = new("Frame", { Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1, Parent = sidebar },
    { pad(10, 12), new("UIListLayout", { Padding = UDim.new(0, 4) }) })
label({ Text = "RightShift = ซ่อน/แสดง", TextColor3 = C.muted, TextSize = 11, Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 14, 1, -34), TextWrapped = true, Parent = sidebar })
new("Frame", { Size = UDim2.new(0, 1, 1, -55), Position = UDim2.fromOffset(SIDE, 55), BackgroundColor3 = C.stroke, BorderSizePixel = 0, Parent = main })

local content = new("Frame", {
    Size = UDim2.new(1, -(SIDE + 1), 1, -55), Position = UDim2.fromOffset(SIDE + 1, 55),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = main,
})

-- แจ้งเตือน
local toasts = new("Frame", {
    Size = UDim2.fromOffset(250, 320), Position = UDim2.new(1, -262, 1, -332),
    BackgroundTransparency = 1, Parent = gui,
}, { new("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom }) })

notify = function(title, body)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.panel, BackgroundTransparency = 1, Parent = toasts,
    }, { corner(10), stroke(), pad(14, 10), new("UIListLayout", { Padding = UDim.new(0, 2) }) })
    local bar = new("Frame", { Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(5, 8), BackgroundColor3 = C.white, BackgroundTransparency = 1, Parent = f })
    local a = label({ Text = title, Weight = BOLD, TextSize = 14, Size = UDim2.new(1, 0, 0, 18), TextTransparency = 1, Parent = f })
    local b = label({ Text = body or "", TextColor3 = C.muted, TextSize = 13, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextTransparency = 1, Parent = f })
    tween(f, 0.25, { BackgroundTransparency = 0 })
    tween(bar, 0.25, { BackgroundTransparency = 0 })
    tween(a, 0.25, { TextTransparency = 0 })
    tween(b, 0.25, { TextTransparency = 0 })
    task.delay(3.4, function()
        for _, o in ipairs({ f, bar }) do tween(o, 0.3, { BackgroundTransparency = 1 }) end
        tween(a, 0.3, { TextTransparency = 1 })
        tween(b, 0.3, { TextTransparency = 1 })
        task.wait(0.35)
        f:Destroy()
    end)
end

local pages, tabButtons, current = {}, {}, nil
local refreshers = {}
local function refreshUI()
    for _, fn in ipairs(refreshers) do fn(true) end
end

local function selectTab(name)
    if current == name then return end
    current = name
    for n, pg in pairs(pages) do
        local on = n == name
        pg.Visible = on
        if on then
            pg.Position = UDim2.fromOffset(0, 10)
            tween(pg, 0.3, { Position = UDim2.fromOffset(0, 0) })
        end
    end
    for n, b in pairs(tabButtons) do
        local on = n == name
        tween(b, 0.2, { BackgroundTransparency = on and 0 or 1 })
        tween(b.Label, 0.2, { TextColor3 = on and C.text or C.muted })
        tween(b.Bar, 0.2, { BackgroundTransparency = on and 0 or 1 })
    end
end

local function createPage(name)
    local sf = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = content,
    }, { pad(14, 14), new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
    pages[name] = sf

    local btn = new("TextButton", {
        Text = "", Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card, BackgroundTransparency = 1,
        AutoButtonColor = false, Parent = tabList,
    }, { corner(9) })
    new("Frame", { Name = "Bar", Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = C.white, BackgroundTransparency = 1, Parent = btn }, { corner(2) })
    label({ Name = "Label", Text = name, Weight = MED, TextSize = 15, TextColor3 = C.muted, Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(16, 0), Parent = btn })
    tabButtons[name] = btn
    btn.MouseEnter:Connect(function() if current ~= name then tween(btn.Label, 0.12, { TextColor3 = C.text }) end end)
    btn.MouseLeave:Connect(function() if current ~= name then tween(btn.Label, 0.12, { TextColor3 = C.muted }) end end)
    btn.MouseButton1Click:Connect(function() selectTab(name) end)

    local P = {}
    local function card(h)
        local f = new("Frame", {
            Size = UDim2.new(1, 0, 0, h or 44), BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = sf,
        }, { corner(10), stroke() })
        return f
    end
    local function hoverable(f, hit)
        hit.MouseEnter:Connect(function() tween(f, 0.15, { BackgroundColor3 = C.hover }) end)
        hit.MouseLeave:Connect(function() tween(f, 0.15, { BackgroundColor3 = C.card }) end)
    end

    function P:Section(t)
        local f = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = sf })
        label({ Text = t, Weight = BOLD, TextSize = 13, TextColor3 = C.muted, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.fromOffset(2, 4), Parent = f })
    end

    function P:Hero(title, desc, getter, setter)
        local c = card(86)
        sheen(c)
        label({ Text = title, Weight = BOLD, TextSize = 18, Size = UDim2.new(1, -90, 0, 26), Position = UDim2.fromOffset(18, 16), Parent = c })
        label({ Text = desc, TextColor3 = C.muted, TextSize = 13, Size = UDim2.new(1, -90, 0, 20), Position = UDim2.fromOffset(18, 44), TextTruncate = Enum.TextTruncate.AtEnd, Parent = c })
        local tr = new("Frame", { Size = UDim2.fromOffset(52, 28), Position = UDim2.new(1, -70, 0.5, -14), BackgroundColor3 = C.hover, Parent = c }, { corner(14) })
        local kn = new("Frame", { Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.muted, Parent = tr }, { corner(11) })
        local function render(anim)
            local on = getter()
            local t = anim and 0.22 or 0
            tween(tr, t, { BackgroundColor3 = on and C.white or C.hover })
            tween(kn, t, { Position = on and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and C.black or C.muted })
        end
        render(false)
        refreshers[#refreshers + 1] = render
        local hit = new("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = c })
        hit.MouseButton1Click:Connect(function() setter(not getter()) end)
    end

    function P:Tiles(items)
        local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = sf },
            { new("UIGridLayout", { CellSize = UDim2.new(1 / 3, -6, 0, 62), CellPadding = UDim2.fromOffset(8, 8) }) })
        local setters = {}
        for i, name in ipairs(items) do
            local t = new("Frame", { BackgroundColor3 = C.card, LayoutOrder = i, Parent = grid }, { corner(10), stroke() })
            local v = label({ Text = "-", Weight = BOLD, TextSize = 19, Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(12, 8), TextTruncate = Enum.TextTruncate.AtEnd, Parent = t })
            label({ Text = name, TextColor3 = C.muted, TextSize = 12, Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(12, 36), Parent = t })
            setters[name] = function(s) v.Text = tostring(s) end
        end
        return setters
    end

    function P:Toggle(lbl, key, onChange, desc)
        local c = card(desc and 58 or 46)
        label({ Text = lbl, TextSize = 15, Size = UDim2.new(1, -80, 0, desc and 24 or 46), Position = UDim2.fromOffset(16, desc and 8 or 0), Parent = c })
        if desc then
            label({ Text = desc, TextColor3 = C.muted, TextSize = 12, Size = UDim2.new(1, -80, 0, 18), Position = UDim2.fromOffset(16, 31), TextTruncate = Enum.TextTruncate.AtEnd, Parent = c })
        end
        local tr = new("Frame", { Size = UDim2.fromOffset(42, 22), Position = UDim2.new(1, -58, 0.5, -11), BackgroundColor3 = C.hover, Parent = c }, { corner(11) })
        local kn = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.muted, Parent = tr }, { corner(8) })
        local function render(anim)
            local on = S[key]
            local t = anim and 0.2 or 0
            tween(tr, t, { BackgroundColor3 = on and C.white or C.hover })
            tween(kn, t, { Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and C.black or C.muted })
        end
        render(false)
        refreshers[#refreshers + 1] = render
        local hit = new("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = c })
        hoverable(c, hit)
        hit.MouseButton1Click:Connect(function()
            S[key] = not S[key]
            render(true)
            saveSettings()
            if onChange then onChange(S[key]) end
        end)
    end

    function P:Slider(lbl, key, min, max, suffix)
        local c = card(58)
        label({ Text = lbl, TextSize = 15, Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.fromOffset(16, 5), Parent = c })
        local val = label({ Text = "", Weight = BOLD, TextSize = 14, TextColor3 = C.text, Size = UDim2.new(0.4, -32, 0, 28), Position = UDim2.new(0.6, 16, 0, 5), TextXAlignment = Enum.TextXAlignment.Right, Parent = c })
        local bar = new("Frame", { Size = UDim2.new(1, -32, 0, 4), Position = UDim2.new(0, 16, 0, 42), BackgroundColor3 = C.hover, Parent = c }, { corner(2) })
        local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.white, Parent = bar }, { corner(2) })
        local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = C.white, Parent = bar }, { corner(6) })
        local function render()
            local a = math.clamp((S[key] - min) / (max - min), 0, 1)
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.fromScale(a, 0.5)
            val.Text = tostring(S[key]) .. (suffix or "")
        end
        render()
        refreshers[#refreshers + 1] = render
        local dragging = false
        local function setFrom(x)
            local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            S[key] = math.floor(min + (max - min) * a + 0.5)
            render()
            saveSettings()
        end
        local hit = new("TextButton", { Text = "", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, Parent = c })
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFrom(i.Position.X)
            end
        end)
        track(UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                setFrom(i.Position.X)
            end
        end))
        track(UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    function P:Button(lbl, cb, primary)
        local c = card(42)
        if primary then c.BackgroundColor3 = C.white end
        local b = new("TextButton", {
            Text = lbl, FontFace = font(BOLD), TextSize = 15, TextColor3 = primary and C.black or C.text,
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Parent = c,
        })
        if not primary then hoverable(c, b) end
        b.MouseButton1Click:Connect(function()
            local s = new("UIScale", { Parent = c })
            tween(s, 0.07, { Scale = 0.97 })
            task.delay(0.08, function()
                tween(s, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
                task.delay(0.25, function() s:Destroy() end)
            end)
            task.spawn(cb)
        end)
    end

    function P:Dropdown(lbl, key, options, onChange)
        local c = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.card, BorderSizePixel = 0, ClipsDescendants = true, Parent = sf,
        }, { corner(10), stroke(), new("UIListLayout", {}) })
        local head = new("TextButton", { Text = "", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 1, Parent = c })
        label({ Text = lbl, TextSize = 15, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(16, 0), Parent = head })
        local cur = label({ Text = tostring(S[key]) .. "  ▾", TextColor3 = C.muted, TextSize = 14, Size = UDim2.new(0.5, -32, 1, 0), Position = UDim2.new(0.5, 16, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = head })
        refreshers[#refreshers + 1] = function() cur.Text = tostring(S[key]) .. "  ▾" end
        local list = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = c },
            { new("UIListLayout", {}) })
        new("Frame", { Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, Parent = list, LayoutOrder = 0 })
        for n, opt in ipairs(options) do
            local ob = new("TextButton", {
                Text = opt, FontFace = font(MED), TextSize = 14, TextColor3 = C.muted,
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.hover, BackgroundTransparency = 1,
                AutoButtonColor = false, LayoutOrder = n, Parent = list,
            })
            ob.MouseEnter:Connect(function() tween(ob, 0.1, { BackgroundTransparency = 0, TextColor3 = C.text }) end)
            ob.MouseLeave:Connect(function() tween(ob, 0.1, { BackgroundTransparency = 1, TextColor3 = C.muted }) end)
            ob.MouseButton1Click:Connect(function()
                S[key] = opt
                cur.Text = opt .. "  ▾"
                list.Visible = false
                saveSettings()
                if onChange then onChange(opt) end
            end)
        end
        head.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    end

    function P:Input(lbl, placeholder, cb)
        local c = card(46)
        label({ Text = lbl, TextSize = 15, Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.fromOffset(16, 0), Parent = c })
        local box = new("TextBox", {
            Text = "", PlaceholderText = placeholder, PlaceholderColor3 = C.muted, ClearTextOnFocus = false,
            FontFace = font(MED), TextSize = 14, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.7, -92, 0, 30), Position = UDim2.new(0.3, 0, 0.5, -15),
            BackgroundColor3 = C.bg, Parent = c,
        }, { corner(8), stroke(), pad(10, 0) })
        local go = new("TextButton", {
            Text = "ตกลง", FontFace = font(BOLD), TextSize = 13, TextColor3 = C.black,
            Size = UDim2.fromOffset(62, 30), Position = UDim2.new(1, -74, 0.5, -15),
            BackgroundColor3 = C.white, AutoButtonColor = false, Parent = c,
        }, { corner(8) })
        go.MouseButton1Click:Connect(function() if box.Text ~= "" then task.spawn(cb, box.Text) end end)
    end

    return P
end

-- ปุ่มลอย
local fab = new("TextButton", {
    Text = "2K", FontFace = font(BOLD), TextSize = 14, TextColor3 = C.black,
    Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 12, 0.5, -21),
    BackgroundColor3 = C.white, AutoButtonColor = false, Parent = gui,
}, { corner(21), stroke(C.stroke) })
fab.MouseButton1Click:Connect(function() setVisible(not visible) end)
track(UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then setVisible(not visible) end
end))

----------------------------------------------------------------
-- หน้าต่างๆ
----------------------------------------------------------------
local function setFarm(on)
    S.autoHarvest, S.autoSell, S.autoPlant, S.autoWater = on, on, on, on
    saveSettings()
    refreshUI()
    notify("ออโต้ฟาร์ม", on and "เริ่มทำงานแล้ว" or "หยุดแล้ว")
end

local home = createPage("หน้าหลัก")
home:Hero("ออโต้ฟาร์มครบวงจร", "เก็บเกี่ยว ขาย ปลูก และรดน้ำให้อัตโนมัติ",
    function() return S.autoHarvest and S.autoSell end, setFarm)
home:Section("ภาพรวม")
local tiles = home:Tiles({ "เงิน", "ถุง", "ผลสุก", "รีเบิร์ธ", "น้ำ", "สถานะ" })
home:Section("ทั่วไป")
home:Toggle("กัน AFK", "antiAfk", nil, "ไม่ถูกเตะเมื่อไม่ได้ขยับ")
home:Toggle("ลดแล็ก (กราฟิกต่ำ)", "lowGfx", applyLowGfx, "ช่วยให้ FPS ดีขึ้นเมื่อฟาร์มนานๆ")

local farm = createPage("ฟาร์ม")
farm:Section("เก็บเกี่ยว")
farm:Toggle("เก็บเกี่ยวอัตโนมัติ", "autoHarvest", nil, "วาร์ปไปรับผลสุกแล้วกลับที่เดิม")
farm:Toggle("ไฮไลต์ผลสุก (ESP)", "fruitEsp", nil, "มองเห็นผลที่พร้อมเก็บ")
farm:Section("ขาย")
farm:Toggle("ขายอัตโนมัติ", "autoSell", nil, "ขายที่โกดังเมื่อถุงเต็มตามเปอร์เซ็นต์")
farm:Slider("ขายเมื่อถุงเต็ม", "sellPercent", 10, 100, "%")
farm:Button("ขายตอนนี้", function() sellAll() end)
farm:Section("ปลูก")
farm:Toggle("ปลูกอัตโนมัติ", "autoPlant", nil, "ปลูกเมล็ดในช่องว่างของฟาร์ม")
farm:Dropdown("เมล็ดที่ปลูก", "plantSeed", SEED_OPTIONS)
farm:Section("รดน้ำ")
farm:Toggle("รดน้ำอัตโนมัติ", "autoWater", nil, "รดทุกต้น เติมน้ำที่บ่อเมื่อหมด")
farm:Slider("รดทุกๆ", "waterEvery", 5, 120, " วิ")
farm:Button("รดน้ำทุกต้นตอนนี้", function() waterBatch(true) end)
farm:Button("เติมน้ำที่บ่อ", function()
    exclusive(function()
        local ok = refillWater()
        notify("เติมน้ำ", ok and ("น้ำเต็ม " .. waterUses() .. " หยด") or "เติมไม่สำเร็จ")
    end)
end)

local shop = createPage("ร้านค้า")
shop:Section("เมล็ดพันธุ์")
shop:Toggle("ซื้อเมล็ดอัตโนมัติ", "autoBuy", nil, "วาร์ปไปร้านแล้วซื้อตามจำนวน")
shop:Dropdown("ชนิดเมล็ด", "buySeed", SEEDS)
shop:Slider("จำนวนต่อรอบ", "buyQty", 1, 20, " ชิ้น")
shop:Slider("ซื้อทุกๆ", "buyEvery", 3, 120, " วิ")
shop:Button("ซื้อเลย", function()
    buySeeds(S.buySeed, S.buyQty)
    notify("ร้านค้า", "ซื้อ " .. S.buySeed .. " x" .. S.buyQty)
end, true)
shop:Section("ปุ๋ย")
shop:Dropdown("ชนิดปุ๋ย", "fertType", FERTS)
shop:Button("ซื้อปุ๋ย", function()
    buyFert(S.fertType)
    notify("ร้านค้า", "ซื้อปุ๋ย " .. S.fertType)
end)

local grow = createPage("ปลดล็อก")
grow:Section("ฟาร์ม")
grow:Toggle("ปลดล็อกแปลง/โรงนาอัตโนมัติ", "autoUnlock", nil, "ไล่ซื้อจากราคาถูกไปแพงเมื่อเงินพอ")
grow:Button("ปลดล็อกตอนนี้", function() unlockPads() end)
grow:Section("คนสวน")
grow:Dropdown("เลือกคนสวน", "gardener", GARDENERS)
grow:Button("จ้างคนสวน", function()
    Remotes.Gardener:FireServer("Hire", S.gardener)
    notify("คนสวน", "ส่งคำขอจ้าง " .. S.gardener)
end)
grow:Toggle("จ่ายค่าจ้างอัตโนมัติ", "autoPay", nil, "จ่ายทุก 60 วินาที")
grow:Section("รีเบิร์ธ")
grow:Toggle("รีเบิร์ธอัตโนมัติ", "autoRebirth", nil, "รีเซ็ตความคืบหน้า! ปิดทุกครั้งที่เปิดสคริปต์")
grow:Button("รีเบิร์ธตอนนี้", function()
    local cost = rebirthCost()
    if cost and cash() < cost then
        notify("รีเบิร์ธ", "เงินไม่พอ ต้องใช้ $" .. comma(cost))
    else
        doRebirth()
    end
end)

local player = createPage("ผู้เล่น")
player:Section("การเคลื่อนที่")
player:Toggle("ปรับความเร็ววิ่ง", "speedOn")
player:Slider("ความเร็ว", "speed", 16, 150)
player:Toggle("ปรับแรงกระโดด", "jumpOn")
player:Slider("แรงกระโดด", "jump", 50, 200)
player:Toggle("กระโดดไม่จำกัด", "infJump")
player:Toggle("ทะลุสิ่งกีดขวาง (Noclip)", "noclip")
player:Toggle("บิน", "fly", nil, "Space = ขึ้น, Ctrl = ลง")
player:Slider("ความเร็วบิน", "flySpeed", 20, 200)
player:Section("โลก")
player:Toggle("สว่างตลอด (Fullbright)", "fullbright", applyFullbright)

local misc = createPage("อื่นๆ")
misc:Section("วาร์ป")
misc:Button("ไปที่ฐานของฉัน", function()
    local b = myBase()
    local s = b and b:FindFirstChild("SpawnPad")
    goto(s and s.Position)
end)
misc:Button("ไปจุดขายผล", function() goto(sellSpot()) end)
misc:Button("ไปร้านเมล็ดพันธุ์", function() goto(seedSpot()) end)
misc:Section("โค้ด")
misc:Input("ใส่โค้ด", "พิมพ์โค้ดที่นี่", function(code)
    local ok, res = pcall(function() return Remotes.Codes:InvokeServer(code) end)
    notify("โค้ด", ok and tostring(res) or "ไม่สำเร็จ")
end)
misc:Section("เซิร์ฟเวอร์")
misc:Button("เข้าเซิร์ฟเวอร์เดิมอีกครั้ง", function() TeleportService:Teleport(game.PlaceId, lp) end)
misc:Button("เปลี่ยนเซิร์ฟเวอร์", serverHop)
misc:Section("สคริปต์")
misc:Button("ปิดสคริปต์", function() if env.TwoK_DurianGarden then env.TwoK_DurianGarden.Stop() end end)

selectTab("หน้าหลัก")

-- อัปเดตสถานะสด
loop(0.5, function()
    local count, max = bag()
    tiles["เงิน"]("$" .. comma(cash()))
    tiles["ถุง"](count .. " / " .. max)
    tiles["ผลสุก"](#ripePrompts())
    tiles["รีเบิร์ธ"](lp:GetAttribute("Rebirths") or 0)
    tiles["น้ำ"](waterUses() .. " / 3")
    tiles["สถานะ"](status)
    pillText.Text = status
    tween(dot, 0.2, { BackgroundColor3 = status == "ว่าง" and C.muted or C.white })
end)

----------------------------------------------------------------
-- ปิดสคริปต์
----------------------------------------------------------------
env.TwoK_DurianGarden = {
    Stop = function()
        alive = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        pcall(function() espFolder:Destroy() end)
        S.fullbright, S.lowGfx = false, false
        pcall(applyFullbright)
        pcall(applyLowGfx)
        local h = humanoid()
        if h then pcall(function() h.WalkSpeed = 16 end) end
        gui:Destroy()
        env.TwoK_DurianGarden = nil
    end,
}

applyFullbright()
applyLowGfx()
tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
notify("2K SCRIPT", "โหลดเสร็จแล้ว กด RightShift เพื่อซ่อน/แสดงเมนู")

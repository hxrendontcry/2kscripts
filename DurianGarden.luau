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
local VERSION = "2.2"

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
    buyList = { ["Kradumthong"] = true },
    buyKeep = 0,
    buyRubberSaplings = 0,
    buyItems = {},
    autoRubber = false,
    autoRubberTap = false,
    cashReserve = 0,
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
            if S[k] ~= nil and type(v) == type(S[k]) then
                if type(v) == "table" then
                    local t = {}
                    for tk, tv in pairs(v) do t[tk] = tv end
                    S[k] = t
                else
                    S[k] = v
                end
            end
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

local function safeRequire(name)
    local m = Shared:FindFirstChild(name)
    if not m then return end
    local ok, r = pcall(require, m)
    return ok and r or nil
end
local RebirthConfig = safeRequire("RebirthConfig")
local RubberConfig = safeRequire("RubberConfig")
local GardenerConfig = safeRequire("GardenerConfig")
local DurianConfig = safeRequire("DurianConfig")
local FruitIcons = RS:FindFirstChild("FruitIcons")

local THAI_NAMES = {
    Any = "ทุกชนิด",
    Kradumthong = "กระดุมทอง",
    Chanee = "ชะนี",
    Puangmanee = "พวงมณี",
    Kanyao = "ก้านยาว",
    Nokyip = "นกหยิบ",
    Monthong = "หมอนทอง",
    OilPalm = "ปาล์มน้ำมัน",
}

local THAI_INITIALS = {
    Any = "ทุก",
    Kradumthong = "ก",
    Chanee = "ชน",
    Puangmanee = "พม",
    Kanyao = "กย",
    Nokyip = "นย",
    Monthong = "มท",
    OilPalm = "ปม",
}

local BUYABLE_SEEDS = { "Kradumthong", "Chanee", "Puangmanee", "Kanyao", "Nokyip", "Monthong" }
local ALL_PLANT_SEEDS = { "Any", "Kradumthong", "Chanee", "Puangmanee", "Kanyao", "Nokyip", "Monthong", "OilPalm" }
local SEEDS = BUYABLE_SEEDS
local SEED_OPTIONS = ALL_PLANT_SEEDS
local FERTS = { "Basic", "Super", "Mega", "TonicBasic", "TonicSuper", "TonicMega" }
local GARDENERS = { "UncleBoon", "Noi", "BigTong", "Mali" }
local ShopIcons = RS:FindFirstChild("ShopIcons")

local FERT_INFO = {
    Basic = { Name = "ปุ๋ยธรรมดา", Desc = "เร่งโตต้นละ 2 นาที", Initial = "ป1" },
    Super = { Name = "ปุ๋ยซุปเปอร์", Desc = "เร่งโตต้นละ 8 นาที", Initial = "ป2" },
    Mega = { Name = "ปุ๋ยเมก้า", Desc = "เร่งโตต้นละ 30 นาที", Initial = "ป3" },
    TonicBasic = { Name = "ยาบำรุงธรรมดา", Desc = "ผลเพิ่ม 20 ครั้ง", Initial = "ย1" },
    TonicSuper = { Name = "ยาบำรุงซุปเปอร์", Desc = "ผลเพิ่ม 20 ครั้ง", Initial = "ย2" },
    TonicMega = { Name = "ยาบำรุงเมก้า", Desc = "ผลเพิ่ม 20 ครั้ง", Initial = "ย3" },
    RubberSapling = { Name = "ต้นกล้ายาง", Desc = "ต้นกล้ายางพารา", Initial = "ยาง" },
    Gun_Pistol = { Name = "ปืนฉีดน้ำ", Desc = "ปืนฉีดน้ำพกพา", Initial = "ปืน" },
    Gun_Shotgun = { Name = "ลูกซองฉีดน้ำ", Desc = "ฉีดน้ำได้กว้างขึ้น (ซื้อได้ครั้งเดียว)", Initial = "ลูกซอง" },
    Gun_AK = { Name = "AK-47 ฉีดน้ำ", Desc = "ปืนฉีดน้ำอัตโนมัติ (Robux)", Initial = "AK" },
}

local FERTS_ORDER = {
    "Basic", "Super", "Mega",
    "TonicBasic", "TonicSuper", "TonicMega",
    "RubberSapling", "Gun_Pistol", "Gun_Shotgun", "Gun_AK",
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(160, 160, 160),
    Uncommon = Color3.fromRGB(80, 200, 120),
    Rare = Color3.fromRGB(70, 140, 255),
    Epic = Color3.fromRGB(170, 80, 255),
    Legendary = Color3.fromRGB(255, 175, 40),
    Mythic = Color3.fromRGB(255, 60, 90),
}

local shopState = nil
local lastShopUpdate = 0
local onShopStateChanged = {}

local function countHeldTools(id)
    local count = 0
    local function check(tool)
        if not tool:IsA("Tool") then return end
        local itemId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id") or tool:GetAttribute("FertId")
        if itemId ~= nil then
            if itemId == id then count += (tonumber(tool:GetAttribute("Count")) or 1) end
            return
        end
        local tName = tool.Name
        if id == "RubberSapling" then
            if tName:find("Rubber Sapling", 1, true) then
                count += tonumber(tName:match("x(%d+)$")) or 1
            end
        elseif id:sub(1, 4) == "Gun_" then
            if tool:GetAttribute("GunId") == id or tName:lower():find(id:sub(5):lower(), 1, true) then
                count += 1
            end
        elseif tool:GetAttribute("SeedId") == id then
            count += 1
        end
    end
    local c = lp.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do check(t) end
    end
    if lp.Backpack then
        for _, t in ipairs(lp.Backpack:GetChildren()) do check(t) end
    end
    return count
end

local function countHeldSeeds(id)
    local count = 0
    local function check(tool)
        if tool:IsA("Tool") and tool.Name:find("Seed") then
            if id == "Any" then
                count += 1
            elseif tool:GetAttribute("SeedId") == id or tool.Name:find(id, 1, true) then
                count += 1
            end
        end
    end
    local c = lp.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do check(t) end
    end
    if lp.Backpack then
        for _, t in ipairs(lp.Backpack:GetChildren()) do check(t) end
    end
    return count
end

local function totalAllHeldSeeds()
    return countHeldSeeds("Any")
end

local function getFertItem(id)
    if shopState and shopState.Ferts then
        for _, item in ipairs(shopState.Ferts) do
            if item.Id == id then
                local clone = {}
                for k, v in pairs(item) do clone[k] = v end
                clone.Owned = math.max(item.Owned or 0, countHeldTools(id))
                return clone
            end
        end
    end
    local staticInfo = FERT_INFO[id] or {}
    local fallbackPrices = {
        Basic = 500, Super = 5000, Mega = 10000,
        TonicBasic = 500, TonicSuper = 5000, TonicMega = 10000,
        RubberSapling = 1500, Gun_Pistol = 3000, Gun_Shotgun = 12000, Gun_AK = 0,
    }
    return {
        Id = id,
        Name = staticInfo.Name or id,
        Price = fallbackPrices[id] or 0,
        Owned = countHeldTools(id),
        Rarity = (id == "Gun_AK" and "Legendary") or (id == "Gun_Shotgun" and "Epic") or (id == "Gun_Pistol" and "Rare") or (id:find("Mega") and "Rare") or (id:find("Super") and "Uncommon") or "Common",
        Desc = staticInfo.Desc or "",
        Unique = (id == "Gun_Shotgun"),
        Robux = (id == "Gun_AK" and 249 or nil),
    }
end

local function getShopItem(id)
    if shopState and shopState.Items then
        for _, item in ipairs(shopState.Items) do
            if item.Id == id then return item end
        end
    end
    local cfg = DurianConfig and DurianConfig.ById and DurianConfig.ById[id]
    if cfg then
        return {
            Id = id,
            Name = cfg.Name or id,
            Rarity = cfg.Rarity or "Common",
            Price = cfg.SeedPrice or 0,
            Stock = 99,
            Max = 99,
            Owned = countHeldSeeds(id),
            FruitValue = cfg.FruitValue or 0,
            GrowSeconds = cfg.GrowSeconds or 60,
        }
    end
    return {
        Id = id,
        Name = id,
        Rarity = "Common",
        Price = 0,
        Stock = 0,
        Max = 0,
        Owned = countHeldSeeds(id),
        FruitValue = 0,
        GrowSeconds = 0,
    }
end

local function formatRestockTime()
    if not (shopState and shopState.NextRestock) then return "--:--" end
    local nowServer = workspace:GetServerTimeNow()
    local left = math.max(0, math.floor(shopState.NextRestock - nowServer))
    local m = math.floor(left / 60)
    local s = left % 60
    return string.format("%02d:%02d", m, s)
end

local function formatLastUpdate()
    if lastShopUpdate == 0 then return "ยังไม่อัปเดต" end
    local diff = math.floor(os.clock() - lastShopUpdate)
    return diff .. " วิที่แล้ว"
end

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
local busyStartTime = 0
local busyThread = nil

local function exclusive(fn)
    while busy and alive do
        if os.clock() - busyStartTime > 45 then
            warn("[2K] Watchdog: exclusive ค้างเกิน 45 วินาที บังคับปลดล็อค busy")
            if busyThread and coroutine.status(busyThread) ~= "dead" then
                pcall(task.cancel, busyThread)
            end
            busy = false
            busyThread = nil
            break
        end
        task.wait(0.1)
    end
    if not alive then return false end

    busy = true
    busyStartTime = os.clock()
    local startChar = lp.Character
    local r = root()
    local home = r and r.CFrame

    local ok, err = false, nil
    busyThread = task.spawn(function()
        ok, err = pcall(fn)
    end)

    while busyThread and coroutine.status(busyThread) ~= "dead" and alive do
        if os.clock() - busyStartTime > 45 then
            warn("[2K] Watchdog: งานใน exclusive ทำงานนานเกิน 45 วินาที ยกเลิกเธรด")
            pcall(task.cancel, busyThread)
            ok = false
            err = "Timeout > 45s"
            break
        end
        task.wait(0.1)
    end

    busy = false
    busyThread = nil

    -- ตรวจสอบตัวละครก่อนวาร์ปกลับ home: ถ้าตัวละครเปลี่ยน (ตาย/เกิดใหม่) ห้ามวาร์ปกลับ home เดิม
    local endChar = lp.Character
    local r2 = root()
    local h2 = humanoid()
    if endChar and endChar == startChar and r2 and r2 == r and home and h2 and h2.Health > 0 then
        r2.CFrame = home
        r2.AssemblyLinearVelocity = Vector3.zero
    end

    if not ok and err then warn("[2K] " .. tostring(err)) end
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
local plantFailedUntil = setmetatable({}, { __mode = "k" })
local function ripePrompts() return promptsOf("Harvest") end
local function emptySpots()
    local list, items = {}, itemsRoot()
    if not items then return list end
    local now = os.clock()
    for _, d in ipairs(items:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.ActionText == "Plant Seed" and d.Enabled then
            if (plantFailedUntil[d] or 0) <= now then
                list[#list + 1] = d
            end
        end
    end
    return list
end

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
local sellCooldownUntil = 0
local sellFailStreak = 0

local function sellAll(force)
    local now = os.clock()
    if not force and now < sellCooldownUntil then return false end

    local spot = sellSpot()
    if not spot then return false end
    status = "กำลังขาย"
    local soldOk = false

    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.9)
        local beforeBag = bag()
        Remotes.SellDurians:FireServer("All")

        local t = 0
        while t < 2.0 and alive do
            task.wait(0.1)
            t += 0.1
            if bag() < beforeBag or bag() == 0 then
                soldOk = true
                break
            end
        end
        task.wait(0.3)
    end)

    if soldOk then
        sellFailStreak = 0
        sellCooldownUntil = 0
        return true
    else
        sellFailStreak += 1
        local backoff = math.min(30, 4 + (sellFailStreak * 3))
        sellCooldownUntil = os.clock() + backoff
        warn("[2K] ขายไม่สำเร็จ (รอบที่ " .. sellFailStreak .. ") พักขาย " .. backoff .. " วินาที")
        status = "พักขาย (" .. backoff .. "วิ)"
        return false
    end
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
            -- ยืนยันว่าถือเมล็ดอยู่ใน Character จริงก่อนกด prompt
            local c = lp.Character
            if not (c and tool.Parent == c) then
                task.wait(0.2)
                if not (lp.Character and tool.Parent == lp.Character) then
                    warn("[2K] ไม่สามารถถือเมล็ด " .. tool.Name .. " ได้ ข้ามรอบนี้")
                    break
                end
            end

            local pos = posOf(p.Parent)
            if pos and p.Enabled and p:IsDescendantOf(workspace) then
                tp(pos + Vector3.new(0, 3, 0))
                task.wait(0.4)

                -- ตรวจสอบอีกครั้งหลังวาร์ปว่ายังถือเมล็ดอยู่จริงก่อนกด prompt
                if tool.Parent ~= lp.Character then
                    equip(tool)
                    task.wait(0.2)
                end
                if tool.Parent ~= lp.Character then
                    warn("[2K] เมล็ดหลุดมือก่อนกด prompt ข้ามช่องนี้ชั่วคราว")
                    plantFailedUntil[p] = os.clock() + 10
                    continue
                end

                firePrompt(p)

                -- ตรวจสอบผลว่าช่องถูกปลูกจริงหรือไม่ (Prompt หาย/ปิด หรือ มี Tree/Seed ขึ้น)
                local planted = false
                local t = 0
                while t < 1.8 and alive do
                    task.wait(0.15)
                    t += 0.15
                    local hasPlant = false
                    if p.Parent then
                        if p.Parent:FindFirstChild("Tree") or p.Parent:FindFirstChild("Seed") then
                            hasPlant = true
                        elseif p.Parent.Parent and (p.Parent.Parent:FindFirstChild("Tree") or p.Parent.Parent:FindFirstChild("Seed")) then
                            hasPlant = true
                        end
                    end
                    if not p.Enabled or not p:IsDescendantOf(workspace) or hasPlant then
                        planted = true
                        break
                    end
                end

                if planted then
                    plantFailedUntil[p] = nil
                else
                    -- ปลูกไม่สำเร็จ ให้พักช่องนี้ 20 วินาทีเพื่อไม่ให้ติดลูปซ้ำ
                    plantFailedUntil[p] = os.clock() + 20
                end
                task.wait(0.3)
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

-- รดทุกต้น: ต้องถือกระป๋อง และรดได้ในระยะ ~35 studs จึงเดินเฉพาะเมื่อไกลเกิน
-- ต้นที่ยิงรดแล้วน้ำไม่ลด (ยืนยัน 2 ครั้ง) จะพักสั้นๆ ไม่ให้เสียเวลาซ้ำ
local wetUntil = setmetatable({}, { __mode = "k" })
local WET_SKIP = 20

local function waterBatch(force)
    local spots = grownSpots()
    if #spots == 0 then return end
    local can = findTool(function(t) return t:GetAttribute("GearId") == "WateringCan" end)
    if not can then
        if notify and force then notify("รดน้ำ", "ไม่พบกระป๋องรดน้ำในกระเป๋า") end
        status = "ไม่มีกระป๋อง"
        return
    end
    local watered, wet = 0, 0
    status = "กำลังรดน้ำ"
    exclusive(function()
        for _, spot in ipairs(spots) do
            if not (alive and (force or S.autoWater)) then break end
            -- เซิร์ฟเวอร์ไม่หักน้ำถ้าไม่ได้ถือกระป๋อง (ทดสอบแล้ว)
            if can.Parent ~= lp.Character then
                equip(can)
                if can.Parent ~= lp.Character then
                    status = "หยิบกระป๋องไม่ได้"
                    break
                end
            end
            if not force and (wetUntil[spot] or 0) > os.clock() then
                wet += 1
                continue
            end
            if waterUses() <= 0 and not refillWater() then
                status = "เติมน้ำไม่ได้"
                break
            end
            local moved = false
            local r = root()
            if r and (r.Position - spot.Position).Magnitude > 30 then
                tp(spot.Position + Vector3.new(0, 3, 0))
                task.wait(0.5) -- ให้เซิร์ฟเวอร์เห็นตำแหน่งใหม่ก่อน ไม่งั้นรดไม่ติด
                moved = true
            end

            -- ตรวจสอบและรดน้ำ โดยถ้าครั้งแรกน้ำไม่ลด (อาจเกิดจาก lag) ให้ยืนยันซ้ำรอบ 2 ก่อนตัดสินว่าต้นไม้เปียก
            local ok = false
            for attempt = 1, 2 do
                if not alive then break end
                if waterUses() <= 0 then
                    if not refillWater() then break end
                    local rNow = root()
                    if rNow and (rNow.Position - spot.Position).Magnitude > 30 then
                        tp(spot.Position + Vector3.new(0, 3, 0))
                        task.wait(0.4)
                    end
                end

                local before = waterUses()
                Remotes.Water:FireServer("Water", spot.Position)
                local t = 0
                while t < 1.0 and alive and waterUses() == before do
                    task.wait(0.05)
                    t += 0.05
                end

                if waterUses() ~= before then
                    ok = true
                    break
                end

                if attempt == 1 then
                    task.wait(0.4) -- รอ network เคลียร์ก่อนลองรอบสอง
                    if waterUses() ~= before then
                        ok = true
                        break
                    end
                end
            end

            if ok then
                watered += 1
                wetUntil[spot] = nil
            else
                wet += 1
                wetUntil[spot] = os.clock() + WET_SKIP
            end
            task.wait(0.15)
        end
        local h = humanoid()
        if h then h:UnequipTools() end
    end)
    if not notify then return end
    if watered > 0 then
        notify("รดน้ำ", "รดแล้ว " .. watered .. " ต้น" .. (wet > 0 and (" (อีก " .. wet .. " ต้นยังเปียกอยู่)") or ""))
    elseif wet > 0 and force then
        notify("รดน้ำ", "ต้นไม้ยังเปียกอยู่ทุกต้น ยังไม่ต้องรด")
    end
end

if Remotes:FindFirstChild("SeedShop") then
    track(Remotes.SeedShop.OnClientEvent:Connect(function(action, state)
        if action == "Update" and type(state) == "table" then
            shopState = state
            lastShopUpdate = os.clock()
            for _, cb in ipairs(onShopStateChanged) do
                pcall(cb, state)
            end
        end
    end))
end

local function refreshShop()
    local spot = seedSpot()
    if not spot then return notify("ร้านค้า", "ไม่พบตำแหน่งร้านค้า") end
    status = "รีเฟรชร้านค้า"
    local updated = false
    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.6)
        local prevTime = lastShopUpdate
        Remotes.SeedShop:FireServer("Refresh")
        local t = 0
        while t < 2.0 and alive do
            task.wait(0.1)
            t += 0.1
            if lastShopUpdate > prevTime then
                updated = true
                break
            end
        end
        task.wait(0.2)
    end)
    if updated then
        if notify then notify("ร้านค้า", "อัปเดตข้อมูลสต็อกร้านค้าแล้ว") end
    else
        if notify then notify("ร้านค้า", "รีเฟรชร้านไม่สำเร็จ (หมดเวลา)") end
    end
end

local warnedEmptyBuyList = false

-- จำนวนที่อยากถือไว้ของแต่ละชิ้นในร้าน (ตั้งจากการ์ด) ต้นกล้ายางรองรับค่าเดิมจากสไลเดอร์เก่าด้วย
local function itemTarget(id)
    local t = tonumber(S.buyItems and S.buyItems[id]) or 0
    if id == "RubberSapling" then t = math.max(t, S.buyRubberSaplings or 0) end
    return t
end

local function itemNeedsList()
    local list, total = {}, 0
    for _, id in ipairs(FERTS_ORDER) do
        local target = itemTarget(id)
        if target > 0 then
            local it = getFertItem(id)
            if not it.Robux and not (it.Unique and (it.Owned or 0) > 0) then
                local need = target - (it.Owned or 0)
                if it.Unique then need = math.min(need, 1) end
                if need > 0 then
                    list[#list + 1] = { id = id, need = need, price = it.Price or 0 }
                    total += need
                end
            end
        end
    end
    return list, total
end

local function autoBuyStep(force)
    if not S.autoBuy then return end

    local empties = #emptySpots()
    local totalHeld = totalAllHeldSeeds()
    local seedsNeeded = math.max(0, (empties + (S.buyKeep or 0)) - totalHeld)
    local needList, itemsTotal = itemNeedsList()

    if seedsNeeded <= 0 and itemsTotal <= 0 then return end

    local hasSelectedSeed = false
    for id, on in pairs(S.buyList or {}) do
        if on and id ~= "OilPalm" then
            hasSelectedSeed = true
            break
        end
    end

    if seedsNeeded > 0 and not hasSelectedSeed then
        if itemsTotal <= 0 then
            if not warnedEmptyBuyList then
                warnedEmptyBuyList = true
                if notify then notify("ซื้อเมล็ด", "กรุณาเลือกชนิดเมล็ดที่ต้องการซื้อในหน้าร้านค้า") end
            end
            return
        end
    else
        warnedEmptyBuyList = false
    end

    local availableCash = math.max(0, cash() - (S.cashReserve or 0))
    if availableCash <= 0 then return end

    local minAffordable = math.huge
    if seedsNeeded > 0 and hasSelectedSeed then
        for id, on in pairs(S.buyList) do
            if on and id ~= "OilPalm" then
                local it = getShopItem(id)
                local pr = it and it.Price or 0
                if pr > 0 and pr < minAffordable then minAffordable = pr end
            end
        end
    end
    for _, e in ipairs(needList) do
        if e.price > 0 and e.price < minAffordable then minAffordable = e.price end
    end
    if availableCash < minAffordable then return end

    -- ไม่วาร์ปไปร้านฟรีๆ: ถ้าไม่มีของนอกเหนือจากเมล็ดที่ต้องซื้อ และข้อมูลรอบรีสต็อกนี้บอกว่าเมล็ดที่เลือกหมด ให้รอรอบถัดไป
    if not force and itemsTotal <= 0 and shopState and shopState.Cycle == math.floor(workspace:GetServerTimeNow() / 300) then
        local anyStock = false
        for id, on in pairs(S.buyList or {}) do
            if on and id ~= "OilPalm" then
                local it = getShopItem(id)
                if it and (it.Stock or 0) > 0 and (it.Price or 0) <= availableCash then
                    anyStock = true
                    break
                end
            end
        end
        if not anyStock then return end
    end

    local spot = seedSpot()
    if not spot then return end

    status = "กำลังซื้อเมล็ด/ของร้านค้า"
    local boughtNames = {}
    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.8)

        local prevTime = lastShopUpdate
        Remotes.SeedShop:FireServer("Refresh")
        local t = 0
        while t < 1.2 and alive do
            task.wait(0.1)
            t += 0.1
            if lastShopUpdate > prevTime then break end
        end
        task.wait(0.1)

        local curCash = math.max(0, cash() - (S.cashReserve or 0))
        if curCash <= 0 then return end

        -- เมล็ด: เลือกแพง -> ถูก ตามสต็อกที่เพิ่งรีเฟรช
        local freshEmpties = #emptySpots()
        local freshHeld = totalAllHeldSeeds()
        local actualSeedsNeeded = math.max(0, (freshEmpties + (S.buyKeep or 0)) - freshHeld)
        if actualSeedsNeeded > 0 and hasSelectedSeed then
            local candidates = {}
            for id, on in pairs(S.buyList) do
                if on and id ~= "OilPalm" then
                    local info = getShopItem(id)
                    if info and (info.Stock == nil or info.Stock > 0) then
                        candidates[#candidates + 1] = info
                    end
                end
            end
            table.sort(candidates, function(a, z) return (a.Price or 0) > (z.Price or 0) end)

            local remainingSeeds = actualSeedsNeeded
            for _, item in ipairs(candidates) do
                if remainingSeeds <= 0 or curCash < (item.Price or 0) then break end
                local price = item.Price or 0
                if price > 0 then
                    local canBuy = math.min(remainingSeeds, math.floor(curCash / price), (item.Stock ~= nil) and item.Stock or 99)
                    if canBuy > 0 then
                        for _ = 1, canBuy do
                            Remotes.SeedShop:FireServer("Buy", item.Id)
                            task.wait(0.18)
                        end
                        remainingSeeds -= canBuy
                        curCash -= canBuy * price
                        boughtNames[#boughtNames + 1] = (THAI_NAMES[item.Id] or item.Id) .. " x" .. canBuy
                    end
                end
            end
        end

        -- ของอื่นในร้าน (ปุ๋ย ยา ต้นกล้ายาง ปืน): เติมให้ครบตามจำนวนที่ตั้ง
        local freshList = itemNeedsList()
        for _, e in ipairs(freshList) do
            if e.price > 0 and curCash >= e.price then
                local q = math.min(e.need, math.floor(curCash / e.price))
                for _ = 1, q do
                    Remotes.SeedShop:FireServer("BuyFert", e.id)
                    task.wait(0.25)
                end
                curCash -= q * e.price
                boughtNames[#boughtNames + 1] = ((FERT_INFO[e.id] and FERT_INFO[e.id].Name) or e.id) .. " x" .. q
            end
        end

        task.wait(0.4)
    end)
    if notify and #boughtNames > 0 then
        notify("ซื้ออัตโนมัติ", table.concat(boughtNames, ", "))
    end
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
    task.delay(1.5, function()
        refreshUI()
    end)
end

local function buyFertItem(id, qty)
    if id == "Gun_AK" then return end
    qty = qty or 1
    local spot = seedSpot()
    if not spot then return end

    local info = getFertItem(id)
    if info.Unique and info.Owned and info.Owned > 0 then
        if notify then notify("ร้านค้า", "ไอเทมนี้มีอยู่แล้ว (ซื้อได้ครั้งเดียว)") end
        return
    end

    local unitPrice = info.Price or 0
    if unitPrice > 0 and cash() < unitPrice * qty then
        if notify then notify("ร้านค้า", "เงินไม่พอสำหรับซื้อ " .. (info.Name or id)) end
        return
    end

    status = "กำลังซื้อของร้านค้า"
    local before = cash()
    exclusive(function()
        tp(spot + Vector3.new(0, 3, 0))
        task.wait(0.8)
        for _ = 1, qty do
            Remotes.SeedShop:FireServer("BuyFert", id)
            task.wait(0.25)
        end
        task.wait(0.3)
        Remotes.SeedShop:FireServer("Refresh")
        task.wait(0.8)
    end)
    local spent = before - cash()
    if notify then
        if spent > 0 and unitPrice > 0 then
            notify("ร้านค้า", "ซื้อ " .. (info.Name or id) .. " x" .. math.floor(spent / unitPrice + 0.5))
        else
            notify("ร้านค้า", "ซื้อ " .. (info.Name or id) .. " ไม่สำเร็จ")
        end
    end
end

local function buyFert(id)
    buyFertItem(id, 1)
end

local function stripTags(str)
    return (str:gsub("<[^>]->", ""))
end

local function parseNumberWithSuffix(str)
    str = str:gsub(",", ""):gsub("%s+", "")
    local numStr, suffix = str:match("^(%d+%.?%d*)([kKmMbB]?)$")
    if not numStr then return nil end
    local num = tonumber(numStr)
    if not num then return nil end
    if suffix == "k" or suffix == "K" then
        return num * 1e3
    elseif suffix == "m" or suffix == "M" then
        return num * 1e6
    elseif suffix == "b" or suffix == "B" then
        return num * 1e9
    end
    return num
end

local function padCost(pad)
    for _, d in ipairs(pad:GetDescendants()) do
        if d:IsA("TextLabel") then
            local clean = stripTags(d.Text):gsub("%s+", " "):match("^%s*(.-)%s*$")
            if clean then
                local upper = clean:upper()
                if upper == "FREE" or upper:find("FREE") then return 0 end

                -- ตรวจจับรูปแบบ "$1,000", "$ 50K", "$1.5M", "Cost: $500"
                local pricePart = clean:match("%$[%s]*([%d,%.]+%s*[kKmMbB]?)")
                if pricePart then
                    local val = parseNumberWithSuffix(pricePart)
                    if val then return val end
                end

                -- Fallback ตรวจจับตัวเลขโดดๆ
                local pureNum = clean:match("^([%d,%.]+%s*[kKmMbB]?)$")
                if pureNum then
                    local val = parseNumberWithSuffix(pureNum)
                    if val then return val end
                end
            end
        end
    end
    return nil
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
        if S.autoSell then
            if os.clock() >= sellCooldownUntil then
                sellAll()
            else
                status = "พักขาย (" .. math.max(1, math.floor(sellCooldownUntil - os.clock())) .. "วิ)"
            end
        else
            status = "ถุงเต็ม"
        end
        return
    end
    if not harvestBatch() then status = "รอผลสุก" end
end)

loop(2, function()
    if not S.autoSell then return end
    if os.clock() < sellCooldownUntil then return end
    local count, max = bag()
    if count > 0 and count >= math.max(1, math.floor(max * S.sellPercent / 100)) then
        sellAll()
    end
end)

loop(3, function() if S.autoPlant then plantBatch() end end)

-- ปลูกต้นยาง: ต้องถือต้นกล้า แล้วกด prompt "Plant Sapling" ในช่องแปลงยาง (ทดสอบแล้ว)
local function saplingTool()
    return findTool(function(t) return t.Name:find("Rubber Sapling", 1, true) ~= nil end)
end

local function rubberPlantBatch()
    local spots = promptsOf("Plant Sapling")
    if #spots == 0 or not saplingTool() then return end
    status = "กำลังปลูกต้นยาง"
    exclusive(function()
        for _, p in ipairs(spots) do
            if not (alive and S.autoRubber) then break end
            local tool = saplingTool()
            if not tool then status = "ไม่มีต้นกล้ายาง" break end
            equip(tool)
            if tool.Parent ~= lp.Character then break end
            local pos = posOf(p.Parent)
            if pos and p.Enabled then
                tp(pos + Vector3.new(0, 3, 0))
                task.wait(0.5)
                firePrompt(p)
                local t = 0
                while t < 3 and alive and p.Enabled do
                    task.wait(0.15)
                    t += 0.15
                end
                task.wait(0.3)
            end
        end
        local h = humanoid()
        if h then h:UnequipTools() end
    end)
end
loop(5, function() if S.autoRubber then rubberPlantBatch() end end)

-- กรีดยาง/ใส่กรด: เซิร์ฟเวอร์ส่ง ("Game", ชนิด, ...) แล้วรอ GameDone(ชนิด, คะแนน)
-- ทดสอบแล้ว: ส่งคะแนน 1 หลังรอครบเวลาเล่น (Tap 6 วิ / Acid 5 วิ) ได้ "Tapped! 100% cut."
local gameCons = {}
local gameStarted, gameAnswered = 0, 0
local rubberCooldown = setmetatable({}, { __mode = "k" })

local function disableGameHandlers()
    if not getconnections then return false end
    local any = false
    for _, c in ipairs(getconnections(Remotes.PlotType.OnClientEvent)) do
        local ok, src = pcall(function() return debug.info(c.Function, "s") end)
        if ok and tostring(src):find("RubberGameController") then
            pcall(function() c:Disable() end)
            gameCons[#gameCons + 1] = c
            any = true
        end
    end
    return any
end

local function restoreGameHandlers()
    for _, c in ipairs(gameCons) do pcall(function() c:Enable() end) end
    gameCons = {}
end

track(Remotes.PlotType.OnClientEvent:Connect(function(a1, kind)
    if a1 ~= "Game" or not S.autoRubberTap then return end
    gameStarted += 1
    task.spawn(function()
        local secs
        if kind == "Tap" then
            secs = (RubberConfig and RubberConfig.TapSeconds) or 6
        else
            secs = (RubberConfig and RubberConfig.StirSeconds) or 5
        end
        task.wait(secs + 0.8)
        if alive then
            Remotes.PlotType:FireServer("GameDone", kind, 1)
            gameAnswered += 1
        end
    end)
end))

local function rubberTapBatch()
    local items = itemsRoot()
    if not items then return end
    local list = {}
    local now = os.clock()
    for _, d in ipairs(items:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled and d.ActionText ~= "Plant Sapling"
            and d.Parent and d.Parent.Name == "PlantSpot"
            and d.Parent.Parent and d.Parent.Parent.Parent and d.Parent.Parent.Parent.Name == "RubberSlots"
            and (rubberCooldown[d] or 0) <= now then
            list[#list + 1] = d
        end
    end
    if #list == 0 then return end
    status = "กำลังทำงานต้นยาง"
    exclusive(function()
        for _, p in ipairs(list) do
            if not (alive and S.autoRubberTap) then break end
            local pos = posOf(p.Parent)
            if pos and p.Enabled then
                tp(pos + Vector3.new(0, 3, 2.5))
                task.wait(0.6)
                local startedBefore, answeredBefore = gameStarted, gameAnswered
                firePrompt(p)
                local t = 0
                while t < 2.5 and alive and gameStarted == startedBefore do
                    task.wait(0.1)
                    t += 0.1
                end
                if gameStarted > startedBefore then
                    t = 0
                    while t < 14 and alive and gameAnswered == answeredBefore do
                        task.wait(0.2)
                        t += 0.2
                    end
                    task.wait(1.2)
                end
                rubberCooldown[p] = os.clock() + 10
            end
        end
    end)
end

local function applyRubberTap()
    if S.autoRubberTap then
        if not disableGameHandlers() and getconnections then
            -- ไม่พบตัวรับมินิเกมของเกม (อาจปิดไว้แล้ว) ถือว่าพร้อมใช้งาน
        end
    else
        restoreGameHandlers()
    end
end
applyRubberTap()
loop(3, function() if S.autoRubberTap then rubberTapBatch() end end)
loop(function() return S.waterEvery end, function()
    if env.TwoK_DEBUG then warn("[2K] water tick", S.autoWater, busy, #grownSpots()) end
    if S.autoWater then waterBatch() end
end)
local lastBuyCycle = math.floor(workspace:GetServerTimeNow() / 300)
local lastBuyCheck = 0
loop(2, function()
    if not S.autoBuy then return end
    local now = workspace:GetServerTimeNow()
    local cyc = math.floor(now / 300)
    if cyc ~= lastBuyCycle and now - cyc * 300 >= 3 then
        -- ร้านรีสต็อกแล้ว (ทุก 5 นาที): ไปดูของใหม่ทันที
        lastBuyCycle = cyc
        lastBuyCheck = os.clock()
        autoBuyStep(true)
        return
    end
    if os.clock() - lastBuyCheck >= S.buyEvery then
        lastBuyCheck = os.clock()
        autoBuyStep(false)
    end
end)
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

-- ESP ผลสุก (Object Pooling)
local espFolder = Instance.new("Folder")
espFolder.Name = "TwoK_ESP"
espFolder.Parent = workspace

local activeHighlights = {}
local highlightPool = {}

local function getHighlight(adornee)
    local h = table.remove(highlightPool)
    if not h or not h.Parent then
        h = Instance.new("Highlight")
        h.FillColor = Color3.new(1, 1, 1)
        h.FillTransparency = 0.5
        h.OutlineColor = Color3.new(1, 1, 1)
        h.Parent = espFolder
    end
    h.Adornee = adornee
    h.Enabled = true
    return h
end

local function releaseHighlight(adornee, h)
    if h then
        h.Enabled = false
        h.Adornee = nil
        highlightPool[#highlightPool + 1] = h
    end
    activeHighlights[adornee] = nil
end

loop(1.5, function()
    if not S.fruitEsp then
        for adornee, h in pairs(activeHighlights) do
            releaseHighlight(adornee, h)
        end
        return
    end

    local currentTargets = {}
    for _, p in ipairs(ripePrompts()) do
        local a = p.Parent
        if a and (a:IsA("BasePart") or a:IsA("Model")) then
            currentTargets[a] = true
            if not activeHighlights[a] then
                activeHighlights[a] = getHighlight(a)
            end
        end
    end

    for adornee, h in pairs(activeHighlights) do
        if not currentTargets[adornee] or not adornee:IsDescendantOf(workspace) then
            releaseHighlight(adornee, h)
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

local function createFruitViewport(id, sizeOffset)
    local vf = Instance.new("ViewportFrame")
    vf.Size = sizeOffset or UDim2.fromOffset(48, 48)
    vf.BackgroundTransparency = 1
    vf.BorderSizePixel = 0
    vf.Ambient = Color3.fromRGB(220, 220, 220)
    vf.LightColor = Color3.fromRGB(255, 255, 255)
    vf.LightDirection = Vector3.new(-1, -1, -1)

    local icon = FruitIcons and FruitIcons:FindFirstChild(id)
    if icon and icon:IsA("BasePart") then
        local clone = icon:Clone()
        clone.CFrame = CFrame.new()
        clone.Parent = vf

        local cam = Instance.new("Camera")
        cam.FieldOfView = 30
        local maxDim = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z)
        cam.CFrame = CFrame.lookAt(Vector3.new(1.2, 0.9, 1.6) * maxDim, Vector3.zero)
        vf.CurrentCamera = cam
        cam.Parent = vf
    else
        label({
            Text = THAI_INITIALS[id] or id:sub(1, 2),
            Weight = BOLD,
            TextSize = 16,
            TextColor3 = C.muted,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = vf,
        })
    end
    return vf
end

local function createShopIconViewport(id, size)
    local vf = Instance.new("ViewportFrame")
    vf.Size = size or UDim2.fromOffset(48, 48)
    vf.BackgroundTransparency = 1
    vf.BorderSizePixel = 0
    vf.Ambient = Color3.fromRGB(200, 200, 200)
    vf.LightColor = Color3.fromRGB(255, 255, 255)
    vf.LightDirection = Vector3.new(-0.4, -1, -0.6)

    local ok = false
    local src = ShopIcons and ShopIcons:FindFirstChild("Fert_" .. id)
    if src and src:IsA("Model") then
        ok = pcall(function()
            local m = src:Clone()
            local cf, sz = m:GetBoundingBox()
            m:PivotTo(m:GetPivot() - cf.Position)
            m.Parent = vf
            local cam = Instance.new("Camera")
            cam.FieldOfView = 30
            local dist = math.max(sz.X, sz.Y, sz.Z) * 2.4
            cam.CFrame = CFrame.lookAt(Vector3.new(1.2, 0.9, 1.6).Unit * dist, Vector3.zero)
            cam.Parent = vf
            vf.CurrentCamera = cam
        end)
    end
    if not ok then
        local meta = FERT_INFO[id]
        label({
            Text = meta and meta.Initial or id:sub(1, 2),
            Weight = BOLD, TextSize = 16, TextColor3 = C.muted,
            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center, Parent = vf,
        })
    end
    return vf
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
local liveRefreshers = {} -- ส่วนที่ต้องอัปเดตตามเวลาจริง (การ์ดเมล็ด หัวร้าน ชิป)
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

    function P:QuickStart(points, btnText, btnCb)
        local c = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = sf,
        }, { corner(12), stroke(), pad(14, 12, 14, 12) })
        sheen(c)

        new("UIListLayout", { Padding = UDim.new(0, 8), Parent = c })

        local h = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = c })
        label({ Text = "เริ่มต้นใช้งาน (Quick Start)", Weight = BOLD, TextSize = 15, TextColor3 = C.text, Size = UDim2.fromScale(1, 1), Parent = h })

        for _, pt in ipairs(points) do
            local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = c })
            label({ Text = pt, TextSize = 13, TextColor3 = C.muted, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
        end

        local b = new("TextButton", {
            Text = btnText, FontFace = font(BOLD), TextSize = 13, TextColor3 = C.black,
            Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.white, AutoButtonColor = false, Parent = c,
        }, { corner(8) })
        b.MouseButton1Click:Connect(function()
            local s = new("UIScale", { Parent = b })
            tween(s, 0.07, { Scale = 0.97 })
            task.delay(0.08, function()
                tween(s, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
                task.delay(0.25, function() s:Destroy() end)
            end)
            task.spawn(btnCb)
        end)
    end

    function P:ShopHeader(refreshCb)
        local c = new("Frame", {
            Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = sf,
        }, { corner(8), stroke(), pad(10, 0, 10, 0) })

        local infoLbl = label({
            Text = "ของใหม่ใน --:--  ·  อัปเดต: ยังไม่อัปเดต",
            TextColor3 = C.muted, TextSize = 12,
            Size = UDim2.new(1, -95, 1, 0), Position = UDim2.fromOffset(4, 0),
            Parent = c,
        })

        local btn = new("TextButton", {
            Text = "รีเฟรชร้าน", FontFace = font(BOLD), TextSize = 12, TextColor3 = C.text,
            Size = UDim2.fromOffset(80, 28), Position = UDim2.new(1, -80, 0.5, -14),
            BackgroundColor3 = C.hover, AutoButtonColor = false, Parent = c,
        }, { corner(6), stroke(C.stroke, 1) })

        btn.MouseButton1Click:Connect(function()
            task.spawn(refreshCb)
        end)

        local function updateHeader()
            infoLbl.Text = "ของใหม่ใน " .. formatRestockTime() .. "  ·  อัปเดต " .. formatLastUpdate()
        end
        updateHeader()
        onShopStateChanged[#onShopStateChanged + 1] = updateHeader
        refreshers[#refreshers + 1] = updateHeader
        liveRefreshers[#liveRefreshers + 1] = updateHeader
        return updateHeader
    end

    function P:SeedCards(items)
        local grid = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Parent = sf,
        }, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })

        local cardUpdaters = {}

        for _, id in ipairs(items) do
            local c = new("Frame", {
                Size = UDim2.new(1, 0, 0, 88), BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = grid,
            }, { corner(10), stroke() })

            -- กล่องไอคอน 3D / Fallback
            local iconBox = new("Frame", {
                Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(12, 13),
                BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = c,
            }, { corner(8), stroke(C.stroke, 1) })
            local vf = createFruitViewport(id, UDim2.fromScale(1, 1))
            vf.Parent = iconBox

            -- รายละเอียดเมล็ด
            local info = new("Frame", {
                Size = UDim2.new(1, -200, 1, -16), Position = UDim2.fromOffset(84, 8),
                BackgroundTransparency = 1, Parent = c,
            }, { new("UIListLayout", { Padding = UDim.new(0, 2) }) })

            local row1 = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = info })
            label({ Text = (THAI_NAMES[id] or id) .. " (" .. id .. ")", Weight = BOLD, TextSize = 14, Size = UDim2.new(1, 0, 1, 0), Parent = row1 })

            local row2 = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = info })
            local priceLbl = label({ Text = "$0", Weight = BOLD, TextSize = 13, TextColor3 = Color3.fromRGB(100, 225, 130), Size = UDim2.new(1, 0, 1, 0), Parent = row2 })

            local row3 = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = info })
            local stockLbl = label({ Text = "สต็อก 0/0  ·  ในตัว 0 ชิ้น", TextSize = 12, TextColor3 = C.muted, Size = UDim2.new(1, 0, 1, 0), Parent = row3 })

            -- ฝั่งขวา: ป้ายสถานะ & ปุ่มเลือกซื้อออโต้
            local rightBox = new("Frame", {
                Size = UDim2.fromOffset(104, 68), Position = UDim2.new(1, -114, 0.5, -34),
                BackgroundTransparency = 1, Parent = c,
            }, { new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

            local statusBadge = new("Frame", {
                Size = UDim2.fromOffset(82, 22), BackgroundColor3 = C.panel, Parent = rightBox,
            }, { corner(6), stroke(C.stroke) })
            local badgeText = label({
                Text = "ปกติ", TextSize = 11, TextColor3 = C.muted, Weight = BOLD,
                Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = statusBadge,
            })

            local toggleBtn = new("TextButton", {
                Text = "ซื้อออโต้", FontFace = font(BOLD), TextSize = 12, TextColor3 = C.muted,
                Size = UDim2.fromOffset(104, 32), BackgroundColor3 = C.panel, AutoButtonColor = false, Parent = rightBox,
            }, { corner(8), stroke(C.stroke) })

            local function updateCard()
                local item = getShopItem(id)
                local isSelected = S.buyList and S.buyList[id] == true
                local held = countHeldSeeds(id)
                local myCash = cash()
                local price = item.Price or 0
                local stock = item.Stock or 0
                local maxStock = item.Max or 0
                local growSec = item.GrowSeconds or 60
                local fruitVal = item.FruitValue or 0
                local rarity = item.Rarity or "Common"

                priceLbl.Text = "$" .. comma(price) .. "  ·  โต " .. growSec .. "s  ·  ผลละ $" .. comma(fruitVal)
                stockLbl.Text = "สต็อก " .. stock .. "/" .. maxStock .. "  ·  ในตัว " .. held .. " ชิ้น"

                if stock <= 0 then
                    statusBadge.Visible = true
                    statusBadge.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
                    badgeText.Text = "ของหมด"
                    badgeText.TextColor3 = Color3.fromRGB(255, 100, 100)
                elseif price > myCash then
                    statusBadge.Visible = true
                    statusBadge.BackgroundColor3 = Color3.fromRGB(45, 40, 20)
                    badgeText.Text = "เงินไม่พอ"
                    badgeText.TextColor3 = Color3.fromRGB(240, 180, 70)
                else
                    statusBadge.Visible = true
                    statusBadge.BackgroundColor3 = C.panel
                    badgeText.Text = rarity
                    badgeText.TextColor3 = RARITY_COLORS[rarity] or C.muted
                end

                if isSelected then
                    toggleBtn.BackgroundColor3 = C.white
                    toggleBtn.TextColor3 = C.black
                    toggleBtn.Text = "✓ ซื้อออโต้"
                    c.UIStroke.Color = Color3.fromRGB(110, 110, 110)
                else
                    toggleBtn.BackgroundColor3 = C.panel
                    toggleBtn.TextColor3 = C.muted
                    toggleBtn.Text = "+ เลือกซื้อ"
                    c.UIStroke.Color = C.stroke
                end

                local dimmed = (stock <= 0 or price > myCash)
                c.BackgroundTransparency = dimmed and 0.45 or 0
                iconBox.BackgroundTransparency = dimmed and 0.5 or 0
            end

            updateCard()
            cardUpdaters[#cardUpdaters + 1] = updateCard

            local function toggle()
                S.buyList = S.buyList or {}
                S.buyList[id] = not S.buyList[id]
                saveSettings()
                updateCard()
            end

            toggleBtn.MouseButton1Click:Connect(toggle)
            local hit = new("TextButton", {
                Text = "", Size = UDim2.new(1, -118, 1, 0), BackgroundTransparency = 1, Parent = c,
            })
            hit.MouseButton1Click:Connect(toggle)
        end

        local function refreshAllCards()
            for _, fn in ipairs(cardUpdaters) do fn() end
        end
        onShopStateChanged[#onShopStateChanged + 1] = refreshAllCards
        refreshers[#refreshers + 1] = refreshAllCards
        liveRefreshers[#liveRefreshers + 1] = refreshAllCards
        return refreshAllCards
    end

    function P:ShopItemCards(ids)
        local grid = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Parent = sf,
        }, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })
        local updaters = {}

        for _, id in ipairs(ids) do
            local meta = FERT_INFO[id] or { Name = id, Desc = "", Initial = id:sub(1, 2) }
            local c = new("Frame", {
                Size = UDim2.new(1, 0, 0, 108), BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = grid,
            }, { corner(10), stroke() })

            local iconBox = new("Frame", {
                Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(12, 23),
                BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = c,
            }, { corner(8), stroke(C.stroke, 1) })
            createShopIconViewport(id, UDim2.fromScale(1, 1)).Parent = iconBox

            local info = new("Frame", {
                Size = UDim2.new(1, -212, 1, -16), Position = UDim2.fromOffset(84, 8),
                BackgroundTransparency = 1, Parent = c,
            }, { new("UIListLayout", { Padding = UDim.new(0, 2) }) })
            local r1 = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = info })
            label({ Text = meta.Name, Weight = BOLD, TextSize = 14, Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd, Parent = r1 })
            local r2 = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = info })
            label({ Text = meta.Desc, TextSize = 12, TextColor3 = C.muted, TextWrapped = true, Size = UDim2.fromScale(1, 1), TextYAlignment = Enum.TextYAlignment.Top, Parent = r2 })
            local r3 = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = info })
            local priceLbl = label({ Text = "$0", Weight = BOLD, TextSize = 13, TextColor3 = Color3.fromRGB(100, 225, 130), TextWrapped = true, Size = UDim2.fromScale(1, 1), TextYAlignment = Enum.TextYAlignment.Top, Parent = r3 })

            local right = new("Frame", {
                Size = UDim2.fromOffset(110, 92), Position = UDim2.new(1, -120, 0.5, -46),
                BackgroundTransparency = 1, Parent = c,
            }, { new("UIListLayout", { Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
            local badge = new("Frame", { Size = UDim2.fromOffset(110, 22), BackgroundColor3 = C.panel, Parent = right }, { corner(6), stroke(C.stroke) })
            local badgeText = label({ Text = "-", TextSize = 11, Weight = BOLD, TextColor3 = C.muted, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })

            -- ปุ่มหลัก: ซื้ออัตโนมัติ
            local autoBtn = new("TextButton", {
                Text = "+ ซื้ออัตโนมัติ", FontFace = font(BOLD), TextSize = 12, TextColor3 = C.muted,
                Size = UDim2.fromOffset(110, 32), BackgroundColor3 = C.panel, AutoButtonColor = false, Parent = right,
            }, { corner(8), stroke(C.stroke) })

            -- แถวปรับจำนวนที่เก็บไว้ + ปุ่มซื้อมือ (รอง)
            local row = new("Frame", { Size = UDim2.fromOffset(110, 26), BackgroundTransparency = 1, Parent = right },
                { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }) })
            local function mini(txt, w)
                return new("TextButton", {
                    Text = txt, FontFace = font(BOLD), TextSize = 13, TextColor3 = C.text,
                    Size = UDim2.fromOffset(w, 26), BackgroundColor3 = C.hover, AutoButtonColor = false, Parent = row,
                }, { corner(6) })
            end
            local minus, plus, once = mini("−", 26), mini("+", 26), mini("ซื้อ 1", 48)

            local function maxKeep(item) return item.Unique and 1 or 20 end

            local function update()
                local item = getFertItem(id)
                local price = item.Price or 0
                local owned = item.Owned or 0
                local robux = item.Robux ~= nil
                local unique = item.Unique == true
                local target = itemTarget(id)
                local have = cash()

                if robux then
                    priceLbl.Text = "R$ " .. tostring(item.Robux) .. "\nซื้อด้วย Robux เท่านั้น"
                else
                    priceLbl.Text = "$" .. comma(price) .. "  ·  ในตัว " .. owned .. " ชิ้น"
                        .. (target > 0 and ("\nเก็บไว้ " .. target .. " ชิ้น") or "")
                end

                if robux then
                    badge.BackgroundColor3 = Color3.fromRGB(45, 40, 20)
                    badgeText.Text = "Robux"
                    badgeText.TextColor3 = Color3.fromRGB(240, 180, 70)
                elseif unique and owned > 0 then
                    badge.BackgroundColor3 = C.panel
                    badgeText.Text = "มีแล้ว"
                    badgeText.TextColor3 = C.muted
                elseif have < price then
                    badge.BackgroundColor3 = Color3.fromRGB(45, 40, 20)
                    badgeText.Text = "เงินไม่พอ"
                    badgeText.TextColor3 = Color3.fromRGB(240, 180, 70)
                else
                    badge.BackgroundColor3 = C.panel
                    badgeText.Text = item.Rarity or "Common"
                    badgeText.TextColor3 = RARITY_COLORS[item.Rarity or "Common"] or C.muted
                end

                local usable = not robux and not (unique and owned > 0)
                if target > 0 and usable then
                    autoBtn.BackgroundColor3 = C.white
                    autoBtn.TextColor3 = C.black
                    autoBtn.Text = "✓ ออโต้ · เก็บ " .. target
                    c.UIStroke.Color = Color3.fromRGB(110, 110, 110)
                else
                    autoBtn.BackgroundColor3 = C.panel
                    autoBtn.TextColor3 = usable and C.muted or Color3.fromRGB(90, 90, 90)
                    autoBtn.Text = usable and "+ ซื้ออัตโนมัติ" or (robux and "ไม่รองรับ" or "มีแล้ว")
                    c.UIStroke.Color = C.stroke
                end
                minus.Visible = usable and not unique
                plus.Visible = usable and not unique
                once.Visible = usable
                once.TextColor3 = (have >= price) and C.text or C.muted
                local dim = robux or (unique and owned > 0)
                c.BackgroundTransparency = dim and 0.45 or 0
                iconBox.BackgroundTransparency = dim and 0.5 or 0
            end
            update()
            updaters[#updaters + 1] = update

            local function setTarget(n)
                local item = getFertItem(id)
                if item.Robux then return end
                S.buyItems = S.buyItems or {}
                S.buyItems[id] = math.clamp(n, 0, maxKeep(item))
                if id == "RubberSapling" then S.buyRubberSaplings = 0 end -- ใช้ค่าจากการ์ดแทนสไลเดอร์เก่า
                saveSettings()
                update()
            end

            autoBtn.MouseButton1Click:Connect(function()
                local item = getFertItem(id)
                if item.Robux or (item.Unique and (item.Owned or 0) > 0) then return end
                if itemTarget(id) > 0 then setTarget(0) else setTarget(item.Unique and 1 or 3) end
                if itemTarget(id) > 0 and not S.autoBuy and notify then
                    notify("ซื้ออัตโนมัติ", "อย่าลืมเปิดสวิตช์ \"ซื้ออัตโนมัติ\" ด้านบนด้วย")
                end
            end)
            minus.MouseButton1Click:Connect(function() setTarget(itemTarget(id) - 1) end)
            plus.MouseButton1Click:Connect(function() setTarget(itemTarget(id) + 1) end)
            once.MouseButton1Click:Connect(function()
                if getFertItem(id).Robux then return end
                task.spawn(buyFertItem, id, 1)
            end)
        end

        local function refreshAll()
            for _, fn in ipairs(updaters) do fn() end
        end
        onShopStateChanged[#onShopStateChanged + 1] = refreshAll
        refreshers[#refreshers + 1] = refreshAll
        liveRefreshers[#liveRefreshers + 1] = refreshAll
        return refreshAll
    end

    function P:PlantSeedChips(options)
        local c = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = sf,
        }, { corner(10), stroke(), pad(10, 10, 10, 10) })

        local head = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = c })
        label({ Text = "เมล็ดที่ปลูก", Weight = BOLD, TextSize = 14, Size = UDim2.new(0.5, 0, 1, 0), Parent = head })
        local curLbl = label({
            Text = "เลือก: " .. (THAI_NAMES[S.plantSeed] or S.plantSeed),
            TextColor3 = C.muted, TextSize = 13, Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = head,
        })

        local grid = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 28),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = c,
        }, { new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 42), CellPadding = UDim2.fromOffset(8, 8) }) })

        local chipUpdaters = {}

        for _, id in ipairs(options) do
            local b = new("TextButton", {
                Text = "", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.panel,
                AutoButtonColor = false, Parent = grid,
            }, { corner(8), stroke(C.stroke, 1) })

            local icon = createFruitViewport(id, UDim2.fromOffset(30, 30))
            icon.Position = UDim2.fromOffset(6, 6)
            icon.Parent = b

            local name = label({
                Text = THAI_NAMES[id] or id, Weight = MED, TextSize = 13,
                Size = UDim2.new(1, -74, 1, 0), Position = UDim2.fromOffset(40, 0), Parent = b,
            })

            local countBadge = label({
                Text = "", TextColor3 = C.muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
                Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -36, 0, 0), Parent = b,
            })

            local function updateChip()
                local isSelected = S.plantSeed == id
                local held = (id == "Any") and totalAllHeldSeeds() or countHeldSeeds(id)
                countBadge.Text = "(" .. held .. ")"

                if isSelected then
                    b.BackgroundColor3 = C.hover
                    b.UIStroke.Color = C.white
                    b.UIStroke.Thickness = 1.5
                    name.TextColor3 = C.text
                    name.FontFace = font(BOLD)
                    countBadge.TextColor3 = C.text
                else
                    b.BackgroundColor3 = C.panel
                    b.UIStroke.Color = C.stroke
                    b.UIStroke.Thickness = 1
                    name.TextColor3 = C.muted
                    name.FontFace = font(MED)
                    countBadge.TextColor3 = C.muted
                end
            end

            b.MouseButton1Click:Connect(function()
                S.plantSeed = id
                curLbl.Text = "เลือก: " .. (THAI_NAMES[id] or id)
                saveSettings()
                for _, fn in ipairs(chipUpdaters) do fn() end
            end)

            updateChip()
            chipUpdaters[#chipUpdaters + 1] = updateChip
        end

        local function refreshChips()
            curLbl.Text = "เลือก: " .. (THAI_NAMES[S.plantSeed] or S.plantSeed)
            for _, fn in ipairs(chipUpdaters) do fn() end
        end
        refreshers[#refreshers + 1] = refreshChips
        liveRefreshers[#liveRefreshers + 1] = refreshChips
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

home:QuickStart({
    "1. ปลูกเมล็ดในแปลงว่าง และรดน้ำที่บ่อ (บอทรดได้ในระยะ 35 studs)",
    "2. บอทจะเก็บผลสุกและวาร์ปไปขายที่โกดังอัตโนมัติเมื่อถุงถึง 80%",
    "3. เลือกเมล็ดที่ต้องการในหน้าร้านค้า เพื่อให้บอทซื้อมาเติมแปลงว่าง",
}, "ตั้งค่าแนะนำสำหรับปล่อยฟาร์มยาวๆ", function()
    S.autoHarvest = true
    S.autoSell = true
    S.sellPercent = 80
    S.autoPlant = true
    S.autoWater = true
    S.waterEvery = 20
    S.autoBuy = true
    local anyBuy = false
    for _, on in pairs(S.buyList or {}) do if on then anyBuy = true break end end
    if not anyBuy then
        S.buyList = { ["Kradumthong"] = true }
    end
    S.antiAfk = true
    S.lowGfx = true
    pcall(applyLowGfx)
    saveSettings()
    refreshUI()
    notify("ตั้งค่าแนะนำ", "เปิดระบบฟาร์มครบวงจรสำหรับการ AFK ยาวๆ เรียบร้อยแล้ว")
end)

home:Section("ภาพรวม")
local tiles = home:Tiles({ "เงิน", "ถุง", "ผลสุก", "รีเบิร์ธ", "น้ำ", "สถานะ" })
home:Section("ทั่วไป")
home:Toggle("กัน AFK", "antiAfk", nil, "ป้องกันการถูกเตะเมื่อไม่ได้ขยับตัว")
home:Toggle("ลดแล็ก (กราฟิกต่ำ)", "lowGfx", applyLowGfx, "ลดภาระเครื่อง ช่วยให้ FPS นิ่งเมื่อฟาร์มนานๆ")

local farm = createPage("ฟาร์ม")
farm:Section("เก็บเกี่ยว")
farm:Toggle("เก็บเกี่ยวอัตโนมัติ", "autoHarvest", nil, "วาร์ปเก็บผลสุกเมื่อถุงยังว่าง")
farm:Toggle("ไฮไลต์ผลสุก (ESP)", "fruitEsp", nil, "แสดงกล่องเรืองแสงที่ผลพร้อมเก็บ")
farm:Section("ขาย")
farm:Toggle("ขายอัตโนมัติ", "autoSell", nil, "วาร์ปไปขายที่โกดังเมื่อผลไม้ในถุงถึงเกณฑ์")
farm:Slider("ขายเมื่อถุงเต็ม", "sellPercent", 10, 100, "%")
farm:Button("ขายตอนนี้", function() sellAll(true) end)
farm:Section("ปลูก")
farm:Toggle("ปลูกอัตโนมัติ", "autoPlant", nil, "ถือเมล็ดแล้วปลูกในแปลงว่างอัตโนมัติ")
farm:PlantSeedChips(ALL_PLANT_SEEDS)
farm:Section("ยางพารา")
farm:Toggle("ปลูกต้นยางอัตโนมัติ", "autoRubber", nil, "ปลูกต้นกล้ายางในแปลงยางที่ว่าง (ซื้อต้นกล้าอัตโนมัติได้ในหน้าร้านค้า)")
farm:Toggle("กรีดยาง/ใส่กรดอัตโนมัติ", "autoRubberTap", function()
    applyRubberTap()
    if S.autoRubberTap and not getconnections and notify then
        notify("ยางพารา", "executor นี้ไม่รองรับ getconnections หน้ามินิเกมของเกมอาจเด้งขึ้นมา")
    end
end, "ทำมินิเกมกรีดยาง/ใส่กรดให้เอง (รดน้ำอัตโนมัติจะรดต้นยางให้ด้วย)")
farm:Section("รดน้ำ")
farm:Toggle("รดน้ำอัตโนมัติ", "autoWater", nil, "รดน้ำทุกต้น และเติมน้ำที่บ่อเมื่อหมด")
farm:Slider("รดทุกๆ", "waterEvery", 5, 120, " วิ")
farm:Button("รดน้ำทุกต้นตอนนี้", function() waterBatch(true) end)
farm:Button("เติมน้ำที่บ่อ", function()
    exclusive(function()
        local ok = refillWater()
        notify("เติมน้ำ", ok and ("น้ำเต็ม " .. waterUses() .. " หยด") or "เติมไม่สำเร็จ")
    end)
end)

local shop = createPage("ร้านค้า")
shop:Section("ซื้ออัตโนมัติ")
shop:Toggle("ซื้อเมล็ดอัตโนมัติ", "autoBuy", nil, "ซื้อเมล็ดที่เลือกเมื่อมีแปลงว่างและเงินพอ")
shop:Slider("เมล็ดสำรองในตัว", "buyKeep", 0, 10, " ชิ้น")
shop:Slider("เก็บเงินสำรอง", "cashReserve", 0, 50000, " $")
shop:Slider("ตรวจร้านทุกๆ", "buyEvery", 3, 60, " วิ")

shop:Section("รายการเมล็ดพันธุ์")
local shopInfo = shop:ShopHeader(function()
    refreshShop()
end)
shop:SeedCards(BUYABLE_SEEDS)

shop:Section("ปุ๋ย ยา และของอื่นในร้าน")
shop:ShopItemCards(FERTS_ORDER)

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
local KNOWN_CODES = { "Shanakung", "DURIAN", "Tester", "FIX BUG", "SORRY", "Watergun", "LOVEADMIN", "poppy5star", "DUM888" }
misc:Button("ใส่โค้ดทั้งหมดที่รู้จัก", function()
    local okCount = 0
    for _, code in ipairs(KNOWN_CODES) do
        local ok, res = pcall(function() return Remotes.Codes:InvokeServer(code) end)
        if ok and res == true then okCount += 1 end
        task.wait(0.8)
    end
    notify("โค้ด", "ใส่สำเร็จ " .. okCount .. " จาก " .. #KNOWN_CODES .. " โค้ด (ที่เหลือใช้ไปแล้วหรือหมดอายุ)")
end, true)
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

-- อัปเดตส่วนที่เปลี่ยนตามเวลาจริง
loop(1, function()
    for _, fn in ipairs(liveRefreshers) do pcall(fn) end
end)

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
        for adornee, h in pairs(activeHighlights) do releaseHighlight(adornee, h) end
        for _, h in ipairs(highlightPool) do pcall(function() h:Destroy() end) end
        pcall(function() espFolder:Destroy() end)
        onShopStateChanged = {}
        pcall(restoreGameHandlers)
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

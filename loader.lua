-- ============================================================
--  2SKI Universal Script Hub & Telemetry Loader v3
--  Features:
--    1. Multi-Map Auto-Routing via PlaceId & Central Registry
--    2. Real-Time ID & Telemetry Tracker (Who runs, which map)
--    3. Anti-Environment & Tamper Protection
--    4. Maintenance Killswitch per Game
-- ============================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local currentPlaceId = game.PlaceId

local GITHUB_BASE = "https://raw.githubusercontent.com/hxrendontcry/2kscripts/main/"
local cacheBust = "?t=" .. tostring(os.time())

-- Notification Helper
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "2K Script Hub",
            Text = text or "",
            Duration = duration or 5
        })
    end)
end

-- Telemetry Reporter (ส่งข้อมูล ID ผู้รันเข้า Web Dashboard แบบไม่ขัดจังหวะ)
local function sendTelemetry(action, details)
    task.spawn(function()
        pcall(function()
            local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
            if not requestFunc then return end

            local gameName = "Roblox Experience"
            pcall(function()
                gameName = MarketplaceService:GetProductInfo(currentPlaceId).Name
            end)

            local execName = "Unknown"
            pcall(function()
                execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Executor"
            end)

            local payload = {
                userId = localPlayer.UserId,
                username = localPlayer.Name,
                displayName = localPlayer.DisplayName,
                placeId = currentPlaceId,
                gameName = gameName,
                executor = execName,
                action = action or "execute",
                details = details or {}
            }

            -- Telemetry endpoints: 24/7 Permanent Vercel Server + Localhost fallback
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

-- ── Heartbeat Watchdog: ส่งสัญญาณชีพทุก 35 วินาที เพื่อให้แดชบอร์ดระบุว่า ONLINE ตลอดเวลาที่เล่น ──
task.spawn(function()
    while true do
        task.wait(35)
        sendTelemetry("heartbeat", { ping = true })
    end
end)

-- ── Layer 1: Anti-Environment Guard ──────────────────────────
local okAnti, anti = pcall(function()
    return loadstring(game:HttpGet(GITHUB_BASE .. "anti_env.lua" .. cacheBust))()
end)

if okAnti and anti then
    pcall(anti.enforce)
    anti.startWatchdog(25)
else
    local genv = getgenv and getgenv() or _G
    if genv.Hydroxide or genv.RemoteSpy or genv.SimpleSpy then
        localPlayer:Kick("[2SKI] Blocked")
        error("", 0)
    end
end

-- ── Layer 2: Universal Map Routing & Execution ────────────────
local function executeTargetScript(scriptUrl, gameTitle)
    notify("2K Script Hub", "กำลังโหลดสคริปต์สำหรับ " .. (gameTitle or "เกมนี้") .. "...", 3)
    sendTelemetry("execute", { title = gameTitle, url = scriptUrl })

    local okFetch, src = pcall(game.HttpGet, game, scriptUrl .. cacheBust)
    if not okFetch or not src or src == "" then
        notify("2K Script Hub", "เกิดข้อผิดพลาดในการดาวน์โหลดสคริปต์", 6)
        return
    end

    local fn, err = loadstring(src)
    if not fn then
        notify("2K Script Hub", "Syntax Error: " .. tostring(err), 8)
        error("[2SKI] Compile error: " .. tostring(err), 0)
        return
    end

    local okRun, runErr = pcall(fn)
    if not okRun then
        notify("2K Script Hub", "Runtime Error: " .. tostring(runErr), 8)
        warn("[2SKI] Execution failed: " .. tostring(runErr))
    end
end

-- ดึงสารบัญเกมจาก GitHub Registry
local okGames, gamesJson = pcall(game.HttpGet, game, GITHUB_BASE .. "games.json" .. cacheBust)
local matchedGame = nil

if okGames and gamesJson and gamesJson ~= "" then
    local okParse, gamesList = pcall(function()
        return HttpService:JSONDecode(gamesJson)
    end)

    if okParse and type(gamesList) == "table" then
        for _, g in ipairs(gamesList) do
            if g.placeIds and type(g.placeIds) == "table" then
                for _, pid in ipairs(g.placeIds) do
                    if tonumber(pid) == tonumber(currentPlaceId) then
                        matchedGame = g
                        break
                    end
                end
            end
            if matchedGame then break end
        end
    end
end

-- ประมวลผลผลลัพธ์การจับคู่แมพ
if matchedGame then
    if matchedGame.status == "maintenance" then
        notify("2K Script Hub", "สคริปต์แมพ [" .. matchedGame.name .. "] กำลังปิดปรับปรุงชั่วคราว", 7)
        sendTelemetry("maintenance_alert", { name = matchedGame.name })
        return
    end

    executeTargetScript(matchedGame.scriptUrl, matchedGame.name)
else
    -- Fallback เฉพาะกรณี PlaceId 118805555015549 (Loot to Forge)
    if tonumber(currentPlaceId) == 118805555015549 then
        executeTargetScript(GITHUB_BASE .. "LootToForge.luau", "+1 ของรางวัลที่จะหลอม (Loot to Forge)")
    else
        -- แมพที่ยังไม่รองรับ: บันทึกข้อมูลเข้า Dashboard เพื่อให้แอดมินรู้ว่าคนอยากเล่นแมพไหน
        local gName = "Roblox Experience"
        pcall(function()
            gName = MarketplaceService:GetProductInfo(currentPlaceId).Name
        end)

        sendTelemetry("unsupported", { name = gName, placeId = currentPlaceId })
        notify("2K Script Hub", "แมพนี้ยังไม่รองรับ (" .. gName .. ")\nPlaceId: " .. tostring(currentPlaceId) .. " บันทึกคำขอแล้ว!", 8)
    end
end

-- ============================================================
--  2SKI Anti-Environment Engine v2
--  Layer 1: Hook / Dump / Spy detection + integrity
-- ============================================================

local _anti = {}

local rawget    = rawget
local rawset    = rawset
local rawequal  = rawequal
local type      = type
local pcall     = pcall
local tostring  = tostring
local error     = error
local task_wait = task.wait
local os_clock  = os.clock

-- ── 1. Catalogue of known exploit/debug GC globals ───────────────────────────
local _DANGER_GLOBALS = {
    -- Remote spy tools
    "SimpleSpy", "RemoteSpy", "Hydroxide", "SynapseX_RemoteSpy",
    -- Dex explorer / instance inspector
    "Dex", "DexExplorer", "DEX",
    -- Script decompilers / dumpers  
    "ScriptDumper", "Decompiler", "IceHaxDumper",
    -- Debug injectors
    "ScriptEditor", "OwlHub", "Infinite_Yield",
    -- Coregui scanners
    "RawHax",
}

-- ── 2. Check if known spy/debug GC objects exist ─────────────────────────────
local function _checkDangerGlobals()
    local genv = getgenv and getgenv() or _G
    for _, name in ipairs(_DANGER_GLOBALS) do
        if rawget(genv, name) ~= nil then
            return true, name
        end
    end
    return false, nil
end

-- ── 3. Verify game metamethods not hooked ────────────────────────────────────
-- Hydroxide and most remote spies hook __namecall / __index on `game`
local function _checkMetamethodIntegrity()
    -- Get the raw metatable of game
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or type(mt) ~= "table" then return false end  -- can't even read = exploit

    -- Snapshot a reference call and check if it's a native C function
    local nc = rawget(mt, "__namecall")
    local ni = rawget(mt, "__index")

    -- If __namecall returns something that has an upvalue or is Lua closure = HOOKED
    local function isLuaClosure(f)
        if type(f) ~= "function" then return false end
        local ok2, info = pcall(debug and debug.info or function() end, f, "s")
        -- If source starts with "@" it's a Lua file — native should return "[C]"
        return ok2 and type(info) == "string" and info ~= "[C]"
    end

    if isLuaClosure(nc) or isLuaClosure(ni) then
        return false
    end
    return true
end

-- ── 4. Check if hookfunction / hooking utilities are exposed + used on us ────
local function _checkHookExposure()
    -- If hookfunction is tampered on known game:GetService it means somebody
    -- already pre-hooked the environment before us
    local genv = getgenv and getgenv() or _G
    -- Healthy executors will have hookfunction but it shouldn't be aliased to
    -- a Lua wrapper yet at this point in execution
    local hf = rawget(genv, "hookfunction") or rawget(genv, "replaceclosure")
    if hf == nil then return true end  -- no hookfunction = safe (vanilla executor or patched)

    -- Try hooking a dummy and see if the hook itself is double-hooked (nested hook = spy)
    local _dummy = function() return 1 end
    local _called = false
    local ok, err = pcall(function()
        local orig = hf(_dummy, function() _called = true; return 1 end)
        _dummy()
        -- Restore immediately
        pcall(hf, _dummy, orig)
    end)
    -- We don't flag _called here since we did it ourselves
    return ok  -- if pcall failed, hookfunction itself is broken/nested
end

-- ── 5. CoreGui ScreenGui scanner — Hydroxide / Dex GUI detection ─────────────
local function _scanCoreGuiForSpies()
    local cg = game:GetService("CoreGui")
    local suspicious = {
        "HydroxideGUI", "DexGui", "RemoteSpyGUI", "HydroInfo",
        "SimpleSpy", "synapsedbg", "ScriptEditor",
    }
    for _, child in ipairs(cg:GetChildren()) do
        local n = child.Name
        for _, pat in ipairs(suspicious) do
            if string.find(string.lower(n), string.lower(pat)) then
                return true, n
            end
        end
    end
    return false, nil
end

-- ── 6. Time-check: detect debugger pausing execution ─────────────────────────
local function _checkTimingIntegrity()
    local t0 = os_clock()
    -- trivial tight loop
    local s = 0
    for i = 1, 50000 do s = s + i end
    local dt = os_clock() - t0
    -- If someone paused execution mid-script with a debugger / breakpoint
    -- the elapsed time would be absurdly large
    return dt < 3.0, dt
end

-- ── 7. Main gate: run all checks, crash if hostile env ───────────────────────
function _anti.enforce()
    -- Danger globals
    local hasDanger, dangerName = _checkDangerGlobals()
    if hasDanger then
        game:GetService("Players").LocalPlayer:Kick(
            "[2SKI] Hostile environment detected (" .. dangerName .. ")"
        )
        error("__2SKI_BLOCKED__", 0)
    end

    -- CoreGui scan
    local hasGui, guiName = _scanCoreGuiForSpies()
    if hasGui then
        game:GetService("Players").LocalPlayer:Kick(
            "[2SKI] Remote spy GUI detected (" .. guiName .. ")"
        )
        error("__2SKI_BLOCKED__", 0)
    end

    -- Metamethod & Timing: pass-through to prevent false-positives on executors with Luau bridges
    return true
end

-- ── 8. Background watchdog — continuous monitoring while script runs ──────────
function _anti.startWatchdog(intervalSecs)
    intervalSecs = intervalSecs or 15
    task.spawn(function()
        while task_wait(intervalSecs) do
            local hasDanger = _checkDangerGlobals()
            local hasGui    = _scanCoreGuiForSpies()
            if hasDanger or hasGui then
                -- Corrupt _G quietly, stop all loops
                rawset(getgenv and getgenv() or _G, "TwoSkiRunning", false)
                rawset(getgenv and getgenv() or _G, "TwoSkiLoaded",  false)
                -- Destroy UI silently
                pcall(function()
                    for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
                        if v.Name:find("2SKI") or v.Name:find("WindUI") then
                            v:Destroy()
                        end
                    end
                end)
                break
            end
        end
    end)
end

return _anti

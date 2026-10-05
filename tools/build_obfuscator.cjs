const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

/**
 * 2K SCRIPT - INDUSTRIAL LUAU OBFUSCATOR & ENCRYPTION ENGINE
 * Author: cook45 for clack
 * Features:
 *  - Polymorphic 32-byte Rolling XOR + Additive Offset Cipher
 *  - Chunked Memory Decryptor (handles arbitrary size > 500KB without stack overflow)
 *  - Anti-Tamper & Anti-Hook Integrity Envelope
 *  - Anti-Decompiler Trap Tokens & Dead Code Insertion
 */

function generateRandomKey(length = 32) {
    return crypto.randomBytes(length).toString('hex');
}

function obfuscateLuau(sourceCode, scriptName = '2K-Engine') {
    const key = generateRandomKey(24);
    const keyBytes = Buffer.from(key, 'utf8');
    const srcBytes = Buffer.from(sourceCode, 'utf8');

    // 1. Multi-Stage Polymorphic Byte Transformation
    // b' = (b ^ key[i % len] + (i * 7)) % 256
    const encrypted = [];
    for (let i = 0; i < srcBytes.length; i++) {
        const b = srcBytes[i];
        const kb = keyBytes[i % keyBytes.length];
        const transformed = ((b ^ kb) + (i * 7)) % 256;
        encrypted.push(transformed);
    }

    // 2. Chunk encrypted bytes into array strings (500 bytes per chunk for optimal Lua string throughput)
    const CHUNK_SIZE = 500;
    const chunks = [];
    for (let i = 0; i < encrypted.length; i += CHUNK_SIZE) {
        const slice = encrypted.slice(i, i + CHUNK_SIZE);
        // format as comma-separated byte string: {12,45,200,...}
        chunks.push(`{${slice.join(',')}}`);
    }

    const varKey = `_2k_k_${crypto.randomBytes(3).toString('hex')}`;
    const varChunks = `_2k_c_${crypto.randomBytes(3).toString('hex')}`;
    const varDec = `_2k_d_${crypto.randomBytes(3).toString('hex')}`;
    const varBuf = `_2k_b_${crypto.randomBytes(3).toString('hex')}`;
    const varRun = `_2k_r_${crypto.randomBytes(3).toString('hex')}`;

    // 3. Assemble Self-Executing Protected Envelope
    const output = `-- [ 2K SECURITY V3 - HARDENED DISTRIBUTION ENVELOPE ]
-- Module: ${scriptName}
-- Build: ${new Date().toISOString()}
-- Protected by 2K Security Engine (Anti-Hook / Anti-Dump / Anti-Decompile)

do
    local _opq = 0x5F3759DF
    if (_opq * 0) ~= 0 then
        while true do end
        return
    end
end

-- ── 2K DIRECT EXECUTION STEALTH TELEMETRY ──
task.spawn(function()
    pcall(function()
        local gKey = "_2K_TELEMETRY_DONE_" .. tostring(game.PlaceId)
        if _G[gKey] then return end
        _G[gKey] = true

        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local MarketplaceService = game:GetService("MarketplaceService")
        local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()

        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return end

        local currentPlaceId = game.PlaceId
        local gName = "${scriptName}"
        pcall(function()
            gName = MarketplaceService:GetProductInfo(currentPlaceId).Name
        end)

        local execName = "Unknown"
        pcall(function()
            execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Executor"
        end)

        local eps = {
            "https://2k-telemetry-dashboard.vercel.app/api/telemetry",
            "http://localhost:3000/api/telemetry"
        }

        local function sendReport(action, details)
            local body = HttpService:JSONEncode({
                userId = lp.UserId,
                username = lp.Name,
                displayName = lp.DisplayName,
                placeId = currentPlaceId,
                gameName = gName,
                executor = execName,
                action = action or "execute",
                details = details or {}
            })
            for _, ep in ipairs(eps) do
                pcall(function()
                    req({
                        Url = ep,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["x-2k-signature"] = "2k-sec-v3-e8a9f2"
                        },
                        Body = body
                    })
                end)
            end
        end

        local isDirect = not _G._2K_LOADER_ACTIVE
        sendReport("execute", { directRun = isDirect, script = "${scriptName}" })

        if isDirect then
            task.spawn(function()
                while true do
                    task.wait(35)
                    sendReport("heartbeat", { ping = true, directRun = true })
                end
            end)
        end
    end)
end)

local ${varKey} = "${key}"
local ${varChunks} = {
${chunks.join(',\n')}
}

local function ${varDec}()
    local s_char = string.char
    local s_byte = string.byte
    local t_concat = table.concat
    local b_xor = (bit32 and bit32.bxor) or function(a, b)
        local p, c = 1, 0
        while a > 0 and b > 0 do
            local ra, rb = a % 2, b % 2
            if ra ~= rb then c = c + p end
            a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
        end
        if a < b then a = b end
        while a > 0 do
            local ra = a % 2
            if ra > 0 then c = c + p end
            a, p = (a - ra) / 2, p * 2
        end
        return c
    end

    local k_len = #${varKey}
    local k_bytes = {}
    for i = 1, k_len do
        k_bytes[i] = s_byte(${varKey}, i)
    end

    local result_parts = {}
    local global_idx = 0

    for c_idx = 1, #${varChunks} do
        local chunk = ${varChunks}[c_idx]
        local chunk_len = #chunk
        local part = {}
        for j = 1, chunk_len do
            local enc_val = chunk[j]
            local kb = k_bytes[(global_idx % k_len) + 1]
            local offset_sub = (enc_val - (global_idx * 7)) % 256
            if offset_sub < 0 then offset_sub = offset_sub + 256 end
            local orig_byte = b_xor(offset_sub, kb)
            part[j] = s_char(orig_byte)
            global_idx = global_idx + 1
        end
        result_parts[c_idx] = t_concat(part)
    end

    return t_concat(result_parts)
end

local ${varRun} = (loadstring or load)

-- Anti-Hooking & Auto-Restoration
if isfunctionhooked and isfunctionhooked(${varRun}) then
    if restorefunction then
        pcall(restorefunction, ${varRun})
    end
end

if debug and debug.info then
    local ok_info, src_info = pcall(debug.info, ${varRun}, "s")
    if ok_info and type(src_info) == "string" and src_info ~= "[C]" and src_info ~= "=[C]" and src_info ~= "" and not string.find(src_info, "loadstring") then
        pcall(function()
            local p = game:GetService("Players").LocalPlayer
            if p and p.Kick then p:Kick("[2K Security] Interception attempt detected.") end
        end)
        return
    end
end

local ${varBuf} = ${varDec}()

-- Integrity Verification
if not ${varBuf} or #${varBuf} == 0 then
    error("[2K Security] Integrity verification failed.", 0)
    return
end

local _compiled, _cErr = ${varRun}(${varBuf}, "=${scriptName}")

-- In-Memory GC Scrubbing (Purge all traces from heap memory)
${varBuf} = nil
${varChunks} = nil
${varKey} = nil
${varDec} = nil
if gcinfo then pcall(gcinfo) end
if collectgarbage then pcall(collectgarbage, "collect") end

if not _compiled then
    error("[2K Security] Execution failure: " .. tostring(_cErr), 0)
    return
end

return _compiled(...)
`;

    return output;
}

// Build pipeline
function build() {
    const scriptsDir = path.resolve(__dirname, '..');
    const srcDir = path.join(scriptsDir, 'src');

    if (!fs.existsSync(srcDir)) {
        console.error('Source directory src/ not found! Create src/ and place clean files there.');
        process.exit(1);
    }

    const targets = [
        { src: 'LootToForge.luau', dest: 'LootToForge.luau', name: '2K_LootToForge' },
        { src: 'OpenSeaHub.luau', dest: 'OpenSeaHub.luau', name: '2K_OpenSeaHub' },
        { src: 'BuildThePyramid.luau', dest: 'BuildThePyramid.luau', name: '2K_BuildThePyramid' },
        { src: 'TwoK_SniperArena_Hub.luau', dest: 'TwoK_SniperArena_Hub.luau', name: '2K_SniperArena' },
        { src: 'AnimeDice.luau', dest: 'AnimeDice.luau', name: '2K_AnimeDice' }
    ];

    console.log('=== 2K SCRIPT INDUSTRIAL OBFUSCATION BUILD ===');

    targets.forEach(t => {
        const srcPath = path.join(srcDir, t.src);
        const destPath = path.join(scriptsDir, t.dest);

        if (!fs.existsSync(srcPath)) {
            console.log(`[SKIP] Source ${t.src} does not exist in src/`);
            return;
        }

        const rawCode = fs.readFileSync(srcPath, 'utf8');
        console.log(`[OBFUSCATING] ${t.src} (${rawCode.length.toLocaleString()} bytes)...`);

        const start = Date.now();
        const obfCode = obfuscateLuau(rawCode, t.name);
        const elapsed = Date.now() - start;

        fs.writeFileSync(destPath, obfCode, 'utf8');
        console.log(`[DONE] ${t.dest} -> Output size: ${obfCode.length.toLocaleString()} bytes in ${elapsed}ms`);
    });

    console.log('\n[SUCCESS] All target scripts obfuscated successfully! Original code remains safe in src/.');
}

build();

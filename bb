--//doitenroi.9941
local Players = game:GetService("Players")
if not script_key then
    Players.LocalPlayer:Kick("Key not found make sure running script with key")
    return
end
local doitenroi =
    (function()
    local function a(b)
        return (b:gsub(
            ".",
            function(c)
                return string.format("%02X", string.byte(c))
            end
        ))
    end

    local function c(d)
        return (d:gsub(
            "..",
            function(e)
                return string.char(tonumber(e, 16))
            end
        ))
    end

    local function f(g, h)
        local i = 0
        local j = 1
        while g > 0 or h > 0 do
            local k = g % 2
            local l = h % 2
            if k ~= l then
                i = i + j
            end
            j = j * 2
            g = math.floor(g / 2)
            h = math.floor(h / 2)
        end
        return i
    end

    local function m(n, o)
        local p = {}
        local q = #o
        for r = 1, #n do
            local s = string.byte(n, r)
            local t = string.byte(o, (r - 1) % q + 1)
            p[r] = string.char(f(s, t))
        end
        return table.concat(p)
    end

    local function u(v, w)
        w = w % 8
        local x = math.floor(v / 2 ^ w)
        local y = (v * 2 ^ (8 - w)) % 256
        local function z(A, B)
            local C = 0
            local D = 1
            while A > 0 or B > 0 do
                local E = A % 2
                local F = B % 2
                if E ~= F then
                    C = C + D
                end
                D = D * 2
                A = math.floor(A / 2)
                B = math.floor(B / 2)
            end
            return C
        end
        return z(y, x)
    end

    local function G(H, I)
        local J = {}
        for K = 1, #H do
            local L = string.byte(H, K)
            local M = u(L, 8 - I)
            J[K] = string.char(M)
        end
        return table.concat(J)
    end

    local function N(O)
        local P = "doitenroi"
        local Q = 3
        local R = c(O)
        local S = G(R, Q)
        local T = m(S, P)
        return T
    end

    local U = {
        [1] = "25A0E5A9A6EAA6AB6B4AC6C4854221880BE4A12BE4E70A2B86C4C0C6E4E0C645",
        [2] = "C50745E80A8223E04562A3C3674485E0A4650A67CB42A30B49E2C5006B45E0E5",
        [3] = "8B8487838482E3E6A34A2BC704A2C644E4264AEBA724C263E867E1C5670AC4E0"
    }

    local V = {
        __index = function(_, W)
            local X = U[W]
            if X then
                return N(X)
            else
                error("[doitenroi] Invalid key access", 0)
            end
        end,
        __newindex = function()
            error("[doitenroi] Write denied", 0)
        end,
        __metatable = "[doitenroi] LOCKED"
    }

    local Y = setmetatable({}, V)

    local Z = {
        __index = function(_, aa)
            if aa == "keygen" then
                return Y
            else
                error("[doitenroi] Access violation", 0)
            end
        end,
        __newindex = function()
            error("[doitenroi] Write denied", 0)
        end,
        __metatable = "[doitenroi] LOCKED"
    }

    local ab = setmetatable({}, Z)
    return ab
end)()

local function toHex(str)
    return (str:gsub(
        ".",
        function(c)
            return string.format("%02X", c:byte())
        end
    ))
end
local function fromHex(hex)
    return (hex:gsub(
        "..",
        function(cc)
            return string.char(tonumber(cc, 16))
        end
    ))
end
local function bxor(a, b)
    local res = 0
    local bitval = 1
    while a > 0 or b > 0 do
        local abit = a % 2
        local bbit = b % 2
        if abit ~= bbit then
            res = res + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return res
end

local function mul32(a, b)
    local aLow = a % 0x10000
    local aHigh = math.floor(a / 0x10000)
    local bLow = b % 0x10000
    local bHigh = math.floor(b / 0x10000)

    local low = aLow * bLow
    local mid = aLow * bHigh + aHigh * bLow
    local high = aHigh * bHigh

    local carry = math.floor(low / 0x10000) + (mid % 0x10000)
    local resultLow = low % 0x10000 + (carry % 0x10000) * 0x10000
    local resultHigh = high + math.floor(mid / 0x10000) + math.floor(carry / 0x10000)

    return (resultHigh % 0x10000) * 0x10000 + (resultLow % 0x10000)
end

local function fnv1a(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bxor(hash, string.byte(str, i))
        hash = mul32(hash, 16777619)
    end
    return string.format("%08x", hash)
end

local function verifysignature(key, securet, time, serverSignature, serverSecret)
    local input = key .. "|" .. securet .. "|" .. tostring(time) .. "|" .. serverSecret
    local computed = fnv1a(input)
    return computed == serverSignature
end
local function xor(data, key)
    local result = {}
    for i = 1, #data do
        local a = data:byte(i)
        local b = key:byte(((i - 1) % #key + 1))
        result[i] = string.char(bit32.bxor(a, b))
    end
    return table.concat(result)
end

local function reverse(str)
    return str:reverse()
end
local function shiftKey(key, iv)
    return xor(key:rep(math.ceil(#iv / #key)), iv)
end
local function randomIV()
    local iv = {}
    for i = 1, 8 do
        iv[i] = string.char(math.random(0, 255))
    end
    return table.concat(iv)
end
local function encrypt(content, key)
    local iv = randomIV()
    local shiftedKey = shiftKey(key, iv)
    local reversed = reverse(content)
    local encrypted = xor(reversed, shiftedKey)
    return reverse(toHex(iv .. encrypted))
end
local function decrypt(data, key)
    local decoded = fromHex(reverse(data))
    local iv = decoded:sub(1, 8)
    local encrypted = decoded:sub(9)
    local shiftedKey = shiftKey(key, iv)
    return reverse(xor(encrypted, shiftedKey))
end
local function randomString(len)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local t, i = {}, 1
    local seed = tostring(os.clock() * 1e9):reverse()

    while i <= len do
        local hash = 0
        local j = 1
        while j <= #seed do
            hash = (hash + seed:byte(j) * j) % 256
            j = j + 1
        end

        local idx = (hash + i * 73) % #charset + 1
        t[i] = charset:sub(idx, idx)
        seed = tostring(os.clock() * 1e9 + idx * i):reverse()
        i = i + 1
    end

    return table.concat(t)
end
local function jd(s)
    local function get(k)
        local i = 1
        local key = '"' .. k .. '":'
        while i <= #s do
            if s:sub(i, i + #key - 1) == key then
                i = i + #key
                while s:sub(i, i):match("%s") do
                    i = i + 1
                end
                if s:sub(i, i) == '"' then
                    i = i + 1
                    local start = i
                    while i <= #s and s:sub(i, i) ~= '"' do
                        i = i + 1
                    end
                    return s:sub(start, i - 1)
                else
                    local start = i
                    while i <= #s and s:sub(i, i):match("%d") do
                        i = i + 1
                    end
                    return tonumber(s:sub(start, i - 1))
                end
            end
            i = i + 1
        end
    end

    return {
        status = get("status"),
        notes = get("notes"),
        expiredtime = get("expiredtime"),
        execution = get("execution"),
        integrity = get("integrity"),
        key = get("key")
    }
end
local function jsencode(tbl)
    local parts = {}
    table.insert(parts, "{")
    local first = true
    for k, v in pairs(tbl) do
        if not first then
            table.insert(parts, ",")
        end
        first = false
        table.insert(parts, '"' .. tostring(k) .. '":')

        local t = typeof(v)
        if t == "string" then
            table.insert(parts, '"' .. v:gsub('"', '\\"') .. '"')
        else
            table.insert(parts, tostring(v))
        end
    end
    table.insert(parts, "}")
    return table.concat(parts)
end
local function getclientid()
    if gethwid then
        return gethwid()
    elseif request then
        local res =
            request(
            {
                Url = "https://doitenroi.vercel.app/api/test",
                Method = "POST"
            }
        )
        return res and res.Body or nil
    else
        return nil
    end
end
local function validate(wlkey)
    local hwid = getclientid()
    local timesent = os.time()
    local randomstr = randomString(32)

    local encryptedData = encrypt(jsencode({key = wlkey,hwida = hwid,time = tostring(timesent),securet = randomstr}), doitenroi.keygen[1])

    local success, res =
        pcall(
        function()
            return request(
                {
                    Url = "https://doitenroi.vercel.app/api/wlsystem",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsencode(
                        {
                            action = "validate",
                            data = encryptedData
                        }
                    )
                }
            )
        end
    )

    if not success or not res.Success then
        return "error", "Failed to reach server", 0, 0, nil
    end
    if islclousre and islclousre(request) or iscclosure and not iscclosure(request) then
        return "error", "Failed to reach server", 0, 0, nil
    end
    local decrypted = decrypt(res.Body, doitenroi.keygen[2])
    local decoded = jd(decrypted)
    if not decoded then
        return "error", "Invalid response", 0, 0, nil
    end
    return decoded.status, decoded.notes or "", decoded.integrity or "", timesent or 0, randomstr or "", decoded.expiredtime or
        0, decoded.execution or 0, decoded.key or ""
end

local status, notes, integrity, timeclient, secure, expired, exec, key = validate(script_key)
if status == "valid" then
    local verified = verifysignature(key, secure, timeclient, integrity, doitenroi.keygen[3])
    if not verified or script_key ~= key then
        return Players.LocalPlayer:Kick("integrity verify failed")
    end
elseif status == "hwidmismatch" then
    Players.LocalPlayer:Kick("Key Linked With Different Hwid. Use /resethwid for reset hwid on this key")
    return
elseif status == "expired" then
    Players.LocalPlayer:Kick("Your Key Is Expired")
    return
elseif status == "invalid" then
    Players.LocalPlayer:Kick("Your Key Is Invalid")
    return
elseif status == "hwidnotfound" then
    Players.LocalPlayer:Kick("not found hwid in executor")
    return
else
    Players.LocalPlayer:Kick(notes)
    return
end
loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Vogiahungpro/Lol/refs/heads/main/fat"))()

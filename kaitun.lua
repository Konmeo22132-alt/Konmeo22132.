--[[
  GAG2 Kaitun — Auto nuôi acc

  getgenv().KaitunConfig = { MovementMode = "legit" | "cheat", ... }
  loadstring(readfile("kaitun.lua"))()

  Runtime API (after load):
    getgenv().KaitunStop()   — stop all loops gracefully
    getgenv().KaitunRunning  — boolean
    getgenv().KaitunState    — { phase, status, ... }

  Deep-dive docs: KAITUN_MODULES.md
]]

-- Giá seed GAG2 (rẻ → đắt) — tên khớp với SeedShop UI thật trong game
local SEED_CATALOG = {
    { name = "Carrot", price = 1 },
    { name = "Strawberry", price = 10 },
    { name = "Blueberry", price = 25 },
    { name = "Tulip", price = 40 },
    { name = "Tomato", price = 200 },
    { name = "Apple", price = 400 },
    { name = "Bamboo", price = 700 },
    { name = "Corn", price = 2500 },
    { name = "Cactus", price = 5000 },
    { name = "Pineapple", price = 10000 },
    { name = "Mushroom", price = 15000 },
    { name = "Green Bean", price = 20000 },
    { name = "Banana", price = 30000 },
    { name = "Grape", price = 50000 },
    { name = "Coconut", price = 70000 },
    { name = "Dragon Fruit", price = 120000 },
    { name = "Mango", price = 300000 },
    { name = "Acorn", price = 700000 },
    { name = "Cherry", price = 1200000 },
    { name = "Sunflower", price = 1500000 },
    { name = "Venus Fly Trap", price = 7000000 },
    { name = "Pomegranate", price = 12000000 },
    { name = "Poison Apple", price = 25000000 },
    { name = "Venom Spitter", price = 50000000 },
    { name = "Moon Bloom", price = 65000000 },
    { name = "Dragon's Breath", price = 90000000 },
}

local PET_CATALOG = {
    "Bear", "Bee", "BlackDragon", "Bunny", "Deer", "Frog", "GoldenDragonfly",
    "IceSerpent", "Monkey", "Owl", "Raccoon", "Robin", "Turtle", "Unicorn",
}

local function buildSeedToggles(enabledNames)
    local map = {}
    local set = {}
    if type(enabledNames) == "table" then
        for _, n in ipairs(enabledNames) do set[n] = true end
    end
    for _, entry in ipairs(SEED_CATALOG) do
        map[entry.name] = set[entry.name] == true
    end
    map.Gold = false
    map.Rainbow = false
    return map
end

local function buildPetToggles(enabledNames)
    local map = {}
    local set = {}
    if type(enabledNames) == "table" then
        for _, n in ipairs(enabledNames) do set[n] = true end
    end
    for _, name in ipairs(PET_CATALOG) do
        map[name] = set[name] == true
    end
    return map
end

local DEFAULT_CONFIG = {
    MovementMode = "cheat",

    BuySeed = {
        Enable = true,
        Seed = buildSeedToggles({
            "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo",
            "Corn", "Cactus", "Pineapple", "Mushroom", "Green Bean", "Banana", "Grape",
        }),
    },

    PlantSeed = {
        Enable = true,
        Seed = buildSeedToggles({
            "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo",
            "Corn", "Cactus", "Pineapple", "Mushroom", "Green Bean", "Banana", "Grape",
        }),
    },

    GiftMail = {
        Enable = false,
        RecipientUserId = "",
        RecipientName = "",
        Message = "auto-shipped from kaitun",
        IntervalSec = 30,
        Pet = buildPetToggles({}),
        Seed = buildSeedToggles({}),
    },

    Tutorial = {
        Enable = true,
        SendFirstPet = true,
        -- Auto-tutorial flow: tạo file Surge Hub/Surge.json, mua 1 carrot → plant →
        -- harvest (đợi inventory +1 carrot) → sell → mark tutorialDone=true trong file.
        -- Flow chính (buy/plant/harvest/sell) bị BLOCK cho đến khi tutorial xong.
        AutoFlow = true,
        SeedName = "Carrot",
        HarvestTimeout = 60,   -- giây, chờ harvest carrot
    },

    PetFinder = {
        Enable = true,
        Pet = buildPetToggles({ "Owl" }),
        HopCooldown = 45,
        MoneyWhenHop = 50000000,
    },

    BuyGears = { "Common Sprinkler", "Common Watering Can" },
    MaxBuysPerCycle = 50,
    MaxBuysPerTick = 25,
    PlantAttemptsPerTick = 32,
    MaxInventoryTools = 83,
    HarvestInterval = 1,
    PlantAttemptsPerCycle = 48,
    Sprinkler = "Common Sprinkler",
    AutoWater = true,
    StackSpacing = 1.2,
    StackMaxPlants = 64,
    BuyLoopInterval = 1,
    PlantLoopInterval = 0.05,
    HarvestLoopInterval = 0.1,
    SellLoopInterval = 0.3,
    BuyBackoffSec = 5,
    KeepBudgetSheckles = 0,
    SeedHoardTarget = 200,
    QuickProfitMode = false,       -- Chỉ mua seed rẻ (ROI nhanh cho short-term profit)
    QuickProfitMaxPrice = 1000,    -- Giá seed tối đa khi QuickProfitMode = true
    DeleteNonFarmPlants = false,
    AutoExpand = true,
    AutoCollectGold = true,
    AutoCollectRainbow = true,
    WorldSeedSnatchTimeout = 3,
    AutoOpenEggs = true,
    EggPriority = { "Common Egg", "Epic Egg" },
    AutoEquipPet = true,
    AutoUpgradePetSlot = true,
    WebhookUrl = "",
    WebhookInterval = 120,
    -- Webhook định kỳ 30s: tài khoản, tiền, tổng seed, số pet
    WebhookStatusInterval = 30,
    -- Webhook khi collect được seed Gold/Rainbow + tổng số đã collect
    WebhookOnSeedCollect = true,
    -- Webhook filter: chỉ thông báo pet/seed theo rarity/name (từ top1 script)
    WebhookPetRarity = { "Mythic", "Super", "Secret" },
    WebhookSeedName = {
        "Dragon's Breath", "Venus Fly Trap", "Pomegranate", "Poison Apple",
        "Venom Spitter", "Ghost Pepper", "Romanesco", "Moon Bloom",
    },
    AntiAfk = true,
    StayInBase = true,
    -- HopServer = false → KHÔNG hop server dưới BẤT CỨ trường hợp nào (dù PetFinder muốn hop)
    HopServer = true,
    MainLoopDelay = 0.25,
    RemoteCooldown = 0.10,
    SellInterval = 1,
    ExpandInterval = 12,
    FpsCap = 30,
    LowGraphics = true,
    UseFFlags = true,
    HideGarden3D = true,
    ShowUI = true,
    UIUpdateInterval = 1,
    InvScanInterval = 3,
}

local function deepMerge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            deepMerge(dst[k], v)
        else
            dst[k] = v
        end
    end
end

local function cloneTable(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = type(v) == "table" and cloneTable(v) or v
    end
    return c
end

local Config = cloneTable(DEFAULT_CONFIG)
if type(getgenv().KaitunConfig) == "table" then
    deepMerge(Config, getgenv().KaitunConfig)
end

local function normalizePetFinderConfig()
    local pf = Config.PetFinder
    local legacyPet = Config.TargetPet
    if pf == true then
        Config.PetFinder = {
            Enable = true,
            Pet = buildPetToggles(legacyPet and { legacyPet } or { "Owl" }),
            HopCooldown = 45,
            MoneyWhenHop = 50000000,
        }
    elseif type(pf) ~= "table" then
        Config.PetFinder = {
            Enable = false,
            Pet = buildPetToggles({}),
            HopCooldown = 45,
            MoneyWhenHop = 50000000,
        }
    else
        pf.Pet = pf.Pet or buildPetToggles({})
        pf.HopCooldown = pf.HopCooldown or 45
        pf.MoneyWhenHop = pf.MoneyWhenHop or 50000000
        if legacyPet and pf.Pet[legacyPet] == nil then
            pf.Pet[legacyPet] = true
        end
    end
end
normalizePetFinderConfig()

local ALL_SEEDS_BY_PRICE = SEED_CATALOG
local PetNames = PET_CATALOG

local function isSeedEnabled(section, seedName)
    if type(section) ~= "table" or section.Enable ~= true then return false end
    local seeds = section.Seed
    return type(seeds) == "table" and seeds[seedName] == true
end

local function isPetGiftEnabled(petName)
    local mail = Config.GiftMail
    if type(mail) ~= "table" or mail.Enable ~= true then return false end
    return type(mail.Pet) == "table" and mail.Pet[petName] == true
end

local function isSeedGiftEnabled(seedName)
    local mail = Config.GiftMail
    if type(mail) ~= "table" or mail.Enable ~= true then return false end
    return type(mail.Seed) == "table" and mail.Seed[seedName] == true
end

local function isPetFinderEnabled()
    return type(Config.PetFinder) == "table" and Config.PetFinder.Enable == true
end

local function isPetFinderTarget(petName)
    if not isPetFinderEnabled() then return false end
    return type(Config.PetFinder.Pet) == "table" and Config.PetFinder.Pet[petName] == true
end

local function getPetFinderHopMoney()
    local pf = Config.PetFinder
    return (type(pf) == "table" and tonumber(pf.MoneyWhenHop)) or 50000000
end

local function getPetFinderHopCooldown()
    local pf = Config.PetFinder
    return (type(pf) == "table" and tonumber(pf.HopCooldown)) or 45
end

local function resolveGiftRecipientId()
    local mail = Config.GiftMail
    if type(mail) ~= "table" then return end
    local uid = tonumber(mail.RecipientUserId)
    if uid then return uid end
    local name = mail.RecipientName
    if type(name) == "string" and name ~= "" then
        local ok, id = pcall(function()
            return game:GetService("Players"):GetUserIdFromNameAsync(name)
        end)
        if ok and id then return id end
    end
end

if Config.MovementMode then
    getgenv().movement_mode = Config.MovementMode
elseif getgenv().movement_mode == nil then
    getgenv().movement_mode = "cheat"
end

-- ── Lightweight dashboard UI (no WindUI / no HttpGet) ─────────────────────────

local Gui = { Body = nil, Panel = nil, Screen = nil, visible = true }
local PerfState = {
    currentFps = 0,
    hideGarden3D = false,
    fflagsOn = false,
    lowGfxOn = false,
    hiddenParts = {},
    hideConn = nil,
    hideSweepTask = nil,
    lastHideSweep = 0,
}
local UICache = {
    inv = nil,
    invAt = 0,
    worldPlants = 0,
    worldPlantsAt = 0,
    garden = nil,
    gardenAt = 0,
}

-- ── Services ────────────────────────────────────────────────────────────────

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Gardens = workspace:WaitForChild("Gardens")
local NightVal = ReplicatedStorage:WaitForChild("Night")
local Net = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))

local KaitunRunning = true
local TravelActive = false
local FarmLoopsStarted = false
local RemoteLastFire = {}
local State = {
    phase = "init",
    nextHarvestAt = 0,
    lastHarvest = 0,
    lastWater = 0,
    lastExtras = 0,
    tutorialDone = false,
    tutorialStarted = false,
    tutorialPhase = "",
    lastHop = 0,
    lastSell = 0,
    lastExpand = 0,
    lastWebhook = 0,
    lastStatusWebhook = 0,
    lastPetMgmt = 0,
    lastBuy = 0,
    lastPlant = 0,
    lastSell = 0,
    status = "Starting...",
    -- Tracking seed Gold/Rainbow đã collect
    goldSeedCollected = 0,
    rainbowSeedCollected = 0,
    petHuntBackoffUntil = 0,
    -- Uptime & rejoin tracking
    startTime = os.time(),
    lastRejoinNotified = 0,
}

local PetHuntFails = {}

-- ── Logging ─────────────────────────────────────────────────────────────────

local function log(msg)
    State.status = tostring(msg)
    print("[Kaitun] " .. State.status)
end

local function fireRemote(key, fn, cooldown)
    cooldown = cooldown or Config.RemoteCooldown
    local now = os.clock()
    if RemoteLastFire[key] and (now - RemoteLastFire[key]) < cooldown then
        return false
    end
    RemoteLastFire[key] = now
    local ok = pcall(fn)
    return ok
end

-- ── Movement ────────────────────────────────────────────────────────────────

local MoveArriveDist = 5
local MoveTimeout = 22
local MovementToken = 0

local function fmtMoney(n)
    local s = tostring(math.floor(n or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return out:sub(1, 1) == "," and out:sub(2) or out
end

local function getMovementMode()
    local g = getgenv and getgenv() or {}
    local mode = type(g.movement_mode) == "string" and g.movement_mode:lower() or "cheat"
    return mode == "legit" and "legit" or "cheat"
end

local function isLegitMovement()
    return getMovementMode() == "legit"
end

local function cancelMovement()
    MovementToken += 1
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getGroundPosition(pos)
    local origin = Vector3.new(pos.X, pos.Y + 25, pos.Z)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if LocalPlayer.Character then table.insert(exclude, LocalPlayer.Character) end
    rayParams.FilterDescendantsInstances = exclude
    local hit = workspace:Raycast(origin, Vector3.new(0, -120, 0), rayParams)
    if hit then return hit.Position + Vector3.new(0, 3, 0) end
    return pos
end

local function moveToPosition(targetPos, activeCheck)
    activeCheck = activeCheck or function() return true end
    local myToken = MovementToken + 1
    MovementToken = myToken

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local HRP = getHRP()
    if not hum or not HRP or not activeCheck() then return false end

    local goal = getGroundPosition(targetPos)

    if getMovementMode() == "cheat" then
        if MovementToken ~= myToken or not activeCheck() then return false end
        HRP.CFrame = CFrame.new(goal)
        hum:MoveTo(goal)
        task.wait(0.15)
        return activeCheck() and MovementToken == myToken
    end

    hum:MoveTo(goal)
    local lastMoveAt = os.clock()
    local deadline = os.clock() + MoveTimeout
    while os.clock() < deadline do
        if not activeCheck() or MovementToken ~= myToken then return false end
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        HRP = getHRP()
        if not hum or not HRP then return false end
        local flatDist = (Vector3.new(HRP.Position.X, 0, HRP.Position.Z) - Vector3.new(goal.X, 0, goal.Z)).Magnitude
        if flatDist <= MoveArriveDist then return true end
        if os.clock() - lastMoveAt >= 2 then
            hum:MoveTo(goal)
            lastMoveAt = os.clock()
        end
        task.wait(0.2)
    end
    return false
end

-- ── Garden / Economy ────────────────────────────────────────────────────────

local function getMyGarden()
    for _, garden in pairs(Gardens:GetChildren()) do
        if garden:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return garden
        end
    end
end

local function getMyGardenCached()
    local now = os.clock()
    if UICache.garden and (now - UICache.gardenAt) < 2 then
        return UICache.garden
    end
    UICache.garden = getMyGarden()
    UICache.gardenAt = now
    return UICache.garden
end

local function getPlotId(garden)
    return tonumber(garden.Name:match("%d+"))
end

local SeedToolCache = { list = nil, at = 0 }
local function getSeedToolsMap()
    local now = os.clock()
    if SeedToolCache.list and (now - SeedToolCache.at) < 0.4 then
        return SeedToolCache.list
    end
    local map = {}
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") then
                local s = tool:GetAttribute("SeedTool")
                if s then map[s] = map[s] or tool end
            end
        end
    end
    scan(LocalPlayer.Backpack)
    scan(LocalPlayer.Character)
    SeedToolCache.list = map
    SeedToolCache.at = now
    return map
end

local function countSeedToolTotal()
    local n = 0
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") and tool:GetAttribute("SeedTool") then n += 1 end
        end
    end
    scan(LocalPlayer.Backpack)
    scan(LocalPlayer.Character)
    return n
end

local function getPlantableSeedList()
    local tools = getSeedToolsMap()
    local out = {}
    for _, entry in ipairs(ALL_SEEDS_BY_PRICE) do
        if isSeedEnabled(Config.PlantSeed, entry.name) and tools[entry.name] then
            table.insert(out, entry)
        end
    end
    return out
end

local function getSpendableSheckles()
    local s = getPlayerSheckles()
    local budget = tonumber(Config.KeepBudgetSheckles) or 0
    if s <= budget then return 0 end
    return s - budget
end

local function getPlayerSheckles()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local s = ls and ls:FindFirstChild("Sheckles")
    return s and s.Value or 0
end

local function getFruitCount()
    return tonumber(LocalPlayer:GetAttribute("FruitCount")) or 0
end

local function getMaxFruitCapacity()
    return tonumber(LocalPlayer:GetAttribute("MaxFruitCapacity")) or 100
end

local function getToolCount()
    local n = 0
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") then n += 1 end
        end
    end
    scan(LocalPlayer.Backpack)
    scan(LocalPlayer.Character)
    return n
end

local ToolCountCache = { n = 0, at = 0 }
local function getToolCountCached()
    local now = os.clock()
    if (now - ToolCountCache.at) < 0.3 then return ToolCountCache.n end
    ToolCountCache.n = getToolCount()
    ToolCountCache.at = now
    return ToolCountCache.n
end

local function isInventoryFull()
    return getFruitCount() >= getMaxFruitCapacity()
end

local function shouldBlockBuy()
    if isInventoryFull() then return true end
    if getToolCountCached() >= (Config.MaxInventoryTools or 83) - 5 then
        return countSeedToolTotal() > 0
    end
    return false
end

local function forceSell()
    local resp
    local ok = pcall(function()
        resp = Net.NPCS.SellAll:Fire()
    end)
    if ok and resp and resp.Success then
        State.lastSellPrice = resp.SellPrice or 0
        State.lastSoldCount = resp.SoldCount or 0
        State.totalEarned = (State.totalEarned or 0) + (resp.SellPrice or 0)
        return true
    end
    return false
end

local function getHomePosition()
    local garden = getMyGarden()
    if not garden then return end
    local visual = garden:FindFirstChild("Visual")
    local target = visual and (visual:FindFirstChild("GardenZonePart") or visual:FindFirstChild("PRIM"))
    return target and target.Position
end

local function findToolByAttribute(attrName, value)
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") then
                local attr = tool:GetAttribute(attrName)
                if attr and (not value or attr == value) then return tool end
            end
        end
    end
    local char = LocalPlayer.Character
    return scan(char) or scan(LocalPlayer.Backpack)
end

local LastEquippedTool = nil
local function equipTool(tool)
    if not tool then return nil end
    local char = LocalPlayer.Character
    -- Nếu tool đã equipped, return luôn
    if tool.Parent == char then return tool end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and tool.Parent == LocalPlayer.Backpack then
        hum:EquipTool(tool)
        task.wait(0.05)
    end
    return tool and tool.Parent == char and tool or nil
end

local function getPlantAreas(garden)
    local areas = {}
    for _, part in CollectionService:GetTagged("PlantArea") do
        if part:IsDescendantOf(garden) then table.insert(areas, part) end
    end
    return areas
end

local function getPlantPartPosition(plant)
    if plant.GetPivot then return plant:GetPivot().Position end
    local part = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position
end

local function plantNameInSet(seedName, set)
    if not seedName then return false end
    for _, name in ipairs(set) do
        if name == seedName then return true end
    end
    return false
end

local function countMyPlants(garden, filterSet)
    local n = 0
    local folder = garden:FindFirstChild("Plants")
    if not folder then return 0 end
    for _, plant in folder:GetChildren() do
        if plant:GetAttribute("UserId") ~= LocalPlayer.UserId then continue end
        local seedName = plant:GetAttribute("SeedName")
        if not filterSet or plantNameInSet(seedName, filterSet) then n += 1 end
    end
    return n
end

local function countOccupiedStackSlots(garden)
    local positions = getStackPositions(garden)
    local n = 0
    for _, pos in ipairs(positions) do
        if isTooCloseToPlant(pos, garden, Config.StackSpacing * 0.6) then
            n += 1
        end
    end
    return n
end

local function getStackPositions(garden)
    local areas = getPlantAreas(garden)
    if #areas == 0 then return {} end
    local area = areas[1]
    local center = (area.CFrame * CFrame.new(0, area.Size.Y / 2 + 0.5, 0)).Position
    local positions = {}
    local spacing = Config.StackSpacing
    local max = Config.StackMaxPlants
    local side = math.ceil(math.sqrt(max))
    for x = 0, side - 1 do
        for z = 0, side - 1 do
            local offset = Vector3.new((x - side / 2) * spacing, 0, (z - side / 2) * spacing)
            table.insert(positions, center + offset)
            if #positions >= max then return positions end
        end
    end
    return positions
end

local function isTooCloseToPlant(pos, garden, minDist)
    local folder = garden:FindFirstChild("Plants")
    if not folder then return false end
    for _, plant in folder:GetChildren() do
        local p = getPlantPartPosition(plant)
        if p then
            local dx, dz = p.X - pos.X, p.Z - pos.Z
            if math.sqrt(dx * dx + dz * dz) < (minDist or 1) then return true end
        end
    end
    return false
end

-- ── Farm actions ────────────────────────────────────────────────────────────

local function fireHarvest(plantId, fruitId)
    pcall(function()
        Net.Garden.CollectFruit:Fire(tostring(plantId), fruitId and tostring(fruitId) or "")
    end)
end

local function tryHarvest(garden)
    local folder = garden:FindFirstChild("Plants")
    if not folder then return 0 end
    local harvested = 0
    local myUid = LocalPlayer.UserId
    for _, plant in folder:GetChildren() do
        if not KaitunRunning then break end
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in fruitsFolder:GetChildren() do
                if fruit:GetAttribute("UserId") == myUid then
                    local plantId = fruit:GetAttribute("PlantId")
                    local fruitId = fruit:GetAttribute("FruitId")
                    if plantId and fruitId then
                        fireHarvest(plantId, fruitId)
                        harvested += 1
                        task.wait(0.08)
                    end
                end
            end
        elseif plant:GetAttribute("UserId") == myUid
            and plant:GetAttribute("PlantGrowthReady") == true then
            local plantId = plant:GetAttribute("PlantId")
            if plantId then
                fireHarvest(plantId, nil)
                harvested += 1
                task.wait(0.08)
            end
        end
    end
    return harvested
end

local function trySell()
    return forceSell()
end

local function getSeedShopStock(seedName)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local shop = pg:FindFirstChild("SeedShop")
    if not shop then return nil end
    local frame = shop:FindFirstChild("Frame")
    local normal = frame and frame:FindFirstChild("NormalShop")
    if not normal then return nil end
    local item = normal:FindFirstChild(seedName)
    if not item then return 0 end
    local main = item:FindFirstChild("Main_Frame")
    local label = main and main:FindFirstChild("Stock_Text")
    if not label or not label:IsA("TextLabel") then return nil end
    return tonumber(label.Text:match("x(%d+)")) or 0
end

local BuyBackoff = { untilTs = 0, reason = "" }
local function tryBuySeedsTiered(maxBuys)
    if not Config.BuySeed.Enable then return 0 end
    -- Backoff: nếu vừa fail, chờ trước khi thử lại
    if BuyBackoff.untilTs and os.clock() < BuyBackoff.untilTs then
        return 0
    end
    maxBuys = maxBuys or Config.MaxBuysPerCycle or 50
    local bought = 0
    local ranOutOfMoney = false
    local totalAvailableStock = 0   -- tổng stock tất cả seed enabled
    for _, entry in ipairs(ALL_SEEDS_BY_PRICE) do
        if bought >= maxBuys then break end
        if ranOutOfMoney then break end
        if not isSeedEnabled(Config.BuySeed, entry.name) then continue end
        -- QuickProfitMode: chỉ mua seed rẻ để tối ưu short-term profit
        if Config.QuickProfitMode and entry.price > (Config.QuickProfitMaxPrice or 1000) then
            continue
        end
        -- Đọc stock 1 lần đầu — nếu nil (GUI chưa load) hoặc 0 thì skip
        local stock = getSeedShopStock(entry.name)
        if stock == nil then continue end
        if stock <= 0 then continue end
        totalAvailableStock += stock
        local maxAttempts = math.min(stock, maxBuys - bought)
        local attempts = 0
        while attempts < maxAttempts and KaitunRunning do
            if shouldBlockBuy() then return bought end
            -- Check tiền thực tế mỗi lần (sheckles có thể giảm do plant/harvest khác)
            local currentSheckles = getPlayerSheckles()
            if currentSheckles < entry.price then
                ranOutOfMoney = true
                break
            end
            pcall(function()
                Net.SeedShop.PurchaseSeed:Fire(entry.name)
            end)
            bought += 1
            attempts += 1
            task.wait(0.05)
        end
    end
    -- Backoff khi không mua được gì — phân biệt lý do
    if bought == 0 then
        local backoff = Config.BuyBackoffSec or 5
        if ranOutOfMoney then
            BuyBackoff.reason = "out_of_money"
            -- Hết tiền: backoff dài hơn (10s) để chờ earn tiền từ sell
            backoff = 10
        elseif totalAvailableStock == 0 then
            BuyBackoff.reason = "no_stock"
            -- Hết stock: backoff ngắn (3s) vì restock có thể xảy ra bất cứ lúc nào
            backoff = 3
        else
            BuyBackoff.reason = "unknown"
        end
        BuyBackoff.untilTs = os.clock() + backoff
        log("Buy backoff " .. backoff .. "s — " .. BuyBackoff.reason)
    end
    return bought
end

local function findPlantPosition(garden)
    for _, pos in ipairs(getStackPositions(garden)) do
        if not isTooCloseToPlant(pos, garden, Config.StackSpacing * 0.6) then
            return pos
        end
    end
    for _, area in ipairs(getPlantAreas(garden)) do
        local cf, size = area.CFrame, area.Size
        local step = Config.StackSpacing
        for x = -size.X / 2, size.X / 2 - step, step do
            for z = -size.Z / 2, size.Z / 2 - step, step do
                local pos = (cf * CFrame.new(x, size.Y / 2 + 0.5, z)).Position
                if not isTooCloseToPlant(pos, garden, Config.StackSpacing * 0.6) then
                    return pos
                end
            end
        end
    end
end

local function tryPlantOneSeed(garden)
    if not Config.PlantSeed.Enable then return false end
    local pos = findPlantPosition(garden)
    if not pos then return false end

    local tools = getSeedToolsMap()
    -- Ưu tiên tool đã equipped (tránh equip lại)
    local char = LocalPlayer.Character
    for _, entry in ipairs(ALL_SEEDS_BY_PRICE) do
        if isSeedEnabled(Config.PlantSeed, entry.name) then
            local seedTool = tools[entry.name]
            if seedTool and seedTool.Parent == char then
                pcall(function()
                    Net.Plant.PlantSeed:Fire(pos, entry.name, seedTool)
                end)
                return true
            end
        end
    end
    -- Fallback: equip tool đầu tiên tìm thấy
    for _, entry in ipairs(ALL_SEEDS_BY_PRICE) do
        if not isSeedEnabled(Config.PlantSeed, entry.name) then continue end
        local seedTool = tools[entry.name]
        if not seedTool then continue end
        seedTool = equipTool(seedTool)
        if not seedTool then continue end
        pcall(function()
            Net.Plant.PlantSeed:Fire(pos, entry.name, seedTool)
        end)
        return true
    end
    return false
end

local function tryPlantAllSeeds(garden)
    local planted = 0
    for _ = 1, Config.PlantAttemptsPerCycle do
        if not tryPlantOneSeed(garden) then break end
        planted += 1
        task.wait(0.12)
    end
    return planted
end

local function tryDeletePlants(garden)
    if not Config.DeleteNonFarmPlants then return false end
    local shovel = findToolByAttribute("Shovel")
    if not shovel then return false end
    shovel = equipTool(shovel)
    if not shovel then return false end
    local shovelName = shovel:GetAttribute("Shovel")
    local folder = garden:FindFirstChild("Plants")
    if not folder then return false end
    for _, plant in folder:GetChildren() do
        if plant:GetAttribute("UserId") ~= LocalPlayer.UserId then continue end
        local seedName = plant:GetAttribute("SeedName")
        if isSeedEnabled(Config.PlantSeed, seedName) then continue end
        local plantId = plant:GetAttribute("PlantId")
        if plantId then
            fireRemote("shovel", function()
                Net.Shovel.UseShovel:Fire(tostring(plantId), "", shovelName, shovel)
            end, 0.2)
            return true
        end
    end
    return false
end

local function trySprinkler(garden)
    local plotId = getPlotId(garden)
    if not plotId then return false end
    local tool = findToolByAttribute("Sprinkler", Config.Sprinkler)
        or findToolByAttribute("Sprinkler")
    if not tool then return false end
    tool = equipTool(tool)
    if not tool then return false end
    local areas = getPlantAreas(garden)
    if #areas == 0 then return false end
    local pos = areas[1].Position
    return fireRemote("sprinkler", function()
        Net.Place.PlaceSprinkler:Fire(pos, tool:GetAttribute("Sprinkler"), tool, plotId)
    end, 5)
end

local function tryWater(garden)
    if Config.AutoWater == false then return false end
    local canTool = findToolByAttribute("WateringCan", "Common Watering Can")
        or findToolByAttribute("WateringCan")
    if not canTool then return false end
    canTool = equipTool(canTool)
    if not canTool then return false end
    local canName = canTool:GetAttribute("WateringCan")
    local folder = garden:FindFirstChild("Plants")
    if not folder then return false end
    local watered = false
    for _, plant in folder:GetChildren() do
        if not KaitunRunning then break end
        if plant:GetAttribute("UserId") ~= LocalPlayer.UserId then continue end
        local pos = getPlantPartPosition(plant)
        if pos then
            fireRemote("water_" .. tostring(plant:GetAttribute("PlantId")), function()
                Net.WateringCan.UseWateringCan:Fire(pos - Vector3.new(0, 0.3, 0), canName, canTool)
            end, 0.12)
            watered = true
            task.wait(0.12)
        end
    end
    return watered
end

local function tryExpand()
    if not Config.AutoExpand then return false end
    if os.clock() - State.lastExpand < Config.ExpandInterval then return false end
    State.lastExpand = os.clock()
    return fireRemote("expand", function()
        Net.Actions.ExpandGarden:Fire()
    end, Config.ExpandInterval)
end

local function tryBuyEssentials()
    for _, gear in ipairs(Config.BuyGears) do
        fireRemote("gear_" .. gear, function()
            Net.GearShop.PurchaseGear:Fire(gear)
        end, 0.15)
    end
end

local function findEggTool(eggName)
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") and tool:GetAttribute("Egg") == eggName then
                return tool
            end
        end
    end
    return scan(LocalPlayer.Backpack) or scan(LocalPlayer.Character)
end

local function findAnyEggTool()
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") and tool:GetAttribute("Egg") then
                return tool
            end
        end
    end
    return scan(LocalPlayer.Backpack) or scan(LocalPlayer.Character)
end

local function tryOpenEgg()
    if not Config.AutoOpenEggs then return false end
    local candidates = {}
    if type(Config.EggPriority) == "table" then
        for _, eggName in ipairs(Config.EggPriority) do
            table.insert(candidates, eggName)
        end
    end
    table.insert(candidates, "*")

    for _, eggName in ipairs(candidates) do
        local tool = eggName == "*" and findAnyEggTool() or findEggTool(eggName)
        if tool then
            local equipped = equipTool(tool)
            if equipped then
                fireRemote("openegg_" .. tostring(equipped:GetAttribute("Egg")), function()
                    Net.Egg.OpenEgg:Fire(equipped:GetAttribute("Egg"))
                end, 3.5)
                task.wait(3.5)
                return true
            end
        end
    end
    return false
end

-- ── World seeds (Gold / Rainbow) — highest priority snatcher ────────────────

local WorldSeedSnatcher = {
    claiming = false,
    seen = {},
    locs = nil,
    conns = {},
}

local function isWorldSeedCollectEnabled()
    return Config.AutoCollectGold or Config.AutoCollectRainbow
end

local function classifySpawnPart(part)
    if not part or not part.Parent then return nil end
    local isRainbow = part:GetAttribute("RainbowSeed") == true
    local isGold = part:GetAttribute("GoldSeed") == true
    if isRainbow and not Config.AutoCollectRainbow then return nil end
    if isGold and not Config.AutoCollectGold then return nil end
    if not isRainbow and not isGold then return nil end
    local pos
    if part:IsA("BasePart") then
        pos = part.Position
    elseif part.GetPivot then
        pos = part:GetPivot().Position
    end
    if not pos then return nil end
    return {
        part = part,
        pos = pos,
        name = isRainbow and "Rainbow" or "Gold",
        priority = isRainbow and 1 or 2,
    }
end

local function waitForSpawnTarget(part)
    local deadline = os.clock() + 1.2
    while part.Parent and os.clock() < deadline do
        local target = classifySpawnPart(part)
        if target then return target end
        task.wait(0.02)
    end
    return classifySpawnPart(part)
end

local function listActiveWorldSeedTargets()
    local locs = WorldSeedSnatcher.locs
    if not locs or not locs.Parent then
        locs = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SeedPackSpawnServerLocations")
        WorldSeedSnatcher.locs = locs
    end
    if not locs then return {} end

    local targets = {}
    for _, part in locs:GetChildren() do
        local target = classifySpawnPart(part)
        if target then
            table.insert(targets, target)
        end
    end
    table.sort(targets, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        local HRP = getHRP()
        if not HRP then return false end
        return (a.pos - HRP.Position).Magnitude < (b.pos - HRP.Position).Magnitude
    end)
    return targets
end

local function touchPartWithCharacter(part, goal)
    local char = LocalPlayer.Character
    local HRP = char and char:FindFirstChild("HumanoidRootPart")
    if not HRP or not part or not part.Parent then return end

    HRP.AssemblyLinearVelocity = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    HRP.CFrame = CFrame.new(goal)

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:MoveTo(goal)
    end

    if firetouchinterest then
        pcall(firetouchinterest, part, HRP, 0)
        pcall(firetouchinterest, part, HRP, 1)
    end

    for _, inst in char:GetDescendants() do
        if inst:IsA("BasePart") and inst ~= HRP then
            if firetouchinterest then
                pcall(firetouchinterest, part, inst, 0)
                pcall(firetouchinterest, part, inst, 1)
            end
        end
    end
end

local function snatchWorldSeedTarget(target)
    if not target or WorldSeedSnatcher.claiming then return false end
    WorldSeedSnatcher.claiming = true
    TravelActive = true
    cancelMovement()
    log("SNATCH " .. target.name .. " seed")
    State.phase = "seed_snatch"

    local deadline = os.clock() + (Config.WorldSeedSnatchTimeout or 3)
    local got = false

    while os.clock() < deadline and KaitunRunning do
        local part = target.part
        if not part or not part.Parent then
            got = true
            break
        end

        local pos = part:IsA("BasePart") and part.Position or part:GetPivot().Position
        local goal = pos + Vector3.new(0, 2, 0)
        touchPartWithCharacter(part, goal)

        if not part.Parent then
            got = true
            break
        end
        RunService.Heartbeat:Wait()
    end

    WorldSeedSnatcher.claiming = false
    TravelActive = false
    if got then
        log("Got " .. target.name .. " seed!")
        -- Track số lượng seed Gold/Rainbow đã collect
        if target.name == "Gold" then
            State.goldSeedCollected = (State.goldSeedCollected or 0) + 1
        elseif target.name == "Rainbow" then
            State.rainbowSeedCollected = (State.rainbowSeedCollected or 0) + 1
        end
        -- Webhook embed chi tiết: tách riêng Gold/Rainbow
        if Config.WebhookOnSeedCollect then
            local color, emoji, label
            if target.name == "Gold" then
                color, emoji, label = 0xF1C40F, "🥇", "Gold Seed"
            elseif target.name == "Rainbow" then
                color, emoji, label = 0xE74C3C, "🌈", "Rainbow Seed"
            else
                color, emoji, label = 0x9B59B6, "✨", target.name .. " Seed"
            end
            sendWebhookEmbed(
                emoji .. " Nhặt được " .. label,
                string.format("**%s** vừa nhặt được **%s**", LocalPlayer.Name, label),
                color,
                {
                    { name = "Seed", value = label, inline = true },
                    { name = "Gold đã collect", value = "×" .. tostring(State.goldSeedCollected or 0), inline = true },
                    { name = "Rainbow đã collect", value = "×" .. tostring(State.rainbowSeedCollected or 0), inline = true },
                }
            )
        else
            sendWebhookEmbed(
                "✨ Snatched " .. target.name .. " seed",
                string.format("**%s** nhặt được **%s** seed", LocalPlayer.Name, target.name),
                0x9B59B6
            )
        end
    end
    return got
end

local function rushWorldSeedAtPosition(pos)
    if not isWorldSeedCollectEnabled() or WorldSeedSnatcher.claiming then return end
    task.spawn(function()
        local HRP = getHRP()
        if HRP then
            TravelActive = true
            cancelMovement()
            HRP.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
        end
        for _ = 1, 40 do
            if WorldSeedSnatcher.claiming then return end
            local targets = listActiveWorldSeedTargets()
            if #targets > 0 then
                snatchWorldSeedTarget(targets[1])
                return
            end
            RunService.Heartbeat:Wait()
        end
        if not WorldSeedSnatcher.claiming then
            TravelActive = false
        end
    end)
end

local function onWorldSeedSpawn(part)
    if WorldSeedSnatcher.seen[part] then return end
    WorldSeedSnatcher.seen[part] = true
    task.spawn(function()
        local target = waitForSpawnTarget(part)
        if target then
            snatchWorldSeedTarget(target)
        end
    end)
end

local function startWorldSeedSnatcher()
    if not isWorldSeedCollectEnabled() then return end

    task.spawn(function()
        local map = workspace:WaitForChild("Map", 60)
        if not map then return end
        local locs = map:WaitForChild("SeedPackSpawnServerLocations", 60)
        if not locs then return end
        WorldSeedSnatcher.locs = locs

        for _, part in locs:GetChildren() do
            onWorldSeedSpawn(part)
        end

        table.insert(WorldSeedSnatcher.conns, locs.ChildAdded:Connect(onWorldSeedSpawn))
        table.insert(WorldSeedSnatcher.conns, locs.ChildRemoved:Connect(function(part)
            WorldSeedSnatcher.seen[part] = nil
        end))
    end)

    pcall(function()
        table.insert(WorldSeedSnatcher.conns, Net.SeedPackSpawn.FX.OnClientEvent:Connect(function(pos)
            if typeof(pos) == "Vector3" then
                rushWorldSeedAtPosition(pos)
            end
        end))
    end)

    table.insert(WorldSeedSnatcher.conns, RunService.Heartbeat:Connect(function()
        if not KaitunRunning or not isWorldSeedCollectEnabled() then return end
        if WorldSeedSnatcher.claiming then return end
        local targets = listActiveWorldSeedTargets()
        if #targets > 0 then
            task.spawn(function()
                snatchWorldSeedTarget(targets[1])
            end)
        end
    end))
end

local function tryCollectWorldSeeds()
    if WorldSeedSnatcher.claiming then return false end
    local targets = listActiveWorldSeedTargets()
    if #targets == 0 then return false end
    return snatchWorldSeedTarget(targets[1])
end

-- ── Pets ────────────────────────────────────────────────────────────────────

local function parsePromptPrice(text)
    if not text then return end
    local digits = text:gsub("[^%d]", "")
    if digits == "" then return end
    return tonumber(digits)
end

local function getWildPetPrice(target)
    if not target then return end
    local ref = target.ref
    local root = (ref and ref:FindFirstChild("RootPart")) or target.part
    if root then
        local attr = root:GetAttribute("Price")
        if type(attr) == "number" then return attr end
    end
    if target.price then return target.price end
    return parsePromptPrice(target.prompt and target.prompt.ObjectText)
end

local function wildPetPurchaseSucceeded(target, petName)
    if petName and playerOwnsPet(petName) then return true end
    if not target or not target.ref then return true end
    if not target.ref.Parent then return true end
    if target.ref:GetAttribute("OwnerUserId") == LocalPlayer.UserId then return true end
    if target.prompt and not target.prompt.Enabled then return true end
    return false
end

local function holdNearWildPet(target)
    local HRP = getHRP()
    local part = target and target.part
    if not HRP or not part or not part.Parent then return false end
    local maxDist = (target.prompt and target.prompt.MaxActivationDistance or 12) - 0.5
    local goal = part.CFrame * CFrame.new(0, 0, 2)
    HRP.AssemblyLinearVelocity = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    HRP.CFrame = goal
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:MoveTo(goal.Position) end
    return (HRP.Position - part.Position).Magnitude <= maxDist + 1
end

local function triggerHoldPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end
    local hold = (prompt.HoldDuration and prompt.HoldDuration > 0) and prompt.HoldDuration or 0.5
    local ok = pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, hold)
        else
            prompt:InputHoldBegin()
            task.wait(hold)
            prompt:InputHoldEnd()
        end
    end)
    task.wait(0.3)
    return ok
end

local function findWildPetTargets(petFilter)
    local targets = {}
    local folder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
    if not folder then return targets end
    for _, ref in folder:GetChildren() do
        if ref:GetAttribute("OwnerUserId") == LocalPlayer.UserId then continue end
        local petName = ref:GetAttribute("PetName") or ref.Name:match("^WildPet_([^_]+)_")
        if petName and (not petFilter or petName == petFilter) then
            local root = ref:FindFirstChild("RootPart")
            local prompt = root and root:FindFirstChild("BuyPrompt")
            if root and prompt and prompt.Enabled then
                table.insert(targets, {
                    name = petName, part = root, prompt = prompt, ref = ref,
                    price = root:GetAttribute("Price"),
                })
            end
        end
    end
    local HRP = getHRP()
    if HRP then
        table.sort(targets, function(a, b)
            return (a.part.Position - HRP.Position).Magnitude < (b.part.Position - HRP.Position).Magnitude
        end)
    end
    return targets
end

local function playerOwnsPet(petName)
    local function scan(container)
        if not container then return false end
        for _, item in container:GetChildren() do
            if item:IsA("Tool") and item:GetAttribute("Pet") == petName then return true end
            if item:GetAttribute("PetName") == petName then return true end
        end
        return false
    end
    return scan(LocalPlayer.Backpack) or scan(LocalPlayer.Character)
end

local function getPetFinderQueue()
    local list = {}
    if not isPetFinderEnabled() then return list end
    for _, name in ipairs(PET_CATALOG) do
        if isPetFinderTarget(name) then
            table.insert(list, name)
        end
    end
    return list
end

local function getActiveFinderPet()
    for _, name in ipairs(getPetFinderQueue()) do
        if not playerOwnsPet(name) then return name end
    end
end

local function getOwnedFinderPet()
    for _, name in ipairs(getPetFinderQueue()) do
        if playerOwnsPet(name) then return name end
    end
end

local function tryBuyWildPet(target)
    if not target or not target.ref or not target.ref.Parent then return false, "missing" end
    if target.ref:GetAttribute("OwnerUserId") == LocalPlayer.UserId then return false, "owned" end
    if not target.prompt or not target.prompt.Enabled then return false, "disabled" end

    local petName = target.name
    local failKey = tostring(target.ref)
    if (PetHuntFails[failKey] or 0) >= 3 then return false, "blacklist" end

    local price = getWildPetPrice(target)
    if price and getPlayerSheckles() < price then return false, "money" end

    cancelMovement()
    TravelActive = true

    local arrived = moveToPosition(target.part.Position, function() return KaitunRunning end)
    if not arrived then
        TravelActive = false
        return false, "move"
    end

    if not holdNearWildPet(target) then
        TravelActive = false
        return false, "too_far"
    end

    local tameKey = "wildpet_" .. failKey
    if isLegitMovement() then
        if not triggerHoldPrompt(target.prompt) then
            TravelActive = false
            PetHuntFails[failKey] = (PetHuntFails[failKey] or 0) + 1
            return false, "prompt"
        end
    else
        if not fireRemote(tameKey, function()
            Net.Pets.WildPetTame:Fire(target.ref)
        end, 0.35) then
            pcall(function()
                Net.Pets.WildPetTame:Fire(target.ref)
            end)
        end
    end

    local deadline = os.clock() + 3.5
    while os.clock() < deadline and KaitunRunning do
        if wildPetPurchaseSucceeded(target, petName) then
            PetHuntFails[failKey] = nil
            TravelActive = false
            return true
        end
        holdNearWildPet(target)
        task.wait(0.12)
    end

    TravelActive = false
    PetHuntFails[failKey] = (PetHuntFails[failKey] or 0) + 1
    if (PetHuntFails[failKey] or 0) >= 3 then
        State.petHuntBackoffUntil = os.clock() + 20
        log("Pet buy failed x3 — farm 20s then retry (" .. petName .. ")")
    end
    return false, "failed"
end

local function countOwnedPets()
    local n = 0
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if tool:IsA("Tool") and (tool:GetAttribute("Pet") or tool:GetAttribute("PetName")) then
                n += 1
            end
        end
    end
    scan(LocalPlayer.Backpack)
    scan(LocalPlayer.Character)
    return n
end

local function tryPetManagement()
    if Config.AutoUpgradePetSlot and countOwnedPets() >= 2 then
        fireRemote("petslot", function()
            Net.Pets.RequestPurchasePetSlot:Fire()
        end, 60)
    end
    if Config.AutoEquipPet then
        local equipName = getOwnedFinderPet() or getActiveFinderPet()
        if equipName then
            fireRemote("equip_" .. equipName, function()
                Net.Pets.RequestEquipByName:Fire(equipName)
            end, 5)
        end
    end
    tryOpenEgg()
end

local function huntFinderPetOnce()
    if not isPetFinderEnabled() then return false end
    local petName = getActiveFinderPet()
    if not petName then return false end
    local targets = findWildPetTargets(petName)
    if #targets == 0 then return false end
    for _, target in ipairs(targets) do
        local ok, reason = tryBuyWildPet(target)
        if ok then
            log("Bought wild pet: " .. target.name)
            return true
        elseif reason == "money" then
            log("Need more Sheckles for " .. target.name .. " (£" .. fmtMoney(getWildPetPrice(target) or 0) .. ")")
            return false
        elseif reason == "blacklist" then
            continue
        end
    end
    return false
end

-- ── Gift mail + tutorial ────────────────────────────────────────────────────

local function findGiftableTool()
    local function scan(container)
        if not container then return end
        for _, tool in container:GetChildren() do
            if not tool:IsA("Tool") then continue end
            local petName = tool:GetAttribute("Pet") or tool:GetAttribute("PetName")
            if petName and isPetGiftEnabled(petName) then
                return tool, "Pet", petName
            end
            if tool:GetAttribute("GoldSeed") == true and isSeedGiftEnabled("Gold") then
                return tool, "Seed", "Gold"
            end
            if tool:GetAttribute("RainbowSeed") == true and isSeedGiftEnabled("Rainbow") then
                return tool, "Seed", "Rainbow"
            end
            local seedName = tool:GetAttribute("SeedTool")
            if seedName and isSeedGiftEnabled(seedName) then
                return tool, "Seed", seedName
            end
        end
    end
    return scan(LocalPlayer.Character) or scan(LocalPlayer.Backpack)
end

local function hasAnyGiftPetEnabled()
    for _, name in ipairs(PET_CATALOG) do
        if isPetGiftEnabled(name) then return true end
    end
    return false
end

local function tryGiftMailOnce()
    local mail = Config.GiftMail
    if type(mail) ~= "table" or mail.Enable ~= true then return false end
    local uid = resolveGiftRecipientId()
    if not uid then return false end

    local tool, itemType, itemKey = findGiftableTool()
    if not tool then return false end

    tool = equipTool(tool) or tool
    local uuid = tool:GetAttribute("Uuid") or tool:GetAttribute("Pet")
        or tool:GetAttribute("SeedTool") or tool.Name

    return fireRemote("giftmail_" .. tostring(itemKey), function()
        Net.Gifting.Send:Fire(uid, itemType, uuid)
    end, mail.IntervalSec or 30)
end

local function canRunTutorial()
    local tut = Config.Tutorial
    if type(tut) ~= "table" or tut.Enable ~= true then return false end
    if tut.AutoFlow ~= true then
        -- Legacy: chỉ gửi pet qua GiftMail
        local mail = Config.GiftMail
        if type(mail) ~= "table" or mail.Enable ~= true then return false end
        if not resolveGiftRecipientId() then return false end
        return hasAnyGiftPetEnabled()
    end
    return true
end

-- ── Tutorial file (Surge Hub/Surge.json) ───────────────────────────────────
-- writefile/readfile/isfolder/makefiles từ executor. Fallback: in-memory.

local TutorialStore = { data = {}, loaded = false }

local function getTutorialFolderPath()
    return "Surge Hub"
end
local function getTutorialFilePath()
    return "Surge Hub/Surge.json"
end

local function loadTutorialFile()
    if TutorialStore.loaded then return TutorialStore.data end
    local raw
    pcall(function()
        if readfile then raw = readfile(getTutorialFilePath()) end
    end)
    if raw and #raw > 0 then
        local ok, parsed = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if ok and type(parsed) == "table" then
            TutorialStore.data = parsed
        end
    end
    TutorialStore.loaded = true
    return TutorialStore.data
end

local function saveTutorialFile()
    local raw = HttpService:JSONEncode(TutorialStore.data)
    pcall(function()
        if not isfolder or not isfolder(getTutorialFolderPath()) then
            if makefiles then makefiles(getTutorialFolderPath() .. "/") end
        end
        if writefile then writefile(getTutorialFilePath(), raw) end
    end)
end

local function getAccountKey()
    return LocalPlayer.Name .. "_" .. tostring(LocalPlayer.UserId)
end

local function isTutorialDoneInFile()
    local data = loadTutorialFile()
    local acc = data[getAccountKey()]
    if type(acc) ~= "table" then return false end
    return acc.tutorial == true
end

local function markTutorialDoneInFile()
    local data = loadTutorialFile()
    local key = getAccountKey()
    if type(data[key]) ~= "table" then data[key] = {} end
    data[key].account = LocalPlayer.Name
    data[key].tutorial = true
    data[key].doneAt = os.time()
    saveTutorialFile()
end

-- ── Tutorial flow: buy 1 carrot → plant → harvest (wait inventory +1) → sell ─

local function tutorialCountCarrotTools()
    local n = 0
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SeedTool") == Config.Tutorial.SeedName then
                n += 1
            end
        end
    end
    scan(LocalPlayer.Backpack)
    if LocalPlayer.Character then scan(LocalPlayer.Character) end
    return n
end

local function tutorialCountFruit()
    return tonumber(LocalPlayer:GetAttribute("FruitCount")) or 0
end

local function runAutoTutorialFlow()
    local tut = Config.Tutorial
    local seedName = tut.SeedName or "Carrot"
    State.tutorialPhase = "start"

    -- 1. Mua 1 seed
    State.tutorialPhase = "buy"
    log("Tutorial: mua 1 " .. seedName)
    local boughtOnce = false
    for _ = 1, 20 do
        if not KaitunRunning then return false end
        if tutorialCountCarrotTools() > 0 then boughtOnce = true; break end
        local stock = getSeedShopStock(seedName)
        if stock == nil then
            log("Tutorial: SeedShop GUI chưa load, chờ...")
            task.wait(0.5)
        elseif stock <= 0 then
            log("Tutorial: " .. seedName .. " hết stock, chờ restock...")
            task.wait(1)
        else
            pcall(function() Net.SeedShop.PurchaseSeed:Fire(seedName) end)
            task.wait(0.3)
        end
    end
    if not boughtOnce then
        log("Tutorial: không mua được " .. seedName .. " — retry sau")
        State.tutorialPhase = "buy_failed"
        return false
    end

    -- 2. Plant seed
    State.tutorialPhase = "plant"
    local garden = getMyGarden()
    if not garden then
        log("Tutorial: không tìm thấy garden — retry sau")
        return false
    end
    log("Tutorial: trồng " .. seedName)
    local planted = false
    for _ = 1, 10 do
        if not KaitunRunning then return false end
        local pos = findPlantPosition(garden)
        if not pos then
            log("Tutorial: không còn chỗ plant")
            break
        end
        local tools = getSeedToolsMap()
        local tool = tools[seedName]
        if not tool then
            log("Tutorial: mất seed tool?")
            break
        end
        tool = equipTool(tool) or tool
        pcall(function() Net.Plant.PlantSeed:Fire(pos, seedName, tool) end)
        task.wait(0.4)
        -- Check plant đã xuất hiện
        local plantsFolder = garden:FindFirstChild("Plants")
        if plantsFolder then
            for _, p in ipairs(plantsFolder:GetChildren()) do
                if p:GetAttribute("UserId") == LocalPlayer.UserId then
                    planted = true; break
                end
            end
        end
        if planted then break end
        task.wait(0.3)
    end
    if not planted then
        log("Tutorial: plant fail — retry sau")
        State.tutorialPhase = "plant_failed"
        return false
    end

    -- 3. Harvest — đợi plant ready rồi harvest (đợi inventory fruit +1)
    State.tutorialPhase = "harvest_wait"
    log("Tutorial: đợi " .. seedName .. " ready để harvest")
    local fruitBefore = tutorialCountFruit()
    local timeout = tut.HarvestTimeout or 60
    local t0 = os.clock()
    local harvested = false
    while KaitunRunning and (os.clock() - t0) < timeout do
        local plantsFolder = garden:FindFirstChild("Plants")
        local hasReady = false
        if plantsFolder then
            for _, p in ipairs(plantsFolder:GetChildren()) do
                if p:GetAttribute("UserId") == LocalPlayer.UserId then
                    local ff = p:FindFirstChild("Fruits")
                    if (ff and #ff:GetChildren() > 0)
                        or p:GetAttribute("PlantGrowthReady") == true then
                        hasReady = true; break
                    end
                end
            end
        end
        if hasReady then
            State.tutorialPhase = "harvest"
            tryHarvest(garden)
            task.wait(0.5)
            if tutorialCountFruit() > fruitBefore then
                harvested = true
                break
            end
        end
        task.wait(0.5)
    end
    if not harvested then
        log("Tutorial: harvest timeout — retry sau")
        State.tutorialPhase = "harvest_failed"
        return false
    end
    log("Tutorial: harvested! fruit=" .. tutorialCountFruit())

    -- 4. Sell
    State.tutorialPhase = "sell"
    log("Tutorial: bán fruit")
    for _ = 1, 10 do
        if not KaitunRunning then break end
        if tutorialCountFruit() <= 0 then break end
        forceSell()
        task.wait(0.5)
    end

    -- 5. Mark done + save file
    State.tutorialPhase = "done"
    markTutorialDoneInFile()
    State.tutorialDone = true
    log("Tutorial: DONE — flow chính bắt đầu")
    return true
end

local function tryAutoTutorialSendPet()
    if State.tutorialDone then return true end
    local tut = Config.Tutorial
    if type(tut) ~= "table" or tut.Enable ~= true then
        State.tutorialDone = true
        return true
    end

    -- Nếu file đã mark done → skip
    if isTutorialDoneInFile() then
        State.tutorialDone = true
        log("Tutorial: đã done trong Surge.json — skip")
        return true
    end

    -- AutoFlow: buy carrot → plant → harvest → sell
    if tut.AutoFlow == true then
        return runAutoTutorialFlow()
    end

    -- Legacy: gửi pet đầu tiên qua GiftMail
    if tut.SendFirstPet ~= true then
        State.tutorialDone = true
        return true
    end
    if not canRunTutorial() then
        State.tutorialDone = true
        log("Tutorial skipped (GiftMail/recipient chưa setup)")
        return true
    end
    log("Tutorial: gửi pet đầu tiên qua GiftMail")
    if tryGiftMailOnce() then
        markTutorialDoneInFile()
        State.tutorialDone = true
        log("Tutorial send done")
        return true
    end
    if Config.AutoOpenEggs then
        tryOpenEgg()
        tryBuyEssentials()
        tryBuySeedsTiered()
    end
    return false
end

-- ── Server hop ──────────────────────────────────────────────────────────────

local function shouldHopForPet()
    if not Config.HopServer then return false end  -- chặn hop khi HopServer = false
    if not isPetFinderEnabled() then return false end
    local petName = getActiveFinderPet()
    if not petName then return false end
    if getPlayerSheckles() < getPetFinderHopMoney() then return false end
    if os.clock() - State.lastHop < getPetFinderHopCooldown() then return false end
    local targets = findWildPetTargets(petName)
    return #targets == 0
end

local function hopServer()
    if not Config.HopServer then
        log("Hop blocked by config (HopServer = false)")
        State.lastHop = os.clock()  -- tránh re-trigger liên tục
        return false
    end
    local petName = getActiveFinderPet() or "?"
    State.lastHop = os.clock()
    log("Hopping server (£" .. fmtMoney(getPetFinderHopMoney()) .. "+, no " .. petName .. " here)")
    local req = (syn and syn.request) or (http and http.request) or request
    if not req then return false end
    local ok, body = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        return req({ Url = url, Method = "GET" }).Body
    end)
    if not ok or not body then return false end
    local data = HttpService:JSONDecode(body)
    if not data or not data.data then return false end
    for _, server in ipairs(data.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            end)
            return true
        end
    end
    return false
end

-- ── Stay base + webhook + optimization ──────────────────────────────────────

local function tryStayInBase()
    if not Config.StayInBase or TravelActive then return end
    local home = getHomePosition()
    local HRP = getHRP()
    if not home or not HRP then return end
    local flatDist = (Vector3.new(HRP.Position.X, 0, HRP.Position.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude
    if flatDist > 35 then
        moveToPosition(home, function() return KaitunRunning and not TravelActive end)
    end
end

local function sendWebhook(msg)
    if Config.WebhookUrl == "" or not Config.WebhookUrl:find("discord") then return end
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or request
        if not req then return end
        req({
            Url = Config.WebhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                content = msg,
                username = "Surge Hub",
            }),
        })
    end)
end

-- Gửi webhook dạng embed (không ping ai). fields: { {name=.., value=.., inline=..}, ... }
local function sendWebhookEmbed(title, description, color, fields)
    if Config.WebhookUrl == "" or not Config.WebhookUrl:find("discord") then return end
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or request
        if not req then return end
        local embed = {
            title = title,
            description = description,
            color = color or 0x3498DB,
            footer = { text = "Surge Hub" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }
        if fields and #fields > 0 then embed.fields = fields end
        req({
            Url = Config.WebhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                username = "Surge Hub",
                embeds = { embed },
            }),
        })
    end)
end

-- Tính uptime dạng "Xh Ym Zs" hoặc "Xm Zs"
local function formatUptime(seconds)
    seconds = math.floor(seconds or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%dh %dm %ds", h, m, s) end
    return string.format("%dm %ds", m, s)
end

-- Helper đếm tổng seed (seed tools) trong inventory
local function countTotalSeeds()
    local n = 0
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SeedTool") then n += 1 end
        end
    end
    scan(LocalPlayer.Backpack)
    if LocalPlayer.Character then scan(LocalPlayer.Character) end
    return n
end

-- Đếm seed Gold/Rainbow variant đang có trong inventory
local function countGoldRainbowSeeds()
    local gold, rainbow = 0, 0
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SeedTool") then
                if t:GetAttribute("GoldSeed") == true then gold += 1 end
                if t:GetAttribute("RainbowSeed") == true then rainbow += 1 end
            end
        end
    end
    scan(LocalPlayer.Backpack)
    if LocalPlayer.Character then scan(LocalPlayer.Character) end
    return gold, rainbow
end

-- Webhook status định kỳ: tài khoản, tiền, tổng seed, số pet, gold/rainbow, uptime (EMBED)
local function sendStatusWebhook()
    local sheckles = getPlayerSheckles()
    local totalSeeds = countTotalSeeds()
    local petCount = countOwnedPets()
    local goldInv, rainbowInv = countGoldRainbowSeeds()
    local uptimeStr = formatUptime(os.difftime(os.time(), State.startTime or os.time()))
    sendWebhookEmbed(
        "📊 Status — " .. LocalPlayer.Name,
        nil,
        0x3498DB,
        {
            { name = "Sheckles", value = "£" .. tostring(sheckles), inline = true },
            { name = "Seeds", value = tostring(totalSeeds), inline = true },
            { name = "Pets", value = tostring(petCount), inline = true },
            { name = "Gold seed", value = string.format("Túi: %d | Đã collect: %d", goldInv, State.goldSeedCollected or 0), inline = true },
            { name = "Rainbow seed", value = string.format("Túi: %d | Đã collect: %d", rainbowInv, State.rainbowSeedCollected or 0), inline = true },
            { name = "Phase", value = "`" .. tostring(State.phase) .. "`", inline = true },
            { name = "Uptime", value = "`" .. uptimeStr .. "`", inline = true },
        }
    )
end

-- ── Performance / FPS / Hide 3D ─────────────────────────────────────────────

local Lighting = game:GetService("Lighting")
local FFLAG_LIST = {
    { "DFIntTaskSchedulerTargetFps", function() return tostring(Config.FpsCap or 30) end },
    -- Texture quality: xóa texture, giảm chất lượng
    { "DFIntTextureQualityOverride", "0" },
    { "DFIntPerformanceControlTextureQualityBestUtility", "0" },
    { "FIntDebugForceMSAA", "0" },
    { "FIntRenderShadowIntensity", "0" },
    { "FIntRenderShadowDistance", "0" },
    { "FIntRenderLocalShadowFade", "0" },
    -- LoD: giảm chi tiết mesh từ xa
    { "DFIntCSGLevelOfDetailSwitchingDistance", "1" },
    { "DFIntCSGLevelOfDetailSwitchingDistanceMedium", "1" },
    { "DFIntCSGLevelOfDetailSwitchingDistanceFar", "1" },
    { "FIntRenderingQuality", "1" },
    -- FRM (frame rate manager) — ép render cực thấp
    { "FIntFRMMaxFramesToBeBehindBeforeIdle", "1" },
    { "FIntFRMinimumGraphiteDistance", "0" },
    { "DFIntMaxFrameBufferSize", "1" },
    -- Particle/decal: tắt
    { "FIntRGUBatchSize", "1" },
    -- Anti-aliasing off
    { "FIntAntiAliasingMode", "0" },
    -- Material quality thấp
    { "FIntMaterialQuality", "0" },
}

local function applyFFlags()
    if not setfflag then return end
    for _, entry in ipairs(FFLAG_LIST) do
        local name, val = entry[1], entry[2]
        if type(val) == "function" then val = val() end
        pcall(setfflag, name, val)
    end
    PerfState.fflagsOn = true
end

local function clearFFlags()
    PerfState.fflagsOn = false
end

local SavedLighting = {}
local isPlantVisual  -- forward declare (defined bên dưới)

local function applyLowGraphics()
    pcall(function()
        SavedLighting.GlobalShadows = Lighting.GlobalShadows
        SavedLighting.Technology = Lighting.Technology
        SavedLighting.Brightness = Lighting.Brightness
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        if Enum.Technology.Legacy then
            Lighting.Technology = Enum.Technology.Legacy
        end
    end)
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decoration = false
        end
    end)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        settings().Rendering.EnableFRM = true
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end)
    -- Xóa texture toàn workspace: ép material về SmoothPlastic, tắt Decal/Texture
    pcall(function()
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") then
                -- Bỏ qua plant visual (đã handle riêng bởi Hide3D)
                if not isPlantVisual(inst) then
                    pcall(function() inst.Material = Enum.Material.SmoothPlastic end)
                    pcall(function() inst.CastShadow = false end)
                    pcall(function() inst.Reflectance = 0 end)
                end
            elseif inst:IsA("Decal") or inst:IsA("Texture") then
                pcall(function() inst.Transparency = 1 end)
            elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
                pcall(function() inst.Enabled = false end)
            elseif inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                pcall(function() inst.Enabled = false end)
            end
        end
    end)
    -- Theo dõi instance mới thêm vào workspace để xóa texture (spawn plants, effects)
    pcall(function()
        PerfState.texConn = workspace.DescendantAdded:Connect(function(inst)
            if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
                or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                pcall(function() inst.Enabled = false end)
            elseif inst:IsA("Decal") or inst:IsA("Texture") then
                pcall(function() inst.Transparency = 1 end)
            end
        end)
    end)
    PerfState.lowGfxOn = true
end

local function clearLowGraphics()
    pcall(function()
        if SavedLighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = SavedLighting.GlobalShadows
        end
        if SavedLighting.Technology then
            Lighting.Technology = SavedLighting.Technology
        end
        if SavedLighting.Brightness then
            Lighting.Brightness = SavedLighting.Brightness
        end
    end)
    pcall(function()
        if PerfState.texConn then PerfState.texConn:Disconnect() end
        PerfState.texConn = nil
    end)
    PerfState.lowGfxOn = false
end

isPlantVisual = function(inst)
    if not inst then return false end
    if inst:IsDescendantOf(Gardens) then
        local plants = inst:FindFirstAncestor("Plants")
        if plants then return true end
    end
    return false
end

local function hideVisualInstance(inst)
    if inst:IsA("BasePart") then
        if not PerfState.hiddenParts[inst] then
            PerfState.hiddenParts[inst] = {
                Transparency = inst.Transparency,
                CanCollide = inst.CanCollide,
                CanQuery = inst.CanQuery,
                CastShadow = inst.CastShadow,
                LocalTransparencyModifier = inst.LocalTransparencyModifier,
            }
        end
        inst.LocalTransparencyModifier = 1
        inst.Transparency = 1
        inst.CanCollide = false
        inst.CanQuery = false
        inst.CastShadow = false
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        if not PerfState.hiddenParts[inst] then
            PerfState.hiddenParts[inst] = { Transparency = inst.Transparency }
        end
        inst.Transparency = 1
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
        if not PerfState.hiddenParts[inst] then
            PerfState.hiddenParts[inst] = { Enabled = inst.Enabled }
        end
        inst.Enabled = false
    elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
        if not PerfState.hiddenParts[inst] then
            PerfState.hiddenParts[inst] = { Enabled = inst.Enabled }
        end
        inst.Enabled = false
    end
end

local function restoreVisualInstance(inst, saved)
    if not inst or not saved then return end
    if inst:IsA("BasePart") then
        inst.Transparency = saved.Transparency or 0
        inst.CanCollide = saved.CanCollide ~= false
        inst.CanQuery = saved.CanQuery ~= false
        inst.CastShadow = saved.CastShadow ~= false
        inst.LocalTransparencyModifier = saved.LocalTransparencyModifier or 0
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        inst.Transparency = saved.Transparency or 0
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
        inst.Enabled = saved.Enabled ~= false
    elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
        inst.Enabled = saved.Enabled ~= false
    end
end

local function sweepHideAllGardenPlants()
    if not PerfState.hideGarden3D then return end
    for _, garden in Gardens:GetChildren() do
        local plants = garden:FindFirstChild("Plants")
        if plants then
            for _, desc in plants:GetDescendants() do
                hideVisualInstance(desc)
            end
        end
        local visual = garden:FindFirstChild("Visual")
        if visual then
            for _, desc in visual:GetDescendants() do
                if desc:IsA("BasePart") and desc.Name:lower():find("plant") then
                    hideVisualInstance(desc)
                end
            end
        end
    end
end

local function enableHideGarden3D()
    PerfState.hideGarden3D = true
    sweepHideAllGardenPlants()
    if PerfState.hideConn then PerfState.hideConn:Disconnect() end
    PerfState.hideConn = Gardens.DescendantAdded:Connect(function(inst)
        if PerfState.hideGarden3D and isPlantVisual(inst) then
            hideVisualInstance(inst)
        end
    end)
    if PerfState.hideSweepTask then task.cancel(PerfState.hideSweepTask) end
    PerfState.hideSweepTask = task.spawn(function()
        while PerfState.hideGarden3D and KaitunRunning do
            task.wait(3)
            if PerfState.hideGarden3D then sweepHideAllGardenPlants() end
        end
    end)
end

local function disableHideGarden3D()
    PerfState.hideGarden3D = false
    if PerfState.hideConn then
        PerfState.hideConn:Disconnect()
        PerfState.hideConn = nil
    end
    if PerfState.hideSweepTask then
        task.cancel(PerfState.hideSweepTask)
        PerfState.hideSweepTask = nil
    end
    for inst, saved in pairs(PerfState.hiddenParts) do
        if inst and inst.Parent then
            restoreVisualInstance(inst, saved)
        end
    end
    PerfState.hiddenParts = {}
end

local stopKaitun
local function syncKaitunGenv()
    local g = getgenv and getgenv() or _G
    g.KaitunRunning = KaitunRunning
    g.KaitunState = State
    g.KaitunStop = stopKaitun
end

stopKaitun = function()
    if not KaitunRunning then return end
    KaitunRunning = false
    cancelMovement()
    TravelActive = false
    WorldSeedSnatcher.claiming = false
    for _, conn in ipairs(WorldSeedSnatcher.conns) do
        pcall(function() conn:Disconnect() end)
    end
    WorldSeedSnatcher.conns = {}
    if PerfState.hideGarden3D then disableHideGarden3D() end
    if PerfState.lowGfxOn then clearLowGraphics() end
    if PerfState.fflagsOn then clearFFlags() end
    State.phase = "stopped"
    log("Stopped")
    syncKaitunGenv()
    sendWebhookEmbed(
        "🛑 Surge Hub stopped",
        string.format("Script đã dừng — **%s**", LocalPlayer.Name),
        0xE74C3C,
        {
            { name = "Sheckles", value = "£" .. tostring(getPlayerSheckles()), inline = true },
            { name = "Uptime", value = "`" .. formatUptime(os.difftime(os.time(), State.startTime or os.time())) .. "`", inline = true },
        }
    )
end

local function classifyTool(tool)
    if not tool:IsA("Tool") then return "Other" end
    if tool:GetAttribute("SeedTool") then return "Seeds" end
    if tool:GetAttribute("Pet") or tool:GetAttribute("PetName") then return "Pets" end
    if tool:GetAttribute("Egg") then return "Eggs" end
    if tool:GetAttribute("Crate") then return "Crates" end
    if tool:GetAttribute("HarvestedFruit") or tool:GetAttribute("Fruit") or tool:GetAttribute("FruitName") then
        return "Fruits"
    end
    if tool:GetAttribute("Sprinkler") or tool:GetAttribute("WateringCan")
        or tool:GetAttribute("Shovel") or tool:GetAttribute("Gear") then
        return "Gear"
    end
    return "Other"
end

local function scanInventoryCounts()
    local counts = {
        Seeds = 0, Pets = 0, Eggs = 0, Crates = 0,
        Fruits = 0, Gear = 0, Other = 0, Total = 0,
    }
    local function scan(container)
        if not container then return end
        for _, item in container:GetChildren() do
            if item:IsA("Tool") then
                local cat = classifyTool(item)
                counts[cat] = (counts[cat] or 0) + 1
                counts.Total += 1
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return counts
end

local function formatInventoryText(counts)
    return table.concat({
        "Total tools: " .. counts.Total,
        "Seeds: " .. counts.Seeds,
        "Pets: " .. counts.Pets,
        "Eggs: " .. counts.Eggs,
        "Fruits: " .. counts.Fruits,
        "Gear: " .. counts.Gear,
        "Crates: " .. counts.Crates,
        "Other: " .. counts.Other,
    }, "\n")
end

local function countWorldPlants()
    local total = 0
    for _, garden in Gardens:GetChildren() do
        local plants = garden:FindFirstChild("Plants")
        if plants then total += #plants:GetChildren() end
    end
    return total
end

local function scanInventoryCached()
    local now = os.clock()
    if UICache.inv and (now - UICache.invAt) < Config.InvScanInterval then
        return UICache.inv
    end
    UICache.inv = scanInventoryCounts()
    UICache.invAt = now
    return UICache.inv
end

local function countWorldPlantsCached()
    local now = os.clock()
    if (now - UICache.worldPlantsAt) < Config.InvScanInterval then
        return UICache.worldPlants
    end
    UICache.worldPlants = countWorldPlants()
    UICache.worldPlantsAt = now
    return UICache.worldPlants
end

local function countHiddenParts()
    local n = 0
    for _ in pairs(PerfState.hiddenParts) do n += 1 end
    return n
end

local function onFlag(label, active)
    return label .. (active and " ON" or " OFF")
end

local function buildDashboardText()
    local counts = scanInventoryCached()
    local garden = getMyGardenCached()
    local activePet = getActiveFinderPet() or getOwnedFinderPet() or "—"
    local ownsActive = activePet ~= "—" and playerOwnsPet(activePet)
    local now = os.clock()
    local sinceBuy = math.floor(now - (State.lastBuy or 0))
    local sincePlant = math.floor(now - (State.lastPlant or 0))
    local sinceHarvest = math.floor(now - (State.lastHarvest or 0))
    local sinceSell = math.floor(now - (State.lastSell or 0))
    return table.concat({
        "FPS " .. PerfState.currentFps .. "  |  cap " .. Config.FpsCap,
        onFlag("FFlags", PerfState.fflagsOn) .. "  |  " .. onFlag("LowGFX", PerfState.lowGfxOn) .. "  |  " .. onFlag("Hide3D", PerfState.hideGarden3D),
        "────────────────────────",
        "Phase: " .. State.phase .. (State.tutorialPhase and State.tutorialPhase ~= "" and (" [" .. State.tutorialPhase .. "]") or ""),
        "Buy " .. sinceBuy .. "s | Plant " .. sincePlant .. "s | Harv " .. sinceHarvest .. "s",
        "Sell " .. sinceSell .. "s ago  |  loops: parallel",
        "Tools: " .. getToolCountCached() .. "/" .. (Config.MaxInventoryTools or 83)
            .. "  |  fruit " .. getFruitCount() .. "/" .. getMaxFruitCapacity(),
        "£" .. fmtMoney(getPlayerSheckles()) .. "  |  " .. getMovementMode() .. " mode",
        "Garden: " .. (garden and garden.Name or "—") .. "  |  Night: " .. tostring(NightVal.Value),
        "Pet: " .. activePet .. (ownsActive and " ✓" or " ✗")
            .. "  |  finder: " .. (isPetFinderEnabled() and "ON" or "OFF"),
        "Gold seed: " .. (State.goldSeedCollected or 0) .. "  |  Rainbow seed: " .. (State.rainbowSeedCollected or 0),
        "────────────────────────",
        "Inv seed:" .. counts.Seeds .. "  pet:" .. counts.Pets .. "  egg:" .. counts.Eggs,
        "    fruit:" .. counts.Fruits .. "  gear:" .. counts.Gear .. "  total:" .. counts.Total,
        "World plants: " .. countWorldPlantsCached() .. "  hidden: " .. countHiddenParts(),
        "[RightShift] hide  |  [STOP] quit  |  3D/GFX/FF toggles",
    }, "\n")
end

local function styleToggleBtn(btn, active)
    btn.BackgroundColor3 = active and Color3.fromRGB(55, 110, 70) or Color3.fromRGB(45, 48, 58)
    btn.TextColor3 = active and Color3.fromRGB(210, 255, 220) or Color3.fromRGB(170, 175, 185)
end

local function makeToggle(parent, text, x, active, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(44, 22)
    btn.Position = UDim2.fromOffset(x, 6)
    btn.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn
    styleToggleBtn(btn, active)
    btn.MouseButton1Click:Connect(function()
        local next = not btn:GetAttribute("Active")
        btn:SetAttribute("Active", next)
        styleToggleBtn(btn, next)
        callback(next)
    end)
    btn:SetAttribute("Active", active)
    return btn
end

local function createKaitunUI()
    if Config.ShowUI == false then return end
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("KaitunDash")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "KaitunDash"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(318, 248)
    panel.Position = UDim2.new(1, -328, 0, 8)
    panel.BackgroundColor3 = Color3.fromRGB(14, 15, 18)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(126, 217, 87)
    stroke.Thickness = 1
    stroke.Transparency = 0.45
    stroke.Parent = panel

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -130, 0, 28)
    header.Position = UDim2.fromOffset(10, 4)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = Color3.fromRGB(126, 217, 87)
    header.Text = "SURGE HUB"
    header.Parent = panel

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.fromOffset(44, 22)
    stopBtn.Position = UDim2.fromOffset(118, 6)
    stopBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 45)
    stopBtn.BorderSizePixel = 0
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 11
    stopBtn.Text = "STOP"
    stopBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
    stopBtn.AutoButtonColor = false
    stopBtn.Parent = panel
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 5)
    stopCorner.Parent = stopBtn
    stopBtn.MouseButton1Click:Connect(function()
        stopBtn.Active = false
        stopKaitun()
    end)

    makeToggle(panel, "3D", 168, Config.HideGarden3D, function(v)
        if v then enableHideGarden3D() else disableHideGarden3D() end
    end)
    makeToggle(panel, "GFX", 218, Config.LowGraphics, function(v)
        if v then applyLowGraphics() else clearLowGraphics() end
    end)
    makeToggle(panel, "FF", 268, Config.UseFFlags, function(v)
        if v then applyFFlags() else clearFFlags() end
    end)

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Size = UDim2.new(1, -16, 1, -38)
    body.Position = UDim2.fromOffset(8, 34)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Code
    body.TextSize = 13
    body.TextColor3 = Color3.fromRGB(215, 220, 230)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.Text = "Loading..."
    body.Parent = panel

    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Gui.visible = not Gui.visible
            panel.Visible = Gui.visible
        end
    end)

    sg.Parent = pg
    Gui.Screen = sg
    Gui.Panel = panel
    Gui.Body = body
end

local function updateUI()
    if not Gui.Body then return end
    Gui.Body.Text = buildDashboardText()
end

local function startFpsTracker()
    local frames, elapsed = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        frames += 1
        elapsed += dt
        if elapsed >= 1 then
            PerfState.currentFps = math.floor(frames / elapsed)
            frames, elapsed = 0, 0
        end
    end)
end

local function startUIUpdater()
    task.spawn(function()
        while KaitunRunning do
            if Gui.Body and Gui.visible then updateUI() end
            task.wait(Config.UIUpdateInterval)
        end
    end)
end

local function applyOptimizations()
    if setfpscap and Config.FpsCap then pcall(setfpscap, Config.FpsCap) end
    if Config.UseFFlags then applyFFlags() end
    if Config.LowGraphics then applyLowGraphics() end
    if Config.HideGarden3D then enableHideGarden3D() end
end

local function startAntiAfk()
    if not Config.AntiAfk then return end
    pcall(function() LocalPlayer:SetAttribute("AntiAfkIdleOverride", 999999) end)
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
end

-- ── Main kaitun loop ────────────────────────────────────────────────────────

local function hasPlantableSeeds()
    if not Config.PlantSeed.Enable then return false end
    return #getPlantableSeedList() > 0
end

-- Plant loop: trồng ngay khi có seed + còn chỗ
local function startPlantLoop()
    task.spawn(function()
        while KaitunRunning do
            if WorldSeedSnatcher.claiming then
                task.wait(0.1)
                continue
            end
            if Config.PlantSeed.Enable then
                local garden = getMyGardenCached()
                if garden and not isInventoryFull() then
                    local planted = 0
                    local maxPerTick = Config.PlantAttemptsPerTick or 32
                    for _ = 1, maxPerTick do
                        if not tryPlantOneSeed(garden) then break end
                        planted += 1
                    end
                    if planted > 0 then
                        State.phase = "plant"
                        State.lastPlant = os.clock()
                    end
                end
            end
            task.wait(Config.PlantLoopInterval or 0.05)
        end
    end)
end

-- Buy loop: mua all seed khi còn slot + tiền (có backoff khi hết tiền)
local function startBuyLoop()
    task.spawn(function()
        while KaitunRunning do
            if WorldSeedSnatcher.claiming then
                task.wait(0.1)
                continue
            end
            if Config.BuySeed.Enable and not shouldBlockBuy() then
                local bought = tryBuySeedsTiered(Config.MaxBuysPerTick or 25)
                if bought > 0 then
                    State.phase = "buy"
                    State.lastBuy = os.clock()
                end
            end
            task.wait(Config.BuyLoopInterval or 1)
        end
    end)
end

-- Harvest loop: thu hoạch ngay khi có plant ready (poll nhanh, không chờ interval)
local function startHarvestLoop()
    task.spawn(function()
        while KaitunRunning do
            if WorldSeedSnatcher.claiming then
                task.wait(0.1)
                continue
            end
            local garden = getMyGardenCached()
            if garden then
                -- Check nhanh có plant ready không trước khi harvest (tránh scan không)
                local plants = garden:FindFirstChild("Plants")
                local hasReady = false
                if plants then
                    for _, plant in ipairs(plants:GetChildren()) do
                        if plant:GetAttribute("UserId") == LocalPlayer.UserId then
                            local fruitsFolder = plant:FindFirstChild("Fruits")
                            if (fruitsFolder and #fruitsFolder:GetChildren() > 0)
                                or plant:GetAttribute("PlantGrowthReady") == true then
                                hasReady = true
                                break
                            end
                        end
                    end
                end
                if hasReady then
                    local harvested = tryHarvest(garden)
                    if harvested > 0 then
                        State.phase = "harvest"
                        State.lastHarvest = os.clock()
                    end
                end
            end
            task.wait(Config.HarvestLoopInterval or 0.1)
        end
    end)
end

-- Sell loop: sell NGAY khi có fruit (poll nhanh)
local function startSellLoop()
    task.spawn(function()
        while KaitunRunning do
            local fc = getFruitCount()
            if fc > 0 then
                if forceSell() then
                    State.lastSell = os.clock()
                end
            end
            task.wait(Config.SellLoopInterval or 0.3)
        end
    end)
end

-- Maintenance loop: water/sprinkler/extras/pet/delete (ít thường xuyên)
local function startMaintenanceLoop()
    task.spawn(function()
        while KaitunRunning do
            local garden = getMyGardenCached()
            if garden and not WorldSeedSnatcher.claiming then
                if os.clock() - State.lastWater >= 45 then
                    if Config.AutoWater ~= false then tryWater(garden) end
                    trySprinkler(garden)
                    State.lastWater = os.clock()
                end
                if os.clock() - (State.lastExtras or 0) >= 60 then
                    tryBuyEssentials()
                    State.lastExtras = os.clock()
                end
                if os.clock() - (State.lastPetMgmt or 0) >= 20 then
                    tryPetManagement()
                    State.lastPetMgmt = os.clock()
                end
                if Config.DeleteNonFarmPlants then
                    tryDeletePlants(garden)
                end
            end
            task.wait(2)
        end
    end)
end

local function startAutoSellLoop()
    startSellLoop()
end

log("Surge Hub started | mode=" .. getMovementMode() .. " | finder=" .. table.concat(getPetFinderQueue(), ", "))
syncKaitunGenv()
State.lastHarvest = os.clock()
createKaitunUI()
startFpsTracker()
startUIUpdater()
applyOptimizations()
startAntiAfk()
startWorldSeedSnatcher()
-- Farm loops (buy/plant/harvest/sell/maintenance) sẽ start SAU khi tutorial done
-- (xem main orchestrator). Nếu tutorial disable thì start ngay.
sendWebhookEmbed(
    "🟢 Surge Hub started",
    string.format("Script đã khởi động — **%s**", LocalPlayer.Name),
    0x2ECC71,
    {
        { name = "Sheckles", value = "£" .. tostring(getPlayerSheckles()), inline = true },
        { name = "Mode", value = "`" .. getMovementMode() .. "`", inline = true },
        { name = "Pet finder", value = "`" .. table.concat(getPetFinderQueue(), ", ") .. "`", inline = true },
    }
)
State.startTime = os.time()
State.lastRejoinNotified = os.time()

-- Phát hiện acc vào lại game (rejoin/respawn): gửi embed webhook, KHÔNG ping ai
task.spawn(function()
    local lastChar = LocalPlayer.Character
    local lastBackpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        -- Chỉ notify nếu thực sự rejoin/respawn (char mới khác char cũ)
        if newChar and newChar ~= lastChar then
            local now = os.time()
            -- Tránh spam: tối thiểu 15s giữa 2 notify
            if now - (State.lastRejoinNotified or 0) >= 15 then
                State.lastRejoinNotified = now
                local uptimeStr = formatUptime(os.difftime(now, State.startTime or now))
                pcall(function()
                    sendWebhookEmbed(
                        "🔄 Account vào lại game",
                        string.format("**%s** vừa rejoin/respawn", LocalPlayer.Name),
                        0x2ECC71,
                        {
                            { name = "Sheckles", value = "£" .. tostring(getPlayerSheckles()), inline = true },
                            { name = "Uptime (session)", value = uptimeStr, inline = true },
                            { name = "Phase", value = "`" .. tostring(State.phase) .. "`", inline = true },
                        }
                    )
                end)
            end
            lastChar = newChar
        end
    end)
    if lastChar then
        -- Nếu đã có character sẵn khi script start, không notify (chỉ notify khi rejoin sau)
        lastChar = LocalPlayer.Character
    end
end)

task.spawn(function()
    while KaitunRunning and Config.AutoExpand do
        tryExpand()
        task.wait(Config.ExpandInterval)
    end
end)

task.spawn(function()
    while KaitunRunning do
        if os.clock() - State.lastStatusWebhook >= (Config.WebhookStatusInterval or 30) then
            State.lastStatusWebhook = os.clock()
            pcall(sendStatusWebhook)
        end
        task.wait(5)
    end
end)

task.spawn(function()
    while KaitunRunning and Config.StayInBase do
        tryStayInBase()
        task.wait(3)
    end
end)

task.spawn(function()
    while KaitunRunning do
        if Config.GiftMail and Config.GiftMail.Enable then
            tryGiftMailOnce()
            task.wait(Config.GiftMail.IntervalSec or 30)
        else
            task.wait(5)
        end
    end
end)

-- Nếu tutorial disable hoặc đã done trong file → mark done ngay để farm loops start
if not (Config.Tutorial and Config.Tutorial.Enable) then
    State.tutorialDone = true
elseif Config.Tutorial.AutoFlow == true and isTutorialDoneInFile() then
    State.tutorialDone = true
    log("Tutorial: đã done trong Surge.json — skip, farm loops start ngay")
end

-- Main orchestrator
while KaitunRunning do
    if WorldSeedSnatcher.claiming then
        State.phase = "seed_snatch"
        task.wait(0.03)
        continue
    end

    local garden = getMyGarden()

    if Config.Tutorial and Config.Tutorial.Enable and not State.tutorialDone then
        State.phase = "tutorial"
        tryAutoTutorialSendPet()
        task.wait(1)
        if not State.tutorialDone then
            continue
        end
    end

    -- Start farm loops SAU khi tutorial done (chỉ 1 lần)
    if not FarmLoopsStarted then
        FarmLoopsStarted = true
        log("Starting farm loops (buy/plant/harvest/sell/maintenance)")
        startBuyLoop()
        startPlantLoop()
        startHarvestLoop()
        startSellLoop()
        startMaintenanceLoop()
    end

    if isPetFinderEnabled()
        and getActiveFinderPet()
        and getPlayerSheckles() >= getPetFinderHopMoney()
        and not WorldSeedSnatcher.claiming then
        local petName = getActiveFinderPet()
        local inBackoff = State.petHuntBackoffUntil and os.clock() < State.petHuntBackoffUntil
        local targets = inBackoff and {} or findWildPetTargets(petName)
        if #targets > 0 then
            State.phase = "pet_hunt"
            huntFinderPetOnce()
            task.wait(0.5)
            continue
        elseif not inBackoff and shouldHopForPet() then
            State.phase = "hop"
            hopServer()
            task.wait(8)
            continue
        end
    end

    if garden then
        -- Farm work chạy ở các background loop song song.
        -- Main orchestrator chỉ lo tutorial + pet finder/hop.
        -- Sinh trạng thái farm tổng hợp cho UI.
        local elapsed = os.clock() - math.max(State.lastBuy or 0, State.lastPlant or 0, State.lastHarvest or 0)
        if elapsed < 1 then
            State.status = ("buy/plant/harvest active | £%s"):format(fmtMoney(getPlayerSheckles()))
        else
            State.status = "farm loops running"
        end
    else
        State.phase = "waiting_garden"
        log("Waiting for garden...")
    end

    task.wait(Config.MainLoopDelay)
end

syncKaitunGenv()
log("Kaitun stopped")

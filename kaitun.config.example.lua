-- ─────────────────────────────────────────────────────────────────────────────
--  Surge Hub (GAG2) — Example config
--  Load kaitun.lua BEFORE set config không tác dụng; set getgenv().KaitunConfig
--  TRƯỚC khi loadstring(readfile("kaitun.lua"))()
-- ─────────────────────────────────────────────────────────────────────────────

getgenv().KaitunConfig = {
    -- ── Movement ──
    MovementMode = "cheat",   -- "cheat" = teleport CFrame (nhanh) | "legit" = MoveTo

    -- ── Performance ──
    FpsCap = 30,              -- FPS cap (set 5-10 cho acc nền để tiết kiệm CPU/GPU)
    HideGarden3D = true,      -- ẩn plant visual trong garden → giảm render
    AntiAfk = true,           -- anti-afk tự động (VirtualUser click khi idle)

    -- ── Farm flow (4 loop song song) ──
    MaxBuysPerCycle = 50,
    MaxBuysPerTick = 25,
    PlantAttemptsPerTick = 32,
    PlantAttemptsPerCycle = 48,
    MaxInventoryTools = 83,
    StackSpacing = 1.2,
    StackMaxPlants = 64,
    BuyLoopInterval = 1,      -- giây giữa mỗi buy tick
    PlantLoopInterval = 0.05, -- poll plant nhanh
    HarvestLoopInterval = 0.1,
    SellLoopInterval = 0.3,
    BuyBackoffSec = 5,        -- backoff khi không mua được (auto: 10s hết tiền, 3s hết stock)

    -- ── Quick profit (short-term) ──
    QuickProfitMode = false,       -- true = chỉ mua seed rẻ (ROI nhanh)
    QuickProfitMaxPrice = 1000,    -- giá seed tối đa khi QuickProfitMode = true

    -- ── Budget ──
    KeepBudgetSheckles = 0,   -- giữ lại bao nhiêu Sheckles (không tiêu hết)
    SeedHoardTarget = 200,    -- giữ kho seed tối thiểu

    -- ── Maintenance ──
    AutoWater = FALSE,
    Sprinkler = "Common Sprinkler",
    BuyGears = { "Common Sprinkler", "Common Watering Can" },
    AutoExpand = true,
    ExpandInterval = 12,
    DeleteNonFarmPlants = false,

    -- ── World seed (Gold / Rainbow) snatcher ──
    AutoCollectGold = true,
    AutoCollectRainbow = true,
    WorldSeedSnatchTimeout = 3,

    -- ── Eggs / Pets ──
    AutoOpenEggs = true,
    EggPriority = { "Common Egg", "Epic Egg" },
    AutoEquipPet = true,
    AutoUpgradePetSlot = true,

    -- ── Tutorial (auto flow) ──
    Tutorial = {
        Enable = true,
        SendFirstPet = true,        -- legacy: gửi pet qua GiftMail
        AutoFlow = true,            -- flow mới: mua Carrot → plant → harvest → sell → mark done
        SeedName = "Carrot",
        HarvestTimeout = 60,        -- giây chờ harvest carrot
    },

    -- ── Buy seed (chỉ mua loại = true) ──
    BuySeed = {
        Enable = true,
        Seed = {
            ["Carrot"]           = true,   -- £1
            ["Strawberry"]       = true,   -- £10
            ["Blueberry"]        = true,   -- £25
            ["Tulip"]            = true,   -- £40
            ["Tomato"]           = true,   -- £200
            ["Apple"]            = true,   -- £400
            ["Bamboo"]           = true,   -- £700
            ["Corn"]             = true,   -- £2,500
            ["Cactus"]           = true,   -- £5,000
            ["Pineapple"]        = true,   -- £10,000
            ["Mushroom"]         = true,   -- £15,000
            ["Green Bean"]       = true,   -- £20,000
            ["Banana"]           = true,   -- £30,000
            ["Grape"]            = true,   -- £50,000
            ["Coconut"]          = true,   -- £70,000
            ["Dragon Fruit"]     = true,   -- £120,000
            ["Mango"]            = true,   -- £300,000
            ["Acorn"]            = true,   -- £700,000
            ["Cherry"]           = true,   -- £1,200,000
            ["Sunflower"]        = true,   -- £1,500,000
            ["Venus Fly Trap"]   = true,   -- £7,000,000
            ["Pomegranate"]      = true,   -- £12,000,000
            ["Poison Apple"]     = true,   -- £25,000,000
            ["Venom Spitter"]    = true,   -- £50,000,000
            ["Moon Bloom"]       = true,   -- £65,000,000
            ["Dragon's Breath"]  = true,   -- £90,000,000
        },
    },

    -- ── Plant seed (chỉ trồng loại = true) ──
    PlantSeed = {
        Enable = true,
        Seed = {
            ["Carrot"]           = true,
            ["Strawberry"]       = true,
            ["Blueberry"]        = true,
            ["Tulip"]            = true,
            ["Tomato"]           = true,
            ["Apple"]            = true,
            ["Bamboo"]           = true,
            ["Corn"]             = true,
            ["Cactus"]           = true,
            ["Pineapple"]        = true,
            ["Mushroom"]         = true,
            ["Green Bean"]       = true,
            ["Banana"]           = true,
            ["Grape"]            = true,
            ["Coconut"]          = true,
            ["Dragon Fruit"]     = true,
            ["Mango"]            = true,
            ["Acorn"]            = true,
            ["Cherry"]           = true,
            ["Sunflower"]        = true,
            ["Venus Fly Trap"]   = true,
            ["Pomegranate"]      = true,
            ["Poison Apple"]     = true,
            ["Venom Spitter"]    = true,
            ["Moon Bloom"]       = true,
            ["Dragon's Breath"]  = true,
        },
    },

    -- ── Gift mail (auto ship item cho acc chính) ──
    GiftMail = {
        Enable = false,
        RecipientUserId = "",          -- ưu tiên UserId
        RecipientName = "",            -- hoặc username Roblox
        Message = "auto-shipped from Surge Hub",
        IntervalSec = 30,

        Pet = {
            ["Bear"]            = false,
            ["Bee"]             = false,
            ["BlackDragon"]     = false,
            ["Bunny"]           = false,
            ["Deer"]            = false,
            ["Frog"]            = false,
            ["GoldenDragonfly"] = false,
            ["IceSerpent"]      = false,
            ["Monkey"]          = false,
            ["Owl"]             = false,
            ["Raccoon"]         = false,
            ["Robin"]           = false,
            ["Turtle"]          = false,
            ["Unicorn"]         = false,
        },

        Seed = {
            ["Gold"]            = false,  -- world gold seed pack
            ["Rainbow"]         = false,  -- world rainbow seed pack
            ["Carrot"]          = false,
            ["Strawberry"]      = false,
            ["Blueberry"]       = false,
            ["Tulip"]           = false,
            ["Tomato"]          = false,
            ["Apple"]           = false,
            ["Bamboo"]          = false,
            ["Corn"]            = false,
            ["Cactus"]          = false,
            ["Pineapple"]       = false,
            ["Mushroom"]        = false,
            ["Green Bean"]      = false,
            ["Banana"]          = false,
            ["Grape"]           = false,
            ["Coconut"]         = false,
            ["Dragon Fruit"]    = false,
            ["Mango"]           = false,
            ["Acorn"]           = false,
            ["Cherry"]          = false,
            ["Sunflower"]       = false,
            ["Venus Fly Trap"]  = false,
            ["Pomegranate"]     = false,
            ["Poison Apple"]    = false,
            ["Venom Spitter"]   = false,
            ["Moon Bloom"]      = false,
            ["Dragon's Breath"] = false,
        },
    },

    -- ── Pet finder + server hop ──
    PetFinder = {
        Enable = false,
        HopCooldown = 45,              -- giây giữa mỗi lần hop
        MoneyWhenHop = 50000000,       -- chỉ hop khi đủ tiền (50M)

        Pet = {
            ["Bear"]            = false,
            ["Bee"]             = false,
            ["BlackDragon"]     = false,
            ["Bunny"]           = false,
            ["Deer"]            = false,
            ["Frog"]            = true,
            ["GoldenDragonfly"] = false,
            ["IceSerpent"]      = false,
            ["Monkey"]          = false,
            ["Owl"]             = false,
            ["Raccoon"]         = false,
            ["Robin"]           = false,
            ["Turtle"]          = false,
            ["Unicorn"]         = true,
        },
    },

    -- ── Server hop control ──
    -- false = KHÔNG hop server dưới BẤT CỨ trường hợp nào (dù PetFinder muốn hop)
    HopServer = true,

    -- ── Stay in base ──
    StayInBase = true,

    -- ── Webhook ──
    WebhookUrl = "",
    WebhookInterval = 120,             -- webhook cũ (sẽ bị thay bởi status)
    WebhookStatusInterval = 30,        -- 30s gửi 1 status: tài khoản, tiền, seed, pet, gold/rainbow
    WebhookOnSeedCollect = true,       -- thông báo ngay khi collect được Gold/Rainbow seed
    WebhookPetRarity = { "Mythic", "Super", "Secret" },  -- filter rarity pet
    WebhookSeedName = {                -- filter seed name (seed hiếm)
        "Dragon's Breath", "Venus Fly Trap", "Pomegranate", "Poison Apple",
        "Venom Spitter", "Ghost Pepper", "Romanesco", "Moon Bloom",
    },

    -- ── UI ──
    ShowUI = true,

    -- ── Loop timing ──
    MainLoopDelay = 0.25,
    RemoteCooldown = 0.10,
    SellInterval = 1,
}

-- Load script:
--   loadstring(readfile("kaitun.lua"))()

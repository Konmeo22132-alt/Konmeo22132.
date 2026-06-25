# Kaitun.lua — Deep Dive Modules

Tài liệu chi tiết cho từng module trong `kaitun.lua` (GAG2 Auto Kaitun).

---

## 1. Farm Module

### Mục đích
Tự động trồng, mua seed, thu hoạch, tưới nước, sprinkler, mở trứng, mở rộng garden.

### Entry point
`runFarmTick(garden)` — gọi mỗi ~0.25s từ main loop khi không có snatch/tutorial/pet hunt.

### Thứ tự action (mỗi tick)

| Bước | Hàm | Điều kiện |
|------|-----|-----------|
| 1 | `tryPlantOneSeed` × N | `PlantSeed.Enable`, có seed tool, còn chỗ plant |
| 2 | `tryBuySeedsTiered` | `BuySeed.Enable`, không `shouldBlockBuy()` |
| 3 | `tryHarvest` | Mỗi `HarvestCycleInterval` (30s) |
| 4 | `tryWater` + `trySprinkler` | Mỗi 45s |
| 5 | `tryBuyEssentials` + `tryOpenEgg` | Mỗi 90s (`lastExtras`) |
| 6 | `tryDeletePlants` | `DeleteNonFarmPlants = true` |
| 7 | `tryPetManagement` | Mỗi tick (equip pet, upgrade slot, mở trứng) |

### Planting — stack algorithm

```
getStackPositions(garden)
  → Lấy PlantArea đầu tiên (tag "PlantArea")
  → Grid sqrt(StackMaxPlants) × spacing quanh center
  → findPlantPosition: ưu tiên stack slots trống, fallback scan grid trong areas
  → isTooCloseToPlant: khoảng cách 2D < StackSpacing × 0.6
```

Seed được chọn theo thứ tự `SEED_CATALOG` (rẻ → đắt), seed đầu tiên có trong backpack và bật trong `PlantSeed.Seed`.

Remote: `Net.Plant.PlantSeed:Fire(pos, seedName, seedTool)`

### Buy seed — đọc stock UI

`getSeedShopStock(seedName)` đọc path:
`PlayerGui.SeedShop.Frame.NormalShop.[seedName].Main_Frame.Stock_Text` → parse `x(\d+)`.

**Fallback:** Nếu SeedShop GUI chưa load, `getSeedShopStock` trả `nil` và `tryBuySeedsTiered` thử mua 1 lần (optimistic) thay vì bỏ qua.

### Harvest

Hai pattern fruit:
- Có folder `Fruits` → collect từng fruit có `PlantId` + `FruitId`
- Không có fruits → plant có `PlantGrowthReady == true` → collect với `fruitId = ""`

Remote: `Net.Garden.CollectFruit:Fire(plantId, fruitId)`

### Chặn mua (`shouldBlockBuy`)

- `getToolCount() >= MaxInventoryTools` (83)
- `FruitCount >= MaxFruitCapacity`

Auto sell chạy background mỗi `SellInterval` qua `Net.NPCS.SellAll:Fire()`.

---

## 2. Pet Finder Module

### Mục đích
Săn pet hoang dã trên server hiện tại; hop server khi đủ tiền và không thấy pet.

### Config

```lua
PetFinder = {
    Enable = true,
    Pet = { Owl = true, ... },  -- toggle map
    HopCooldown = 45,             -- giây giữa các lần hop
    MoneyWhenHop = 50000000,      -- chỉ hop khi >= £50M
}
```

### Queue logic

```
getPetFinderQueue()
  → Duyệt PET_CATALOG, lấy pet đã bật trong config

getActiveFinderPet()
  → Pet đầu tiên trong queue mà CHƯA sở hữu (playerOwnsPet)

getOwnedFinderPet()
  → Pet đầu tiên trong queue mà ĐÃ sở hữu (dùng để auto equip)
```

### Scan wild pets

`findWildPetTargets(petFilter)` quét `workspace.Map.WildPetSpawns`:
- Bỏ qua nếu `OwnerUserId == LocalPlayer.UserId`
- Cần `RootPart` + `BuyPrompt` enabled
- Sort theo khoảng cách tới player

### Mua pet (`tryBuyWildPet`)

1. Check blacklist: fail 3 lần → skip target đó
2. Check tiền qua `getWildPetPrice` (attribute hoặc prompt text)
3. `moveToPosition` tới pet
4. **legit mode:** `fireproximityprompt` / hold prompt
5. **cheat mode:** `Net.Pets.WildPetTame:Fire(target.ref)`
6. Poll 3.5s xem `wildPetPurchaseSucceeded`
7. Fail x3 → backoff 20s, quay farm

### Server hop (`hopServer`)

Điều kiện (`shouldHopForPet`):
- PetFinder bật + có active pet chưa sở hữu
- Sheckles >= MoneyWhenHop
- Hết HopCooldown
- `#findWildPetTargets(petName) == 0`

Gọi Roblox API public servers → `TeleportService:TeleportToPlaceInstance`. Cần executor có `request` HTTP.

### Main loop priority

Pet hunt chạy **trước** farm khi:
- `getPlayerSheckles() >= getPetFinderHopMoney()`
- Không trong backoff
- Không đang snatch world seed

---

## 3. World Seed Snatcher Module

### Mục đích
Nhặt Gold/Rainbow seed spawn trên map — **ưu tiên cao nhất**, chặn main loop khi đang claim.

### State

```lua
WorldSeedSnatcher = {
    claiming = false,  -- true → main loop chỉ wait
    seen = {},         -- tránh xử lý trùng spawn part
    locs = nil,        -- Map.SeedPackSpawnServerLocations
    conns = {},        -- event connections
}
```

### 3 trigger sources

1. **ChildAdded** trên `SeedPackSpawnServerLocations`
2. **Heartbeat** poll `listActiveWorldSeedTargets()`
3. **Remote** `Net.SeedPackSpawn.FX.OnClientEvent(pos)` → `rushWorldSeedAtPosition`

### Classification

`classifySpawnPart(part)`:
- `RainbowSeed == true` → priority 1 (cao hơn Gold)
- `GoldSeed == true` → priority 2
- Respect `AutoCollectRainbow` / `AutoCollectGold` config

Sort targets: priority trước, rồi khoảng cách.

### Snatch flow (`snatchWorldSeedTarget`)

1. Set `claiming = true`, `TravelActive = true`
2. Loop trong `WorldSeedSnatchTimeout` (3s):
   - Teleport HRP tới part + `firetouchinterest` (executor API)
3. Part biến mất = success
4. Webhook Discord nếu thành công

Main loop check đầu tiên:
```lua
if WorldSeedSnatcher.claiming then
    State.phase = "seed_snatch"
    task.wait(0.03)
    continue
end
```

---

## 4. UI Dashboard Module

### Mục đích
Panel runtime góc phải — stats, phase, toggles perf, stop script.

### Components

| Element | Chức năng |
|---------|-----------|
| Header "GAG2 KAITUN" | Kéo thả panel |
| Toggle 3D | `enableHideGarden3D` — ẩn mesh cây trong garden |
| Toggle GFX | `applyLowGraphics` — tắt hiệu ứng |
| Toggle FF | `applyFFlags` — FFlags tối ưu |
| Toggle STOP | Dừng script (`stopKaitun`) |
| Body text | `buildDashboardText()` refresh mỗi `UIUpdateInterval` |

### Dashboard metrics

- FPS, FFlags/LowGFX/Hide3D status
- `State.phase` + `State.status`
- Sheckles, movement mode, garden name, Night value
- Pet finder target + owned checkmark
- Inventory breakdown (cached `InvScanInterval`)
- World plants count, hidden parts count

### Hotkeys

- **RightShift** — ẩn/hiện panel

### API runtime

```lua
getgenv().KaitunStop()      -- dừng script
getgenv().KaitunRunning     -- boolean trạng thái
getgenv().KaitunState       -- table State (phase, status, ...)
```

---

## 5. Main Orchestrator

```
while KaitunRunning do
    1. seed_snatch wait (if claiming)
    2. tutorial (send first pet via GiftMail)
    3. pet_hunt OR hop (if PetFinder + đủ tiền)
    4. runFarmTick (if garden exists)
    5. wait MainLoopDelay (0.25s)
end
```

Background (spawned at init):
- Auto sell, expand, webhook, stay in base, gift mail
- World seed snatcher listeners
- UI updater, FPS tracker, anti-AFK

---

## Debug cheat sheet

| Phase stuck | Check |
|-------------|-------|
| `waiting_garden` | Garden chưa load / OwnerUserId mismatch |
| `tutorial` | Set `GiftMail.RecipientUserId` hoặc `Tutorial.Enable = false` |
| `seed_snatch` | Tắt `AutoCollectGold/Rainbow` nếu loop vô hạn |
| `pet_hunt` | Thử `MovementMode = "cheat"` |
| `hop` | Executor cần HTTP `request` |
| Farm không mua | Mở SeedShop in-game hoặc dùng fallback buy |

Console: mọi log qua `[Kaitun]` prefix + `State.status`.

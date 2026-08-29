local TARGET_PLACE_ID = 77649408247578

local selectedMap = "Desert Temple"
local selectedDifficulty = "Insane"

getgenv().AutoCreateAndStart = false
getgenv().AutoFarmEnabled = false
getgenv().DungeonFarmLoop = nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local function pressKey(keyStr)
    local success, keyCode = pcall(function() return Enum.KeyCode[keyStr:upper()] end)
    if success and keyCode then
        task.spawn(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

local function tryStartGame()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("remotes")
        if remotes then
            local changeStartValue = remotes:FindFirstChild("changeStartValue")
            if changeStartValue and changeStartValue:IsA("RemoteEvent") then
                changeStartValue:FireServer()
            end
        end
    end)
end

local function stopFarm()
    if getgenv().DungeonFarmLoop then
        getgenv().DungeonFarmLoop:Disconnect()
        getgenv().DungeonFarmLoop = nil
    end
end

local function startFarm()
    if game.PlaceId == TARGET_PLACE_ID then
        warn("[AutoFarm] ไม่สามารถใช้งานระบบฟาร์มในห้อง Lobby ได้!")
        return
    end

    stopFarm()

    local currentTarget = nil
    local lastSkillTime = 0
    local lastFoundMonsterTime = tick()
    local isDodgingBoss = false

    local function getTarget()
        if currentTarget and currentTarget.Parent then
            local hum = currentTarget:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
                if hrp then
                    lastFoundMonsterTime = tick()
                    return hrp
                end
            end
        end

        currentTarget = nil
        local scanArea = workspace:FindFirstChild("dungeon") or workspace

        for _, obj in ipairs(scanArea:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChild("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")

                if hum and hrp and hum.Health > 0 then
                    currentTarget = obj
                    hrp.Size = Vector3.new(25, 25, 25)
                    hrp.Transparency = 0.8
                    hrp.CanCollide = false
                    lastFoundMonsterTime = tick()
                    return hrp
                end
            end
        end
        return nil
    end

    getgenv().DungeonFarmLoop = RunService.Heartbeat:Connect(function()
        if not getgenv().AutoFarmEnabled or game.PlaceId == TARGET_PLACE_ID then return end

        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

            local targetHrp = getTarget()
            if targetHrp then
                local safeHeight = 12
                if workspace:FindFirstChild("bossShot") then
                    safeHeight = 50
                    isDodgingBoss = true
                else
                    isDodgingBoss = false
                end
                local safePos = targetHrp.Position + Vector3.new(0, safeHeight, 0)
                hrp.CFrame = CFrame.lookAt(safePos, targetHrp.Position)
            else
                isDodgingBoss = false
                if tick() - lastFoundMonsterTime > 1.5 then
                    tryStartGame()
                end
            end
        end)
    end)

    task.spawn(function()
        while getgenv().AutoFarmEnabled do
            task.wait(0.05)
            pcall(function()
                if game.PlaceId == TARGET_PLACE_ID then return end
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

                local targetHrp = getTarget()
                if not targetHrp or isDodgingBoss then return end

                if tick() - lastSkillTime > 0.15 then
                    local items = {}
                    if LocalPlayer:FindFirstChild("Backpack") then
                        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, v) end
                    end
                    for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end

                    for _, item in ipairs(items) do
                        if item:IsA("Tool") then
                            local slot = item:FindFirstChild("abilitySlot")
                            local cd = item:FindFirstChild("cooldown")
                            if slot and cd and slot:IsA("ValueBase") and cd:IsA("ValueBase") then
                                if cd.Value <= 0.1 then
                                    pressKey(tostring(slot.Value))
                                    lastSkillTime = tick()
                                    return
                                end
                            end
                        end
                    end
                end

                local equippedTool = char:FindFirstChildOfClass("Tool")
                if equippedTool then
                    equippedTool:Activate()
                end
            end)
        end
    end)
end

-- ================= WindUI Setup =================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub",
    Icon = "ghost",
    Author = "by .TiM",
    Folder = "WindUI",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.LeftShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = false,
        Anonymous = false,
        Callback = function() end,
    },
})

-- ================= สร้าง ConfigManager และ Config Instance =================
local ConfigManager = Window:ConfigManager({
    Directory = "WindUI",
})

-- สร้าง Instance ของ Config ชื่อ "config"
local myConfig = ConfigManager:CreateConfig("config")

-- ลงทะเบียน Flag ทั้งหมดที่ต้องการให้จำค่า
myConfig:Register("SelectedMap", { Type = "Dropdown" })
myConfig:Register("SelectedDifficulty", { Type = "Dropdown" })
myConfig:Register("AutoCreateAndStart", { Type = "Toggle" })
myConfig:Register("AutoFarmEnabled", { Type = "Toggle" })

-- ================= สร้าง UI Tabs =================
local LobbyTab = Window:Tab({
    Title = "Lobby",
    Icon = "house",
    Locked = false,
})

LobbyTab:Section({
    Title = "Auto Start Dungeon",
    TextXAlignment = "Left",
    TextSize = 16,
})

LobbyTab:Dropdown({
    Title = "Map Selected",
    Values = {
        "Egg Island", "Desert Temple", "Winter Outpost", "Pirate Island",
        "King's Castle", "The Underworld", "Samurai Palace", "The Canals",
        "Ghastly Harbor", "Steampunk Sewers", "Orbital Outpost", "Volcanic Chambers",
        "Aquatic Temple", "Enchanted Forest", "Northern Lands", "Gilded Skies", "Oni Dungeon"
    },
    Default = selectedMap,
    Flag = "SelectedMap",
    Callback = function(value)
        selectedMap = value
        myConfig:Save()
    end
})

LobbyTab:Dropdown({
    Title = "Difficulty Selection",
    Values = {"Easy", "Medium", "Hard", "Insane", "Nightmare", "Hardcore Mode"},
    Default = selectedDifficulty,
    Flag = "SelectedDifficulty",
    Callback = function(value)
        selectedDifficulty = value
        myConfig:Save()
    end
})

LobbyTab:Toggle({
    Title = "AutoStart",
    Default = getgenv().AutoCreateAndStart,
    Flag = "AutoCreateAndStart",
    Callback = function(Value)
        getgenv().AutoCreateAndStart = Value
        myConfig:Save()
    end
})

local DungeonTab = Window:Tab({
    Title = "Dungeon",
    Icon = "bow-arrow",
    Locked = false,
})

DungeonTab:Section({
    Title = "Auto Farm",
    TextXAlignment = "Left",
    TextSize = 16,
})

DungeonTab:Toggle({
    Title = "Auto Farm",
    Desc = "Auto Farm Dungeon & Boss Dodge",
    Default = getgenv().AutoFarmEnabled,
    Flag = "AutoFarmEnabled",
    Callback = function(State)
        getgenv().AutoFarmEnabled = State
        myConfig:Save()

        if State then
            startFarm()
        else
            stopFarm()
        end
    end
})

-- ================= โหลด Config อัตโนมัติ =================
pcall(function()
    myConfig:Load()
    
    -- อัปเดตค่าตัวแปรหลังจากโหลด
    selectedMap = myConfig:GetValue("SelectedMap") or selectedMap
    selectedDifficulty = myConfig:GetValue("SelectedDifficulty") or selectedDifficulty
    getgenv().AutoCreateAndStart = myConfig:GetValue("AutoCreateAndStart") or false
    getgenv().AutoFarmEnabled = myConfig:GetValue("AutoFarmEnabled") or false
end)

-- ================= Loops & Execution =================
task.spawn(function()
    while true do
        if getgenv().AutoCreateAndStart then
            pcall(function()
                if game.PlaceId ~= TARGET_PLACE_ID then return end

                local remotes = ReplicatedStorage:WaitForChild("remotes", 5)
                if not remotes then return end

                local createLobbyRemote = remotes:FindFirstChild("createLobby")
                local startDungeonRemote = remotes:FindFirstChild("startDungeon")

                if createLobbyRemote then
                    local args = {
                        selectedMap,
                        selectedDifficulty,
                        0,
                        false,
                        false,
                        false
                    }
                    createLobbyRemote:InvokeServer(unpack(args))
                    task.wait(1)
                end

                if startDungeonRemote then
                    startDungeonRemote:FireServer()
                    task.wait(1)
                end
            end)
        end
        task.wait(2)
    end
end)

if game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(function()
        if getgenv().AutoFarmEnabled then
            startFarm()
        end
    end)
end

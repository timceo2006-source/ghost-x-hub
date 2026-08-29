-- ================= CONFIG SYSTEM =================
local CONFIG_FOLDER = "GhostHub_Configs"
local CONFIG_FILE = CONFIG_FOLDER .. "/settings.json"

local HttpService = game:GetService("HttpService")

-- ฟังก์ชันโหลด config
local function LoadConfig()
    local success, result = pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        if isfile(CONFIG_FILE) then
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- ฟังก์ชันเซฟ config
local function SaveConfig(data)
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

-- ================= MAIN SCRIPT =================
local TARGET_PLACE_ID = 77649408247578

-- โหลดค่า config เริ่มต้น
local savedConfig = LoadConfig()

-- กำหนดค่าเริ่มต้นด้วย Default Values ที่ปลอดภัย
local defaultConfig = {
    selectedMap = "Desert Temple",
    selectedDifficulty = "Insane",
    AutoCreateAndStart = false,
    AutoFarmEnabled = false
}

-- ใช้ค่าจาก config หรือค่าเริ่มต้น (ป้องกัน nil)
local selectedMap = (savedConfig and savedConfig.selectedMap) or defaultConfig.selectedMap
local selectedDifficulty = (savedConfig and savedConfig.selectedDifficulty) or defaultConfig.selectedDifficulty

getgenv().AutoCreateAndStart = (savedConfig and savedConfig.AutoCreateAndStart) ~= nil and savedConfig.AutoCreateAndStart or defaultConfig.AutoCreateAndStart
getgenv().AutoFarmEnabled = (savedConfig and savedConfig.AutoFarmEnabled) ~= nil and savedConfig.AutoFarmEnabled or defaultConfig.AutoFarmEnabled
getgenv().DungeonFarmLoop = nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันรวมเซฟ config
local function UpdateConfig()
    SaveConfig({
        selectedMap = selectedMap or "Desert Temple",
        selectedDifficulty = selectedDifficulty or "Insane",
        AutoCreateAndStart = getgenv().AutoCreateAndStart or false,
        AutoFarmEnabled = getgenv().AutoFarmEnabled or false
    })
end

-- ================= FUNCTIONS =================
-- ... (ฟังก์ชันอื่นๆ เหมือนเดิม) ...

-- ================= UI SETUP =================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub",
    Icon = "ghost",
    Author = "by .TiM",
    Folder = "GhostHub",
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

-- ================= TABS =================
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

-- เพิ่ม Flag ให้กับ Dropdown เพื่อให้ WindUI จัดการค่าได้
LobbyTab:Dropdown({
    Title = "Map Selected",
    Values = {
        "Egg Island", "Desert Temple", "Winter Outpost", "Pirate Island",
        "King's Castle", "The Underworld", "Samurai Palace", "The Canals",
        "Ghastly Harbor", "Steampunk Sewers", "Orbital Outpost", "Volcanic Chambers",
        "Aquatic Temple", "Enchanted Forest", "Northern Lands", "Gilded Skies", "Oni Dungeon"
    },
    Default = selectedMap,
    Flag = "SelectedMap",  -- เพิ่ม Flag
    Callback = function(value)
        selectedMap = value
        UpdateConfig()
    end
})

LobbyTab:Dropdown({
    Title = "Difficulty Selection",
    Values = {"Easy", "Medium", "Hard", "Insane", "Nightmare", "Hardcore Mode"},
    Default = selectedDifficulty,
    Flag = "SelectedDifficulty",  -- เพิ่ม Flag
    Callback = function(value)
        selectedDifficulty = value
        UpdateConfig()
    end
})

LobbyTab:Toggle({
    Title = "AutoStart",
    Default = getgenv().AutoCreateAndStart,
    Flag = "AutoCreateAndStart",  -- เพิ่ม Flag
    Callback = function(Value)
        getgenv().AutoCreateAndStart = Value
        UpdateConfig()
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
    Flag = "AutoFarmEnabled",  -- เพิ่ม Flag
    Callback = function(State)
        getgenv().AutoFarmEnabled = State
        UpdateConfig()

        if State then
            startFarm()
        else
            stopFarm()
        end
    end
})

-- ================= LOOPS & EXECUTION =================
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
                        selectedMap or "Desert Temple",
                        selectedDifficulty or "Insane",
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

-- เริ่ม Auto Farm อัตโนมัติถ้าเปิดใช้งานอยู่
if getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(startFarm)
end

-- ================= PRINT STATUS (แก้ไขแล้ว) =================
-- ใช้ tostring เพื่อป้องกัน error และใช้ fallback values
print("[Ghost Hub] Loaded Successfully!")
print(string.format("[Ghost Hub] Config: Map = %s, Difficulty = %s", 
    tostring(selectedMap or "Desert Temple"), 
    tostring(selectedDifficulty or "Insane")))
print("[Ghost Hub] AutoStart = " .. tostring(getgenv().AutoCreateAndStart or false))
print("[Ghost Hub] AutoFarm = " .. tostring(getgenv().AutoFarmEnabled or false))

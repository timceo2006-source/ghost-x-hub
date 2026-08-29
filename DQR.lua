local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub",
    Icon = "ghost",
    Author = "by .TiM",
    Folder = "MyGhostHub",
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
        Callback = function()
        end,
    },
})

local Tab = Window:Tab({
    Title = "Lobby",
    Icon = "house",
    Locked = false,
})

local Section = Tab:Section({
    Title = "Auto Start Dungeon",
    TextXAlignment = "Left",
    TextSize = 16,
})

getgenv().AutoCreateAndStart = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TARGET_PLACE_ID = 77649408247578

local selectedMap = "Desert Temple"
local selectedDifficulty = "Insane"

Tab:Dropdown({
    Title = "Map Selected",
    Values = {
        "Egg Island",
        "Desert Temple",
        "Winter Outpost",
        "Pirate Island",
        "King's Castle",
        "The Underworld",
        "Samurai Palace",
        "The Canals",
        "Ghastly Harbor",
        "Steampunk Sewers",
        "Orbital Outpost",
        "Volcanic Chambers",
        "Aquatic Temple",
        "Enchanted Forest",
        "Northern Lands",
        "Gilded Skies",
        "Oni Dungeon"
    },
    Default = "Desert Temple",
    Callback = function(value)
        selectedMap = value
    end
})

Tab:Dropdown({
    Title = "Difficulty Selection",
    Values = {"Easy", "Medium", "Hard", "Insane", "Nightmare", "Hardcore Mode"},
    Default = "Insane",
    Callback = function(value)
        selectedDifficulty = value
    end
})

Tab:Toggle({
    Title = "AutoStart",
    Default = Auto
    Callback = function(Value)
        getgenv().AutoCreateAndStart = Value
    end
})

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

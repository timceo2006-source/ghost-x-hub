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
    Title = "Main",
    Locked = false,
})

local Button = Tab:Button({
    Title = "Aimbot",
    Desc = "Aimbot+Button",
    Locked = false,
    Callback = function()
        -- ...
    end
})
local Button = Tab:Button({
    Title = "ESP",
    Desc = "ESP Players",
    Locked = false,
    Callback = function()
        -- ...
    end
})

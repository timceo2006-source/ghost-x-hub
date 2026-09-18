local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SetAutoRoll = RS:WaitForChild("Network"):WaitForChild("RollService"):WaitForChild("RE"):WaitForChild("SetAutoRoll")

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
	Callback = function()
	end
})

local Tab = Window:Tab({
    Title = "Main",
    Icon = "house",
    Locked = false,
})

local AutoRollToggle = Tab:Toggle({
    Title = "Auto Roll",
    Desc = "Auto Roll Unit",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        if state then
            pcall(function()
                SetAutoRoll:FireServer(true)
                local rootUI = LocalPlayer.PlayerGui:FindFirstChild("Root")
                if rootUI and rootUI:FindFirstChild("Rolling") then
                    local hiddenBtn = rootUI.Rolling:FindFirstChild("Options") and rootUI.Rolling.Options:FindFirstChild("HiddenRoll")
                    if hiddenBtn and getconnections then
                        for _, connection in pairs(getconnections(hiddenBtn.MouseButton1Click)) do
                            connection:Fire()
                        end
                    end
                    rootUI.Rolling.Visible = false
                end
            end)
        end
    end
})

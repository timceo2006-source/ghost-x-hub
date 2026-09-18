local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer

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
	ScrollBarEnabled = false
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
        pcall(function()
            local SetAutoRoll = RS:WaitForChild("Network"):WaitForChild("RollService"):WaitForChild("RE"):WaitForChild("SetAutoRoll")
            SetAutoRoll:FireServer(state)
            
            if state then
                local HiddenRoll = LocalPlayer.PlayerGui.Root.Rolling.Options.HiddenRoll
                
                if getconnections then
                    for _, connection in pairs(getconnections(HiddenRoll.MouseButton1Click)) do
                        connection:Fire()
                    end
                elseif firesignal then
                    firesignal(HiddenRoll.MouseButton1Click)
                end
                
                LocalPlayer.PlayerGui.Root.Rolling.Visible = false
            end
        end)
    end
})

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local isAutoRoll = false 

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
        pcall(function()
            local SetAutoRoll = RS:WaitForChild("Network"):WaitForChild("RollService"):WaitForChild("RE"):WaitForChild("SetAutoRoll")
            SetAutoRoll:FireServer(state)
        end)
        
        if state then
            task.spawn(function()
                task.wait(0.2)
                pcall(function()
                    local HiddenRoll = game:GetService("Players").LocalPlayer.PlayerGui.Root.Rolling.Options.HiddenRoll
                    local GuiService = game:GetService("GuiService")
                    local VIM = game:GetService("VirtualInputManager")
                    
                    GuiService.SelectedObject = HiddenRoll
                    
                    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    
                    GuiService.SelectedObject = nil
                end)
            end)
        end
    end
})})

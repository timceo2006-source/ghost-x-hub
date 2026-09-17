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
})

local Tab = Window:Tab({
    Title = "Main",
    Icon = "house", -- optional
    Locked = false,
})

local = Tab:Toggle({
    Title = "Auto Roll",
    Desc = "Auto Roll Unit",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        State.AutoRoll = state
        
        if state then
            task.spawn(function()
                while State.AutoRoll do
                    pcall(function()
                        if RollService:FindFirstChild("RE") and RollService.RE:FindFirstChild("Roll") then
                            RollService.RE.Roll:FireServer()
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

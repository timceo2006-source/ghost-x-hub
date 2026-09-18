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
        isAutoRoll = state
        
        -- ส่งค่าเปิด/ปิดไปที่เกมโดยตรง
        pcall(function()
            local SetAutoRoll = RS:WaitForChild("Network"):WaitForChild("RollService"):WaitForChild("RE"):WaitForChild("SetAutoRoll")
            SetAutoRoll:FireServer(state)
        end)
        
        -- ถ้ากดเปิด ให้ลูปซ่อน UI ตลอดเวลา
        if state then
            task.spawn(function()
                while isAutoRoll do
                    pcall(function()
                        local Root = LocalPlayer.PlayerGui:FindFirstChild("Root")
                        if Root and Root:FindFirstChild("Rolling") then
                            if Root.Rolling.Visible then
                                Root.Rolling.Visible = false
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.FogEnd = 100000
Lighting.GlobalShadows = false

Lighting.Changed:Connect(function()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.GlobalShadows = false
end)

local FOV_RADIUS = 150

local function isVisible(targetPart)
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("Head") then return false end

	local origin = Camera.CFrame.Position
	local destination = targetPart.Position

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char, targetPart.Parent}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(origin, destination - origin, rayParams)
	if result then return false end
	return true
end

local function getBestTargetInFOV(myPos)
	local closestTarget = nil
	local shortestDist = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hum = char:FindFirstChildOfClass("Humanoid")
			local head = char:FindFirstChild("Head")
			local torso = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
			
			if hum and hum.Health > 0 then
				local targetPart = nil
				if head and isVisible(head) then
					targetPart = head
				elseif torso and isVisible(torso) then
					targetPart = torso
				end
				
				if targetPart then
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if screenDist <= FOV_RADIUS then
							local dist = (myPos - targetPart.Position).Magnitude
							if dist < shortestDist then
								shortestDist = dist
								closestTarget = targetPart
							end
						end
					end
				end
			end
		end
	end
	return closestTarget
end

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

local aimbotHubEnabled = false
local aimbotEnabled = false
local aimbotLoop = nil
local screenGui = nil

Tab:Button({
	Title = "Aimbot",
	Desc = "เปิด/ปิด Aimbot และ ปุ่มกลางจอ",
	Locked = false,
	Callback = function()
		aimbotHubEnabled = not aimbotHubEnabled
		
		if aimbotHubEnabled then
			if screenGui then screenGui:Destroy() end
			
			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "AimbotToggleGui"
			screenGui.ResetOnSpawn = false
			pcall(function() screenGui.Parent = CoreGui end)
			if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

			local toggleButton = Instance.new("TextButton")
			toggleButton.Size = UDim2.new(0, 100, 0, 30)
			toggleButton.Position = UDim2.new(0.5, -50, 0, 10)
			toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			toggleButton.BorderColor3 = Color3.fromRGB(0, 255, 255)
			toggleButton.TextColor3 = Color3.fromRGB(255, 50, 50)
			toggleButton.TextSize = 13
			toggleButton.Font = Enum.Font.SourceSansBold
			toggleButton.Text = "AIM: OFF"
			toggleButton.Parent = screenGui
			
			aimbotEnabled = false

			toggleButton.MouseButton1Click:Connect(function()
				aimbotEnabled = not aimbotEnabled
				if aimbotEnabled then
					toggleButton.TextColor3 = Color3.fromRGB(50, 255, 50)
					toggleButton.Text = "AIM: ON"
				else
					toggleButton.TextColor3 = Color3.fromRGB(255, 50, 50)
					toggleButton.Text = "AIM: OFF"
				end
			end)

			if not aimbotLoop then
				aimbotLoop = RunService.RenderStepped:Connect(function()
					if aimbotEnabled then
						local char = LocalPlayer.Character
						if char and char:FindFirstChild("HumanoidRootPart") then
							local targetPart = getBestTargetInFOV(char.HumanoidRootPart.Position)
							if targetPart then
								local currentCamCF = Camera.CFrame
								local targetCF = CFrame.new(currentCamCF.Position, targetPart.Position)
								Camera.CFrame = currentCamCF:Lerp(targetCF, 0.3)
							end
						end
					end
					pcall(function()
						if Camera:FindFirstChild("CameraShake") then
							Camera.CameraShake:Destroy()
						end
					end)
				end)
			end
		else
			aimbotEnabled = false
			if screenGui then
				screenGui:Destroy()
				screenGui = nil
			end
			if aimbotLoop then
				aimbotLoop:Disconnect()
				aimbotLoop = nil
			end
		end
	end
})

local espHubEnabled = false
local espLoop = nil
local playerAddedConn = nil
local charAddedConns = {}

Tab:Button({
	Title = "ESP",
	Desc = "เปิด/ปิด ESP Players",
	Locked = false,
	Callback = function()
		espHubEnabled = not espHubEnabled
		
		if espHubEnabled then
			-- ลบ WaitForChild ออกเพื่อไม่ให้ลูป RenderStepped ค้าง
			local function applyEsp(char)
				local head = char:FindFirstChild("Head")
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if not head or not humanoid then return end

				if not head:FindFirstChild("PlayerInfoGui") then
					local gui = Instance.new("BillboardGui")
					gui.Name = "PlayerInfoGui"
					gui.Adornee = head
					gui.Size = UDim2.new(0, 200, 0, 50)
					gui.StudsOffset = Vector3.new(0, 3, 0)
					gui.AlwaysOnTop = true
					gui.Parent = head

					local textLabel = Instance.new("TextLabel")
					textLabel.Name = "InfoText"
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
					textLabel.TextStrokeTransparency = 0
					textLabel.TextSize = 14
					textLabel.Font = Enum.Font.SourceSansBold
					textLabel.Parent = gui
				end

				if not char:FindFirstChild("PlayerHighlight") then
					local hl = Instance.new("Highlight")
					hl.Name = "PlayerHighlight"
					hl.Adornee = char
					hl.Parent = char
					hl.FillColor = Color3.fromRGB(0, 255, 255)
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.5
					hl.OutlineTransparency = 0
				end
			end

			espLoop = RunService.RenderStepped:Connect(function()
				local char = LocalPlayer.Character
				if not char or not char:FindFirstChild("HumanoidRootPart") then return end
				local myPos = char.HumanoidRootPart.Position

				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer then
						local pChar = player.Character
						if pChar then
							local pHum = pChar:FindFirstChildOfClass("Humanoid")
							local head = pChar:FindFirstChild("Head")
							
							if pHum and head then
								-- เรียกใช้ applyEsp แบบไม่ Delay
								applyEsp(pChar)

								local gui = head:FindFirstChild("PlayerInfoGui")
								if gui then
									local txt = gui:FindFirstChild("InfoText")
									if txt then
										local dist = math.floor((myPos - head.Position).Magnitude)
										if dist <= 2500 then
											local hp = math.floor(pHum.Health)
											txt.Text = string.format("%s | HP: %d | [%dm]", player.Name, hp, dist)
											gui.Enabled = true
											
											-- แก้ไขลอจิกขนาดตัวหนังสือเล็กน้อยให้ไล่สเกลถูกต้อง
											if dist > 1500 then
												txt.TextSize = 11
											elseif dist > 500 then
												txt.TextSize = 12
											else
												txt.TextSize = 14
											end
										else
											gui.Enabled = false
										end
									end
								end
								
								local hl = pChar:FindFirstChild("PlayerHighlight")
								if hl then
									local dist = math.floor((myPos - head.Position).Magnitude)
									hl.Enabled = (dist <= 2500)
								end
							end
						end
					end
				end
			end)
		else
			if espLoop then
				espLoop:Disconnect()
				espLoop = nil
			end
			
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local head = player.Character:FindFirstChild("Head")
					if head and head:FindFirstChild("PlayerInfoGui") then
						head.PlayerInfoGui:Destroy()
					end
					if player.Character:FindFirstChild("PlayerHighlight") then
						player.Character.PlayerHighlight:Destroy()
					end
				end
			end
		end
	end
})

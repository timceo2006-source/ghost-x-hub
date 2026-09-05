local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
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

local function isAimingWithTool()
	local char = LocalPlayer.Character
	if not char then return false end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return false end
	local isHoldingClick = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or (UserInputService.TouchEnabled and #UserInputService:GetTouches() > 0)
	return isHoldingClick
end

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

local function getClosestVisiblePlayer(myPos)
	local closestTarget = nil
	local shortestDist = math.huge
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if player.Team ~= LocalPlayer.Team or not LocalPlayer.Team then
				local char = player.Character
				local hum = char:FindFirstChildOfClass("Humanoid")
				local head = char:FindFirstChild("Head")
				
				if hum and hum.Health > 0 and head then
					if isVisible(head) then
						local dist = (myPos - head.Position).Magnitude
						if dist < shortestDist then
							shortestDist = dist
							closestTarget = head
						end
					end
				end
			end
		end
	end
	return closestTarget
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local myPos = char.HumanoidRootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local pChar = player.Character
			local pHum = pChar:FindFirstChildOfClass("Humanoid")
			local head = pChar:FindFirstChild("Head")
			
			if pHum and pHum.Health > 0 and head then
				local gui = head:FindFirstChild("PlayerInfoGui")
				if not gui then
					gui = Instance.new("BillboardGui")
					gui.Name = "PlayerInfoGui"
					gui.Adornee = head
					-- ใช้ Size แบบ Scale ผสม Offset เพื่อให้ปรับขนาดตามระยะอัตโนมัติ
					gui.Size = UDim2.new(0, 160, 0, 40)
					gui.StudsOffset = Vector3.new(0, 2.5, 0)
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

				local txt = gui:FindFirstChild("InfoText")
				if txt then
					local dist = math.floor((myPos - head.Position).Magnitude)
					local hp = math.floor(pHum.Health)
					txt.Text = string.format("%s | HP: %d | [%dm]", player.Name, hp, dist)
					
					-- ระบบควบคุมขนาดตัวหนังสือไม่ให้เล็กเกินไปเมื่ออยู่ไกล
					-- ยิ่งไกล ค่า TextScaled จะช่วยปรับลง แต่เราจำกัดขนาดต่ำสุดไว้ที่ 11 เพื่อให้อ่านออก
					if dist > 1500 then
						txt.TextSize = 11
					elseif dist > 150 then
						txt.TextSize = 12
					else
						txt.TextSize = 14
					end
				end
				
				local hl = pChar:FindFirstChild("PlayerHighlight")
				if not hl then
					hl = Instance.new("Highlight")
					hl.Name = "PlayerHighlight"
					hl.Adornee = pChar
					hl.Parent = pChar
					hl.FillColor = Color3.fromRGB(0, 255, 255)
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.6
					hl.OutlineTransparency = 0
				end
			end
		end
	end

	if isAimingWithTool() then
		local targetHead = getClosestVisiblePlayer(myPos)
		if targetHead then
			local currentCamCF = Camera.CFrame
			local targetCF = CFrame.new(currentCamCF.Position, targetHead.Position)
			Camera.CFrame = currentCamCF:Lerp(targetCF, 0.3)
		end
	end

	pcall(function()
		if Camera:FindFirstChild("CameraShake") then
			Camera.CameraShake:Destroy()
		end
	end)
end)

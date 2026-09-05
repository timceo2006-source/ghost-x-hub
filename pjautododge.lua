local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

local activeDrawings = {}

local function clearDrawings()
	for _, drawing in pairs(activeDrawings) do
		drawing:Remove()
	end
	activeDrawings = {}
end

local function createEspElements()
	local box = Drawing.new("Square")
	box.Visible = false
	box.Color = Color3.fromRGB(0, 255, 255)
	box.Thickness = 1.5
	box.Filled = false
	table.insert(activeDrawings, box)

	local text = Drawing.new("Text")
	text.Visible = false
	text.Center = true
	text.Outline = true
	text.Color = Color3.fromRGB(255, 255, 255)
	text.Size = 14
	table.insert(activeDrawings, text)

	return box, text
end

local function isHoldingTool()
	local char = LocalPlayer.Character
	if not char then return false end
	return char:FindFirstChildOfClass("Tool") ~= nil
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
	clearDrawings()

	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local myPos = char.HumanoidRootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local pChar = player.Character
			local pHum = pChar:FindFirstChildOfClass("Humanoid")
			local pRoot = pChar:FindFirstChild("HumanoidRootPart")
			
			if pHum and pHum.Health > 0 and pRoot then
				local dist = (myPos - pRoot.Position).Magnitude
				if dist < 2500 then
					local vector, onScreen = Camera:WorldToViewportPoint(pRoot.Position)
					if onScreen then
						local box, txt = createEspElements()
						local scaleFactor = 1000 / vector.Z
						box.Size = Vector2.new(25 * scaleFactor, 45 * scaleFactor)
						box.Position = Vector2.new(vector.X - box.Size.X / 2, vector.Y - box.Size.Y / 2)
						box.Visible = true

						txt.Text = string.format("%s [%dm]", player.Name, math.floor(dist))
						txt.Position = Vector2.new(vector.X, box.Position.Y - 18)
						txt.Visible = true
					end
				end
			end
		end
	end

	if isHoldingTool() then
		local targetHead = getClosestVisiblePlayer(myPos)
		if targetHead then
			local currentCamCF = Camera.CFrame
			local targetCF = CFrame.new(currentCamCF.Position, targetHead.Position)
			Camera.CFrame = currentCamCF:Lerp(targetCF, 0.25)
		end
	end

	pcall(function()
		if Camera:FindFirstChild("CameraShake") then
			Camera.CameraShake:Destroy()
		end
	end)
end)

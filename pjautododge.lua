local TARGET_PLACE_ID = 77649408247578

local selectedMap = "The Underworld"
local selectedDifficulty = "Insane"

local ORBIT_RADIUS = 12 -- ระยะห่างรอบตัวมอนสเตอร์
local HOVER_HEIGHT = 14 -- ความสูงในการลอยตัว

getgenv().AutoCreateAndStart = true
getgenv().AutoFarmEnabled = true
getgenv().DungeonFarmLoop = nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ==================== GUI (มุมขวาบน) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SmartOrbitFarm"
screenGui.ResetOnSpawn = false
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
elseif gethui then
    screenGui.Parent = gethui()
else
    screenGui.Parent = CoreGui
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 115)
mainFrame.Position = UDim2.new(0.68, 0, 0.08, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Smart Orbit Logic"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0, 20)
timerLabel.Position = UDim2.new(0, 0, 0, 25)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "Status: Ready"
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.TextSize = 11
timerLabel.Font = Enum.Font.SourceSans
timerLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.9, 0, 0, 38)
toggleButton.Position = UDim2.new(0.05, 0, 0.52, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Text = "Status: ON"
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

local startFarm, stopFarm

toggleButton.MouseButton1Click:Connect(function()
    getgenv().AutoFarmEnabled = not getgenv().AutoFarmEnabled
    getgenv().AutoCreateAndStart = getgenv().AutoFarmEnabled
    
    if getgenv().AutoFarmEnabled then
        toggleButton.Text = "Status: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        timerLabel.Text = "Status: Ready"
        if game.PlaceId ~= TARGET_PLACE_ID then
            task.defer(startFarm)
        end
    else
        toggleButton.Text = "Status: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(205, 50, 50)
        timerLabel.Text = "Paused"
        stopFarm()
    end
end)

local function pressKey(keyStr)
    local success, keyCode = pcall(function() return Enum.KeyCode[keyStr:upper()] end)
    if success and keyCode then
        task.spawn(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

local function tryStartGame()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("remotes")
        if remotes then
            local changeStartValue = remotes:FindFirstChild("changeStartValue")
            if changeStartValue and changeStartValue:IsA("RemoteEvent") then
                changeStartValue:FireServer()
            end
        end
    end)
end

function stopFarm()
    if getgenv().DungeonFarmLoop then
        getgenv().DungeonFarmLoop:Disconnect()
        getgenv().DungeonFarmLoop = nil
    end
end

function startFarm()
    if game.PlaceId == TARGET_PLACE_ID then return end
    stopFarm()

    local lastSkillTime = 0
    local lastFoundMonsterTime = tick()

    local function getTarget()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local dungeon = workspace:FindFirstChild("dungeon")
        if not dungeon then return nil end

        local bestHeart = nil
        local nearestEnemy = nil
        local shortestDistance = math.huge

        for _, room in ipairs(dungeon:GetChildren()) do
            if room:IsA("Folder") or room:IsA("Model") then
                for _, obj in ipairs(room:GetDescendants()) do
                    if obj:IsA("Model") and obj ~= char then
                        local hum = obj:FindFirstChild("Humanoid")
                        local targetHrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
                        
                        if hum and targetHrp and hum.Health > 0 then
                            if not Players:GetPlayerFromCharacter(obj) then
                                if string.find(string.lower(obj.Name), "heart") then
                                    bestHeart = targetHrp
                                else
                                    local dist = (targetHrp.Position - hrp.Position).Magnitude
                                    if dist < shortestDistance then
                                        shortestDistance = dist
                                        nearestEnemy = targetHrp
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return bestHeart or nearestEnemy
    end

    -- ฟังก์ชันเช็คว่าพิกัดรอบตัวปลอดภัยจากหิน/ฮิตบ็อกซ์ไหม
    local function isPositionSafe(pos)
        local dungeon = workspace:FindFirstChild("dungeon")
        if not dungeon then return true end
        
        for _, room in ipairs(dungeon:GetChildren()) do
            if room:IsA("Folder") or room:IsA("Model") then
                for _, obj in ipairs(room:GetDescendants()) do
                    if obj:IsA("BasePart" ) and obj.Transparency < 0.9 then
                        local nameLower = string.lower(obj.Name)
                        local color = obj.Color
                        local isHazard = (color.R > 0.4 and color.G < 0.3 and color.B < 0.3) or 
                                         string.find(nameLower, "spike") or 
                                         string.find(nameLower, "rock") or 
                                         string.find(nameLower, "stone") or 
                                         string.find(nameLower, "hitbox") or
                                         string.find(nameLower, "warn")
                                         
                        if isHazard then
                            if (obj.Position - pos).Magnitude < 6 then -- ถ้ารัศมีใกล้ฮิตบ็อกซ์อันตรายเกิน 6 หน่วย ถือว่าไม่ปลอดภัย
                                return false
                            end
                        end
                    end
                end
            end
        end
        return true
    end

    -- ลูปหลัก: สุ่มหาจุดที่ปลอดภัยที่สุดรอบตัวมอนสเตอร์เพื่อเกาะตี
    getgenv().DungeonFarmLoop = RunService.Heartbeat:Connect(function()
        if not getgenv().AutoFarmEnabled or game.PlaceId == TARGET_PLACE_ID then return end

        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            local targetHrp = getTarget()
            if targetHrp and targetHrp.Parent then
                lastFoundMonsterTime = tick()
                timerLabel.Text = "Status: Safe Orbit Attacking"
                
                -- เช็ค 8 มุมรอบตัวมอนสเตอร์ (0 ถึง 360 องศา) เพื่อหาจุดที่ไม่มีหินโผล่
                local bestPos = nil
                for angle = 0, math.pi * 2, math.pi / 4 do
                    local candidatePos = targetHrp.Position + Vector3.new(math.cos(angle) * ORBIT_RADIUS, HOVER_HEIGHT, math.sin(angle) * ORBIT_RADIUS)
                    if isPositionSafe(candidatePos) then
                        bestPos = candidatePos
                        break -- เจอจุดปลอดภัยแรก วาปไปทันที
                    end
                end
                
                -- ถ้าทุกมุมอันตรายหมด ให้ถอยออกไปตั้งหลักไกลขึ้นชั่วคราว
                if not bestPos then
                    bestPos = targetHrp.Position + Vector3.new(0, HOVER_HEIGHT + 15, -ORBIT_RADIUS - 10)
                end
                
                hrp.CFrame = CFrame.lookAt(bestPos, targetHrp.Position)
            else
                timerLabel.Text = "Status: Searching..."
                if tick() - lastFoundMonsterTime > 1.5 then
                    tryStartGame()
                end
            end
        end)
    end)

    -- ลูปกดสกิลและโจมตีปกติ
    task.spawn(function()
        while getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID do
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local targetHrp = getTarget()
                    if targetHrp then
                        if tick() - lastSkillTime > 0.15 then
                            local items = {}
                            if LocalPlayer:FindFirstChild("Backpack") then
                                for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, v) end
                            end
                            for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end
                            
                            for _, item in ipairs(items) do
                                if item:IsA("Tool") then
                                    local slot = item:FindFirstChild("abilitySlot")
                                    local cd = item:FindFirstChild("cooldown")
                                    if slot and cd and slot:IsA("ValueBase") and cd:IsA("ValueBase") then
                                        if cd.Value <= 0.1 then
                                            pressKey(tostring(slot.Value))
                                            lastSkillTime = tick()
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        
                        local equippedTool = char:FindFirstChildOfClass("Tool")
                        if equippedTool then
                            equippedTool:Activate()
                        end
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

task.spawn(function()
    while true do
        if getgenv().AutoCreateAndStart then
            if game.PlaceId == TARGET_PLACE_ID then
                pcall(function()
                    timerLabel.Text = "Waiting for remotes..."
                    local remotes = ReplicatedStorage:WaitForChild("remotes", 10)
                    if not remotes then return end

                    local createLobbyRemote = remotes:FindFirstChild("createLobby")
                    local startDungeonRemote = remotes:FindFirstChild("startDungeon")

                    if createLobbyRemote then
                        timerLabel.Text = "Creating Lobby..."
                        local args = { selectedMap, selectedDifficulty, 0, false, false, false }
                        createLobbyRemote:InvokeServer(unpack(args))
                        task.wait(1.5)
                    end

                    if startDungeonRemote then
                        for i = 5, 1, -1 do
                            if not getgenv().AutoCreateAndStart or game.PlaceId ~= TARGET_PLACE_ID then break end
                            timerLabel.Text = "Starting in: " .. i .. "s"
                            task.wait(1)
                        end
                        
                        if getgenv().AutoCreateAndStart and game.PlaceId == TARGET_PLACE_ID then
                            timerLabel.Text = "Starting Game..."
                            startDungeonRemote:FireServer()
                            task.wait(3)
                        end
                    end
                end)
            else
                timerLabel.Text = "In Dungeon"
                if not getgenv().DungeonFarmLoop then
                    task.defer(startFarm)
                end
            end
        else
            timerLabel.Text = "Status: OFF"
        end
        task.wait(2)
    end
end)

if getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(startFarm)
end

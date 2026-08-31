local TARGET_PLACE_ID = 77649408247578

local selectedMap = "The Underworld"
local selectedDifficulty = "Insane"

-- ตั้งค่าให้เปิดทั้งฟาร์มและออโต้สร้างห้องตั้งแต่เริ่มรันสคริปต์
getgenv().AutoCreateAndStart = true
getgenv().AutoFarmEnabled = true
getgenv().DungeonFarmLoop = nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ==================== สร้าง GUI (มุมขวาบน) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonFarmGui"
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
titleLabel.Text = "Dungeon Auto Farm"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
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

-- ระบบลาก GUI
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

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

-- ==================== ระบบหลักของสคริปต์ ====================

task.spawn(function()
    pcall(function()
        local errorPrompt = CoreGui:FindFirstChild("RobloxPromptGui", true)
        if errorPrompt then
            errorPrompt.DescendantAdded:Connect(function(subChild)
                if subChild.Name == "ErrorTitle" then
                    task.wait(2)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
        end
    end)
    
    while true do
        task.wait(5)
        pcall(function()
            if not LocalPlayer or not LocalPlayer.Parent then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
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

    local currentTargetModel = nil
    local lastFoundMonsterTime = tick()
    local initialTargetHealth = nil
    local hasDealtDamage = false

    local function getTarget()
        if currentTargetModel and currentTargetModel.Parent then
            local hum = currentTargetModel:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = currentTargetModel:FindFirstChild("HumanoidRootPart")
                if hrp then
                    lastFoundMonsterTime = tick()
                    return hrp, hum, currentTargetModel
                end
            end
        end

        currentTargetModel = nil
        initialTargetHealth = nil
        hasDealtDamage = false
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local modelName = obj.Name
                if modelName:find("_reyillsPreview") or modelName:find("Preview") then
                    continue
                end

                local hum = obj:FindFirstChild("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")

                if hum and hrp and hum.Health > 0 then
                    if obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") then
                        currentTargetModel = obj
                        initialTargetHealth = hum.Health
                        hasDealtDamage = false
                        hrp.Size = Vector3.new(65, 65, 65)
                        hrp.Transparency = 0.8
                        hrp.CanCollide = false
                        lastFoundMonsterTime = tick()
                        return hrp, hum, obj
                    end
                end
            end
        end
        return nil, nil, nil
    end

    local function areSkillsReady()
        local readyCount = 0
        local totalSkills = 0
        
        local items = {}
        if LocalPlayer:FindFirstChild("Backpack") then
            for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, v) end
        end
        if LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetChildren()) do table.insert(items, v) end
        end

        for _, item in ipairs(items) do
            if item:IsA("Tool") then
                local slot = item:FindFirstChild("abilitySlot")
                local cd = item:FindFirstChild("cooldown")
                if slot and cd and slot:IsA("ValueBase") and cd:IsA("ValueBase") then
                    totalSkills = totalSkills + 1
                    if cd.Value <= 0.1 then
                        readyCount = readyCount + 1
                    end
                end
            end
        end

        if totalSkills > 0 and readyCount >= math.min(2, totalSkills) then
            return true, items
        end
        return false, items
    end

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
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

            local targetHrp, targetHum, targetModel = getTarget()
            if targetHrp and targetHum then
                if initialTargetHealth and targetHum.Health < initialTargetHealth then
                    hasDealtDamage = true
                end

                local skillsReady, items = areSkillsReady()
                
                local safeHeight = 50 
                local diveHeight = 15 -- ลดความสูงตอนลงมาอีกนิดเผื่อบอสนอนติดพื้น
                
                -- เช็คว่าบอสตายหรือล้มหน้าคว่ำอยู่ไหม (เช็คจากความเอียงหรือตำแหน่งแกน Y ของหัวกับลำตัว)
                local isBossDown = false
                local head = targetModel:FindFirstChild("Head")
                if head and head.Position.Y < targetHrp.Position.Y - 2 then
                    isBossDown = true
                end

                local currentHeight = safeHeight
                if (skillsReady or workspace:FindFirstChild("bossShot") or isBossDown) and not hasDealtDamage then
                    currentHeight = diveHeight
                else
                    if hasDealtDamage and skillsReady == false then
                        hasDealtDamage = false
                    end
                end

                local timeNow = tick()
                local radius = 16 
                local speed = 3   
                local angle = timeNow * speed
                
                local offsetX = math.cos(angle) * radius
                local offsetZ = math.sin(angle) * radius
                
                local targetPos = targetHrp.Position
                local orbitPos = targetPos + Vector3.new(offsetX, currentHeight, offsetZ)
                
                hrp.CFrame = CFrame.lookAt(orbitPos, targetPos)

                if currentHeight == diveHeight and skillsReady then
                    for _, item in ipairs(items) do
                        if item:IsA("Tool") then
                            local slot = item:FindFirstChild("abilitySlot")
                            local cd = item:FindFirstChild("cooldown")
                            if slot and cd and slot:IsA("ValueBase") and cd:IsA("ValueBase") then
                                if cd.Value <= 0.1 then
                                    pressKey(tostring(slot.Value))
                                    task.wait(0.02)
                                end
                            end
                        end
                    end
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    if equippedTool then
                        equippedTool:Activate()
                    end
                end
            else
                hasDealtDamage = false
                initialTargetHealth = nil
                if tick() - lastFoundMonsterTime > 1.5 then
                    tryStartGame()
                end
            end
        end)
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
                        local args = {
                            selectedMap,
                            selectedDifficulty,
                            0,
                            false,
                            false,
                            false
                        }
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
                timerLabel.Text = "In Dungeon / Farming"
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

-- โค้ดนี้ถูกอัปเดตเพื่อแก้ปัญหาบอสนอนล้มแล้วตีไม่โดน
if getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(startFarm)
end

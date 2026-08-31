local TARGET_PLACE_ID = 77649408247578

local selectedMap = "King's Castle"
local selectedDifficulty = "Nightmare"

-- ตั้งค่าฮิตบ็อกซ์
local HITBOX_RADIUS = 150 -- ระยะขยายฮิตบ็อกซ์รอบตัวผู้เล่น (Studs)
local HITBOX_SIZE = Vector3.new(20, 20, 20) -- ขนาดฮิตบ็อกซ์ที่เหมาะสม

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
    local attackAttemptTime = nil
    local isDiving = false
    local ignoredMonsters = {}

    -- ระดับความสูงช่วงรอคูลดาวน์
    local hoverHeights = {50, 60, 70}
    local heightIndex = 1
    local lastHeightChange = tick()
    local currentDynamicHeight = hoverHeights[1]

    local function isIgnored(model)
        if ignoredMonsters[model] then
            if tick() < ignoredMonsters[model] then
                return true
            else
                ignoredMonsters[model] = nil
            end
        end
        return false
    end

    local function expandNearbyHitboxes(playerHrp)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) and not isIgnored(obj) then
                local modelName = obj.Name
                if not (modelName:find("_reyillsPreview") or modelName:find("Preview")) then
                    local hum = obj:FindFirstChild("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")

                    if hum and hrp and hum.Health > 0 then
                        local distance = (hrp.Position - playerHrp.Position).Magnitude
                        if distance <= HITBOX_RADIUS then
                            hrp.Size = HITBOX_SIZE
                            hrp.Transparency = 0.8
                            hrp.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    local function getTarget()
        if currentTargetModel and currentTargetModel.Parent and not isIgnored(currentTargetModel) then
            local hum = currentTargetModel:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = currentTargetModel:FindFirstChild("HumanoidRootPart")
                if hrp then
                    lastFoundMonsterTime = tick()
                    return hrp, hum
                end
            end
        end

        currentTargetModel = nil
        initialTargetHealth = nil
        attackAttemptTime = nil
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) and not isIgnored(obj) then
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
                        attackAttemptTime = nil
                        lastFoundMonsterTime = tick()
                        return hrp, hum
                    end
                end
            end
        end
        return nil, nil
    end

    local function checkSkillsReady()
        local readyTools = {}
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
                    if cd.Value <= 0 then
                        table.insert(readyTools, item)
                    end
                end
            end
        end

        local requiredCount = math.min(2, totalSkills)
        if totalSkills > 0 and #readyTools >= requiredCount then
            return true, readyTools
        end
        return false, {}
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

            expandNearbyHitboxes(hrp)

            local targetHrp, targetHum = getTarget()
            if targetHrp and targetHum then
                local isReady, readyTools = checkSkillsReady()

                if isReady and not isDiving then
                    isDiving = true
                    attackAttemptTime = tick()
                    initialTargetHealth = targetHum.Health

                    task.spawn(function()
                        -- STEP 1: ดิ่งลงมาที่ความสูง 20
                        currentDynamicHeight = 20
                        task.wait(0.12)
                        
                        -- วนลูปปล่อยทีละสกิล โดยกดย้ำซ้ำๆ จนกว่าสกิลนั้นจะเริ่มนับคูลดาวน์จริง (> 0)
                        for _, item in ipairs(readyTools) do
                            local slot = item:FindFirstChild("abilitySlot")
                            local cd = item:FindFirstChild("cooldown")

                            if slot and slot:IsA("ValueBase") then
                                local keyName = tostring(slot.Value)
                                local startWait = tick()

                                repeat
                                    pressKey(keyName)
                                    task.wait(0.08)
                                until (cd and cd:IsA("ValueBase") and cd.Value > 0) or (tick() - startWait) > 1.2
                            end
                        end
                        
                        local currentChar = LocalPlayer.Character
                        if currentChar then
                            local equippedTool = currentChar:FindFirstChildOfClass("Tool")
                            if equippedTool then
                                equippedTool:Activate()
                            end
                        end

                        -- ค้างต่ออีกเล็กน้อยให้กระสุน/เอฟเฟกต์พุ่งออกจากตัวจนสุด
                        task.wait(0.2)

                        -- STEP 2: ค่อยๆ ถอยขึ้นไปความสูง 30
                        currentDynamicHeight = 30
                        task.wait(0.2)

                        -- STEP 3: จบการดิ่ง กลับขึ้นไปลอยนิ่งรอคูลดาวน์รอบถัดไป
                        isDiving = false
                    end)
                end

                local targetPos = targetHrp.Position
                local orbitPos

                if isDiving then
                    -- ขณะดิ่งปล่อยสกิล: หมุนควงรอบตัวมอนสเตอร์
                    local timeNow = tick()
                    local radius = 20 
                    local speed = 5   
                    local angle = timeNow * speed
                    
                    local offsetX = math.cos(angle) * radius
                    local offsetZ = math.sin(angle) * radius
                    orbitPos = targetPos + Vector3.new(offsetX, currentDynamicHeight, offsetZ)
                else
                    -- ขณะรอคูลดาวน์: ลอยนิ่ง และสลับความสูง 50, 60, 70 ทุก 1 วินาที
                    if tick() - lastHeightChange >= 1 then
                        heightIndex = (heightIndex % #hoverHeights) + 1
                        currentDynamicHeight = hoverHeights[heightIndex]
                        lastHeightChange = tick()
                    end

                    orbitPos = targetPos + Vector3.new(0, currentDynamicHeight, 0)
                end

                hrp.CFrame = CFrame.lookAt(orbitPos, targetPos)

                -- เช็คถ้าระบบไม่ทำดาเมจหลังเริ่มโจมตี 2.5 วินาที ให้เปลี่ยนเป้าหมาย
                if attackAttemptTime and (tick() - attackAttemptTime > 2.5) then
                    if initialTargetHealth and targetHum.Health >= initialTargetHealth then
                        ignoredMonsters[currentTargetModel] = tick() + 15
                        currentTargetModel = nil
                        attackAttemptTime = nil
                        isDiving = false
                    else
                        attackAttemptTime = nil
                    end
                end

            else
                isDiving = false
                initialTargetHealth = nil
                attackAttemptTime = nil
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

if getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(startFarm)
end

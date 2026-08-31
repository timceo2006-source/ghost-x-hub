local TARGET_PLACE_ID = 77649408247578

local selectedMap = "The Underworld"
local selectedDifficulty = "Insane"

-- ตั้งค่าเพิ่มเติม
local USE_NORMAL_ATTACK = true -- true = ใช้ตีธรรมดาด้วย, false = ใช้เฉพาะสกิล
local AUTO_DODGE_ENABLED = true -- เปิด/ปิด ระบบออโต้หลบอัจฉริยะ

-- ตั้งค่าเงื่อนไขพิเศษสำหรับบอส (ปรับความสูงลงมาเหลือ 35 เพื่อให้ปล่อยสกิลโดนง่ายขึ้น)
local BOSS_CONFIGURATIONS = {
    ["Demon Lord Azrallik"] = {
        customHoverHeight = 35, -- ลดความสูงลงมาให้อยู่ในระยะปล่อยสกิลโดน
        skipNormalAttack = false
    }
}

-- ตั้งค่าฮิตบ็อกซ์
local HITBOX_RADIUS = 150
local HITBOX_SIZE = Vector3.new(20, 20, 20)

-- ตั้งค่าเปิดใช้งานระบบ
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

-- ==================== GUI (มุมขวาบน) ====================
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
titleLabel.Text = "Dungeon Auto Farm & Dodge"
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

    -- ฟังก์ชันดึงพาร์ทหลักของมอนสเตอร์ รองรับทุกชื่อ
    local function getMonsterRootPart(obj)
        local hrp = obj:FindFirstChild("HumanoidRootPart") 
            or obj:FindFirstChild("Torso") 
            or obj:FindFirstChild("UpperTorso") 
            or obj.PrimaryPart
            
        if not hrp then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BasePart") then
                    hrp = child
                    break
                end
            end
        end
        return hrp
    end

    local function expandNearbyHitboxes(playerHrp)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local modelName = obj.Name
                if not (modelName:find("_reyillsPreview") or modelName:find("Preview")) then
                    local hum = obj:FindFirstChild("Humanoid")
                    local hrp = getMonsterRootPart(obj)

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
        if currentTargetModel and currentTargetModel.Parent then
            local hum = currentTargetModel:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = getMonsterRootPart(currentTargetModel)
                if hrp then
                    lastFoundMonsterTime = tick()
                    return hrp, hum
                end
            end
        end

        currentTargetModel = nil
        
        local heartTarget, heartHrp, heartHum = nil, nil, nil
        local minionTarget, minionHrp, minionHum = nil, nil, nil
        local generalTarget, generalHrp, generalHum = nil, nil, nil

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local modelName = obj.Name
                if modelName:find("_reyillsPreview") or modelName:find("Preview") then
                    continue
                end

                local hum = obj:FindFirstChild("Humanoid")
                local hrp = getMonsterRootPart(obj)

                if hum and hrp and hum.Health > 0 then
                    if modelName:find("Heart") then
                        heartTarget, heartHrp, heartHum = obj, hrp, hum
                    elseif modelName:find("Minion") then
                        minionTarget, minionHrp, minionHum = obj, hrp, hum
                    else
                        if not generalTarget then
                            generalTarget, generalHrp, generalHum = obj, hrp, hum
                        end
                    end
                end
            end
        end

        local chosenTarget, chosenHrp, chosenHum = nil, nil, nil

        if heartTarget and heartHrp and heartHum then
            chosenTarget, chosenHrp, chosenHum = heartTarget, heartHrp, heartHum
        elseif minionTarget and minionHrp and minionHum then
            chosenTarget, chosenHrp, chosenHum = minionTarget, minionHrp, minionHum
        elseif generalTarget and generalHrp and generalHum then
            chosenTarget, chosenHrp, chosenHum = generalTarget, generalHrp, generalHum
        end

        if chosenTarget and chosenHrp and chosenHum then
            currentTargetModel = chosenTarget
            lastFoundMonsterTime = tick()
            return chosenHrp, chosenHum
        end

        return nil, nil
    end

    -- ฟังก์ชันตรวจสอบและกดใช้สกิลทั้งหมดที่พร้อมใช้งานแบบง่าย
    local function executeSkillsAndAttacks(bossConfig)
        local items = {}
        if LocalPlayer:FindFirstChild("Backpack") then
            for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, v) end
        end
        if LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetChildren()) do table.insert(items, v) end
        end

        -- กดใช้สกิลที่คูลดาวน์หมดแล้ว
        for _, item in ipairs(items) do
            if item:IsA("Tool") then
                local slot = item:FindFirstChild("abilitySlot")
                local cd = item:FindFirstChild("cooldown")
                if slot and cd and slot:IsA("ValueBase") and cd:IsA("ValueBase") then
                    if cd.Value <= 0.1 then
                        pressKey(tostring(slot.Value))
                        task.wait(0.04)
                    end
                end
            end
        end

        -- ตีธรรมดา (ถ้าเปิดใช้งาน)
        local shouldAttackNormal = USE_NORMAL_ATTACK
        if bossConfig and bossConfig.skipNormalAttack ~= nil then
            shouldAttackNormal = not bossConfig.skipNormalAttack
        end

        if shouldAttackNormal and LocalPlayer.Character then
            local equippedTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if equippedTool then
                equippedTool:Activate()
            end
        end
    end

    -- ฟังก์ชันคำนวณการหลบอัจฉริยะ (Auto Dodge แบบ 100% ครอบคลุมเลเซอร์และวงเตือนภัย)
    local function getDodgeOffset(playerHrp)
        if not AUTO_DODGE_ENABLED then return Vector3.new(0, 0, 0) end

        local dodgeShift = Vector3.new(0, 0, 0)
        local dangerDetected = false

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local isRedColor = obj.Color.R > 0.7 and obj.Color.G < 0.3 and obj.Color.B < 0.3
                local isWarningName = (obj.Name:lower():find("warning") or obj.Name:lower():find("indicator") or obj.Name:lower():find("danger") or obj.Name:lower():find("laser") or obj.Name:lower():find("zone"))

                if isRedColor or isWarningName then
                    local dist = (obj.Position - playerHrp.Position).Magnitude
                    if dist <= 30 then
                        dangerDetected = true
                        local escapeDir = (playerHrp.Position - obj.Position)
                        escapeDir = Vector3.new(escapeDir.X, 0, escapeDir.Z).Unit
                        if escapeDir.Magnitude == 0 then escapeDir = Vector3.new(1, 0, 0) end
                        
                        -- เมื่อหลบจะพุ่งออกด้านข้างและลอยขึ้นสูง 35 หน่วยเพื่อความปลอดภัย
                        dodgeShift = (escapeDir * 12) + Vector3.new(0, 35, 0)
                        break
                    end
                end
            end
        end

        return dangerDetected, dodgeShift
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
                local bossConfig = nil
                if currentTargetModel and BOSS_CONFIGURATIONS[currentTargetModel.Name] then
                    bossConfig = BOSS_CONFIGURATIONS[currentTargetModel.Name]
                end

                local isDanger, dodgeShift = getDodgeOffset(hrp)
                local targetPos = targetHrp.Position
                local safePos

                if isDanger then
                    safePos = targetPos + dodgeShift
                else
                    -- ปรับความสูงปกติลดลงเหลือ 25 (หรือตามค่า config) เพื่อให้ปล่อยสกิลโจมตีโดนเป้าหมายชัวร์ๆ
                    local hoverHeight = bossConfig and bossConfig.customHoverHeight or 25
                    safePos = targetPos + Vector3.new(0, hoverHeight, 0)
                end

                hrp.CFrame = CFrame.lookAt(safePos, targetPos)
                executeSkillsAndAttacks(bossConfig)

            else
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

local TARGET_PLACE_ID = 77649408247578

local selectedMap = "King's Castle"
local selectedDifficulty = "Nightmare"

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
screenGui.Name = "CleanDungeonGui"
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
titleLabel.Text = "Clean Auto Farm (Y-Level)"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = mainFrame

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
        statusLabel.Text = "Status: Ready"
        if game.PlaceId ~= TARGET_PLACE_ID then
            task.defer(startFarm)
        end
    else
        toggleButton.Text = "Status: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(205, 50, 50)
        statusLabel.Text = "Paused"
        stopFarm()
    end
end)

-- ==================== ระบบฟังก์ชันหลัก ====================

local function pressKey(keyStr)
    local success, keyCode = pcall(function() return Enum.KeyCode[keyStr:upper()] end)
    if success and keyCode then
        task.spawn(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.04)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
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

    local currentTarget = nil
    local lastMonsterTime = tick()
    local farmState = "UP_50" -- สถานะเริ่มต้น: ขึ้นไปรอที่ Y: 50

    -- ค้นหามอนสเตอร์ที่ยังมีชีวิต
    local function getTarget()
        if currentTarget and currentTarget.Parent then
            local hum = currentTarget:FindFirstChild("Humanoid")
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                lastMonsterTime = tick()
                return hrp, hum
            end
        end

        currentTarget = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                if not obj.Name:find("Preview") then
                    local hum = obj:FindFirstChild("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        currentTarget = obj
                        lastMonsterTime = tick()
                        return hrp, hum
                    end
                end
            end
        end
        return nil, nil
    end

    -- เช็กสถานะคูลดาวน์สกิล Q
    local function isSkillReady()
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
                if slot and tostring(slot.Value):upper() == "Q" then
                    local cd = item:FindFirstChild("cooldown")
                    if cd and cd.Value <= 0.1 then
                        return true
                    end
                end
            end
        end
        return false
    end

    getgenv().DungeonFarmLoop = RunService.Heartbeat:Connect(function()
        if not getgenv().AutoFarmEnabled or game.PlaceId == TARGET_PLACE_ID then return end

        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            if not hrp or not humanoid then return end

            local targetHrp, targetHum = getTarget()
            if targetHrp and targetHum then
                local currentY = hrp.Position.Y

                -- สเต็ปที่ 1: ขึ้นไปรอความสูง Y = 50 เพื่อซ่อนตัว/ปิดการตรวจจับจาก Anti-Cheat
                if farmState == "UP_50" then
                    local safePos = Vector3.new(targetHrp.Position.X, targetHrp.Position.Y + 50, targetHrp.Position.Z)
                    hrp.CFrame = CFrame.lookAt(safePos, targetHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                    -- ถ้าสกิลพร้อม ให้เริ่มสเต็ปทิ้งตัวลงมา
                    if isSkillReady() then
                        farmState = "DOWN_30"
                    end

                -- สเต็ปที่ 2: ลงมาที่ความสูง Y = 30 เพื่อเตรียมหามอนและปล่อยสกิลลงด้านล่าง
                elseif farmState == "DOWN_30" then
                    local dropPos = Vector3.new(targetHrp.Position.X, targetHrp.Position.Y + 30, targetHrp.Position.Z)
                    hrp.CFrame = CFrame.lookAt(dropPos, targetHrp.Position)

                    -- ปล่อยสกิล Q ลงด้านล่าง
                    if isSkillReady() then
                        pressKey("Q")
                        task.wait(0.05)
                    end

                    -- โจมตีปกติเสริม
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    if equippedTool then
                        equippedTool:Activate()
                    end

                    -- ถ้าตัวละครตกลงมาถึงระดับความสูง Y <= 15 ให้เปลี่ยนสถานะเพื่อวาปกลับขึ้นไป
                    if currentY <= 15 then
                        farmState = "RESET_BACK"
                    end

                -- สเต็ปที่ 3: เมื่อถึง Y = 15 ให้วาปเด้งกลับขึ้นไปรอ Y = 50 เพื่อคูลดาวน์
                elseif farmState == "RESET_BACK" then
                    local resetPos = Vector3.new(targetHrp.Position.X, targetHrp.Position.Y + 50, targetHrp.Position.Z)
                    hrp.CFrame = CFrame.lookAt(resetPos, targetHrp.Position)
                    task.wait(0.1)
                    farmState = "UP_50"
                end
            else
                -- ถ้าหามอนไม่เจอ ให้รีเซ็ตกลับไปตั้งหลักที่ Y = 50
                farmState = "UP_50"
                if tick() - lastMonsterTime > 1.5 then
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("remotes")
                        if remotes and remotes:FindFirstChild("changeStartValue") then
                            remotes.changeStartValue:FireServer()
                        end
                    end)
                end
            end
        end)
    end)
end

-- ==================== ระบบเข้าด่าน / สร้างห้อง ====================
task.spawn(function()
    while true do
        if getgenv().AutoCreateAndStart then
            if game.PlaceId == TARGET_PLACE_ID then
                pcall(function()
                    statusLabel.Text = "Waiting for remotes..."
                    local remotes = ReplicatedStorage:WaitForChild("remotes", 10)
                    if not remotes then return end

                    local createLobbyRemote = remotes:FindFirstChild("createLobby")
                    local startDungeonRemote = remotes:FindFirstChild("startDungeon")

                    if createLobbyRemote then
                        statusLabel.Text = "Creating Lobby..."
                        createLobbyRemote:InvokeServer(selectedMap, selectedDifficulty, 0, false, false, false)
                        task.wait(1.5)
                    end

                    if startDungeonRemote then
                        for i = 5, 1, -1 do
                            if not getgenv().AutoCreateAndStart or game.PlaceId ~= TARGET_PLACE_ID then break end
                            statusLabel.Text = "Starting in: " .. i .. "s"
                            task.wait(1)
                        end
                        
                        if getgenv().AutoCreateAndStart and game.PlaceId == TARGET_PLACE_ID then
                            statusLabel.Text = "Starting Game..."
                            startDungeonRemote:FireServer()
                            task.wait(3)
                        end
                    end
                end)
            else
                statusLabel.Text = "In Dungeon / Farming"
                
                local checkTimer = tick()
                while game.PlaceId ~= TARGET_PLACE_ID and getgenv().AutoCreateAndStart do
                    local _, hum = (function()
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model" ) and obj ~= LocalPlayer.Character then
                                local h = obj:FindFirstChild("Humanoid")
                                if h and h.Health > 0 and not obj.Name:find("Preview") then
                                    return obj:FindFirstChild("HumanoidRootPart"), h
                                end
                            end
                        end
                        return nil, nil
                    end)()

                    if hum then break end
                    if tick() - checkTimer >= 5 then
                        statusLabel.Text = "Waiting for monsters..."
                        break
                    end
                    task.wait(0.5)
                end

                if not getgenv().DungeonFarmLoop then
                    task.defer(startFarm)
                end
            end
        else
            statusLabel.Text = "Status: OFF"
        end
        task.wait(2)
    end
end)

if getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(startFarm)
end

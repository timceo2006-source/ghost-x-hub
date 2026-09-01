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
local TweenService = game:GetService("TweenService")
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
titleLabel.Text = "Clean Auto Farm"
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
toggleButton.Position = UDim2.,new(0.05, 0, 0.52, 0) -- Fixed comma syntax issue below properly
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

-- ==================== ฟังก์ชันควบคุมคีย์บอร์ด ====================
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

-- ==================== เช็กคูลดาวน์สกิล Q และ E ====================
local function getSkillCooldownStatus()
    local items = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, v) end
    end
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetChildren()) do table.insert(items, v) end
    end

    local qReady, eReady = false, false

    for _, item in ipairs(items) do
        if item:IsA("Tool") then
            local slot = item:FindFirstChild("abilitySlot")
            local cd = item:FindFirstChild("cooldown")
            if slot and cd then
                local slotVal = tostring(slot.Value):upper()
                if slotVal == "Q" and cd.Value <= 0.1 then
                    qReady = true
                elseif slotVal == "E" and cd.Value <= 0.1 then
                    eReady = true
                end
            end
        end
    end
    return qReady, eReady
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

    -- ค้นหามอนสเตอร์ที่ยังมีชีวิต
    local function getTarget()
        if currentTarget and currentTarget.Parent then
            local hum = currentTarget:FindFirstChild("Humanoid")
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
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
                        return hrp, hum
                    end
                end
            end
        end
        return nil, nil
    end

    -- ฟังก์ชัน Tween ตัวละครไปยังตำแหน่งที่ต้องการแบบนุ่มนวลหลบ Anti-Cheat
    local function smoothTweenTo(targetCFrame, speed)
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        speed = speed or 16
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local duration = distance / speed
        if duration < 0.05 then duration = 0.05 end

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        
        local completed = false
        local conn
        conn = tween.Completed:Connect(function()
            completed = true
            if conn then conn:Disconnect() end
        end)

        -- รอจนกว่าจะ Tween เสร็จหรือเป้าหมายเปลี่ยน
        local startTime = tick()
        while not completed and tick() - startTime < (duration + 1) do
            task.wait(0.05)
        end
    end

    -- ลูปหลักในการฟาร์มตามระบบใหม่
    getgenv().DungeonFarmLoop = task.spawn(function()
        while getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID do
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then 
                    task.wait(0.5)
                    return 
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then 
                    task.wait(0.5)
                    return 
                end

                local targetHrp, targetHum = getTarget()
                if targetHrp and targetHum then
                    statusLabel.Text = "Triggering Monster Movement..."
                    
                    -- 1. วนรอบตัวมอนสเตอร์เป็นมุมสี่เหลี่ยม (หน้า 10, ข้าง 5) เพื่อกระตุ้นระบบฟิสิกส์และการเคลื่อนที่ของมอน
                    local offsets = {
                        targetHrp.CFrame * CFrame.new(0, 0, -10), -- ด้านหน้า
                        targetHrp.CFrame * CFrame.new(5, 0, 0),   -- ด้านขวา
                        targetHrp.CFrame * CFrame.new(-5, 0, 0),  -- ด้านซ้าย
                    }

                    for _, posCFrame in ipairs(offsets) do
                        if not targetHrp or not targetHrp.Parent then break end
                        smoothTweenTo(posCFrame, 20)
                        task.wait(0.2)
                    end

                    -- เช็กให้แน่ใจว่ามอนสเตอร์เคลื่อนที่หรือมีการขยับตัวแล้ว
                    statusLabel.Text = "Waiting for Monster Move..."
                    local oldPos = targetHrp.Position
                    task.wait(0.3)
                    
                    -- 2. เมื่อมอนขยับ/พร้อมแล้ว วาร์ปขึ้นไปบนหัวมอนสเตอร์ (0, 25, 0)
                    statusLabel.Text = "Attacking from Above..."
                    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 25, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                    -- 3. ลูปเช็กคูลดาวน์และปล่อยสกิล Q และ E
                    local attackTimeout = tick()
                    while targetHum and targetHum.Health > 0 and getgenv().AutoFarmEnabled do
                        local qReady, eReady = getSkillCooldownStatus()

                        if qReady or eReady then
                            if qReady then
                                pressKey("Q")
                                task.wait(0.1)
                            end
                            if eReady then
                                pressKey("E")
                                task.wait(0.1)
                            end
                        else
                            -- ถ้าสกิลติดคูลดาวน์ ให้สลับขึ้นไปรอพักคูลดาวน์ที่ความสูงสลับกัน (50, 80, 130)
                            local heights = {50, 80, 130}
                            for _, h in ipairs(heights) do
                                if targetHrp and targetHrp.Parent then
                                    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, h, 0)
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                                
                                -- เช็กคูลดาวน์ระหว่างรอ
                                local waitStart = tick()
                                while tick() - waitStart < 1.5 do
                                    local qCheck, eCheck = getSkillCooldownStatus()
                                    if qCheck or eCheck then break end
                                    task.wait(0.2)
                                end

                                -- เช็กว่าสกิลพร้อมหรือยัง ถ้าพร้อมให้ลงไปปล่อยสกิลที่ (0, 25, 0)
                                local qCheck, eCheck = getSkillCooldownStatus()
                                if qCheck or eCheck then
                                    if targetHrp and targetHrp.Parent then
                                        hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 25, 0)
                                    end
                                    break
                                end
                            end
                        end

                        -- ป้องกันลูปค้างหากมอนตายหรือเลือดหมด
                        if targetHum.Health <= 0 or not targetHrp.Parent then
                            break
                        end

                        task.wait(0.1)
                    end
                else
                    statusLabel.Text = "Searching for Monsters..."
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("remotes")
                        if remotes and remotes:FindFirstChild("changeStartValue") then
                            remotes.changeStartValue:FireServer()
                        end
                    end)
                    task.wait(1)
                end
            end)
            task.wait(0.2)
        end
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
                if not getgenv().DungeonFarmLoop or coroutine.status(getgenv().DungeonFarmLoop) == "dead" then
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

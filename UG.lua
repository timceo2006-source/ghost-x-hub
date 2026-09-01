-- รอให้เกมโหลดเสร็จก่อน
if not game:IsLoaded() then
    game.Loaded:Wait()
end

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
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ==================== ลบ GUI เก่าออกถ้ารันซ้ำ ====================
if getgenv().CleanDungeonGui then
    pcall(function() getgenv().CleanDungeonGui:Destroy() end)
end

-- ==================== GUI (มุมขวาบน) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CleanDungeonGui"
screenGui.ResetOnSpawn = false
getgenv().CleanDungeonGui = screenGui

local successUI, uiParent = pcall(function() return gethui() end)
if successUI and uiParent then
    screenGui.Parent = uiParent
else
    local CoreGui = game:GetService("CoreGui")
    local successCore = pcall(function() screenGui.Parent = CoreGui end)
    if not successCore then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 115)
mainFrame.Position = UDim2.new(0.68, 0, 0.08, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
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
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
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
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.04)
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            end)
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
    getgenv().AutoFarmEnabled = false
    if getgenv().DungeonFarmLoop then
        task.cancel(getgenv().DungeonFarmLoop)
        getgenv().DungeonFarmLoop = nil
    end
end

function startFarm()
    if game.PlaceId == TARGET_PLACE_ID then return end
    stopFarm()
    getgenv().AutoFarmEnabled = true

    local currentTarget = nil

    -- ค้นหามอนสเตอร์
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
                if not string.find(obj.Name, "Preview") then
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

    -- ลูปหลักในการฟาร์ม
    getgenv().DungeonFarmLoop = task.spawn(function()
        local FLY_HEIGHT = 20    -- ความสูงลอยฟ้าเหนือมอนสเตอร์ (20 หน่วย)
        local CIRCLE_RADIUS = 12 -- รัศมีวงกลมขณะวน

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
                    statusLabel.Text = "Circling Above Monster..."
                    
                    local angle = 0
                    local startTime = tick()
                    
                    -- หมุนวนวาร์ปเป็นวงกลมบนหัวมอนสูง 20 หน่วย จนกว่ามอนสเตอร์จะเดินขยับตัว
                    while getgenv().AutoFarmEnabled and targetHrp and targetHrp.Parent and targetHum and targetHum.Health > 0 do
                        -- ตรวจสอบว่ามอนสเตอร์เคลื่อนที่แล้วหรือยัง
                        local isMoving = targetHrp.AssemblyLinearVelocity.Magnitude > 0.5 or targetHum.MoveVelocity.Magnitude > 0.5
                        if isMoving or (tick() - startTime > 2.5) then
                            break
                        end

                        -- คำนวณพิกัดวงกลมแบบเรียลไทม์
                        angle = angle + math.rad(36)
                        local offset = Vector3.new(math.cos(angle) * CIRCLE_RADIUS, FLY_HEIGHT, math.sin(angle) * CIRCLE_RADIUS)
                        
                        -- วาร์ปแบบทันทีลอยสูง +20 หน่วย
                        hrp.CFrame = CFrame.new(targetHrp.Position + offset, targetHrp.Position)
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        task.wait(0.02)
                    end

                    statusLabel.Text = "Attacking..."
                    -- วาร์ปไปตำแหน่งบนหัวมอนสูง 20 หน่วยเพื่อโจมตี
                    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, FLY_HEIGHT, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                    while targetHum and targetHum.Health > 0 and getgenv().AutoFarmEnabled do
                        local qReady, eReady = getSkillCooldownStatus()

                        if qReady or eReady then
                            -- อยู่สูง +20 ขณะปล่อยสกิล
                            hrp.CFrame = targetHrp.CFrame + Vector3.new(0, FLY_HEIGHT, 0)
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                            if qReady then pressKey("Q") task.wait(0.04) end
                            if eReady then pressKey("E") task.wait(0.04) end
                        else
                            -- สลับลอยขึ้นสูงพักคูลดาวน์ (สูงขึ้นเป็น 40, 60, 90 หน่วย)
                            local heights = {40, 60, 90}
                            for _, h in ipairs(heights) do
                                if targetHrp and targetHrp.Parent then
                                    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, h, 0)
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                                
                                local waitStart = tick()
                                while tick() - waitStart < 1.0 do
                                    local qCheck, eCheck = getSkillCooldownStatus()
                                    if qCheck or eCheck then break end
                                    task.wait(0.1)
                                end

                                local qCheck, eCheck = getSkillCooldownStatus()
                                if qCheck or eCheck then
                                    if targetHrp and targetHrp.Parent then
                                        hrp.CFrame = targetHrp.CFrame + Vector3.new(0, FLY_HEIGHT, 0)
                                    end
                                    break
                                end
                            end
                        end

                        if targetHum.Health <= 0 or not targetHrp.Parent then
                            break
                        end
                        task.wait(0.03)
                    end
                else
                    statusLabel.Text = "Searching for Monsters..."
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("remotes")
                        if remotes and remotes:FindFirstChild("changeStartValue") then
                            remotes.changeStartValue:FireServer()
                        end
                    end)
                    task.wait(0.5)
                end
            end)
            task.wait(0.03)
        end
    end)
end

-- ==================== ระบบเข้าด่าน / สร้างห้อง ====================
task.spawn(function()
    while true do
        if getgenv().AutoCreateAndStart then
            if game.PlaceId == TARGET_PLACE_ID then
                pcall(function()
                    statusLabel.Text = "Waiting for lobby..."
                    local remotes = ReplicatedStorage:WaitForChild("remotes", 5)
                    if not remotes then return end

                    local createLobbyRemote = remotes:FindFirstChild("createLobby")
                    local startDungeonRemote = remotes:FindFirstChild("startDungeon")

                    if createLobbyRemote then
                        statusLabel.Text = "Creating Lobby..."
                        createLobbyRemote:InvokeServer(selectedMap, selectedDifficulty, 0, false, false, false)
                        task.wait(1.5)
                    end

                    if startDungeonRemote then
                        for i = 3, 1, -1 do
                            if not getgenv().AutoCreateAndStart or game.PlaceId ~= TARGET_PLACE_ID then break end
                            statusLabel.Text = "Starting in: " .. i .. "s"
                            task.wait(1)
                        end
                        
                        if getgenv().AutoCreateAndStart and game.PlaceId == TARGET_PLACE_ID then
                            statusLabel.Text = "Teleporting..."
                            startDungeonRemote:FireServer()
                            task.wait(4)
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
        task.wait(1.5)
    end
end)

if getgenv().AutoFarmEnabled and game.PlaceId ~= TARGET_PLACE_ID then
    task.defer(startFarm)
end

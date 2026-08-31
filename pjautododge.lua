local TARGET_PLACE_ID = 77649408247578

local selectedMap = "The Underworld"
local selectedDifficulty = "Insane"

local USE_NORMAL_ATTACK = true 
local HOVER_HEIGHT = 25

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
titleLabel.Text = "Smart Target & Heart Priority"
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

    -- ฟังก์ชันคัดเลือกเป้าหมายอัจฉริยะ: เช็คหาหัวใจก่อนเสมอ -> ถ้าไม่มีค่อยหาตัวที่ใกล้ที่สุด
    local function getTarget()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local dungeon = workspace:FindFirstChild("dungeon")
        if not dungeon then return nil end

        local bestHeart = nil
        local nearestEnemy = nil
        local shortestDistance = math.huge

        -- วนลูปทุกห้องใน dungeon เพื่อหาเป้าหมายทั้งหมด
        for _, room in ipairs(dungeon:GetChildren()) do
            if room:IsA("Folder") or room:IsA("Model") then
                for _, obj in ipairs(room:GetDescendants()) do
                    if obj:IsA("Model") and obj ~= char then
                        local hum = obj:FindFirstChild("Humanoid")
                        local targetHrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
                        
                        if hum and targetHrp and hum.Health > 0 then
                            if not Players:GetPlayerFromCharacter(obj) then
                                -- เช็คว่าเป็น "หัวใจบอส" หรือไม่ (มีคำว่า Heart ในชื่อ)
                                if string.find(string.lower(obj.Name), "heart") then
                                    bestHeart = targetHrp
                                else
                                    -- คำนวณหาระยะทางเพื่อหาตัวที่อยู่ใกล้ที่สุด
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

        -- ถ้าระบบเจอหัวใจบอส ให้สลับไปตีหัวใจทันทีเป็นอันดับแรกสุด
        if bestHeart then
            bestHeart.Size = Vector3.new(25, 25, 25)
            bestHeart.Transparency = 0.8
            bestHeart.CanCollide = false
            return bestHeart
        end

        -- ถ้าไม่มีหัวใจ ให้เลือกตัวที่อยู่ใกล้ที่สุด
        if nearestEnemy then
            nearestEnemy.Size = Vector3.new(25, 25, 25)
            nearestEnemy.Transparency = 0.8
            nearestEnemy.CanCollide = false
            return nearestEnemy
        end

        return nil
    end

    -- ลูปหลัก: ลอยตัวนิ่งๆ บนหัวเป้าหมายที่เลือก
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
            
            local targetHrp = getTarget()
            if targetHrp then
                lastFoundMonsterTime = tick()
                local safePos = targetHrp.Position + Vector3.new(0, HOVER_HEIGHT, 0)
                hrp.CFrame = CFrame.lookAt(safePos, targetHrp.Position)
            else
                if tick() - lastFoundMonsterTime > 1.5 then
                    tryStartGame()
                end
            end
        end)
    end)

    -- ลูปแยกสำหรับกดสกิลและโจมตีปกติ
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
                        
                        if USE_NORMAL_ATTACK then
                            local equippedTool = char:FindFirstChildOfClass("Tool")
                            if equippedTool then
                                equippedTool:Activate()
                            end
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

local TARGET_PLACE_ID = 77649408247578

getgenv().AutoFarmEnabled = false
getgenv().BossDetectorEnabled = false 
getgenv().DungeonFarmLoop = nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- สร้าง GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DungeonAutoFarmGUI"
ScreenGui.ResetOnSpawn = false

if CoreGui:FindFirstChild("DungeonAutoFarmGUI") then
    CoreGui.DungeonAutoFarmGUI:Destroy()
end

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 320, 0, 310)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Dungeon Auto Farm & Skill Detector"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.BorderSizePixel = 0
ToggleButton.Position = UDim2.new(0, 10, 0.5, -20)
ToggleButton.Size = UDim2.new(0, 70, 0, 30)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "UI: ON"
ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 0)
ToggleButton.TextSize = 14

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    ToggleButton.Text = MainFrame.Visible and "UI: ON" or "UI: OFF"
    ToggleButton.TextColor3 = MainFrame.Visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

local InfoBox = Instance.new("TextLabel")
InfoBox.Parent = MainFrame
InfoBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfoBox.BorderSizePixel = 0
InfoBox.Position = UDim2.new(0.05, 0, 0.12, 0)
InfoBox.Size = UDim2.new(0.9, 0, 0, 85)
InfoBox.Font = Enum.Font.Code
InfoBox.Text = "สถานะ: พร้อมใช้งาน (Logic ฟาร์มใหม่)\n(กดรีเฟรชเพื่อสแกนหาพาร์ทสกิล/เส้นแดงใต้เท้า)"
InfoBox.TextColor3 = Color3.fromRGB(100, 255, 100)
InfoBox.TextSize = 11
InfoBox.TextWrapped = true
InfoBox.TextXAlignment = Enum.TextXAlignment.Left
InfoBox.TextYAlignment = Enum.TextYAlignment.Top

local AutoFarmBtn = Instance.new("TextButton")
AutoFarmBtn.Parent = MainFrame
AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AutoFarmBtn.BorderSizePixel = 0
AutoFarmBtn.Position = UDim2.new(0.05, 0, 0.42, 0)
AutoFarmBtn.Size = UDim2.new(0.9, 0, 0, 38)
AutoFarmBtn.Font = Enum.Font.SourceSansBold
AutoFarmBtn.Text = "ออโต้ฟาร์มดันเจี้ยน: ปิดอยู่"
AutoFarmBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
AutoFarmBtn.TextSize = 13

local DetectorBtn = Instance.new("TextButton")
DetectorBtn.Parent = MainFrame
DetectorBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
DetectorBtn.BorderSizePixel = 0
DetectorBtn.Position = UDim2.new(0.05, 0, 0.58, 0)
DetectorBtn.Size = UDim2.new(0.9, 0, 0, 38)
DetectorBtn.Font = Enum.Font.SourceSansBold
DetectorBtn.Text = "ตรวจหาสกิลบอสใต้เท้า: ปิดอยู่"
DetectorBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
DetectorBtn.TextSize = 13

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Parent = MainFrame
RefreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Position = UDim2.new(0.05, 0, 0.74, 0)
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 42)
RefreshBtn.Font = Enum.Font.SourceSansBold
RefreshBtn.Text = "🔄 รีเฟรช / สแกนหาสกิลตอนนี้"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
RefreshBtn.TextSize = 13

-- ฟังก์ชันสแกนหาพาร์ทสกิลหรือเส้นแดงใต้เท้า
local function scanForSkills()
    local char = LocalPlayer.Character
    if not char then 
        InfoBox.Text = "❌ ไม่พบตัวละครของคุณ!"
        return 
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        InfoBox.Text = "❌ ไม่พบ HumanoidRootPart!"
        return 
    end

    local detectedSkills = {}
    local scanFolders = {workspace, workspace:FindFirstChild("dungeon")}

    for _, folder in ipairs(scanFolders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nameLower = obj.Name:lower()
                    local col = obj.Color
                    
                    local isRedPart = (col.R > 0.7 and col.G < 0.3 and col.B < 0.3)
                    local hasKeyword = nameLower:find("shot") or nameLower:find("skill") or nameLower:find("warning") or nameLower:find("attack") or nameLower:find("hitbox") or nameLower:find("danger") or nameLower:find("effect")

                    if hasKeyword or isRedPart then
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist <= 60 then
                            local tag = isRedPart and "[พาร์ทสีแดงเตือนภัย]" or "[พาร์ทสกิล]"
                            table.insert(detectedSkills, string.format("- %s %s (ระยะ: %.1fม.)", tag, obj.Name, dist))
                        end
                    end
                end
            end
        end
    end

    if #detectedSkills > 0 then
        InfoBox.Text = "🚨 ตรวจพบสกิล/เส้นแดงใกล้ตัว:\n" .. table.concat(detectedSkills, "\n")
    else
        InfoBox.Text = "✅ ปลอดภัย: ไม่พบพาร์ทสกิลหรือเส้นแดงใต้เท้า"
    end
end

RefreshBtn.MouseButton1Click:Connect(function()
    scanForSkills()
end)

-- ระบบตรวจจับการโดนเตะเพื่อรีจอยอัตโนมัติ
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

-- ลูปเช็คสกิลต่อเนื่อง
task.spawn(function()
    while true do
        task.wait(0.4)
        if getgenv().BossDetectorEnabled then
            pcall(function()
                scanForSkills()
            end)
        end
    end
end)

local function stopFarm()
    if getgenv().DungeonFarmLoop then
        getgenv().DungeonFarmLoop:Disconnect()
        getgenv().DungeonFarmLoop = nil
    end
end

local function startFarm()
    if game.PlaceId == TARGET_PLACE_ID then return end
    stopFarm()

    local currentTargetModel = nil
    local lastSkillTime = 0
    local isDodgingBoss = false

    -- Logic การกรองและเลือกเป้าหมายแบบใหม่ (คุมระยะไม่ให้เกิน 150 และกรองพรีวิวออก)
    local function getTarget()
        local char = LocalPlayer.Character
        local playerHrp = char and char:FindFirstChild("HumanoidRootPart")

        if currentTargetModel and currentTargetModel.Parent then
            local hum = currentTargetModel:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = currentTargetModel:FindFirstChild("HumanoidRootPart")
                if hrp and playerHrp then
                    if (hrp.Position - playerHrp.Position).Magnitude < 150 then
                        return hrp, hum
                    end
                end
            end
        end

        currentTargetModel = nil
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local modelName = obj.Name
                -- กรองข้ามพรีวิวหรือมอนสเตอร์จำลอง
                if modelName:find("_reyillsPreview") or modelName:find("Preview") then
                    continue
                end

                local hum = obj:FindFirstChild("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")

                if hum and hrp and hum.Health > 0 then
                    if playerHrp and (hrp.Position - playerHrp.Position).Magnitude <= 150 then
                        currentTargetModel = obj
                        hrp.Size = Vector3.new(20, 20, 20)
                        hrp.Transparency = 0.8
                        hrp.CanCollide = false
                        return hrp, hum
                    end
                end
            end
        end
        return nil, nil
    end

    -- Logic การเคลื่อนที่และฟาร์มแบบใหม่ (Heartbeat)
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

            local targetHrp, targetHum = getTarget()
            if targetHrp and targetHum then
                local safeHeight = 12
                local hasSkillNearby = false
                
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("bossshot") or obj.Name:lower():find("warning") or obj.Name:lower():find("skill")) then
                        if (obj.Position - hrp.Position).Magnitude < 30 then
                            hasSkillNearby = true
                            break
                        end
                    end
                end

                if hasSkillNearby then
                    safeHeight = 50
                    isDodgingBoss = true
                else
                    isDodgingBoss = false
                end

                -- ใช้การคำนวณตำแหน่งแบบสมูทเข้าหาเป้าหมายใหม่
                local targetPos = targetHrp.Position + Vector3.new(0, safeHeight, 0)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(targetPos, targetHrp.Position), 0.3)
            else
                isDodgingBoss = false
            end
        end)
    end)

    -- ลูปกดสกิลและโจมตีแบบใหม่
    task.spawn(function()
        while getgenv().AutoFarmEnabled do
            task.wait(0.05)
            pcall(function()
                if game.PlaceId == TARGET_PLACE_ID then return end
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

                local targetHrp = getTarget()
                if not targetHrp or isDodgingBoss then return end

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
                                    return
                                end
                            end
                        end
                    end
                end

                local equippedTool = char:FindFirstChildOfClass("Tool")
                if equippedTool then
                    equippedTool:Activate()
                end
            end)
        end
    end)
end

AutoFarmBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmEnabled = not getgenv().AutoFarmEnabled
    if getgenv().AutoFarmEnabled then
        AutoFarmBtn.Text = "ออโต้ฟาร์มดันเจี้ยน: เปิดอยู่"
        AutoFarmBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        startFarm()
    else
        AutoFarmBtn.Text = "ออโต้ฟาร์มดันเจี้ยน: ปิดอยู่"
        AutoFarmBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        stopFarm()
    end
end)

DetectorBtn.MouseButton1Click:Connect(function()
    getgenv().BossDetectorEnabled = not getgenv().BossDetectorEnabled
    if getgenv().BossDetectorEnabled then
        DetectorBtn.Text = "ตรวจหาสกิลบอสใต้เท้า: เปิดอยู่"
        DetectorBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        DetectorBtn.Text = "ตรวจหาสกิลบอสใต้เท้า: ปิดอยู่"
        DetectorBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        InfoBox.Text = "สถานะ: ปิดการตรวจจับออโต้แล้ว"
    end
end)

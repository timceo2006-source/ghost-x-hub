function startFarm()
    if game.PlaceId == TARGET_PLACE_ID then return end

    stopFarm()

    local currentTargetModel = nil
    local lastFoundMonsterTime = tick()
    local initialTargetHealth = nil
    local hasDealtDamage = false
    
    -- ตัวแปรใหม่สำหรับระบบเช็คเลือดไม่ลด
    local lastCheckHealthTime = tick()
    local healthCheckInterval = 1.0  -- เช็คทุกๆ 1 วินาที
    local lastTrackedHealth = nil

    local function getTarget()
        -- ถ้ายังมีเป้าหมายเดิมอยู่ เช็คว่ายังใช้งานได้ไหม
        if currentTargetModel and currentTargetModel.Parent then
            local hum = currentTargetModel:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = currentTargetModel:FindFirstChild("HumanoidRootPart")
                if hrp then
                    lastFoundMonsterTime = tick()
                    return hrp, hum
                end
            end
        end

        -- รีเซ็ตค่าเป้าหมายเก่าถ้าตัวเก่าตายหรือหายไป
        currentTargetModel = nil
        initialTargetHealth = nil
        hasDealtDamage = false
        lastTrackedHealth = nil
        
        -- ค้นหามอนสเตอร์ตัวใหม่ใน Workspace
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
                        lastTrackedHealth = hum.Health
                        hasDealtDamage = false
                        lastCheckHealthTime = tick()
                        
                        hrp.Size = Vector3.new(65, 65, 65)
                        hrp.Transparency = 0.8
                        hrp.CanCollide = false
                        lastFoundMonsterTime = tick()
                        return hrp, hum
                    end
                end
            end
        end
        return nil, nil
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

            local targetHrp, targetHum = getTarget()
            if targetHrp and targetHum then
                
                -- เช็คว่าเลือดลดลงจากตอนแรกไหม (เพื่อเก็บสถานะว่าเคยทำดาเมจเข้าแล้ว)
                if initialTargetHealth and targetHum.Health < initialTargetHealth then
                    hasDealtDamage = true
                end

                -- ระบบเช็คเพิ่มเติม: ถ้าเราปล่อยสกิล/โจมตีไปแล้ว แต่ผ่านมา 1 วินาที เลือดตัวนี้ "เท่าเดิมเป๊ะๆ" (ไม่ลดลงเลย)
                -- ให้ทำการสลัดเป้าหมายนี้ทิ้งแล้วไปหาตัวอื่นทันที
                if tick() - lastCheckHealthTime >= healthCheckInterval then
                    if hasDealtDamage == false and lastTrackedHealth and targetHum.Health >= lastTrackedHealth then
                        -- เลือดไม่ลด บังคับสลับเป้าหมายใหม่ทันทีโดยการล้างค่า CurrentTarget
                        currentTargetModel = nil
                        initialTargetHealth = nil
                        lastTrackedHealth = nil
                        return
                    end
                    lastTrackedHealth = targetHum.Health
                    lastCheckHealthTime = tick()
                end

                local skillsReady, items = areSkillsReady()
                
                local safeHeight = 50 
                local diveHeight = 20 
                local currentHeight = safeHeight
                
                if (skillsReady or workspace:FindFirstChild("bossShot")) and not hasDealtDamage then
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
                lastTrackedHealth = nil
                if tick() - lastFoundMonsterTime > 1.5 then
                    tryStartGame()
                end
            end
        end)
    end)
end

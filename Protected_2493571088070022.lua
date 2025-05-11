-- Improved target validation
local function IsValidTarget(target)
    if not target then return false end
    local humanoid = target:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0 and not target:GetAttribute("Invulnerable")
end

-- Check if the tool is a fruit (to avoid using it)
local function IsFruitTool(local FastAttackSystem = {}
local LocalPlayer = game:GetService("Players").LocalPlayer
local AttackEnabled = true
local LastAttackTime = 0
local AttackCooldown = 0.1
local FruitAttackEnabled = false
local LastFruitAttackTime = 0
local FruitAttackCooldown = 0.2

-- Improved target validation
local function IsValidTarget(target)
    if not target then return false end
    local humanoid = target:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0 and not target:GetAttribute("Invulnerable")
end

-- Optimized target finding
local function GetNearbyTargets(character, range)
    local targets = {}
    local origin = character:GetPivot().Position
    
    -- Check enemies
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        local root = enemy:FindFirstChild("HumanoidRootPart")
        if root and IsValidTarget(enemy) then
            local distance = (root.Position - origin).Magnitude
            if distance <= range then
                table.insert(targets, enemy)
            end
        end
    end
    
    -- Check players
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root and IsValidTarget(player.Character) then
                local distance = (root.Position - origin).Magnitude
                if distance <= range then
                    table.insert(targets, player.Character)
                end
            end
        end
    end
    
    return targets
end

-- Check if the player has a fruit ability equipped
local function HasEquippedFruit()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    
    -- Check if there's a fruit in inventory or equipped
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item:GetAttribute("IsFruit") then
            return true
        end
    end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") and item:GetAttribute("IsFruit") then
            return true
        end
    end
    
    return false
end

-- Get the currently equipped fruit ability
local function GetEquippedFruit()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") and item:GetAttribute("IsFruit") then
            return item
        end
    end
    
    return nil
end

-- Special FastM1 function for fruit abilities
FastAttackSystem.FruitFastM1 = function()
    local now = tick()
    if now - LastFruitAttackTime < FruitAttackCooldown then return end
    LastFruitAttackTime = now
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Check if a fruit is equipped
    local fruitTool = GetEquippedFruit()
    if not fruitTool then return end
    
    -- Get valid targets with extended range for fruit abilities
    local targets = GetNearbyTargets(character, 100)
    if #targets == 0 then return end
    
    -- Network setup
    local rs = game:GetService("ReplicatedStorage")
    local modules = rs:FindFirstChild("Modules")
    if not modules then return end
    
    local fruitRemote = modules:WaitForChild("Net"):WaitForChild("RE/FruitAbility")
    local registerHit = modules:WaitForChild("Net"):WaitForChild("RE/RegisterHit")
    if not fruitRemote or not registerHit then return end
    
    -- Prepare hit data specific for fruit abilities
    local hitData = {}
    local mainTargetPart
    
    -- Target priority parts for fruit abilities (usually center mass)
    local bodyParts = {
        "HumanoidRootPart", "UpperTorso", "LowerTorso",
        "Head", "RightUpperArm", "LeftUpperArm"
    }
    
    for _, target in ipairs(targets) do
        local part = target:FindFirstChild(bodyParts[math.random(#bodyParts)]) or target.PrimaryPart
        if part then
            table.insert(hitData, {target, part})
            if not mainTargetPart then
                mainTargetPart = part
            end
        end
    end
    
    if not mainTargetPart then return end
    
    -- Execute fruit ability
    local function SendFruitAttack()
        -- Fire the primary M1 attack for the fruit
        fruitRemote:FireServer("M1", mainTargetPart.Position)
        
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        
        local fruitScript = playerScripts:FindFirstChild("FruitController")
        if not fruitScript then
            for _, script in ipairs(playerScripts:GetChildren()) do
                if script:IsA("LocalScript") and script.Name:find("Fruit") then
                    fruitScript = script
                    break
                end
            end
        end
        
        -- Try to find and use the fruit's hit registration function
        if fruitScript and getsenv then
            local success, env = pcall(getsenv, fruitScript)
            if success and env then
                if env.RegisterFruitHit then
                    env.RegisterFruitHit(mainTargetPart, hitData)
                    return
                elseif env._G and env._G.FruitHitRegister then
                    env._G.FruitHitRegister(mainTargetPart, hitData)
                    return
                end
            end
        end
        
        -- Fallback method for fruit hits
        registerHit:FireServer(mainTargetPart, hitData, "FruitM1")
    end
    
    -- Execute fruit attacks with protection
    local attackCount = math.random(1, 2)  -- Less attacks for fruits due to power
    for i = 1, attackCount do
        SendFruitAttack()
        if i < attackCount then
            task.wait(math.random(15, 25)/1000)  -- Slightly longer delay for fruit abilities
        end
    end
end

-- Main attack function
FastAttackSystem.Execute = function()
    local now = tick()
    if now - LastAttackTime < AttackCooldown then return end
    LastAttackTime = now
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Find equipped weapon
    local weapon
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            weapon = item
            break
        end
    end
    if not weapon then return end
    
    -- Get valid targets
    local targets = GetNearbyTargets(character, 60)
    if #targets == 0 then return end
    
    -- Network setup
    local rs = game:GetService("ReplicatedStorage")
    local modules = rs:FindFirstChild("Modules")
    if not modules then return end
    
    local registerAttack = modules:WaitForChild("Net"):WaitForChild("RE/RegisterAttack")
    local registerHit = modules:WaitForChild("Net"):WaitForChild("RE/RegisterHit")
    if not registerAttack or not registerHit then return end
    
    -- Prepare hit data
    local hitData = {}
    local mainTargetPart
    local bodyParts = {
        "RightLowerArm", "RightUpperArm",
        "LeftLowerArm", "LeftUpperArm",
        "RightHand", "LeftHand",
        "HumanoidRootPart", "Head"
    }
    
    for _, target in ipairs(targets) do
        local part = target:FindFirstChild(bodyParts[math.random(#bodyParts)]) or target.PrimaryPart
        if part then
            table.insert(hitData, {target, part})
            mainTargetPart = part
        end
    end
    
    if not mainTargetPart then return end
    
    -- Safe attack execution
    local function SendAttack()
        registerAttack:FireServer(0)
        
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        
        local combatScript = playerScripts:FindFirstChildOfClass("LocalScript")
        while not combatScript do
            playerScripts.ChildAdded:Wait()
            combatScript = playerScripts:FindFirstChildOfClass("LocalScript")
        end
        
        -- Advanced hit registration
        if getsenv then
            local success, env = pcall(getsenv, combatScript)
            if success and env and env._G and env._G.SendHitsToServer then
                env._G.SendHitsToServer(mainTargetPart, hitData)
                return
            end
        end
        
        -- Fallback method
        local success, combatRemote = pcall(function()
            return require(modules.Flags).COMBAT_REMOTE_THREAD or false
        end)
        
        if success and not combatRemote then
            registerHit:FireServer(mainTargetPart, hitData)
        end
    end
    
    -- Execute multiple attacks with protection
    local attackCount = math.random(2, 3)
    for i = 1, attackCount do
        SendAttack()
        if i < attackCount then
            task.wait(math.random(5, 15)/1000)
        end
    end
end

-- Main loop with performance optimization
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
    -- Always execute melee/sword attacks regardless of equipped tools
    if AttackEnabled then
        FastAttackSystem.Execute()
    end
    
    -- Only execute fruit attacks if specifically enabled
    if FruitAttackEnabled and HasEquippedFruit() then
        FastAttackSystem.FruitFastM1()
    end
end)

-- Configuration
return {
    Toggle = function(state)
        AttackEnabled = state or not AttackEnabled
        return AttackEnabled
    end,
    
    ToggleFruit = function(state)
        FruitAttackEnabled = state or not FruitAttackEnabled
        return FruitAttackEnabled
    end,
    
    DisableFruit = function()
        FruitAttackEnabled = false
        return "Fruit attacks disabled"
    end,
    
    EnableFruit = function()
        FruitAttackEnabled = true
        return "Fruit attacks enabled"
    end,
    
    IsFruitEnabled = function()
        return FruitAttackEnabled
    end,
    
    SetCooldown = function(cooldown)
        AttackCooldown = math.clamp(cooldown, 0.05, 1.0)
    end,
    
    SetFruitCooldown = function(cooldown)
        FruitAttackCooldown = math.clamp(cooldown, 0.1, 1.5)
    end,
    
    Message = "Enhanced version with Fruit FastM1 support (fruit attacks can be disabled)"
}

-- ================================================
-- JUMP TAB (WITH AUTO RETURN)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local JumpTab = Window:CreateTab("Jump", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local function fire(name, ...)
    if remotes then
        local remote = remotes:FindFirstChild(name)
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        end
    end
end

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.jump then settings.jump = {} end
local jumpSettings = settings.jump

-- ======================================
-- SETTINGS
-- ======================================
local autoKickEnabled = jumpSettings.autoKick or false
local autoKickThread = nil
local autoReturnEnabled = jumpSettings.autoReturn or false
local autoReturnThread = nil
local fullAutoEnabled = jumpSettings.fullAuto or false
local fullAutoThread = nil
local collectJumpEnabled = jumpSettings.collectJump or false
local collectJumpThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function startKick()
    fire("RequestKick", {
        ["action"] = "charge"
    })
end

local function perfectKick()
    fire("RequestKick", {
        ["tier"] = "Perfect"
    })
end

local function autoReturn()
    fire("RequestAutoReturn")
end

local function collectJump()
    fire("PlayCollectJump")
end

local function boostKick()
    fire("BoostKick")
end

local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function isInKickZone()
    local root = getRoot()
    if root then
        local zones = workspace:FindFirstChild("Zones")
        if zones then
            local kickZone = zones:FindFirstChild("KickZone")
            if kickZone and kickZone:IsA("BasePart") then
                local distance = (root.Position - kickZone.Position).Magnitude
                return distance < kickZone.Size.Magnitude
            end
        end
    end
    return false
end

-- ======================================
-- UI - COLLECT JUMP
-- ======================================
JumpTab:CreateSection("Collect Jump")

JumpTab:CreateButton({
    Name = "Collect Jump Once",
    Callback = function()
        collectJump()
        print("[Jump] Collected jump")
    end
})

JumpTab:CreateToggle({
    Name = "Auto Collect Jump",
    CurrentValue = collectJumpEnabled,
    Callback = function(v)
        collectJumpEnabled = v
        jumpSettings.collectJump = v
        getgenv().HubSettings.jump = jumpSettings
        saveHubSettings()
        if v then
            collectJumpThread = task.spawn(function()
                while collectJumpEnabled do
                    collectJump()
                    task.wait(0.5)
                end
            end)
        else
            if collectJumpThread then task.cancel(collectJumpThread) end
        end
    end
})

-- ======================================
-- UI - AUTO KICK
-- ======================================
JumpTab:CreateSection("Auto Kick")

JumpTab:CreateButton({
    Name = "Start Kick (Charge)",
    Callback = function()
        startKick()
        print("[Jump] Kick charged")
    end
})

JumpTab:CreateButton({
    Name = "Perfect Kick",
    Callback = function()
        perfectKick()
        print("[Jump] Perfect kick sent")
    end
})

JumpTab:CreateToggle({
    Name = "Auto Kick (Charge + Perfect)",
    CurrentValue = autoKickEnabled,
    Callback = function(v)
        autoKickEnabled = v
        jumpSettings.autoKick = v
        getgenv().HubSettings.jump = jumpSettings
        saveHubSettings()
        if v then
            autoKickThread = task.spawn(function()
                while autoKickEnabled do
                    startKick()
                    task.wait(1.1)
                    perfectKick()
                    getgenv().ActivityStatus.current = "Auto Kick - Perfect!"
                    getgenv().ActivityStatus.trigger = true
                    task.wait(2)
                end
            end)
        else
            if autoKickThread then task.cancel(autoKickThread) end
        end
    end
})

-- ======================================
-- UI - AUTO RETURN
-- ======================================
JumpTab:CreateSection("Auto Return")

JumpTab:CreateButton({
    Name = "Return to Safe Zone",
    Callback = function()
        autoReturn()
        getgenv().ActivityStatus.current = "Returning to safe zone"
        getgenv().ActivityStatus.trigger = true
        print("[Jump] Auto return sent")
    end
})

JumpTab:CreateToggle({
    Name = "Auto Return After Landing",
    CurrentValue = autoReturnEnabled,
    Callback = function(v)
        autoReturnEnabled = v
        jumpSettings.autoReturn = v
        getgenv().HubSettings.jump = jumpSettings
        saveHubSettings()
        if v then
            autoReturnThread = task.spawn(function()
                while autoReturnEnabled do
                    -- Check if not in kick zone (meaning we're out in the field)
                    if not isInKickZone() then
                        autoReturn()
                        getgenv().ActivityStatus.current = "Returning to safe zone"
                        getgenv().ActivityStatus.trigger = true
                    end
                    task.wait(3)
                end
            end)
        else
            if autoReturnThread then task.cancel(autoReturnThread) end
        end
    end
})

-- ======================================
-- UI - FULL AUTO (KICK + RETURN LOOP)
-- ======================================
JumpTab:CreateSection("Full Auto")

JumpTab:CreateLabel("Auto Kick → Fly → Land → Return → Repeat")

JumpTab:CreateToggle({
    Name = "Full Auto Jump Loop",
    CurrentValue = fullAutoEnabled,
    Callback = function(v)
        fullAutoEnabled = v
        jumpSettings.fullAuto = v
        getgenv().HubSettings.jump = jumpSettings
        saveHubSettings()
        if v then
            fullAutoThread = task.spawn(function()
                while fullAutoEnabled do
                    -- Check if in kick zone
                    if isInKickZone() then
                        getgenv().ActivityStatus.current = "Starting Kick..."
                        getgenv().ActivityStatus.trigger = true
                        startKick()
                        task.wait(1.1)
                        perfectKick()
                        task.wait(5) -- Wait for flight
                    else
                        getgenv().ActivityStatus.current = "Returning to safe zone..."
                        getgenv().ActivityStatus.trigger = true
                        autoReturn()
                        task.wait(2)
                    end
                    task.wait(1)
                end
            end)
        else
            if fullAutoThread then task.cancel(fullAutoThread) end
        end
    end
})

-- ======================================
-- UI - BOOST
-- ======================================
JumpTab:CreateSection("Boost")

JumpTab:CreateButton({
    Name = "Boost Once",
    Callback = function()
        boostKick()
        print("[Jump] Boosted")
    end
})

JumpTab:CreateToggle({
    Name = "Auto Boost (During Flight)",
    CurrentValue = jumpSettings.autoBoost or false,
    Callback = function(v)
        jumpSettings.autoBoost = v
        getgenv().HubSettings.jump = jumpSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    boostKick()
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if collectJumpEnabled then
    collectJumpThread = task.spawn(function()
        while collectJumpEnabled do
            collectJump()
            task.wait(0.5)
        end
    end)
end

if autoKickEnabled then
    autoKickThread = task.spawn(function()
        while autoKickEnabled do
            startKick()
            task.wait(1.1)
            perfectKick()
            task.wait(2)
        end
    end)
end

if autoReturnEnabled then
    autoReturnThread = task.spawn(function()
        while autoReturnEnabled do
            if not isInKickZone() then
                autoReturn()
            end
            task.wait(3)
        end
    end)
end

if fullAutoEnabled then
    fullAutoThread = task.spawn(function()
        while fullAutoEnabled do
            if isInKickZone() then
                startKick()
                task.wait(1.1)
                perfectKick()
                task.wait(5)
            else
                autoReturn()
                task.wait(2)
            end
            task.wait(1)
        end
    end)
end

print("[Jump] Loaded!")

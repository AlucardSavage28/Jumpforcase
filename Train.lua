-- ================================================
-- TRAIN TAB (WEIGHT + TRAINING + STRENGTH)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local TrainTab = Window:CreateTab("Train", nil)

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
if not settings.train then settings.train = {} end
local trainSettings = settings.train

-- ======================================
-- CONFIG
-- ======================================
local WeightsConfig = require(ReplicatedStorage:FindFirstChild("WeightsConfig"))

-- ======================================
-- WEIGHT LIST
-- ======================================
local weightList = {}
if WeightsConfig and WeightsConfig.Order then
    for _, weightName in ipairs(WeightsConfig.Order) do
        table.insert(weightList, weightName)
    end
end
if #weightList == 0 then
    weightList = {"Wooden Stick", "Basic Barbell", "Stone Barbell", "Invisible Barbell", "Copper Barbell", "Golden Barbell", "Diamond Barbell", "Mountain Barbell", "Sand Barbell", "Radioactive Barbell", "Ice Barbell", "Volcano Barbell", "Black Diamond Barbell", "Emerald Barbell", "Lava Barbell", "Skull Barbell", "Haunted Barbell", "Angel Barbell", "Toxic Barbell", "Purple Void Barbell", "Saturno Barbell", "Demon Barbell", "Black Hole Barbell"}
end

-- ======================================
-- SETTINGS
-- ======================================
local selectedWeight = trainSettings.selectedWeight or "Wooden Stick"
local autoTrainEnabled = trainSettings.autoTrain or false
local autoTrainThread = nil
local autoBuyEnabled = trainSettings.autoBuy or false
local autoBuyThread = nil
local bestWeightEnabled = trainSettings.autoBestWeight or false
local bestWeightThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function getEquippedWeight()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        -- Search HUD for weight name
        local game = playerGui:FindFirstChild("Game")
        if game then
            local hud = game:FindFirstChild("HUD")
            if hud then
                local hudFrame = hud:FindFirstChild("HUDFrame")
                if hudFrame then
                    local invBottom = hudFrame:FindFirstChild("InventoryBottom")
                    if invBottom then
                        local slotsLayout = invBottom:FindFirstChild("SlotsLayout")
                        if slotsLayout then
                            for _, slot in ipairs(slotsLayout:GetChildren()) do
                                local content = slot:FindFirstChild("Content")
                                if content then
                                    local weightName = content:FindFirstChild("WeightName")
                                    if weightName and weightName.Text ~= "" then
                                        return weightName.Text
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Search Frames for WeightUI
        local frames = playerGui:FindFirstChild("Frames")
        if frames then
            local weightUI = frames:FindFirstChild("WeightUI")
            if weightUI then
                -- Check if weight UI is open
                if weightUI.Visible then
                    return "Weight UI Open"
                end
            end
        end
    end
    return "Unknown"
end

local function getWeightIndex(weightName)
    for i, name in ipairs(weightList) do
        if name == weightName then
            return i
        end
    end
    return 0
end

local function getTrainTimer(tier)
    -- Tier format: T2, T4, T8, T16, S2, S4, S8, S16
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local game = playerGui:FindFirstChild("Game")
        if game then
            local hud = game:FindFirstChild("HUD")
            if hud then
                local hudFrame = hud:FindFirstChild("HUDFrame")
                if hudFrame then
                    local multipliers = hudFrame:FindFirstChild("Multipliers")
                    if multipliers then
                        local bottom = multipliers:FindFirstChild("Bottom")
                        if bottom then
                            local trainFrame = bottom:FindFirstChild("TrainEffect_" .. tier)
                            if trainFrame then
                                local timer = trainFrame:FindFirstChild("TrainTimer")
                                if timer then
                                    return timer.Text
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getAllTrainTimers()
    local timers = {}
    local tiers = {"T2", "T4", "T8", "T16", "S2", "S4", "S8", "S16"}
    for _, tier in ipairs(tiers) do
        local time = getTrainTimer(tier)
        if time and time ~= "" and time ~= "0s" then
            timers[tier] = time
        end
    end
    return timers
end

local function hasActiveTraining()
    local timers = getAllTrainTimers()
    return next(timers) ~= nil
end

local function buyWeight(weightName)
    fire("RequestBuyWeight", weightName)
end

local function equipWeight(weightName)
    fire("RequestEquipWeight", weightName)
end

local function buyAllWeights()
    for _, weightName in ipairs(weightList) do
        buyWeight(weightName)
        task.wait(0.2)
    end
end

local function equipBestWeight()
    local currentWeight = getEquippedWeight()
    local currentIndex = getWeightIndex(currentWeight)
    
    -- Try to equip the highest weight (best training)
    for i = #weightList, 1, -1 do
        if i > currentIndex then
            local bestWeight = weightList[i]
            equipWeight(bestWeight)
            return bestWeight
        end
    end
    
    return currentWeight
end

-- ======================================
-- UI - WEIGHT SHOP
-- ======================================
TrainTab:CreateSection("Weight Shop")

TrainTab:CreateDropdown({
    Name = "Select Weight",
    Options = weightList,
    CurrentOption = {selectedWeight},
    Callback = function(v)
        selectedWeight = v[1]
        trainSettings.selectedWeight = v[1]
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
    end
})

TrainTab:CreateButton({
    Name = "Buy Weight",
    Callback = function()
        buyWeight(selectedWeight)
        getgenv().ActivityStatus.current = "Buying " .. selectedWeight
        getgenv().ActivityStatus.trigger = true
        print("[Train] Bought: " .. selectedWeight)
    end
})

TrainTab:CreateButton({
    Name = "Equip Weight",
    Callback = function()
        equipWeight(selectedWeight)
        getgenv().ActivityStatus.current = "Equipping " .. selectedWeight
        getgenv().ActivityStatus.trigger = true
        print("[Train] Equipped: " .. selectedWeight)
    end
})

TrainTab:CreateButton({
    Name = "Buy All Weights",
    Callback = function()
        buyAllWeights()
        getgenv().ActivityStatus.current = "Buying All Weights"
        getgenv().ActivityStatus.trigger = true
        print("[Train] Buying all weights")
    end
})

TrainTab:CreateToggle({
    Name = "Auto Buy All Weights",
    CurrentValue = autoBuyEnabled,
    Callback = function(v)
        autoBuyEnabled = v
        trainSettings.autoBuy = v
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
        if v then
            autoBuyThread = task.spawn(function()
                while autoBuyEnabled do
                    buyAllWeights()
                    getgenv().ActivityStatus.current = "Auto Buying All Weights"
                    getgenv().ActivityStatus.trigger = true
                    task.wait(30)
                end
            end)
        else
            if autoBuyThread then task.cancel(autoBuyThread) end
        end
    end
})

-- ======================================
-- UI - TRAINING
-- ======================================
TrainTab:CreateSection("Training")

TrainTab:CreateToggle({
    Name = "Auto Train (Re-equip Weight)",
    CurrentValue = autoTrainEnabled,
    Callback = function(v)
        autoTrainEnabled = v
        trainSettings.autoTrain = v
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
        if v then
            autoTrainThread = task.spawn(function()
                local wasActive = false
                while autoTrainEnabled do
                    local currentWeight = getEquippedWeight()
                    
                    if currentWeight ~= "Unknown" and currentWeight ~= "Weight UI Open" then
                        -- Re-equip to maintain training
                        equipWeight(currentWeight)
                        
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Training with " .. currentWeight
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                    end
                    
                    task.wait(3)
                end
            end)
        else
            if autoTrainThread then task.cancel(autoTrainThread) end
        end
    end
})

TrainTab:CreateToggle({
    Name = "Auto Equip Best Weight",
    CurrentValue = bestWeightEnabled,
    Callback = function(v)
        bestWeightEnabled = v
        trainSettings.autoBestWeight = v
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
        if v then
            bestWeightThread = task.spawn(function()
                local wasActive = false
                while bestWeightEnabled do
                    local currentWeight = getEquippedWeight()
                    local currentIndex = getWeightIndex(currentWeight)
                    
                    -- Check if there's a better weight
                    local bestWeight = nil
                    for i = #weightList, 1, -1 do
                        if i > currentIndex then
                            bestWeight = weightList[i]
                            break
                        end
                    end
                    
                    if bestWeight then
                        -- Try to buy and equip
                        buyWeight(bestWeight)
                        task.wait(0.5)
                        equipWeight(bestWeight)
                        
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Equipping Best Weight: " .. bestWeight
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                        
                        print("[Train] Upgraded to: " .. bestWeight)
                    else
                        -- Already have best weight
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Already using best weight: " .. currentWeight
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                    end
                    
                    task.wait(10)
                end
            end)
        else
            if bestWeightThread then task.cancel(bestWeightThread) end
        end
    end
})

-- ======================================
-- UI - STRENGTH
-- ======================================
TrainTab:CreateSection("Strength")

TrainTab:CreateButton({
    Name = "Activate Strength Bonus",
    Callback = function()
        fire("StrengthBonus")
        getgenv().ActivityStatus.current = "Strength Bonus Activated"
        getgenv().ActivityStatus.trigger = true
        print("[Train] Strength bonus activated")
    end
})

TrainTab:CreateToggle({
    Name = "Auto Strength Bonus",
    CurrentValue = false,
    Callback = function(v)
        if v then
            task.spawn(function()
                while v do
                    fire("StrengthBonus")
                    getgenv().ActivityStatus.current = "Strength Bonus Activated"
                    getgenv().ActivityStatus.trigger = true
                    task.wait(60)
                end
            end)
        end
    end
})

-- ======================================
-- UI - STATUS
-- ======================================
TrainTab:CreateSection("Status")

local weightStatusLabel = TrainTab:CreateLabel("Equipped: Checking...")
local trainingStatusLabel = TrainTab:CreateLabel("Training: Checking...")

task.spawn(function()
    while true do
        task.wait(3)
        
        local weight = getEquippedWeight()
        pcall(function() weightStatusLabel:SetText("Equipped: " .. weight) end)
        
        local hasTraining = hasActiveTraining()
        if hasTraining then
            local timers = getAllTrainTimers()
            local timerText = ""
            for tier, time in pairs(timers) do
                timerText = timerText .. tier .. ": " .. time .. " | "
            end
            pcall(function() trainingStatusLabel:SetText("Active: " .. timerText) end)
        else
            pcall(function() trainingStatusLabel:SetText("Active: No training") end)
        end
    end
end)

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if autoBuyEnabled then
    autoBuyThread = task.spawn(function()
        while autoBuyEnabled do
            buyAllWeights()
            task.wait(30)
        end
    end)
end

if autoTrainEnabled then
    autoTrainThread = task.spawn(function()
        while autoTrainEnabled do
            local currentWeight = getEquippedWeight()
            if currentWeight ~= "Unknown" and currentWeight ~= "Weight UI Open" then
                equipWeight(currentWeight)
            end
            task.wait(3)
        end
    end)
end

if bestWeightEnabled then
    bestWeightThread = task.spawn(function()
        while bestWeightEnabled do
            local currentWeight = getEquippedWeight()
            local currentIndex = getWeightIndex(currentWeight)
            
            for i = #weightList, 1, -1 do
                if i > currentIndex then
                    local bestWeight = weightList[i]
                    buyWeight(bestWeight)
                    task.wait(0.5)
                    equipWeight(bestWeight)
                    break
                end
            end
            
            task.wait(10)
        end
    end)
end

print("[Train] Loaded!")

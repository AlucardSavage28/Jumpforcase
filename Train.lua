-- ================================================
-- TRAIN TAB (FIXED REMOTE ARGUMENTS)
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

-- ======================================
-- SETTINGS
-- ======================================
local selectedWeight = trainSettings.selectedWeight or "Wooden Stick"
local autoBuyEnabled = trainSettings.autoBuy or false
local autoBuyThread = nil
local autoEquipBestEnabled = trainSettings.autoEquipBest or false
local autoEquipBestThread = nil

-- ======================================
-- FUNCTIONS (CORRECT FORMATS)
-- ======================================
local function buyWeight(weightName)
    fire("RequestBuyWeight", {
        ["key"] = weightName
    })
end

local function equipWeight(weightName)
    fire("RequestEquipWeight", {
        ["key"] = weightName
    })
end

local function buyAllWeights()
    for _, weightName in ipairs(weightList) do
        buyWeight(weightName)
        task.wait(0.2)
    end
end

local function getEquippedWeight()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
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
-- UI - AUTO EQUIP BEST
-- ======================================
TrainTab:CreateSection("Auto Training")

TrainTab:CreateToggle({
    Name = "Auto Equip Best Weight",
    CurrentValue = autoEquipBestEnabled,
    Callback = function(v)
        autoEquipBestEnabled = v
        trainSettings.autoEquipBest = v
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
        if v then
            autoEquipBestThread = task.spawn(function()
                local wasActive = false
                while autoEquipBestEnabled do
                    local currentWeight = getEquippedWeight()
                    local currentIndex = getWeightIndex(currentWeight)
                    
                    -- Check if there's a better weight to equip
                    local bestWeight = nil
                    for i = #weightList, 1, -1 do
                        if i > currentIndex then
                            bestWeight = weightList[i]
                            break
                        end
                    end
                    
                    if bestWeight then
                        -- Buy first then equip
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
                        -- Already have best weight equipped
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Using best weight: " .. currentWeight
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                    end
                    
                    task.wait(10)
                end
            end)
        else
            if autoEquipBestThread then task.cancel(autoEquipBestThread) end
        end
    end
})

-- ======================================
-- UI - STATUS
-- ======================================
TrainTab:CreateSection("Status")

local weightStatusLabel = TrainTab:CreateLabel("Equipped: Checking...")

task.spawn(function()
    while true do
        task.wait(3)
        local weight = getEquippedWeight()
        pcall(function() weightStatusLabel:SetText("Equipped: " .. weight) end)
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

if autoEquipBestEnabled then
    autoEquipBestThread = task.spawn(function()
        while autoEquipBestEnabled do
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

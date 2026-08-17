-- ================================================
-- TRAIN TAB (SIMPLIFIED - EQUIP + AUTO CLICK 2X)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local TrainTab = Window:CreateTab("Train", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

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
local autoEquipEnabled = trainSettings.autoEquip or false
local autoEquipThread = nil
local autoClick2XEnabled = trainSettings.autoClick2X or false
local autoClick2XThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function equipWeight(weightName)
    fire("RequestEquipWeight", {
        ["key"] = weightName
    })
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

local function find2XButton()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, button in ipairs(playerGui:GetDescendants()) do
            if button:IsA("ImageButton") or button:IsA("TextButton") then
                -- Look for 2x or X2 button
                local buttonText = ""
                for _, desc in ipairs(button:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                        buttonText = buttonText .. " " .. desc.Text
                    end
                end
                
                if buttonText:find("2") or buttonText:find("X2") or buttonText:find("x2") then
                    return button
                end
            end
        end
    end
    return nil
end

local function click2XButton()
    local button = find2XButton()
    if button then
        -- Try firing Activated
        firesignal(button.Activated)
        return true
    end
    
    -- Fallback: Try clicking at screen position
    -- The 2x button is usually on the right side of screen
    local camera = workspace.CurrentCamera
    if camera then
        local viewportSize = camera.ViewportSize
        -- Try clicking at various positions where 2x might be
        VirtualInputManager:SendMouseButtonEvent(viewportSize.X * 0.7, viewportSize.Y * 0.3, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(viewportSize.X * 0.7, viewportSize.Y * 0.3, 0, false, game, 1)
    end
    return false
end

-- ======================================
-- UI - EQUIP WEIGHT
-- ======================================
TrainTab:CreateSection("Equip Weight")

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
    Name = "Equip Weight Once",
    Callback = function()
        equipWeight(selectedWeight)
        getgenv().ActivityStatus.current = "Equipping " .. selectedWeight
        getgenv().ActivityStatus.trigger = true
        print("[Train] Equipped: " .. selectedWeight)
    end
})

TrainTab:CreateToggle({
    Name = "Auto Equip (Keep Training)",
    CurrentValue = autoEquipEnabled,
    Callback = function(v)
        autoEquipEnabled = v
        trainSettings.autoEquip = v
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
        if v then
            autoEquipThread = task.spawn(function()
                local wasActive = false
                while autoEquipEnabled do
                    local currentWeight = getEquippedWeight()
                    
                    if currentWeight ~= selectedWeight then
                        equipWeight(selectedWeight)
                        
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Training with " .. selectedWeight
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                    end
                    
                    task.wait(5)
                end
            end)
        else
            if autoEquipThread then task.cancel(autoEquipThread) end
        end
    end
})

-- ======================================
-- UI - AUTO CLICK 2X
-- ======================================
TrainTab:CreateSection("Auto Click 2X")

TrainTab:CreateLabel("Automatically clicks the 2x button when it appears")

TrainTab:CreateToggle({
    Name = "Auto Click 2X Button",
    CurrentValue = autoClick2XEnabled,
    Callback = function(v)
        autoClick2XEnabled = v
        trainSettings.autoClick2X = v
        getgenv().HubSettings.train = trainSettings
        saveHubSettings()
        if v then
            autoClick2XThread = task.spawn(function()
                local clickCount = 0
                while autoClick2XEnabled do
                    local clicked = click2XButton()
                    
                    if clicked then
                        clickCount = clickCount + 1
                        if clickCount == 1 then
                            getgenv().ActivityStatus.current = "Auto Clicking 2X Button"
                            getgenv().ActivityStatus.trigger = true
                        end
                    end
                    
                    task.wait(0.5)
                end
            end)
        else
            if autoClick2XThread then task.cancel(autoClick2XThread) end
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
if autoEquipEnabled then
    autoEquipThread = task.spawn(function()
        while autoEquipEnabled do
            local currentWeight = getEquippedWeight()
            if currentWeight ~= selectedWeight then
                equipWeight(selectedWeight)
            end
            task.wait(5)
        end
    end)
end

if autoClick2XEnabled then
    autoClick2XThread = task.spawn(function()
        while autoClick2XEnabled do
            click2XButton()
            task.wait(0.5)
        end
    end)
end

print("[Train] Loaded!")

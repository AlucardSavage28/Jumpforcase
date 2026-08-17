-- ================================================
-- CASE TAB (OPEN + AUTO OPEN + REROLL + HIDE ANIM)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local CaseTab = Window:CreateTab("Case", nil)

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
if not settings.case then settings.case = {} end
local caseSettings = settings.case

-- ======================================
-- CONFIG
-- ======================================
local CasesConfig = require(ReplicatedStorage:FindFirstChild("CasesConfig"))

-- ======================================
-- CASE LIST
-- ======================================
local caseList = {}
if CasesConfig and CasesConfig.Order then
    for _, caseName in ipairs(CasesConfig.Order) do
        table.insert(caseList, caseName)
    end
end
if #caseList == 0 then
    caseList = {"Basic", "Common", "Sand", "Copper", "Haunted", "Legendary", "Mythic", "Galaxy", "Godly", "Oceania", "Secret", "Holy", "Emerald", "Ice", "Diamond", "BlackDiamond", "Void", "BlackHole", "Cerberus"}
end

-- ======================================
-- RARITY LIST FOR REROLL
-- ======================================
local rarityList = {"Basic", "Common", "Copper", "Sand", "Haunted", "Legendary", "RoyalBlue", "RoyalRed", "Golden", "Mythic", "Lava", "Bubblegum", "Radioactive", "Galaxy", "ShopDiamond", "ShopIce", "Godly", "Oceania", "Secret", "OG", "Holy", "Emerald", "Ice", "Diamond", "BlackDiamond", "Void", "BlackHole", "Cerberus"}

-- ======================================
-- SETTINGS
-- ======================================
local selectedCase = caseSettings.selectedCase or "Basic"
local caseAmount = caseSettings.caseAmount or 1
local autoOpenEnabled = caseSettings.autoOpen or false
local autoOpenThread = nil
local fastAutoOpenEnabled = false

local targetRarity = caseSettings.targetRarity or "Secret"
local rerollEnabled = caseSettings.autoReroll or false
local rerollThread = nil
local rerollStopOnTarget = caseSettings.rerollStopOnTarget or true

local hideAnimEnabled = caseSettings.hideAnim or false
local animHooked = false

-- ======================================
-- HIDE ANIMATION SYSTEM
-- ======================================
local function hookAnimation()
    if animHooked then return end
    animHooked = true
    
    -- Hook CaseOpened and CaseMulti3D to block animations
    if remotes then
        local caseOpened = remotes:FindFirstChild("CaseOpened")
        local caseMulti3D = remotes:FindFirstChild("CaseMulti3D")
        local caseReveal3D = remotes:FindFirstChild("CaseReveal3D")
        local autoOpenRevealClosed = remotes:FindFirstChild("AutoOpenRevealClosed")
        
        if caseOpened then
            local oldName = caseOpened.Name
            -- Block client-side animation by intercepting
            local oldConnect = caseOpened.OnClientEvent
        end
    end
    
    -- Try to hook the CaseReveal3D remote
    local success, err = pcall(function()
        local PlayerScripts = player:FindFirstChild("PlayerScripts")
        if PlayerScripts then
            local caseScripts = PlayerScripts:FindFirstChild("Client")
            if caseScripts then
                local ui = caseScripts:FindFirstChild("UI")
                if ui then
                    local revealScript = ui:FindFirstChild("RareCaseCutsceneController")
                    if revealScript then
                        -- Disable the script
                        revealScript.Disabled = true
                        print("[Case] Rare case cutscene disabled")
                    end
                    
                    local caseEquipScript = ui:FindFirstChild("CaseEquipOpenController")
                    if caseEquipScript then
                        -- Disable the script
                        caseEquipScript.Disabled = true
                        print("[Case] Case equip controller disabled")
                    end
                    
                    local luckBroadcastScript = ui:FindFirstChild("LuckCaseBroadcastController")
                    if luckBroadcastScript then
                        luckBroadcastScript.Disabled = true
                        print("[Case] Luck case broadcast disabled")
                    end
                end
            end
        end
    end)
    
    -- Hook the CaseOpenConfirm script
    pcall(function()
        local PlayerScripts = player:FindFirstChild("PlayerScripts")
        if PlayerScripts then
            local caseOpenConfirm = PlayerScripts:FindFirstChild("CaseOpenConfirm")
            if caseOpenConfirm then
                caseOpenConfirm.Disabled = true
                print("[Case] Case open confirm disabled")
            end
        end
    end)
end

local function unhookAnimation()
    animHooked = false
    
    pcall(function()
        local PlayerScripts = player:FindFirstChild("PlayerScripts")
        if PlayerScripts then
            local ui = PlayerScripts:FindFirstChild("Client") and PlayerScripts.Client:FindFirstChild("UI")
            if ui then
                local revealScript = ui:FindFirstChild("RareCaseCutsceneController")
                if revealScript then revealScript.Disabled = false end
                
                local caseEquipScript = ui:FindFirstChild("CaseEquipOpenController")
                if caseEquipScript then caseEquipScript.Disabled = false end
                
                local luckBroadcastScript = ui:FindFirstChild("LuckCaseBroadcastController")
                if luckBroadcastScript then luckBroadcastScript.Disabled = false end
            end
        end
    end)
end

-- ======================================
-- FUNCTIONS
-- ======================================
local function openCase(caseName, amount)
    amount = amount or 1
    if hideAnimEnabled then
        -- Fire directly without animation
        if amount > 1 then
            fire("RequestOpenCaseMulti", caseName, amount)
        else
            fire("RequestOpenCase", caseName)
        end
        -- Skip reveal animation
        fire("RequestRevealComplete")
    else
        if amount > 1 then
            fire("RequestOpenCaseMulti", caseName, amount)
        else
            fire("RequestOpenCase", caseName)
        end
    end
end

local function getCaseUid(caseName)
    if CasesConfig and CasesConfig.UidForKey then
        return CasesConfig.UidForKey(caseName)
    end
    return caseName
end

local function getCaseRarity(caseName)
    if CasesConfig and CasesConfig.RarityOf then
        return CasesConfig.RarityOf(caseName)
    end
    return "Unknown"
end

local function getCaseLuck(caseName)
    if CasesConfig and CasesConfig.LuckOf then
        return CasesConfig.LuckOf(caseName)
    end
    return "Unknown"
end

-- ======================================
-- UI - CASE OPENING
-- ======================================
CaseTab:CreateSection("Case Opening")

CaseTab:CreateDropdown({
    Name = "Select Case",
    Options = caseList,
    CurrentOption = {selectedCase},
    Callback = function(v)
        selectedCase = v[1]
        caseSettings.selectedCase = v[1]
        getgenv().HubSettings.case = caseSettings
        saveHubSettings()
    end
})

CaseTab:CreateInput({
    Name = "Multi Open Amount",
    CurrentValue = tostring(caseAmount),
    PlaceholderText = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            caseAmount = math.max(1, n)
            caseSettings.caseAmount = n
            getgenv().HubSettings.case = caseSettings
            saveHubSettings()
        end
    end
})

CaseTab:CreateButton({
    Name = "Open Case (Single)",
    Callback = function()
        openCase(selectedCase, 1)
        getgenv().ActivityStatus.current = "Opening " .. selectedCase .. " Case"
        getgenv().ActivityStatus.trigger = true
        print("[Case] Opened: " .. selectedCase)
    end
})

CaseTab:CreateButton({
    Name = "Open Case (Multi)",
    Callback = function()
        openCase(selectedCase, caseAmount)
        getgenv().ActivityStatus.current = "Opening " .. selectedCase .. " Case x" .. caseAmount
        getgenv().ActivityStatus.trigger = true
        print("[Case] Opened: " .. selectedCase .. " x" .. caseAmount)
    end
})

CaseTab:CreateToggle({
    Name = "Auto Open Case",
    CurrentValue = autoOpenEnabled,
    Callback = function(v)
        autoOpenEnabled = v
        caseSettings.autoOpen = v
        getgenv().HubSettings.case = caseSettings
        saveHubSettings()
        if v then
            autoOpenThread = task.spawn(function()
                local wasActive = false
                while autoOpenEnabled do
                    if caseAmount > 1 then
                        openCase(selectedCase, caseAmount)
                    else
                        openCase(selectedCase, 1)
                    end
                    
                    if not wasActive then
                        getgenv().ActivityStatus.current = "Auto Opening " .. selectedCase .. " Case"
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                    end
                    
                    task.wait(0.3)
                end
            end)
        else
            if autoOpenThread then task.cancel(autoOpenThread) end
        end
    end
})

CaseTab:CreateToggle({
    Name = "Auto Open (Fast Mode)",
    CurrentValue = false,
    Callback = function(v)
        fastAutoOpenEnabled = v
        if v then
            fire("RequestAutoOpen", selectedCase)
            getgenv().ActivityStatus.current = "Fast Auto Open Started: " .. selectedCase
            getgenv().ActivityStatus.trigger = true
            print("[Case] Fast auto open started: " .. selectedCase)
        else
            fire("RequestAutoOpenStop")
            getgenv().ActivityStatus.current = "Fast Auto Open Stopped"
            getgenv().ActivityStatus.trigger = true
            print("[Case] Fast auto open stopped")
        end
    end
})

-- ======================================
-- UI - HIDE ANIMATION
-- ======================================
CaseTab:CreateSection("Animation")

CaseTab:CreateToggle({
    Name = "Hide Case Animation",
    CurrentValue = hideAnimEnabled,
    Callback = function(v)
        hideAnimEnabled = v
        caseSettings.hideAnim = v
        getgenv().HubSettings.case = caseSettings
        saveHubSettings()
        
        if v then
            hookAnimation()
            getgenv().ActivityStatus.current = "Case Animation Hidden"
            getgenv().ActivityStatus.trigger = true
            print("[Case] Animation hidden")
        else
            unhookAnimation()
            getgenv().ActivityStatus.current = "Case Animation Shown"
            getgenv().ActivityStatus.trigger = true
            print("[Case] Animation restored")
        end
    end
})

-- ======================================
-- UI - CASE INFO
-- ======================================
CaseTab:CreateSection("Case Info")

local caseInfoLabel = CaseTab:CreateLabel("Select a case to see info")

local function updateCaseInfo()
    local rarity = getCaseRarity(selectedCase)
    local luck = getCaseLuck(selectedCase)
    local uid = getCaseUid(selectedCase)
    local infoText = string.format(
        "Case: %s\nRarity: %s\nLuck: %s\nUid: %s",
        selectedCase, rarity, luck, uid
    )
    pcall(function() caseInfoLabel:SetText(infoText) end)
end

task.spawn(function()
    local lastCase = ""
    while true do
        task.wait(1)
        if selectedCase ~= lastCase then
            lastCase = selectedCase
            updateCaseInfo()
        end
    end
end)

-- ======================================
-- UI - AUTO REROLL (AUTO OPEN FOR TARGET)
-- ======================================
CaseTab:CreateSection("Auto Reroll (Auto Open for Target)")

CaseTab:CreateLabel("This will continuously open cases until target rarity is found")

CaseTab:CreateDropdown({
    Name = "Target Rarity",
    Options = rarityList,
    CurrentOption = {targetRarity},
    Callback = function(v)
        targetRarity = v[1]
        caseSettings.targetRarity = v[1]
        getgenv().HubSettings.case = caseSettings
        saveHubSettings()
    end
})

CaseTab:CreateToggle({
    Name = "Stop When Target Found",
    CurrentValue = rerollStopOnTarget,
    Callback = function(v)
        rerollStopOnTarget = v
        caseSettings.rerollStopOnTarget = v
        getgenv().HubSettings.case = caseSettings
        saveHubSettings()
    end
})

CaseTab:CreateButton({
    Name = "Reroll Once (Open Case)",
    Callback = function()
        openCase(selectedCase, 1)
        getgenv().ActivityStatus.current = "Rerolling " .. selectedCase .. " for " .. targetRarity
        getgenv().ActivityStatus.trigger = true
        print("[Case] Rerolled: " .. selectedCase)
    end
})

CaseTab:CreateToggle({
    Name = "Auto Reroll (Auto Open)",
    CurrentValue = rerollEnabled,
    Callback = function(v)
        rerollEnabled = v
        caseSettings.autoReroll = v
        getgenv().HubSettings.case = caseSettings
        saveHubSettings()
        if v then
            rerollThread = task.spawn(function()
                local wasActive = false
                local openCount = 0
                
                while rerollEnabled do
                    -- Open case
                    openCase(selectedCase, 1)
                    openCount = openCount + 1
                    
                    if not wasActive then
                        getgenv().ActivityStatus.current = "Auto Rerolling " .. selectedCase .. " for " .. targetRarity
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                    end
                    
                    task.wait(0.5)
                    
                    -- Check if we got target rarity
                    if rerollStopOnTarget then
                        local currentRarity = getCaseRarity(selectedCase)
                        if currentRarity == targetRarity then
                            getgenv().ActivityStatus.current = "Got " .. targetRarity .. " after " .. openCount .. " opens!"
                            getgenv().ActivityStatus.trigger = true
                            print("[Case] Got target rarity: " .. targetRarity .. " after " .. openCount .. " opens")
                            rerollEnabled = false
                            break
                        end
                    end
                end
            end)
        else
            if rerollThread then task.cancel(rerollThread) end
        end
    end
})

-- ======================================
-- UI - LUCK CASE
-- ======================================
CaseTab:CreateSection("Luck Case")

CaseTab:CreateButton({
    Name = "Clear Luck Case",
    Callback = function()
        fire("LuckCaseClear")
        getgenv().ActivityStatus.current = "Luck Case Cleared"
        getgenv().ActivityStatus.trigger = true
        print("[Case] Luck case cleared")
    end
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if autoOpenEnabled then
    autoOpenThread = task.spawn(function()
        while autoOpenEnabled do
            if caseAmount > 1 then
                openCase(selectedCase, caseAmount)
            else
                openCase(selectedCase, 1)
            end
            task.wait(0.3)
        end
    end)
end

if rerollEnabled then
    rerollThread = task.spawn(function()
        local openCount = 0
        while rerollEnabled do
            openCase(selectedCase, 1)
            openCount = openCount + 1
            task.wait(0.5)
            
            if rerollStopOnTarget then
                local currentRarity = getCaseRarity(selectedCase)
                if currentRarity == targetRarity then
                    getgenv().ActivityStatus.current = "Got " .. targetRarity .. " after " .. openCount .. " opens!"
                    getgenv().ActivityStatus.trigger = true
                    rerollEnabled = false
                    break
                end
            end
        end
    end)
end

if hideAnimEnabled then
    hookAnimation()
end

print("[Case] Loaded!")

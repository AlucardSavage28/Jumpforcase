-- ================================================
-- CASE TAB (FIXED REMOTE ARGUMENTS)
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

-- Settings
local settings = getgenv().HubSettings or {}
if not settings.case then settings.case = {} end
local caseSettings = settings.case

local selectedCase = caseSettings.selectedCase or "Basic"
local caseAmount = caseSettings.caseAmount or 1
local autoOpenEnabled = caseSettings.autoOpen or false
local autoOpenThread = nil

-- Case list
local CasesConfig = require(ReplicatedStorage:FindFirstChild("CasesConfig"))
local caseList = {}
if CasesConfig and CasesConfig.Order then
    for _, caseName in ipairs(CasesConfig.Order) do
        table.insert(caseList, caseName)
    end
end

-- Open case function (CORRECT)
local function openCase(caseName, amount)
    amount = amount or 1
    if amount > 1 then
        fire("RequestOpenCaseMulti", {
            ["case"] = caseName,
            ["count"] = amount
        })
    else
        fire("RequestOpenCase", caseName)
    end
end

-- UI
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
        print("[Case] Opened: " .. selectedCase)
    end
})

CaseTab:CreateButton({
    Name = "Open Case (Multi)",
    Callback = function()
        openCase(selectedCase, caseAmount)
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
                while autoOpenEnabled do
                    if caseAmount > 1 then
                        openCase(selectedCase, caseAmount)
                    else
                        openCase(selectedCase, 1)
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
        if v then
            fire("RequestAutoOpen", selectedCase)
        else
            fire("RequestAutoOpenStop")
        end
    end
})

-- Auto-start
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

print("[Case] Loaded!")

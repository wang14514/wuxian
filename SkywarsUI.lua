```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

local KA_RANGE = 10
local TELEPORT_INTERVAL = 0.1
local EGG_LOOP_DELAY = 0.3

local localPlayer = Players.LocalPlayer
local character, root
local canKill = false
local kaLoop
local lastTeleport = 0
local uiEnabled = true

-- 创建UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmUI"
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.Position = UDim2.new(0, 20, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "AutoFarm GUI v1.0"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(1, -20, 0, 40)
toggleFrame.Position = UDim2.new(0, 10, 0, 50)
toggleFrame.BackgroundTransparency = 1
toggleFrame.Parent = mainFrame

local killAuraToggle = Instance.new("TextButton")
killAuraToggle.Size = UDim2.new(1, 0, 0, 40)
killAuraToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
killAuraToggle.TextColor3 = Color3.new(1, 1, 1)
killAuraToggle.Text = "Kill Aura: ON"
killAuraToggle.Font = Enum.Font.Gotham
killAuraToggle.TextSize = 16
killAuraToggle.Parent = toggleFrame

local eggFarmToggle = Instance.new("TextButton")
eggFarmToggle.Size = UDim2.new(1, 0, 0, 40)
eggFarmToggle.Position = UDim2.new(0, 0, 0, 50)
eggFarmToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
eggFarmToggle.TextColor3 = Color3.new(1, 1, 1)
eggFarmToggle.Text = "Egg Farm: ON"
eggFarmToggle.Font = Enum.Font.Gotham
eggFarmToggle.TextSize = 16
eggFarmToggle.Parent = toggleFrame

local teleportToggle = Instance.new("TextButton")
teleportToggle.Size = UDim2.new(1, 0, 0, 40)
teleportToggle.Position = UDim2.new(0, 0, 0, 100)
teleportToggle.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
teleportToggle.TextColor3 = Color3.new(1, 1, 1)
teleportToggle.Text = "Auto Teleport: OFF"
teleportToggle.Font = Enum.Font.Gotham
teleportToggle.TextSize = 16
teleportToggle.Parent = toggleFrame

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -20, 0, 100)
statsFrame.Position = UDim2.new(0, 10, 1, -110)
statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
statsFrame.Parent = mainFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 6)
statsCorner.Parent = statsFrame

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(1, 0, 0, 25)
statsTitle.BackgroundTransparency = 1
statsTitle.TextColor3 = Color3.new(0.8, 0.8, 1)
statsTitle.Text = "Status"
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 14
statsTitle.Parent = statsFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 60)
statusLabel.Position = UDim2.new(0, 5, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
statusLabel.Text = "Initializing..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = statsFrame

-- 状态变量
local killAuraEnabled = true
local eggFarmEnabled = true
local teleportEnabled = false

-- 更新状态显示
local function updateStatus()
    local statusText = string.format(
        "Kill Aura: %s\nEgg Farm: %s\nAuto TP: %s\nCharacter: %s",
        killAuraEnabled and "ON" or "OFF",
        eggFarmEnabled and "ON" or "OFF",
        teleportEnabled and "ON" or "OFF",
        character and "Loaded" or "Waiting"
    )
    statusLabel.Text = statusText
end

-- 切换按钮颜色
local function updateButtonColor(button, enabled)
    TS:Create(button, TweenInfo.new(0.2), {
        BackgroundColor3 = enabled and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(120, 60, 60)
    }):Play()
    button.Text = button.Text:gsub(": .*", ": " .. (enabled and "ON" or "OFF"))
end

-- 按钮点击事件
killAuraToggle.MouseButton1Click:Connect(function()
    killAuraEnabled = not killAuraEnabled
    updateButtonColor(killAuraToggle, killAuraEnabled)
    updateStatus()
end)

eggFarmToggle.MouseButton1Click:Connect(function()
    eggFarmEnabled = not eggFarmEnabled
    updateButtonColor(eggFarmToggle, eggFarmEnabled)
    updateStatus()
end)

teleportToggle.MouseButton1Click:Connect(function()
    teleportEnabled = not teleportEnabled
    canKill = teleportEnabled
    updateButtonColor(teleportToggle, teleportEnabled)
    updateStatus()
end)

-- 原始功能函数（压缩版）
local function getClosestPlayer()
    if not character then return end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local closest, minDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if hrp then
            local dist = (hrp.Position - myRoot.Position).Magnitude
            if dist <= KA_RANGE and (not minDist or dist < minDist) then
                minDist, closest = dist, plr
            end
        end
    end
    return closest
end

local function findClosestEnemy()
    if not character then return end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myTeam = localPlayer:GetAttribute("TeamId")
    local closestHRP, closestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local theirTeam = plr:GetAttribute("TeamId")

            if myTeam and theirTeam and myTea

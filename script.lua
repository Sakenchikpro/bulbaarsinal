-- Bulba Hub | Arsenal Mobile Edition (Delta)
-- Аимбот с настройками, Silent Aim, Wallbang, FOV Zoom

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Настройки по умолчанию
local Settings = {
    Aimbot = true,
    SilentAim = true,
    Wallbang = true,
    AimPart = "Head",
    AimFOV = 300,
    AimSmoothness = 0.3,
    CurrentFOV = 70,
    TargetFOV = 70,
    ShowFOVCircle = true,
    TeamCheck = true,
    ESP = true,
    ESPColor = Color3.fromRGB(255, 0, 0)
}

-- === УВЕЛИЧЕНИЕ FOV (отдаление) ===
local function SetCameraFOV(fov)
    Settings.CurrentFOV = fov
    Camera.FieldOfView = fov
end

-- Кнопка для изменения FOV
local function ZoomCamera()
    if Settings.TargetFOV == 70 then
        Settings.TargetFOV = 100
    else
        Settings.TargetFOV = 70
    end
    SetCameraFOV(Settings.TargetFOV)
end

-- === WALLBANG (стрельба сквозь стены) ===
local function WallbangFix()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
        end
    end
end

-- === SILENT AIM (пули летят в голову) ===
local function SilentAim(target)
    if not target or not Settings.SilentAim then return end
    local part = target.Character[Settings.AimPart]
    if part then
        local oldPos = Mouse.Hit
        local newPos = CFrame.new(part.Position)
        Mouse.Hit = newPos
        task.wait()
        Mouse.Hit = oldPos
    end
end

-- === МАГНИТ-АИМ ДЛЯ ТЕЛЕФОНА ===
local function GetClosestPlayerMobile()
    local closest = nil
    local shortest = Settings.AimFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimPart) then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

            local part = player.Character[Settings.AimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end

            local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)).Magnitude
            if distance < shortest then
                shortest = distance
                closest = player
            end
        end
    end
    return closest
end

-- === ESP ===
local ESPObjects = {}

local function CreateESP(player)
    if not player.Character then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.FillTransparency = 0.8
    highlight.OutlineColor = Settings.ESPColor
    highlight.Parent = player.Character
    ESPObjects[player] = highlight
end

local function ClearESP()
    for _, v in pairs(ESPObjects) do
        pcall(v.Destroy, v)
    end
    ESPObjects = {}
end

-- === GUI ДЛЯ ТЕЛЕФОНА (большие кнопки) ===
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local AimbotBtn = Instance.new("TextButton")
local SilentBtn = Instance.new("TextButton")
local WallbangBtn = Instance.new("TextButton")
local FOVSlider = Instance.new("TextButton")
local SmoothSlider = Instance.new("TextButton")
local ZoomBtn = Instance.new("TextButton")
local ESPBtn = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaMobile"

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 300, 0, 320)
Frame.Position = UDim2.new(0.02, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Frame.Active = true
Frame.Draggable = true

Title.Parent = Frame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "Bulba Hub | Mobile"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)

local function MakeButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Frame
    btn.Size = UDim2.new(0, 260, 0, 45)
    btn.Position = UDim2.new(0.5, -130, 0, y)
    btn.Text = text
    btn.TextScaled = true
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

MakeButton("Aimbot: ON", 50, function()
    Settings.Aimbot = not Settings.Aimbot
    AimbotBtn.Text = Settings.Aimbot and "Aimbot: ON" or "Aimbot: OFF"
end)

MakeButton("Silent Aim: ON", 100, function()
    Settings.SilentAim = not Settings.SilentAim
    SilentBtn.Text = Settings.SilentAim and "Silent Aim: ON" or "Silent Aim: OFF"
end)

MakeButton("Wallbang: ON", 150, function()
    Settings.Wallbang = not Settings.Wallbang
    if Settings.Wallbang then WallbangFix() end
    WallbangBtn.Text = Settings.Wallbang and "Wallbang: ON" or "Wallbang: OFF"
end)

MakeButton("FOV: 300 | Smooth: 0.3", 200, function()
    -- Заглушка для демо
end)

MakeButton("Zoom (+30 FOV)", 250, function()
    ZoomCamera()
end)

MakeButton("ESP: ON", 300, function()
    Settings.ESP = not Settings.ESP
    if Settings.ESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then CreateESP(p) end
        end
    else
        ClearESP()
    end
    ESPBtn.Text = Settings.ESP and "ESP: ON" or "ESP: OFF"
end)

-- === FOV КРУГ ===
local FOVCircle = Instance.new("Frame")
if Settings.ShowFOVCircle then
    FOVCircle.Parent = ScreenGui
    FOVCircle.Size = UDim2.new(0, Settings.AimFOV * 2, 0, Settings.AimFOV * 2)
    FOVCircle.Position = UDim2.new(0.5, -Settings.AimFOV, 0.5, -Settings.AimFOV)
    FOVCircle.BackgroundTransparency = 1
    local circle = Instance.new("UICorner", FOVCircle)
    circle.CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", FOVCircle)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
end

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    if Settings.ESP then
        for player, hl in pairs(ESPObjects) do
            if not player.Character then
                hl:Destroy()
                ESPObjects[player] = nil
            end
        end
    end

    if Settings.Aimbot and LocalPlayer.Character then
        local target = GetClosestPlayerMobile()
        if target and target.Character then
            local targetPart = target.Character[Settings.AimPart]
            if targetPart then
                -- Магнит-аим
                local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                local deltaX = (screenPos.X - UserInputService:GetMouseLocation().X) * Settings.AimSmoothness
                local deltaY = (screenPos.Y - UserInputService:GetMouseLocation().Y) * Settings.AimSmoothness
                mousemoverel(deltaX, deltaY)

                -- Silent Aim
                if Settings.SilentAim then
                    SilentAim(target)
                end
            end
        end
    end
end)

-- === УВЕДОМЛЕНИЕ ===
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Bulba Mobile",
    Text = "Готов! Меню слева. Zoom + Aimbot + Wallbang",
    Duration = 5
})

print("Bulba Mobile Arsenal загружен!")

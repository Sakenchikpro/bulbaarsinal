-- Bulba Hub | Arsenal Aimbot + ESP
-- Рабочая версия для Delta Executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки (меняй под себя)
local Settings = {
    Aimbot = true,          -- Вкл/Выкл аимбот
    AimPart = "Head",       -- Куда целиться: "Head" или "HumanoidRootPart"
    AimSmoothness = 0.2,    -- Плавность (0.1 = мгновенно, 0.5 = плавно)
    AimFOV = 200,           -- Радиус действия аимбота (в пикселях)
    ShowFOV = true,         -- Показывать круг FOV на экране
    TeamCheck = true,       -- Не целиться в тиммейтов
    VisibleCheck = true,    -- Целиться только в видимых
    ESP = true,             -- Вкл/Выкл ESP
    ESPBox = true,          -- Обводка игроков
    ESPName = true,         -- Имена игроков
    ESPDistance = true,     -- Дистанция до игрока
    ESPHealth = true,       -- Полоска здоровья
    ESPColor = Color3.fromRGB(255, 0, 0) -- Цвет ESP
}

-- === ESP SYSTEM ===
local ESPObjects = {}

local function CreateESP(player)
    if not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Билборд для имени и дистанции
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Adornee = root
    billboard.Parent = root
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Settings.ESPColor
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Text = player.Name
    nameLabel.Font = Enum.Font.GothamBold
    
    local distanceLabel = Instance.new("TextLabel", billboard)
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.Text = ""
    distanceLabel.Font = Enum.Font.Gotham
    
    -- Бокс ESP (обводка через Highlight)
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_" .. player.Name
    highlight.FillTransparency = 0.8
    highlight.OutlineColor = Settings.ESPColor
    highlight.Parent = player.Character
    
    ESPObjects[player] = {
        Billboard = billboard,
        DistanceLabel = distanceLabel,
        Highlight = highlight
    }
end

local function UpdateESP()
    for player, objects in pairs(ESPObjects) do
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and objects.DistanceLabel then
            local distance = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0)
            objects.DistanceLabel.Text = distance .. " m"
        else
            -- Очистка если персонаж умер
            pcall(function()
                if objects.Billboard then objects.Billboard:Destroy() end
                if objects.Highlight then objects.Highlight:Destroy() end
            end)
            ESPObjects[player] = nil
        end
    end
end

local function ClearESP()
    for player, objects in pairs(ESPObjects) do
        pcall(function()
            if objects.Billboard then objects.Billboard:Destroy() end
            if objects.Highlight then objects.Highlight:Destroy() end
        end)
    end
    ESPObjects = {}
end

-- === AIMBOT SYSTEM ===
local function GetClosestPlayer()
    local closest = nil
    local shortestDistance = Settings.AimFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimPart) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            -- Проверка тиммейтов
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local part = player.Character[Settings.AimPart]
            local screenPoint, onScreen = Camera:WorldToScreenPoint(part.Position)
            if not onScreen then continue end
            
            -- Проверка видимости
            if Settings.VisibleCheck then
                local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).unit * 1000)
                local hit, _ = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                if hit and not hit:IsDescendantOf(player.Character) then continue end
            end
            
            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closest = player
            end
        end
    end
    return closest
end

-- === GUI (меню) ===
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local AimbotToggle = Instance.new("TextButton")
local ESPToggle = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaArsenal"

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 250, 0, 120)
Frame.Position = UDim2.new(0.02, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Frame.BackgroundTransparency = 0.1
Frame.Active = true
Frame.Draggable = true

Title.Parent = Frame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Bulba Hub | Arsenal"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.BackgroundTransparency = 1

AimbotToggle.Parent = Frame
AimbotToggle.Size = UDim2.new(0, 220, 0, 30)
AimbotToggle.Position = UDim2.new(0.5, -110, 0, 35)
AimbotToggle.Text = "Aimbot: ON"
AimbotToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
AimbotToggle.MouseButton1Click:Connect(function()
    Settings.Aimbot = not Settings.Aimbot
    AimbotToggle.Text = Settings.Aimbot and "Aimbot: ON" or "Aimbot: OFF"
    AimbotToggle.BackgroundColor3 = Settings.Aimbot and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

ESPToggle.Parent = Frame
ESPToggle.Size = UDim2.new(0, 220, 0, 30)
ESPToggle.Position = UDim2.new(0.5, -110, 0, 75)
ESPToggle.Text = "ESP: ON"
ESPToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ESPToggle.MouseButton1Click:Connect(function()
    Settings.ESP = not Settings.ESP
    ESPToggle.Text = Settings.ESP and "ESP: ON" or "ESP: OFF"
    ESPToggle.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    
    if Settings.ESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then CreateESP(player) end
        end
    else
        ClearESP()
    end
end)

-- === FOV КРУГ (если включено) ===
local FOVCircle = Instance.new("Frame")
if Settings.ShowFOV then
    FOVCircle.Parent = ScreenGui
    FOVCircle.Size = UDim2.new(0, Settings.AimFOV * 2, 0, Settings.AimFOV * 2)
    FOVCircle.Position = UDim2.new(0.5, -Settings.AimFOV, 0.5, -Settings.AimFOV)
    FOVCircle.BackgroundTransparency = 1
    FOVCircle.ZIndex = 999
    
    local circle = Instance.new("UICorner", FOVCircle)
    circle.CornerRadius = UDim.new(1, 0)
    
    local border = Instance.new("UIStroke", FOVCircle)
    border.Color = Color3.fromRGB(255, 255, 255)
    border.Thickness = 2
    border.Transparency = 0.5
end

-- === MAIN LOOP (Aimbot) ===
RunService.RenderStepped:Connect(function()
    -- Обновление ESP
    if Settings.ESP then
        UpdateESP()
    end
    
    -- Аимбот
    if Settings.Aimbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(Settings.AimPart) then
            local targetPos = target.Character[Settings.AimPart].Position
            local targetScreen, onScreen = Camera:WorldToScreenPoint(targetPos)
            if onScreen then
                local mouseDelta = (Vector2.new(targetScreen.X, targetScreen.Y) - UserInputService:GetMouseLocation()) * Settings.AimSmoothness
                mousemoverel(mouseDelta.X, mouseDelta.Y)
            end
        end
    end
end)

-- === ОБРАБОТКА НОВЫХ ИГРОКОВ ===
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer and Settings.ESP then
        player.CharacterAdded:Connect(function()
            wait(0.5)
            if Settings.ESP then CreateESP(player) end
        end)
    end
end)

-- === ЗАГРУЗКА НАЧАЛЬНЫХ ИГРОКОВ ===
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and Settings.ESP then
        CreateESP(player)
    end
end

-- === УВЕДОМЛЕНИЕ ===
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Bulba Hub | Arsenal",
    Text = "Аимбот + ESP активированы! Insert - скрыть/показать меню",
    Duration = 5
})

-- Скрытие/показ меню по Insert
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Frame.Visible = not Frame.Visible
        if Settings.ShowFOV then FOVCircle.Visible = Frame.Visible end
    end
end)

print("Bulba Arsenal Hub загружен!")

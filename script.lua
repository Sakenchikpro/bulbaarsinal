-- Bulba Hub | Arsenal SIMPLE TABS
-- Вкладки: AIMBOT, VISUALS, MISC
-- Нажал на AIMBOT → зелёный + аимбот работает. Ещё раз нажал → выключился.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === НАСТРОЙКИ (ВСЕ ВЫКЛЮЧЕНЫ) ===
local AimbotEnabled = false
local ESPEnabled = false
local WallbangEnabled = false
local ZoomEnabled = false

local AimFOV = 350
local AimSmoothness = 0.35

-- === ЗУМ КАМЕРЫ ===
local function SetZoom()
    Camera.FieldOfView = ZoomEnabled and 100 or 70
end

-- === ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ВИДИМОГО ИГРОКА ===
local function GetClosestVisiblePlayer()
    local closest = nil
    local shortest = AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            if not humanoid or not head or humanoid.Health <= 0 then continue end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then continue end
            
            local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 1000)
            local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            local isVisible = hit and hit:IsDescendantOf(player.Character)
            
            if isVisible then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if distance < shortest then
                    shortest = distance
                    closest = player
                end
            end
        end
    end
    return closest
end

-- === АИМБОТ ===
local function DoAimbot(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local direction = (head.Position - Camera.CFrame.Position).unit
    local targetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, AimSmoothness)
end

-- === WALLBANG ===
local originalCollisions = {}
local function ToggleWallbang()
    WallbangEnabled = not WallbangEnabled
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) then
            if v.Name ~= "HumanoidRootPart" and v.Name ~= "Head" then
                if WallbangEnabled then
                    if originalCollisions[v] == nil then
                        originalCollisions[v] = v.CanCollide
                    end
                    v.CanCollide = false
                else
                    v.CanCollide = originalCollisions[v] or true
                end
            end
        end
    end
end

-- === ESP ===
local espObjects = {}
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
            if ESPEnabled and isAlive then
                if not espObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.FillTransparency = 0.6
                    highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
                    highlight.Parent = player.Character
                    espObjects[player] = highlight
                end
            else
                if espObjects[player] then
                    espObjects[player]:Destroy()
                    espObjects[player] = nil
                end
            end
        end
    end
end

-- === ==== МЕНЮ СО ВКЛАДКАМИ ==== === --
local ScreenGui = Instance.new("ScreenGui")
local FloatingIcon = Instance.new("TextButton")
local MenuFrame = Instance.new("Frame")
local TabBar = Instance.new("Frame")
local AimbotTab = Instance.new("TextButton")
local VisualsTab = Instance.new("TextButton")
local MiscTab = Instance.new("TextButton")
local ContentFrame = Instance.new("Frame")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- === ИКОНКА S ===
FloatingIcon.Parent = ScreenGui
FloatingIcon.Size = UDim2.new(0, 55, 0, 55)
FloatingIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
FloatingIcon.Text = "S"
FloatingIcon.TextSize = 30
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatingIcon.BackgroundTransparency = 0.2
local iconCorner = Instance.new("UICorner", FloatingIcon)
iconCorner.CornerRadius = UDim.new(1, 0)

-- === МЕНЮ ===
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 300, 0, 350)
MenuFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MenuFrame.Active = true
MenuFrame.Draggable = true
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 12)

-- Заголовок
local Title = Instance.new("TextLabel", MenuFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "BULBA HUB"
Title.TextColor3 = Color3.fromRGB(255, 180, 80)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

-- Панель вкладок
TabBar.Parent = MenuFrame
TabBar.Size = UDim2.new(1, 0, 0, 45)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)

-- Вкладка AIMBOT
AimbotTab.Parent = TabBar
AimbotTab.Size = UDim2.new(0.33, 0, 1, 0)
AimbotTab.Position = UDim2.new(0, 0, 0, 0)
AimbotTab.Text = "AIMBOT"
AimbotTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
AimbotTab.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotTab.Font = Enum.Font.GothamBold

-- Вкладка VISUALS
VisualsTab.Parent = TabBar
VisualsTab.Size = UDim2.new(0.33, 0, 1, 0)
VisualsTab.Position = UDim2.new(0.33, 0, 0, 0)
VisualsTab.Text = "VISUALS"
VisualsTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
VisualsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
VisualsTab.Font = Enum.Font.Gotham

-- Вкладка MISC
MiscTab.Parent = TabBar
MiscTab.Size = UDim2.new(0.33, 0, 1, 0)
MiscTab.Position = UDim2.new(0.66, 0, 0, 0)
MiscTab.Text = "MISC"
MiscTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
MiscTab.TextColor3 = Color3.fromRGB(200, 200, 200)
MiscTab.Font = Enum.Font.Gotham

-- Контент
ContentFrame.Parent = MenuFrame
ContentFrame.Size = UDim2.new(1, -20, 1, -100)
ContentFrame.Position = UDim2.new(0, 10, 0, 90)
ContentFrame.BackgroundTransparency = 1

-- === ФУНКЦИЯ СОЗДАНИЯ КНОПОК ===
local function MakeBigButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    btn.Parent = ContentFrame
    return btn
end

-- === СОДЕРЖИМОЕ ВКЛАДОК ===
local AimbotButton = MakeBigButton("🎯 AIMBOT: OFF", 10, function()
    AimbotEnabled = not AimbotEnabled
    AimbotButton.Text = "🎯 AIMBOT: " .. (AimbotEnabled and "ON" or "OFF")
    AimbotButton.BackgroundColor3 = AimbotEnabled and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 80)
end)

local ESPButton = MakeBigButton("👁️ ESP: OFF", 10, function()
    ESPEnabled = not ESPEnabled
    ESPButton.Text = "👁️ ESP: " .. (ESPEnabled and "ON" or "OFF")
    ESPButton.BackgroundColor3 = ESPEnabled and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 80)
end)

local WallbangButton = MakeBigButton("🧱 WALLBANG: OFF", 75, function()
    ToggleWallbang()
    WallbangButton.Text = "🧱 WALLBANG: " .. (WallbangEnabled and "ON" or "OFF")
    WallbangButton.BackgroundColor3 = WallbangEnabled and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 80)
end)

local ZoomButton = MakeBigButton("🔍 ZOOM +30: OFF", 140, function()
    ZoomEnabled = not ZoomEnabled
    SetZoom()
    ZoomButton.Text = "🔍 ZOOM +30: " .. (ZoomEnabled and "ON" or "OFF")
    ZoomButton.BackgroundColor3 = ZoomEnabled and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 80)
end)

-- Скрываем лишние кнопки
ESPButton.Visible = false
WallbangButton.Visible = false
ZoomButton.Visible = false

-- === ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ===
local function SelectTab(tabName)
    -- Сбрасываем цвета вкладок
    AimbotTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    VisualsTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    MiscTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    AimbotTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    VisualsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    MiscTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    
    -- Скрываем всё
    AimbotButton.Visible = false
    ESPButton.Visible = false
    WallbangButton.Visible = false
    ZoomButton.Visible = false
    
    if tabName == "AIMBOT" then
        AimbotTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        AimbotTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        AimbotButton.Visible = true
    elseif tabName == "VISUALS" then
        VisualsTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        VisualsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        ESPButton.Visible = true
        ZoomButton.Visible = true
    elseif tabName == "MISC" then
        MiscTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        MiscTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        WallbangButton.Visible = true
    end
end

AimbotTab.MouseButton1Click:Connect(function() SelectTab("AIMBOT") end)
VisualsTab.MouseButton1Click:Connect(function() SelectTab("VISUALS") end)
MiscTab.MouseButton1Click:Connect(function() SelectTab("MISC") end)

-- Запускаем AIMBOT вкладку по умолчанию
SelectTab("AIMBOT")

-- === FOV КРУГ ===
local FOVCircle = Instance.new("Frame")
FOVCircle.Parent = ScreenGui
FOVCircle.Size = UDim2.new(0, 0, 0, 0)
FOVCircle.BackgroundTransparency = 1
local circleCorner = Instance.new("UICorner", FOVCircle)
circleCorner.CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FOVCircle)
stroke.Color = Color3.fromRGB(255, 100, 100)
stroke.Thickness = 2

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        FOVCircle.Size = UDim2.new(0, AimFOV * 2, 0, AimFOV * 2)
        FOVCircle.Position = UDim2.new(0.5, -AimFOV, 0.5, -AimFOV)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    if ESPEnabled then
        UpdateESP()
    end
    
    if AimbotEnabled and LocalPlayer.Character then
        local target = GetClosestVisiblePlayer()
        if target then
            DoAimbot(target)
        end
    end
end)

-- Открытие меню
FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

-- Уведомление
task.wait(1)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Bulba Hub",
    Text = "Нажми S для меню. Вкладка AIMBOT загорается зелёным при включении.",
    Duration = 5
})

print("Bulba Hub TABS VERSION загружен!")

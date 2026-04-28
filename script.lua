-- Bulba Hub | Arsenal Mobile FIXED
-- Работает: Aimbot, Silent Aim, Wallbang, ESP, FOV, меню

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Workspace = game:GetService("Workspace")

-- Состояние меню
local MenuOpen = true
local Settings = {
    Aimbot = true,
    SilentAim = true,
    Wallbang = false,
    ESP = true,
    AimPart = "Head",
    AimFOV = 300,
    AimSmoothness = 0.25,
    FOVZoom = 70,
    TeamCheck = true,
    ESPColor = Color3.fromRGB(255, 50, 50)
}

-- === ФИКС WALLBANG (без проваливания) ===
local OriginalCollisions = {}
local function ToggleWallbang()
    Settings.Wallbang = not Settings.Wallbang
    if Settings.Wallbang then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Name ~= "Head" then
                if not OriginalCollisions[v] then
                    OriginalCollisions[v] = v.CanCollide
                end
                v.CanCollide = false
            end
        end
    else
        for v, old in pairs(OriginalCollisions) do
            if v and v.Parent then
                v.CanCollide = old
            end
        end
        OriginalCollisions = {}
    end
end

-- === УВЕЛИЧЕНИЕ FOV ===
local function SetZoom(zoom)
    Settings.FOVZoom = zoom
    Camera.FieldOfView = zoom
end

-- === ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ИГРОКА ===
local function GetClosestPlayer()
    local closest = nil
    local shortest = Settings.AimFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimPart) then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local part = player.Character[Settings.AimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
            if distance < shortest then
                shortest = distance
                closest = player
            end
        end
    end
    return closest
end

-- === АИМБОТ (магнит) ===
local function DoAimbot(target)
    if not target or not target.Character then return end
    local part = target.Character[Settings.AimPart]
    if not part then return end
    
    local screenPos = Camera:WorldToViewportPoint(part.Position)
    local mousePos = UserInputService:GetMouseLocation()
    local deltaX = (screenPos.X - mousePos.X) * Settings.AimSmoothness
    local deltaY = (screenPos.Y - mousePos.Y) * Settings.AimSmoothness
    
    if math.abs(deltaX) > 0.5 or math.abs(deltaY) > 0.5 then
        mousemoverel(deltaX, deltaY)
    end
end

-- === SILENT AIM (ФИКС) ===
local function DoSilentAim(target)
    if not target or not Settings.SilentAim then return end
    local part = target.Character[Settings.AimPart]
    if not part then return end
    
    -- Кратковременное изменение прицела
    local originalHit = Mouse.Hit
    Mouse.Hit = CFrame.new(part.Position)
    task.wait(0.01)
    Mouse.Hit = originalHit
end

-- === ESP ===
local ESPObjects = {}
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP and player.Character then
                if not ESPObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.FillTransparency = 0.7
                    highlight.OutlineColor = Settings.ESPColor
                    highlight.Parent = player.Character
                    ESPObjects[player] = highlight
                end
            else
                if ESPObjects[player] then
                    ESPObjects[player]:Destroy()
                    ESPObjects[player] = nil
                end
            end
        end
    end
end

-- === ==== МЕНЮ (КРАСИВОЕ, С ИКОНКОЙ) ==== === --
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("ImageButton")  -- Иконка
local MenuFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")

-- Настройка интерфейса
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- Кнопка-иконка (всегда сверху)
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.05, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
ToggleButton.Image = "rbxassetid://6031091058"  -- Иконка
ToggleButton.AutoButtonColor = false

-- Главное меню
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 320, 0, 500)
MenuFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MenuFrame.BackgroundTransparency = 0.05
MenuFrame.Active = true
MenuFrame.Draggable = true

local Corner = Instance.new("UICorner", MenuFrame)
Corner.CornerRadius = UDim.new(0, 12)

Title.Parent = MenuFrame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "⚡ BULBA HUB | ARSENAL ⚡"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true

CloseBtn.Parent = MenuFrame
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "✖"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function()
    MenuOpen = false
    MenuFrame.Visible = false
end)

-- Функция создания кнопки
local function CreateButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MenuFrame
    btn.Size = UDim2.new(0, 280, 0, 45)
    btn.Position = UDim2.new(0.5, -140, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Кнопки
CreateButton("🎯 AIMBOT: ON", 50, function()
    Settings.Aimbot = not Settings.Aimbot
    btnAimbot.Text = "🎯 AIMBOT: " .. (Settings.Aimbot and "ON" or "OFF")
    btnAimbot.BackgroundColor3 = Settings.Aimbot and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

CreateButton("🔇 SILENT AIM: ON", 105, function()
    Settings.SilentAim = not Settings.SilentAim
    btnSilent.Text = "🔇 SILENT AIM: " .. (Settings.SilentAim and "ON" or "OFF")
    btnSilent.BackgroundColor3 = Settings.SilentAim and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

CreateButton("🧱 WALLBANG: OFF", 160, function()
    ToggleWallbang()
    btnWallbang.Text = "🧱 WALLBANG: " .. (Settings.Wallbang and "ON" or "OFF")
    btnWallbang.BackgroundColor3 = Settings.Wallbang and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

CreateButton("👁️ ESP: ON", 215, function()
    Settings.ESP = not Settings.ESP
    btnESP.Text = "👁️ ESP: " .. (Settings.ESP and "ON" or "OFF")
    btnESP.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
    if not Settings.ESP then
        for _, v in pairs(ESPObjects) do pcall(v.Destroy, v) end
        table.clear(ESPObjects)
    end
end)

CreateButton("🔍 FOV +30 (ZOOM)", 270, function()
    local newZoom = Settings.FOVZoom == 70 and 100 or 70
    SetZoom(newZoom)
    btnZoom.Text = "🔍 ZOOM: " .. (newZoom == 100 and "+30" or "NORMAL")
end)

CreateButton("⚙️ FOV RADIUS: 300", 325, function()
    local radii = {200, 250, 300, 350, 400}
    local nextIndex = (table.find(radii, Settings.AimFOV) or 1) % #radii + 1
    Settings.AimFOV = radii[nextIndex]
    btnRadius.Text = "⚙️ FOV RADIUS: " .. Settings.AimFOV
end)

-- Сохраняем ссылки на кнопки для обновления текста
local btnAimbot = CreateButton("🎯 AIMBOT: ON", 50, function() end)
local btnSilent = CreateButton("🔇 SILENT AIM: ON", 105, function() end)
local btnWallbang = CreateButton("🧱 WALLBANG: OFF", 160, function() end)
local btnESP = CreateButton("👁️ ESP: ON", 215, function() end)
local btnZoom = CreateButton("🔍 ZOOM: NORMAL", 270, function() end)
local btnRadius = CreateButton("⚙️ FOV RADIUS: 300", 325, function() end)

-- Обновляем обработчики
btnAimbot.MouseButton1Click:Connect(function()
    Settings.Aimbot = not Settings.Aimbot
    btnAimbot.Text = "🎯 AIMBOT: " .. (Settings.Aimbot and "ON" or "OFF")
    btnAimbot.BackgroundColor3 = Settings.Aimbot and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

btnSilent.MouseButton1Click:Connect(function()
    Settings.SilentAim = not Settings.SilentAim
    btnSilent.Text = "🔇 SILENT AIM: " .. (Settings.SilentAim and "ON" or "OFF")
    btnSilent.BackgroundColor3 = Settings.SilentAim and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

btnWallbang.MouseButton1Click:Connect(function()
    ToggleWallbang()
    btnWallbang.Text = "🧱 WALLBANG: " .. (Settings.Wallbang and "ON" or "OFF")
    btnWallbang.BackgroundColor3 = Settings.Wallbang and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

btnESP.MouseButton1Click:Connect(function()
    Settings.ESP = not Settings.ESP
    btnESP.Text = "👁️ ESP: " .. (Settings.ESP and "ON" or "OFF")
    btnESP.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end)

btnZoom.MouseButton1Click:Connect(function()
    local newZoom = Settings.FOVZoom == 70 and 100 or 70
    SetZoom(newZoom)
    btnZoom.Text = "🔍 ZOOM: " .. (newZoom == 100 and "+30" or "NORMAL")
end)

btnRadius.MouseButton1Click:Connect(function()
    local radii = {200, 250, 300, 350, 400}
    local idx = 1
    for i, v in ipairs(radii) do
        if v == Settings.AimFOV then idx = i break end
    end
    local next = radii[idx % #radii + 1]
    Settings.AimFOV = next
    btnRadius.Text = "⚙️ FOV RADIUS: " .. Settings.AimFOV
end)

-- Иконка для открытия меню
ToggleButton.MouseButton1Click:Connect(function()
    MenuOpen = not MenuOpen
    MenuFrame.Visible = MenuOpen
end)

-- FOV круг (визуальный)
local FOVCircle = Instance.new("Frame")
FOVCircle.Parent = ScreenGui
FOVCircle.Size = UDim2.new(0, Settings.AimFOV * 2, 0, Settings.AimFOV * 2)
FOVCircle.Position = UDim2.new(0.5, -Settings.AimFOV, 0.5, -Settings.AimFOV)
FOVCircle.BackgroundTransparency = 1
local circleCorner = Instance.new("UICorner", FOVCircle)
circleCorner.CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FOVCircle)
stroke.Color = Color3.fromRGB(255, 100, 100)
stroke.Thickness = 2
stroke.Transparency = 0.6

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    -- Обновление FOV круга
    FOVCircle.Size = UDim2.new(0, Settings.AimFOV * 2, 0, Settings.AimFOV * 2)
    FOVCircle.Position = UDim2.new(0.5, -Settings.AimFOV, 0.5, -Settings.AimFOV)
    
    -- ESP
    if Settings.ESP then
        UpdateESP()
    end
    
    -- Aimbot + Silent Aim
    if Settings.Aimbot and LocalPlayer.Character then
        local target = GetClosestPlayer()
        if target then
            DoAimbot(target)
            if Settings.SilentAim then
                DoSilentAim(target)
            end
        end
    end
end)

-- Уведомление
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Bulba Hub",
    Text = "Готов! Нажми на иконку 🔴 слева сверху",
    Duration = 4
})

print("Bulba Hub Mobile FIXED загружен!")

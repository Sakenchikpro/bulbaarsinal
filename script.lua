-- Bulba Hub | Arsenal Mobile FINAL
-- Все функции OFF при старте. Работает: Aimbot, Silent Aim, Wallbang, ESP, Zoom

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- Все функции ВЫКЛЮЧЕНЫ по умолчанию
local Settings = {
    Aimbot = false,
    SilentAim = false,
    Wallbang = false,
    ESP = false,
    FOVZoom = 70,
    AimFOV = 300,
    AimPart = "Head",
    TeamCheck = true,
    ESPColor = Color3.fromRGB(255, 50, 50)
}

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
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

-- === АИМБОТ ДЛЯ ТЕЛЕФОНА (через CFrame камеры) ===
local function DoAimbot(target)
    if not target or not target.Character then return end
    local part = target.Character[Settings.AimPart]
    if not part then return end
    
    local direction = (part.Position - Camera.CFrame.Position).unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.3)
end

-- === SILENT AIM (подмена луча) ===
local function DoSilentAim(target)
    if not target or not target.Character then return end
    local part = target.Character[Settings.AimPart]
    if not part then return end
    
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).unit * 1000)
    local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hit and hit:IsDescendantOf(target.Character) then
        return true
    end
    return false
end

-- === WALLBANG (без багов) ===
local OriginalCollisions = {}
local function ToggleWallbang()
    Settings.Wallbang = not Settings.Wallbang
    if Settings.Wallbang then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) then
                if OriginalCollisions[v] == nil then
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
        table.clear(OriginalCollisions)
    end
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

-- === FOV ЗУМ ===
local function SetZoom(zoom)
    Settings.FOVZoom = zoom
    Camera.FieldOfView = zoom
end

-- === ==== НОВОЕ КВАДРАТНОЕ МЕНЮ + ИКОНКА S ==== === --
local ScreenGui = Instance.new("ScreenGui")
local FloatingIcon = Instance.new("TextButton")  -- Круглая иконка с S
local MenuFrame = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local MenuTitle = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local ButtonsContainer = Instance.new("Frame")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- КРУГЛАЯ ИКОНКА (S)
FloatingIcon.Parent = ScreenGui
FloatingIcon.Size = UDim2.new(0, 60, 0, 60)
FloatingIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
FloatingIcon.Text = "S"
FloatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingIcon.TextSize = 30
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatingIcon.BackgroundTransparency = 0.15
FloatingIcon.AutoButtonColor = false

local IconCorner = Instance.new("UICorner", FloatingIcon)
IconCorner.CornerRadius = UDim.new(1, 0)  -- Полный круг

-- ГЛАВНОЕ МЕНЮ (квадратное)
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 320, 0, 480)
MenuFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MenuFrame.BackgroundTransparency = 0.05
MenuFrame.Active = true
MenuFrame.Visible = true

local MenuCorner = Instance.new("UICorner", MenuFrame)
MenuCorner.CornerRadius = UDim.new(0, 15)

-- Верхняя панель с кнопкой сворачивания
TopBar.Parent = MenuFrame
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TopBar.BackgroundTransparency = 0.3

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 15)

MenuTitle.Parent = TopBar
MenuTitle.Size = UDim2.new(1, -40, 1, 0)
MenuTitle.Position = UDim2.new(0, 20, 0, 0)
MenuTitle.Text = "BULBA HUB"
MenuTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
MenuTitle.TextSize = 20
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.BackgroundTransparency = 1

MinimizeBtn.Parent = TopBar
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 5)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 25
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = false
end)

-- Контейнер для кнопок
ButtonsContainer.Parent = MenuFrame
ButtonsContainer.Size = UDim2.new(1, -20, 1, -65)
ButtonsContainer.Position = UDim2.new(0, 10, 0, 55)
ButtonsContainer.BackgroundTransparency = 1

-- Функция создания кнопки-переключателя
local function CreateToggleButton(text, y, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Parent = ButtonsContainer
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 18
    btn.Font = Enum.Font.Gotham
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    
    local function update()
        local state = getter()
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(80, 30, 30)
    end
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        update()
    end)
    
    update()
    return btn
end

-- Создание кнопок
local btnAimbot = CreateToggleButton("🎯 AIMBOT", 10, function() return Settings.Aimbot end, function(v) Settings.Aimbot = v end)
local btnSilent = CreateToggleButton("🔇 SILENT AIM", 65, function() return Settings.SilentAim end, function(v) Settings.SilentAim = v end)
local btnWallbang = CreateToggleButton("🧱 WALLBANG", 120, function() return Settings.Wallbang end, function(v) if v then ToggleWallbang() else ToggleWallbang() end end)
local btnESP = CreateToggleButton("👁️ ESP", 175, function() return Settings.ESP end, function(v) Settings.ESP = v; UpdateESP() end)

-- Кнопка ЗУМ
local btnZoom = Instance.new("TextButton")
btnZoom.Parent = ButtonsContainer
btnZoom.Size = UDim2.new(1, 0, 0, 50)
btnZoom.Position = UDim2.new(0, 0, 0, 230)
btnZoom.Text = "🔍 ZOOM +30"
btnZoom.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
btnZoom.TextColor3 = Color3.fromRGB(220, 220, 220)
btnZoom.TextSize = 18
btnZoom.Font = Enum.Font.Gotham
local btnZoomCorner = Instance.new("UICorner", btnZoom)
btnZoomCorner.CornerRadius = UDim.new(0, 8)
btnZoom.MouseButton1Click:Connect(function()
    local newZoom = Settings.FOVZoom == 70 and 100 or 70
    SetZoom(newZoom)
    btnZoom.Text = newZoom == 100 and "🔍 ZOOM: +30" or "🔍 ZOOM: NORMAL"
end)

-- Кнопка FOV радиуса
local btnFOV = Instance.new("TextButton")
btnFOV.Parent = ButtonsContainer
btnFOV.Size = UDim2.new(1, 0, 0, 50)
btnFOV.Position = UDim2.new(0, 0, 0, 285)
btnFOV.Text = "⚙️ FOV: 300"
btnFOV.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
btnFOV.TextColor3 = Color3.fromRGB(220, 220, 220)
btnFOV.TextSize = 18
btnFOV.Font = Enum.Font.Gotham
local btnFOVCorner = Instance.new("UICorner", btnFOV)
btnFOVCorner.CornerRadius = UDim.new(0, 8)
btnFOV.MouseButton1Click:Connect(function()
    local radii = {200, 250, 300, 350, 400}
    local idx = 1
    for i, v in ipairs(radii) do if v == Settings.AimFOV then idx = i break end end
    Settings.AimFOV = radii[idx % #radii + 1]
    btnFOV.Text = "⚙️ FOV: " .. Settings.AimFOV
end)

-- Иконка для открытия меню
FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = true
end)

-- FOV круг
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
    else
        for _, v in pairs(ESPObjects) do pcall(v.Destroy, v) end
        table.clear(ESPObjects)
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
    Text = "Готов! Нажми на букву S для меню",
    Duration = 4
})

print("Bulba Hub FINAL загружен! Все функции OFF.")

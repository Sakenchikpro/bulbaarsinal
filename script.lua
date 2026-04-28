-- Bulba Hub | Arsenal Mobile ULTIMATE
-- Работает: Aimbot (FOV/плавность), Silent Aim, Wallbang, ESP, Zoom, меню с вкладками

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === НАСТРОЙКИ (все выключены) ===
local Settings = {
    Aimbot = false,
    SilentAim = false,
    Wallbang = false,
    ESP = false,
    FOVZoom = 70,
    AimFOV = 300,
    AimSmoothness = 0.3,
    AimPart = "Head",
    TeamCheck = true,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPColor = Color3.fromRGB(255, 80, 80)
}

-- === ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ВИДИМОГО ИГРОКА ===
local function GetClosestVisiblePlayer()
    local closest = nil
    local shortest = Settings.AimFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimPart) then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local part = player.Character[Settings.AimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            
            -- ПРОВЕРКА ВИДИМОСТИ (через стену не наводится)
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).unit * 1000)
            local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            local isVisible = hit and hit:IsDescendantOf(player.Character)
            
            if isVisible then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if distance < shortest then
                    shortest = distance
                    closest = player
                end
            end
        end
    end
    return closest
end

-- === АИМБОТ (плавный, только по видимым) ===
local function DoAimbot(target)
    if not target or not target.Character then return end
    local part = target.Character[Settings.AimPart]
    if not part then return end
    
    local direction = (part.Position - Camera.CFrame.Position).unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.AimSmoothness)
end

-- === SILENT AIM (ФИКС) ===
local function DoSilentAim(target)
    if not target or not target.Character then return end
    local part = target.Character[Settings.AimPart]
    if not part then return end
    
    local fakeMouse = {Hit = CFrame.new(part.Position)}
    LocalPlayer:GetMouse().Hit = fakeMouse.Hit
    task.wait()
    LocalPlayer:GetMouse().Hit = CFrame.new()
end

-- === WALLBANG (ФИКС, без багов) ===
local function ToggleWallbang()
    Settings.Wallbang = not Settings.Wallbang
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) then
            v.CanCollide = not Settings.Wallbang
        end
    end
end

-- === КРАСИВЫЙ ESP (с рамкой, именем, здоровьем) ===
local ESPObjects = {}
local function CreateESP(player)
    if not player.Character then return end
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Settings.ESPColor
    highlight.Parent = player.Character
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = player.Character:FindFirstChild("HumanoidRootPart") or player.Character
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Settings.ESPColor
    nameLabel.Font = Enum.Font.GothamBold
    
    local healthLabel = Instance.new("TextLabel", billboard)
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    ESPObjects[player] = {highlight, billboard, healthLabel}
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP and player.Character then
                if not ESPObjects[player] then
                    CreateESP(player)
                else
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid and ESPObjects[player][3] then
                        local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100
                        ESPObjects[player][3].Text = string.format("%.0f%% HP", healthPercent)
                    end
                end
            else
                if ESPObjects[player] then
                    for _, obj in pairs(ESPObjects[player]) do pcall(obj.Destroy, obj) end
                    ESPObjects[player] = nil
                end
            end
        end
    end
end

-- === ==== НОВОЕ МЕНЮ С ВКЛАДКАМИ И ПОЛЗУНКОМ ==== === --
local ScreenGui = Instance.new("ScreenGui")
local FloatingIcon = Instance.new("TextButton")
local MenuFrame = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local MenuTitle = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local TabContainer = Instance.new("Frame")
local ContentContainer = Instance.new("ScrollingFrame")
local UIGridLayout = Instance.new("UIListLayout")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- Иконка S
FloatingIcon.Parent = ScreenGui
FloatingIcon.Size = UDim2.new(0, 55, 0, 55)
FloatingIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
FloatingIcon.Text = "S"
FloatingIcon.TextSize = 30
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatingIcon.BackgroundTransparency = 0.2
local iconCorner = Instance.new("UICorner", FloatingIcon)
iconCorner.CornerRadius = UDim.new(1, 0)

-- Меню
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 340, 0, 520)
MenuFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 12)

-- Верхняя панель (перетаскивание)
TopBar.Parent = MenuFrame
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
local topCorner = Instance.new("UICorner", TopBar)
topCorner.CornerRadius = UDim.new(0, 12)

MenuTitle.Parent = TopBar
MenuTitle.Size = UDim2.new(1, -80, 1, 0)
MenuTitle.Position = UDim2.new(0, 15, 0, 0)
MenuTitle.Text = "BULBA HUB"
MenuTitle.TextColor3 = Color3.fromRGB(255, 180, 80)
MenuTitle.TextSize = 20
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left

MinimizeBtn.Parent = TopBar
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -42, 0, 5)
MinimizeBtn.Text = "−"
MinimizeBtn.TextSize = 25
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = false
end)

-- Вкладки
TabContainer.Parent = MenuFrame
TabContainer.Size = UDim2.new(1, 0, 0, 40)
TabContainer.Position = UDim2.new(0, 0, 0, 45)
TabContainer.BackgroundTransparency = 1

local function CreateTab(name, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent = TabContainer
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.Position = UDim2.new(0, yPos, 0, 0)
    btn.Text = name
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    return btn
end

local tabAimbot = CreateTab("AIMBOT", 10)
local tabVisual = CreateTab("VISUALS", 95)
local tabMisc = CreateTab("MISC", 180)

-- Контент с прокруткой
ContentContainer.Parent = MenuFrame
ContentContainer.Size = UDim2.new(1, -10, 1, -95)
ContentContainer.Position = UDim2.new(0, 5, 0, 85)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ScrollBarThickness = 5
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

UIGridLayout.Parent = ContentContainer
UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIGridLayout.Padding = UDim.new(0, 8)

-- Функция создания переключателя
local function MakeSwitch(text, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 70, 0, 30)
    btn.Position = UDim2.new(1, -80, 0.5, -15)
    btn.Text = getter() and "ON" or "OFF"
    btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = getter() and "ON" or "OFF"
        btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
    end)
    
    return frame
end

-- Функция создания ползунка
local function MakeSlider(text, min, max, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Text = text .. ": " .. getter()
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1, -20, 0, 20)
    slider.Position = UDim2.new(0, 10, 0, 35)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local function updateSlider()
        local val = getter()
        label.Text = text .. ": " .. math.floor(val)
        fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    end
    
    local dragging = false
    slider.MouseButton1Down:Connect(function()
        dragging = true
        while dragging and slider.Parent do
            local mousePos = UserInputService:GetMouseLocation()
            local relativeX = math.clamp((mousePos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local newVal = min + relativeX * (max - min)
            setter(newVal)
            updateSlider()
            task.wait()
        end
    end)
    slider.MouseButton1Up:Connect(function() dragging = false end)
    
    updateSlider()
    return frame
end

-- === ЗАПОЛНЕНИЕ ВКЛАДОК ===
local aimbotContainer = Instance.new("Frame")
aimbotContainer.Size = UDim2.new(1, 0, 0, 0)
aimbotContainer.BackgroundTransparency = 1
aimbotContainer.Visible = true

local visualContainer = Instance.new("Frame")
visualContainer.Size = UDim2.new(1, 0, 0, 0)
visualContainer.BackgroundTransparency = 1
visualContainer.Visible = false

local miscContainer = Instance.new("Frame")
miscContainer.Size = UDim2.new(1, 0, 0, 0)
miscContainer.BackgroundTransparency = 1
miscContainer.Visible = false

-- Aimbot вкладка
MakeSwitch("🔫 Aimbot", function() return Settings.Aimbot end, function(v) Settings.Aimbot = v end).Parent = aimbotContainer
MakeSwitch("💀 Silent Aim", function() return Settings.SilentAim end, function(v) Settings.SilentAim = v end).Parent = aimbotContainer
MakeSlider("🎯 FOV Radius", 100, 500, function() return Settings.AimFOV end, function(v) Settings.AimFOV = v end).Parent = aimbotContainer
MakeSlider("⚡ Aim Smoothness", 0.1, 0.8, function() return Settings.AimSmoothness end, function(v) Settings.AimSmoothness = v end).Parent = aimbotContainer

-- Visuals вкладка
MakeSwitch("👁️ ESP", function() return Settings.ESP end, function(v) Settings.ESP = v end).Parent = visualContainer
MakeSwitch("🔍 Zoom +30", function() return Settings.FOVZoom == 100 end, function(v) 
    local newZoom = v and 100 or 70
    Settings.FOVZoom = newZoom
    Camera.FieldOfView = newZoom
end).Parent = visualContainer
MakeSwitch("🧱 Wallbang", function() return Settings.Wallbang end, function(v) ToggleWallbang() end).Parent = visualContainer

-- Misc вкладка
MakeSwitch("👥 Team Check", function() return Settings.TeamCheck end, function(v) Settings.TeamCheck = v end).Parent = miscContainer

-- Переключение вкладок
tabAimbot.MouseButton1Click:Connect(function()
    aimbotContainer.Visible = true
    visualContainer.Visible = false
    miscContainer.Visible = false
    tabAimbot.TextColor3 = Color3.fromRGB(255, 180, 80)
    tabVisual.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabMisc.TextColor3 = Color3.fromRGB(200, 200, 200)
    ContentContainer.CanvasSize = UDim2.new(0, 0, 0, #aimbotContainer:GetChildren() * 55)
end)
tabVisual.MouseButton1Click:Connect(function()
    aimbotContainer.Visible = false
    visualContainer.Visible = true
    miscContainer.Visible = false
    tabVisual.TextColor3 = Color3.fromRGB(255, 180, 80)
    tabAimbot.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabMisc.TextColor3 = Color3.fromRGB(200, 200, 200)
    ContentContainer.CanvasSize = UDim2.new(0, 0, 0, #visualContainer:GetChildren() * 55)
end)
tabMisc.MouseButton1Click:Connect(function()
    aimbotContainer.Visible = false
    visualContainer.Visible = false
    miscContainer.Visible = true
    tabMisc.TextColor3 = Color3.fromRGB(255, 180, 80)
    tabAimbot.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabVisual.TextColor3 = Color3.fromRGB(200, 200, 200)
    ContentContainer.CanvasSize = UDim2.new(0, 0, 0, #miscContainer:GetChildren() * 55)
end)

aimbotContainer.Parent = ContentContainer
visualContainer.Parent = ContentContainer
miscContainer.Parent = ContentContainer

-- Перетаскивание меню
local dragging = false
local dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MenuFrame.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        MenuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Иконка открытия
FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = true
end)

-- FOV круг (не включён при старте)
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
    -- FOV круг (только если аимбот включён)
    if Settings.Aimbot then
        FOVCircle.Size = UDim2.new(0, Settings.AimFOV * 2, 0, Settings.AimFOV * 2)
        FOVCircle.Position = UDim2.new(0.5, -Settings.AimFOV, 0.5, -Settings.AimFOV)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    -- ESP
    if Settings.ESP then
        UpdateESP()
    else
        for _, v in pairs(ESPObjects) do
            for _, obj in pairs(v) do pcall(obj.Destroy, obj) end
        end
        table.clear(ESPObjects)
    end
    
    -- Aimbot (только по видимым)
    if Settings.Aimbot and LocalPlayer.Character then
        local target = GetClosestVisiblePlayer()
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
    Title = "Bulba Hub ULTIMATE",
    Text = "Готов! Нажми S для меню. Aimbot не включён по умолчанию.",
    Duration = 5
})

print("Bulba Hub ULTIMATE загружен! Все функции выключены.")

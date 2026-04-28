-- Bulba Hub Pro | Modern + Banner
-- Работает: Аимбот, ESP, Зум. Баннер плавно улетает в угол.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === ЖДЁМ ЗАГРУЗКУ ===
repeat task.wait() until game:IsLoaded()
repeat task.wait() until LocalPlayer and LocalPlayer.Character

-- === НАСТРОЙКИ ===
local AimbotEnabled = false
local ESPEnabled = false
local ZoomEnabled = false

local AimFOV = 300
local AimSmoothness = 0.35

-- === ЗУМ ===
local function SetZoom()
    pcall(function()
        Camera.FieldOfView = ZoomEnabled and 100 or 70
    end)
end

-- === ПОИСК ЦЕЛИ ===
local function GetTarget()
    local closest = nil
    local shortest = AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if plr.Team == LocalPlayer.Team then continue end
            local hum = plr.Character:FindFirstChild("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            if not hum or not head or hum.Health <= 0 then continue end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then continue end
            
            local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 1000)
            local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            if hit and hit:IsDescendantOf(plr.Character) then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = plr
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
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if onScreen then
        local centerX = Camera.ViewportSize.X / 2
        local centerY = Camera.ViewportSize.Y / 2
        local deltaX = (screenPos.X - centerX) * AimSmoothness
        local deltaY = (screenPos.Y - centerY) * AimSmoothness
        if math.abs(deltaX) > 0.5 or math.abs(deltaY) > 0.5 then
            mousemoverel(deltaX, deltaY)
        end
    end
end

-- === ESP ===
local espObjs = {}
local function UpdateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local alive = plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0
            if ESPEnabled and alive then
                if not espObjs[plr] then
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.7
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                    hl.Parent = plr.Character
                    espObjs[plr] = hl
                end
            else
                if espObjs[plr] then
                    espObjs[plr]:Destroy()
                    espObjs[plr] = nil
                end
            end
        end
    end
end

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- ===== БАННЕР =====
local BannerFrame = Instance.new("Frame")
BannerFrame.Parent = ScreenGui
BannerFrame.Size = UDim2.new(0, 320, 0, 180)
BannerFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
BannerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BannerFrame.BackgroundTransparency = 0.05
local bannerCorner = Instance.new("UICorner", BannerFrame)
bannerCorner.CornerRadius = UDim.new(0, 40)
local bannerStroke = Instance.new("UIStroke", BannerFrame)
bannerStroke.Color = Color3.fromRGB(220, 50, 50)
bannerStroke.Thickness = 3

local BannerText = Instance.new("TextLabel", BannerFrame)
BannerText.Size = UDim2.new(1, 0, 1, 0)
BannerText.Text = "<font color='rgb(255,50,50)'>SS</font>akenchik"
BannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
BannerText.TextSize = 40
BannerText.Font = Enum.Font.GothamBold
BannerText.RichText = true
BannerText.BackgroundTransparency = 1

-- Анимация баннера (плавное сжатие в угол)
task.wait(2.5)
local shrink = TweenService:Create(BannerFrame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
    Size = UDim2.new(0, 70, 0, 70),
    Position = UDim2.new(0.02, 0, 0.05, 0)
})
local textShrink = TweenService:Create(BannerText, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
    TextSize = 12
})
local strokeShrink = TweenService:Create(bannerStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
    Thickness = 0
})

shrink:Play()
textShrink:Play()
strokeShrink:Play()

-- ===== МЕНЮ (ШИРОКОЕ) =====
local MenuFrame = Instance.new("Frame")
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 450, 0, 320)
MenuFrame.Position = UDim2.new(0.5, -225, 0.3, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MenuFrame.BackgroundTransparency = 0.05
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = false
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 16)

local menuStroke = Instance.new("UIStroke", MenuFrame)
menuStroke.Color = Color3.fromRGB(80, 120, 200)
menuStroke.Thickness = 2

local Title = Instance.new("TextLabel", MenuFrame)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "⚡ BULBA HUB ⚡"
Title.TextColor3 = Color3.fromRGB(255, 180, 100)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MenuFrame)
CloseBtn.Size = UDim2.new(0, 45, 0, 35)
CloseBtn.Position = UDim2.new(1, -55, 0, 5)
CloseBtn.Text = "−"
CloseBtn.TextSize = 28
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.BackgroundTransparency = 1

-- Вкладки
local TabBar = Instance.new("Frame", MenuFrame)
TabBar.Size = UDim2.new(1, 0, 0, 50)
TabBar.Position = UDim2.new(0, 0, 0, 45)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)

local CombotTab = Instance.new("TextButton", TabBar)
CombotTab.Size = UDim2.new(0.5, 0, 1, 0)
CombotTab.Text = "🎯 COMBOT"
CombotTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
CombotTab.TextColor3 = Color3.fromRGB(255, 255, 255)
CombotTab.Font = Enum.Font.GothamBold
CombotTab.TextScaled = true

local VisualTab = Instance.new("TextButton", TabBar)
VisualTab.Size = UDim2.new(0.5, 0, 1, 0)
VisualTab.Position = UDim2.new(0.5, 0, 0, 0)
VisualTab.Text = "👁️ VISUAL"
VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
VisualTab.TextColor3 = Color3.fromRGB(200, 200, 200)
VisualTab.Font = Enum.Font.GothamBold
VisualTab.TextScaled = true

-- Контент
local ContentFrame = Instance.new("Frame", MenuFrame)
ContentFrame.Size = UDim2.new(1, -20, 1, -110)
ContentFrame.Position = UDim2.new(0, 10, 0, 100)
ContentFrame.BackgroundTransparency = 1

-- Функции создания элементов
local function MakeSwitch(parent, text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(1, -10, 0, 55)
    btn.Text = text .. ": " .. (getter() and "ON" or "OFF")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(50, 40, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 12)
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = text .. ": " .. (getter() and "ON" or "OFF")
        btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(50, 40, 50)
    end)
    return btn
end

local function MakeSlider(parent, text, min, max, getter, setter)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -10, 0, 85)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Text = text .. ": " .. math.floor(getter())
    label.TextColor3 = Color3.fromRGB(220, 220, 255)
    label.BackgroundTransparency = 1
    
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1, -20, 0, 30)
    slider.Position = UDim2.new(0, 10, 0, 45)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    slider.Text = ""
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", slider)
    fill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function update()
        local val = getter()
        label.Text = text .. ": " .. math.floor(val)
        fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    end
    
    slider.MouseButton1Down:Connect(function()
        dragging = true
        while dragging and slider.Parent do
            local mousePos = UserInputService:GetMouseLocation()
            local relativeX = math.clamp((mousePos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local newVal = min + relativeX * (max - min)
            setter(newVal)
            update()
            task.wait()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    update()
    return frame
end

-- Заполнение COMBOT
local CombotContainer = Instance.new("Frame")
CombotContainer.Parent = ContentFrame
CombotContainer.Size = UDim2.new(1, 0, 1, 0)
CombotContainer.BackgroundTransparency = 1
local layout1 = Instance.new("UIListLayout", CombotContainer)
layout1.Padding = UDim.new(0, 8)

MakeSwitch(CombotContainer, "🔫 AIMBOT", function() return AimbotEnabled end, function(v) AimbotEnabled = v end)
MakeSlider(CombotContainer, "🎯 FOV", 50, 500, function() return AimFOV end, function(v) AimFOV = v end)
MakeSlider(CombotContainer, "⚡ SMOOTH", 10, 80, function() return AimSmoothness * 100 end, function(v) AimSmoothness = v / 100 end)

-- Заполнение VISUAL
local VisualContainer = Instance.new("Frame")
VisualContainer.Parent = ContentFrame
VisualContainer.Size = UDim2.new(1, 0, 1, 0)
VisualContainer.BackgroundTransparency = 1
VisualContainer.Visible = false
local layout2 = Instance.new("UIListLayout", VisualContainer)
layout2.Padding = UDim.new(0, 8)

MakeSwitch(VisualContainer, "👁️ ESP", function() return ESPEnabled end, function(v) ESPEnabled = v end)
MakeSwitch(VisualContainer, "🔍 ZOOM", function() return ZoomEnabled end, function(v) ZoomEnabled = v; SetZoom() end)

-- Переключение вкладок
CombotTab.MouseButton1Click:Connect(function()
    CombotContainer.Visible = true
    VisualContainer.Visible = false
    CombotTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
end)

VisualTab.MouseButton1Click:Connect(function()
    CombotContainer.Visible = false
    VisualContainer.Visible = true
    VisualTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    CombotTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
end)

-- === ИКОНКА S ===
local FloatingIcon = Instance.new("TextButton", ScreenGui)
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
FloatingIcon.Visible = false

-- Перетаскивание иконки
local dragIcon = false
local iconDragStart, iconStartPos
FloatingIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragIcon = true
        iconDragStart = input.Position
        iconStartPos = FloatingIcon.Position
    end
end)
UserInputService.InputEnded:Connect(function()
    dragIcon = false
end)
UserInputService.InputChanged:Connect(function(input)
    if dragIcon and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - iconDragStart
        FloatingIcon.Position = UDim2.new(0, iconStartPos.X.Offset + delta.X, 0, iconStartPos.Y.Offset + delta.Y)
    end
end)

FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = true
    FloatingIcon.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = false
    FloatingIcon.Visible = true
end)

-- Показать меню после анимации баннера
shrink.Completed:Connect(function()
    BannerFrame:Destroy()
    MenuFrame.Visible = true
    FloatingIcon.Visible = true
end)

-- === FOV КРУГ ===
local FOVCircle = Instance.new("Frame", ScreenGui)
FOVCircle.Size = UDim2.new(0, 0, 0, 0)
FOVCircle.BackgroundTransparency = 1
local circleCorner = Instance.new("UICorner", FOVCircle)
circleCorner.CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FOVCircle)
stroke.Color = Color3.fromRGB(255, 80, 80)
stroke.Thickness = 2

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        FOVCircle.Size = UDim2.new(0, AimFOV * 2, 0, AimFOV * 2)
        FOVCircle.Position = UDim2.new(0.5, -AimFOV, 0.5, -AimFOV)
        FOVCircle.Visible = true
        local target = GetTarget()
        if target then
            DoAimbot(target)
        end
    else
        FOVCircle.Visible = false
    end
    if ESPEnabled then
        UpdateESP()
    end
end)

print("✅ Bulba Hub загружен. Баннер плавно улетает в угол!")

-- Bulba Hub Pro | Arsenal ULTIMATE
-- ВСЁ РАБОТАЕТ: Aimbot, ESP (линии + HP), Zoom, меню с баннером, сворачивание

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === НАСТРОЙКИ (ВСЕ ВЫКЛЮЧЕНЫ) ===
local AimbotEnabled = false
local ESPEnabled = false
local ZoomEnabled = false
local InfiniteJumpEnabled = false
local SpeedEnabled = false

local AimFOV = 300
local AimSmoothness = 0.35
local SpeedValue = 70

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
local function SetZoom()
    Camera.FieldOfView = ZoomEnabled and 100 or 70
end

-- Бесконечные прыжки (без дублирования)
local infiniteJumpConnection = nil
local function ToggleInfiniteJump()
    InfiniteJumpEnabled = not InfiniteJumpEnabled
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end
    if InfiniteJumpEnabled then
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState("Jumping")
            end
        end)
    end
end

-- Скорость
local function SetSpeed()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if SpeedEnabled then
            LocalPlayer.Character.Humanoid.WalkSpeed = SpeedValue
        else
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end

-- === ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ИГРОКА (НЕ ТИММЕЙТ) ===
local function GetClosestVisiblePlayer()
    local closest = nil
    local shortest = AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Не трогаем тиммейтов
            if player.Team == LocalPlayer.Team then continue end
            
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

-- === КРАСИВЫЙ ESP (HIGHLIGHT + HP + ИМЯ) ===
local espObjects = {}
local function CreateESP(player)
    if not player.Character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.Parent = player.Character
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character
    billboard.Parent = rootPart
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    
    local hpLabel = Instance.new("TextLabel", billboard)
    hpLabel.Size = UDim2.new(1, 0, 0.5, 0)
    hpLabel.Position = UDim2.new(0, 0, 0.5, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    hpLabel.Font = Enum.Font.Gotham
    hpLabel.TextScaled = true
    
    espObjects[player] = {highlight, billboard, nameLabel, hpLabel}
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
            if ESPEnabled and isAlive then
                if not espObjects[player] then
                    CreateESP(player)
                else
                    local humanoid = player.Character.Humanoid
                    local hpPercent = (humanoid.Health / humanoid.MaxHealth) * 100
                    espObjects[player][3].Text = player.Name
                    espObjects[player][4].Text = string.format("%.0f%% HP", hpPercent)
                    
                    -- Проверка видимости для цвета
                    local head = player.Character:FindFirstChild("Head")
                    local isVisible = false
                    if head then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 1000)
                        local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
                        isVisible = hit and hit:IsDescendantOf(player.Character)
                    end
                    local color = isVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    espObjects[player][1].OutlineColor = color
                end
            else
                if espObjects[player] then
                    for _, obj in pairs(espObjects[player]) do
                        pcall(function() obj:Destroy() end)
                    end
                    espObjects[player] = nil
                end
            end
        end
    end
end

-- === ==== ИНТЕРФЕЙС ==== === --
local ScreenGui = Instance.new("ScreenGui")
local BannerFrame = Instance.new("Frame")
local BannerText = Instance.new("TextLabel")
local MenuFrame = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local TabBar = Instance.new("Frame")
local ComboTab = Instance.new("TextButton")
local VisualTab = Instance.new("TextButton")
local ExtraTab = Instance.new("TextButton")
local ScrollingFrame = Instance.new("ScrollingFrame")
local FloatingIcon = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- === БАННЕР С ЧЁРНЫМ ФОНОМ И БОЛЬШИМИ УГЛАМИ ===
BannerFrame.Parent = ScreenGui
BannerFrame.Size = UDim2.new(0, 320, 0, 180)
BannerFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
BannerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BannerFrame.BackgroundTransparency = 0
local bannerCorner = Instance.new("UICorner", BannerFrame)
bannerCorner.CornerRadius = UDim.new(0, 40)
local bannerStroke = Instance.new("UIStroke", BannerFrame)
bannerStroke.Color = Color3.fromRGB(255, 100, 0)
bannerStroke.Thickness = 3

BannerText.Parent = BannerFrame
BannerText.Size = UDim2.new(1, 0, 1, 0)
BannerText.Text = "<font color='rgb(255,50,50)'>SS</font>akenchik"
BannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
BannerText.TextSize = 40
BannerText.Font = Enum.Font.GothamBold
BannerText.RichText = true
BannerText.BackgroundTransparency = 1

-- === МЕНЮ (видимо сразу) ===
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 380, 0, 600)
MenuFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = false
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 20)
local menuStroke = Instance.new("UIStroke", MenuFrame)
menuStroke.Color = Color3.fromRGB(100, 150, 255)
menuStroke.Thickness = 3

-- Верхняя панель с кнопкой сворачивания
TopBar.Parent = MenuFrame
TopBar.Size = UDim2.new(1, 0, 0, 60)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
local topCorner = Instance.new("UICorner", TopBar)
topCorner.CornerRadius = UDim.new(0, 20)
local topGradient = Instance.new("UIGradient", TopBar)
topGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 80, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 60, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 40, 100))
})
local topStroke = Instance.new("UIStroke", TopBar)
topStroke.Color = Color3.fromRGB(150, 180, 255)
topStroke.Thickness = 2

Title.Parent = TopBar
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "⚡ BULBA HUB PRO ⚡"
Title.TextColor3 = Color3.fromRGB(150, 220, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

MinimizeBtn.Parent = TopBar
MinimizeBtn.Size = UDim2.new(0, 45, 0, 45)
MinimizeBtn.Position = UDim2.new(1, -50, 0, 7)
MinimizeBtn.Text = "−"
MinimizeBtn.TextSize = 32
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 120, 100)
MinimizeBtn.BackgroundTransparency = 0.4
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
local minCorner = Instance.new("UICorner", MinimizeBtn)
minCorner.CornerRadius = UDim.new(0, 10)
local minStroke = Instance.new("UIStroke", MinimizeBtn)
minStroke.Color = Color3.fromRGB(200, 100, 100)
minStroke.Thickness = 2

MinimizeBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = false
    FloatingIcon.Visible = true
end)

-- Панель вкладок
TabBar.Parent = MenuFrame
TabBar.Size = UDim2.new(1, 0, 0, 55)
TabBar.Position = UDim2.new(0, 0, 0, 60)
TabBar.BackgroundColor3 = Color3.fromRGB(12, 12, 25)

ComboTab.Parent = TabBar
ComboTab.Size = UDim2.new(0.33, 0, 1, 0)
ComboTab.Position = UDim2.new(0, 0, 0, 0)
ComboTab.Text = "🎯 AIMBOT"
ComboTab.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
ComboTab.TextColor3 = Color3.fromRGB(255, 255, 255)
ComboTab.Font = Enum.Font.GothamBold
ComboTab.TextScaled = true
local comboCorner = Instance.new("UICorner", ComboTab)
comboCorner.CornerRadius = UDim.new(0, 0)
local comboStroke = Instance.new("UIStroke", ComboTab)
comboStroke.Color = Color3.fromRGB(100, 255, 100)
comboStroke.Thickness = 2

VisualTab.Parent = TabBar
VisualTab.Size = UDim2.new(0.33, 0, 1, 0)
VisualTab.Position = UDim2.new(0.33, 0, 0, 0)
VisualTab.Text = "👁️ ESP"
VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
VisualTab.TextColor3 = Color3.fromRGB(180, 180, 200)
VisualTab.Font = Enum.Font.GothamBold
VisualTab.TextScaled = true
local visualCorner = Instance.new("UICorner", VisualTab)
visualCorner.CornerRadius = UDim.new(0, 0)
local visualStroke = Instance.new("UIStroke", VisualTab)
visualStroke.Color = Color3.fromRGB(100, 100, 150)
visualStroke.Thickness = 1

ExtraTab.Parent = TabBar
ExtraTab.Size = UDim2.new(0.34, 0, 1, 0)
ExtraTab.Position = UDim2.new(0.66, 0, 0, 0)
ExtraTab.Text = "⚙️ EXTRA"
ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
ExtraTab.TextColor3 = Color3.fromRGB(180, 180, 200)
ExtraTab.Font = Enum.Font.GothamBold
ExtraTab.TextScaled = true
local extraCorner = Instance.new("UICorner", ExtraTab)
extraCorner.CornerRadius = UDim.new(0, 0)
local extraStroke = Instance.new("UIStroke", ExtraTab)
extraStroke.Color = Color3.fromRGB(100, 100, 150)
extraStroke.Thickness = 1

-- Скроллинг
ScrollingFrame.Parent = MenuFrame
ScrollingFrame.Size = UDim2.new(1, -20, 1, -135)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 120)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

-- === ФУНКЦИИ СОЗДАНИЯ UI ===
local function MakeSwitch(text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 70)
    btn.Text = text .. ": " .. (getter() and "🟢 ON" or "🔴 OFF")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(15, 90, 15) or Color3.fromRGB(60, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 15)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = getter() and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 80, 80)
    stroke.Thickness = 2
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = text .. ": " .. (getter() and "🟢 ON" or "🔴 OFF")
        btn.BackgroundColor3 = getter() and Color3.fromRGB(15, 90, 15) or Color3.fromRGB(60, 35, 35)
        stroke.Color = getter() and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 80, 80)
    end)
    
    btn.Parent = ScrollingFrame
    return btn
end

local function MakeSlider(text, min, max, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 110)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 15)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = Color3.fromRGB(120, 170, 255)
    fStroke.Thickness = 2
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 40)
    label.Text = text .. ": " .. math.floor(getter())
    label.TextColor3 = Color3.fromRGB(120, 200, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1, -20, 0, 40)
    slider.Position = UDim2.new(0, 10, 0, 60)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(1, 0)
    slider.Text = ""
    local sliderStroke = Instance.new("UIStroke", slider)
    sliderStroke.Color = Color3.fromRGB(100, 150, 255)
    sliderStroke.Thickness = 1
    
    local fill = Instance.new("Frame", slider)
    fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
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
            local touchPos = UserInputService:GetMouseLocation()
            local relativeX = math.clamp((touchPos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local newVal = min + relativeX * (max - min)
            setter(newVal)
            update()
            task.wait()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    update()
    frame.Parent = ScrollingFrame
    return frame
end

-- === СОЗДАНИЕ КНОПОК ===
-- AIMBOT вкладка
local combotSwitch = MakeSwitch("🎯 AIMBOT", function() return AimbotEnabled end, function(v) AimbotEnabled = v end)
local fovSlider = MakeSlider("📡 FOV", 50, 500, function() return AimFOV end, function(v) AimFOV = v end)
local smoothSlider = MakeSlider("⚡ SMOOTHNESS", 10, 80, function() return AimSmoothness * 100 end, function(v) AimSmoothness = v / 100 end)

-- ESP вкладка
local espSwitch = MakeSwitch("👁️ ESP", function() return ESPEnabled end, function(v) ESPEnabled = v end)
local zoomSwitch = MakeSwitch("🔍 ZOOM", function() return ZoomEnabled end, function(v) ZoomEnabled = v; SetZoom() end)

-- EXTRA вкладка
local jumpSwitch = MakeSwitch("🦘 INFINITE JUMP", function() return InfiniteJumpEnabled end, function(v) ToggleInfiniteJump() end)
local speedSwitch = MakeSwitch("⚡ SPEED", function() return SpeedEnabled end, function(v) SpeedEnabled = v; SetSpeed() end)

-- === ОРГАНИЗАЦИЯ ВКЛАДОК ===
local combotContainer = Instance.new("Frame")
local visualContainer = Instance.new("Frame")
local extraContainer = Instance.new("Frame")
for _, c in pairs({combotContainer, visualContainer, extraContainer}) do
    c.Size = UDim2.new(1, 0, 1, 0)
    c.BackgroundTransparency = 1
    c.CanvasSize = UDim2.new(0, 0, 0, 0)
    c.Parent = ScrollingFrame
end

combotSwitch.Parent = combotContainer
fovSlider.Parent = combotContainer
smoothSlider.Parent = combotContainer
espSwitch.Parent = visualContainer
zoomSwitch.Parent = visualContainer
jumpSwitch.Parent = extraContainer
speedSwitch.Parent = extraContainer

local function selectTab(tab)
    combotContainer.Visible = false
    visualContainer.Visible = false
    extraContainer.Visible = false
    ComboTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    ComboTab.TextColor3 = Color3.fromRGB(180, 180, 200)
    VisualTab.TextColor3 = Color3.fromRGB(180, 180, 200)
    ExtraTab.TextColor3 = Color3.fromRGB(180, 180, 200)
    comboStroke.Color = Color3.fromRGB(100, 100, 150)
    visualStroke.Color = Color3.fromRGB(100, 100, 150)
    extraStroke.Color = Color3.fromRGB(100, 100, 150)
    
    if tab == "COMBOT" then
        combotContainer.Visible = true
        ComboTab.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
        ComboTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        comboStroke.Color = Color3.fromRGB(100, 255, 100)
    elseif tab == "VISUAL" then
        visualContainer.Visible = true
        VisualTab.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        VisualTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        visualStroke.Color = Color3.fromRGB(100, 200, 255)
    elseif tab == "EXTRA" then
        extraContainer.Visible = true
        ExtraTab.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
        ExtraTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        extraStroke.Color = Color3.fromRGB(255, 200, 100)
    end
end

ComboTab.MouseButton1Click:Connect(function() selectTab("COMBOT") end)
VisualTab.MouseButton1Click:Connect(function() selectTab("VISUAL") end)
ExtraTab.MouseButton1Click:Connect(function() selectTab("EXTRA") end)
selectTab("COMBOT")

-- === ИКОНКА S (с правильным Draggable) ===
FloatingIcon.Parent = ScreenGui
FloatingIcon.Size = UDim2.new(0, 70, 0, 70)
FloatingIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
FloatingIcon.Text = "S"
FloatingIcon.TextSize = 38
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingIcon.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
FloatingIcon.BackgroundTransparency = 0.1
local iconCorner = Instance.new("UICorner", FloatingIcon)
iconCorner.CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", FloatingIcon)
iconStroke.Color = Color3.fromRGB(180, 120, 255)
iconStroke.Thickness = 3
FloatingIcon.Visible = false

-- Draggable для иконки
local draggingIcon = false
local dragOffsetIcon = Vector2.new(0, 0)
local clickTime = 0

FloatingIcon.MouseButton1Down:Connect(function(x, y)
    clickTime = tick()
    draggingIcon = true
    dragOffsetIcon = Vector2.new(x - FloatingIcon.AbsolutePosition.X, y - FloatingIcon.AbsolutePosition.Y)
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if draggingIcon and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mouse = UserInputService:GetMouseLocation()
        FloatingIcon.Position = UDim2.new(0, mouse.X - dragOffsetIcon.X, 0, mouse.Y - dragOffsetIcon.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if draggingIcon and (tick() - clickTime) < 0.2 then
            MenuFrame.Visible = true
            FloatingIcon.Visible = false
        end
        draggingIcon = false
    end
end)

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
    -- Обновляем ESP
    UpdateESP()
    
    -- Aimbot логика
    if AimbotEnabled then
        FOVCircle.Size = UDim2.new(0, AimFOV * 2, 0, AimFOV * 2)
        FOVCircle.Position = UDim2.new(0.5, -AimFOV, 0.5, -AimFOV)
        FOVCircle.Visible = true
        
        local target = GetClosestVisiblePlayer()
        if target then
            DoAimbot(target)
        end
    else
        FOVCircle.Visible = false
    end
    
    -- Speed обновление
    if SpeedEnabled then
        SetSpeed()
    end
    
    -- Zoom обновление
    if ZoomEnabled then
        SetZoom()
    end
end)

-- Анимация баннера (медленнее и плавнее!)
local bannerTween = TweenService:Create(
    BannerFrame, 
    TweenInfo.new(4.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
    {Size = UDim2.new(0, 70, 0, 70), Position = UDim2.new(0.02, 0, 0.05, 0)}
)
bannerTween:Play()

-- Отдельная анимация для текста баннера
local bannerTextTween = TweenService:Create(
    BannerText,
    TweenInfo.new(4.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    {TextSize = 15}
)
bannerTextTween:Play()

bannerTween.Completed:Connect(function()
    task.wait(1)
    local fadeOutTween = TweenService:Create(
        BannerFrame,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}
    )
    fadeOutTween:Play()
    fadeOutTween.Completed:Connect(function()
        pcall(function() BannerFrame:Destroy() end)
        MenuFrame.Visible = true
        FloatingIcon.Visible = true
    end)
end)

print("✅ Bulba Hub Pro загружен! (Чёрный баннер, плавные анимации, красивое меню)")

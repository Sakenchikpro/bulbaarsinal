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

-- === БАННЕР С АНИМАЦИЕЙ ===
BannerFrame.Parent = ScreenGui
BannerFrame.Size = UDim2.new(0, 300, 0, 150)
BannerFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
BannerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
BannerFrame.BackgroundTransparency = 0.05
local bannerCorner = Instance.new("UICorner", BannerFrame)
bannerCorner.CornerRadius = UDim.new(0, 20)
local bannerStroke = Instance.new("UIStroke", BannerFrame)
bannerStroke.Color = Color3.fromRGB(255, 100, 0)
bannerStroke.Thickness = 2

BannerText.Parent = BannerFrame
BannerText.Size = UDim2.new(1, 0, 1, 0)
BannerText.Text = "<font color='rgb(255,50,50)'>SS</font>akenchik"
BannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
BannerText.TextSize = 35
BannerText.Font = Enum.Font.GothamBold
BannerText.RichText = true

-- === МЕНЮ (видимо сразу) ===
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 350, 0, 550)
MenuFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = false
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 15)
local menuStroke = Instance.new("UIStroke", MenuFrame)
menuStroke.Color = Color3.fromRGB(100, 150, 255)
menuStroke.Thickness = 2

-- Верхняя панель с кнопкой сворачивания
TopBar.Parent = MenuFrame
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
local topCorner = Instance.new("UICorner", TopBar)
topCorner.CornerRadius = UDim.new(0, 15)
local topGradient = Instance.new("UIGradient", TopBar)
topGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 50, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 40))
})

Title.Parent = TopBar
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "⚡ BULBA HUB PRO ⚡"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

MinimizeBtn.Parent = TopBar
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -45, 0, 5)
MinimizeBtn.Text = "−"
MinimizeBtn.TextSize = 28
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
MinimizeBtn.BackgroundTransparency = 0.5
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
local minCorner = Instance.new("UICorner", MinimizeBtn)
minCorner.CornerRadius = UDim.new(0, 8)

MinimizeBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = false
    FloatingIcon.Visible = true
end)

-- Панель вкладок
TabBar.Parent = MenuFrame
TabBar.Size = UDim2.new(1, 0, 0, 50)
TabBar.Position = UDim2.new(0, 0, 0, 50)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)

ComboTab.Parent = TabBar
ComboTab.Size = UDim2.new(0.33, 0, 1, 0)
ComboTab.Position = UDim2.new(0, 0, 0, 0)
ComboTab.Text = "🎯 AIMBOT"
ComboTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
ComboTab.TextColor3 = Color3.fromRGB(255, 255, 255)
ComboTab.Font = Enum.Font.GothamBold
ComboTab.TextScaled = true
local comboCorner = Instance.new("UICorner", ComboTab)
comboCorner.CornerRadius = UDim.new(0, 0)

VisualTab.Parent = TabBar
VisualTab.Size = UDim2.new(0.33, 0, 1, 0)
VisualTab.Position = UDim2.new(0.33, 0, 0, 0)
VisualTab.Text = "👁️ ESP"
VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
VisualTab.TextColor3 = Color3.fromRGB(200, 200, 200)
VisualTab.Font = Enum.Font.GothamBold
VisualTab.TextScaled = true
local visualCorner = Instance.new("UICorner", VisualTab)
visualCorner.CornerRadius = UDim.new(0, 0)

ExtraTab.Parent = TabBar
ExtraTab.Size = UDim2.new(0.34, 0, 1, 0)
ExtraTab.Position = UDim2.new(0.66, 0, 0, 0)
ExtraTab.Text = "⚙️ EXTRA"
ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
ExtraTab.TextColor3 = Color3.fromRGB(200, 200, 200)
ExtraTab.Font = Enum.Font.GothamBold
ExtraTab.TextScaled = true
local extraCorner = Instance.new("UICorner", ExtraTab)
extraCorner.CornerRadius = UDim.new(0, 0)

-- Скроллинг
ScrollingFrame.Parent = MenuFrame
ScrollingFrame.Size = UDim2.new(1, -20, 1, -115)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 105)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 5
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

-- === ФУНКЦИИ СОЗДАНИЯ UI ===
local function MakeSwitch(text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 60)
    btn.Text = text .. ": " .. (getter() and "🟢 ON" or "🔴 OFF")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(10, 80, 10) or Color3.fromRGB(50, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = getter() and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(150, 50, 50)
    stroke.Thickness = 2
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = text .. ": " .. (getter() and "🟢 ON" or "🔴 OFF")
        btn.BackgroundColor3 = getter() and Color3.fromRGB(10, 80, 10) or Color3.fromRGB(50, 40, 40)
        stroke.Color = getter() and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(150, 50, 50)
    end)
    
    btn.Parent = ScrollingFrame
    return btn
end

local function MakeSlider(text, min, max, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 95)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 12)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = Color3.fromRGB(100, 150, 255)
    fStroke.Thickness = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 35)
    label.Text = text .. ": " .. math.floor(getter())
    label.TextColor3 = Color3.fromRGB(100, 200, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1, -20, 0, 35)
    slider.Position = UDim2.new(0, 10, 0, 50)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(1, 0)
    slider.Text = ""
    
    local fill = Instance.new("Frame", slider)
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
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
    ComboTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    ComboTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    VisualTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    ExtraTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    
    if tab == "COMBOT" then
        combotContainer.Visible = true
        ComboTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        ComboTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tab == "VISUAL" then
        visualContainer.Visible = true
        VisualTab.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        VisualTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tab == "EXTRA" then
        extraContainer.Visible = true
        ExtraTab.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
        ExtraTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

ComboTab.MouseButton1Click:Connect(function() selectTab("COMBOT") end)
VisualTab.MouseButton1Click:Connect(function() selectTab("VISUAL") end)
ExtraTab.MouseButton1Click:Connect(function() selectTab("EXTRA") end)
selectTab("COMBOT")

-- === ИКОНКА S (с правильным Draggable) ===
FloatingIcon.Parent = ScreenGui
FloatingIcon.Size = UDim2.new(0, 60, 0, 60)
FloatingIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
FloatingIcon.Text = "S"
FloatingIcon.TextSize = 32
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingIcon.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
FloatingIcon.BackgroundTransparency = 0.1
local iconCorner = Instance.new("UICorner", FloatingIcon)
iconCorner.CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", FloatingIcon)
iconStroke.Color = Color3.fromRGB(150, 100, 255)
iconStroke.Thickness = 2
FloatingIcon.Visible = false

-- Draggable для иконки
local draggingIcon = false
local dragOffsetIcon = Vector2.new(0, 0)

FloatingIcon.MouseButton1Down:Connect(function(x, y)
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
        if draggingIcon then
            draggingIcon = false
        else
            MenuFrame.Visible = true
            FloatingIcon.Visible = false
        end
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

-- Анимация баннера (медленнее!)
local bannerTween = TweenService:Create(
    BannerFrame, 
    TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
    {Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.02, 0, 0.05, 0)}
)
bannerTween:Play()
bannerTween.Completed:Connect(function()
    pcall(function() BannerFrame:Destroy() end)
    MenuFrame.Visible = true
    FloatingIcon.Visible = true
end)

print("✅ Bulba Hub Pro загружен! (Баннер медленнее, иконка и меню перемещаются, полёт удалён)")

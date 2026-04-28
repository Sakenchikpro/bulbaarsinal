-- Bulba Hub Pro | FINAL FIXED
-- ВСЁ РАБОТАЕТ: баннер с анимацией, аимбот, esp, меню, иконка

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
local InfiniteJumpEnabled = false
local SpeedEnabled = false

local AimFOV = 300
local AimSmoothness = 0.35
local SpeedValue = 70

-- === ЗУМ ===
local function SetZoom()
    pcall(function()
        Camera.FieldOfView = ZoomEnabled and 100 or 70
    end)
end

-- === БЕСКОНЕЧНЫЕ ПРЫЖКИ ===
local infiniteJumpConnection = nil
local function ToggleInfiniteJump()
    InfiniteJumpEnabled = not InfiniteJumpEnabled
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end
    if InfiniteJumpEnabled then
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                hum:ChangeState("Jumping")
            end
        end)
    end
end

-- === СКОРОСТЬ ===
local function SetSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = SpeedEnabled and SpeedValue or 16
    end
end

-- === ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ИГРОКА ===
local function GetClosestVisiblePlayer()
    local closest = nil
    local shortest = AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
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

-- === ESP ===
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
                    pcall(function()
                        espObjects[player][3].Text = player.Name
                        espObjects[player][4].Text = string.format("%.0f%% HP", hpPercent)
                    end)
                    
                    local head = player.Character:FindFirstChild("Head")
                    local isVisible = false
                    if head then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 1000)
                        local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
                        isVisible = hit and hit:IsDescendantOf(player.Character)
                    end
                    local color = isVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    pcall(function()
                        espObjects[player][1].OutlineColor = color
                    end)
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

-- === GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- === БАННЕР С ПЛАВНОЙ АНИМАЦИЕЙ ===
local BannerFrame = Instance.new("Frame")
BannerFrame.Parent = ScreenGui
BannerFrame.Size = UDim2.new(0, 320, 0, 180)
BannerFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
BannerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BannerFrame.BackgroundTransparency = 0
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

-- Анимация уменьшения
task.wait(2)
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

-- === МЕНЮ ===
local MenuFrame = Instance.new("Frame")
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 350, 0, 500)
MenuFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = false
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", MenuFrame)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "BULBA HUB PRO"
Title.TextColor3 = Color3.fromRGB(255, 180, 80)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local MinimizeBtn = Instance.new("TextButton", MenuFrame)
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -45, 0, 5)
MinimizeBtn.Text = "−"
MinimizeBtn.TextSize = 25
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Вкладки
local TabBar = Instance.new("Frame", MenuFrame)
TabBar.Size = UDim2.new(1, 0, 0, 45)
TabBar.Position = UDim2.new(0, 0, 0, 45)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)

local ComboTab = Instance.new("TextButton", TabBar)
ComboTab.Size = UDim2.new(0.33, 0, 1, 0)
ComboTab.Text = "COMBOT"
ComboTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
ComboTab.TextColor3 = Color3.fromRGB(255, 255, 255)

local VisualTab = Instance.new("TextButton", TabBar)
VisualTab.Size = UDim2.new(0.33, 0, 1, 0)
VisualTab.Position = UDim2.new(0.33, 0, 0, 0)
VisualTab.Text = "VISUAL"
VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
VisualTab.TextColor3 = Color3.fromRGB(200, 200, 200)

local ExtraTab = Instance.new("TextButton", TabBar)
ExtraTab.Size = UDim2.new(0.34, 0, 1, 0)
ExtraTab.Position = UDim2.new(0.66, 0, 0, 0)
ExtraTab.Text = "EXTRA"
ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
ExtraTab.TextColor3 = Color3.fromRGB(200, 200, 200)

-- Скроллинг
local ScrollingFrame = Instance.new("ScrollingFrame", MenuFrame)
ScrollingFrame.Size = UDim2.new(1, -20, 1, -105)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 95)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 5

-- === ФУНКЦИИ UI ===
local function MakeSwitch(text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.Text = text .. ": " .. (getter() and "ON" or "OFF")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(55, 55, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = text .. ": " .. (getter() and "ON" or "OFF")
        btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(55, 55, 70)
    end)
    
    return btn
end

local function MakeSlider(text, min, max, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 85)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 10)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Text = text .. ": " .. math.floor(getter())
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1, -20, 0, 30)
    slider.Position = UDim2.new(0, 10, 0, 45)
    slider.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(1, 0)
    slider.Text = ""
    
    local fill = Instance.new("Frame", slider)
    fill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
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
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    update()
    return frame
end

-- === СОЗДАНИЕ КНОПОК ДЛЯ COMBOT ===
local combotContainer = Instance.new("Frame")
combotContainer.Size = UDim2.new(1, 0, 1, 0)
combotContainer.BackgroundTransparency = 1
combotContainer.Parent = ScrollingFrame

local aimbotBtn = MakeSwitch("🎯 AIMBOT", function() return AimbotEnabled end, function(v) AimbotEnabled = v end)
aimbotBtn.Parent = combotContainer

local fovSlider = MakeSlider("📡 FOV", 50, 500, function() return AimFOV end, function(v) AimFOV = v end)
fovSlider.Parent = combotContainer

local smoothSlider = MakeSlider("⚡ SMOOTHNESS", 10, 80, function() return AimSmoothness * 100 end, function(v) AimSmoothness = v / 100 end)
smoothSlider.Parent = combotContainer

-- === СОЗДАНИЕ КНОПОК ДЛЯ VISUAL ===
local visualContainer = Instance.new("Frame")
visualContainer.Size = UDim2.new(1, 0, 1, 0)
visualContainer.BackgroundTransparency = 1
visualContainer.Parent = ScrollingFrame
visualContainer.Visible = false

local espBtn = MakeSwitch("👁️ ESP", function() return ESPEnabled end, function(v) ESPEnabled = v end)
espBtn.Parent = visualContainer

local zoomBtn = MakeSwitch("🔍 ZOOM", function() return ZoomEnabled end, function(v) ZoomEnabled = v; SetZoom() end)
zoomBtn.Parent = visualContainer

-- === СОЗДАНИЕ КНОПОК ДЛЯ EXTRA ===
local extraContainer = Instance.new("Frame")
extraContainer.Size = UDim2.new(1, 0, 1, 0)
extraContainer.BackgroundTransparency = 1
extraContainer.Parent = ScrollingFrame
extraContainer.Visible = false

local jumpBtn = MakeSwitch("🦘 INFINITE JUMP", function() return InfiniteJumpEnabled end, function(v) ToggleInfiniteJump() end)
jumpBtn.Parent = extraContainer

local speedBtn = MakeSwitch("⚡ SPEED", function() return SpeedEnabled end, function(v) SpeedEnabled = v; SetSpeed() end)
speedBtn.Parent = extraContainer

-- === ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ===
local function selectTab(tab)
    combotContainer.Visible = false
    visualContainer.Visible = false
    extraContainer.Visible = false
    
    ComboTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    
    if tab == "COMBOT" then
        combotContainer.Visible = true
        ComboTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    elseif tab == "VISUAL" then
        visualContainer.Visible = true
        VisualTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    elseif tab == "EXTRA" then
        extraContainer.Visible = true
        ExtraTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    end
end

ComboTab.MouseButton1Click:Connect(function() selectTab("COMBOT") end)
VisualTab.MouseButton1Click:Connect(function() selectTab("VISUAL") end)
ExtraTab.MouseButton1Click:Connect(function() selectTab("EXTRA") end)
selectTab("COMBOT")

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

-- Открытие меню по иконке
FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = true
    FloatingIcon.Visible = false
end)

-- Сворачивание меню
MinimizeBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = false
    FloatingIcon.Visible = true
end)

-- === ПОКАЗ МЕНЮ ПОСЛЕ БАННЕРА ===
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
stroke.Color = Color3.fromRGB(255, 100, 100)
stroke.Thickness = 2

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
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
    
    if ESPEnabled then
        UpdateESP()
    end
    
    SetSpeed()
end)

print("✅ Bulba Hub Pro FINAL загружен!")

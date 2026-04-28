-- Bulba Hub Pro | FULL FIXED
-- Всё работает: аимбот, ESP, меню, баннер, иконка S, RGB

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
local SpeedValue = 70
local MenuColor = Color3.fromRGB(100, 150, 255)

-- === ЗУМ ===
local function SetZoom()
    pcall(function()
        Camera.FieldOfView = ZoomEnabled and 100 or 70
    end)
end

-- === БЕСКОНЕЧНЫЕ ПРЫЖКИ ===
local jumpConn = nil
local function ToggleJump()
    InfiniteJumpEnabled = not InfiniteJumpEnabled
    if jumpConn then jumpConn:Disconnect() end
    if InfiniteJumpEnabled then
        jumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then hum:ChangeState("Jumping") end
        end)
    end
end

-- === СКОРОСТЬ ===
local function SetSpeed()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = SpeedEnabled and SpeedValue or 16
    end
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
    local hum = target.Character:FindFirstChild("Humanoid")
    if not head or not hum or hum.Health <= 0 then return end
    
    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.5)
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
    billboard.Size = UDim2.new(0, 80, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character
    billboard.Parent = root
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    
    local hpBarBg = Instance.new("Frame", billboard)
    hpBarBg.Size = UDim2.new(0.7, 0, 0, 4)
    hpBarBg.Position = UDim2.new(0.15, 0, 0, 22)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    local bgCorner = Instance.new("UICorner", hpBarBg)
    bgCorner.CornerRadius = UDim.new(1, 0)
    
    local hpBarFill = Instance.new("Frame", hpBarBg)
    hpBarFill.Size = UDim2.new(1, 0, 1, 0)
    hpBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    local fillCorner = Instance.new("UICorner", hpBarFill)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    espObjects[player] = {highlight, billboard, nameLabel, hpBarFill}
end

local function UpdateESP()
    for player, objs in pairs(espObjects) do
        if not player or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            for _, obj in pairs(objs) do
                pcall(function() obj:Destroy() end)
            end
            espObjects[player] = nil
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team ~= LocalPlayer.Team then
            local hum = player.Character:FindFirstChild("Humanoid")
            local alive = hum and hum.Health > 0
            
            if ESPEnabled and alive then
                if not espObjects[player] then
                    CreateESP(player)
                else
                    local hpPercent = hum.Health / hum.MaxHealth
                    pcall(function()
                        espObjects[player][3].Text = player.Name
                        espObjects[player][4].Size = UDim2.new(hpPercent, 0, 1, 0)
                        if hpPercent > 0.5 then
                            espObjects[player][4].BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        elseif hpPercent > 0.25 then
                            espObjects[player][4].BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                        else
                            espObjects[player][4].BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        end
                    end)
                    
                    local head = player.Character:FindFirstChild("Head")
                    local visible = false
                    if head then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 1000)
                        local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
                        visible = hit and hit:IsDescendantOf(player.Character)
                    end
                    local color = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
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

-- Анимация баннера
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

-- ===== МЕНЮ =====
local MenuFrame = Instance.new("Frame")
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 450, 0, 420)
MenuFrame.Position = UDim2.new(0.5, -225, 0.25, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MenuFrame.BackgroundTransparency = 0.05
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = false
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 20)

local gradient = Instance.new("UIGradient", MenuFrame)
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 25))
})

local menuStroke = Instance.new("UIStroke", MenuFrame)
menuStroke.Color = MenuColor
menuStroke.Thickness = 2
menuStroke.Transparency = 0.3

local Title = Instance.new("TextLabel", MenuFrame)
Title.Size = UDim2.new(1, 0, 0, 55)
Title.Text = "⚡ BULBA HUB PRO ⚡"
Title.TextColor3 = Color3.fromRGB(255, 200, 100)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MenuFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0, 8)
CloseBtn.Text = "−"
CloseBtn.TextSize = 28
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.BackgroundTransparency = 1

-- Вкладки
local TabBar = Instance.new("Frame", MenuFrame)
TabBar.Size = UDim2.new(1, 0, 0, 50)
TabBar.Position = UDim2.new(0, 0, 0, 55)
TabBar.BackgroundTransparency = 1

local function CreateTab(name, x)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.33, 0, 1, 0)
    btn.Position = UDim2.new(x, 0, 0, 0)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 80)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 50)}):Play()
    end)
    
    return btn
end

local CombotTab = CreateTab("🎯 COMBOT", 0)
local VisualTab = CreateTab("👁️ VISUAL", 0.33)
local ExtraTab = CreateTab("⚡ EXTRA", 0.66)

-- Контент
local ContentFrame = Instance.new("Frame", MenuFrame)
ContentFrame.Size = UDim2.new(1, -20, 1, -120)
ContentFrame.Position = UDim2.new(0, 10, 0, 110)
ContentFrame.BackgroundTransparency = 1

-- Функции создания элементов
local function MakeSwitch(parent, text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.Text = text .. ": " .. (getter() and "✅ ON" or "❌ OFF")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(40, 35, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 12)
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = text .. ": " .. (getter() and "✅ ON" or "❌ OFF")
        local color = getter() and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(40, 35, 50)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = getter() and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(60, 50, 70)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = getter() and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(40, 35, 50)}):Play()
    end)
    
    return btn
end

local function MakeSlider(parent, text, min, max, getter, setter)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 80)
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
    fill.BackgroundColor3 = MenuColor
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
        update()
    end)
    
    update()
    return frame
end

local function MakeColorSlider(parent)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Text = "🎨 MENU COLOR"
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
    fill.BackgroundColor3 = MenuColor
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function update()
        fill.BackgroundColor3 = MenuColor
        if menuStroke then menuStroke.Color = MenuColor end
        if CombotTab then
            if CombotContainer and CombotContainer.Visible then
                CombotTab.BackgroundColor3 = MenuColor
            end
            if VisualContainer and VisualContainer.Visible then
                VisualTab.BackgroundColor3 = MenuColor
            end
            if ExtraContainer and ExtraContainer.Visible then
                ExtraTab.BackgroundColor3 = MenuColor
            end
        end
    end
    
    slider.MouseButton1Down:Connect(function()
        dragging = true
        while dragging and slider.Parent do
            local mousePos = UserInputService:GetMouseLocation()
            local relativeX = math.clamp((mousePos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            MenuColor = Color3.fromHSV(relativeX, 1, 1)
            update()
            task.wait()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
        update()
    end)
    
    update()
    return frame
end

-- === КОНТЕЙНЕРЫ ===
local CombotContainer = Instance.new("Frame")
local VisualContainer = Instance.new("Frame")
local ExtraContainer = Instance.new("Frame")
for _, c in pairs({CombotContainer, VisualContainer, ExtraContainer}) do
    c.Size = UDim2.new(1, 0, 1, 0)
    c.BackgroundTransparency = 1
    c.Parent = ContentFrame
end

local layout1 = Instance.new("UIListLayout", CombotContainer)
layout1.Padding = UDim.new(0, 8)
local layout2 = Instance.new("UIListLayout", VisualContainer)
layout2.Padding = UDim.new(0, 8)
local layout3 = Instance.new("UIListLayout", ExtraContainer)
layout3.Padding = UDim.new(0, 8)

-- COMBOT
MakeSwitch(CombotContainer, "🔫 AIMBOT", function() return AimbotEnabled end, function(v) AimbotEnabled = v end)
MakeSlider(CombotContainer, "🎯 FOV", 50, 500, function() return AimFOV end, function(v) AimFOV = v end)

-- VISUAL
MakeSwitch(VisualContainer, "👁️ ESP", function() return ESPEnabled end, function(v) ESPEnabled = v end)
MakeSwitch(VisualContainer, "🔍 ZOOM +30", function() return ZoomEnabled end, function(v) ZoomEnabled = v; SetZoom() end)
MakeColorSlider(VisualContainer)

-- EXTRA
MakeSwitch(ExtraContainer, "🦘 INFINITE JUMP", function() return InfiniteJumpEnabled end, function(v) ToggleJump() end)
MakeSwitch(ExtraContainer, "⚡ SPEED", function() return SpeedEnabled end, function(v) SpeedEnabled = v; SetSpeed() end)

-- Переключение вкладок
local function selectTab(tab)
    CombotContainer.Visible = false
    VisualContainer.Visible = false
    ExtraContainer.Visible = false
    
    TweenService:Create(CombotTab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 50), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    TweenService:Create(VisualTab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 50), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    TweenService:Create(ExtraTab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 50), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    
    if tab == "COMBOT" then
        CombotContainer.Visible = true
        TweenService:Create(CombotTab, TweenInfo.new(0.2), {BackgroundColor3 = MenuColor, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    elseif tab == "VISUAL" then
        VisualContainer.Visible = true
        TweenService:Create(VisualTab, TweenInfo.new(0.2), {BackgroundColor3 = MenuColor, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    elseif tab == "EXTRA" then
 

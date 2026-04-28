-- Bulba Hub Pro | Arsenal Premium
-- Анимации, ESP со скелетом/цветом, модное меню, иконка S, новые функции

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === НАСТРОЙКИ ===
local AimbotEnabled = false
local ESPEnabled = false
local ZoomEnabled = false
local InfiniteJumpEnabled = false
local SpeedEnabled = false
local FlyEnabled = false

local AimFOV = 300
local AimSmoothness = 0.35
local SpeedValue = 70

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
local function SetZoom()
    Camera.FieldOfView = ZoomEnabled and 100 or 70
end

-- Бесконечные прыжки
local function ToggleInfiniteJump()
    InfiniteJumpEnabled = not InfiniteJumpEnabled
    if InfiniteJumpEnabled then
        local UIS = game:GetService("UserInputService")
        UIS.JumpRequest:Connect(function()
            if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState("Jumping")
            end
        end)
    end
end

-- Скорость
local function SetSpeed()
    if SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = SpeedValue
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end

-- Полёт
local function ToggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
        bodyVelocity.Velocity = Vector3.new(0, 50, 0)
        bodyVelocity.Parent = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        game:GetService("RunService").RenderStepped:Connect(function()
            if FlyEnabled and bodyVelocity and bodyVelocity.Parent then
                local moveDirection = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
                bodyVelocity.Velocity = moveDirection * 100
            end
        end)
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity"):Destroy()
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

-- === КРАСИВЫЙ ESP (СКЕЛЕТ + ЦВЕТ ПО ВИДИМОСТИ) ===
local espObjects = {}
local function CreateESP(player)
    if not player.Character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.Parent = player.Character
    
    -- Скелет (линии между частями тела)
    local joints = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}
    local lines = {}
    
    for _, joint in pairs(joints) do
        local attachment = Instance.new("Attachment")
        attachment.Name = joint .. "_Att"
        if player.Character:FindFirstChild(joint) then
            attachment.Parent = player.Character[joint]
            local line = Instance.new("LineHandleAdornment")
            line.AlwaysOnTop = true
            line.Color3 = Color3.fromRGB(255, 0, 0)
            line.Thickness = 2
            line.Visible = true
            line.Parent = player.Character
            lines[#lines+1] = {attachment, line, joint}
        end
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = player.Character:FindFirstChild("HumanoidRootPart") or player.Character
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    
    espObjects[player] = {highlight, billboard, nameLabel, lines}
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
            if ESPEnabled and isAlive then
                if not espObjects[player] then
                    CreateESP(player)
                else
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
                    for _, lineData in pairs(espObjects[player][4]) do
                        lineData[2].Color3 = color
                    end
                end
            else
                if espObjects[player] then
                    for _, obj in pairs(espObjects[player]) do
                        if type(obj) == "table" then
                            for _, line in pairs(obj) do
                                pcall(line[2].Destroy, line[2])
                            end
                        else
                            pcall(obj.Destroy, obj)
                        end
                    end
                    espObjects[player] = nil
                end
            end
        end
    end
end

-- === АНИМАЦИОННОЕ МЕНЮ С БАННЕРОМ ===
local ScreenGui = Instance.new("ScreenGui")
local BannerFrame = Instance.new("Frame")
local BannerText = Instance.new("TextLabel")
local MenuFrame = Instance.new("Frame")
local ScrollingFrame = Instance.new("ScrollingFrame")
local TabBar = Instance.new("Frame")
local ComboTab = Instance.new("TextButton")
local VisualTab = Instance.new("TextButton")
local ExtraTab = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- БАННЕР
BannerFrame.Parent = ScreenGui
BannerFrame.Size = UDim2.new(0, 300, 0, 150)
BannerFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
BannerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
BannerFrame.BackgroundTransparency = 0.1
local bannerCorner = Instance.new("UICorner", BannerFrame)
bannerCorner.CornerRadius = UDim.new(0, 20)

BannerText.Parent = BannerFrame
BannerText.Size = UDim2.new(1, 0, 1, 0)
BannerText.Text = "<font color='rgb(255,50,50)'>S</font>Sakenchik"
BannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
BannerText.TextSize = 30
BannerText.Font = Enum.Font.GothamBold
BannerText.RichText = true

-- Анимация баннера
local bannerTween = TweenService:Create(BannerFrame, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.02, 0, 0.05, 0)})
bannerTween:Play()
bannerTween.Completed:Connect(function()
    BannerFrame.Visible = false
    MenuFrame.Visible = true
end)

-- === МЕНЮ ===
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 340, 0, 480)
MenuFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = false
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", MenuFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "BULBA HUB PRO"
Title.TextColor3 = Color3.fromRGB(255, 180, 80)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

-- Панель вкладок
TabBar.Parent = MenuFrame
TabBar.Size = UDim2.new(1, 0, 0, 45)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)

ComboTab.Parent = TabBar
ComboTab.Size = UDim2.new(0.33, 0, 1, 0)
ComboTab.Position = UDim2.new(0, 0, 0, 0)
ComboTab.Text = "COMBOT"
ComboTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ComboTab.TextColor3 = Color3.fromRGB(255, 255, 255)
ComboTab.Font = Enum.Font.GothamBold

VisualTab.Parent = TabBar
VisualTab.Size = UDim2.new(0.33, 0, 1, 0)
VisualTab.Position = UDim2.new(0.33, 0, 0, 0)
VisualTab.Text = "VISUAL"
VisualTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
VisualTab.TextColor3 = Color3.fromRGB(200, 200, 200)
VisualTab.Font = Enum.Font.Gotham

ExtraTab.Parent = TabBar
ExtraTab.Size = UDim2.new(0.34, 0, 1, 0)
ExtraTab.Position = UDim2.new(0.66, 0, 0, 0)
ExtraTab.Text = "EXTRA"
ExtraTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
ExtraTab.TextColor3 = Color3.fromRGB(200, 200, 200)
ExtraTab.Font = Enum.Font.Gotham

-- Скроллинг
ScrollingFrame.Parent = MenuFrame
ScrollingFrame.Size = UDim2.new(1, -10, 1, -100)
ScrollingFrame.Position = UDim2.new(0, 5, 0, 90)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 5

local function MakeSwitch(text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.Text = text .. ": " .. (getter() and "ON" or "OFF")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)
    
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = text .. ": " .. (getter() and "ON" or "OFF")
        btn.BackgroundColor3 = getter() and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 80)
    end)
    
    btn.Parent = ScrollingFrame
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
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    update()
    frame.Parent = ScrollingFrame
    return frame
end

-- === КОНТЕНТ ВКЛАДОК ===
local combotSwitch = MakeSwitch("🔫 COMBOT", function() return AimbotEnabled end, function(v) AimbotEnabled = v end)
local fovSlider = MakeSlider("🎯 FOV RADIUS", 50, 500, function() return AimFOV end, function(v) AimFOV = v end)
local smoothSlider = MakeSlider("⚡ SMOOTHNESS", 10, 80, function() return AimSmoothness * 100 end, function(v) AimSmoothness = v / 100 end)

local espSwitch = MakeSwitch("👁️ VISUAL", function() return ESPEnabled end, function(v) ESPEnabled = v end)
local zoomSwitch = MakeSwitch("🔍 ZOOM +30", function() return ZoomEnabled end, function(v) ZoomEnabled = v; SetZoom() end)

local jumpSwitch = MakeSwitch("🔁 INFINITE JUMP", function() return InfiniteJumpEnabled end, function(v) ToggleInfiniteJump() end)
local speedSwitch = MakeSwitch("⚡ SPEED", function() return SpeedEnabled end, function(v) SpeedEnabled = v; SetSpeed() end)
local flySwitch = MakeSwitch("🕊️ FLY", function() return FlyEnabled end, function(v) ToggleFly() end)

-- Организация вкладок
local function setupTab(container, ...)
    for _, btn in pairs({...}) do
        btn.Parent = container
    end
end

local combotContainer = Instance.new("Frame")
local visualContainer = Instance.new("Frame")
local extraContainer = Instance.new("Frame")
for _, c in pairs({combotContainer, visualContainer, extraContainer}) do
    c.Size = UDim2.new(1, 0, 1, 0)
    c.BackgroundTransparency = 1
    c.Parent = ScrollingFrame
end

setupTab(combotContainer, combotSwitch, fovSlider, smoothSlider)
setupTab(visualContainer, espSwitch, zoomSwitch)
setupTab(extraContainer, jumpSwitch, speedSwitch, flySwitch)

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
        VisualTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        VisualTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tab == "EXTRA" then
        extraContainer.Visible = true
        ExtraTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        ExtraTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

ComboTab.MouseButton1Click:Connect(function() selectTab("COMBOT") end)
VisualTab.MouseButton1Click:Connect(function() selectTab("VISUAL") end)
ExtraTab.MouseButton1Click:Connect(function() selectTab("EXTRA") end)
selectTab("COMBOT")

-- === ИКОНКА S (только когда меню скрыто) ===
local FloatingIcon = Instance.new("TextButton")
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
FloatingIcon.Visible = true

FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
    FloatingIcon.Visible = not MenuFrame.Visible
end)

MenuFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    FloatingIcon.Visible = not MenuFrame.Visible
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
    
    if AimbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
        local target = GetClosestVisiblePlayer()
        if target then
            DoAimbot(target)
        end
    end
    
    SetSpeed()
end)

print("Bulba Hub Pro загружен!")

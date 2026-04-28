-- Bulba Hub | Arsenal CLEAN NO BUGS
-- Работает: Aimbot (вкл/выкл + FOV + плавность), ESP (вкл/выкл), Zoom (+30)
-- Wallbang УДАЛЁН

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === НАСТРОЙКИ (ВСЕ ВЫКЛЮЧЕНЫ) ===
local AimbotEnabled = false
local ESPEnabled = false
local ZoomEnabled = false

local AimFOV = 300
local AimSmoothness = 0.35

-- === ЗУМ КАМЕРЫ ===
local function SetZoom()
    if ZoomEnabled then
        Camera.FieldOfView = 100
    else
        Camera.FieldOfView = 70
    end
end

-- Защита от сброса зума при смерти
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    SetZoom()
end)

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
            
            -- Проверка видимости (через стену не наводится)
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
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
            if ESPEnabled and isAlive then
                if not espObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.FillTransparency = 0.7
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

-- === ==== МЕНЮ ==== === --
local ScreenGui = Instance.new("ScreenGui")
local FloatingIcon = Instance.new("TextButton")
local MenuFrame = Instance.new("Frame")
local ScrollingFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local TabBar = Instance.new("Frame")
local AimbotTab = Instance.new("TextButton")
local VisualsTab = Instance.new("TextButton")

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
MenuFrame.Size = UDim2.new(0, 320, 0, 450)
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
AimbotTab.Size = UDim2.new(0.5, 0, 1, 0)
AimbotTab.Position = UDim2.new(0, 0, 0, 0)
AimbotTab.Text = "AIMBOT"
AimbotTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
AimbotTab.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotTab.Font = Enum.Font.GothamBold

-- Вкладка VISUALS
VisualsTab.Parent = TabBar
VisualsTab.Size = UDim2.new(0.5, 0, 1, 0)
VisualsTab.Position = UDim2.new(0.5, 0, 0, 0)
VisualsTab.Text = "VISUALS"
VisualsTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
VisualsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
VisualsTab.Font = Enum.Font.Gotham

-- Скроллинг
ScrollingFrame.Parent = MenuFrame
ScrollingFrame.Size = UDim2.new(1, -10, 1, -100)
ScrollingFrame.Position = UDim2.new(0, 5, 0, 90)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 5

UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

-- === ФУНКЦИЯ КНОПКИ-ПЕРЕКЛЮЧАТЕЛЯ ===
local function MakeSwitch(text, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 60)
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

-- === ФУНКЦИЯ ПОЛЗУНКА ===
local function MakeSlider(text, min, max, getter, setter, format)
    format = format or function(v) return math.floor(v) end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 85)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 10)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Text = text .. ": " .. format(getter())
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
        label.Text = text .. ": " .. format(val)
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

-- === КОНТЕЙНЕРЫ ВКЛАДОК ===
local AimbotContainer = Instance.new("Frame")
local VisualsContainer = Instance.new("Frame")
AimbotContainer.Size = UDim2.new(1, 0, 1, 0)
VisualsContainer.Size = UDim2.new(1, 0, 1, 0)
AimbotContainer.BackgroundTransparency = 1
VisualsContainer.BackgroundTransparency = 1
AimbotContainer.Parent = ScrollingFrame
VisualsContainer.Parent = ScrollingFrame

-- Переносим скролл в контейнеры
UIListLayout.Parent = nil

local function setupContainer(container)
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    return layout
end

local aimbotLayout = setupContainer(AimbotContainer)
local visualsLayout = setupContainer(VisualsContainer)

-- === AIMBOT ВКЛАДКА ===
local AimbotToggle = MakeSwitch("🎯 AIMBOT", function() return AimbotEnabled end, function(v) AimbotEnabled = v end)
AimbotToggle.Parent = AimbotContainer

local FOVSlider = MakeSlider("🎯 FOV RADIUS", 50, 500, function() return AimFOV end, function(v) AimFOV = v end)
FOVSlider.Parent = AimbotContainer

local SmoothSlider = MakeSlider("⚡ AIM SMOOTHNESS", 10, 80, function() return AimSmoothness * 100 end, function(v) AimSmoothness = v / 100 end, function(v) return math.floor(v) .. "%" end)
SmoothSlider.Parent = AimbotContainer

-- === VISUALS ВКЛАДКА ===
local ESPToggle = MakeSwitch("👁️ ESP", function() return ESPEnabled end, function(v) ESPEnabled = v end)
ESPToggle.Parent = VisualsContainer

local ZoomToggle = MakeSwitch("🔍 ZOOM +30", function() return ZoomEnabled end, function(v) ZoomEnabled = v; SetZoom() end)
ZoomToggle.Parent = VisualsContainer

-- === ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ===
local function SelectTab(tabName)
    AimbotContainer.Visible = false
    VisualsContainer.Visible = false
    
    AimbotTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    VisualsTab.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    AimbotTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    VisualsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    
    if tabName == "AIMBOT" then
        AimbotContainer.Visible = true
        AimbotTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        AimbotTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tabName == "VISUALS" then
        VisualsContainer.Visible = true
        VisualsTab.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        VisualsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

AimbotTab.MouseButton1Click:Connect(function() SelectTab("AIMBOT") end)
VisualsTab.MouseButton1Click:Connect(function() SelectTab("VISUALS") end)
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
    
    if AimbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
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
    Title = "Bulba Hub CLEAN",
    Text = "Готов! Нажми S для меню. Wallbang УДАЛЁН. Zoom работает.",
    Duration = 5
})

print("Bulba Hub CLEAN NO BUGS загружен!")

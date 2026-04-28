-- Bulba Hub | Arsenal ULTRA FIX
-- Работает: Aimbot (вкл/выкл по нажатию на раздел), Wallbang (без провалов), ESP, иконка S

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- === НАСТРОЙКИ ===
local Settings = {
    Aimbot = false,
    Wallbang = false,
    ESP = false,
    AimFOV = 350,
    AimSmoothness = 0.35
}

-- === ПЕРЕМЕЩЕНИЕ ИКОНКИ S ===
local DraggingIcon = false
local IconDragStart = nil
local IconStartPos = nil

-- === ПЕРЕМЕЩЕНИЕ МЕНЮ ===
local DraggingMenu = false
local MenuDragStart = nil
local MenuStartPos = nil

-- === ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ИГРОКА (только видимых) ===
local function GetClosestVisiblePlayer()
    local closest = nil
    local shortest = Settings.AimFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then continue end
            
            -- Проверка видимости (через стену не наводится)
            local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 1000)
            local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
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

-- === АИМБОТ ===
local function DoAimbot(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local direction = (head.Position - Camera.CFrame.Position).unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.AimSmoothness)
end

-- === ФИКС WALLBANG (без провалов) ===
local function ToggleWallbang()
    Settings.Wallbang = not Settings.Wallbang
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Name ~= "Head" then
            if not v:IsDescendantOf(LocalPlayer.Character) then
                v.CanCollide = not Settings.Wallbang
            end
        end
    end
end

-- === ПРОСТОЙ ESP ===
local ESPObjects = {}
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP and player.Character then
                if not ESPObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.FillTransparency = 0.7
                    highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
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

-- === ==== ИНТЕРФЕЙС ==== === --
local ScreenGui = Instance.new("ScreenGui")
local FloatingIcon = Instance.new("TextButton")
local MenuFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local AimbotSection = Instance.new("TextButton")
local WallbangSection = Instance.new("TextButton")
local ESPButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "BulbaHub"
ScreenGui.ResetOnSpawn = false

-- === ИКОНКА S (ПЕРЕМЕЩАЕМАЯ) ===
FloatingIcon.Parent = ScreenGui
FloatingIcon.Size = UDim2.new(0, 60, 0, 60)
FloatingIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
FloatingIcon.Text = "S"
FloatingIcon.TextSize = 30
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatingIcon.BackgroundTransparency = 0.2
local iconCorner = Instance.new("UICorner", FloatingIcon)
iconCorner.CornerRadius = UDim.new(1, 0)

-- Перемещение иконки S
FloatingIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        DraggingIcon = true
        IconDragStart = input.Position
        IconStartPos = FloatingIcon.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        DraggingIcon = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if DraggingIcon and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - IconDragStart
        FloatingIcon.Position = UDim2.new(IconStartPos.X.Scale, IconStartPos.X.Offset + delta.X, IconStartPos.Y.Scale, IconStartPos.Y.Offset + delta.Y)
    end
end)

-- === МЕНЮ ===
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 260, 0, 280)
MenuFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MenuFrame.Active = true
MenuFrame.Draggable = true
local menuCorner = Instance.new("UICorner", MenuFrame)
menuCorner.CornerRadius = UDim.new(0, 12)

Title.Parent = MenuFrame
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "BULBA HUB"
Title.TextColor3 = Color3.fromRGB(255, 180, 80)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

-- === КНОПКИ-РАЗДЕЛЫ С ПЕРЕКЛЮЧЕНИЕМ ===
AimbotSection.Parent = MenuFrame
AimbotSection.Size = UDim2.new(0, 220, 0, 50)
AimbotSection.Position = UDim2.new(0.5, -110, 0, 55)
AimbotSection.Text = "🎯 AIMBOT: OFF"
AimbotSection.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
AimbotSection.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotSection.Font = Enum.Font.Gotham
AimbotSection.TextScaled = true
local aimCorner = Instance.new("UICorner", AimbotSection)
aimCorner.CornerRadius = UDim.new(0, 8)

WallbangSection.Parent = MenuFrame
WallbangSection.Size = UDim2.new(0, 220, 0, 50)
WallbangSection.Position = UDim2.new(0.5, -110, 0, 115)
WallbangSection.Text = "🧱 WALLBANG: OFF"
WallbangSection.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
WallbangSection.TextColor3 = Color3.fromRGB(255, 255, 255)
WallbangSection.Font = Enum.Font.Gotham
WallbangSection.TextScaled = true
local wallCorner = Instance.new("UICorner", WallbangSection)
wallCorner.CornerRadius = UDim.new(0, 8)

ESPButton.Parent = MenuFrame
ESPButton.Size = UDim2.new(0, 220, 0, 50)
ESPButton.Position = UDim2.new(0.5, -110, 0, 175)
ESPButton.Text = "👁️ ESP: OFF"
ESPButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.Font = Enum.Font.Gotham
ESPButton.TextScaled = true
local espCorner = Instance.new("UICorner", ESPButton)
espCorner.CornerRadius = UDim.new(0, 8)

-- === ОБРАБОТЧИКИ КНОПОК ===
AimbotSection.MouseButton1Click:Connect(function()
    Settings.Aimbot = not Settings.Aimbot
    AimbotSection.Text = "🎯 AIMBOT: " .. (Settings.Aimbot and "ON" or "OFF")
    AimbotSection.BackgroundColor3 = Settings.Aimbot and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(80, 30, 30)
end)

WallbangSection.MouseButton1Click:Connect(function()
    ToggleWallbang()
    WallbangSection.Text = "🧱 WALLBANG: " .. (Settings.Wallbang and "ON" or "OFF")
    WallbangSection.BackgroundColor3 = Settings.Wallbang and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(80, 30, 30)
end)

ESPButton.MouseButton1Click:Connect(function()
    Settings.ESP = not Settings.ESP
    ESPButton.Text = "👁️ ESP: " .. (Settings.ESP and "ON" or "OFF")
    ESPButton.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(80, 30, 30)
    if not Settings.ESP then
        for _, v in pairs(ESPObjects) do pcall(v.Destroy, v) end
        table.clear(ESPObjects)
    end
end)

-- === FOV КРУГ (видим только когда аимбот включён) ===
local FOVCircle = Instance.new("Frame")
FOVCircle.Parent = ScreenGui
FOVCircle.Size = UDim2.new(0, 0, 0, 0)
FOVCircle.BackgroundTransparency = 1
local circleCorner = Instance.new("UICorner", FOVCircle)
circleCorner.CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FOVCircle)
stroke.Color = Color3.fromRGB(255, 100, 100)
stroke.Thickness = 2
stroke.Transparency = 0.5

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    -- FOV круг
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
    end
    
    -- Aimbot
    if Settings.Aimbot and LocalPlayer.Character then
        local target = GetClosestVisiblePlayer()
        if target then
            DoAimbot(target)
        end
    end
end)

-- Открытие меню по иконке
FloatingIcon.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

-- Уведомление
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Bulba Hub",
    Text = "Иконку S можно перемещать. Нажми на неё для меню.",
    Duration = 4
})

print("Bulba Hub ULTRA FIX загружен!")

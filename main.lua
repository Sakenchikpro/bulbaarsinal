-- Arsenal.lua
-- Этот файл лежит по ссылке из таблицы Games

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Функция для уведомлений
local function Notify(Title, Text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = 3
    })
end

-- Пример функции ESP
local function CreateESP(Player)
    if not Player.Character then return end
    local head = Player.Character:FindFirstChild("Head")
    if not head then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel", billboard)
    label.Text = Player.Name .. " (" .. math.floor((Player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) .. "m)"
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    
    billboard.Parent = head
end

-- ESP вкл/выкл
local ESPEnabled = false
local ESPConnections = {}

local function ToggleESP()
    ESPEnabled = not ESPEnabled
    
    if ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateESP(player)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            if ESPEnabled then
                CreateESP(player)
            end
        end)
        
        Notify("ESP", "Включён")
    else
        -- Очистка ESP (удаление билбордов)
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BillboardGui") and v:FindFirstChild("TextLabel") and v.TextLabel.Text:find("m)") then
                v:Destroy()
            end
        end
        Notify("ESP", "Выключен")
    end
end

-- Пример: спидхак
local function SetSpeed(Speed)
    LocalPlayer.Character.Humanoid.WalkSpeed = Speed
    Notify("Speed", "Установлена: " .. Speed)
end

-- Простой GUI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ESPButton = Instance.new("TextButton")
local SpeedButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

ESPButton.Parent = Frame
ESPButton.Size = UDim2.new(0, 180, 0, 30)
ESPButton.Position = UDim2.new(0, 10, 0, 10)
ESPButton.Text = "ESP (Вкл)"
ESPButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ESPButton.MouseButton1Click:Connect(function()
    ToggleESP()
    ESPButton.Text = ESPEnabled and "ESP (Выкл)" or "ESP (Вкл)"
    ESPButton.BackgroundColor3 = ESPEnabled and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(0, 100, 0)
end)

SpeedButton.Parent = Frame
SpeedButton.Size = UDim2.new(0, 180, 0, 30)
SpeedButton.Position = UDim2.new(0, 10, 0, 50)
SpeedButton.Text = "Speed X2"
SpeedButton.BackgroundColor3 = Color3.fromRGB(0, 0, 100)
SpeedButton.MouseButton1Click:Connect(function()
    SetSpeed(32)
end)

Notify("Arsenal Hub", "Загружен! Нажми Insert для GUI")
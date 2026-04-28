-- Bulba Hub Pro | RGB FIX + Tabs Swipe + Expandable Toggles + Animated UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

repeat task.wait() until game:IsLoaded()
repeat task.wait() until LocalPlayer and LocalPlayer.Character

-- === STATE ===
local state = {
    aimbot = false,
    esp = false,
    zoom = false,
    speed = false,
    aimFov = 280,
    aimSmooth = 0.28,
    speedValue = 70,
    gradientSpeed = 0.004,
    hue = 0,
}

local defaultWalkSpeed = 16
local espObjects = {}

-- === HELPERS ===
local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function setZoom()
    Camera.FieldOfView = state.zoom and 100 or 70
end

local function applySpeed()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum then
        hum.WalkSpeed = state.speed and state.speedValue or defaultWalkSpeed
    end
end

local function newRaycast(origin, targetPos, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local dir = targetPos - origin
    return Workspace:Raycast(origin, dir, params)
end

local function isEnemyVisible(player)
    if not player.Character then return false end
    local head = player.Character:FindFirstChild("Head")
    if not head then return false end
    local result = newRaycast(Camera.CFrame.Position, head.Position, {LocalPlayer.Character, Camera})
    if not result then
        return true
    end
    return result.Instance and result.Instance:IsDescendantOf(player.Character)
end

local function getTarget()
    local closest, shortest = nil, state.aimFov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Team ~= LocalPlayer.Team then
            local hum = getHumanoid(plr.Character)
            local head = plr.Character:FindFirstChild("Head")
            if hum and head and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen and isEnemyVisible(plr) then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

local function doAimbot(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    local hum = getHumanoid(target.Character)
    if not head or not hum or hum.Health <= 0 then return end

    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(state.aimSmooth, 0.01, 0.95))
end

-- === ESP ===
local function removeESP(player)
    local data = espObjects[player]
    if not data then return end
    for _, obj in ipairs(data) do
        if obj and obj.Destroy then
            pcall(function() obj:Destroy() end)
        end
    end
    espObjects[player] = nil
end

local function createESP(player)
    if not player.Character or player.Team == LocalPlayer.Team then return end

    local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
    if not root then return end

    local box = Instance.new("Highlight")
    box.FillTransparency = 0.8
    box.FillColor = Color3.fromRGB(70, 0, 0)
    box.OutlineTransparency = 0
    box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    box.Parent = player.Character

    local tag = Instance.new("BillboardGui")
    tag.Name = "BH_ESP"
    tag.Size = UDim2.new(0, 120, 0, 38)
    tag.StudsOffset = Vector3.new(0, 3.1, 0)
    tag.AlwaysOnTop = true
    tag.Parent = root

    local name = Instance.new("TextLabel")
    name.Parent = tag
    name.Size = UDim2.new(1, 0, 0, 18)
    name.BackgroundTransparency = 1
    name.Text = player.Name
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextStrokeTransparency = 0.5
    name.Font = Enum.Font.GothamBold
    name.TextScaled = true

    local barBg = Instance.new("Frame")
    barBg.Parent = tag
    barBg.Size = UDim2.new(0.85, 0, 0, 6)
    barBg.Position = UDim2.new(0.075, 0, 0, 24)
    barBg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame")
    bar.Parent = barBg
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 130)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    espObjects[player] = {box, tag, name, bar}
end

local function updateESP()
    for player in pairs(espObjects) do
        local hum = player.Character and getHumanoid(player.Character)
        if (not state.esp) or player.Team == LocalPlayer.Team or (not hum) or hum.Health <= 0 then
            removeESP(player)
        end
    end

    if not state.esp then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
            local hum = getHumanoid(player.Character)
            if hum and hum.Health > 0 then
                if not espObjects[player] then
                    createESP(player)
                end
                local data = espObjects[player]
                if data then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    data[4].Size = UDim2.new(hp, 0, 1, 0)
                    data[4].BackgroundColor3 = (hp > 0.6 and Color3.fromRGB(0, 255, 130)) or (hp > 0.3 and Color3.fromRGB(255, 200, 0)) or Color3.fromRGB(255, 70, 70)
                    data[1].OutlineColor = isEnemyVisible(player) and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 70, 70)
                end
            end
        end
    end
end

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "BulbaHub"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local menu = Instance.new("Frame")
menu.Parent = gui
menu.Size = UDim2.new(0, 460, 0, 430)
menu.Position = UDim2.new(0.5, -230, 0.22, 0)
menu.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
menu.Active = true
menu.Draggable = true
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 16)

local gradient = Instance.new("UIGradient", menu)
gradient.Rotation = 35
gradient.Offset = Vector2.new(0, 0)

local title = Instance.new("TextLabel", menu)
title.Size = UDim2.new(1, -44, 0, 45)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "BULBA HUB PRO"
title.TextColor3 = Color3.fromRGB(255, 220, 140)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", menu)
close.Size = UDim2.new(0, 34, 0, 34)
close.Position = UDim2.new(1, -40, 0, 6)
close.Text = "X"
close.BackgroundTransparency = 1
close.TextColor3 = Color3.fromRGB(255, 120, 120)
close.Font = Enum.Font.GothamBold
close.TextSize = 22

local tabBar = Instance.new("Frame", menu)
tabBar.Size = UDim2.new(1, -20, 0, 42)
tabBar.Position = UDim2.new(0, 10, 0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 12)

local contentHolder = Instance.new("Frame", menu)
contentHolder.Size = UDim2.new(1, -20, 1, -105)
contentHolder.Position = UDim2.new(0, 10, 0, 95)
contentHolder.BackgroundTransparency = 1
contentHolder.ClipsDescendants = true

local pages = Instance.new("Frame", contentHolder)
pages.Size = UDim2.new(3, 0, 1, 0)
pages.Position = UDim2.new(0, 0, 0, 0)
pages.BackgroundTransparency = 1

local pageList = Instance.new("UIListLayout", pages)
pageList.FillDirection = Enum.FillDirection.Horizontal
pageList.SortOrder = Enum.SortOrder.LayoutOrder
pageList.Padding = UDim.new(0, 10)

local function makePage(order)
    local p = Instance.new("ScrollingFrame")
    p.Parent = pages
    p.LayoutOrder = order
    p.Size = UDim2.new(1/3, -7, 1, 0)
    p.BackgroundTransparency = 1
    p.ScrollBarThickness = 4
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    local l = Instance.new("UIListLayout", p)
    l.Padding = UDim.new(0, 8)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        p.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 6)
    end)
    return p
end

local pageCombat = makePage(1)
local pageVisual = makePage(2)
local pageExtra = makePage(3)

local currentTab = 1
local function animateToTab(tab)
    currentTab = math.clamp(tab, 1, 3)
    local goalX = -(currentTab - 1)
    TweenService:Create(pages, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(goalX, -(currentTab - 1) * 10, 0, 0)
    }):Play()
end

local tabButtons = {}
local function makeTabButton(text, idx)
    local b = Instance.new("TextButton", tabBar)
    b.Size = UDim2.new(0.333, -6, 1, -8)
    b.Position = UDim2.new((idx - 1) * 0.333 + 0.003, 0, 0, 4)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(225, 225, 225)
    b.BackgroundColor3 = Color3.fromRGB(44, 44, 66)
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function()
        animateToTab(idx)
    end)
    tabButtons[idx] = b
end
makeTabButton("COMBAT", 1)
makeTabButton("VISUAL", 2)
makeTabButton("EXTRA", 3)

local function updateTabStyles()
    for idx, b in ipairs(tabButtons) do
        local on = idx == currentTab
        TweenService:Create(b, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Color3.fromRGB(0, 132, 90) or Color3.fromRGB(44, 44, 66)
        }):Play()
    end
end
RunService.RenderStepped:Connect(updateTabStyles)

-- swipe tabs right/left
local touching, startX = false, 0
contentHolder.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        touching = true
        startX = input.Position.X
    end
end)
contentHolder.InputEnded:Connect(function(input)
    if not touching then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local delta = input.Position.X - startX
        if delta < -60 then
            animateToTab(currentTab + 1)
        elseif delta > 60 then
            animateToTab(currentTab - 1)
        end
        touching = false
    end
end)

local function makeCard(parent, titleText)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, -8, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(36, 36, 55)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local titleLabel = Instance.new("TextButton", card)
    titleLabel.Size = UDim2.new(1, -58, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15

    local toggle = Instance.new("TextButton", card)
    toggle.Size = UDim2.new(0, 28, 0, 28)
    toggle.Position = UDim2.new(1, -38, 0.5, -14)
    toggle.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    toggle.Text = ""
    toggle.AutoButtonColor = false
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", toggle)
    stroke.Color = Color3.fromRGB(130, 130, 150)

    local check = Instance.new("TextLabel", toggle)
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = "✓"
    check.Font = Enum.Font.GothamBold
    check.TextScaled = true
    check.TextColor3 = Color3.fromRGB(80, 255, 160)
    check.Visible = false

    return card, titleLabel, toggle, check
end

local function makeSlider(parent, text, minv, maxv, getter, setter)
    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1, -8, 0, 74)
    wrap.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    wrap.Visible = false
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel", wrap)
    label.Size = UDim2.new(1, -14, 0, 28)
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(225, 225, 255)

    local bar = Instance.new("Frame", wrap)
    bar.Size = UDim2.new(1, -18, 0, 24)
    bar.Position = UDim2.new(0, 9, 0, 38)
    bar.BackgroundColor3 = Color3.fromRGB(55, 55, 74)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local drag = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not drag then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            setter(minv + (maxv - minv) * rel)
        end
    end)

    RunService.RenderStepped:Connect(function()
        local v = getter()
        label.Text = string.format("%s: %d", text, math.floor(v))
        fill.Size = UDim2.new((v - minv) / (maxv - minv), 0, 1, 0)
    end)

    return wrap
end

local function makeExpandableFeature(parent, titleText, getter, setter)
    local card, titleBtn, toggleBtn, check = makeCard(parent, titleText)
    local expanded = false
    local extras = Instance.new("Frame", parent)
    extras.Size = UDim2.new(1, -8, 0, 0)
    extras.BackgroundTransparency = 1
    extras.ClipsDescendants = true

    local extraList = Instance.new("UIListLayout", extras)
    extraList.Padding = UDim.new(0, 8)

    local function refresh()
        local enabled = getter()
        check.Visible = enabled
        toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(20, 60, 40) or Color3.fromRGB(20, 20, 30)
        TweenService:Create(extras, TweenInfo.new(0.2), {
            Size = UDim2.new(1, -8, 0, expanded and (extraList.AbsoluteContentSize.Y + 2) or 0)
        }):Play()
    end

    toggleBtn.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)
    titleBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        refresh()
    end)

    refresh()
    return extras, refresh
end

-- combat expandable (aim)
local aimExtras = makeExpandableFeature(pageCombat, "AIM", function() return state.aimbot end, function(v) state.aimbot = v end)
makeSlider(aimExtras, "AIM FOV", 60, 500, function() return state.aimFov end, function(v) state.aimFov = v end).Visible = true
makeSlider(aimExtras, "AIM SMOOTH", 1, 95, function() return state.aimSmooth * 100 end, function(v) state.aimSmooth = v / 100 end).Visible = true

-- visual expandable (esp)
local espExtras = makeExpandableFeature(pageVisual, "WALLHACK (ESP)", function() return state.esp end, function(v) state.esp = v end)

local zoomCard, _, zTog, zCheck = makeCard(pageVisual, "ZOOM")
zTog.MouseButton1Click:Connect(function() state.zoom = not state.zoom; setZoom() end)
RunService.RenderStepped:Connect(function() zCheck.Visible = state.zoom end)

local spExtras = makeExpandableFeature(pageExtra, "SPEED", function() return state.speed end, function(v) state.speed = v; applySpeed() end)
makeSlider(spExtras, "SPEED VALUE", 16, 220, function() return state.speedValue end, function(v) state.speedValue = v; applySpeed() end).Visible = true

makeSlider(pageExtra, "RGB SPEED", 1, 40, function() return state.gradientSpeed * 1000 end, function(v) state.gradientSpeed = v / 1000 end).Visible = true

-- icon minimize
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0, 56, 0, 56)
icon.Position = UDim2.new(0.02, 0, 0.05, 0)
icon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
icon.BackgroundTransparency = 0.2
icon.Text = "S"
icon.TextSize = 32
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
icon.Visible = false

close.MouseButton1Click:Connect(function()
    menu.Visible = false
    icon.Visible = true
end)
icon.MouseButton1Click:Connect(function()
    icon.Visible = false
    menu.Visible = true
end)

-- fov circle
local fov = Instance.new("Frame", gui)
fov.BackgroundTransparency = 1
local fovCorner = Instance.new("UICorner", fov)
fovCorner.CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fov)
fovStroke.Thickness = 2
fovStroke.Color = Color3.fromRGB(255, 100, 100)

-- respawn fixes
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    applySpeed()
    setZoom()
end)

Players.PlayerRemoving:Connect(removeESP)

-- main loop
RunService.RenderStepped:Connect(function()
    -- real rgb gradient animation fix
    state.hue = (state.hue + state.gradientSpeed) % 1
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(state.hue, 1, 0.42)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV((state.hue + 0.2) % 1, 0.9, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV((state.hue + 0.4) % 1, 1, 0.46))
    })
    gradient.Offset = Vector2.new(math.sin(tick() * 0.75) * 0.2, 0)

    if state.aimbot then
        local size = state.aimFov * 2
        fov.Size = UDim2.new(0, size, 0, size)
        fov.Position = UDim2.new(0.5, -state.aimFov, 0.5, -state.aimFov)
        fov.Visible = true
        local target = getTarget()
        if target then doAimbot(target) end
    else
        fov.Visible = false
    end

    updateESP()
end)

animateToTab(1)
updateTabStyles()
setZoom()
applySpeed()

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Bulba Hub Pro",
        Text = "RGB fixed | Swipe tabs | Expandable AIM/ESP",
        Duration = 4,
    })
end)

print("✅ Bulba Hub Pro loaded")

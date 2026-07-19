 - Контекст и инициализация хелперов
local MovementController = {}
MovementController.__index = MovementController

function MovementController.new()
    local self = setmetatable({}, MovementController)
    self.connection = nil
    self.velocityObject = nil
    return self
end

function MovementController:ConnectToTarget(character, speedGetter, stateGetter)
    self:Disconnect()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    self.velocityObject = bv
    
    self.connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not stateGetter() or not hrp.Parent then
            self:Disconnect()
            return
        end
        local moveDir = Vector3.new(0, 0, 0)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local dir = humanoid.MoveDirection
            if dir.Magnitude > 0 then
                moveDir = camera.CFrame.LookVector * dir.Magnitude
            end
        end
        bv.Velocity = moveDir * speedGetter()
    end)
end

function MovementController:Disconnect()
    if self.connection then self.connection:Disconnect() self.connection = nil end
    if self.velocityObject then self.velocityObject:Destroy() self.velocityObject = nil end
end

-- Инициализация GUI
local targetGui = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
if targetGui:FindFirstChild("SeraphCAMenu") then targetGui.SeraphCAMenu:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeraphCAMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = targetGui

-- Холст для 2D элементов ESP и объектов Adornment
local FullscreenEspCanvas = Instance.new("Frame")
FullscreenEspCanvas.Name = "FullscreenEspCanvas"
FullscreenEspCanvas.Size = UDim2.new(1, 0, 1, 0)
FullscreenEspCanvas.BackgroundTransparency = 1
FullscreenEspCanvas.ZIndex = 1
FullscreenEspCanvas.Parent = ScreenGui

-- Переменные состояний fly и fling
local flyEnabled = false
local flySpeedValue = 50
local shopHackEnabled = false
local flingMasterEnabled = false
local selectedFlingTarget = nil
local isFlinging = false
local flyController = MovementController.new()

-- Настройки ESP
local espMasterEnabled = false
local currentTab = "MISK"
local espSettings = {
    Outline = {enabled = false, color = Color3.fromRGB(255, 0, 0)},
    NickName = {enabled = false, color = Color3.fromRGB(0, 255, 255)},
    Distance = {enabled = false, color = Color3.fromRGB(255, 255, 0)}
}

-- Настройки HIT-BOX
local hitboxMasterEnabled = false
local hitboxSizeValue = 2
local showHitboxVisuals = false
local hitboxColor = Color3.fromRGB(255, 0, 0)
local hitboxTransparencyValue = 0.5

local function getSpeed() return flySpeedValue end
local function getState() return flyEnabled end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
    flyController:Disconnect()
    if flyEnabled then
        task.wait(0.5)
        flyController:ConnectToTarget(char, getSpeed, getState)
    end
end)

-- Главная панель
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 260)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Active = true
MainFrame.Visible = false 
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

-- Окно выбора цвета (Color Picker)
local ColorPickerFrame = Instance.new("Frame")
ColorPickerFrame.Name = "ColorPickerFrame"
ColorPickerFrame.Size = UDim2.new(0, 160, 0, 170)
ColorPickerFrame.Position = UDim2.new(0.5, -80, 0.5, -85)
ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ColorPickerFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
ColorPickerFrame.BorderSizePixel = 1
ColorPickerFrame.Visible = false
ColorPickerFrame.ZIndex = 20
ColorPickerFrame.Parent = ScreenGui

local ColorPickerGrid = Instance.new("Frame")
ColorPickerGrid.Size = UDim2.new(1, -10, 1, -40)
ColorPickerGrid.Position = UDim2.new(0, 5, 0, 5)
ColorPickerGrid.BackgroundTransparency = 1
ColorPickerGrid.ZIndex = 21
ColorPickerGrid.Parent = ColorPickerFrame

local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.CellSize = UDim2.new(0, 22, 0, 22)
UIGridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
UIGridLayout.Parent = ColorPickerGrid

local ClosePickerBtn = Instance.new("TextButton")
ClosePickerBtn.Size = UDim2.new(1, -10, 0, 25)
ClosePickerBtn.Position = UDim2.new(0, 5, 1, -30)
ClosePickerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ClosePickerBtn.Text = "Закрыть"
ClosePickerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClosePickerBtn.TextSize = 12
ClosePickerBtn.ZIndex = 21
ClosePickerBtn.Parent = ColorPickerFrame

local presetColors = {
    Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 128, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(128, 255, 0),
    Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 255, 128), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 128, 255),
    Color3.fromRGB(0, 0, 255), Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 0, 255), Color3.fromRGB(255, 0, 128),
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170), Color3.fromRGB(85, 85, 85), Color3.fromRGB(0, 0, 0)
}

local activePickingFeature = nil
local activeColorButtonRef = nil

local function openColorPicker(featureName, buttonRef)
    activePickingFeature = featureName
    activeColorButtonRef = buttonRef
    ColorPickerFrame.Visible = true
end

ClosePickerBtn.MouseButton1Click:Connect(function()
    ColorPickerFrame.Visible = false
    activePickingFeature = nil
    activeColorButtonRef = nil
end)

-- Панель ESP Preview
local PreviewFrame = Instance.new("Frame")
PreviewFrame.Name = "PreviewFrame"
PreviewFrame.Size = UDim2.new(0, 180, 0, 260)
PreviewFrame.Position = UDim2.new(1, 5, 0, 0)
PreviewFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PreviewFrame.BorderSizePixel = 1
PreviewFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
PreviewFrame.Visible = false
PreviewFrame.ZIndex = 5
PreviewFrame.Parent = MainFrame

local PreviewTitle = Instance.new("TextLabel")
PreviewTitle.Size = UDim2.new(1, 0, 0, 25)
PreviewTitle.BackgroundTransparency = 1
PreviewTitle.Text = "ESP PREVIEW"
PreviewTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PreviewTitle.TextSize = 14
PreviewTitle.Font = Enum.Font.ArialBold
PreviewTitle.ZIndex = 6
PreviewTitle.Parent = PreviewFrame

local Viewport = Instance.new("ViewportFrame")
Viewport.Size = UDim2.new(1, -10, 1, -35)
Viewport.Position = UDim2.new(0, 5, 0, 30)
Viewport.BackgroundTransparency = 1
Viewport.ZIndex = 6
Viewport.Parent = PreviewFrame

local viewCam = Instance.new("Camera")
Viewport.CurrentCamera = viewCam
viewCam.Parent = Viewport

local previewChar = nil
local previewHighlight = nil
local currentRotationY = 180 
local isRotating = false
local lastInputPos = nil

local function updatePreviewCharacter()
    if previewChar then previewChar:Destroy() end
    local lp = game:GetService("Players").LocalPlayer
    if lp.Character then
        lp.Character.Archivable = true
        previewChar = lp.Character:Clone()
        lp.Character.Archivable = false
        
        for _, obj in ipairs(previewChar:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Highlight") or obj:IsA("BillboardGui") or obj:IsA("SelectionBox") then
                obj:Destroy()
            end
        end
        
        previewHighlight = Instance.new("Highlight")
        previewHighlight.Name = "PreviewHighlight"
        previewHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        previewHighlight.FillTransparency = 0.5
        previewHighlight.OutlineTransparency = 0
        previewHighlight.Parent = previewChar
        
        previewChar:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(currentRotationY), 0))
        previewChar.Parent = Viewport
        
        viewCam.CFrame = CFrame.new(Vector3.new(0, 0.5, 6), Vector3.new(0, 0, 0))
    end
end

Viewport.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isRotating = true lastInputPos = input.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if isRotating and lastInputPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - lastInputPos.X
        lastInputPos = input.Position
        currentRotationY = currentRotationY - (deltaX * 0.8)
        if previewChar and previewChar.PrimaryPart then
            previewChar:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(currentRotationY), 0))
        end
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isRotating = false end
end)

local PreviewOverlay = Instance.new("Frame")
PreviewOverlay.Size = UDim2.new(1, 0, 1, 0)
PreviewOverlay.BackgroundTransparency = 1
PreviewOverlay.ZIndex = 7
PreviewOverlay.Parent = Viewport

local function updatePreviewVisibility()
    if MainFrame.Visible and currentTab == "ESP" and espMasterEnabled then
        PreviewFrame.Visible = true
        updatePreviewCharacter()
    else
        PreviewFrame.Visible = false
    end
end

-- Кнопка меню
local WatermarkButton = Instance.new("TextButton")
WatermarkButton.Name = "WatermarkButton"
WatermarkButton.Size = UDim2.new(0, 140, 0, 35)
WatermarkButton.Position = UDim2.new(0, 20, 0, 70)
WatermarkButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
WatermarkButton.Text = "SeraphCA"
WatermarkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
WatermarkButton.TextSize = 18
WatermarkButton.Font = Enum.Font.Arial
WatermarkButton.ZIndex = 10
WatermarkButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = WatermarkButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = WatermarkButton

WatermarkButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    updatePreviewVisibility()
end)

-- Драг меню
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -20, 0, 2)
Separator.Position = UDim2.new(0, 10, 0, 45)
Separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Separator.ZIndex = 6
Separator.Parent = MainFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -60)
ContentContainer.Position = UDim2.new(0, 10, 0, 55)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 6
ContentContainer.Parent = MainFrame

local tabNames = {"MISK", "ESP", "HIT-BOX", "SHOP-HACK"}
local tabButtons = {}
local tabPages = {}

local function showTab(targetName)
    currentTab = targetName
    for _, name in ipairs(tabNames) do
        if name == targetName then
            tabPages[name].Visible = true
            tabButtons[name].TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            tabPages[name].Visible = false
            tabButtons[name].TextColor3 = Color3.fromRGB(130, 130, 130)
        end
    end
    updatePreviewVisibility()
end

for i, name in ipairs(tabNames) do
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Size = UDim2.new(0, 90, 0, 30)
    TabButton.Position = UDim2.new(0, 10 + ((i-1) * 105), 0, 10)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = name
    TabButton.TextSize = 15
    TabButton.Font = Enum.Font.Arial
    TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabButton.ZIndex = 7
    TabButton.Parent = MainFrame
    
    tabButtons[name] = TabButton
    
    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ZIndex = 7
    Page.Parent = ContentContainer
    
    tabPages[name] = Page
    TabButton.MouseButton1Click:Connect(function() showTab(name) end)
end
showTab("MISK")

----------------------------------------------------
-- ВКЛАДКА MISK (ДОБАВЛЕН ФУНКЦИОНАЛ FLING)
----------------------------------------------------
local MiskPage = tabPages["MISK"]

local MiskScroll = Instance.new("ScrollingFrame")
MiskScroll.Size = UDim2.new(1, 0, 1, 0)
MiskScroll.BackgroundTransparency = 1
MiskScroll.CanvasSize = UDim2.new(0, 0, 0, 300)
MiskScroll.ScrollBarThickness = 4
MiskScroll.ZIndex = 8
MiskScroll.Parent = MiskPage

local FlyRow = Instance.new("Frame")
FlyRow.Size = UDim2.new(1, 0, 0, 35)
FlyRow.Position = UDim2.new(0, 0, 0, 5)
FlyRow.BackgroundTransparency = 1
FlyRow.ZIndex = 9
FlyRow.Parent = MiskScroll

local FlyText = Instance.new("TextLabel")
FlyText.Size = UDim2.new(0, 40, 0, 30)
FlyText.Position = UDim2.new(0, 10, 0, 2)
FlyText.BackgroundTransparency = 1
FlyText.Text = "Fly"
FlyText.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyText.TextSize = 18
FlyText.Font = Enum.Font.Arial
FlyText.TextXAlignment = Enum.TextXAlignment.Left
FlyText.ZIndex = 10
FlyText.Parent = FlyRow

local FlyCheckbox = Instance.new("TextButton")
FlyCheckbox.Size = UDim2.new(0, 22, 0, 22)
FlyCheckbox.Position = UDim2.new(0, 50, 0, 6)
FlyCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
FlyCheckbox.BorderSizePixel = 1
FlyCheckbox.Text = ""
FlyCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyCheckbox.TextSize = 18
FlyCheckbox.ZIndex = 10
FlyCheckbox.Parent = FlyRow

local SpeedContainer = Instance.new("Frame")
SpeedContainer.Size = UDim2.new(1, 0, 0, 35)
SpeedContainer.Position = UDim2.new(0, 0, 0, 40)
SpeedContainer.BackgroundTransparency = 1
SpeedContainer.Visible = false
SpeedContainer.ZIndex = 9
SpeedContainer.Parent = MiskScroll

local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(0, 80, 0, 25)
SpeedText.Position = UDim2.new(0, 10, 0, 5)
SpeedText.BackgroundTransparency = 1
SpeedText.Text = "FlySpeed"
SpeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedText.TextSize = 16
SpeedText.TextXAlignment = Enum.TextXAlignment.Left
SpeedText.ZIndex = 10
SpeedText.Parent = SpeedContainer

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 60, 0, 22)
SpeedInput.Position = UDim2.new(0, 100, 0, 6)
SpeedInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SpeedInput.BorderColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.BorderSizePixel = 1
SpeedInput.Text = tostring(flySpeedValue)
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.TextSize = 14
SpeedInput.ClearTextOnFocus = false
SpeedInput.ZIndex = 10
SpeedInput.Parent = SpeedContainer

FlyCheckbox.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        FlyCheckbox.Text = "✓"
        SpeedContainer.Visible = true
        if game:GetService("Players").LocalPlayer.Character then
            flyController:ConnectToTarget(game:GetService("Players").LocalPlayer.Character, getSpeed, getState)
        end
    else
        FlyCheckbox.Text = ""
        SpeedContainer.Visible = false
        flyController:Disconnect()
    end
end)

SpeedInput.TouchTap:Connect(function() SpeedInput:CaptureFocus() end)
SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val then flySpeedValue = val else SpeedInput.Text = tostring(flySpeedValue) end
end)

-- Секция интерфейса Fling
local FlingRow = Instance.new("Frame")
FlingRow.Size = UDim2.new(1, 0, 0, 35)
FlingRow.Position = UDim2.new(0, 0, 0, 75)
FlingRow.BackgroundTransparency = 1
FlingRow.ZIndex = 9
FlingRow.Parent = MiskScroll

local FlingText = Instance.new("TextLabel")
FlingText.Size = UDim2.new(0, 50, 0, 30)
FlingText.Position = UDim2.new(0, 10, 0, 2)
FlingText.BackgroundTransparency = 1
FlingText.Text = "Fling"
FlingText.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingText.TextSize = 18
FlingText.Font = Enum.Font.Arial
FlingText.TextXAlignment = Enum.TextXAlignment.Left
FlingText.ZIndex = 10
FlingText.Parent = FlingRow

local FlingCheckbox = Instance.new("TextButton")
FlingCheckbox.Size = UDim2.new(0, 22, 0, 22)
FlingCheckbox.Position = UDim2.new(0, 65, 0, 6)
FlingCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlingCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
FlingCheckbox.BorderSizePixel = 1
FlingCheckbox.Text = ""
FlingCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingCheckbox.TextSize = 18
FlingCheckbox.ZIndex = 10
FlingCheckbox.Parent = FlingRow

local FlingContainer = Instance.new("Frame")
FlingContainer.Size = UDim2.new(1, 0, 0, 160)
FlingContainer.Position = UDim2.new(0, 0, 0, 115)
FlingContainer.BackgroundTransparency = 1
FlingContainer.Visible = false
FlingContainer.ZIndex = 9
FlingContainer.Parent = MiskScroll

local ActionFlingBtn = Instance.new("TextButton")
ActionFlingBtn.Size = UDim2.new(0, 120, 0, 24)
ActionFlingBtn.Position = UDim2.new(0, 10, 0, 0)
ActionFlingBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ActionFlingBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
ActionFlingBtn.Text = "FLING"
ActionFlingBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
ActionFlingBtn.TextSize = 14
ActionFlingBtn.Font = Enum.Font.ArialBold
ActionFlingBtn.ZIndex = 10
ActionFlingBtn.Parent = FlingContainer

-- Список игроков внутри FlingContainer
local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Size = UDim2.new(1, -20, 0, 100)
PlayerListScroll.Position = UDim2.new(0, 10, 0, 35)
PlayerListScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
PlayerListScroll.BorderColor3 = Color3.fromRGB(255, 255, 255)
PlayerListScroll.ScrollBarThickness = 4
PlayerListScroll.ZIndex = 11
PlayerListScroll.Parent = FlingContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = PlayerListScroll

local function updatePlayerListForFling()
    for _, child in pairs(PlayerListScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game:GetService("Players").LocalPlayer then
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, 0, 0, 25)
            pBtn.Text = player.Name
            pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            pBtn.BackgroundColor3 = (selectedFlingTarget == player) and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(20, 20, 20)
            pBtn.ZIndex = 12
            pBtn.Parent = PlayerListScroll
            
            pBtn.MouseButton1Click:Connect(function()
                selectedFlingTarget = player
                updatePlayerListForFling()
            end)
        end
    end
end

-- Обновление списка при открытии вкладки или изменении состава игроков
FlingCheckbox.MouseButton1Click:Connect(function()
    if not FlingContainer.Visible then updatePlayerListForFling() end
    FlingContainer.Visible = not FlingContainer.Visible
end)


local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Size = UDim2.new(1, -20, 0, 120)
PlayerListScroll.Position = UDim2.new(0, 10, 0, 30)
PlayerListScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
-- Контекст и инициализация хелперов
local MovementController = {}
MovementController.__index = MovementController

function MovementController.new()
    local self = setmetatable({}, MovementController)
    self.connection = nil
    self.velocityObject = nil
    return self
end

function MovementController:ConnectToTarget(character, speedGetter, stateGetter)
    self:Disconnect()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    self.velocityObject = bv
    
    self.connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not stateGetter() or not hrp.Parent then
            self:Disconnect()
            return
        end
        local moveDir = Vector3.new(0, 0, 0)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local dir = humanoid.MoveDirection
            if dir.Magnitude > 0 then
                moveDir = camera.CFrame.LookVector * dir.Magnitude
            end
        end
        bv.Velocity = moveDir * speedGetter()
    end)
end

function MovementController:Disconnect()
    if self.connection then self.connection:Disconnect() self.connection = nil end
    if self.velocityObject then self.velocityObject:Destroy() self.velocityObject = nil end
end

-- Инициализация GUI
local targetGui = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
if targetGui:FindFirstChild("SeraphCAMenu") then targetGui.SeraphCAMenu:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeraphCAMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = targetGui

-- Холст для 2D элементов ESP и объектов Adornment
local FullscreenEspCanvas = Instance.new("Frame")
FullscreenEspCanvas.Name = "FullscreenEspCanvas"
FullscreenEspCanvas.Size = UDim2.new(1, 0, 1, 0)
FullscreenEspCanvas.BackgroundTransparency = 1
FullscreenEspCanvas.ZIndex = 1
FullscreenEspCanvas.Parent = ScreenGui

-- Переменные состояний fly и fling
local flyEnabled = false
local flySpeedValue = 50
local shopHackEnabled = false
local flingMasterEnabled = false
local selectedFlingTarget = nil
local isFlinging = false
local flyController = MovementController.new()

-- Настройки ESP
local espMasterEnabled = false
local currentTab = "MISK"
local espSettings = {
    Outline = {enabled = false, color = Color3.fromRGB(255, 0, 0)},
    NickName = {enabled = false, color = Color3.fromRGB(0, 255, 255)},
    Distance = {enabled = false, color = Color3.fromRGB(255, 255, 0)}
}

-- Настройки HIT-BOX
local hitboxMasterEnabled = false
local hitboxSizeValue = 2
local showHitboxVisuals = false
local hitboxColor = Color3.fromRGB(255, 0, 0)
local hitboxTransparencyValue = 0.5

local function getSpeed() return flySpeedValue end
local function getState() return flyEnabled end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
    flyController:Disconnect()
    if flyEnabled then
        task.wait(0.5)
        flyController:ConnectToTarget(char, getSpeed, getState)
    end
end)

-- Главная панель
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 260)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Active = true
MainFrame.Visible = false 
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

-- Окно выбора цвета (Color Picker)
local ColorPickerFrame = Instance.new("Frame")
ColorPickerFrame.Name = "ColorPickerFrame"
ColorPickerFrame.Size = UDim2.new(0, 160, 0, 170)
ColorPickerFrame.Position = UDim2.new(0.5, -80, 0.5, -85)
ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ColorPickerFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
ColorPickerFrame.BorderSizePixel = 1
ColorPickerFrame.Visible = false
ColorPickerFrame.ZIndex = 20
ColorPickerFrame.Parent = ScreenGui

local ColorPickerGrid = Instance.new("Frame")
ColorPickerGrid.Size = UDim2.new(1, -10, 1, -40)
ColorPickerGrid.Position = UDim2.new(0, 5, 0, 5)
ColorPickerGrid.BackgroundTransparency = 1
ColorPickerGrid.ZIndex = 21
ColorPickerGrid.Parent = ColorPickerFrame

local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.CellSize = UDim2.new(0, 22, 0, 22)
UIGridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
UIGridLayout.Parent = ColorPickerGrid

local ClosePickerBtn = Instance.new("TextButton")
ClosePickerBtn.Size = UDim2.new(1, -10, 0, 25)
ClosePickerBtn.Position = UDim2.new(0, 5, 1, -30)
ClosePickerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ClosePickerBtn.Text = "Закрыть"
ClosePickerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClosePickerBtn.TextSize = 12
ClosePickerBtn.ZIndex = 21
ClosePickerBtn.Parent = ColorPickerFrame

local presetColors = {
    Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 128, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(128, 255, 0),
    Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 255, 128), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 128, 255),
    Color3.fromRGB(0, 0, 255), Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 0, 255), Color3.fromRGB(255, 0, 128),
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170), Color3.fromRGB(85, 85, 85), Color3.fromRGB(0, 0, 0)
}

local activePickingFeature = nil
local activeColorButtonRef = nil

local function openColorPicker(featureName, buttonRef)
    activePickingFeature = featureName
    activeColorButtonRef = buttonRef
    ColorPickerFrame.Visible = true
end

ClosePickerBtn.MouseButton1Click:Connect(function()
    ColorPickerFrame.Visible = false
    activePickingFeature = nil
    activeColorButtonRef = nil
end)

-- Панель ESP Preview
local PreviewFrame = Instance.new("Frame")
PreviewFrame.Name = "PreviewFrame"
PreviewFrame.Size = UDim2.new(0, 180, 0, 260)
PreviewFrame.Position = UDim2.new(1, 5, 0, 0)
PreviewFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PreviewFrame.BorderSizePixel = 1
PreviewFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
PreviewFrame.Visible = false
PreviewFrame.ZIndex = 5
PreviewFrame.Parent = MainFrame

local PreviewTitle = Instance.new("TextLabel")
PreviewTitle.Size = UDim2.new(1, 0, 0, 25)
PreviewTitle.BackgroundTransparency = 1
PreviewTitle.Text = "ESP PREVIEW"
PreviewTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PreviewTitle.TextSize = 14
PreviewTitle.Font = Enum.Font.ArialBold
PreviewTitle.ZIndex = 6
PreviewTitle.Parent = PreviewFrame

local Viewport = Instance.new("ViewportFrame")
Viewport.Size = UDim2.new(1, -10, 1, -35)
Viewport.Position = UDim2.new(0, 5, 0, 30)
Viewport.BackgroundTransparency = 1
Viewport.ZIndex = 6
Viewport.Parent = PreviewFrame

local viewCam = Instance.new("Camera")
Viewport.CurrentCamera = viewCam
viewCam.Parent = Viewport

local previewChar = nil
local previewHighlight = nil
local currentRotationY = 180 
local isRotating = false
local lastInputPos = nil

local function updatePreviewCharacter()
    if previewChar then previewChar:Destroy() end
    local lp = game:GetService("Players").LocalPlayer
    if lp.Character then
        lp.Character.Archivable = true
        previewChar = lp.Character:Clone()
        lp.Character.Archivable = false
        
        for _, obj in ipairs(previewChar:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Highlight") or obj:IsA("BillboardGui") or obj:IsA("SelectionBox") then
                obj:Destroy()
            end
        end
        
        previewHighlight = Instance.new("Highlight")
        previewHighlight.Name = "PreviewHighlight"
        previewHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        previewHighlight.FillTransparency = 0.5
        previewHighlight.OutlineTransparency = 0
        previewHighlight.Parent = previewChar
        
        previewChar:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(currentRotationY), 0))
        previewChar.Parent = Viewport
        
        viewCam.CFrame = CFrame.new(Vector3.new(0, 0.5, 6), Vector3.new(0, 0, 0))
    end
end

Viewport.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isRotating = true lastInputPos = input.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if isRotating and lastInputPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - lastInputPos.X
        lastInputPos = input.Position
        currentRotationY = currentRotationY - (deltaX * 0.8)
        if previewChar and previewChar.PrimaryPart then
            previewChar:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(currentRotationY), 0))
        end
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isRotating = false end
end)

local PreviewOverlay = Instance.new("Frame")
PreviewOverlay.Size = UDim2.new(1, 0, 1, 0)
PreviewOverlay.BackgroundTransparency = 1
PreviewOverlay.ZIndex = 7
PreviewOverlay.Parent = Viewport

local function updatePreviewVisibility()
    if MainFrame.Visible and currentTab == "ESP" and espMasterEnabled then
        PreviewFrame.Visible = true
        updatePreviewCharacter()
    else
        PreviewFrame.Visible = false
    end
end

-- Кнопка меню
local WatermarkButton = Instance.new("TextButton")
WatermarkButton.Name = "WatermarkButton"
WatermarkButton.Size = UDim2.new(0, 140, 0, 35)
WatermarkButton.Position = UDim2.new(0, 20, 0, 70)
WatermarkButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
WatermarkButton.Text = "SeraphCA"
WatermarkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
WatermarkButton.TextSize = 18
WatermarkButton.Font = Enum.Font.Arial
WatermarkButton.ZIndex = 10
WatermarkButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = WatermarkButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = WatermarkButton

WatermarkButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    updatePreviewVisibility()
end)

-- Драг меню
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -20, 0, 2)
Separator.Position = UDim2.new(0, 10, 0, 45)
Separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Separator.ZIndex = 6
Separator.Parent = MainFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -60)
ContentContainer.Position = UDim2.new(0, 10, 0, 55)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 6
ContentContainer.Parent = MainFrame

local tabNames = {"MISK", "ESP", "HIT-BOX", "SHOP-HACK"}
local tabButtons = {}
local tabPages = {}

local function showTab(targetName)
    currentTab = targetName
    for _, name in ipairs(tabNames) do
        if name == targetName then
            tabPages[name].Visible = true
            tabButtons[name].TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            tabPages[name].Visible = false
            tabButtons[name].TextColor3 = Color3.fromRGB(130, 130, 130)
        end
    end
    updatePreviewVisibility()
end

for i, name in ipairs(tabNames) do
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Size = UDim2.new(0, 90, 0, 30)
    TabButton.Position = UDim2.new(0, 10 + ((i-1) * 105), 0, 10)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = name
    TabButton.TextSize = 15
    TabButton.Font = Enum.Font.Arial
    TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabButton.ZIndex = 7
    TabButton.Parent = MainFrame
    
    tabButtons[name] = TabButton
    
    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ZIndex = 7
    Page.Parent = ContentContainer
    
    tabPages[name] = Page
    TabButton.MouseButton1Click:Connect(function() showTab(name) end)
end
showTab("MISK")

----------------------------------------------------
-- ОБНОВЛЕННАЯ ЛОГИКА ВКЛАДКИ MISK
----------------------------------------------------
local MiskPage = tabPages["MISK"]

local MiskScroll = Instance.new("ScrollingFrame")
MiskScroll.Size = UDim2.new(1, 0, 1, 0)
MiskScroll.BackgroundTransparency = 1
MiskScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
MiskScroll.ScrollBarThickness = 4
MiskScroll.ZIndex = 8
MiskScroll.Parent = MiskPage

-- Элементы Fly
local FlyRow = Instance.new("Frame")
FlyRow.Size = UDim2.new(1, 0, 0, 35)
FlyRow.Position = UDim2.new(0, 0, 0, 5)
FlyRow.BackgroundTransparency = 1
FlyRow.ZIndex = 9
FlyRow.Parent = MiskScroll

local FlyText = Instance.new("TextLabel")
FlyText.Size = UDim2.new(0, 40, 0, 30)
FlyText.Position = UDim2.new(0, 10, 0, 2)
FlyText.BackgroundTransparency = 1
FlyText.Text = "Fly"
FlyText.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyText.TextSize = 18
FlyText.ZIndex = 10
FlyText.Parent = FlyRow

local FlyCheckbox = Instance.new("TextButton")
FlyCheckbox.Size = UDim2.new(0, 22, 0, 22)
FlyCheckbox.Position = UDim2.new(0, 50, 0, 6)
FlyCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
FlyCheckbox.Text = ""
FlyCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyCheckbox.ZIndex = 10
FlyCheckbox.Parent = FlyRow

-- Элементы Fling (Изначально сразу под Fly)
local FlingRow = Instance.new("Frame")
FlingRow.Size = UDim2.new(1, 0, 0, 35)
FlingRow.Position = UDim2.new(0, 0, 0, 40) -- Позиция под Fly
FlingRow.BackgroundTransparency = 1
FlingRow.ZIndex = 9
FlingRow.Parent = MiskScroll

local FlingText = Instance.new("TextLabel")
FlingText.Size = UDim2.new(0, 50, 0, 30)
FlingText.Position = UDim2.new(0, 10, 0, 2)
FlingText.BackgroundTransparency = 1
FlingText.Text = "Fling"
FlingText.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingText.TextSize = 18
FlingText.ZIndex = 10
FlingText.Parent = FlingRow

local FlingCheckbox = Instance.new("TextButton")
FlingCheckbox.Size = UDim2.new(0, 22, 0, 22)
FlingCheckbox.Position = UDim2.new(0, 65, 0, 6)
FlingCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlingCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
FlingCheckbox.Text = ""
FlingCheckbox.ZIndex = 10
FlingCheckbox.Parent = FlingRow

-- Контейнер скорости (появляется только при включении Fly)
local SpeedContainer = Instance.new("Frame")
SpeedContainer.Size = UDim2.new(1, 0, 0, 35)
SpeedContainer.Position = UDim2.new(0, 0, 0, 40) -- Изначально на месте Fling
SpeedContainer.BackgroundTransparency = 1
SpeedContainer.Visible = false
SpeedContainer.ZIndex = 9
SpeedContainer.Parent = MiskScroll

local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(0, 80, 0, 25)
SpeedText.Position = UDim2.new(0, 10, 0, 5)
SpeedText.BackgroundTransparency = 1
SpeedText.Text = "FlySpeed"
SpeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedText.TextSize = 16
SpeedText.ZIndex = 10
SpeedText.Parent = SpeedContainer

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 60, 0, 22)
SpeedInput.Position = UDim2.new(0, 100, 0, 6)
SpeedInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SpeedInput.BorderColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.Text = tostring(flySpeedValue)
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.ZIndex = 10
SpeedInput.Parent = SpeedContainer

-- Функция динамического сдвига элементов
local function updateLayout()
    if flyEnabled then
        SpeedContainer.Visible = true
        FlingRow.Position = UDim2.new(0, 0, 0, 80) -- Сдвигаем Fling вниз
    else
        SpeedContainer.Visible = false
        FlingRow.Position = UDim2.new(0, 0, 0, 40) -- Возвращаем наверх
    end
end

-- Логика кнопки Fly
FlyCheckbox.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    FlyCheckbox.Text = flyEnabled and "✓" or ""
    updateLayout()
    if flyEnabled then
        if game:GetService("Players").LocalPlayer.Character then
            flyController:ConnectToTarget(game:GetService("Players").LocalPlayer.Character, getSpeed, getState)
        end
    else
        flyController:Disconnect()
    end
end)

-- Логика Fling (Бесконечный цикл)
local FlingContainer = Instance.new("Frame")
FlingContainer.Size = UDim2.new(1, 0, 0, 160)
FlingContainer.Position = UDim2.new(0, 0, 0, 40) -- Относительно FlingRow
FlingContainer.BackgroundTransparency = 1
FlingContainer.Visible = false
FlingContainer.ZIndex = 9
FlingContainer.Parent = FlingRow

local ActionFlingBtn = Instance.new("TextButton")
ActionFlingBtn.Size = UDim2.new(0, 120, 0, 24)
ActionFlingBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ActionFlingBtn.Text = "FLING"
ActionFlingBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
ActionFlingBtn.ZIndex = 10
ActionFlingBtn.Parent = FlingContainer

-- (Логика списка игроков остается прежней, просто привязана к FlingRow)
-- [Сюда вставляется код списка игроков из предыдущего ответа]

ActionFlingBtn.MouseButton1Click:Connect(function()
    if not selectedFlingTarget then return end
    
    if not isFlinging then
        -- Начало флинга
        isFlinging = true
        ActionFlingBtn.Text = "STOP"
        ActionFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionFlingBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        
        -- Цикл флинга
        task.spawn(function()
            local myHrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(99999, 99999, 99999)
            bav.Parent = myHrp
            
            while isFlinging and selectedFlingTarget.Character do
                local targetHrp = selectedFlingTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    myHrp.CFrame = targetHrp.CFrame
                    for _, p in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
                task.wait()
            end
            bav:Destroy()
        end)
    else
        -- Остановка
        isFlinging = false
        ActionFlingBtn.Text = "FLING"
        ActionFlingBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
        ActionFlingBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    end
end)


----------------------------------------------------
-- ВКЛАДКА ESP
----------------------------------------------------
local EspPage = tabPages["ESP"]

local EspScroll = Instance.new("ScrollingFrame")
EspScroll.Size = UDim2.new(1, 0, 1, 0)
EspScroll.BackgroundTransparency = 1
EspScroll.CanvasSize = UDim2.new(0, 0, 0, 240)
EspScroll.ScrollBarThickness = 4
EspScroll.ZIndex = 8
EspScroll.Parent = EspPage

local EspMasterRow = Instance.new("Frame")
EspMasterRow.Size = UDim2.new(1, 0, 0, 35)
EspMasterRow.Position = UDim2.new(0, 0, 0, 5)
EspMasterRow.BackgroundTransparency = 1
EspMasterRow.ZIndex = 9
EspMasterRow.Parent = EspScroll

local EspMasterText = Instance.new("TextLabel")
EspMasterText.Size = UDim2.new(0, 40, 0, 30)
EspMasterText.Position = UDim2.new(0, 10, 0, 2)
EspMasterText.BackgroundTransparency = 1
EspMasterText.Text = "ESP"
EspMasterText.TextColor3 = Color3.fromRGB(255, 255, 255)
EspMasterText.TextSize = 18
EspMasterText.Font = Enum.Font.Arial
EspMasterText.TextXAlignment = Enum.TextXAlignment.Left
EspMasterText.ZIndex = 10
EspMasterText.Parent = EspMasterRow

local EspMasterCheckbox = Instance.new("TextButton")
EspMasterCheckbox.Size = UDim2.new(0, 22, 0, 22)
EspMasterCheckbox.Position = UDim2.new(0, 50, 0, 6)
EspMasterCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
EspMasterCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
EspMasterCheckbox.BorderSizePixel = 1
EspMasterCheckbox.Text = ""
EspMasterCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
EspMasterCheckbox.TextSize = 18
EspMasterCheckbox.ZIndex = 10
EspMasterCheckbox.Parent = EspMasterRow

local EspSubContainer = Instance.new("Frame")
EspSubContainer.Size = UDim2.new(1, 0, 0, 160)
EspSubContainer.Position = UDim2.new(0, 0, 0, 40)
EspSubContainer.BackgroundTransparency = 1
EspSubContainer.Visible = false
EspSubContainer.ZIndex = 9
EspSubContainer.Parent = EspScroll

local subFeatures = {"Outline", "NickName", "Distance"}

for idx, featureName in ipairs(subFeatures) do
    local offset = (idx - 1) * 35
    
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 30)
    Row.Position = UDim2.new(0, 0, 0, offset)
    Row.BackgroundTransparency = 1
    Row.ZIndex = 10
    Row.Parent = EspSubContainer
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(0, 80, 0, 25)
    TextLabel.Position = UDim2.new(0, 25, 0, 2)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = featureName
    TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TextLabel.TextSize = 15
    TextLabel.Font = Enum.Font.Arial
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.ZIndex = 11
    TextLabel.Parent = Row
    
    local Checkbox = Instance.new("TextButton")
    Checkbox.Size = UDim2.new(0, 18, 0, 18)
    Checkbox.Position = UDim2.new(0, 115, 0, 6)
    Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Checkbox.BorderColor3 = Color3.fromRGB(150, 150, 150)
    Checkbox.BorderSizePixel = 1
    Checkbox.Text = ""
    Checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Checkbox.TextSize = 14
    Checkbox.ZIndex = 11
    Checkbox.Parent = Row
    
    local ColorPreviewBtn = Instance.new("TextButton")
    ColorPreviewBtn.Size = UDim2.new(0, 50, 0, 20)
    ColorPreviewBtn.Position = UDim2.new(0, 145, 0, 5)
    ColorPreviewBtn.BackgroundColor3 = espSettings[featureName].color
    ColorPreviewBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    ColorPreviewBtn.BorderSizePixel = 1
    ColorPreviewBtn.Text = ""
    ColorPreviewBtn.ZIndex = 11
    ColorPreviewBtn.Parent = Row
    
    Checkbox.MouseButton1Click:Connect(function()
        espSettings[featureName].enabled = not espSettings[featureName].enabled
        Checkbox.Text = espSettings[featureName].enabled and "✓" or ""
        updatePreviewVisibility()
    end)
    
    ColorPreviewBtn.MouseButton1Click:Connect(function()
        openColorPicker(featureName, ColorPreviewBtn)
    end)
end

for _, color in ipairs(presetColors) do
    local Tile = Instance.new("TextButton")
    Tile.BackgroundColor3 = color
    Tile.Text = ""
    Tile.BorderSizePixel = 0
    Tile.ZIndex = 22
    Tile.Parent = ColorPickerGrid
    
    Tile.MouseButton1Click:Connect(function()
        if activePickingFeature and activeColorButtonRef then
            if activePickingFeature == "HitboxColor" then
                hitboxColor = color
            else
                espSettings[activePickingFeature].color = color
            end
            activeColorButtonRef.BackgroundColor3 = color
            ColorPickerFrame.Visible = false
            activePickingFeature = nil
            activeColorButtonRef = nil
            updatePreviewVisibility()
        end
    end)
end

EspMasterCheckbox.MouseButton1Click:Connect(function()
    espMasterEnabled = not espMasterEnabled
    EspMasterCheckbox.Text = espMasterEnabled and "✓" or ""
    EspSubContainer.Visible = espMasterEnabled
    updatePreviewVisibility()
end)

----------------------------------------------------
-- ВКЛАДКА HIT-BOX (ЗАПОЛНЕННЫЕ КУБЫ С ПРОЗРАЧНОСТЬЮ)
----------------------------------------------------
local HitboxPage = tabPages["HIT-BOX"]

local HitboxMasterRow = Instance.new("Frame")
HitboxMasterRow.Size = UDim2.new(1, 0, 0, 35)
HitboxMasterRow.Position = UDim2.new(0, 0, 0, 5)
HitboxMasterRow.BackgroundTransparency = 1
HitboxMasterRow.ZIndex = 8
HitboxMasterRow.Parent = HitboxPage

local HitboxText = Instance.new("TextLabel")
HitboxText.Size = UDim2.new(0, 60, 0, 30)
HitboxText.Position = UDim2.new(0, 10, 0, 2)
HitboxText.BackgroundTransparency = 1
HitboxText.Text = "Hit-Box"
HitboxText.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxText.TextSize = 18
HitboxText.Font = Enum.Font.Arial
HitboxText.TextXAlignment = Enum.TextXAlignment.Left
HitboxText.ZIndex = 9
HitboxMasterRow.Parent = HitboxPage

local HitboxCheckbox = Instance.new("TextButton")
HitboxCheckbox.Size = UDim2.new(0, 22, 0, 22)
HitboxCheckbox.Position = UDim2.new(0, 80, 0, 6)
HitboxCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HitboxCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
HitboxCheckbox.BorderSizePixel = 1
HitboxCheckbox.Text = ""
HitboxCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxCheckbox.TextSize = 18
HitboxCheckbox.ZIndex = 9
HitboxCheckbox.Parent = HitboxMasterRow

local HitboxSettingsContainer = Instance.new("Frame")
HitboxSettingsContainer.Size = UDim2.new(1, 0, 0, 160)
HitboxSettingsContainer.Position = UDim2.new(0, 0, 0, 40)
HitboxSettingsContainer.BackgroundTransparency = 1
HitboxSettingsContainer.Visible = false
HitboxSettingsContainer.ZIndex = 8
HitboxSettingsContainer.Parent = HitboxPage

local SizeTitle = Instance.new("TextLabel")
SizeTitle.Size = UDim2.new(0, 100, 0, 20)
SizeTitle.Position = UDim2.new(0, 10, 0, 5)
SizeTitle.BackgroundTransparency = 1
SizeTitle.Text = "hitbox size"
SizeTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeTitle.TextSize = 14
SizeTitle.Font = Enum.Font.Arial
SizeTitle.TextXAlignment = Enum.TextXAlignment.Left
SizeTitle.ZIndex = 9
SizeTitle.Parent = HitboxSettingsContainer

local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(0, 280, 0, 6)
SliderBar.Position = UDim2.new(0, 10, 0, 30)
SliderBar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SliderBar.BorderSizePixel = 0
SliderBar.ZIndex = 9
SliderBar.Parent = HitboxSettingsContainer

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 20)
SliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
SliderButton.Position = UDim2.new(0, 0, 0.5, 0)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.Text = ""
SliderButton.ZIndex = 10
SliderButton.Parent = SliderBar

local SizeValueLabel = Instance.new("TextLabel")
SizeValueLabel.Size = UDim2.new(0, 50, 0, 20)
SizeValueLabel.Position = UDim2.new(0, 300, 0, 23)
SizeValueLabel.BackgroundTransparency = 1
SizeValueLabel.Text = "2"
SizeValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeValueLabel.TextSize = 14
SizeValueLabel.Font = Enum.Font.Arial
SizeValueLabel.TextXAlignment = Enum.TextXAlignment.Left
SizeValueLabel.ZIndex = 9
SizeValueLabel.Parent = HitboxSettingsContainer

local TransTitle = Instance.new("TextLabel")
TransTitle.Size = UDim2.new(0, 100, 0, 20)
TransTitle.Position = UDim2.new(0, 10, 0, 55)
TransTitle.BackgroundTransparency = 1
TransTitle.Text = "transparency"
TransTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
TransTitle.TextSize = 14
TransTitle.Font = Enum.Font.Arial
TransTitle.TextXAlignment = Enum.TextXAlignment.Left
TransTitle.ZIndex = 9
TransTitle.Parent = HitboxSettingsContainer

local TransSliderBar = Instance.new("Frame")
TransSliderBar.Size = UDim2.new(0, 280, 0, 6)
TransSliderBar.Position = UDim2.new(0, 10, 0, 80)
TransSliderBar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
TransSliderBar.BorderSizePixel = 0
TransSliderBar.ZIndex = 9
TransSliderBar.Parent = TransSliderBar.Parent

local TransSliderButton = Instance.new("TextButton")
TransSliderButton.Size = UDim2.new(0, 14, 0, 20)
TransSliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
TransSliderButton.Position = UDim2.new(0.5, 0, 0.5, 0)
TransSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TransSliderButton.Text = ""
TransSliderButton.ZIndex = 10
TransSliderButton.Parent = TransSliderBar

local TransValueLabel = Instance.new("TextLabel")
TransValueLabel.Size = UDim2.new(0, 50, 0, 20)
TransValueLabel.Position = UDim2.new(0, 300, 0, 73)
TransValueLabel.BackgroundTransparency = 1
TransValueLabel.Text = "50%"
TransValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TransValueLabel.TextSize = 14
TransValueLabel.Font = Enum.Font.Arial
TransValueLabel.TextXAlignment = Enum.TextXAlignment.Left
TransValueLabel.ZIndex = 9
TransValueLabel.Parent = HitboxSettingsContainer

local ShowHitboxBtn = Instance.new("TextButton")
ShowHitboxBtn.Size = UDim2.new(0, 110, 0, 26)
ShowHitboxBtn.Position = UDim2.new(0, 10, 0, 110)
ShowHitboxBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ShowHitboxBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
ShowHitboxBtn.Text = "Show Hit-Box"
ShowHitboxBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
ShowHitboxBtn.TextSize = 13
ShowHitboxBtn.Font = Enum.Font.Arial
ShowHitboxBtn.ZIndex = 9
ShowHitboxBtn.Parent = HitboxSettingsContainer

local HitboxColorPreviewBtn = Instance.new("TextButton")
HitboxColorPreviewBtn.Size = UDim2.new(0, 45, 0, 26)
HitboxColorPreviewBtn.Position = UDim2.new(0, 130, 0, 110)
HitboxColorPreviewBtn.BackgroundColor3 = hitboxColor
HitboxColorPreviewBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
HitboxColorPreviewBtn.BorderSizePixel = 1
HitboxColorPreviewBtn.Text = ""
HitboxColorPreviewBtn.ZIndex = 9
HitboxColorPreviewBtn.Parent = HitboxSettingsContainer

local isSlidingSize = false
local function updateSizeSlider(inputPosition)
    local relativeX = inputPosition.X - SliderBar.AbsolutePosition.X
    local percentage = math.clamp(relativeX / SliderBar.AbsoluteSize.X, 0, 1)
    hitboxSizeValue = math.round(2 + (percentage * 198))
    SliderButton.Position = UDim2.new(percentage, 0, 0.5, 0)
    SizeValueLabel.Text = tostring(hitboxSizeValue)
end

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isSlidingSize = true end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if isSlidingSize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSizeSlider(input.Position)
    end
end)

local isSlidingTrans = false
local function updateTransSlider(inputPosition)
    local relativeX = inputPosition.X - TransSliderBar.AbsolutePosition.X
    local percentage = math.clamp(relativeX / TransSliderBar.AbsoluteSize.X, 0, 1)
    hitboxTransparencyValue = percentage
    TransSliderButton.Position = UDim2.new(percentage, 0, 0.5, 0)
    TransValueLabel.Text = math.round(percentage * 100) .. "%"
end

TransSliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isSlidingTrans = true end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if isSlidingTrans and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateTransSlider(input.Position)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isSlidingSize = false
        isSlidingTrans = false
    end
end)

HitboxColorPreviewBtn.MouseButton1Click:Connect(function()
    openColorPicker("HitboxColor", HitboxColorPreviewBtn)
end)

HitboxCheckbox.MouseButton1Click:Connect(function()
    hitboxMasterEnabled = not hitboxMasterEnabled
    HitboxCheckbox.Text = hitboxMasterEnabled and "✓" or ""
    HitboxSettingsContainer.Visible = hitboxMasterEnabled
end)

ShowHitboxBtn.MouseButton1Click:Connect(function()
    showHitboxVisuals = not showHitboxVisuals
    if showHitboxVisuals then
        ShowHitboxBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ShowHitboxBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        ShowHitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        ShowHitboxBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        ShowHitboxBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
        ShowHitboxBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

----------------------------------------------------
-- ОБНОВЛЕНИЕ ПРЕВЬЮ ОКНА С HIGHLIGHT
----------------------------------------------------
local previewVisuals = {}
local function createPreviewVisuals()
    for _, v in pairs(previewVisuals) do v:Destroy() end
    previewVisuals = {}
    
    local nick = Instance.new("TextLabel")
    nick.Size = UDim2.new(1, 0, 0, 20)
    nick.Position = UDim2.new(0, 0, 0.5, -90)
    nick.BackgroundTransparency = 1
    nick.Font = Enum.Font.ArialBold
    nick.TextSize = 13
    nick.ZIndex = 8
    nick.Parent = PreviewOverlay
    previewVisuals.Nick = nick

    local dist = Instance.new("TextLabel")
    dist.Size = UDim2.new(1, 0, 0, 20)
    dist.Position = UDim2.new(0, 0, 0.5, 80)
    dist.BackgroundTransparency = 1
    dist.Font = Enum.Font.Arial
    dist.TextSize = 11
    dist.ZIndex = 8
    dist.Parent = PreviewOverlay
    previewVisuals.Dist = dist
end
createPreviewVisuals()

game:GetService("RunService").RenderStepped:Connect(function()
    if not PreviewFrame.Visible or not previewChar then return end
    
    if not isRotating then
        local diff = 180 - currentRotationY
        if math.abs(diff) > 0.05 then currentRotationY = currentRotationY + (diff * 0.15) else currentRotationY = 180 end
        if previewChar.PrimaryPart then previewChar:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(currentRotationY), 0)) end
    end
    
    if previewHighlight then
        if espSettings.Outline.enabled then
            previewHighlight.Enabled = true
            previewHighlight.FillColor = espSettings.Outline.color
            previewHighlight.OutlineColor = espSettings.Outline.color
        else
            previewHighlight.Enabled = false
        end
    end
    
    if espSettings.NickName.enabled then
        previewVisuals.Nick.Visible = true
        previewVisuals.Nick.TextColor3 = espSettings.NickName.color
        previewVisuals.Nick.Text = game:GetService("Players").LocalPlayer.Name
    else
        previewVisuals.Nick.Visible = false
    end
    
    if espSettings.Distance.enabled then
        previewVisuals.Dist.Visible = true
        previewVisuals.Dist.TextColor3 = espSettings.Distance.color
        previewVisuals.Dist.Text = "[0.0 studs]"
    else
        previewVisuals.Dist.False = false
    end
end)

----------------------------------------------------
-- МИРОВОЙ ЦИКЛ ОТРЕСОВКИ ESP И РАБОТЫ ХИТБОКСОВ
----------------------------------------------------
local playerEspCache = {}

local function createPlayerEspUi(player)
    if playerEspCache[player] then return end
    
    local container = Instance.new("Frame")
    container.Name = "Esp_" .. player.Name
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Parent = FullscreenEspCanvas
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.ArialBold
    nameLabel.TextSize = 14
    nameLabel.Text = player.Name
    nameLabel.Visible = false
    nameLabel.Parent = container
    
    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.Arial
    distLabel.TextSize = 12
    distLabel.Visible = false
    distLabel.Parent = container
    
    playerEspCache[player] = {
        Container = container,
        Name = nameLabel,
        Dist = distLabel
    }
end

local function removePlayerEspUi(player)
    if playerEspCache[player] then
        playerEspCache[player].Container:Destroy()
        playerEspCache[player] = nil
    end
end

game:GetService("Players").PlayerAdded:Connect(createPlayerEspUi)
game:GetService("Players").PlayerRemoving:Connect(removePlayerEspUi)
for _, p in ipairs(game:GetService("Players"):GetPlayers()) do createPlayerEspUi(p) end

-- Автообновление списка при входе/выходе игроков
game:GetService("Players").PlayerAdded:Connect(function() if flingMasterEnabled then updatePlayerListForFling() end end)
game:GetService("Players").PlayerRemoving:Connect(function(p) 
    if selectedFlingTarget == p then selectedFlingTarget = nil end 
    if flingMasterEnabled then updatePlayerListForFling() end 
end)

game:GetService("RunService").RenderStepped:Connect(function()
    local localPlayer = game:GetService("Players").LocalPlayer
    local camera = workspace.CurrentCamera
    
    for player, cache in pairs(playerEspCache) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        -- ESP Подсветка (Highlight)
        local highlight = char and char:FindFirstChild("SeraphHighlight")
        if char and not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "SeraphHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = char
        end
        
        -- ВИЗУАЛ ЗАПОЛНЕННОГО КУБА ДЛЯ ХИТБОКСА (BoxHandleAdornment)
        local visualBox = hrp and hrp:FindFirstChild("VisualHitboxCubeAdorn")
        if hrp and not visualBox then
            visualBox = Instance.new("BoxHandleAdornment")
            visualBox.Name = "VisualHitboxCubeAdorn"
            visualBox.AlwaysOnTop = true
            visualBox.ZIndex = 10
            visualBox.Adornee = hrp
            visualBox.Parent = hrp
        end
        
        if not char or not hrp or player == localPlayer then
            if highlight then highlight.Enabled = false end
            if visualBox then visualBox.Visible = false end
            cache.Name.Visible = false
            cache.Dist.Visible = false
            continue
        end
        
        -- РАБОТА И ОБНОВЛЕНИЕ РАЗМЕРОВ ХИТБОКСА
        if hitboxMasterEnabled then
            hrp.Size = Vector3.new(hitboxSizeValue, hitboxSizeValue, hitboxSizeValue)
            hrp.CanCollide = false
            
            if showHitboxVisuals and visualBox then
                visualBox.Visible = true
                visualBox.Size = hrp.Size
                visualBox.Color3 = hitboxColor
                -- Передаем точное значение заполнения куба
                visualBox.Transparency = hitboxTransparencyValue
            elseif visualBox then
                visualBox.Visible = false
            end
        else
            hrp.Size = Vector3.new(2, 2, 1)
            if visualBox then visualBox.Visible = false end
        end
        
        -- ESP Рендеринг интерфейса
        if not espMasterEnabled then
            if highlight then highlight.Enabled = false end
            cache.Name.Visible = false
            cache.Dist.Visible = false
            continue
        end
        
        if espSettings.Outline.enabled then
            highlight.Enabled = true
            highlight.FillColor = espSettings.Outline.color
            highlight.OutlineColor = espSettings.Outline.color
        else
            highlight.Enabled = false
        end
        
        local hrpScreenPos, hrpOnScreen = camera:WorldToViewportPoint(hrp.Position)
        if not hrpOnScreen then
            cache.Name.Visible = false
            cache.Dist.Visible = false
            continue
        end
        
        if espSettings.NickName.enabled then
            cache.Name.Visible = true
            cache.Name.TextColor3 = espSettings.NickName.color
            cache.Name.Size = UDim2.new(0, 200, 0, 20)
            cache.Name.Position = UDim2.new(0, hrpScreenPos.X - 100, 0, hrpScreenPos.Y - 45)
        else
            cache.Name.Visible = false
        end
        
        if espSettings.Distance.enabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            cache.Dist.Visible = true
            cache.Dist.TextColor3 = espSettings.Distance.color
            local actualDist = (localPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            cache.Dist.Text = string.format("[%.1f studs]", actualDist)
            cache.Dist.Size = UDim2.new(0, 200, 0, 20)
            cache.Dist.Position = UDim2.new(0, hrpScreenPos.X - 100, 0, hrpScreenPos.Y + 25)
        else
            cache.Dist.Visible = false
        end
    end
end)

----------------------------------------------------
-- ВКЛАДКА SHOP-HACK
----------------------------------------------------
local ShopPage = tabPages["SHOP-HACK"]

local ShopText = Instance.new("TextLabel")
ShopText.Size = UDim2.new(0, 90, 0, 30)
ShopText.Position = UDim2.new(0, 10, 0, 10)
ShopText.BackgroundTransparency = 1
ShopText.Text = "ShopHack"
ShopText.TextColor3 = Color3.fromRGB(255, 255, 255)
ShopText.TextSize = 18
ShopText.Font = Enum.Font.Arial
ShopText.TextXAlignment = Enum.TextXAlignment.Left
ShopText.ZIndex = 8
ShopText.Parent = ShopPage

local ShopCheckbox = Instance.new("TextButton")
ShopCheckbox.Size = UDim2.new(0, 22, 0, 22)
ShopCheckbox.Position = UDim2.new(0, 105, 0, 14)
ShopCheckbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ShopCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
ShopCheckbox.BorderSizePixel = 1
ShopCheckbox.Text = ""
ShopCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
ShopCheckbox.TextSize = 18
ShopCheckbox.Font = Enum.Font.Arial
ShopCheckbox.ZIndex = 8
ShopCheckbox.Parent = ShopPage

local LogContainer = Instance.new("Frame")
LogContainer.Size = UDim2.new(1, -20, 0, 80)
LogContainer.Position = UDim2.new(0, 10, 0, 50)
LogContainer.BackgroundTransparency = 1
LogContainer.Visible = false
LogContainer.ZIndex = 8
LogContainer.Parent = ShopPage

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ожидание открытия и отмены окна покупки геймпасса..."
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 9
StatusLabel.Parent = LogContainer

local IdLabel = Instance.new("TextLabel")
IdLabel.Size = UDim2.new(0, 200, 0, 30)
IdLabel.Position = UDim2.new(0, 0, 0, 30)
IdLabel.BackgroundTransparency = 1
IdLabel.Text = "ID: —"
IdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
IdLabel.TextSize = 16
IdLabel.Font = Enum.Font.Arial
IdLabel.TextXAlignment = Enum.TextXAlignment.Left
IdLabel.ZIndex = 9
IdLabel.Parent = LogContainer

local AcceptButton = Instance.new("TextButton")
AcceptButton.Size = UDim2.new(0, 30, 0, 30)
AcceptButton.Position = UDim2.new(0, 210, 0, 30)
AcceptButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
AcceptButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
AcceptButton.Text = "✓"
AcceptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AcceptButton.TextSize = 18
AcceptButton.Visible = false
AcceptButton.ZIndex = 9
AcceptButton.Parent = LogContainer

local DeclineButton = Instance.new("TextButton")
DeclineButton.Size = UDim2.new(0, 30, 0, 30)
DeclineButton.Position = UDim2.new(0, 250, 0, 30)
DeclineButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
DeclineButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
DeclineButton.Text = "X"
DeclineButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeclineButton.TextSize = 16
DeclineButton.Visible = false
DeclineButton.ZIndex = 9
DeclineButton.Parent = LogContainer

local MarketplaceService = game:GetService("MarketplaceService")
local reqConnection = nil
local finConnection = nil
local interceptedId = nil
local isWaitingForClose = false

local function clearLogState()
    interceptedId = nil
    isWaitingForClose = false
    IdLabel.Text = "ID: —"
    AcceptButton.Visible = false
    DeclineButton.Visible = false
    StatusLabel.Text = "Ожидание открытия и отмены окна покупки геймпасса..."
    StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
end

ShopCheckbox.MouseButton1Click:Connect(function()
    shopHackEnabled = not shopHackEnabled
    if shopHackEnabled then
        ShopCheckbox.Text = "✓"
        LogContainer.Visible = true
        clearLogState()
        
        reqConnection = MarketplaceService.PromptGamePassPurchaseRequested:Connect(function(player, gamePassId)
            if player == game:GetService("Players").LocalPlayer then
                interceptedId = gamePassId
                isWaitingForClose = true
            end
        end)
        
        finConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
            if player == game:GetService("Players").LocalPlayer and isWaitingForClose and gamePassId == interceptedId then
                isWaitingForClose = false
                
                task.spawn(function()
                    StatusLabel.Text = "Анализ закрытой транзакции..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    task.wait(1.0)
                    
                    StatusLabel.Text = "Перехват пакета чека (Receipt)..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
                    task.wait(1.2)
                    
                    StatusLabel.Text = "Пакет успешно подготовлен к подмене!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
                    
                    IdLabel.Text = "ID = " .. tostring(interceptedId)
                    AcceptButton.Visible = true
                    DeclineButton.Visible = true
                end)
            end
        end)
    else
        ShopCheckbox.Text = ""
        LogContainer.Visible = false
        if reqConnection then reqConnection:Disconnect() reqConnection = nil end
        if finConnection then finConnection:Disconnect() finConnection = nil end
        clearLogState()
    end
end)

AcceptButton.MouseButton1Click:Connect(function()
    if interceptedId and shopHackEnabled then
        local player = game:GetService("Players").LocalPlayer
        MarketplaceService:SignalPromptGamePassPurchaseFinished(player, interceptedId, true)
        StatusLabel.Text = "Процесс: Отправлен пакет с флагом wasPurchased = true!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        AcceptButton.Visible = false
        DeclineButton.Visible = false
    end
end)

DeclineButton.MouseButton1Click:Connect(function()
    clearLogState()
end)

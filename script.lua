--[[
    SeraphiCA | Defuse Edition v16
    Target: Roblox / Luau (Defuse — CS:GO copy)
    Platform: Android 9-13 / Delta Executor

    v16 Changes:
    - FIXED: ThirdPerson now forces camera distance every frame (game can't block it).
    - FIXED: Spinbot now disables AutoRotate so you spin even while walking.
    - FIXED: BunnyHop logic rewritten for reliable auto-jumping.
    - ADDED: Bhop Speed slider.
    - Base v15 features intact.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- ANDROID SCREEN DETECTION
-- ============================================================

local ViewportSize = Camera.ViewportSize
local screenScale = math.min(ViewportSize.X / 800, ViewportSize.Y / 460)
if screenScale > 1 then screenScale = 1 end
if screenScale < 0.5 then screenScale = 0.5 end

local UI_WIDTH = math.floor(800 * screenScale)
local UI_HEIGHT = math.floor(460 * screenScale)

-- ============================================================
-- BOOTSTRAP
-- ============================================================

local GUI_NAME = "SeraphiCA_Defuse_v16_Fixes"

local function getGuiParent()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Parent = getGuiParent()
local old = Parent:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local oldRuntime = Parent:FindFirstChild("SeraphiCA_Runtime_v15")
if oldRuntime then oldRuntime:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Parent

-- ============================================================
-- THEME
-- ============================================================

local Theme = {
    Background = Color3.fromRGB(9, 10, 14),
    Surface = Color3.fromRGB(18, 19, 24),
    Surface2 = Color3.fromRGB(25, 26, 32),
    Surface3 = Color3.fromRGB(31, 32, 39),
    Text = Color3.fromRGB(248, 248, 250),
    Secondary = Color3.fromRGB(163, 165, 174),
    Muted = Color3.fromRGB(103, 105, 114),
    Accent = Color3.fromRGB(67, 142, 255),
    AccentSoft = Color3.fromRGB(38, 76, 132),
    Green = Color3.fromRGB(49, 209, 88),
    Red = Color3.fromRGB(255, 69, 58),
    Orange = Color3.fromRGB(255, 159, 10),
    Purple = Color3.fromRGB(175, 82, 222),
    Yellow = Color3.fromRGB(255, 214, 10),
    Divider = Color3.fromRGB(49, 50, 57),
    White = Color3.fromRGB(255, 255, 255),
}

local function tween(obj, duration, props, style, direction)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Divider
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = obj
    return s
end

local function padding(obj, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = obj
    return p
end

local function label(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or Theme.Text
    l.TextScaled = false
    l.TextSize = math.floor((size or 14) * screenScale)
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

-- ============================================================
-- STATE
-- ============================================================

local State = {
    AimBot = {
        Enabled = false, FOV = 120, VisibleCheck = true, ShowFov = true, Target = "Closest",
        SilentEnabled = false, SilentFOV = 150, SilentTargetPart = "Head", SilentWallCheck = true,
    },
    Visuals = {
        ESP = false, Boxes = false, Health = false, Names = true, Distance = false, Tracers = false,
        ColorWorld = false, WorldColor = Color3.fromRGB(150, 150, 150),
        XRayEnabled = false, XRayMode = "Potato", XRayTransparency = 75, XRayColor = Color3.fromRGB(200, 0, 255),
        SpectatorList = false, BombCalculator = false, SoundESP = false,
    },
    Misc = {
        Fly = false, FlySpeed = 50, WallShot = false,
        ThirdPerson = false, CamDistance = 15,
        AntiAim = false, SpinSpeed = 10,
        BunnyHop = false, BhopSpeed = 1, -- NEW
        MoveBeforeTime = false, FastReload = false,
        NoFlash = false, AntiSmoke = false,
    },
    Settings = { Blur = true, Animations = true, Sounds = false, Dark = true }
}

local callbacks = {}
local UI_Toggles = {}

local function setState(section, key, value)
    State[section][key] = value
    local cb = callbacks[section] and callbacks[section][key]
    if cb then pcall(cb, value) end
end

-- ============================================================
-- TEAMMATE DETECTION
-- ============================================================

local function isTeammate(player)
    if player == LocalPlayer then return true end
    local success, result = pcall(function()
        if LocalPlayer.Team and player.Team then return LocalPlayer.Team == player.Team end
        if not LocalPlayer.Neutral and not player.Neutral then
            if LocalPlayer.TeamColor and player.TeamColor then
                return LocalPlayer.TeamColor.Number == player.TeamColor.Number
            end
        end
        local localAttr = LocalPlayer:GetAttribute("Team")
        local playerAttr = player:GetAttribute("Team")
        if localAttr ~= nil and playerAttr ~= nil then return localAttr == playerAttr end
        local directAttr = player:GetAttribute("IsTeammate")
        if directAttr ~= nil then return directAttr == true end
        return false
    end)
    if not success then return false end
    return result
end

local function getEnemyCharacters()
    local chars = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) and player.Character then
            table.insert(chars, player.Character)
        end
    end
    return chars
end

-- ============================================================
-- DYNAMIC ISLAND & MAIN WINDOW
-- ============================================================

local ISLAND_W = math.floor(250 * screenScale)
local ISLAND_H = math.floor(42 * screenScale)

local Island = Instance.new("TextButton")
Island.Name = "DynamicIsland"
Island.Size = UDim2.fromOffset(ISLAND_W, ISLAND_H)
Island.Position = UDim2.new(0.5, -ISLAND_W / 2, 0, math.floor(14 * screenScale))
Island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Island.AutoButtonColor = false
Island.Text = ""
Island.ZIndex = 100
Island.Parent = ScreenGui
corner(Island, math.floor(21 * screenScale))

local IslandGlow = Instance.new("Frame")
IslandGlow.BackgroundTransparency = 1
IslandGlow.Size = UDim2.fromScale(1, 1)
IslandGlow.Parent = Island
corner(IslandGlow, math.floor(21 * screenScale))
stroke(IslandGlow, Theme.White, 1, 0.55)

local IslandDot = Instance.new("Frame")
IslandDot.Size = UDim2.fromOffset(math.floor(8 * screenScale), math.floor(8 * screenScale))
IslandDot.Position = UDim2.new(0, math.floor(16 * screenScale), 0.5, -math.floor(4 * screenScale))
IslandDot.BackgroundColor3 = Theme.Green
IslandDot.Parent = Island
corner(IslandDot, math.floor(8 * screenScale))

local IslandTitle = label(Island, "SeraphiCA", 13, Theme.White, Enum.Font.GothamBold)
IslandTitle.Size = UDim2.fromOffset(math.floor(90 * screenScale), ISLAND_H)
IslandTitle.Position = UDim2.fromOffset(math.floor(31 * screenScale), 0)

local IslandTime = label(Island, "00:00:00", 12, Theme.Secondary, Enum.Font.GothamMedium)
IslandTime.Size = UDim2.fromOffset(math.floor(70 * screenScale), ISLAND_H)
IslandTime.Position = UDim2.new(1, -math.floor(116 * screenScale), 0, 0)
IslandTime.TextXAlignment = Enum.TextXAlignment.Right

local IslandChevron = label(Island, "⌄", 17, Theme.Secondary, Enum.Font.GothamBold)
IslandChevron.Size = UDim2.fromOffset(math.floor(20 * screenScale), ISLAND_H)
IslandChevron.Position = UDim2.new(1, -math.floor(29 * screenScale), 0, 0)
IslandChevron.TextXAlignment = Enum.TextXAlignment.Center

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(UI_WIDTH, UI_HEIGHT)
Main.Position = UDim2.new(0.5, -UI_WIDTH / 2, 0.5, -UI_HEIGHT / 2)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
corner(Main, math.floor(24 * screenScale))
stroke(Main, Color3.fromRGB(70, 72, 82), 1, 0.25)

local Shine = Instance.new("Frame")
Shine.Size = UDim2.new(1, 0, 0, 1)
Shine.Position = UDim2.new(0, 0, 0, 0)
Shine.BackgroundColor3 = Theme.White
Shine.BackgroundTransparency = 0.86
Shine.BorderSizePixel = 0
Shine.Parent = Main

-- HEADER
local HEADER_H = math.floor(70 * screenScale)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, HEADER_H)
Header.BackgroundTransparency = 1
Header.Parent = Main

local HeaderTitle = label(Header, "SeraphiCA", 24, Theme.Text, Enum.Font.GothamBlack)
HeaderTitle.Position = UDim2.fromOffset(math.floor(28 * screenScale), math.floor(10 * screenScale))
HeaderTitle.Size = UDim2.fromOffset(math.floor(260 * screenScale), math.floor(30 * screenScale))

local HeaderSub = label(Header, "Fixes v16", 12, Theme.Secondary, Enum.Font.GothamMedium)
HeaderSub.Position = UDim2.fromOffset(math.floor(29 * screenScale), math.floor(40 * screenScale))
HeaderSub.Size = UDim2.fromOffset(math.floor(180 * screenScale), math.floor(20 * screenScale))

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(math.floor(32 * screenScale), math.floor(32 * screenScale))
CloseBtn.Position = UDim2.new(1, -math.floor(130 * screenScale), 0, math.floor(19 * screenScale))
CloseBtn.BackgroundColor3 = Theme.Surface2
CloseBtn.AutoButtonColor = false
CloseBtn.Text = "✕"
CloseBtn.TextSize = math.floor(14 * screenScale)
CloseBtn.TextColor3 = Theme.Red
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header
corner(CloseBtn, math.floor(10 * screenScale))

local HeaderStatus = Instance.new("Frame")
HeaderStatus.Size = UDim2.fromOffset(math.floor(90 * screenScale), math.floor(32 * screenScale))
HeaderStatus.Position = UDim2.new(1, -math.floor(90 * screenScale), 0, math.floor(19 * screenScale))
HeaderStatus.BackgroundColor3 = Theme.Surface2
HeaderStatus.Parent = Header
corner(HeaderStatus, math.floor(16 * screenScale))

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(math.floor(7 * screenScale), math.floor(7 * screenScale))
StatusDot.Position = UDim2.fromOffset(math.floor(12 * screenScale), math.floor(13 * screenScale))
StatusDot.BackgroundColor3 = Theme.Green
StatusDot.Parent = HeaderStatus
corner(StatusDot, math.floor(7 * screenScale))

local StatusText = label(HeaderStatus, "ON", 11, Theme.Secondary, Enum.Font.GothamBold)
StatusText.Position = UDim2.fromOffset(math.floor(25 * screenScale), 0)
StatusText.Size = UDim2.fromOffset(math.floor(55 * screenScale), math.floor(32 * screenScale))

-- SIDEBAR
local SIDEBAR_W = math.floor(190 * screenScale)
local SIDEBAR_H = math.floor(370 * screenScale)
local SIDEBAR_Y = math.floor(75 * screenScale)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.fromOffset(SIDEBAR_W, SIDEBAR_H)
Sidebar.Position = UDim2.fromOffset(math.floor(18 * screenScale), SIDEBAR_Y)
Sidebar.BackgroundColor3 = Theme.Surface
Sidebar.Parent = Main
corner(Sidebar, math.floor(19 * screenScale))

local SideTop = label(Sidebar, "CONTROL", 10, Theme.Muted, Enum.Font.GothamBold)
SideTop.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(15 * screenScale))
SideTop.Size = UDim2.new(1, -math.floor(36 * screenScale), 0, math.floor(18 * screenScale))

local TabList = Instance.new("Frame")
TabList.Size = UDim2.new(1, -math.floor(20 * screenScale), 1, -math.floor(65 * screenScale))
TabList.Position = UDim2.fromOffset(math.floor(10 * screenScale), math.floor(48 * screenScale))
TabList.BackgroundTransparency = 1
TabList.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, math.floor(7 * screenScale))
TabLayout.Parent = TabList

local TabData = {
    {Name = "AimBot", Icon = "⌁", Color = Theme.Accent},
    {Name = "Visuals", Icon = "◉", Color = Theme.Purple},
    {Name = "Misc", Icon = "✦", Color = Theme.Yellow},
    {Name = "Settings", Icon = "⚙", Color = Theme.Secondary},
}

local Tabs = {}
local activeTab = nil

-- CONTENT AREA
local CONTENT_X = math.floor(220 * screenScale)
local CONTENT_Y = math.floor(75 * screenScale)
local CONTENT_W = UI_WIDTH - CONTENT_X - math.floor(18 * screenScale)
local CONTENT_H = UI_HEIGHT - CONTENT_Y - math.floor(13 * screenScale)

local Content = Instance.new("Frame")
Content.Size = UDim2.fromOffset(CONTENT_W, CONTENT_H)
Content.Position = UDim2.fromOffset(CONTENT_X, CONTENT_Y)
Content.BackgroundTransparency = 1
Content.Parent = Main

local PageTitle = label(Content, "AimBot", 26, Theme.Text, Enum.Font.GothamBlack)
PageTitle.Position = UDim2.fromOffset(math.floor(24 * screenScale), 0)
PageTitle.Size = UDim2.new(1, -math.floor(48 * screenScale), 0, math.floor(36 * screenScale))

local PageDescription = label(Content, "Configure targeting preferences.", 12, Theme.Secondary, Enum.Font.GothamMedium)
PageDescription.Position = UDim2.fromOffset(math.floor(25 * screenScale), math.floor(35 * screenScale))
PageDescription.Size = UDim2.new(1, -math.floor(50 * screenScale), 0, math.floor(22 * screenScale))

local Page = Instance.new("ScrollingFrame")
Page.Name = "Page"
Page.Size = UDim2.new(1, -math.floor(48 * screenScale), 1, -math.floor(72 * screenScale))
Page.Position = UDim2.fromOffset(math.floor(24 * screenScale), math.floor(70 * screenScale))
Page.BackgroundTransparency = 1
Page.BorderSizePixel = 0
Page.ScrollBarThickness = math.floor(3 * screenScale)
Page.ScrollBarImageColor3 = Theme.Accent
Page.CanvasSize = UDim2.new()
Page.Parent = Content

local PageLayout = Instance.new("UIListLayout")
PageLayout.Padding = UDim.new(0, math.floor(10 * screenScale))
PageLayout.Parent = Page
padding(Page, 0, 6, 0, 12)

PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Page.CanvasSize = UDim2.fromOffset(0, PageLayout.AbsoluteContentSize.Y + 20)
end)

-- ============================================================
-- UI COMPONENTS
-- ============================================================

local function sectionHeader(text, subtext)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, math.floor(45 * screenScale))
    holder.BackgroundTransparency = 1
    holder.Parent = Page

    local a = label(holder, text:upper(), 10, Theme.Muted, Enum.Font.GothamBold)
    a.Size = UDim2.new(1, 0, 0, math.floor(18 * screenScale))
    a.Position = UDim2.fromOffset(2, 0)

    if subtext then
        local b = label(holder, subtext, 11, Theme.Secondary, Enum.Font.Gotham)
        b.Size = UDim2.new(1, 0, 0, math.floor(22 * screenScale))
        b.Position = UDim2.fromOffset(2, math.floor(18 * screenScale))
    end
end

local function card(height)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, math.floor((height or 60) * screenScale))
    c.BackgroundColor3 = Theme.Surface
    c.BorderSizePixel = 0
    c.Parent = Page
    corner(c, math.floor(16 * screenScale))
    return c
end

local function makeSwitch(parent, initial, callback)
    local track = Instance.new("TextButton")
    track.Size = UDim2.fromOffset(math.floor(54 * screenScale), math.floor(34 * screenScale))
    track.BackgroundColor3 = initial and Theme.Green or Theme.Surface3
    track.AutoButtonColor = false
    track.Text = ""
    track.Parent = parent
    corner(track, math.floor(17 * screenScale))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(math.floor(26 * screenScale), math.floor(26 * screenScale))
    knob.Position = initial and UDim2.new(1, -math.floor(30 * screenScale), 0.5, -math.floor(13 * screenScale)) or UDim2.fromOffset(math.floor(4 * screenScale), math.floor(4 * screenScale))
    knob.BackgroundColor3 = Theme.White
    knob.Parent = track
    corner(knob, math.floor(13 * screenScale))

    local state = initial

    local function render(animate)
        local pos = state and UDim2.new(1, -math.floor(30 * screenScale), 0.5, -math.floor(13 * screenScale)) or UDim2.fromOffset(math.floor(4 * screenScale), math.floor(4 * screenScale))
        local color = state and Theme.Green or Theme.Surface3
        if animate then
            tween(track, 0.22, {BackgroundColor3 = color}, Enum.EasingStyle.Quad)
            tween(knob, 0.32, {Position = pos}, Enum.EasingStyle.Back)
        else
            track.BackgroundColor3 = color
            knob.Position = pos
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            render(true)
            if callback then callback(state) end
        end
    end)

    return {
        Get = function() return state end,
        Set = function(v)
            state = v and true or false
            render(true)
            if callback then callback(state) end
        end
    }
end

local function toggleRow(titleText, description, section, key)
    local c = card(66)
    local title = label(c, titleText, 14, Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(9 * screenScale))
    title.Size = UDim2.new(1, -math.floor(90 * screenScale), 0, math.floor(22 * screenScale))

    local desc = label(c, description, 11, Theme.Secondary, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(32 * screenScale))
    desc.Size = UDim2.new(1, -math.floor(90 * screenScale), 0, math.floor(20 * screenScale))
    desc.TextTruncate = Enum.TextTruncate.AtEnd

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(math.floor(54 * screenScale), math.floor(34 * screenScale))
    holder.Position = UDim2.new(1, -math.floor(72 * screenScale), 0.5, -math.floor(17 * screenScale))
    holder.Parent = c

    return makeSwitch(holder, State[section][key], function(v)
        setState(section, key, v)
    end)
end

local function sliderRow(titleText, description, section, key, minValue, maxValue)
    local c = card(84)
    local title = label(c, titleText, 14, Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(8 * screenScale))
    title.Size = UDim2.new(1, -math.floor(100 * screenScale), 0, math.floor(21 * screenScale))

    local valueLabel = label(c, tostring(State[section][key]), 12, Theme.Accent, Enum.Font.GothamBold)
    valueLabel.Position = UDim2.new(1, -math.floor(65 * screenScale), 0, math.floor(8 * screenScale))
    valueLabel.Size = UDim2.fromOffset(math.floor(45 * screenScale), math.floor(21 * screenScale))
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local desc = label(c, description, 11, Theme.Secondary, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(28 * screenScale))
    desc.Size = UDim2.new(1, -math.floor(36 * screenScale), 0, math.floor(18 * screenScale))

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, -math.floor(36 * screenScale), 0, math.floor(8 * screenScale))
    bar.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(61 * screenScale))
    bar.BackgroundColor3 = Theme.Surface3
    bar.AutoButtonColor = false
    bar.Text = ""
    bar.Parent = c
    corner(bar, math.floor(4 * screenScale))

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((State[section][key] - minValue) / (maxValue - minValue), 0, 1, 0)
    fill.Parent = bar
    corner(fill, math.floor(4 * screenScale))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(math.floor(22 * screenScale), math.floor(22 * screenScale))
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Theme.White
    knob.Parent = bar
    corner(knob, math.floor(11 * screenScale))

    local dragging = false

    local function update(inputX)
        local x = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(minValue + (maxValue - minValue) * x + 0.5)
        fill.Size = UDim2.new(x, 0, 1, 0)
        knob.Position = UDim2.new(x, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
        setState(section, key, value)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function choiceRow(titleText, description, section, key, choices)
    local c = card(72)
    local title = label(c, titleText, 14, Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(8 * screenScale))
    title.Size = UDim2.new(1, -math.floor(200 * screenScale), 0, math.floor(22 * screenScale))

    local desc = label(c, description, 11, Theme.Secondary, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(31 * screenScale))
    desc.Size = UDim2.new(1, -math.floor(200 * screenScale), 0, math.floor(20 * screenScale))

    local selected = State[section][key]
    local right = Instance.new("TextButton")
    right.Size = UDim2.fromOffset(math.floor(145 * screenScale), math.floor(42 * screenScale))
    right.Position = UDim2.new(1, -math.floor(160 * screenScale), 0.5, -math.floor(21 * screenScale))
    right.BackgroundColor3 = Theme.Surface2
    right.AutoButtonColor = false
    right.Text = ""
    right.Parent = c
    corner(right, math.floor(12 * screenScale))
    stroke(right, Theme.Divider, 1, 0.2)

    local txt = label(right, selected, 12, Theme.Text, Enum.Font.GothamMedium)
    txt.Size = UDim2.new(1, -math.floor(30 * screenScale), 1, 0)
    txt.Position = UDim2.fromOffset(math.floor(12 * screenScale), 0)

    local chevron = label(right, "›", 18, Theme.Muted, Enum.Font.Gotham)
    chevron.Size = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(42 * screenScale))
    chevron.Position = UDim2.new(1, -math.floor(23 * screenScale), 0, 0)
    chevron.TextXAlignment = Enum.TextXAlignment.Center

    local index = table.find(choices, selected) or 1

    right.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            index += 1
            if index > #choices then index = 1 end
            selected = choices[index]
            txt.Text = selected
            setState(section, key, selected)
            tween(right, 0.12, {BackgroundColor3 = Theme.AccentSoft}, Enum.EasingStyle.Quad)
            task.delay(0.12, function()
                if right.Parent then tween(right, 0.2, {BackgroundColor3 = Theme.Surface2}, Enum.EasingStyle.Quad) end
            end)
        end
    end)
end

local function colorPickerRow(titleText, description, section, key, colors)
    local c = card(100)
    local title = label(c, titleText, 14, Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(8 * screenScale))
    title.Size = UDim2.new(1, -math.floor(36 * screenScale), 0, math.floor(21 * screenScale))

    local desc = label(c, description, 11, Theme.Secondary, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(28 * screenScale))
    desc.Size = UDim2.new(1, -math.floor(36 * screenScale), 0, math.floor(18 * screenScale))

    local colorContainer = Instance.new("Frame")
    colorContainer.BackgroundTransparency = 1
    colorContainer.Size = UDim2.new(1, -math.floor(36 * screenScale), 0, math.floor(40 * screenScale))
    colorContainer.Position = UDim2.fromOffset(math.floor(18 * screenScale), math.floor(52 * screenScale))
    colorContainer.Parent = c

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, math.floor(8 * screenScale))
    layout.Parent = colorContainer

    for _, color in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(math.floor(30 * screenScale), math.floor(30 * screenScale))
        btn.BackgroundColor3 = color
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = colorContainer
        corner(btn, math.floor(8 * screenScale))
        stroke(btn, Theme.White, 1, State[section][key] == color and 0 or 1)

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                setState(section, key, color)
                for _, child in ipairs(colorContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        stroke(child, Theme.White, 1, 1)
                    end
                end
                stroke(btn, Theme.White, 1, 0)
            end
        end)
    end
end

local function infoRow(titleText, valueText, accent)
    local c = card(56)
    local title = label(c, titleText, 13, Theme.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.fromOffset(math.floor(18 * screenScale), 0)
    title.Size = UDim2.new(0.6, 0, 1, 0)

    local value = label(c, valueText, 12, accent or Theme.Secondary, Enum.Font.GothamBold)
    value.Position = UDim2.new(0.6, 0, 0, 0)
    value.Size = UDim2.new(0.4, -math.floor(18 * screenScale), 1, 0)
    value.TextXAlignment = Enum.TextXAlignment.Right
end

-- ============================================================
-- PAGES
-- ============================================================

local Pages = {}

Pages.AimBot = function()
    sectionHeader("Targeting", "Fast camera targeting. Teammates are ignored.")
    UI_Toggles.AimEnabled = toggleRow("Enable Aim", "Automatically targets the closest enemy inside FOV.", "AimBot", "Enabled")
    sliderRow("FOV", "Changes the radius of the targeting circle.", "AimBot", "FOV", 30, 360)
    toggleRow("VisibleCheck", "Only targets players with a clear camera ray.", "AimBot", "VisibleCheck")
    toggleRow("ShowFov", "Shows the white FOV circle at screen center.", "AimBot", "ShowFov")
    choiceRow("Target mode", "Select the target priority.", "AimBot", "Target", {"Closest", "Nearest to center", "Lowest distance"})

    sectionHeader("Silent Aim", "Redirects bullets without moving camera.")
    UI_Toggles.SilentEnabled = toggleRow("Silent Aim", "Enables bullet redirection. Disables regular aim.", "AimBot", "SilentEnabled")
    sliderRow("Silent FOV", "Radius for silent target detection (Max 360).", "AimBot", "SilentFOV", 10, 360)
    choiceRow("Target Part", "Which bone to hit.", "AimBot", "SilentTargetPart", {"Head", "Torso", "Closest"})
    toggleRow("Silent Wall Check", "Only redirect to visible enemies.", "AimBot", "SilentWallCheck")
end

Pages.Visuals = function()
    sectionHeader("World", "Modify map appearance for better FPS.")
    toggleRow("ColorWorld", "Removes textures and paints the map.", "Visuals", "ColorWorld")
    colorPickerRow("World Color", "Choose a color for the map.", "Visuals", "WorldColor", {
        Color3.fromRGB(150, 150, 150), Color3.fromRGB(50, 50, 50), Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 255, 100)
    })

    sectionHeader("X-Ray", "See through walls and map geometry.")
    toggleRow("X-Ray", "Makes map transparent to see enemies.", "Visuals", "XRayEnabled")
    choiceRow("X-Ray Mode", "Potato changes material, Default keeps it.", "Visuals", "XRayMode", {"Potato", "Default"})
    sliderRow("X-Ray Transparency", "Transparency level of the map (0-100%).", "Visuals", "XRayTransparency", 0, 100)
    colorPickerRow("X-Ray Color", "Highlight color for X-Ray.", "Visuals", "XRayColor", {
        Color3.fromRGB(200, 0, 255), Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 255, 255)
    })

    sectionHeader("Player visuals", "ESP for enemies only. Teammates are hidden.")
    toggleRow("ESP", "Master switch for enemy visual overlays.", "Visuals", "ESP")
    toggleRow("Box", "Draws a 2D box around each enemy.", "Visuals", "Boxes")
    toggleRow("Health", "Shows current health in green and lost in red.", "Visuals", "Health")
    toggleRow("Names", "Shows the enemy's display name.", "Visuals", "Names")
    toggleRow("Distance", "Shows the distance from the local player.", "Visuals", "Distance")
    toggleRow("Tracers", "Draws a line from screen bottom toward each enemy.", "Visuals", "Tracers")

    sectionHeader("Tactical", "Defuse specific visual aids.")
    toggleRow("Spectator List", "Shows who is spectating you.", "Visuals", "SpectatorList")
    toggleRow("Bomb Calculator", "Calculates bomb timer and defuse chance.", "Visuals", "BombCalculator")
    toggleRow("Sound ESP", " Draws circles on footsteps/reloads through walls.", "Visuals", "SoundESP")
end

Pages.Misc = function()
    sectionHeader("Movement", "Fly and movement utilities.")
    toggleRow("Fly", "Free flight with Noclip. Use joystick + buttons.", "Misc", "Fly")
    sliderRow("Fly Speed", "Controls how fast you fly.", "Misc", "FlySpeed", 10, 300)
    toggleRow("BunnyHop", "Auto-jump when touching the ground.", "Misc", "BunnyHop")
    sliderRow("Bhop Speed", "Jump power multiplier for BunnyHop.", "Misc", "BhopSpeed", 1, 5)
    toggleRow("Move before time", "Removes spawn barriers collision during prep.", "Misc", "MoveBeforeTime")

    sectionHeader("Combat", "Legit wall penetration and rotation.")
    toggleRow("Fast Reload", "Instantly reloads weapon when ammo hits 0.", "Misc", "FastReload")
    toggleRow("WallShot", "Bullets pass through walls ONLY when enemy is behind them.", "Misc", "WallShot")
    toggleRow("AntiAim / Spinbot", "Rotates your character. Camera stays still.", "Misc", "AntiAim")
    sliderRow("Spin Speed", "Rotation speed in degrees per frame.", "Misc", "SpinSpeed", 1, 30)
    toggleRow("No-Flash", "Blocks screen blinding from flashbangs.", "Misc", "NoFlash")
    toggleRow("Anti-Smoke", "Removes smoke particles for clear vision.", "Misc", "AntiSmoke")

    sectionHeader("Camera", "View modifiers.")
    toggleRow("ThirdPerson", "Switch to 3rd person view.", "Misc", "ThirdPerson")
    sliderRow("Cam Distance", "Distance of the camera in 3rd person.", "Misc", "CamDistance", 5, 30)
end

Pages.Settings = function()
    sectionHeader("Appearance", "Customize how the interface behaves.")
    toggleRow("Blur", "Use a subtle background blur while the menu is open.", "Settings", "Blur")
    toggleRow("Animations", "Enable interface transitions and micro-interactions.", "Settings", "Animations")
    toggleRow("Sounds", "Enable optional interface sound callbacks.", "Settings", "Sounds")
    toggleRow("Dark mode", "Keep the dark iOS-style appearance.", "Settings", "Dark")
    sectionHeader("Device")
    infoRow("Player", LocalPlayer.Name, Theme.Text)
    infoRow("Platform", "Android / Delta", Theme.Secondary)
    infoRow("Version", "v16 — Movement Fixes", Theme.Green)
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================

local function clearPage()
    for _, child in ipairs(Page:GetChildren()) do
        if child ~= PageLayout and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local descriptions = {
    AimBot = "Configure targeting preferences.",
    Visuals = "Control visual presentation.",
    Misc = "Movement and combat utilities.",
    Settings = "Customize the interface."
}

local function selectTab(name)
    if activeTab == name then return end
    activeTab = name

    for tabName, data in pairs(Tabs) do
        local active = tabName == name
        if active then
            tween(data.Background, 0.2, {BackgroundColor3 = data.Color, BackgroundTransparency = 0})
            tween(data.Icon, 0.2, {TextColor3 = Theme.White})
            tween(data.Title, 0.2, {TextColor3 = Theme.White})
        else
            tween(data.Background, 0.2, {BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0})
            tween(data.Icon, 0.2, {TextColor3 = Theme.Secondary})
            tween(data.Title, 0.2, {TextColor3 = Theme.Secondary})
        end
    end

    PageTitle.Text = name
    PageDescription.Text = descriptions[name] or ""
    clearPage()
    local render = Pages[name]
    if render then render() end
    Page.CanvasPosition = Vector2.new(0, 0)
end

local TAB_H = math.floor(54 * screenScale)

for _, tab in ipairs(TabData) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, TAB_H)
    b.BackgroundColor3 = Theme.Surface
    b.AutoButtonColor = false
    b.Text = ""
    b.Parent = TabList
    corner(b, math.floor(15 * screenScale))

    local icon = label(b, tab.Icon, 19, Theme.Secondary, Enum.Font.GothamBold)
    icon.Size = UDim2.fromOffset(math.floor(35 * screenScale), TAB_H)
    icon.Position = UDim2.fromOffset(math.floor(8 * screenScale), 0)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local title = label(b, tab.Name, 13, Theme.Secondary, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(math.floor(48 * screenScale), 0)
    title.Size = UDim2.new(1, -math.floor(58 * screenScale), 1, 0)

    local arrow = label(b, "›", 18, Theme.Muted, Enum.Font.Gotham)
    arrow.Size = UDim2.fromOffset(math.floor(20 * screenScale), TAB_H)
    arrow.Position = UDim2.new(1, -math.floor(27 * screenScale), 0, 0)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    Tabs[tab.Name] = {Background = b, Icon = icon, Title = title, Color = tab.Color}

    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            selectTab(tab.Name)
        end
    end)
end

-- ============================================================
-- CLOCK & OPEN / CLOSE & DRAG
-- ============================================================

local fps = 60
local frames = 0
local lastFPS = os.clock()

RunService.RenderStepped:Connect(function()
    frames += 1
    local now = os.clock()
    if now - lastFPS >= 1 then
        fps = frames
        frames = 0
        lastFPS = now
    end
    IslandTime.Text = os.date("%H:%M:%S")
end)

local open = false
local busy = false

local function setOpen(value)
    if busy or open == value then return end
    busy = true
    open = value

    if value then
        Main.Visible = true
        Main.Size = UDim2.fromOffset(UI_WIDTH, 0)
        Main.BackgroundTransparency = 0.15
        IslandChevron.Text = "⌃"
        tween(Main, 0.45, {Size = UDim2.fromOffset(UI_WIDTH, UI_HEIGHT), BackgroundTransparency = 0}, Enum.EasingStyle.Exponential)
        tween(Island, 0.25, {Size = UDim2.fromOffset(ISLAND_W + math.floor(20 * screenScale), ISLAND_H + math.floor(2 * screenScale)), Position = UDim2.new(0.5, -(ISLAND_W + math.floor(20 * screenScale)) / 2, 0, math.floor(12 * screenScale))})
        task.delay(0.46, function() busy = false end)
    else
        IslandChevron.Text = "⌄"
        tween(Main, 0.35, {Size = UDim2.fromOffset(UI_WIDTH, 0), BackgroundTransparency = 0.2}, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
        tween(Island, 0.25, {Size = UDim2.fromOffset(ISLAND_W, ISLAND_H), Position = UDim2.new(0.5, -ISLAND_W / 2, 0, math.floor(14 * screenScale))})
        task.delay(0.37, function() Main.Visible = false busy = false end)
    end
end

Island.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setOpen(not open)
    end
end)

CloseBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setOpen(false)
    end
end)

local dragging = false
local dragStart, startPosition, dragInput

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

-- ============================================================
-- RUNTIME GUI
-- ============================================================

local RuntimeGui = Instance.new("ScreenGui")
RuntimeGui.Name = "SeraphiCA_Runtime_v16"
RuntimeGui.IgnoreGuiInset = true
RuntimeGui.ResetOnSpawn = false
RuntimeGui.DisplayOrder = 500
RuntimeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
RuntimeGui.Parent = Parent

local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.fromScale(0.5, 0.5)
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.ZIndex = 5
FovCircle.Parent = RuntimeGui
corner(FovCircle, 9999)
stroke(FovCircle, Theme.White, 2, 0)

local EspLayer = Instance.new("Frame")
EspLayer.Name = "ESP"
EspLayer.Size = UDim2.fromScale(1, 1)
EspLayer.BackgroundTransparency = 1
EspLayer.BorderSizePixel = 0
EspLayer.ZIndex = 10
EspLayer.Parent = RuntimeGui

local SpectatorWidget = Instance.new("Frame")
SpectatorWidget.Size = UDim2.fromOffset(math.floor(150 * screenScale), math.floor(100 * screenScale))
SpectatorWidget.Position = UDim2.new(0, math.floor(20 * screenScale), 0, math.floor(60 * screenScale))
SpectatorWidget.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SpectatorWidget.BackgroundTransparency = 0.3
SpectatorWidget.Visible = false
SpectatorWidget.Parent = RuntimeGui
corner(SpectatorWidget, 8)
stroke(SpectatorWidget, Theme.White, 1, 0.5)

local SpectatorTitle = label(SpectatorWidget, "SPECTATORS", 12, Theme.White, Enum.Font.GothamBold)
SpectatorTitle.Size = UDim2.new(1, 0, 0, math.floor(20 * screenScale))
SpectatorTitle.Position = UDim2.fromOffset(0, math.floor(5 * screenScale))
SpectatorTitle.TextXAlignment = Enum.TextXAlignment.Center

local SpectatorList = label(SpectatorWidget, "", 11, Theme.Secondary, Enum.Font.Gotham)
SpectatorList.Size = UDim2.new(1, -math.floor(10 * screenScale), 1, -math.floor(30 * screenScale))
SpectatorList.Position = UDim2.fromOffset(math.floor(5 * screenScale), math.floor(25 * screenScale))
SpectatorList.TextXAlignment = Enum.TextXAlignment.Center
SpectatorList.TextYAlignment = Enum.TextYAlignment.Top

local BombWidget = Instance.new("TextLabel")
BombWidget.Size = UDim2.fromOffset(math.floor(200 * screenScale), math.floor(40 * screenScale))
BombWidget.Position = UDim2.new(0.5, -math.floor(100 * screenScale), 0, math.floor(60 * screenScale))
BombWidget.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BombWidget.BackgroundTransparency = 0.3
BombWidget.Visible = false
BombWidget.Text = ""
BombWidget.TextColor3 = Theme.White
BombWidget.Font = Enum.Font.GothamBold
BombWidget.TextSize = math.floor(14 * screenScale)
BombWidget.Parent = RuntimeGui
corner(BombWidget, 8)
stroke(BombWidget, Theme.White, 1, 0.5)

local FLY_BTN_SIZE = math.floor(70 * screenScale)

local FlyUpButton = Instance.new("TextButton")
FlyUpButton.Size = UDim2.fromOffset(FLY_BTN_SIZE, FLY_BTN_SIZE)
FlyUpButton.Position = UDim2.new(0, math.floor(20 * screenScale), 1, -FLY_BTN_SIZE - math.floor(100 * screenScale))
FlyUpButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyUpButton.BackgroundTransparency = 0.35
FlyUpButton.Text = "↑"
FlyUpButton.TextSize = math.floor(36 * screenScale)
FlyUpButton.TextColor3 = Theme.White
FlyUpButton.Font = Enum.Font.GothamBold
FlyUpButton.Visible = false
FlyUpButton.ZIndex = 200
FlyUpButton.Parent = RuntimeGui
corner(FlyUpButton, math.floor(35 * screenScale))
stroke(FlyUpButton, Theme.White, 1, 0.3)

local FlyDownButton = Instance.new("TextButton")
FlyDownButton.Size = UDim2.fromOffset(FLY_BTN_SIZE, FLY_BTN_SIZE)
FlyDownButton.Position = UDim2.new(0, math.floor(20 * screenScale), 1, -FLY_BTN_SIZE - math.floor(25 * screenScale))
FlyDownButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyDownButton.BackgroundTransparency = 0.35
FlyDownButton.Text = "↓"
FlyDownButton.TextSize = math.floor(36 * screenScale)
FlyDownButton.TextColor3 = Theme.White
FlyDownButton.Font = Enum.Font.GothamBold
FlyDownButton.Visible = false
FlyDownButton.ZIndex = 200
FlyDownButton.Parent = RuntimeGui
corner(FlyDownButton, math.floor(35 * screenScale))
stroke(FlyDownButton, Theme.White, 1, 0.3)

local flyUp = false
local flyDown = false

FlyUpButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyUp = true end
end)
FlyUpButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyUp = false end
end)
FlyDownButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyDown = true end
end)
FlyDownButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyDown = false end
end)

-- ============================================================
-- FEATURE LOGIC: COLOR WORLD & X-RAY
-- ============================================================

local originalParts = {}
local function enableColorWorld()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") then
            originalParts[obj] = {obj.Material, obj.Color, obj.Transparency}
            obj.Material = Enum.Material.SmoothPlastic
            obj.Color = State.Visuals.WorldColor
        end
    end
end

local function disableColorWorld()
    for obj, props in pairs(originalParts) do
        if obj and obj.Parent then
            obj.Material = props[1]
            obj.Color = props[2]
            obj.Transparency = props[3]
        end
    end
    originalParts = {}
end

local xrayParts = {}
local function applyXRay()
    xrayParts = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") then
            local isPlayer = false
            local model = obj:FindFirstAncestorOfClass("Model")
            if model and Players:GetPlayerFromCharacter(model) then isPlayer = true end
            if not isPlayer then
                xrayParts[obj] = {obj.Material, obj.Transparency, obj.Color}
                if State.Visuals.XRayMode == "Potato" then obj.Material = Enum.Material.SmoothPlastic end
                obj.Transparency = State.Visuals.XRayTransparency / 100
                obj.Color = State.Visuals.XRayColor
            end
        end
    end
end

local function restoreXRay()
    for obj, props in pairs(xrayParts) do
        if obj and obj.Parent then
            obj.Material = props[1]
            obj.Transparency = props[2]
            obj.Color = props[3]
        end
    end
    xrayParts = {}
end

-- ============================================================
-- FEATURE LOGIC: MOVE BEFORE TIME
-- ============================================================

local barrierParts = {}
local function enableMoveBeforeTime()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") and obj.CanCollide then
            local name = obj.Name:lower()
            if name:match("barrier") or name:match("invisible") or name:match("buyzone") or name:match("wall") or name:match("zone") or name:match("bound") or name:match("region") or name:match("area") then
                barrierParts[obj] = true
                obj.CanCollide = false
            elseif obj.Transparency >= 0.9 then
                barrierParts[obj] = true
                obj.CanCollide = false
            end
        end
    end
end

local function disableMoveBeforeTime()
    for part, _ in pairs(barrierParts) do
        if part and part.Parent then part.CanCollide = true end
    end
    barrierParts = {}
end

-- ============================================================
-- FEATURE LOGIC: FAST RELOAD
-- ============================================================

local lastAmmo = -1
local reloadCooldown = 0

local function fastReloadLoop()
    if not State.Misc.FastReload then return end
    if tick() < reloadCooldown then return end

    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then lastAmmo = -1 return end

    local ammoVal = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Mag") or tool:FindFirstChild("Clip") or tool:FindFirstChild("Bullets")
    if not ammoVal or not ammoVal:IsA("IntValue") and not ammoVal:IsA("NumberValue") then return end

    if ammoVal.Value == 0 and lastAmmo > 0 then
        reloadCooldown = tick() + 1
        local firedRemote = false
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:lower():match("reload") then
                obj:FireServer(tool)
                firedRemote = true
                break
            end
        end
        if not firedRemote then
            for _, obj in ipairs(tool:GetDescendants()) do
                if obj:IsA("RemoteEvent") and obj.Name:lower():match("reload") then
                    obj:FireServer()
                    firedRemote = true
                    break
                end
            end
        end
        local maxAmmo = tool:FindFirstChild("MaxAmmo") or tool:FindFirstChild("MagSize") or tool:FindFirstChild("ClipSize")
        if maxAmmo and (maxAmmo:IsA("IntValue") or maxAmmo:IsA("NumberValue")) then
            ammoVal.Value = maxAmmo.Value
        end
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    end
    lastAmmo = ammoVal.Value
end

-- ============================================================
-- FEATURE LOGIC: THIRD PERSON
-- ============================================================

local origMinZoom = LocalPlayer.CameraMinZoomDistance
local origMaxZoom = LocalPlayer.CameraMaxZoomDistance

local function enableThirdPerson()
    origMinZoom = LocalPlayer.CameraMinZoomDistance
    origMaxZoom = LocalPlayer.CameraMaxZoomDistance
end

local function disableThirdPerson()
    LocalPlayer.CameraMinZoomDistance = 0.5
    LocalPlayer.CameraMaxZoomDistance = origMaxZoom
end

-- ============================================================
-- FEATURE LOGIC: NO-FLASH & ANTI-SMOKE
-- ============================================================

local noFlashConn
local function enableNoFlash()
    if noFlashConn then return end
    noFlashConn = RunService.RenderStepped:Connect(function()
        if Lighting.Brightness > 1 then Lighting.Brightness = 1 end
        if Lighting.ExposureCompensation > 0.5 then Lighting.ExposureCompensation = 0 end
        local cce = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cce and cce.Brightness > 0.5 then cce.Brightness = 0 end
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name:lower():match("flash") then
                local frame = gui:FindFirstChildOfClass("Frame") or gui:FindFirstChildOfClass("ImageLabel")
                if frame and frame.BackgroundTransparency < 0.5 then frame.BackgroundTransparency = 1 end
            end
        end
    end)
end

local function disableNoFlash()
    if noFlashConn then noFlashConn:Disconnect() noFlashConn = nil end
end

local antiSmokeConn
local function enableAntiSmoke()
    if antiSmokeConn then return end
    antiSmokeConn = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ParticleEmitter") and (obj.Name:lower():match("smoke") or obj.Name:lower():match("fog")) then
            obj.Enabled = false
        end
    end)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") and (obj.Name:lower():match("smoke") or obj.Name:lower():match("fog")) then
            obj.Enabled = false
        end
    end
end

local function disableAntiSmoke()
    if antiSmokeConn then antiSmokeConn:Disconnect() antiSmokeConn = nil end
end

-- ============================================================
-- FEATURE LOGIC: SOUND / FOOTSTEP ESP
-- ============================================================

local soundEspParts = {}
local function spawnSoundCircle(pos, color)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Size = Vector3.new(1, 0.1, 1)
    part.CFrame = CFrame.new(pos)
    part.Parent = Workspace
    table.insert(soundEspParts, {Part = part, Time = tick()})
end

local soundEspConn
local function enableSoundESP()
    if soundEspConn then return end
    soundEspConn = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isTeammate(player) and player.Character then
                local char = player.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    if hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
                        if math.random(1, 10) == 1 then spawnSoundCircle(root.Position, Theme.Yellow) end
                    end
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") then
                        for _, sound in ipairs(tool.Handle:GetChildren()) do
                            if sound:IsA("Sound") and sound.IsPlaying and (sound.Name:lower():match("shoot") or sound.Name:lower():match("reload") or sound.Name:lower():match("fire")) then
                                spawnSoundCircle(root.Position, Theme.Red)
                                break
                            end
                        end
                    end
                end
            end
        end
        for i = #soundEspParts, 1, -1 do
            local data = soundEspParts[i]
            local elapsed = tick() - data.Time
            if elapsed > 2 then
                if data.Part and data.Part.Parent then data.Part:Destroy() end
                table.remove(soundEspParts, i)
            else
                local t = TweenService:Create(data.Part, TweenInfo.new(0.1), {Transparency = elapsed / 2, Size = Vector3.new(1 + (elapsed * 3), 0.1, 1 + (elapsed * 3))})
                t:Play()
            end
        end
    end)
end

local function disableSoundESP()
    if soundEspConn then soundEspConn:Disconnect() soundEspConn = nil end
    for _, data in ipairs(soundEspParts) do
        if data.Part and data.Part.Parent then data.Part:Destroy() end
    end
    soundEspParts = {}
end

-- ============================================================
-- FEATURE LOGIC: SILENT AIM, WALLSHOT, FLY, ESP
-- ============================================================

local EspObjects = {}

local function clearEsp(player)
    local entry = EspObjects[player]
    if not entry then return end
    for _, object in pairs(entry) do
        if typeof(object) == "Instance" then object:Destroy() end
    end
    EspObjects[player] = nil
end

local function makeEsp(player)
    if EspObjects[player] then return EspObjects[player] end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.ZIndex = 10
    box.Parent = EspLayer
    stroke(box, Theme.White, 1.5, 0)

    local healthBack = Instance.new("Frame")
    healthBack.BackgroundColor3 = Theme.Red
    healthBack.BorderSizePixel = 0
    healthBack.Visible = false
    healthBack.ZIndex = 11
    healthBack.Parent = EspLayer
    corner(healthBack, 2)

    local healthFill = Instance.new("Frame")
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.Position = UDim2.fromScale(0, 1)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Theme.Green
    healthFill.BorderSizePixel = 0
    healthFill.ZIndex = 12
    healthFill.Parent = healthBack
    corner(healthFill, 2)

    local name = label(EspLayer, "", 12, Theme.White, Enum.Font.GothamBold)
    name.TextStrokeTransparency = 0.35
    name.Visible = false
    name.ZIndex = 13

    local distance = label(EspLayer, "", 11, Theme.Secondary, Enum.Font.GothamMedium)
    distance.TextStrokeTransparency = 0.35
    distance.Visible = false
    distance.ZIndex = 13

    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0, 0.5)
    tracer.BackgroundColor3 = Theme.White
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.ZIndex = 9
    tracer.Parent = EspLayer

    local entry = {Box = box, HealthBack = healthBack, HealthFill = healthFill, Name = name, Distance = distance, Tracer = tracer}
    EspObjects[player] = entry
    return entry
end

local function setLine(frame, from, to)
    local delta = to - from
    local length = delta.Magnitude
    frame.Position = UDim2.fromOffset(from.X, from.Y)
    frame.Size = UDim2.fromOffset(length, 1)
    frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

local function getBoundingScreenBox(character)
    local boxCFrame, boxSize = character:GetBoundingBox()
    local half = boxSize * 0.5
    local corners = {
        boxCFrame * Vector3.new(-half.X, -half.Y, -half.Z), boxCFrame * Vector3.new(-half.X, -half.Y, half.Z),
        boxCFrame * Vector3.new(-half.X, half.Y, -half.Z), boxCFrame * Vector3.new(-half.X, half.Y, half.Z),
        boxCFrame * Vector3.new(half.X, -half.Y, -half.Z), boxCFrame * Vector3.new(half.X, -half.Y, half.Z),
        boxCFrame * Vector3.new(half.X, half.Y, -half.Z), boxCFrame * Vector3.new(half.X, half.Y, half.Z),
    }
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local visibleCorner = false
    for _, worldPoint in ipairs(corners) do
        local screenPoint, onScreen = Camera:WorldToViewportPoint(worldPoint)
        if screenPoint.Z > 0 then
            minX = math.min(minX, screenPoint.X)
            minY = math.min(minY, screenPoint.Y)
            maxX = math.max(maxX, screenPoint.X)
            maxY = math.max(maxY, screenPoint.Y)
            visibleCorner = visibleCorner or onScreen
        end
    end
    if not visibleCorner or minX == math.huge then return nil end
    return minX, minY, maxX, maxY
end

local function isTargetVisible(character, targetPart)
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function findAimTarget()
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestPlayer, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local targetPart = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
            if humanoid and humanoid.Health > 0 and targetPart then
                local point, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen and point.Z > 0 then
                    local screenPosition = Vector2.new(point.X, point.Y)
                    local screenDistance = (screenPosition - center).Magnitude
                    if screenDistance <= State.AimBot.FOV then
                        local visible = true
                        if State.AimBot.VisibleCheck then visible = isTargetVisible(character, targetPart) end
                        if visible then
                            local worldDistance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                            local score = (State.AimBot.Target == "Lowest distance") and worldDistance or screenDistance
                            if score < bestScore then
                                bestScore = score
                                bestPlayer = player
                                bestPart = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

local CachedSilentTarget = nil

local function findSilentTarget()
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestPart, bestScore = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist <= State.AimBot.SilentFOV and dist < bestScore then
                            bestScore = dist
                            bestPart = targetPart
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

local function updateFov()
    local fovValue = State.AimBot.SilentEnabled and State.AimBot.SilentFOV or State.AimBot.FOV
    FovCircle.Size = UDim2.fromOffset(fovValue * 2, fovValue * 2)
    FovCircle.Visible = State.AimBot.ShowFov
end

local function updateEsp()
    local enabled = State.Visuals.ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local entry = makeEsp(player)
            if isTeammate(player) then
                entry.Box.Visible = false
                entry.HealthBack.Visible = false
                entry.Name.Visible = false
                entry.Distance.Visible = false
                entry.Tracer.Visible = false
            else
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
                if enabled and character and humanoid and humanoid.Health > 0 and root then
                    local minX, minY, maxX, maxY = getBoundingScreenBox(character)
                    if minX then
                        local width = math.max(2, maxX - minX)
                        local height = math.max(2, maxY - minY)
                        entry.Box.Position = UDim2.fromOffset(minX, minY)
                        entry.Box.Size = UDim2.fromOffset(width, height)
                        entry.Box.Visible = State.Visuals.Boxes
                        entry.HealthBack.Position = UDim2.fromOffset(minX - 7, minY)
                        entry.HealthBack.Size = UDim2.fromOffset(4, height)
                        entry.HealthBack.Visible = State.Visuals.Health
                        local healthRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                        entry.HealthFill.Size = UDim2.fromScale(1, healthRatio)
                        local viewportPoint, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen and viewportPoint.Z > 0 then
                            local rootScreen = Vector2.new(viewportPoint.X, viewportPoint.Y)
                            entry.Name.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
                            entry.Name.Position = UDim2.fromOffset(minX, minY - 20)
                            entry.Name.Size = UDim2.fromOffset(width, 18)
                            entry.Name.TextXAlignment = Enum.TextXAlignment.Center
                            entry.Name.Visible = State.Visuals.Names
                            local localRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head"))
                            if localRoot then
                                local distanceValue = (localRoot.Position - root.Position).Magnitude
                                entry.Distance.Text = string.format("%dm", math.floor(distanceValue + 0.5))
                                entry.Distance.Position = UDim2.fromOffset(minX, maxY + 2)
                                entry.Distance.Size = UDim2.fromOffset(width, 16)
                                entry.Distance.TextXAlignment = Enum.TextXAlignment.Center
                                entry.Distance.Visible = State.Visuals.Distance
                            else
                                entry.Distance.Visible = false
                            end
                            local viewport = Camera.ViewportSize
                            setLine(entry.Tracer, Vector2.new(viewport.X * 0.5, viewport.Y), rootScreen)
                            entry.Tracer.Visible = State.Visuals.Tracers
                        else
                            entry.Name.Visible = false
                            entry.Distance.Visible = false
                            entry.Tracer.Visible = false
                        end
                    else
                        entry.Box.Visible = false
                        entry.HealthBack.Visible = false
                        entry.Name.Visible = false
                        entry.Distance.Visible = false
                        entry.Tracer.Visible = false
                    end
                else
                    entry.Box.Visible = false
                    entry.HealthBack.Visible = false
                    entry.Name.Visible = false
                    entry.Distance.Visible = false
                    entry.Tracer.Visible = false
                end
            end
        end
    end
end

local oldNamecall
if hookmetamethod then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if State.AimBot.SilentEnabled and CachedSilentTarget and not checkcaller() then
            local method = getnamecallmethod()
            if method == "Raycast" and self == workspace then
                local args = {...}
                local origin = args[1]
                args[2] = (CachedSilentTarget.Position - origin)
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
end

local wallShotConnection = nil
local modifiedParts = {}
local function restoreModifiedParts()
    for part, _ in pairs(modifiedParts) do
        if part and part.Parent then part.CanQuery = true end
    end
    modifiedParts = {}
end
local function enableWallShot()
    if wallShotConnection then return end
    wallShotConnection = RunService.RenderStepped:Connect(function()
        if not State.Misc.WallShot then return end
        local origin = Camera.CFrame.Position
        local lookDir = Camera.CFrame.LookVector
        local enemyChars = getEnemyCharacters()
        if #enemyChars == 0 then restoreModifiedParts() return end
        local enemyParams = RaycastParams.new()
        enemyParams.FilterType = Enum.RaycastFilterType.Include
        enemyParams.FilterDescendantsInstances = enemyChars
        local enemyHit = Workspace:Raycast(origin, lookDir * 2000, enemyParams)
        if enemyHit then
            local enemyPos = enemyHit.Position
            local dirToEnemy = (enemyPos - origin).Unit
            restoreModifiedParts()
            local excludeList = {LocalPlayer.Character}
            for _, char in ipairs(enemyChars) do table.insert(excludeList, char) end
            local wallParams = RaycastParams.new()
            wallParams.FilterType = Enum.RaycastFilterType.Exclude
            wallParams.FilterDescendantsInstances = excludeList
            local currentPos = origin
            for i = 1, 20 do
                local remaining = (enemyPos - currentPos).Magnitude
                if remaining < 1 then break end
                local wallHit = Workspace:Raycast(currentPos, dirToEnemy * remaining, wallParams)
                if not wallHit then break end
                wallHit.Instance.CanQuery = false
                modifiedParts[wallHit.Instance] = true
                currentPos = wallHit.Position + dirToEnemy * 0.05
            end
        else
            restoreModifiedParts()
        end
    end)
end
local function disableWallShot()
    if wallShotConnection then wallShotConnection:Disconnect() wallShotConnection = nil end
    restoreModifiedParts()
end

local flyConnection, noclipConnection, flyBodyVelocity = nil, nil, nil
local function enableFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    FlyUpButton.Visible = true
    FlyDownButton.Visible = true
    noclipConnection = RunService.Stepped:Connect(function()
        if not State.Misc.Fly then return end
        local c = LocalPlayer.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = root
    flyConnection = RunService.RenderStepped:Connect(function()
        if not State.Misc.Fly then return end
        local c = LocalPlayer.Character
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        local cam = Workspace.CurrentCamera
        if not r or not h or not cam then return end
        local speed = State.Misc.FlySpeed
        local vel = Vector3.zero
        local moveDir = h.MoveDirection
        if moveDir.Magnitude > 0.1 then
            local camLook = cam.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
            local forwardAmount = moveDir.X * flatLook.X + moveDir.Z * flatLook.Z
            vel = Vector3.new(moveDir.X * speed, 0, moveDir.Z * speed)
            if math.abs(forwardAmount) > 0.1 then
                vel = vel + Vector3.new(0, camLook.Y * speed * forwardAmount, 0)
            end
        end
        if flyUp then vel = vel + Vector3.new(0, 1, 0) * speed end
        if flyDown then vel = vel - Vector3.new(0, 1, 0) * speed end
        flyBodyVelocity.Velocity = vel
        if vel.Magnitude > 1 then
            local lookPos = r.Position + vel
            r.CFrame = CFrame.lookAt(r.Position, Vector3.new(lookPos.X, r.Position.Y, lookPos.Z))
        end
    end)
end
local function disableFly()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    FlyUpButton.Visible = false
    FlyDownButton.Visible = false
    flyUp = false
    flyDown = false
end

-- ============================================================
-- CALLBACKS
-- ============================================================

callbacks.AimBot = {}
callbacks.AimBot.Enabled = function(v)
    if v and State.AimBot.SilentEnabled then
        State.AimBot.SilentEnabled = false
        if UI_Toggles.SilentEnabled then UI_Toggles.SilentEnabled.Set(false) end
    end
    updateFov()
end
callbacks.AimBot.SilentEnabled = function(v)
    if v and State.AimBot.Enabled then
        State.AimBot.Enabled = false
        if UI_Toggles.AimEnabled then UI_Toggles.AimEnabled.Set(false) end
    end
    updateFov()
end
callbacks.AimBot.SilentFOV = function() updateFov() end
callbacks.AimBot.FOV = function() updateFov() end
callbacks.AimBot.ShowFov = function() updateFov() end

callbacks.Visuals = {}
callbacks.Visuals.ESP = function() updateEsp() end
callbacks.Visuals.Boxes = function() updateEsp() end
callbacks.Visuals.Health = function() updateEsp() end
callbacks.Visuals.Names = function() updateEsp() end
callbacks.Visuals.Distance = function() updateEsp() end
callbacks.Visuals.Tracers = function() updateEsp() end
callbacks.Visuals.ColorWorld = function(v)
    if v then enableColorWorld() else disableColorWorld() end
end
callbacks.Visuals.WorldColor = function(newColor)
    if State.Visuals.ColorWorld then
        for obj, _ in pairs(originalParts) do
            if obj and obj.Parent then obj.Color = newColor end
        end
    end
end
callbacks.Visuals.XRayEnabled = function(v)
    if v then applyXRay() else restoreXRay() end
end
callbacks.Visuals.XRayMode = function()
    if State.Visuals.XRayEnabled then restoreXRay() applyXRay() end
end
callbacks.Visuals.XRayTransparency = function()
    if State.Visuals.XRayEnabled then
        local trans = State.Visuals.XRayTransparency / 100
        for obj, _ in pairs(xrayParts) do
            if obj and obj.Parent then obj.Transparency = trans end
        end
    end
end
callbacks.Visuals.XRayColor = function()
    if State.Visuals.XRayEnabled then
        for obj, _ in pairs(xrayParts) do
            if obj and obj.Parent then obj.Color = State.Visuals.XRayColor end
        end
    end
end
callbacks.Visuals.SpectatorList = function(v) SpectatorWidget.Visible = v end
callbacks.Visuals.BombCalculator = function(v)
    BombWidget.Visible = v
    if not v then BombWidget.Text = "" end
end
callbacks.Visuals.SoundESP = function(v)
    if v then enableSoundESP() else disableSoundESP() end
end

callbacks.Misc = {}
callbacks.Misc.Fly = function(v) if v then enableFly() else disableFly() end end
callbacks.Misc.WallShot = function(v) if v then enableWallShot() else disableWallShot() end end
callbacks.Misc.ThirdPerson = function(v) if v then enableThirdPerson() else disableThirdPerson() end end
callbacks.Misc.CamDistance = function(val)
    if State.Misc.ThirdPerson then
        LocalPlayer.CameraMaxZoomDistance = val
        LocalPlayer.CameraMinZoomDistance = val
    end
end
callbacks.Misc.MoveBeforeTime = function(v)
    if v then enableMoveBeforeTime() else disableMoveBeforeTime() end
end
callbacks.Misc.NoFlash = function(v)
    if v then enableNoFlash() else disableNoFlash() end
end
callbacks.Misc.AntiSmoke = function(v)
    if v then enableAntiSmoke() else disableAntiSmoke() end
end

-- ============================================================
-- MAIN LOOP & HEARTBEAT LOGIC
-- ============================================================

local bhopConn = RunService.Heartbeat:Connect(function()
    fastReloadLoop()

    -- Spinbot Logic (Fixed: AutoRotate disabled)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            if State.Misc.AntiAim then
                hum.AutoRotate = false
                local oldCamCFrame = Camera.CFrame
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(State.Misc.SpinSpeed), 0)
                Camera.CFrame = oldCamCFrame
            else
                hum.AutoRotate = true
            end
        end
    end

    -- BunnyHop Logic (Fixed: State check + JumpPower multiplier)
    if State.Misc.BunnyHop then
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                h.JumpPower = 50 * State.Misc.BhopSpeed
                if h.FloorMaterial ~= Enum.Material.Air then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or h.MoveDirection.Magnitude > 0.1 then
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera
    updateFov()

    -- Force Third Person (Fixed: Overrides game camera lock)
    if State.Misc.ThirdPerson then
        LocalPlayer.CameraMaxZoomDistance = State.Misc.CamDistance
        LocalPlayer.CameraMinZoomDistance = State.Misc.CamDistance
    end

    if State.AimBot.SilentEnabled then
        CachedSilentTarget = findSilentTarget()
    else
        CachedSilentTarget = nil
    end

    if State.AimBot.Enabled then
        local _, targetPart = findAimTarget()
        if targetPart then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        end
    end

    if State.Visuals.ESP then
        updateEsp()
    else
        for _, entry in pairs(EspObjects) do
            entry.Box.Visible = false
            entry.HealthBack.Visible = false
            entry.Name.Visible = false
            entry.Distance.Visible = false
            entry.Tracer.Visible = false
        end
    end

    -- Spectator List Update
    if State.Visuals.SpectatorList then
        local specs = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local isSpec = false
                if not p.Character then isSpec = true end
                local char = p.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health <= 0 then isSpec = true end
                end
                if isSpec then
                    table.insert(specs, p.DisplayName ~= "" and p.DisplayName or p.Name)
                end
            end
        end
        SpectatorList.Text = #specs > 0 and table.concat(specs, "\n") or "None"
    end

    -- Bomb Calculator Update
    if State.Visuals.BombCalculator then
        local bomb
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:lower():match("c4") or obj.Name:lower():match("bomb")) and obj:FindFirstChildWhichIsA("ProximityPrompt") then
                bomb = obj
                break
            end
        end
        if bomb then
            local timerVal = bomb:FindFirstChild("Time") or bomb:FindFirstChild("Timer") or bomb:FindFirstChild("DetonationTime")
            if timerVal and (timerVal:IsA("IntValue") or timerVal:IsA("NumberValue")) then
                local timeLeft = timerVal.Value
                local hasKit = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("DefuseKit")
                local defuseTime = hasKit and 4 or 7
                if timeLeft > defuseTime then
                    BombWidget.Text = string.format("BOMB: %.1fs | DEFUSABLE", timeLeft)
                    BombWidget.TextColor3 = Theme.Green
                else
                    BombWidget.Text = string.format("BOMB: %.1fs | NO TIME", timeLeft)
                    BombWidget.TextColor3 = Theme.Red
                end
            else
                BombWidget.Text = "BOMB PLANTED"
                BombWidget.TextColor3 = Theme.Yellow
            end
        else
            BombWidget.Text = ""
        end
    end
end)

Players.PlayerRemoving:Connect(clearEsp)

-- ============================================================
-- INIT
-- ============================================================

updateFov()
selectTab("AimBot")

print("[SeraphiCA] Defuse Edition v16 loaded. BunnyHop, ThirdPerson, Spinbot fixed.")

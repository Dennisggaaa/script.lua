--[[
    SeraphiCA NS | Defuse Edition v36
    Target: Roblox / Luau (Defuse — CS:GO copy)
    Platform: Android 9-13 / Delta Executor
    
    v36 Changes:
    - FIXED: UI Library load failure handling (added pcall and error display).
    - FIXED: Minor syntax errors in Neyrone integration logic.
]]

local LocalPlayers = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local UserSettings = UserSettings()
local GameSettings = UserSettings.GameSettings
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = LocalPlayers.LocalPlayer
local cam = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- ============================================================
-- RUNTIME GUI (Для читов, чтобы Neverlose UI не блокировал)
-- ============================================================

local function getRuntimeParent()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return playerGui
end

local RuntimeParent = getRuntimeParent()
local oldRuntime = RuntimeParent:FindFirstChild("SeraphiCA_Runtime_v36")
if oldRuntime then oldRuntime:Destroy() end

local RuntimeGui = Instance.new("ScreenGui")
RuntimeGui.Name = "SeraphiCA_Runtime_v36"
RuntimeGui.ResetOnSpawn = false
RuntimeGui.IgnoreGuiInset = true
RuntimeGui.DisplayOrder = 500
RuntimeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
RuntimeGui.Parent = RuntimeParent

local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.fromScale(0.5, 0.5)
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.ZIndex = 5
FovCircle.Parent = RuntimeGui
local fc = Instance.new("UICorner", FovCircle) fc.CornerRadius = UDim.new(0, 9999)
local fs = Instance.new("UIStroke", FovCircle) fs.Color = Color3.fromRGB(255, 255, 255) fs.Thickness = 2 fs.Transparency = 0

local EspLayer = Instance.new("Frame")
EspLayer.Name = "ESP"
EspLayer.Size = UDim2.fromScale(1, 1)
EspLayer.BackgroundTransparency = 1
EspLayer.BorderSizePixel = 0
EspLayer.ZIndex = 10
EspLayer.Parent = RuntimeGui

-- ============================================================
-- SERAPHICA NS UI LIBRARY (с защитой загрузки)
-- ============================================================

local SeraphiCA
local success, err = pcall(function()
    SeraphiCA = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/NeverLose/refs/heads/main/source.luau"))()
end)

if not success or not SeraphiCA then
    warn("SeraphiCA NS: Failed to load UI library! Error: " .. tostring(err))
    local fallbackGui = Instance.new("ScreenGui")
    fallbackGui.Name = "SeraphiCA_Error"
    fallbackGui.Parent = getRuntimeParent()
    local txt = Instance.new("TextLabel")
    txt.Parent = fallbackGui
    txt.Size = UDim2.new(0, 400, 0, 100)
    txt.Position = UDim2.new(0.5, -200, 0.5, -50)
    txt.Text = "UI LIBRARY FAILED TO LOAD.\nCHECK CONSOLE (F9) FOR ERROR.\nMaybe GitHub is blocked."
    txt.TextColor3 = Color3.new(1, 0, 0)
    txt.BackgroundColor3 = Color3.new(0, 0, 0)
    txt.TextScaled = true
    return
end

local Notification = SeraphiCA:CreateNotification();
local Logging = SeraphiCA:CreateLogger();
local Indicator = SeraphiCA:CreateIndicator();
local window = SeraphiCA:CreateWindow({
    Logo = SeraphiCA.GlobalLogo,
    Name = "SeraphiCA NS",
    Content = "Defuse Full Edition",
    Size = SeraphiCA.Scales.Default,
    ConfigFolder = "SeraphiCAConfigs",
    Enable3DRenderer = false,
    Keybind = "Insert"
});

local Watermark = window:Watermark();

local HC = Indicator.new({
    Name = "DEFUSE",
    Icon = 'crosshairs',
    Color = 'Purple',
})

window:AddTabLabel('SERAPHICA NS')

local ping = Watermark:AddBlock("chart-four-vertical-bars" , "0MS");
local UITogg = Watermark:AddBlock("cube-vertexes" , "SeraphiCA NS");

UITogg:Input(function()
    window:ToggleInterface();
end);

task.spawn(function()
    while true do task.wait(1)
        ping:SetText(tostring(math.random(30,90))..'MS')
    end
end)

-- ============================================================
-- GAME LOGIC & VARIABLES (From Neyrone)
-- ============================================================

local GameData = {
    Network = nil, Ambassador = nil, Variables = nil, Shucky = nil, Appearance = nil,
    BaseWeapon = nil, Viewmodel = nil,
    SkinsData = {
        Weapons = {List = {}, Replacements = {}, Settings = {}},
        Knives = {List = {}, Replacements = {}, Settings = {}, CurrentKnifeType = nil},
        Gloves = {List = {}, Settings = {}, CurrentGloves = nil}
    },
    EquippedWeapon = nil, EquippedWeaponFolder = nil, FireEvent = nil,
    IsAlive = function(p) return p.Character and p.Character:FindFirstChild('Head') and p.Character:FindFirstChild('HumanoidRootPart') and p.Character:FindFirstChild('Torso') and p.Character:FindFirstChild('Humanoid') and p:GetAttribute('Health') > 0 and p:GetAttribute('Team') ~= 'Spectator' and p:GetAttribute('Alive') end,
    IsC4Planted = function() return workspace.Debris:FindFirstChild('PlantedC4') end
}

local ClientData = {HasRequire = true, FullRequire = true, HasGetsenv = true, FullGetsenv = true, HasMousemoverel = true, HasHookmetamethod = true, HasHookfunction = true}

if require then
    local s1, s2, s3, s4, s5 = pcall(function() GameData.Network = require(ReplicatedFirst.Network) end), pcall(function() GameData.Ambassador = require(ReplicatedFirst.Ambassador) end), pcall(function() GameData.Variables = require(ReplicatedFirst.Variables) end), pcall(function() GameData.Shucky = require(ReplicatedStorage.Modules.Shucky) end), pcall(function() GameData.Appearance = require(ReplicatedStorage.Modules.Appearance) end)
    if not (s1 and s2 and s3 and s4 and s5) then ClientData.FullRequire = false end
else ClientData.HasRequire = false end

if getsenv then
    local s = pcall(function() GameData.BaseWeapon = getsenv(player.PlayerScripts.PlayerBase.BaseWeapon) end)
    if not s or not GameData.BaseWeapon.firebullet then ClientData.FullGetsenv = false end
else ClientData.HasGetsenv = false end

if not mousemoverel then ClientData.HasMousemoverel = false end
if not hookmetamethod then ClientData.HasHookmetamethod = false end
if not hookfunction then ClientData.HasHookfunction = false end

for _, v in ipairs(ReplicatedStorage.Weapons:GetChildren()) do
    if v:GetAttribute('WeaponType') == 'Melee' then table.insert(GameData.SkinsData.Knives.List, v.Name) end
end
for _, v in ipairs(ReplicatedStorage.Gloves:GetChildren()) do table.insert(GameData.SkinsData.Gloves.List, v.Name) end

local function weaponFireRemoteNameFromSeed(seed)
    local t, u = math.max(1, math.floor(seed) % 2147483647), {}
    for i = 1, 24 do t = t * 48271 % 2147483647 local w = t % 62 + 1 u[i] = string.sub('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', w, w) end
    return 'sus_' .. table.concat(u)
end

local function getWeaponFireRemote()
    local seed = ReplicatedStorage:GetAttribute('AmongUsSauce')
    while typeof(seed) ~= 'number' do ReplicatedStorage:GetAttributeChangedSignal('AmongUsSauce'):Wait() seed = ReplicatedStorage:GetAttribute('AmongUsSauce') end
    return ReplicatedStorage:WaitForChild('Events'):WaitForChild(weaponFireRemoteNameFromSeed(seed))
end

GameData.GetFireEvent = function()
    if ClientData.HasRequire and GameData.Shucky and GameData.Shucky.activateresult and debug and debug.getupvalue and setthreadidentity then
        local id = getthreadidentity() setthreadidentity(2)
        local t = debug.getupvalue(GameData.Shucky.activateresult, 5)
        local u = t() setthreadidentity(id) return u
    else return getWeaponFireRemote() end
end

GameData.FireEvent = GameData.GetFireEvent()
ReplicatedStorage:GetAttributeChangedSignal('AmongUsSauce'):Connect(function() GameData.FireEvent = GameData.GetFireEvent() end)

if GameData.IsAlive(player) then
    GameData.EquippedWeapon = player.Character:GetAttribute('WhatGun')
    GameData.EquippedWeaponFolder = ReplicatedStorage.Weapons:FindFirstChild(GameData.EquippedWeapon)
end

player.Character:GetAttributeChangedSignal('WhatGun'):Connect(function()
    if not GameData.IsAlive(player) then return end
    GameData.EquippedWeapon = player.Character:GetAttribute('WhatGun')
    GameData.EquippedWeaponFolder = ReplicatedStorage.Weapons:FindFirstChild(GameData.EquippedWeapon)
end)

local WeaponTextures = {
    ['Red + White'] = 'rbxassetid://73492024663403', ['Black + Grey'] = 'rbxassetid://99819667028441', Web = 'rbxassetid://81960247728644', Pink = 'rbxassetid://14003986744', Violet = 'rbxassetid://18876565862', Lego = 'rbxassetid://13654261927', ['Red + Black'] = 'rbxassetid://18993843644', ['Dark Blue + Black'] = 'rbxassetid://12703804272', Shark = 'rbxassetid://12859888187', Camo = 'rbxassetid://1848173837', Lava = 'rbxassetid://5013453655', ['Black + White Leaves'] = 'rbxassetid://1982429041', Red = 'rbxassetid://4786129416'
}

local SoundsList = {
    ['Default Hit Sound'] = tostring(ReplicatedStorage.Sounds.HitSound.Value), ['Default Kill Sound'] = tostring(ReplicatedStorage.Sounds.KillSound.Value), Bameware = 'rbxassetid://3124331820', Bell = 'rbxassetid://6534947240', Bubble = 'rbxassetid://6534947588', Pick = 'rbxassetid://1347140027', Pop = 'rbxassetid://198598793', Rust = 'rbxassetid://1255040462', Skeet = 'rbxassetid://5447626464', ['Mario Coin'] = 'rbxassetid://5709456554', ['COD Hitmarker'] = 'rbxassetid://160432334', ['Minecraft XP'] = 'rbxassetid://1053296915', Neverlose = 'rbxassetid://6607204501', Fatality = 'rbxassetid://6534947869'
}

-- ============================================================
-- TABS
-- ============================================================

local LegitTab = window:AddTab({ Icon = 'crosshairs', Name = "Legit" })
local RageTab = window:AddTab({ Icon = 'crosshairs', Name = "Rage" })
local AimBotTab = window:AddTab({ Icon = 'crosshairs', Name = "AimBot" })
local VisualsTab = window:AddTab({ Icon = 'text', Name = "Visuals" })
local MiscTab = window:AddTab({ Icon = 'crosshairs', Name = "Misc" })
local SkinTab = window:AddTab({ Icon = 'crosshairs', Name = "Skin" })
local PlayersTab = window:AddTab({ Icon = 'crosshairs', Name = "Players" })
local MacroTab = window:AddTab({ Icon = 'crosshairs', Name = "Macro Hub" })

-- ============================================================
-- SECTIONS
-- ============================================================

local LegitSec = LegitTab:AddSection({ Name = "LEGIT BOT" })
local LegitSetSec = LegitTab:AddSection({ Name = "SETTINGS", Position = 'right' })

local RageSec = RageTab:AddSection({ Name = "RAGE BOT" })
local RageMiscSec = RageTab:AddSection({ Name = "MISCELLANEOUS", Position = 'right' })
local KnifeBotSec = RageTab:AddSection({ Name = "KNIFE BOT" })
local AntiAimSec = RageTab:AddSection({ Name = "ANTI AIM", Position = 'right' })

local AimBotSec = AimBotTab:AddSection({ Name = "TARGETING" })
local SilentAimSec = AimBotTab:AddSection({ Name = "SILENT AIM", Position = 'right' })

local EspSec = VisualsTab:AddSection({ Name = "PLAYER ESP" })
local WorldSec = VisualsTab:AddSection({ Name = "WORLD", Position = 'right' })
local TacticalSec = VisualsTab:AddSection({ Name = "TACTICAL", Position = 'right' })
local ViewmodelSec = VisualsTab:AddSection({ Name = "VIEWMODEL", Position = 'left' })
local WeaponSec = VisualsTab:AddSection({ Name = "WEAPON", Position = 'left' })
local SoundSec = VisualsTab:AddSection({ Name = "SOUND EFFECTS", Position = 'left' })
local ChinaHatSec = VisualsTab:AddSection({ Name = "CHINA HAT", Position = 'left' })
local TrailSec = VisualsTab:AddSection({ Name = "TRAIL", Position = 'left' })
local FpsBoostSec = VisualsTab:AddSection({ Name = "FPS BOOST", Position = 'left' })
local FontSec = VisualsTab:AddSection({ Name = "FONT CHANGER" })
local SkySec = VisualsTab:AddSection({ Name = "SKYBOX CHANGER", Position = 'right' })
local ShaderSec = VisualsTab:AddSection({ Name = "PSHADE LITE", Position = 'right' })

local MovementSec = MiscTab:AddSection({ Name = "MOVEMENT" })
local ExploitsSec = MiscTab:AddSection({ Name = "EXPLOITS", Position = 'left' })
local CombatSec = MiscTab:AddSection({ Name = "COMBAT", Position = 'right' })
local GunModsSec = MiscTab:AddSection({ Name = "GUN MODS", Position = 'right' })
local SafetySec = MiscTab:AddSection({ Name = "SAFETY & CAMERA" })
local C4Sec = MiscTab:AddSection({ Name = "C4", Position = 'right' })
local ChatSec = MiscTab:AddSection({ Name = "CHAT", Position = 'right' })

local SkinChangerSec = SkinTab:AddSection({ Name = "SKIN CHANGER" })
local KnifeChangerSec = SkinTab:AddSection({ Name = "KNIFE CHANGER", Position = 'right' })
local GlovesChangerSec = SkinTab:AddSection({ Name = "GLOVES CHANGER", Position = 'right' })

local PlayersListSec = PlayersTab:AddSection({ Name = "PLAYER LIST" })
local PrioritySec = PlayersTab:AddSection({ Name = "PRIORITY", Position = 'right' })

local MainSec = MacroTab:AddSection({ Name = "CONTROLS" })
local GlitchSec = MacroTab:AddSection({ Name = "GLITCHES", Position = 'left' })
local EmotesSec = MacroTab:AddSection({ Name = "PROJECTIONS & EMOTES", Position = 'right' })
local ConfigSec = MacroTab:AddSection({ Name = "CONFIGS", Position = 'right' })

-- ============================================================
-- STATE
-- ============================================================

local State = {
    Legit = {
        SilentAim = false, HitChance = 100, Aimbot = false, AimbotSpeed = 10, AimbotType = "Mouse Movement", AimbotSpeedType = "Linear", AimbotActivate = "Mouse 1",
        Triggerbot = false, TriggerbotDelay = 0, Fov = false, FovVisible = false, FovColor = Color3.fromRGB(255, 255, 255), FovValue = 25, FovNumSides = 100, Hitscan = "Head",
    },
    Rage = {
        Ragebot = false, SilentAim = false, SimulateShoot = false, AutoWall = false, ForceDamage = false, MinDamage = 80, Hitscan = {"Head"},
        Debug = false, Fov = false, FovVisible = false, FovColor = Color3.fromRGB(255, 255, 255), FovValue = 25, FovNumSides = 100, RapidFire = false, ForceHead = false, DoubleTap = false, Throwables = false, Noscope = false, Backstab = false,
        Knifebot = false, SimulateStab = false, KnifeWallCheck = false, KnifeRadius = 7,
        AntiAim = false, FakeDuck = false, YawBase = "Camera", PitchBase = "Custom", SpinSpeed = 3, CustomYaw = 0, CustomPitch = 0,
    },
    AimBot = {
        Enabled = false, FOV = 120, VisibleCheck = true, ShowFov = true, Target = "Closest",
        SilentEnabled = false, SilentFOV = 150, SilentTargetPart = "Head", SilentWallCheck = true, SilentShowFov = true,
    },
    Visuals = {
        ESP = false, Boxes = false, Health = false, Names = true, Distance = false, Chams = false,
        BoxColor = Color3.fromRGB(255, 255, 255), NameColor = Color3.fromRGB(255, 255, 255), DistanceColor = Color3.fromRGB(163, 165, 174), HealthColor = Color3.fromRGB(49, 209, 88),
        ColorWorld = false, WorldColor = Color3.fromRGB(150, 150, 150),
        XRayEnabled = false, XRayMode = "Potato", XRayTransparency = 75, XRayColor = Color3.fromRGB(200, 0, 255),
        SpectatorList = false, BombCalculator = false,
        BulletTracers = false, TracerStartColor = Color3.fromRGB(255, 255, 255), TracerEndColor = Color3.fromRGB(149, 255, 139), TracerTexture = "Line", TracerLifetime = 3,
        HitImpacts = false, HitImpactColor = Color3.fromRGB(255, 255, 255), HitImpactLifetime = 6,
        ViewmodelOffset = false, ViewmodelX = 0, ViewmodelY = 0, ViewmodelZ = 0, NoJumpBob = false, NoBob = false, NoSway = false,
        WeaponChams = false, WeaponChamsColor = Color3.fromRGB(149, 255, 139), WeaponTextureChanger = false, WeaponTexture = "Red + White",
        HitSound = false, HitSoundName = "Default Hit Sound", HitSoundVolume = 2, KillSound = false, KillSoundName = "Default Kill Sound", KillSoundVolume = 2,
    },
    Misc = {
        Fly = false, FlySpeed = 50, ThirdPerson = false, CamDistance = 10,
        BypassSpeed = false, AutoJump = false, Noclip = false, SpeedHack = false, SpeedHackSpeed = 40, Airstuck = false, Pixelsurf = false, Edgebug = false,
        AntiAimEnabled = false, AntiAimPitch = "Down", AntiAimYaw = "Off", BunnyHop = false, BhopSpeed = 1, MoveBeforeTime = false, FastReload = false,
        NoFlash = false, AntiSmoke = false, BypassAntiBan = false, ShotSc = false,
        KillAll = false, KillAllHPS = 1, AntiSpectate = false, AntiSpectateType = "Low Fov",
        NoRecoil = false, NoSpread = false, FullAuto = false, RapidFire = false, ConvertAmmo = false, InfAmmo = false,
    },
    Skins = {
        Weapons = {}, Knives = {Enabled = false, Type = "Knife", Skins = {}}, Gloves = {Enabled = false, Type = "Glove", Skins = {}},
    },
    Priority = { Kill = false, KillHPS = 1, FlashbangIntensity = 1 },
}

-- ============================================================
-- TEAMMATE DETECTION
-- ============================================================

local function isTeammate(p)
    if p == player then return true end
    local success, result = pcall(function()
        if player.Team and p.Team then return player.Team == p.Team end
        if not player.Neutral and not p.Neutral then
            if player.TeamColor and p.TeamColor then return player.TeamColor.Number == p.TeamColor.Number end
        end
        local localAttr = player:GetAttribute("Team")
        local playerAttr = p:GetAttribute("Team")
        if localAttr ~= nil and playerAttr ~= nil then return localAttr == playerAttr end
        local directAttr = p:GetAttribute("IsTeammate")
        if directAttr ~= nil then return directAttr == true end
        return false
    end)
    return success and result or false
end

-- ============================================================
-- AIMBOT LOGIC (SeraphiCA)
-- ============================================================

local CachedSilentTarget = nil
local LegitTarget = nil
local LegitTargetPart = nil
local RageTarget = nil

local function isTargetVisible(character, targetPart)
    local origin = cam.CFrame.Position
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function findSilentTarget()
    local viewport = cam.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestPart, bestScore = nil, math.huge
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and not isTeammate(p) and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist <= State.AimBot.SilentFOV and dist < bestScore then
                            local isVisible = true
                            if State.AimBot.SilentWallCheck then isVisible = isTargetVisible(char, targetPart) end
                            if isVisible then bestScore = dist bestPart = targetPart end
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

-- Усиленный Bypass Anti-Ban
local oldNamecall
if hookmetamethod then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if State.Misc.BypassAntiBan then
            if method == "Kick" and self == player then return nil end
            if (method == "FireServer" or method == "InvokeServer") then
                local remoteName = self.Name:lower()
                local firstArg = type(args[1]) == "string" and args[1]:lower() or ""
                if remoteName:match("ban") or remoteName:match("kick") or remoteName:match("report") or remoteName:match("anticheat") or remoteName:match("detector") then return nil end
                if firstArg:match("ban") or firstArg:match("kick") or firstArg:match("report") then return nil end
            end
        end
        
        if State.AimBot.SilentEnabled and CachedSilentTarget and not checkcaller() then
            if method == "Raycast" and self == workspace then
                local origin = args[1]
                args[2] = (CachedSilentTarget.Position - origin)
                return oldNamecall(self, unpack(args))
            end
        end
        
        -- Neyrone Silent Aim Hook
        if State.Legit.SilentAim and LegitTargetPart and method == "Raycast" and self == workspace and not checkcaller() then
            if State.Legit.HitChance >= math.random(1, 100) then
                args[2] = (LegitTargetPart.Position - args[1]).Unit * args[2].Magnitude
                return oldNamecall(self, unpack(args))
            end
        end
        
        -- Neyrone Throwables Teleport Hook
        if method == "FireServer" and self.Name == "Throwable" then
            if State.Rage.Throwables and RageTarget then
                args[2] = RageTarget.Character.Head.CFrame
                args[3] = -100
                return oldNamecall(self, unpack(args))
            end
        end
        
        -- Neyrone Viewmodel & No Sway Hook
        if method == "PivotTo" and self.Parent == cam and self.Name == "Arms" then
            if State.Visuals.NoSway and not State.Misc.ThirdPerson then
                args[1] = cam.CFrame
                return oldNamecall(self, unpack(args))
            end
            if State.Visuals.ViewmodelOffset then
                args[1] = args[1] * CFrame.new(State.Visuals.ViewmodelX / 300, State.Visuals.ViewmodelY / 300, State.Visuals.ViewmodelZ / 300)
                return oldNamecall(self, unpack(args))
            end
        end
        
        -- Neyrone Bullet Tracers & Hit Impacts Hook
        if method == "FireServer" and self == GameData.FireEvent and args[1] and args[1].Position ~= nil then
            local pos = args[1].Position
            if State.Visuals.BulletTracers then
                task.spawn(function()
                    local arms = cam:FindFirstChild("Arms")
                    if arms and arms:FindFirstChild("Flash") then
                        local startPos = arms.Flash.CFrame.Position
                        local p1 = Instance.new("Part")
                        p1.Size = Vector3.new(0.2, 0.2, 0.2)
                        p1.Position = startPos
                        p1.Transparency = 1
                        p1.CanCollide = false
                        p1.Anchored = true
                        p1.Parent = workspace.Debris
                        local p2 = Instance.new("Part")
                        p2.Size = Vector3.new(0.2, 0.2, 0.2)
                        p2.Position = pos
                        p2.Transparency = 1
                        p2.CanCollide = false
                        p2.Anchored = true
                        p2.Parent = workspace.Debris
                        local att1 = Instance.new("Attachment", p1)
                        local att2 = Instance.new("Attachment", p2)
                        local beam = Instance.new("Beam")
                        beam.Attachment0 = att1
                        beam.Attachment1 = att2
                        beam.Texture = State.Visuals.TracerTexture == "Line" and "rbxassetid://9150663556" or State.Visuals.TracerTexture == "Neyrone" and "rbxassetid://1825953680" or State.Visuals.TracerTexture == "Lighting" and "rbxassetid://446111271" or "ForceField"
                        beam.Color = ColorSequence.new(State.Visuals.TracerStartColor, State.Visuals.TracerEndColor)
                        beam.Width0 = 0.2
                        beam.Width1 = 0.2
                        beam.FaceCamera = true
                        beam.Transparency = NumberSequence.new(0)
                        beam.Parent = workspace.Debris
                        task.wait(State.Visuals.TracerLifetime)
                        for i = 1, 10 do beam.Transparency = NumberSequence.new(i / 10) task.wait(0.05) end
                        beam:Destroy() att1:Destroy() att2:Destroy() p1:Destroy() p2:Destroy()
                    end
                end)
            end
            if State.Visuals.HitImpacts then
                task.spawn(function()
                    local p = Instance.new("Part")
                    p.Transparency = 1
                    p.Anchored = true
                    p.CanCollide = false
                    p.Size = Vector3.new(0.3, 0.3, 0.3)
                    p.Position = pos
                    local sel = Instance.new("SelectionBox", p)
                    sel.LineThickness = 0
                    sel.SurfaceTransparency = 0.5
                    sel.Color3 = State.Visuals.HitImpactColor
                    sel.SurfaceColor3 = State.Visuals.HitImpactColor
                    sel.Adornee = p
                    p.Parent = workspace.Debris
                    task.wait(State.Visuals.HitImpactLifetime)
                    sel:Destroy() p:Destroy()
                end)
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

local function findAimTarget()
    local viewport = cam.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestPart, bestScore = nil, math.huge
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and not isTeammate(p) then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local targetPart = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
            if hum and hum.Health > 0 and targetPart then
                local point, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                if onScreen and point.Z > 0 then
                    local dist = (Vector2.new(point.X, point.Y) - center).Magnitude
                    if dist <= State.AimBot.FOV then
                        local visible = true
                        if State.AimBot.VisibleCheck then visible = isTargetVisible(char, targetPart) end
                        if visible and dist < bestScore then
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
    local isActiveSilent = State.AimBot.SilentEnabled and State.AimBot.SilentShowFov
    local isActiveRegular = State.AimBot.Enabled and State.AimBot.ShowFov
    if isActiveSilent then
        FovCircle.Size = UDim2.fromOffset(State.AimBot.SilentFOV * 2, State.AimBot.SilentFOV * 2)
        FovCircle.Visible = true
    elseif isActiveRegular then
        FovCircle.Size = UDim2.fromOffset(State.AimBot.FOV * 2, State.AimBot.FOV * 2)
        FovCircle.Visible = true
    else
        FovCircle.Visible = false
    end
end

-- ============================================================
-- RAGE BOT LOGIC (Neyrone Integration)
-- ============================================================

local Hitboxes = {Head = "Head", Torso = "HumanoidRootPart"}
local LastShotTick = 0
local LastReloadTick = 0

local function GetLegitTarget(useFov, fovDist)
    local bestDist, bestPlayer = useFov and fovDist or math.huge, nil
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and GameData.IsAlive(p) and (ReplicatedStorage:GetAttribute("NoTKPenalty") or p:GetAttribute("Team") ~= player:GetAttribute("Team")) and not p.Character:FindFirstChildWhichIsA("ForceField") then
            local screenPos, onScreen = cam:WorldToViewportPoint(p.Character[Hitboxes[State.Legit.Hitscan]].Position)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)).Magnitude
            if dist <= bestDist and onScreen then
                bestDist = dist
                bestPlayer = p
            end
        end
    end
    return bestPlayer
end

local function GetRageTarget()
    local bestDist, bestPlayer = State.Rage.Fov and (cam.ViewportSize.X * (State.Rage.FovValue / 2) / cam.FieldOfView) or math.huge, nil
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and GameData.IsAlive(p) and (ReplicatedStorage:GetAttribute("NoTKPenalty") or p:GetAttribute("Team") ~= player:GetAttribute("Team")) and not p.Character:FindFirstChildWhichIsA("ForceField") then
            local screenPos, onScreen = cam:WorldToViewportPoint(p.Character.Head.Position)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)).Magnitude
            if dist <= bestDist and onScreen then
                bestDist = dist
                bestPlayer = p
            end
        end
    end
    return bestPlayer
end

local HitboxMultipliers = {Head = 1.75, Torso = 1.25, ["Left Arm"] = 1, ["Right Arm"] = 1, ["Left Leg"] = 0.75, ["Right Leg"] = 0.75}
local DefaultValues = {Range = 8192, Penetration = 300, ArmorPenetration = 80, Damage = 50, Bullets = 1}

local function ArmorDamageLoss(armorPen, hasArmor)
    if not hasArmor then return 1 end
    return 0.01 * armorPen
end

local function DistanceDamageLoss(distance, rangeMod)
    return math.clamp((distance / 100) ^ (rangeMod / 34.7), 0.45, 1)
end

local function FireEvent(weaponFolder, hitPart, ratio, wallbang, bullets, noscope, backstab)
    local mult = State.Rage.DoubleTap and 2 or 1
    for _ = 1, mult do
        for _ = 1, bullets do
            GameData.FireEvent:FireServer({
                Normal = Vector3.zero, Position = hitPart.Position + Vector3.one, Hit = hitPart.Parent, cCF = cam.CFrame,
                hS = hitPart.Size and hitPart.Size.Magnitude, hP = hitPart.Position, PartName = (State.Rage.ForceHead or hitPart.Name:find("Head")) and "Head" or hitPart.Name,
                Wallbang = wallbang, Noscope = noscope or false, Backstab = backstab or false, Ratio = ratio
            }, weaponFolder, nil, true, cam.CFrame, hitPart.Position, nil, nil)
        end
    end
end

local function FakeShoot(weaponFolder, isKnife)
    if not ClientData.HasRequire or not GameData.Shucky or not GameData.Shucky.shootsound or not GameData.Ambassador or not GameData.Ambassador.Fire then return end
    if (not isKnife and not State.Rage.SimulateShoot) or (isKnife and not State.Rage.SimulateStab) then return end
    if weaponFolder:GetAttribute("WeaponType") == "Throwable" or not weaponFolder:FindFirstChild("Model") then return end
    GameData.Shucky.shootsound(weaponFolder.Model, cam)
    ReplicatedStorage.URE_ViewmodelAnimStream:FireServer(true, "fire", "fire", nil, nil, nil)
    local num = math.random(1, 2)
    GameData.Ambassador.Fire("VPlay", "2fire", "fire")
    GameData.Ambassador.Fire("WPlay", tostring(num), "Fire")
    if ClientData.HasGetsenv and ClientData.FullGetsenv and GameData.BaseWeapon then
        local ammoTable = debug.getupvalue(GameData.BaseWeapon.firebullet, 3)
        if ammoTable then
            local equipped = GameData.Variables.equipped
            local ammoData = ammoTable[equipped]
            if ammoData and ammoData.Ammo then
                local dec = State.Misc.InfAmmo and 0 or State.Rage.DoubleTap and 2 or 1
                ammoData.Ammo -= dec
                if ammoData.Ammo <= 0 then
                    ammoData.Ammo = 0
                    LastReloadTick = tick()
                    GameData.Ambassador.Fire("ReloadWeapon")
                end
                GameData.Ambassador.Fire("UpdateAmmo", ammoData)
            end
        end
    end
end

local function ShootTarget(weaponFolder, isKnife, originPos, targetPlayer, hitPart, visible, ratio, wallbang)
    local noscope, backstab = State.Rage.Noscope, State.Rage.Backstab
    local hasArmor, hasHelmet = targetPlayer:GetAttribute("Armor") > 0, targetPlayer:GetAttribute("Helmet")
    local armorPen = weaponFolder:GetAttribute("ArmorPenetration") or DefaultValues.ArmorPenetration
    local rangeMod = weaponFolder:GetAttribute("RangeModifier")
    local dmg = weaponFolder:GetAttribute("DMG") or DefaultValues.Damage
    local bullets = weaponFolder:GetAttribute("Bullets") or DefaultValues.Bullets
    local highHs = weaponFolder:GetAttribute("HighHS") and 15 or 0
    local hitboxMult = HitboxMultipliers[hitPart.Name] or 1
    local distance = (originPos - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
    local distLoss = rangeMod and DistanceDamageLoss(distance, rangeMod) or 1
    local armorLoss = ArmorDamageLoss(armorPen, hasArmor)
    local finalDmg = dmg * hitboxMult * ratio * armorLoss * distLoss + (hitPart.Name:find("Head") and highHs or 0)
    
    if State.Rage.ForceDamage or finalDmg >= State.Rage.MinDamage then
        if not State.Rage.SilentAim then cam.CFrame = CFrame.new(cam.CFrame.Position, hitPart.Position) end
        if weaponFolder:GetAttribute("Scoped") then
            if GameData.Variables and GameData.Variables.scoped ~= nil then
                noscope = GameData.Variables.scoped and State.Rage.Noscope or false
            else noscope = false end
        end
        task.spawn(FakeShoot, weaponFolder, isKnife)
        task.spawn(FireEvent, weaponFolder, hitPart, ratio, wallbang, bullets, noscope, backstab)
        return true
    end
    return false
end

local function AutoWall(weaponFolder, origin, targetPart, ignoreList)
    local hitResults, dir = {}, (targetPart.Position - origin).Unit
    local range = weaponFolder:GetAttribute("Range") or 8000
    local stepDist = range / 8 or 1000
    local rayDir = dir * stepDist
    local penetration = weaponFolder:GetAttribute("Penetration") or 0
    local lossPerWall = penetration > 0 and penetration * 0.02 or 0
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    params.IgnoreWater = true
    local currentPen = 0
    local result = workspace:Raycast(origin, rayDir, params)
    while result do
        local inst, pos = result.Instance, result.Position
        local isPlayer = inst.Parent:FindFirstChildOfClass("Humanoid")
        if isPlayer then
            table.insert(hitResults, {Hit = inst, Position = pos, Ratio = 1 - currentPen / penetration})
            break
        else
            local peneValue = inst:GetAttribute("PeneValue") or 1
            local mat = inst.Material
            if mat == Enum.Material.DiamondPlate then peneValue = 3 elseif mat == Enum.Material.CorrodedMetal or mat == Enum.Material.Metal then peneValue = 2 elseif mat == Enum.Material.Concrete or mat == Enum.Material.Brick then peneValue = 2 elseif inst.Name == "Grate" or mat == Enum.Material.Wood or mat == Enum.Material.WoodPlanks then peneValue = 0.5 elseif mat == Enum.Material.Fabric or mat == Enum.Material.Sand or mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass or mat == Enum.Material.Ground then peneValue = 0.1 elseif inst.Transparency == 1 or not inst.CanCollide or inst.Name == "Glass" or inst.Name == "Cardboard" then peneValue = 0 end
            if inst.Name == "nowallbang" then currentPen = penetration end
            currentPen += peneValue
            table.insert(params.FilterDescendantsInstances, inst)
            if lossPerWall == 0 or penetration < currentPen or penetration <= currentPen then break end
        end
        result = workspace:Raycast(pos, rayDir, params)
    end
    return hitResults
end

local function RageBotInit(weaponFolder, players, isKnife)
    if not workspace:FindFirstChild("Map") or ReplicatedStorage:GetAttribute("RoundOver") or ReplicatedStorage:GetAttribute("Preparation") or ReplicatedStorage:GetAttribute("GameOver") then return end
    local fireRate = weaponFolder:GetAttribute("FireRate") or 0.1
    local scopedFireRate = weaponFolder:GetAttribute("ScopedFireRate") or fireRate
    local currentRate = player.Character:GetAttribute("Aiming") and scopedFireRate or fireRate
    currentRate = State.Rage.RapidFire and 0.01 or currentRate
    local reloadTime = weaponFolder:GetAttribute("ReloadTime") or 0
    local now = tick()
    if now - LastShotTick < currentRate or now - LastReloadTick < reloadTime then return end
    
    local origin = (State.Rage.AntiAim and State.Rage.FakeDuck) and player.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0) or player.Character.Head.Position
    local hitboxes, hitFound, ignoreList = {}, false, {}
    
    if ClientData.HasRequire and GameData.Variables and GameData.Variables.Params then
        for _, v in ipairs(GameData.Variables.Params.FilterDescendantsInstances) do table.insert(ignoreList, v) end
    else ignoreList = {workspace.Destroyable, workspace.Debris, workspace.Map.Clips} end
    table.insert(ignoreList, player.Character)
    table.insert(ignoreList, cam)
    
    for _, p in ipairs(players) do
        if GameData.IsAlive(p) then
            if isKnife then
                if not State.Rage.Knifebot then return end
                local dir = (p.Character.HumanoidRootPart.Position - origin).Unit * State.Rage.KnifeRadius
                if not State.Rage.KnifeWallCheck then table.insert(ignoreList, workspace.Map) end
                local result = workspace:Raycast(origin, dir, RaycastParams.new())
                if result and result.Instance and result.Instance:IsDescendantOf(p.Character) then
                    task.spawn(FakeShoot, weaponFolder, isKnife)
                    task.spawn(FireEvent, weaponFolder, p.Character.HumanoidRootPart, 1, false, 1, State.Rage.Noscope, State.Rage.Backstab)
                    hitFound = true
                    break
                end
            else
                local parts = {}
                for _, hitboxName in ipairs(State.Rage.Hitscan) do
                    if hitboxName == "Head" and p.Character:FindFirstChild("Head") then table.insert(parts, p.Character.Head) end
                    if hitboxName == "Torso" and p.Character:FindFirstChild("Torso") then table.insert(parts, p.Character.Torso) end
                    if hitboxName == "Arms" then if p.Character:FindFirstChild("Left Arm") then table.insert(parts, p.Character["Left Arm"]) end if p.Character:FindFirstChild("Right Arm") then table.insert(parts, p.Character["Right Arm"]) end end
                    if hitboxName == "Legs" then if p.Character:FindFirstChild("Left Leg") then table.insert(parts, p.Character["Left Leg"]) end if p.Character:FindFirstChild("Right Leg") then table.insert(parts, p.Character["Right Leg"]) end end
                end
                for _, part in ipairs(parts) do
                    local dir = part.Position - origin
                    local result = workspace:Raycast(origin, dir, RaycastParams.new())
                    if result and result.Instance == part then
                        if ShootTarget(weaponFolder, isKnife, origin, p, part, true, 1, false) then hitFound = true break end
                    end
                    if State.Rage.AutoWall then
                        local wallHits = AutoWall(weaponFolder, origin, part, ignoreList)
                        for _, wallHit in ipairs(wallHits) do
                            if wallHit.Hit and wallHit.Hit.Parent == p.Character then
                                if ShootTarget(weaponFolder, isKnife, origin, p, part, false, State.Rage.ForceDamage and 1 or wallHit.Ratio, wallHit.Wallbang or false) then hitFound = true break end
                            end
                        end
                    end
                    if hitFound then break end
                end
            end
            if hitFound then LastShotTick = now break end
        end
    end
end

local function RageBotStart()
    if not State.Rage.Ragebot or not GameData.IsAlive(player) then return end
    if not GameData.EquippedWeapon or GameData.EquippedWeapon == "C4" or not GameData.EquippedWeaponFolder then return end
    if GameData.EquippedWeaponFolder:GetAttribute("WeaponType") == "Throwable" and not State.Rage.Throwables then return end
    local players = {}
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and GameData.IsAlive(p) and (ReplicatedStorage:GetAttribute("NoTKPenalty") or p:GetAttribute("Team") ~= player:GetAttribute("Team")) and not p.Character:FindFirstChildWhichIsA("ForceField") then
            table.insert(players, p)
        end
    end
    if #players > 0 then RageBotInit(GameData.EquippedWeaponFolder, players, GameData.EquippedWeaponFolder:GetAttribute("WeaponType") == "Melee") end
end

RunService.Stepped:Connect(function() task.spawn(RageBotStart) end)

-- ============================================================
-- SKIN CHANGER LOGIC (Neyrone Integration)
-- ============================================================

local function GetWeaponSkins()
    local skins = {}
    for _, folder in ipairs(ReplicatedStorage.Skins:GetChildren()) do
        if folder:IsA("Folder") and not table.find(GameData.SkinsData.Knives.List, folder.Name) and not table.find(GameData.SkinsData.Gloves.List, folder.Name) then
            local skinList = {}
            for _, skinFolder in ipairs(folder:GetChildren()) do
                if skinFolder:IsA("Folder") then table.insert(skinList, skinFolder.Name) end
            end
            if #skinList > 0 then skins[folder.Name] = skinList end
        end
    end
    return skins
end

local function ApplyWeaponSkin(weaponName, skinName)
    local arms = cam:FindFirstChild("Arms")
    if not GameData.IsAlive(player) or not arms or not weaponName or not skinName then return end
    local skinId = weaponName .. "_" .. skinName
    GameData.SkinsData.Weapons.Replacements[weaponName] = skinId
    player.Character:SetAttribute("WhatSkin", skinId)
    if GameData.Appearance and GameData.Appearance.MapGunSkin then
        GameData.Appearance.MapGunSkin(arms, skinId, false, 0, false, player, GameData.EquippedWeaponFolder, nil)
    end
end

local function ApplyCurrentWeaponSkin()
    if not GameData.IsAlive(player) or not GameData.EquippedWeapon or GameData.EquippedWeapon == "C4" or not GameData.EquippedWeaponFolder or GameData.EquippedWeaponFolder:GetAttribute("WeaponType") == "Throwable" then return end
    if State.Skins.Weapons[GameData.EquippedWeapon] and State.Skins.Weapons[GameData.EquippedWeapon].Enabled then
        ApplyWeaponSkin(GameData.EquippedWeapon, State.Skins.Weapons[GameData.EquippedWeapon].Skin)
    end
end

local function ApplyKnifeSkin()
    if not GameData.IsAlive(player) or not State.Skins.Knives.Enabled then return end
    if not GameData.EquippedWeapon or not table.find(GameData.SkinsData.Knives.List, GameData.EquippedWeapon) then return end
    player:SetAttribute("KnifeType", State.Skins.Knives.Type)
    local skin = "Stock"
    if State.Skins.Knives.Skins[State.Skins.Knives.Type] and State.Skins.Knives.Skins[State.Skins.Knives.Type].Enabled then
        skin = State.Skins.Knives.Skins[State.Skins.Knives.Type].Skin
    end
    local skinId = State.Skins.Knives.Type .. "_" .. skin
    player:SetAttribute("KnifeSkin", skinId)
    local arms = cam:FindFirstChild("Arms")
    if arms and GameData.Appearance and GameData.Appearance.MapGunSkin then
        GameData.SkinsData.Knives.Replacements[State.Skins.Knives.Type] = skinId
        GameData.Appearance.MapGunSkin(arms, skinId, false, 0, false, player, GameData.EquippedWeaponFolder, nil)
    end
end

local function ApplyGloves()
    if not GameData.IsAlive(player) or not State.Skins.Gloves.Enabled then return end
    player:SetAttribute("CTGloves", State.Skins.Gloves.Type .. "_Stock")
    player:SetAttribute("TGloves", State.Skins.Gloves.Type .. "_Stock")
    player.Character:SetAttribute("CTGloves", State.Skins.Gloves.Type .. "_Stock")
    player.Character:SetAttribute("TGloves", State.Skins.Gloves.Type .. "_Stock")
    local skin = "Stock"
    if State.Skins.Gloves.Skins[State.Skins.Gloves.Type] and State.Skins.Gloves.Skins[State.Skins.Gloves.Type].Enabled then
        skin = State.Skins.Gloves.Skins[State.Skins.Gloves.Type].Skin
    end
    player:SetAttribute("CTGloves", State.Skins.Gloves.Type .. "_" .. skin)
    player:SetAttribute("TGloves", State.Skins.Gloves.Type .. "_" .. skin)
    player.Character:SetAttribute("CTGloves", State.Skins.Gloves.Type .. "_" .. skin)
    player.Character:SetAttribute("TGloves", State.Skins.Gloves.Type .. "_" .. skin)
end

-- Hook MapGunSkin for skin replacements
if ClientData.HasHookfunction and GameData.Appearance and GameData.Appearance.MapGunSkin then
    local oldMapGunSkin = GameData.Appearance.MapGunSkin
    GameData.Appearance.MapGunSkin = newcclosure(function(self, skinId, ...)
        local arms = cam:FindFirstChild("Arms")
        if arms and GameData.IsAlive(player) and skinId and type(skinId) == "string" and self == arms then
            local weaponName = unpack(skinId:split("_"))
            if weaponName == "Knife" and State.Skins.Knives.Enabled and State.Skins.Knives.Type ~= "Knife" then
                local replacement = GameData.SkinsData.Knives.Replacements and GameData.SkinsData.Knives.Replacements[State.Skins.Knives.Type]
                if replacement then skinId = replacement end
            elseif State.Skins.Weapons[weaponName] and State.Skins.Weapons[weaponName].Enabled then
                local replacement = GameData.SkinsData.Weapons.Replacements[weaponName]
                if replacement then skinId = replacement end
            end
        end
        return oldMapGunSkin(self, skinId, ...)
    end)
end

-- ============================================================
-- ESP LOGIC (SeraphiCA + Neyrone)
-- ============================================================

local EspObjects = {}
local ChamsObjects = {}

local function clearEsp(p)
    local e = EspObjects[p]
    if e then
        for _, o in pairs(e) do
            if typeof(o) == "Instance" then o:Destroy() end
        end
        EspObjects[p] = nil
    end
    if ChamsObjects[p] then
        ChamsObjects[p]:Destroy()
        ChamsObjects[p] = nil
    end
end

local function makeEsp(p)
    if EspObjects[p] then return EspObjects[p] end
    
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.ZIndex = 10
    box.Parent = EspLayer
    local bs = Instance.new("UIStroke", box)
    bs.Color = State.Visuals.BoxColor
    bs.Thickness = 1.5
    bs.Transparency = 0

    local healthBack = Instance.new("Frame")
    healthBack.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
    healthBack.BorderSizePixel = 0
    healthBack.Visible = false
    healthBack.ZIndex = 11
    healthBack.Parent = EspLayer
    local hbcc = Instance.new("UICorner", healthBack) hbcc.CornerRadius = UDim.new(0, 2)

    local healthFill = Instance.new("Frame")
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.Position = UDim2.fromScale(0, 1)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = State.Visuals.HealthColor
    healthFill.BorderSizePixel = 0
    healthFill.ZIndex = 12
    healthFill.Parent = healthBack
    local hfcc = Instance.new("UICorner", healthFill) hfcc.CornerRadius = UDim.new(0, 2)

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Text = ""
    name.TextColor3 = State.Visuals.NameColor
    name.TextSize = 12
    name.Font = Enum.Font.GothamBold
    name.TextStrokeTransparency = 0.35
    name.Visible = false
    name.ZIndex = 13
    name.Parent = EspLayer

    local distance = Instance.new("TextLabel")
    distance.BackgroundTransparency = 1
    distance.Text = ""
    distance.TextColor3 = State.Visuals.DistanceColor
    distance.TextSize = 11
    distance.Font = Enum.Font.GothamMedium
    distance.TextStrokeTransparency = 0.35
    distance.Visible = false
    distance.ZIndex = 13
    distance.Parent = EspLayer

    local entry = {Box = box, HealthBack = healthBack, HealthFill = healthFill, Name = name, Distance = distance}
    EspObjects[p] = entry
    return entry
end

local function getBoundingScreenBox(c)
    local cf, sz = c:GetBoundingBox()
    local h = sz * 0.5
    local corners = {
        cf*Vector3.new(-h.X,-h.Y,-h.Z), cf*Vector3.new(-h.X,-h.Y,h.Z),
        cf*Vector3.new(-h.X,h.Y,-h.Z), cf*Vector3.new(-h.X,h.Y,h.Z),
        cf*Vector3.new(h.X,-h.Y,-h.Z), cf*Vector3.new(h.X,-h.Y,h.Z),
        cf*Vector3.new(h.X,h.Y,-h.Z), cf*Vector3.new(h.X,h.Y,h.Z)
    }
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local vis = false
    for _, wp in ipairs(corners) do
        local sp, os = cam:WorldToViewportPoint(wp)
        if sp.Z > 0 then
            minX = math.min(minX, sp.X)
            minY = math.min(minY, sp.Y)
            maxX = math.max(maxX, sp.X)
            maxY = math.max(maxY, sp.Y)
            vis = vis or os
        end
    end
    if not vis or minX == math.huge then return nil end
    return minX, minY, maxX, maxY
end

local function updateEsp()
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player then
            local e = makeEsp(p)
            
            if State.Visuals.Chams then
                if not ChamsObjects[p] and p.Character then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = State.Visuals.BoxColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                    hl.Parent = p.Character
                    ChamsObjects[p] = hl
                end
            else
                if ChamsObjects[p] then
                    ChamsObjects[p]:Destroy()
                    ChamsObjects[p] = nil
                end
            end
            
            if isTeammate(p) or not State.Visuals.ESP then
                e.Box.Visible = false
                e.HealthBack.Visible = false
                e.Name.Visible = false
                e.Distance.Visible = false
                if ChamsObjects[p] then ChamsObjects[p].Enabled = false end
            else
                if ChamsObjects[p] then ChamsObjects[p].Enabled = State.Visuals.Chams end
                
                local char = p.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
                
                if char and hum and hum.Health > 0 and root then
                    local minX, minY, maxX, maxY = getBoundingScreenBox(char)
                    if minX then
                        local width = math.max(2, maxX - minX)
                        local height = math.max(2, maxY - minY)
                        
                        e.Box.UIStroke.Color = State.Visuals.BoxColor
                        e.HealthFill.BackgroundColor3 = State.Visuals.HealthColor
                        e.Name.TextColor3 = State.Visuals.NameColor
                        e.Distance.TextColor3 = State.Visuals.DistanceColor
                        if ChamsObjects[p] then ChamsObjects[p].FillColor = State.Visuals.BoxColor end
                        
                        e.Box.Position = UDim2.fromOffset(minX, minY)
                        e.Box.Size = UDim2.fromOffset(width, height)
                        e.Box.Visible = State.Visuals.Boxes
                        
                        e.HealthBack.Position = UDim2.fromOffset(minX - 7, minY)
                        e.HealthBack.Size = UDim2.fromOffset(4, height)
                        e.HealthBack.Visible = State.Visuals.Health
                        local hr = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        e.HealthFill.Size = UDim2.fromScale(1, hr)
                        
                        local vp, os = cam:WorldToViewportPoint(root.Position)
                        if os and vp.Z > 0 then
                            e.Name.Text = p.DisplayName ~= "" and p.DisplayName or p.Name
                            e.Name.Position = UDim2.fromOffset(minX, minY - 20)
                            e.Name.Size = UDim2.fromOffset(width, 18)
                            e.Name.TextXAlignment = Enum.TextXAlignment.Center
                            e.Name.Visible = State.Visuals.Names
                            
                            local lr = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head"))
                            if lr then
                                local dv = (lr.Position - root.Position).Magnitude
                                e.Distance.Text = string.format("%dm", math.floor(dv + 0.5))
                                e.Distance.Position = UDim2.fromOffset(minX, maxY + 2)
                                e.Distance.Size = UDim2.fromOffset(width, 16)
                                e.Distance.TextXAlignment = Enum.TextXAlignment.Center
                                e.Distance.Visible = State.Visuals.Distance
                            else
                                e.Distance.Visible = false
                            end
                        else
                            e.Name.Visible = false
                            e.Distance.Visible = false
                        end
                    else
                        e.Box.Visible = false
                        e.HealthBack.Visible = false
                        e.Name.Visible = false
                        e.Distance.Visible = false
                    end
                else
                    e.Box.Visible = false
                    e.HealthBack.Visible = false
                    e.Name.Visible = false
                    e.Distance.Visible = false
                end
            end
        end
    end
end

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
            if model and LocalPlayers:GetPlayerFromCharacter(model) then isPlayer = true end
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
    
    local char = player.Character
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
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui.Name:lower():match("flash") then
                local f = gui:FindFirstChildOfClass("Frame") or gui:FindFirstChildOfClass("ImageLabel")
                if f and f.BackgroundTransparency < 0.5 then f.BackgroundTransparency = 1 end
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
-- FEATURE LOGIC: FLY
-- ============================================================

local FlyUpButton = Instance.new("TextButton")
FlyUpButton.Size = UDim2.fromOffset(70, 70)
FlyUpButton.Position = UDim2.new(0, 20, 1, -170)
FlyUpButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyUpButton.BackgroundTransparency = 0.35
FlyUpButton.Text = "↑"
FlyUpButton.TextSize = 36
FlyUpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyUpButton.Font = Enum.Font.GothamBold
FlyUpButton.Visible = false
FlyUpButton.ZIndex = 200
FlyUpButton.Parent = RuntimeGui
local fuc = Instance.new("UICorner", FlyUpButton) fuc.CornerRadius = UDim.new(0, 35)
local fus = Instance.new("UIStroke", FlyUpButton) fus.Color = Color3.fromRGB(255, 255, 255) fus.Thickness = 1 fus.Transparency = 0.3

local FlyDownButton = Instance.new("TextButton")
FlyDownButton.Size = UDim2.fromOffset(70, 70)
FlyDownButton.Position = UDim2.new(0, 20, 1, -95)
FlyDownButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyDownButton.BackgroundTransparency = 0.35
FlyDownButton.Text = "↓"
FlyDownButton.TextSize = 36
FlyDownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyDownButton.Font = Enum.Font.GothamBold
FlyDownButton.Visible = false
FlyDownButton.ZIndex = 200
FlyDownButton.Parent = RuntimeGui
local fdc = Instance.new("UICorner", FlyDownButton) fdc.CornerRadius = UDim.new(0, 35)
local fds = Instance.new("UIStroke", FlyDownButton) fds.Color = Color3.fromRGB(255, 255, 255) fds.Thickness = 1 fds.Transparency = 0.3

local flyUp, flyDown = false, false
FlyUpButton.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyUp = true end end)
FlyUpButton.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyUp = false end end)
FlyDownButton.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyDown = true end end)
FlyDownButton.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyDown = false end end)

local flyConnection, noclipConnection, flyBodyVelocity = nil, nil, nil
local function enableFly()
    local c = player.Character if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart") local h = c:FindFirstChildOfClass("Humanoid") if not r or not h then return end
    FlyUpButton.Visible = true FlyDownButton.Visible = true
    noclipConnection = RunService.Stepped:Connect(function()
        if not State.Misc.Fly then return end
        local ch = player.Character if ch then for _, p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end)
    flyBodyVelocity = Instance.new("BodyVelocity") flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9) flyBodyVelocity.Velocity = Vector3.zero flyBodyVelocity.Parent = r
    flyConnection = RunService.RenderStepped:Connect(function()
        if not State.Misc.Fly then return end
        local ch = player.Character if not ch then return end
        local rt = ch:FindFirstChild("HumanoidRootPart") local hu = ch:FindFirstChildOfClass("Humanoid") local camera = Workspace.CurrentCamera
        if not rt or not hu or not camera then return end
        local sp = State.Misc.FlySpeed local vel = Vector3.zero local md = hu.MoveDirection
        if md.Magnitude > 0.1 then
            local cl = camera.CFrame.LookVector local fl = Vector3.new(cl.X, 0, cl.Z).Unit local fa = md.X * fl.X + md.Z * fl.Z
            vel = Vector3.new(md.X * sp, 0, md.Z * sp)
            if math.abs(fa) > 0.1 then vel = vel + Vector3.new(0, cl.Y * sp * fa, 0) end
        end
        if flyUp then vel = vel + Vector3.new(0, 1, 0) * sp end
        if flyDown then vel = vel - Vector3.new(0, 1, 0) * sp end
        flyBodyVelocity.Velocity = vel
        if vel.Magnitude > 1 then local lp = rt.Position + vel rt.CFrame = CFrame.lookAt(rt.Position, Vector3.new(lp.X, rt.Position.Y, lp.Z)) end
    end)
end

local function disableFly()
    local c = player.Character if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.PlatformStand = false end for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end if flyConnection then flyConnection:Disconnect() flyConnection = nil end if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    FlyUpButton.Visible = false FlyDownButton.Visible = false flyUp = false flyDown = false
end

-- ============================================================
-- FEATURE LOGIC: SHOTSC
-- ============================================================

local originalSizes = {}
local function disableShotSc()
    for part, size in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = size
            part.Transparency = 0
            part.Material = Enum.Material.Plastic
            part.Color = Color3.fromRGB(163, 162, 165)
            part.CanCollide = true
        end
    end
    originalSizes = {}
end

local function updateShotSc()
    if not State.Misc.ShotSc then return end
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and not isTeammate(p) and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                for _, partName in ipairs({"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}) do
                    local part = char:FindFirstChild(partName)
                    if part and part.Size.X < 10 then
                        if not originalSizes[part] then originalSizes[part] = part.Size end
                        part.Size = Vector3.new(10, 10, 10)
                        part.Transparency = 0.5
                        part.Material = Enum.Material.Neon
                        part.Color = Color3.fromRGB(255, 69, 58)
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end

-- ============================================================
-- FEATURE LOGIC: BYPASS ANTI-BAN
-- ============================================================

local function enableBypassAntiBan()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            local name = v.Name:lower()
            if name:match("anticheat") or name:match("anti") or name:match("cheat") or name:match("ban") or name:match("kick") or name:match("detector") then
                pcall(function() v:Destroy() end)
            end
        end
    end
end

-- ============================================================
-- FEATURE LOGIC: GUN MODS (Neyrone)
-- ============================================================

local originalWeaponStats = {}
local function saveWeaponStats()
    for _, folder in ipairs(ReplicatedStorage.Weapons:GetChildren()) do
        if folder:IsA("Folder") then
            originalWeaponStats[folder.Name] = {
                RecoilX = folder:GetAttribute("RecoilX"), RecoilY = folder:GetAttribute("RecoilY"),
                Auto = folder:GetAttribute("Auto"), ScopedFireRate = folder:GetAttribute("ScopedFireRate"), FireRate = folder:GetAttribute("FireRate"),
                Penetration = folder:GetAttribute("Penetration"), Range = folder:GetAttribute("Range"),
                Ammo = folder:GetAttribute("Ammo"), StoredAmmo = folder:GetAttribute("StoredAmmo"),
                Spread = folder:GetAttribute("Spread"), CrouchSpread = folder:GetAttribute("CrouchSpread"), FireSpread = folder:GetAttribute("FireSpread"),
                LadderSpread = folder:GetAttribute("LadderSpread"), LandSpread = folder:GetAttribute("LandSpread"), MoveSpread = folder:GetAttribute("MoveSpread"),
                StandSpread = folder:GetAttribute("StandSpread"), JumpSpread = folder:GetAttribute("JumpSpread"), RunSpread = folder:GetAttribute("RunSpread")
            }
        end
    end
end

local function applyGunMods()
    for _, folder in ipairs(ReplicatedStorage.Weapons:GetChildren()) do
        if folder:IsA("Folder") then
            local orig = originalWeaponStats[folder.Name]
            if orig then
                if State.Misc.NoRecoil then folder:SetAttribute("RecoilX", 0) folder:SetAttribute("RecoilY", 0) else folder:SetAttribute("RecoilX", orig.RecoilX) folder:SetAttribute("RecoilY", orig.RecoilY) end
                if State.Misc.NoSpread then
                    folder:SetAttribute("Spread", 0) folder:SetAttribute("CrouchSpread", 0) folder:SetAttribute("FireSpread", 0) folder:SetAttribute("LadderSpread", 0) folder:SetAttribute("LandSpread", 0) folder:SetAttribute("MoveSpread", 0) folder:SetAttribute("StandSpread", 0) folder:SetAttribute("JumpSpread", 0) folder:SetAttribute("RunSpread", 0)
                else
                    folder:SetAttribute("Spread", orig.Spread) folder:SetAttribute("CrouchSpread", orig.CrouchSpread) folder:SetAttribute("FireSpread", orig.FireSpread) folder:SetAttribute("LadderSpread", orig.LadderSpread) folder:SetAttribute("LandSpread", orig.LandSpread) folder:SetAttribute("MoveSpread", orig.MoveSpread) folder:SetAttribute("StandSpread", orig.StandSpread) folder:SetAttribute("JumpSpread", orig.JumpSpread) folder:SetAttribute("RunSpread", orig.RunSpread)
                end
                if State.Misc.FullAuto then folder:SetAttribute("Auto", true) else folder:SetAttribute("Auto", orig.Auto) end
                if State.Misc.RapidFire then folder:SetAttribute("FireRate", 0.01) folder:SetAttribute("ScopedFireRate", 0.01) else folder:SetAttribute("FireRate", orig.FireRate) folder:SetAttribute("ScopedFireRate", orig.ScopedFireRate) end
                if State.Misc.ConvertAmmo then folder:SetAttribute("Ammo", 9e9) folder:SetAttribute("StoredAmmo", 9e9) else folder:SetAttribute("Ammo", orig.Ammo) folder:SetAttribute("StoredAmmo", orig.StoredAmmo) end
                if State.Misc.InfAmmo then folder:SetAttribute("UseAmmo", 0) else if folder:GetAttribute("UseAmmo") ~= nil then folder:SetAttribute("UseAmmo", nil) end end
            end
        end
    end
end

saveWeaponStats()

-- ============================================================
-- FEATURE LOGIC: EXPLOITS (Neyrone)
-- ============================================================

local function KillAllInit()
    if not State.Misc.KillAll or not GameData.IsAlive(player) or not GameData.EquippedWeaponFolder then return end
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and GameData.IsAlive(p) and not p.Character:FindFirstChildWhichIsA("ForceField") then
            local hps = State.Misc.KillAllHPS > 1 and State.Misc.KillAllHPS or 1
            for _ = 1, hps do
                GameData.FireEvent:FireServer({
                    Normal = Vector3.zero, Position = p.Character.Head.Position + Vector3.one, Hit = p.Character, cCF = cam.CFrame,
                    hS = p.Character.Head.Size and p.Character.Head.Size.Magnitude, hP = p.Character.Head.Position, PartName = "Head", Wallbang = true
                }, GameData.EquippedWeaponFolder, nil, true, cam.CFrame, p.Character.Head.Position, nil, nil)
            end
        end
    end
end

local function KillPriorityInit()
    if not State.Priority.Kill or not GameData.IsAlive(player) or not GameData.EquippedWeaponFolder then return end
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and GameData.IsAlive(p) and not p.Character:FindFirstChildWhichIsA("ForceField") then
            local hps = State.Priority.KillHPS > 1 and State.Priority.KillHPS or 1
            for _ = 1, hps do
                GameData.FireEvent:FireServer({
                    Normal = Vector3.zero, Position = p.Character.Head.Position + Vector3.one, Hit = p.Character, cCF = cam.CFrame,
                    hS = p.Character.Head.Size and p.Character.Head.Size.Magnitude, hP = p.Character.Head.Position, PartName = "Head", Wallbang = true
                }, GameData.EquippedWeaponFolder, nil, true, cam.CFrame, p.Character.Head.Position, nil, nil)
            end
        end
    end
end

local function FlashbangEnemies()
    if not GameData.IsAlive(player) then return Notification.new({Title = "Exploits", Content = "You are dead!", Duration = 5}) end
    if ReplicatedStorage:GetAttribute("Preparation") then return Notification.new({Title = "Exploits", Content = "Let the round start!", Duration = 5}) end
    if GameData.EquippedWeapon ~= "Flashbang" then return Notification.new({Title = "Exploits", Content = "Hold the flashbang grenade!", Duration = 6}) end
    Notification.new({Title = "Exploits", Content = "Flashbanging enemies...", Duration = 5})
    for _, p in ipairs(LocalPlayers:GetPlayers()) do
        if p ~= player and GameData.IsAlive(p) and not p.Character:FindFirstChildWhichIsA("ForceField") then
            if GameData.EquippedWeapon ~= "Flashbang" then return end
            local intensity = State.Priority.FlashbangIntensity > 1 and State.Priority.FlashbangIntensity or 1
            for _ = 1, intensity do
                GameData.FireEvent:FireServer({
                    Normal = Vector3.zero, Position = p.Character.Torso.Position + Vector3.one, Hit = p.Character, cCF = cam.CFrame,
                    hS = p.Character.Torso.Size and p.Character.Torso.Size.Magnitude, hP = p.Character.Torso.Position, PartName = "Torso", BlindLevel = 1
                }, GameData.EquippedWeaponFolder, nil, true, cam.CFrame, p.Character.Torso.Position, nil, nil)
            end
        end
    end
end

local function PlantC4(site)
    if not GameData.IsAlive(player) then return Notification.new({Title = "C4", Content = "You are dead!", Duration = 5}) end
    if player:GetAttribute("Team") ~= "T" then return Notification.new({Title = "C4", Content = "You are not in Militia team!", Duration = 5}) end
    if ReplicatedStorage:GetAttribute("HasBomb") ~= player.Name then return Notification.new({Title = "C4", Content = "You don't have the bomb!", Duration = 5}) end
    if ReplicatedStorage:GetAttribute("Preparation") then return Notification.new({Title = "C4", Content = "Let the round start!", Duration = 5}) end
    local originCF = player.Character.HumanoidRootPart.CFrame
    task.wait(0.1)
    local siteName = site == "A" and "BombA" or "BombB"
    player.Character.HumanoidRootPart.CFrame = workspace.Map.Markers[siteName].CFrame - Vector3.new(0, -1, 0)
    task.wait(0.3)
    ReplicatedStorage.Events.PlantC4:FireServer()
    player.Character.HumanoidRootPart.CFrame = originCF
    Notification.new({Title = "C4", Content = "Bomb planted on site " .. site, Duration = 5})
end

local function DefuseC4()
    if not GameData.IsAlive(player) then return Notification.new({Title = "C4", Content = "You are dead!", Duration = 5}) end
    if player:GetAttribute("Team") ~= "CT" then return Notification.new({Title = "C4", Content = "You are not in Operators team!", Duration = 5}) end
    if not GameData.IsC4Planted() then return Notification.new({Title = "C4", Content = "Bomb hasn't been planted!", Duration = 5}) end
    ReplicatedStorage.Events.StartDefuse:FireServer()
    if GameData.Ambassador and GameData.Ambassador.Fire then GameData.Ambassador.Fire("UpdateDefuse") end
    ReplicatedStorage.Events.StartDefuse:FireServer()
    if GameData.Ambassador and GameData.Ambassador.Fire then GameData.Ambassador.Fire("StopDefuse") end
    Notification.new({Title = "C4", Content = "Defusing bomb, wait 8 seconds", Duration = 6})
end

-- ============================================================
-- SPECTATOR & BOMB WIDGETS
-- ============================================================

local SpectatorWidget = Instance.new("Frame", RuntimeGui)
SpectatorWidget.Size = UDim2.fromOffset(150, 100)
SpectatorWidget.Position = UDim2.new(0, 20, 0, 60)
SpectatorWidget.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SpectatorWidget.BackgroundTransparency = 0.3
SpectatorWidget.Visible = false
local spc = Instance.new("UICorner", SpectatorWidget) spc.CornerRadius = UDim.new(0, 8)
local sps = Instance.new("UIStroke", SpectatorWidget) sps.Color = Color3.fromRGB(255, 255, 255) sps.Thickness = 1 sps.Transparency = 0.5

local SpectatorTitle = Instance.new("TextLabel", SpectatorWidget)
SpectatorTitle.BackgroundTransparency = 1
SpectatorTitle.Size = UDim2.new(1, 0, 0, 20)
SpectatorTitle.Position = UDim2.fromOffset(0, 5)
SpectatorTitle.Text = "SPECTATORS"
SpectatorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SpectatorTitle.TextSize = 12
SpectatorTitle.Font = Enum.Font.GothamBold
SpectatorTitle.TextXAlignment = Enum.TextXAlignment.Center

local SpectatorList = Instance.new("TextLabel", SpectatorWidget)
SpectatorList.BackgroundTransparency = 1
SpectatorList.Size = UDim2.new(1, -10, 1, -30)
SpectatorList.Position = UDim2.fromOffset(5, 25)
SpectatorList.Text = ""
SpectatorList.TextColor3 = Color3.fromRGB(163, 165, 174)
SpectatorList.TextSize = 11
SpectatorList.Font = Enum.Font.Gotham
SpectatorList.TextXAlignment = Enum.TextXAlignment.Center

local BombWidget = Instance.new("TextLabel", RuntimeGui)
BombWidget.Size = UDim2.fromOffset(200, 40)
BombWidget.Position = UDim2.new(0.5, -100, 0, 60)
BombWidget.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BombWidget.BackgroundTransparency = 0.3
BombWidget.Visible = false
BombWidget.Text = ""
BombWidget.TextColor3 = Color3.fromRGB(255, 255, 255)
BombWidget.Font = Enum.Font.GothamBold
BombWidget.TextSize = 14
local bwc = Instance.new("UICorner", BombWidget) bwc.CornerRadius = UDim.new(0, 8)
local bws = Instance.new("UIStroke", BombWidget) bws.Color = Color3.fromRGB(255, 255, 255) bws.Thickness = 1 bws.Transparency = 0.5

-- ============================================================
-- MACRO HUB FEATURES
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeraphiCAMacroHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local TpButton = Instance.new("TextButton")
TpButton.Name = "OmegaTPBtn"
TpButton.Size = UDim2.new(0, 75, 0, 75)
TpButton.Position = UDim2.new(0.85, 0, 0.35, 0)
TpButton.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
TpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TpButton.Text = "OMEGA\nTP"
TpButton.TextSize = 13
TpButton.Font = Enum.Font.GothamBold
TpButton.Active = true
TpButton.Draggable = true
TpButton.Visible = false
TpButton.Parent = ScreenGui
local TpCorner = Instance.new("UICorner", TpButton) TpCorner.CornerRadius = UDim.new(1, 0)
local TpStroke = Instance.new("UIStroke", TpButton) TpStroke.Thickness = 2 TpStroke.Color = Color3.fromRGB(160, 50, 255)

local LagButton = Instance.new("TextButton")
LagButton.Name = "LagSwitchBtn"
LagButton.Size = UDim2.new(0, 70, 0, 70)
LagButton.Position = UDim2.new(0.85, 0, 0.5, 0)
LagButton.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
LagButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LagButton.Text = "LAG"
LagButton.TextSize = 15
LagButton.Font = Enum.Font.GothamBold
LagButton.Active = true
LagButton.Draggable = true
LagButton.Visible = false
LagButton.Parent = ScreenGui
local LagCorner = Instance.new("UICorner", LagButton) LagCorner.CornerRadius = UDim.new(1, 0)
local LagStroke = Instance.new("UIStroke", LagButton) LagStroke.Thickness = 2 LagStroke.Color = Color3.fromRGB(220, 60, 60)

local HoldButton = Instance.new("TextButton")
HoldButton.Name = "HoldFlick"
HoldButton.Size = UDim2.new(0, 75, 0, 75)
HoldButton.Position = UDim2.new(0.85, 0, 0.65, 0)
HoldButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.Text = "HOLD"
HoldButton.TextSize = 16
HoldButton.Font = Enum.Font.GothamBold
HoldButton.AutoButtonColor = false
HoldButton.Active = true
HoldButton.Draggable = true
HoldButton.Visible = false
HoldButton.Parent = ScreenGui
local HoldCorner = Instance.new("UICorner", HoldButton) HoldCorner.CornerRadius = UDim.new(1, 0)
local HoldStroke = Instance.new("UIStroke", HoldButton) HoldStroke.Thickness = 2 HoldStroke.Color = Color3.fromRGB(100, 150, 255)

local SpidiButton = Instance.new("TextButton")
SpidiButton.Name = "WallHopButton"
SpidiButton.Size = UDim2.new(0, 70, 0, 70)
SpidiButton.Position = UDim2.new(0.1, 0, 0.7, 0)
SpidiButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SpidiButton.Text = "Spidi"
SpidiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpidiButton.Font = Enum.Font.GothamBold
SpidiButton.TextScaled = true
SpidiButton.Visible = false
SpidiButton.Parent = ScreenGui
local SpidiCorner = Instance.new("UICorner", SpidiButton) SpidiCorner.CornerRadius = UDim.new(1, 0)

local speedFrame = Instance.new("Frame")
speedFrame.Name = "SpeedFrame"
speedFrame.Size = UDim2.new(0, 160, 0, 45)
speedFrame.Position = UDim2.new(0.5, -80, 0.85, 0)
speedFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
speedFrame.BackgroundTransparency = 0.1
speedFrame.BorderSizePixel = 0
speedFrame.Active = true
speedFrame.Draggable = true
speedFrame.Visible = false
speedFrame.Parent = ScreenGui
local speedCorner = Instance.new("UICorner", speedFrame) speedCorner.CornerRadius = UDim.new(0, 10)
local speedStroke = Instance.new("UIStroke", speedFrame) speedStroke.Color = Color3.fromRGB(0, 170, 255) speedStroke.Thickness = 1.8
local speedLabel = Instance.new("TextLabel", speedFrame)
speedLabel.Size = UDim2.new(1, 0, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextSize = 16
speedLabel.Text = "Speed: 0"

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    for _, otherPlayer in ipairs(LocalPlayers:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (otherPlayer.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closestPlayer = otherPlayer
            end
        end
    end
    return closestPlayer
end

local isOmegaActive = false
local isStdActive = false
local currentOffset = CFrame.new(0, 0, 0)
local activeGhost, activeWeld = nil, nil
local cachedRoot, cachedTorso = nil, nil

local function runOmegaTeleportGlitch()
    local targetPlayer = getClosestPlayer()
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    local targetHrp = targetPlayer.Character.HumanoidRootPart
    if hrp and torso and targetHrp then
        local ghost = Instance.new("Part")
        ghost.Name = "OmegaTP_Ghost"
        ghost.Size = Vector3.new(1, 1, 1)
        ghost.CFrame = torso.CFrame
        ghost.Transparency = 1
        ghost.CanCollide = false
        ghost.Parent = char
        local weld = Instance.new("Weld")
        weld.Part0 = torso
        weld.Part1 = ghost
        weld.C0 = CFrame.new(0, 0, -250)
        weld.Parent = ghost
        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1.5)
        task.wait(0.05)
        ghost:Destroy()
    end
end

TpButton.MouseButton1Click:Connect(function()
    TpButton.BackgroundColor3 = Color3.fromRGB(140, 0, 220)
    task.spawn(runOmegaTeleportGlitch)
    task.wait(0.1)
    TpButton.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
end)

local function destroyGhost()
    if activeGhost then
        activeGhost:Destroy()
        activeGhost = nil
        activeWeld = nil
    end
end

local function calculateHeight()
    local char = player.Character
    if not char then return 5 end
    local root = char:FindFirstChild("HumanoidRootPart")
    local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("LeftLeg")
    if root and foot then
        return math.abs(root.Position.Y - foot.Position.Y)
    end
    return 5
end

local function deployGhostGlitch()
    if not (isOmegaActive or isStdActive) then
        destroyGhost()
        return
    end
    local char = player.Character
    if not char then return end
    cachedRoot = char:FindFirstChild("HumanoidRootPart")
    cachedTorso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not cachedTorso or not cachedRoot then return end
    local rawCF = cachedRoot.CFrame:ToObjectSpace(cachedTorso.CFrame)
    local height = calculateHeight()
    local baseMultiplier = isOmegaActive and 250 or 50
    if height < 4 or height > 6 then
        baseMultiplier = (isOmegaActive and 200 or 40) * (height / 3)
    end
    local newPos = rawCF.Position * baseMultiplier
    currentOffset = CFrame.new(newPos) * rawCF.Rotation
    local oldGhost = char:FindFirstChild("Skibidi_Ghost_Active")
    if oldGhost then oldGhost:Destroy() end
    local newGhost = Instance.new("Part")
    newGhost.Name = "Skibidi_Ghost_Active"
    newGhost.Size = Vector3.new(1, 1, 1)
    newGhost.CFrame = cachedTorso.CFrame
    newGhost.Transparency = 1
    newGhost.CanCollide = false
    newGhost.Parent = char
    activeWeld = Instance.new("Weld")
    activeWeld.Part0 = cachedTorso
    activeWeld.Part1 = newGhost
    activeWeld.C0 = currentOffset
    activeWeld.Parent = newGhost
    activeGhost = newGhost
end

local function setupListeners(char)
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            activeGhost = nil
            activeWeld = nil
            cachedRoot = nil
            cachedTorso = nil
        end)
    end
    task.defer(deployGhostGlitch)
    char.ChildAdded:Connect(function(child) if child:IsA("Tool") then deployGhostGlitch() end end)
    char.ChildRemoved:Connect(function(child) if child:IsA("Tool") then deployGhostGlitch() end end)
end

if player.Character then setupListeners(player.Character) end
player.CharacterAdded:Connect(setupListeners)

RunService.Heartbeat:Connect(function()
    if isOmegaActive or isStdActive then
        if activeWeld and activeWeld.Parent then
            activeWeld.C0 = currentOffset
        else
            if player.Character and (not activeGhost or activeGhost.Parent ~= player.Character) then
                deployGhostGlitch()
            end
        end
    else
        destroyGhost()
    end
end)

local isLagSwitchActive = false
local lagConnection = nil

local function toggleLag(v)
    isLagSwitchActive = v
    if isLagSwitchActive then
        LagButton.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
        LagStroke.Color = Color3.fromRGB(255, 255, 255)
        lagConnection = RunService.Heartbeat:Connect(function()
            if not isLagSwitchActive then return end
            local startTime = os.clock()
            while os.clock() - startTime < 0.25 do end
        end)
    else
        LagButton.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        LagStroke.Color = Color3.fromRGB(220, 60, 60)
        if lagConnection then
            lagConnection:Disconnect()
            lagConnection = nil
        end
    end
end

local flickPower = 120
local flickDelay = 0.0001
local flickHolding = false

local function startFlick()
    if flickHolding then return end
    flickHolding = true
    while flickHolding do
        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(flickPower), 0)
        task.wait(flickDelay)
        if not flickHolding then break end
        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(-flickPower), 0)
        task.wait(flickDelay)
    end
end

local function stopFlick()
    flickHolding = false
end

HoldButton.MouseButton1Down:Connect(startFlick)
HoldButton.MouseButton1Up:Connect(stopFlick)

local isFlicking = false
local lastFlickTime = 0

local function performVideoFlick()
    if isFlicking then return end
    isFlicking = true
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then isFlicking = false return end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 50, hrp.AssemblyLinearVelocity.Z)
    local startCFrame = cam.CFrame
    cam.CFrame = startCFrame * CFrame.Angles(0, math.rad(180), 0)
    task.wait(0.01)
    cam.CFrame = startCFrame
    isFlicking = false
end

SpidiButton.MouseButton1Click:Connect(function()
    if tick() - lastFlickTime > 0.05 then
        lastFlickTime = tick()
        performVideoFlick()
    end
end)

local dragging = false
local dragStart = nil
local startPos = nil
local activeInput = nil

SpidiButton.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not dragging then
        dragging = true
        activeInput = input
        dragStart = input.Position
        startPos = SpidiButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == activeInput then
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        local viewportSize = cam.ViewportSize
        newX = math.clamp(newX, 0, viewportSize.X - 70)
        newY = math.clamp(newY, 0, viewportSize.Y - 70)
        SpidiButton.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == activeInput then
        dragging = false
        activeInput = nil
    end
end)

local isItemSpamActive = false
local spamLoop = nil

local function toggleItemSpam(v)
    isItemSpamActive = v
    if isItemSpamActive then
        if not spamLoop then
            spamLoop = RunService.RenderStepped:Connect(function()
                if isItemSpamActive then
                    local char = player.Character
                    local backpack = player:FindFirstChild("Backpack")
                    if char and backpack then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        local currentTool = char:FindFirstChildOfClass("Tool")
                        if currentTool then
                            humanoid:UnequipTools()
                        else
                            local toolInBackpack = backpack:FindFirstChildOfClass("Tool")
                            if toolInBackpack then
                                humanoid:EquipTool(toolInBackpack)
                            end
                        end
                    end
                end
            end)
        end
    else
        if spamLoop then
            spamLoop:Disconnect()
            spamLoop = nil
        end
    end
end

local isGGSignActive = false
local DISTANCIA_DETECCAO = 5
local VELOCIDADE_GIRO = 65
local FORCA_MOVIMENTO = 50
local FORCA_TETO = 35
local anguloGiro = 0

RunService.RenderStepped:Connect(function()
    if not isGGSignActive then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local tool = char:FindFirstChildOfClass("Tool")
    local rayParam = RaycastParams.new()
    rayParam.FilterType = Enum.RaycastFilterType.Exclude
    rayParam.FilterDescendantsInstances = {char}
    local ray = workspace:Raycast(root.Position, Vector3.new(0, DISTANCIA_DETECCAO, 0), rayParam)
    if tool and ray then
        root.Velocity = Vector3.new(root.Velocity.X, FORCA_TETO, root.Velocity.Z)
        if hum.MoveDirection.Magnitude > 0 then
            local moveDir = hum.MoveDirection
            root.Velocity = Vector3.new(moveDir.X * FORCA_MOVIMENTO, FORCA_TETO, moveDir.Z * FORCA_MOVIMENTO)
        end
        anguloGiro = anguloGiro + VELOCIDADE_GIRO
        local yaw = math.rad(root.Orientation.Y)
        local cameraRot = CFrame.Angles(0, yaw, 0)
        root.CFrame = CFrame.new(root.Position) * cameraRot * CFrame.Angles(math.rad(90), 0, math.rad(anguloGiro))
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    else
        if hum:GetState() == Enum.HumanoidStateType.Physics then
            anguloGiro = 0
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local speed = hrp.AssemblyLinearVelocity.Magnitude
            speedLabel.Text = string.format("Speed: %.1f", speed)
        end
    else
        speedLabel.Text = "Speed: 0"
    end
end)

local ejecutando = false
local currentTweens = {}
local noclipConexion = nil

local OFFSETS = {
    ["Forward150"] = Vector3.new(0, 0, -150),
    ["Down"]       = Vector3.new(0, -200, 0),
    ["Up"]         = Vector3.new(0, 200, 0),
    ["Left"]       = Vector3.new(-30, 0, 0),
    ["Right"]      = Vector3.new(30, 0, 0)
}

local function getRootAttachment(character)
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local att = hrp:FindFirstChild("RootRigAttachment") or hrp:FindFirstChild("RootAttachment")
    if not att then
        att = Instance.new("Attachment")
        att.Name = "RootRigAttachment"
        att.Parent = hrp
    end
    return att
end

local function restaurar(character)
    if noclipConexion then
        noclipConexion:Disconnect()
        noclipConexion = nil
    end
    for _, tw in ipairs(currentTweens) do tw:Cancel() end
    table.clear(currentTweens)
    if character then
        local rootAttachment = getRootAttachment(character)
        if rootAttachment then rootAttachment.Position = Vector3.zero end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
            end
        end
    end
    ejecutando = false
end

local function playProjection(offsetVector, timeIda, timeVuelta, enableNoclip, isFling)
    local character = player.Character
    if not character or ejecutando then return end
    local rootAttachment = getRootAttachment(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not rootAttachment or not humanoid or not hrp then return end
    ejecutando = true
    local originalPos = rootAttachment.Position
    if isFling then
        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "FlingVelocity"
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(0, 99999, 0)
        bav.Parent = hrp
        task.wait(1.5)
        if hrp:FindFirstChild("FlingVelocity") then hrp.FlingVelocity:Destroy() end
        restaurar(character)
        return
    end
    if enableNoclip then
        noclipConexion = RunService.Stepped:Connect(function()
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    local targetPos = originalPos + offsetVector
    local tweenIr = TweenService:Create(rootAttachment, TweenInfo.new(timeIda or 1.5, Enum.EasingStyle.Linear), {Position = targetPos})
    local tweenVolver = TweenService:Create(rootAttachment, TweenInfo.new(timeVuelta or 1.5, Enum.EasingStyle.Linear), {Position = originalPos})
    table.insert(currentTweens, tweenIr)
    table.insert(currentTweens, tweenVolver)
    tweenIr:Play()
    tweenIr.Completed:Wait()
    if ejecutando then
        tweenVolver:Play()
        tweenVolver.Completed:Wait()
        restaurar(character)
    end
end

local function playInvisible()
    local character = player.Character
    if not character then return end
    restaurar(character)
    ejecutando = true
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end
    noclipConexion = RunService.Stepped:Connect(function()
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

player.Chatted:Connect(function(msg)
    local cleanMsg = string.lower(msg)
    if cleanMsg == "/e tp" or cleanMsg == "tp" or cleanMsg == "/e goto" or cleanMsg == "goto" then
        task.spawn(runOmegaTeleportGlitch)
    elseif cleanMsg == "/e laugh" or cleanMsg == "laugh" then
        task.spawn(function() playProjection(OFFSETS["Forward150"], 5, 2, true) end)
    elseif cleanMsg == "/e wave" or cleanMsg == "wave" then
        task.spawn(function() playProjection(OFFSETS["Up"], 2, 2, false) end)
    elseif cleanMsg == "/e dance" or cleanMsg == "dance" then
        task.spawn(function() playProjection(OFFSETS["Right"], 1.5, 1.5, false) end)
    elseif cleanMsg == "/e dance2" or cleanMsg == "dance2" then
        task.spawn(function() playProjection(OFFSETS["Left"], 1.5, 1.5, false) end)
    elseif cleanMsg == "/e dance3" or cleanMsg == "dance3" then
        task.spawn(function() playProjection(OFFSETS["Up"], 2, 2, false) end)
    elseif cleanMsg == "/e point" or cleanMsg == "point" then
        task.spawn(function() playProjection(OFFSETS["Down"], 2, 2, false) end)
    elseif cleanMsg == "/e point2" or cleanMsg == "point2" then
        task.spawn(function() playProjection(Vector3.new(0, 0, -150), 1.5, 1.5, true) end)
    elseif cleanMsg == "/e hello" or cleanMsg == "hello" then
        task.spawn(function() playProjection(Vector3.new(0, -80, 0), 1.5, 1.5, true) end)
    elseif cleanMsg == "/e hello2" or cleanMsg == "hello2" then
        task.spawn(function() playProjection(Vector3.new(0, 80, 0), 1.5, 1.5, true) end)
    elseif cleanMsg == "/e moonwalk" or cleanMsg == "moonwalk" then
        task.spawn(function() playProjection(Vector3.new(0, 0, 50), 3, 1.5, true) end)
    elseif cleanMsg == "/e babyqueen" or cleanMsg == "babyqueen" then
        task.spawn(function() playProjection(Vector3.new(0, 80, -80), 2, 2, true) end)
    elseif cleanMsg == "/e flingback" or cleanMsg == "flingback" then
        task.spawn(function() playProjection(nil, nil, nil, false, true) end)
    elseif cleanMsg == "/e invisible" or cleanMsg == "invis" then
        task.spawn(playInvisible)
    end
end)

-- ============================================================
-- CHINA HAT INTEGRATION
-- ============================================================

getgenv().ChinaHatSettings = {
    enabled = false, 
    hatColor = Color3.fromRGB(255, 105, 180), 
    lightColor = Color3.fromRGB(255, 105, 180), 
    lightBrightness = 2, 
    lightRange = 12, 
    scale = Vector3.new(1.7, 1.1, 1.7), 
}

local function CreateHat(Character)
    local Head = Character:FindFirstChild("Head")
    if not Head then return end 
    local existing = Character:FindFirstChild("ChinaHatPart")
    if existing then existing:Destroy() end
    local Cone = Instance.new("Part")
    Cone.Name = "ChinaHatPart"
    Cone.Size = Vector3.new(1, 1, 1)
    Cone.Material = Enum.Material.Neon
    Cone.Transparency = 0.2
    Cone.Anchored = false
    Cone.CanCollide = false
    Cone.Color = getgenv().ChinaHatSettings.hatColor 
    local Mesh = Instance.new("SpecialMesh")
    Mesh.MeshType = Enum.MeshType.FileMesh
    Mesh.MeshId = "rbxassetid://1033714"
    Mesh.Scale = getgenv().ChinaHatSettings.scale 
    Mesh.Parent = Cone
    local Weld = Instance.new("Weld")
    Weld.Part0 = Head
    Weld.Part1 = Cone
    Weld.C0 = CFrame.new(0, 0.9, 0)
    Weld.Parent = Cone
    local Light = Instance.new("PointLight")
    Light.Name = "ChinaHatLight"
    Light.Color = getgenv().ChinaHatSettings.lightColor 
    Light.Brightness = getgenv().ChinaHatSettings.lightBrightness 
    Light.Range = getgenv().ChinaHatSettings.lightRange 
    Light.Shadows = true
    Light.Parent = Cone
    Cone.Parent = Character
end

local function RemoveHat(Character)
    if not Character then return end
    local existing = Character:FindFirstChild("ChinaHatPart")
    if existing then existing:Destroy() end
end

local function UpdateHatColors()
    if player.Character then
        local hat = player.Character:FindFirstChild("ChinaHatPart")
        if hat then
            hat.Color = getgenv().ChinaHatSettings.hatColor
            local light = hat:FindFirstChild("ChinaHatLight")
            if light then
                light.Color = getgenv().ChinaHatSettings.lightColor
            end
        end
    end
end

local function OnCharacterAdded(Character)
    if getgenv().ChinaHatSettings.enabled then
        Character:WaitForChild("Head")
        CreateHat(Character)
    end
end

player.CharacterAdded:Connect(OnCharacterAdded)

ChinaHatSec:AddLabel('China Hat'):AddToggle({
    Default = false,
    Callback = function(v)
        getgenv().ChinaHatSettings.enabled = v
        if v then
            if player.Character then
                CreateHat(player.Character)
            end
        else
            if player.Character then
                RemoveHat(player.Character)
            end
        end
    end
})

ChinaHatSec:AddLabel('Hat Color'):AddColorPicker({
    Default = Color3.fromRGB(255, 105, 180),
    Callback = function(color)
        getgenv().ChinaHatSettings.hatColor = color
        UpdateHatColors()
    end
})

ChinaHatSec:AddLabel('Light Color'):AddColorPicker({
    Default = Color3.fromRGB(255, 105, 180),
    Callback = function(color)
        getgenv().ChinaHatSettings.lightColor = color
        UpdateHatColors()
    end
})

-- ============================================================
-- TRAIL INTEGRATION
-- ============================================================

getgenv().TrailSettings = {
    enabled = false,
    color = Color3.fromRGB(0, 255, 255),
    lifetime = 0.5,
    startTransparency = 0
}

local activeTrail, trailConn = nil, nil

local function RemoveTrail(char)
    if activeTrail then activeTrail:Destroy() activeTrail = nil end
    if trailConn then trailConn:Disconnect() trailConn = nil end
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _,v in ipairs(hrp:GetChildren()) do
            if v.Name == "TrailA0" or v.Name == "TrailA1" then
                v:Destroy()
            end
        end
    end
end

local function AddTrail(char)
    RemoveTrail(char)
    if not getgenv().TrailSettings.enabled then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local a0 = Instance.new("Attachment", hrp)
    a0.Name = "TrailA0"
    a0.Position = Vector3.new(0, 2, 0)
    local a1 = Instance.new("Attachment", hrp)
    a1.Name = "TrailA1"
    a1.Position = Vector3.new(0, -2, 0)
    activeTrail = Instance.new("Trail")
    activeTrail.Attachment0 = a0
    activeTrail.Attachment1 = a1
    activeTrail.Lifetime = getgenv().TrailSettings.lifetime
    activeTrail.Color = ColorSequence.new(getgenv().TrailSettings.color)
    activeTrail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, getgenv().TrailSettings.startTransparency),
        NumberSequenceKeypoint.new(1, 1)
    }
    activeTrail.Parent = char
end

player.CharacterAdded:Connect(function(char)
    if getgenv().TrailSettings.enabled then
        task.defer(function() AddTrail(char) end)
    end
end)

TrailSec:AddLabel('Character Trail'):AddToggle({
    Default = false,
    Callback = function(v)
        getgenv().TrailSettings.enabled = v
        if v then
            if player.Character then
                AddTrail(player.Character)
            end
        else
            if player.Character then
                RemoveTrail(player.Character)
            end
        end
    end
})

TrailSec:AddLabel('Trail Color'):AddColorPicker({
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(color)
        getgenv().TrailSettings.color = color
        if activeTrail then
            activeTrail.Color = ColorSequence.new(color)
        end
    end
})

-- ============================================================
-- FPS BOOST INTEGRATION
-- ============================================================

local function applyFpsBoost(v)
    if v then
        pcall(function()
            GameSettings.SavedQualityLevel = Enum.SavedQualityLevel.Level1
        end)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 0.5
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end
        end
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        Lighting.Technology = Enum.Technology.Compatibility
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") or child:IsA("Sky") then
                child:Destroy()
            end
        end
        local graySky = Instance.new("Sky")
        graySky.Name = "FPSBoost_PureGraySky"
        local solidGrayAsset = "rbxassetid://600830720"
        graySky.SkyboxBk = solidGrayAsset
        graySky.SkyboxDn = solidGrayAsset
        graySky.SkyboxFt = solidGrayAsset
        graySky.SkyboxLf = solidGrayAsset
        graySky.SkyboxRt = solidGrayAsset
        graySky.SkyboxUp = solidGrayAsset
        graySky.Color = Color3.fromRGB(110, 110, 110)
        graySky.Parent = Lighting
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveTransparency = 1
            Terrain.WaterReflectance = 0
            pcall(function()
                sethiddenproperty(Terrain, "Decoration", false)
            end)
        end
    end
end

FpsBoostSec:AddLabel('FPS Boost & Gray Sky'):AddToggle({
    Default = false,
    Callback = function(v)
        applyFpsBoost(v)
    end
})

-- ============================================================
-- PSHADE LITE SHADERS
-- ============================================================

local liteShaders = {
    ['morninglite'] = {
        ClockTime = 6.5, Brightness = 2,
        Ambient = Color3.fromRGB(210, 215, 230),
        OutdoorAmbient = Color3.fromRGB(190, 200, 220),
        ColorShift_Bottom = Color3.fromRGB(20, 20, 30),
        ColorShift_Top = Color3.fromRGB(255, 230, 200),
        ExposureCompensation = 0.1,
        CorBrightness = 0, CorContrast = 0.1, CorSaturation = 0.05,
        TintColor = Color3.fromRGB(255, 245, 235),
        BloomIntensity = 0.2, BloomSize = 20, BloomThreshold = 1.5
    },
    ['middaylite'] = {
        ClockTime = 14.0, Brightness = 2.5,
        Ambient = Color3.fromRGB(240, 240, 245),
        OutdoorAmbient = Color3.fromRGB(230, 230, 240),
        ColorShift_Bottom = Color3.fromRGB(40, 40, 40),
        ColorShift_Top = Color3.fromRGB(255, 255, 250),
        ExposureCompensation = 0.2,
        CorBrightness = 0.05, CorContrast = 0.15, CorSaturation = 0.1,
        TintColor = Color3.fromRGB(255, 255, 255),
        BloomIntensity = 0.15, BloomSize = 15, BloomThreshold = 2.0
    },
    ['afternoonlite'] = {
        ClockTime = 17.5, Brightness = 2.1,
        Ambient = Color3.fromRGB(235, 215, 195),
        OutdoorAmbient = Color3.fromRGB(220, 195, 175),
        ColorShift_Bottom = Color3.fromRGB(30, 20, 20),
        ColorShift_Top = Color3.fromRGB(255, 200, 150),
        ExposureCompensation = 0.15,
        CorBrightness = 0, CorContrast = 0.2, CorSaturation = 0.15,
        TintColor = Color3.fromRGB(255, 240, 220),
        BloomIntensity = 0.25, BloomSize = 24, BloomThreshold = 1.2
    },
    ['eveninglite'] = {
        ClockTime = 19.2, Brightness = 1.5,
        Ambient = Color3.fromRGB(150, 130, 160),
        OutdoorAmbient = Color3.fromRGB(120, 100, 140),
        ColorShift_Bottom = Color3.fromRGB(20, 10, 30),
        ColorShift_Top = Color3.fromRGB(200, 150, 200),
        ExposureCompensation = -0.1,
        CorBrightness = -0.05, CorContrast = 0.25, CorSaturation = 0.1,
        TintColor = Color3.fromRGB(240, 220, 255),
        BloomIntensity = 0.3, BloomSize = 30, BloomThreshold = 1.0
    },
    ['nightlite'] = {
        ClockTime = 0.0, Brightness = 0.8,
        Ambient = Color3.fromRGB(40, 45, 60),
        OutdoorAmbient = Color3.fromRGB(25, 30, 45),
        ColorShift_Bottom = Color3.fromRGB(10, 10, 20),
        ColorShift_Top = Color3.fromRGB(50, 70, 100),
        ExposureCompensation = -0.3,
        CorBrightness = -0.1, CorContrast = 0.3, CorSaturation = -0.05,
        TintColor = Color3.fromRGB(200, 220, 255),
        BloomIntensity = 0.4, BloomSize = 40, BloomThreshold = 0.8
    },
    ['midnightlite'] = {
        ClockTime = 1.5, Brightness = 0.5,
        Ambient = Color3.fromRGB(20, 25, 35),
        OutdoorAmbient = Color3.fromRGB(15, 18, 25),
        ColorShift_Bottom = Color3.fromRGB(5, 5, 10),
        ColorShift_Top = Color3.fromRGB(30, 40, 60),
        ExposureCompensation = -0.5,
        CorBrightness = -0.15, CorContrast = 0.35, CorSaturation = -0.1,
        TintColor = Color3.fromRGB(180, 200, 255),
        BloomIntensity = 0.3, BloomSize = 35, BloomThreshold = 0.9
    }
}

local function getEffect(className)
    local eff = Lighting:FindFirstChildOfClass(className)
    if not eff then
        eff = Instance.new(className)
        eff.Parent = Lighting
    end
    eff.Enabled = true
    return eff
end

local colorcor = getEffect("ColorCorrectionEffect")
local bloom = getEffect("BloomEffect")

local activeShaderName = nil

local function applyShaderData(data)
    if not data then return end
    Lighting.ClockTime = data.ClockTime
    Lighting.Brightness = data.Brightness
    Lighting.Ambient = data.Ambient
    Lighting.OutdoorAmbient = data.OutdoorAmbient
    Lighting.ColorShift_Bottom = data.ColorShift_Bottom
    Lighting.ColorShift_Top = data.ColorShift_Top
    Lighting.ExposureCompensation = data.ExposureCompensation
    colorcor.Brightness = data.CorBrightness
    colorcor.Contrast = data.CorContrast
    colorcor.Saturation = data.CorSaturation
    colorcor.TintColor = data.TintColor
    bloom.Intensity = data.BloomIntensity
    bloom.Size = data.BloomSize
    bloom.Threshold = data.BloomThreshold
end

RunService.PreRender:Connect(function()
    if activeShaderName and liteShaders[activeShaderName] then
        applyShaderData(liteShaders[activeShaderName])
    end
end)

for name, _ in pairs(liteShaders) do
    ShaderSec:AddButton({
        Name = name:gsub("^%l", string.upper),
        Callback = function()
            activeShaderName = name
        end
    })
end

ShaderSec:AddButton({
    Name = "Reset Shader",
    Callback = function()
        activeShaderName = nil
        Lighting.ClockTime = 14.0
        Lighting.Brightness = 2.0
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.ExposureCompensation = 0
        Lighting.GlobalShadows = true
        colorcor.Enabled = false
        colorcor.Brightness = 0
        colorcor.Contrast = 0
        colorcor.Saturation = 0
        colorcor.TintColor = Color3.fromRGB(255, 255, 255)
        bloom.Enabled = false
        bloom.Intensity = 0
    end
})

-- ============================================================
-- UI ELEMENTS - LEGIT BOT (Neyrone)
-- ============================================================

if ClientData.HasHookmetamethod then
    LegitSec:AddLabel('Bullet Redirection'):AddToggle({
        Default = State.Legit.SilentAim,
        Callback = function(v) State.Legit.SilentAim = v end
    })
    LegitSec:AddLabel('Hit Chance'):AddSlider({
        Default = State.Legit.HitChance, Min = 0, Max = 100,
        Callback = function(v) State.Legit.HitChance = v end
    })
else
    LegitSec:AddLabel('Bullet Redirection: Unsupported')
end

LegitSec:AddLabel('Aim Assist'):AddToggle({
    Default = State.Legit.Aimbot,
    Callback = function(v) State.Legit.Aimbot = v end
})
LegitSec:AddLabel('Speed'):AddSlider({
    Default = State.Legit.AimbotSpeed, Min = 0, Max = 100,
    Callback = function(v) State.Legit.AimbotSpeed = v end
})
LegitSec:AddLabel('Aim Type'):AddDropdown({
    Default = State.Legit.AimbotType, Values = {"Mouse Movement", "Lerp", "Stick"},
    Callback = function(v) State.Legit.AimbotType = v end
})
LegitSec:AddLabel('Speed Type'):AddDropdown({
    Default = State.Legit.AimbotSpeedType, Values = {"Linear", "Exponential"},
    Callback = function(v) State.Legit.AimbotSpeedType = v end
})
LegitSec:AddLabel('Activation'):AddDropdown({
    Default = State.Legit.AimbotActivate, Values = {"Mouse 1", "Mouse 2"},
    Callback = function(v) State.Legit.AimbotActivate = v end
})

LegitSec:AddLabel('Trigger Bot'):AddToggle({
    Default = State.Legit.Triggerbot,
    Callback = function(v) State.Legit.Triggerbot = v end
})
LegitSec:AddLabel('Delay'):AddSlider({
    Default = State.Legit.TriggerbotDelay, Min = 0, Max = 200,
    Callback = function(v) State.Legit.TriggerbotDelay = v end
})

LegitSetSec:AddLabel('Use FOV'):AddToggle({
    Default = State.Legit.Fov,
    Callback = function(v) State.Legit.Fov = v end
})
LegitSetSec:AddLabel('Visible FOV'):AddToggle({
    Default = State.Legit.FovVisible,
    Callback = function(v) State.Legit.FovVisible = v end
})
LegitSetSec:AddLabel('FOV Circle Color'):AddColorPicker({
    Default = State.Legit.FovColor,
    Callback = function(v) State.Legit.FovColor = v end
})
LegitSetSec:AddLabel('FOV'):AddSlider({
    Default = State.Legit.FovValue, Min = 0, Max = 80,
    Callback = function(v) State.Legit.FovValue = v end
})
LegitSetSec:AddLabel('FOV Num Sides'):AddSlider({
    Default = State.Legit.FovNumSides, Min = 0, Max = 100,
    Callback = function(v) State.Legit.FovNumSides = v end
})
LegitSetSec:AddLabel('Hitscan'):AddDropdown({
    Default = State.Legit.Hitscan, Values = {"Head", "Torso"},
    Callback = function(v) State.Legit.Hitscan = v end
})

-- ============================================================
-- UI ELEMENTS - RAGE BOT (Neyrone)
-- ============================================================

RageSec:AddLabel('Enabled'):AddToggle({
    Default = State.Rage.Ragebot,
    Callback = function(v) State.Rage.Ragebot = v end
})
RageSec:AddLabel('Silent Aim'):AddToggle({
    Default = State.Rage.SilentAim,
    Callback = function(v) State.Rage.SilentAim = v end
})
if ClientData.HasRequire and GameData.Shucky and GameData.Shucky.shootsound and GameData.Ambassador and GameData.Ambassador.Fire then
    RageSec:AddLabel('Simulate Shoot'):AddToggle({
        Default = State.Rage.SimulateShoot,
        Callback = function(v) State.Rage.SimulateShoot = v end
    })
else
    RageSec:AddLabel('Simulate Shoot: Unsupported')
end
RageSec:AddLabel('Auto Wall'):AddToggle({
    Default = State.Rage.AutoWall,
    Callback = function(v) State.Rage.AutoWall = v end
})
RageSec:AddLabel('Force Full Damage'):AddToggle({
    Default = State.Rage.ForceDamage,
    Callback = function(v) State.Rage.ForceDamage = v end
})
RageSec:AddLabel('Minimum Damage'):AddSlider({
    Default = State.Rage.MinDamage, Min = 1, Max = 115,
    Callback = function(v) State.Rage.MinDamage = v end
})
RageSec:AddLabel('Hitscan'):AddDropdown({
    Default = State.Rage.Hitscan[1], Values = {"Head", "Torso", "Arms", "Legs"}, Multi = true,
    Callback = function(v) State.Rage.Hitscan = v end
})

RageMiscSec:AddLabel('Debug'):AddToggle({
    Default = State.Rage.Debug,
    Callback = function(v) State.Rage.Debug = v end
})
RageMiscSec:AddLabel('Use FOV'):AddToggle({
    Default = State.Rage.Fov,
    Callback = function(v) State.Rage.Fov = v end
})
RageMiscSec:AddLabel('Visible FOV'):AddToggle({
    Default = State.Rage.FovVisible,
    Callback = function(v) State.Rage.FovVisible = v end
})
RageMiscSec:AddLabel('FOV Circle Color'):AddColorPicker({
    Default = State.Rage.FovColor,
    Callback = function(v) State.Rage.FovColor = v end
})
RageMiscSec:AddLabel('FOV'):AddSlider({
    Default = State.Rage.FovValue, Min = 0, Max = 80,
    Callback = function(v) State.Rage.FovValue = v end
})
RageMiscSec:AddLabel('FOV Num Sides'):AddSlider({
    Default = State.Rage.FovNumSides, Min = 0, Max = 100,
    Callback = function(v) State.Rage.FovNumSides = v end
})
RageMiscSec:AddLabel('Rapid Fire'):AddToggle({
    Default = State.Rage.RapidFire,
    Callback = function(v) State.Rage.RapidFire = v end
})
RageMiscSec:AddLabel('Force Headshot'):AddToggle({
    Default = State.Rage.ForceHead,
    Callback = function(v) State.Rage.ForceHead = v end
})
RageMiscSec:AddLabel('Double Tap'):AddToggle({
    Default = State.Rage.DoubleTap,
    Callback = function(v) State.Rage.DoubleTap = v end
})
RageMiscSec:AddLabel('Allow Throwables'):AddToggle({
    Default = State.Rage.Throwables,
    Callback = function(v) State.Rage.Throwables = v end
})
RageMiscSec:AddLabel('Noscope Icon'):AddToggle({
    Default = State.Rage.Noscope,
    Callback = function(v) State.Rage.Noscope = v end
})
RageMiscSec:AddLabel('Backstab Icon'):AddToggle({
    Default = State.Rage.Backstab,
    Callback = function(v) State.Rage.Backstab = v end
})

KnifeBotSec:AddLabel('Enabled'):AddToggle({
    Default = State.Rage.Knifebot,
    Callback = function(v) State.Rage.Knifebot = v end
})
if ClientData.HasRequire and GameData.Shucky and GameData.Shucky.shootsound and GameData.Ambassador and GameData.Ambassador.Fire then
    KnifeBotSec:AddLabel('Simulate Stab'):AddToggle({
        Default = State.Rage.SimulateStab,
        Callback = function(v) State.Rage.SimulateStab = v end
    })
else
    KnifeBotSec:AddLabel('Simulate Stab: Unsupported')
end
KnifeBotSec:AddLabel('Wall Check'):AddToggle({
    Default = State.Rage.KnifeWallCheck,
    Callback = function(v) State.Rage.KnifeWallCheck = v end
})
KnifeBotSec:AddLabel('Radius'):AddSlider({
    Default = State.Rage.KnifeRadius, Min = 0, Max = 7,
    Callback = function(v) State.Rage.KnifeRadius = v end
})

AntiAimSec:AddLabel('Enabled'):AddToggle({
    Default = State.Rage.AntiAim,
    Callback = function(v) State.Rage.AntiAim = v end
})
if ClientData.HasRequire and GameData.Ambassador and GameData.Ambassador.Fire then
    AntiAimSec:AddLabel('Fake Duck'):AddToggle({
        Default = State.Rage.FakeDuck,
        Callback = function(v) State.Rage.FakeDuck = v end
    })
else
    AntiAimSec:AddLabel('Fake Duck: Unsupported')
end
AntiAimSec:AddLabel('Yaw Base'):AddDropdown({
    Default = State.Rage.YawBase, Values = {"Camera", "Spin", "Random"},
    Callback = function(v) State.Rage.YawBase = v end
})
if ClientData.HasRequire and GameData.Network and GameData.Network.FireServer then
    AntiAimSec:AddLabel('Pitch Base'):AddDropdown({
        Default = State.Rage.PitchBase, Values = {"Custom", "Random"},
        Callback = function(v) State.Rage.PitchBase = v end
    })
else
    AntiAimSec:AddLabel('Pitch Base: Unsupported')
end
AntiAimSec:AddLabel('Spin Speed'):AddSlider({
    Default = State.Rage.SpinSpeed, Min = 0, Max = 48,
    Callback = function(v) State.Rage.SpinSpeed = v end
})
AntiAimSec:AddLabel('Custom Yaw'):AddSlider({
    Default = State.Rage.CustomYaw, Min = -180, Max = 180,
    Callback = function(v) State.Rage.CustomYaw = v end
})
AntiAimSec:AddLabel('Custom Pitch'):AddSlider({
    Default = State.Rage.CustomPitch, Min = -100, Max = 100,
    Callback = function(v) State.Rage.CustomPitch = v end
})

-- ============================================================
-- UI ELEMENTS - AIMBOT (SeraphiCA)
-- ============================================================

AimBotSec:AddLabel('Enable Aim'):AddToggle({
    Default = State.AimBot.Enabled,
    Callback = function(v)
        State.AimBot.Enabled = v
        if v and State.AimBot.SilentEnabled then
            State.AimBot.SilentEnabled = false
        end
        updateFov()
    end
})

AimBotSec:AddLabel('FOV'):AddSlider({
    Default = State.AimBot.FOV,
    Min = 30, Max = 360,
    Callback = function(v) 
        State.AimBot.FOV = v
        updateFov()
    end
})

AimBotSec:AddLabel('Show FOV'):AddToggle({
    Default = State.AimBot.ShowFov,
    Callback = function(v) 
        State.AimBot.ShowFov = v
        updateFov()
    end
})

AimBotSec:AddLabel('Visible Check'):AddToggle({
    Default = State.AimBot.VisibleCheck,
    Callback = function(v) State.AimBot.VisibleCheck = v end
})

AimBotSec:AddLabel('Target Mode'):AddDropdown({
    Default = State.AimBot.Target,
    Values = {"Closest", "Nearest to center", "Lowest distance"},
    Callback = function(v) State.AimBot.Target = v end
})

SilentAimSec:AddLabel('Silent Aim'):AddToggle({
    Default = State.AimBot.SilentEnabled,
    Callback = function(v)
        State.AimBot.SilentEnabled = v
        if v and State.AimBot.Enabled then
            State.AimBot.Enabled = false
        end
        updateFov()
    end
})

SilentAimSec:AddLabel('Silent FOV'):AddSlider({
    Default = State.AimBot.SilentFOV,
    Min = 10, Max = 360,
    Callback = function(v) 
        State.AimBot.SilentFOV = v
        updateFov()
    end
})

SilentAimSec:AddLabel('Show Silent FOV'):AddToggle({
    Default = State.AimBot.SilentShowFov,
    Callback = function(v) 
        State.AimBot.SilentShowFov = v
        updateFov()
    end
})

SilentAimSec:AddLabel('Silent Wall Check'):AddToggle({
    Default = State.AimBot.SilentWallCheck,
    Callback = function(v) State.AimBot.SilentWallCheck = v end
})

-- ============================================================
-- UI ELEMENTS - VISUALS (SeraphiCA + Neyrone)
-- ============================================================

EspSec:AddLabel('ESP'):AddToggle({
    Default = State.Visuals.ESP,
    Callback = function(v) State.Visuals.ESP = v end
})

EspSec:AddLabel('Box'):AddToggle({
    Default = State.Visuals.Boxes,
    Callback = function(v) State.Visuals.Boxes = v end
})

EspSec:AddLabel('Box Color'):AddColorPicker({
    Default = State.Visuals.BoxColor,
    Callback = function(v) State.Visuals.BoxColor = v end
})

EspSec:AddLabel('Health'):AddToggle({
    Default = State.Visuals.Health,
    Callback = function(v) State.Visuals.Health = v end
})

EspSec:AddLabel('Health Color'):AddColorPicker({
    Default = State.Visuals.HealthColor,
    Callback = function(v) State.Visuals.HealthColor = v end
})

EspSec:AddLabel('Names'):AddToggle({
    Default = State.Visuals.Names,
    Callback = function(v) State.Visuals.Names = v end
})

EspSec:AddLabel('Name Color'):AddColorPicker({
    Default = State.Visuals.NameColor,
    Callback = function(v) State.Visuals.NameColor = v end
})

EspSec:AddLabel('Distance'):AddToggle({
    Default = State.Visuals.Distance,
    Callback = function(v) State.Visuals.Distance = v end
})

EspSec:AddLabel('Distance Color'):AddColorPicker({
    Default = State.Visuals.DistanceColor,
    Callback = function(v) State.Visuals.DistanceColor = v end
})

EspSec:AddLabel('Chams'):AddToggle({
    Default = State.Visuals.Chams,
    Callback = function(v) State.Visuals.Chams = v end
})

WorldSec:AddLabel('ColorWorld'):AddToggle({
    Default = State.Visuals.ColorWorld,
    Callback = function(v)
        State.Visuals.ColorWorld = v
        if v then enableColorWorld() else disableColorWorld() end
    end
})

WorldSec:AddLabel('X-Ray'):AddToggle({
    Default = State.Visuals.XRayEnabled,
    Callback = function(v)
        State.Visuals.XRayEnabled = v
        if v then applyXRay() else restoreXRay() end
    end
})

WorldSec:AddLabel('X-Ray Transparency'):AddSlider({
    Default = State.Visuals.XRayTransparency,
    Min = 0, Max = 100,
    Callback = function(v)
        State.Visuals.XRayTransparency = v
        if State.Visuals.XRayEnabled then
            local trans = v / 100
            for obj, _ in pairs(xrayParts) do
                if obj and obj.Parent then obj.Transparency = trans end
            end
        end
    end
})

TacticalSec:AddLabel('Spectator List'):AddToggle({
    Default = State.Visuals.SpectatorList,
    Callback = function(v)
        State.Visuals.SpectatorList = v
        SpectatorWidget.Visible = v
    end
})

TacticalSec:AddLabel('Bomb Calculator'):AddToggle({
    Default = State.Visuals.BombCalculator,
    Callback = function(v)
        State.Visuals.BombCalculator = v
        BombWidget.Visible = v
    end
})

if ClientData.HasHookmetamethod then
    TacticalSec:AddLabel('Bullet Tracers'):AddToggle({
        Default = State.Visuals.BulletTracers,
        Callback = function(v) State.Visuals.BulletTracers = v end
    })
    TacticalSec:AddLabel('Tracer Start Color'):AddColorPicker({
        Default = State.Visuals.TracerStartColor,
        Callback = function(v) State.Visuals.TracerStartColor = v end
    })
    TacticalSec:AddLabel('Tracer End Color'):AddColorPicker({
        Default = State.Visuals.TracerEndColor,
        Callback = function(v) State.Visuals.TracerEndColor = v end
    })
    TacticalSec:AddLabel('Tracer Texture'):AddDropdown({
        Default = State.Visuals.TracerTexture, Values = {"Line", "Neyrone", "Lighting", "Tracer"},
        Callback = function(v) State.Visuals.TracerTexture = v end
    })
    TacticalSec:AddLabel('Tracer Lifetime'):AddSlider({
        Default = State.Visuals.TracerLifetime, Min = 0, Max = 10,
        Callback = function(v) State.Visuals.TracerLifetime = v end
    })
    TacticalSec:AddLabel('Hit Impacts'):AddToggle({
        Default = State.Visuals.HitImpacts,
        Callback = function(v) State.Visuals.HitImpacts = v end
    })
    TacticalSec:AddLabel('Hit Impact Color'):AddColorPicker({
        Default = State.Visuals.HitImpactColor,
        Callback = function(v) State.Visuals.HitImpactColor = v end
    })
    TacticalSec:AddLabel('Hit Impact Lifetime'):AddSlider({
        Default = State.Visuals.HitImpactLifetime, Min = 0, Max = 10,
        Callback = function(v) State.Visuals.HitImpactLifetime = v end
    })
else
    TacticalSec:AddLabel('Bullet Tracers: Unsupported')
    TacticalSec:AddLabel('Hit Impacts: Unsupported')
end

ViewmodelSec:AddLabel('Viewmodel Offset'):AddToggle({
    Default = State.Visuals.ViewmodelOffset,
    Callback = function(v) State.Visuals.ViewmodelOffset = v end
})
ViewmodelSec:AddLabel('Offset X'):AddSlider({
    Default = State.Visuals.ViewmodelX, Min = -180, Max = 180,
    Callback = function(v) State.Visuals.ViewmodelX = v end
})
ViewmodelSec:AddLabel('Offset Y'):AddSlider({
    Default = State.Visuals.ViewmodelY, Min = -180, Max = 180,
    Callback = function(v) State.Visuals.ViewmodelY = v end
})
ViewmodelSec:AddLabel('Offset Z'):AddSlider({
    Default = State.Visuals.ViewmodelZ, Min = -180, Max = 180,
    Callback = function(v) State.Visuals.ViewmodelZ = v end
})
ViewmodelSec:AddLabel('Remove Jump Bob'):AddToggle({
    Default = State.Visuals.NoJumpBob,
    Callback = function(v) State.Visuals.NoJumpBob = v end
})
if ClientData.HasHookmetamethod then
    ViewmodelSec:AddLabel('Remove Arms Bob'):AddToggle({
        Default = State.Visuals.NoBob,
        Callback = function(v) State.Visuals.NoBob = v end
    })
    ViewmodelSec:AddLabel('Remove Arms Sway'):AddToggle({
        Default = State.Visuals.NoSway,
        Callback = function(v) State.Visuals.NoSway = v end
    })
else
    ViewmodelSec:AddLabel('Remove Arms Bob: Unsupported')
    ViewmodelSec:AddLabel('Remove Arms Sway: Unsupported')
end

WeaponSec:AddLabel('Weapon Chams'):AddToggle({
    Default = State.Visuals.WeaponChams,
    Callback = function(v) State.Visuals.WeaponChams = v end
})
WeaponSec:AddLabel('Chams Color'):AddColorPicker({
    Default = State.Visuals.WeaponChamsColor,
    Callback = function(v) State.Visuals.WeaponChamsColor = v end
})
WeaponSec:AddLabel('Texture Changer'):AddToggle({
    Default = State.Visuals.WeaponTextureChanger,
    Callback = function(v) State.Visuals.WeaponTextureChanger = v end
})
WeaponSec:AddLabel('Texture'):AddDropdown({
    Default = State.Visuals.WeaponTexture, Values = {"Red + White", "Black + Grey", "Web", "Pink", "Violet", "Lego", "Red + Black", "Dark Blue + Black", "Shark", "Camo", "Lava", "Black + White Leaves", "Red"},
    Callback = function(v) State.Visuals.WeaponTexture = v end
})

SoundSec:AddLabel('Custom Hit Sound'):AddToggle({
    Default = State.Visuals.HitSound,
    Callback = function(v) State.Visuals.HitSound = v end
})
SoundSec:AddLabel('Hit Sound'):AddDropdown({
    Default = State.Visuals.HitSoundName, Values = {"Default Hit Sound", "Bameware", "Bell", "Bubble", "Pick", "Pop", "Rust", "Skeet", "Mario Coin", "COD Hitmarker", "Minecraft XP", "Neverlose", "Fatality"},
    Callback = function(v) State.Visuals.HitSoundName = v end
})
SoundSec:AddLabel('Hit Sound Volume'):AddSlider({
    Default = State.Visuals.HitSoundVolume, Min = 0, Max = 5,
    Callback = function(v) State.Visuals.HitSoundVolume = v end
})
SoundSec:AddLabel('Custom Kill Sound'):AddToggle({
    Default = State.Visuals.KillSound,
    Callback = function(v) State.Visuals.KillSound = v end
})
SoundSec:AddLabel('Kill Sound'):AddDropdown({
    Default = State.Visuals.KillSoundName, Values = {"Default Kill Sound", "Bameware", "Bell", "Bubble", "Pick", "Pop", "Rust", "Skeet", "Mario Coin", "COD Hitmarker", "Minecraft XP", "Neverlose", "Fatality"},
    Callback = function(v) State.Visuals.KillSoundName = v end
})
SoundSec:AddLabel('Kill Sound Volume'):AddSlider({
    Default = State.Visuals.KillSoundVolume, Min = 0, Max = 5,
    Callback = function(v) State.Visuals.KillSoundVolume = v end
})

-- ============================================================
-- UI ELEMENTS - MISC (SeraphiCA + Neyrone)
-- ============================================================

MovementSec:AddLabel('Fly'):AddToggle({
    Default = State.Misc.Fly,
    Callback = function(v)
        State.Misc.Fly = v
        if v then enableFly() else disableFly() end
    end
})

MovementSec:AddLabel('Fly Speed'):AddSlider({
    Default = State.Misc.FlySpeed,
    Min = 10, Max = 300,
    Callback = function(v) State.Misc.FlySpeed = v end
})

MovementSec:AddLabel('BunnyHop'):AddToggle({
    Default = State.Misc.BunnyHop,
    Callback = function(v) State.Misc.BunnyHop = v end
})

MovementSec:AddLabel('Move Before Time'):AddToggle({
    Default = State.Misc.MoveBeforeTime,
    Callback = function(v)
        State.Misc.MoveBeforeTime = v
        if v then enableMoveBeforeTime() else disableMoveBeforeTime() end
    end
})

if ClientData.HasRequire and ClientData.FullRequire and GameData.Variables then
    MovementSec:AddLabel('Bypass Speed Limit'):AddToggle({
        Default = State.Misc.BypassSpeed,
        Callback = function(v) State.Misc.BypassSpeed = v end
    })
else
    MovementSec:AddLabel('Bypass Speed Limit: Unsupported')
end

MovementSec:AddLabel('Automatic Jump'):AddToggle({
    Default = State.Misc.AutoJump,
    Callback = function(v) State.Misc.AutoJump = v end
})
MovementSec:AddLabel('Noclip'):AddToggle({
    Default = State.Misc.Noclip,
    Callback = function(v) State.Misc.Noclip = v end
})
MovementSec:AddLabel('Speed Hack'):AddToggle({
    Default = State.Misc.SpeedHack,
    Callback = function(v) State.Misc.SpeedHack = v end
})
MovementSec:AddLabel('Speed Hack Speed'):AddSlider({
    Default = State.Misc.SpeedHackSpeed, Min = 16, Max = 250,
    Callback = function(v) State.Misc.SpeedHackSpeed = v end
})
MovementSec:AddLabel('Airstuck'):AddToggle({
    Default = State.Misc.Airstuck,
    Callback = function(v) State.Misc.Airstuck = v end
})
MovementSec:AddLabel('Pixelsurf'):AddToggle({
    Default = State.Misc.Pixelsurf,
    Callback = function(v) State.Misc.Pixelsurf = v end
})
MovementSec:AddLabel('Edgebug'):AddToggle({
    Default = State.Misc.Edgebug,
    Callback = function(v) State.Misc.Edgebug = v end
})

ExploitsSec:AddLabel('Kill All'):AddToggle({
    Default = State.Misc.KillAll,
    Callback = function(v) State.Misc.KillAll = v end
})
ExploitsSec:AddLabel('Hit Per Second'):AddSlider({
    Default = State.Misc.KillAllHPS, Min = 1, Max = 10,
    Callback = function(v) State.Misc.KillAllHPS = v end
})
ExploitsSec:AddLabel('Anti Spectate'):AddToggle({
    Default = State.Misc.AntiSpectate,
    Callback = function(v) State.Misc.AntiSpectate = v end
})
ExploitsSec:AddLabel('Type'):AddDropdown({
    Default = State.Misc.AntiSpectateType, Values = {"Low Fov", "Freeze"},
    Callback = function(v) State.Misc.AntiSpectateType = v end
})
ExploitsSec:AddButton({
    Name = 'Flashbang Enemies',
    Callback = function() task.spawn(FlashbangEnemies) end
})

CombatSec:AddLabel('ShotSc (Hitbox Expander)'):AddToggle({
    Default = State.Misc.ShotSc,
    Callback = function(v)
        State.Misc.ShotSc = v
        if not v then disableShotSc() end
    end
})

CombatSec:AddLabel('Fast Reload'):AddToggle({
    Default = State.Misc.FastReload,
    Callback = function(v) State.Misc.FastReload = v end
})

GunModsSec:AddLabel('No Recoil'):AddToggle({
    Default = State.Misc.NoRecoil,
    Callback = function(v) State.Misc.NoRecoil = v task.spawn(applyGunMods) end
})
GunModsSec:AddLabel('No Spread'):AddToggle({
    Default = State.Misc.NoSpread,
    Callback = function(v) State.Misc.NoSpread = v task.spawn(applyGunMods) end
})
GunModsSec:AddLabel('Full Auto'):AddToggle({
    Default = State.Misc.FullAuto,
    Callback = function(v) State.Misc.FullAuto = v task.spawn(applyGunMods) end
})
GunModsSec:AddLabel('Rapid Fire'):AddToggle({
    Default = State.Misc.RapidFire,
    Callback = function(v) State.Misc.RapidFire = v task.spawn(applyGunMods) end
})
GunModsSec:AddLabel('Stored Ammo -> Ammo'):AddToggle({
    Default = State.Misc.ConvertAmmo,
    Callback = function(v) State.Misc.ConvertAmmo = v task.spawn(applyGunMods) end
})
GunModsSec:AddLabel('Infinite Ammo'):AddToggle({
    Default = State.Misc.InfAmmo,
    Callback = function(v) State.Misc.InfAmmo = v task.spawn(applyGunMods) end
})

SafetySec:AddLabel('Bypass Anti-Ban'):AddToggle({
    Default = State.Misc.BypassAntiBan,
    Callback = function(v)
        State.Misc.BypassAntiBan = v
        if v then enableBypassAntiBan() end
    end
})

SafetySec:AddLabel('No-Flash'):AddToggle({
    Default = State.Misc.NoFlash,
    Callback = function(v)
        State.Misc.NoFlash = v
        if v then enableNoFlash() else disableNoFlash() end
    end
})

SafetySec:AddLabel('Anti-Smoke'):AddToggle({
    Default = State.Misc.AntiSmoke,
    Callback = function(v)
        State.Misc.AntiSmoke = v
        if v then enableAntiSmoke() else disableAntiSmoke() end
    end
})

SafetySec:AddLabel('ThirdPerson (CFrame)'):AddToggle({
    Default = State.Misc.ThirdPerson,
    Callback = function(v) State.Misc.ThirdPerson = v end
})

SafetySec:AddLabel('Cam Distance'):AddSlider({
    Default = State.Misc.CamDistance,
    Min = 2, Max = 25,
    Callback = function(v) State.Misc.CamDistance = v end
})

C4Sec:AddLabel('Site'):AddDropdown({
    Default = "A", Values = {"A", "B"},
    Callback = function(v) State.Misc.C4Site = v end
})
C4Sec:AddButton({
    Name = 'Plant C4',
    Callback = function() task.spawn(PlantC4, State.Misc.C4Site) end
})
if ClientData.HasRequire and GameData.Ambassador and GameData.Ambassador.Fire then
    C4Sec:AddButton({
        Name = 'Defuse C4',
        Callback = function() task.spawn(DefuseC4) end
    })
else
    C4Sec:AddLabel('Defuse C4: Unsupported')
end

-- ============================================================
-- UI ELEMENTS - SKINS (Neyrone)
-- ============================================================

if ClientData.HasRequire and GameData.Appearance and GameData.Appearance.MapGunSkin then
    local weaponSkins = GetWeaponSkins()
    for weaponName, skins in pairs(weaponSkins) do
        State.Skins.Weapons[weaponName] = {Enabled = false, Skin = skins[1]}
        local displayName = ""
        if ReplicatedStorage.Weapons:FindFirstChild(weaponName) and ReplicatedStorage.Weapons:FindFirstChild(weaponName):GetAttribute("DisplayName") then
            displayName = ReplicatedStorage.Weapons:FindFirstChild(weaponName):GetAttribute("DisplayName")
        end
        SkinChangerSec:AddLabel(displayName ~= "" and displayName or weaponName):AddToggle({
            Default = false,
            Callback = function(v)
                State.Skins.Weapons[weaponName].Enabled = v
                if v then ApplyWeaponSkin(weaponName, State.Skins.Weapons[weaponName].Skin) end
            end
        })
        SkinChangerSec:AddLabel('Skin'):AddDropdown({
            Default = skins[1], Values = skins,
            Callback = function(v)
                State.Skins.Weapons[weaponName].Skin = v
                if State.Skins.Weapons[weaponName].Enabled then ApplyWeaponSkin(weaponName, v) end
            end
        })
    end
else
    SkinChangerSec:AddLabel('Skin Changer: Unsupported')
end

-- Knife Changer
State.Skins.Knives.Type = GameData.SkinsData.Knives.List[1] or "Knife"
KnifeChangerSec:AddLabel('Enabled'):AddToggle({
    Default = State.Skins.Knives.Enabled,
    Callback = function(v)
        State.Skins.Knives.Enabled = v
        if v then ApplyKnifeSkin() end
    end
})
KnifeChangerSec:AddLabel('Knife'):AddDropdown({
    Default = State.Skins.Knives.Type, Values = GameData.SkinsData.Knives.List,
    Callback = function(v)
        State.Skins.Knives.Type = v
        if State.Skins.Knives.Enabled then ApplyKnifeSkin() end
    end
})

if ClientData.HasRequire and GameData.Appearance and GameData.Appearance.MapGunSkin then
    local knifeSkins = {}
    for _, folder in ipairs(ReplicatedStorage.Skins:GetChildren()) do
        if folder:IsA("Folder") and table.find(GameData.SkinsData.Knives.List, folder.Name) then
            local skins = {}
            for _, skinFolder in ipairs(folder:GetChildren()) do
                if skinFolder:IsA("Folder") then table.insert(skins, skinFolder.Name) end
            end
            if #skins > 0 then knifeSkins[folder.Name] = skins end
        end
    end
    for knifeName, skins in pairs(knifeSkins) do
        State.Skins.Knives.Skins[knifeName] = {Enabled = false, Skin = skins[1]}
        KnifeChangerSec:AddLabel(knifeName):AddToggle({
            Default = false,
            Callback = function(v)
                State.Skins.Knives.Skins[knifeName].Enabled = v
                if v and State.Skins.Knives.Enabled and State.Skins.Knives.Type == knifeName then ApplyKnifeSkin() end
            end
        })
        KnifeChangerSec:AddLabel('Skin'):AddDropdown({
            Default = skins[1], Values = skins,
            Callback = function(v)
                State.Skins.Knives.Skins[knifeName].Skin = v
                if State.Skins.Knives.Skins[knifeName].Enabled and State.Skins.Knives.Enabled and State.Skins.Knives.Type == knifeName then ApplyKnifeSkin() end
            end
        })
    end
else
    KnifeChangerSec:AddLabel('Knife Skin Changer: Unsupported')
end

-- Gloves Changer
State.Skins.Gloves.Type = GameData.SkinsData.Gloves.List[1] or "Glove"
GlovesChangerSec:AddLabel('Enabled'):AddToggle({
    Default = State.Skins.Gloves.Enabled,
    Callback = function(v)
        State.Skins.Gloves.Enabled = v
        if v then ApplyGloves() end
    end
})
GlovesChangerSec:AddLabel('Gloves'):AddDropdown({
    Default = State.Skins.Gloves.Type, Values = GameData.SkinsData.Gloves.List,
    Callback = function(v)
        State.Skins.Gloves.Type = v
        if State.Skins.Gloves.Enabled then ApplyGloves() end
    end
})

local glovesSkins = {}
for _, folder in ipairs(ReplicatedStorage.Skins:GetChildren()) do
    if folder:IsA("Folder") and table.find(GameData.SkinsData.Gloves.List, folder.Name) then
        local skins = {}
        for _, skinFolder in ipairs(folder:GetChildren()) do
            if skinFolder:IsA("Folder") then table.insert(skins, skinFolder.Name) end
        end
        if #skins > 0 then glovesSkins[folder.Name] = skins end
    end
end
for gloveName, skins in pairs(glovesSkins) do
    State.Skins.Gloves.Skins[gloveName] = {Enabled = false, Skin = skins[1]}
    GlovesChangerSec:AddLabel(gloveName):AddToggle({
        Default = false,
        Callback = function(v)
            State.Skins.Gloves.Skins[gloveName].Enabled = v
            if v and State.Skins.Gloves.Enabled and State.Skins.Gloves.Type == gloveName then ApplyGloves() end
        end
    })
    GlovesChangerSec:AddLabel('Skin'):AddDropdown({
        Default = skins[1], Values = skins,
        Callback = function(v)
            State.Skins.Gloves.Skins[gloveName].Skin = v
            if State.Skins.Gloves.Skins[gloveName].Enabled and State.Skins.Gloves.Enabled and State.Skins.Gloves.Type == gloveName then ApplyGloves() end
        end
    })
end

-- ============================================================
-- UI ELEMENTS - PLAYERS (Neyrone)
-- ============================================================

PlayersListSec:AddLabel('Player List'):AddButton({
    Name = 'Show Player List',
    Callback = function() Notification.new({Title = "Players", Content = "Player list feature is simplified in this version.", Duration = 5}) end
})

PrioritySec:AddLabel('Kill'):AddToggle({
    Default = State.Priority.Kill,
    Callback = function(v) State.Priority.Kill = v end
})
PrioritySec:AddLabel('Hit Per Second'):AddSlider({
    Default = State.Priority.KillHPS, Min = 1, Max = 10,
    Callback = function(v) State.Priority.KillHPS = v end
})
PrioritySec:AddButton({
    Name = 'Flashbang Priority',
    Callback = function() task.spawn(FlashbangEnemies) end
})
PrioritySec:AddLabel('Flashbang Intensity'):AddSlider({
    Default = State.Priority.FlashbangIntensity, Min = 1, Max = 10,
    Callback = function(v) State.Priority.FlashbangIntensity = v end
})

-- ============================================================
-- UI ELEMENTS - MACRO HUB (SeraphiCA)
-- ============================================================

MainSec:AddLabel('GGSign Style (All Tools)'):AddToggle({
    Default = false,
    Callback = function(v) isGGSignActive = v end
})

MainSec:AddLabel('Speed Tracker Window'):AddToggle({
    Default = false,
    Callback = function(v) speedFrame.Visible = v end
})

MainSec:AddLabel('Hold Flick Widget'):AddToggle({
    Default = false,
    Callback = function(v) HoldButton.Visible = v end
})

MainSec:AddLabel('Spidi WallHop Widget'):AddToggle({
    Default = false,
    Callback = function(v) SpidiButton.Visible = v end
})

MainSec:AddLabel('Lag Switch Widget'):AddToggle({
    Default = false,
    Callback = function(v)
        LagButton.Visible = v
        toggleLag(v)
    end
})

GlitchSec:AddLabel('Item Spam Glitch'):AddToggle({
    Default = false,
    Callback = function(v) toggleItemSpam(v) end
})

GlitchSec:AddLabel('Omega Speed Glitch (x250)'):AddToggle({
    Default = false,
    Callback = function(v)
        isOmegaActive = v
        if isOmegaActive then isStdActive = false end
        TpButton.Visible = isOmegaActive
        deployGhostGlitch()
    end
})

GlitchSec:AddLabel('Standard Speed Glitch (x50)'):AddToggle({
    Default = false,
    Callback = function(v)
        isStdActive = v
        if isStdActive then 
            isOmegaActive = false
            TpButton.Visible = false
        end
        deployGhostGlitch()
    end
})

GlitchSec:AddButton({
    Name = 'Teleport to Closest Player',
    Callback = function() task.spawn(runOmegaTeleportGlitch) end
})

GlitchSec:AddButton({
    Name = 'Reset Character Fix',
    Callback = function() restaurar(player.Character) end
})

GlitchSec:AddButton({
    Name = 'Invisible Mode',
    Callback = function() task.spawn(playInvisible) end
})

GlitchSec:AddButton({
    Name = 'Fling Back Projection',
    Callback = function() task.spawn(function() playProjection(nil, nil, nil, false, true) end) end
})

EmotesSec:AddButton({
    Name = 'Laugh (/e laugh)',
    Callback = function() task.spawn(function() playProjection(OFFSETS["Forward150"], 5, 2, true) end) end
})

EmotesSec:AddButton({
    Name = 'Wave (/e wave)',
    Callback = function() task.spawn(function() playProjection(OFFSETS["Up"], 2, 2, false) end) end
})

EmotesSec:AddButton({
    Name = 'Dance 1 (/e dance)',
    Callback = function() task.spawn(function() playProjection(OFFSETS["Right"], 1.5, 1.5, false) end) end
})

EmotesSec:AddButton({
    Name = 'Dance 2 (/e dance2)',
    Callback = function() task.spawn(function() playProjection(OFFSETS["Left"], 1.5, 1.5, false) end) end
})

EmotesSec:AddButton({
    Name = 'Dance 3 (/e dance3)',
    Callback = function() task.spawn(function() playProjection(OFFSETS["Up"], 2, 2, false) end) end
})

EmotesSec:AddButton({
    Name = 'Point (/e point)',
    Callback = function() task.spawn(function() playProjection(OFFSETS["Down"], 2, 2, false) end) end
})

EmotesSec:AddButton({
    Name = 'Point 2 (/e point2)',
    Callback = function() task.spawn(function() playProjection(Vector3.new(0, 0, -150), 1.5, 1.5, true) end) end
})

EmotesSec:AddButton({
    Name = 'Hello (/e hello)',
    Callback = function() task.spawn(function() playProjection(Vector3.new(0, -80, 0), 1.5, 1.5, true) end) end
})

EmotesSec:AddButton({
    Name = 'Hello 2 (/e hello2)',
    Callback = function() task.spawn(function() playProjection(Vector3.new(0, 80, 0), 1.5, 1.5, true) end) end
})

EmotesSec:AddButton({
    Name = 'Moonwalk (/e moonwalk)',
    Callback = function() task.spawn(function() playProjection(Vector3.new(0, 0, 50), 3, 1.5, true) end) end
})

EmotesSec:AddButton({
    Name = 'Baby Queen (/e babyqueen)',
    Callback = function() task.spawn(function() playProjection(Vector3.new(0, 80, -80), 2, 2, true) end) end
})

local fontsList = {
    {"Gotham", Enum.Font.Gotham},
    {"GothamBold", Enum.Font.GothamBold},
    {"GothamBlack", Enum.Font.GothamBlack},
    {"Cartoon", Enum.Font.Cartoon},
    {"Fantasy", Enum.Font.Fantasy},
    {"Arcade", Enum.Font.Arcade},
    {"Code", Enum.Font.Code},
    {"SourceSans", Enum.Font.SourceSans},
    {"SourceSansBold", Enum.Font.SourceSansBold},
    {"Highway", Enum.Font.Highway},
    {"Bodoni", Enum.Font.Bodoni},
    {"Garamond", Enum.Font.Garamond}
}

for _, fontData in ipairs(fontsList) do
    local name, fontEnum = fontData[1], fontData[2]
    FontSec:AddButton({
        Name = name,
        Callback = function()
            for _, desc in ipairs(playerGui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    pcall(function() desc.Font = fontEnum end)
                end
            end
        end
    })
end

local SkyboxAssets = {
    ['Black Storm'] = {
        SkyboxBk = 'rbxassetid://15502511288', SkyboxDn = 'rbxassetid://15502508460',
        SkyboxFt = 'rbxassetid://15502510289', SkyboxLf = 'rbxassetid://15502507918',
        SkyboxRt = 'rbxassetid://15502509398', SkyboxUp = 'rbxassetid://15502511911',
    },
    HD = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=16553658937', SkyboxDn = 'http://www.roblox.com/asset/?id=16553660713',
        SkyboxFt = 'http://www.roblox.com/asset/?id=16553662144', SkyboxLf = 'http://www.roblox.com/asset/?id=16553664042',
        SkyboxRt = 'http://www.roblox.com/asset/?id=16553665766', SkyboxUp = 'http://www.roblox.com/asset/?id=16553667750',
    },
    Snow = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=155657655', SkyboxDn = 'http://www.roblox.com/asset/?id=155674246',
        SkyboxFt = 'http://www.roblox.com/asset/?id=155657609', SkyboxLf = 'http://www.roblox.com/asset/?id=155657671',
        SkyboxRt = 'http://www.roblox.com/asset/?id=155657619', SkyboxUp = 'http://www.roblox.com/asset/?id=155674931',
    },
    ['Blue Space'] = {
        SkyboxBk = 'rbxassetid://15536110634', SkyboxDn = 'rbxassetid://15536112543',
        SkyboxFt = 'rbxassetid://15536116141', SkyboxLf = 'rbxassetid://15536114370',
        SkyboxRt = 'rbxassetid://15536118762', SkyboxUp = 'rbxassetid://15536117282',
    },
    Realistic = {
        SkyboxBk = 'rbxassetid://653719502', SkyboxDn = 'rbxassetid://653718790',
        SkyboxFt = 'rbxassetid://653719067', SkyboxLf = 'rbxassetid://653719190',
        SkyboxRt = 'rbxassetid://653718931', SkyboxUp = 'rbxassetid://653719321',
    },
    Stormy = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=18703245834', SkyboxDn = 'http://www.roblox.com/asset/?id=18703243349',
        SkyboxFt = 'http://www.roblox.com/asset/?id=18703240532', SkyboxLf = 'http://www.roblox.com/asset/?id=18703237556',
        SkyboxRt = 'http://www.roblox.com/asset/?id=18703235430', SkyboxUp = 'http://www.roblox.com/asset/?id=18703232671',
    },
    Pink = {
        SkyboxBk = 'rbxassetid://12216109205', SkyboxDn = 'rbxassetid://12216109875',
        SkyboxFt = 'rbxassetid://12216109489', SkyboxLf = 'rbxassetid://12216110170',
        SkyboxRt = 'rbxassetid://12216110471', SkyboxUp = 'rbxassetid://12216108877',
    },
    Sunset = {
        SkyboxBk = 'rbxassetid://600830446', SkyboxDn = 'rbxassetid://600831635',
        SkyboxFt = 'rbxassetid://600832720', SkyboxLf = 'rbxassetid://600886090',
        SkyboxRt = 'rbxassetid://600833862', SkyboxUp = 'rbxassetid://600835177',
    },
    Arctic = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=225469390', SkyboxDn = 'http://www.roblox.com/asset/?id=225469395',
        SkyboxFt = 'http://www.roblox.com/asset/?id=225469403', SkyboxLf = 'http://www.roblox.com/asset/?id=225469450',
        SkyboxRt = 'http://www.roblox.com/asset/?id=225469471', SkyboxUp = 'http://www.roblox.com/asset/?id=225469481',
    },
    Space = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=166509999', SkyboxDn = 'http://www.roblox.com/asset/?id=166510057',
        SkyboxFt = 'http://www.roblox.com/asset/?id=166510116', SkyboxLf = 'http://www.roblox.com/asset/?id=166510092',
        SkyboxRt = 'http://www.roblox.com/asset/?id=166510131', SkyboxUp = 'http://www.roblox.com/asset/?id=166510114',
    },
    ['Roblox Default'] = {
        SkyboxBk = 'rbxasset://textures/sky/sky512_bk.tex', SkyboxDn = 'rbxasset://textures/sky/sky512_dn.tex',
        SkyboxFt = 'rbxasset://textures/sky/sky512_ft.tex', SkyboxLf = 'rbxasset://textures/sky/sky512_lf.tex',
        SkyboxRt = 'rbxasset://textures/sky/sky512_rt.tex', SkyboxUp = 'rbxasset://textures/sky/sky512_up.tex',
    },
    ['Red Night'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=401664839', SkyboxDn = 'http://www.roblox.com/asset/?id=401664862',
        SkyboxFt = 'http://www.roblox.com/asset/?id=401664960', SkyboxLf = 'http://www.roblox.com/asset/?id=401664881',
        SkyboxRt = 'http://www.roblox.com/asset/?id=401664901', SkyboxUp = 'http://www.roblox.com/asset/?id=401664936',
    },
    ['Deep Space 1'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=149397692', SkyboxDn = 'http://www.roblox.com/asset/?id=149397686',
        SkyboxFt = 'http://www.roblox.com/asset/?id=149397697', SkyboxLf = 'http://www.roblox.com/asset/?id=149397684',
        SkyboxRt = 'http://www.roblox.com/asset/?id=149397688', SkyboxUp = 'http://www.roblox.com/asset/?id=149397702',
    },
    ['Pink Skies'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=151165214', SkyboxDn = 'http://www.roblox.com/asset/?id=151165197',
        SkyboxFt = 'http://www.roblox.com/asset/?id=151165224', SkyboxLf = 'http://www.roblox.com/asset/?id=151165191',
        SkyboxRt = 'http://www.roblox.com/asset/?id=151165206', SkyboxUp = 'http://www.roblox.com/asset/?id=151165227',
    },
    ['Purple Sunset'] = {
        SkyboxBk = 'rbxassetid://264908339', SkyboxDn = 'rbxassetid://264907909',
        SkyboxFt = 'rbxassetid://264909420', SkyboxLf = 'rbxassetid://264909758',
        SkyboxRt = 'rbxassetid://264908886', SkyboxUp = 'rbxassetid://264907379',
    },
    ['Blue Night'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=12064107', SkyboxDn = 'http://www.roblox.com/asset/?id=12064152',
        SkyboxFt = 'http://www.roblox.com/asset/?id=12064121', SkyboxLf = 'http://www.roblox.com/asset/?id=12063984',
        SkyboxRt = 'http://www.roblox.com/asset/?id=12064115', SkyboxUp = 'http://www.roblox.com/asset/?id=12064131',
    },
    ['Blossom Daylight'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=271042516', SkyboxDn = 'http://www.roblox.com/asset/?id=271077243',
        SkyboxFt = 'http://www.roblox.com/asset/?id=271042556', SkyboxLf = 'http://www.roblox.com/asset/?id=271042310',
        SkyboxRt = 'http://www.roblox.com/asset/?id=271042467', SkyboxUp = 'http://www.roblox.com/asset/?id=271077958',
    },
    ['Blue Nebula'] = {
        SkyboxBk = 'http://www.roblox.com/asset?id=135207744', SkyboxDn = 'http://www.roblox.com/asset?id=135207662',
        SkyboxFt = 'http://www.roblox.com/asset?id=135207770', SkyboxLf = 'http://www.roblox.com/asset?id=135207615',
        SkyboxRt = 'http://www.roblox.com/asset?id=135207695', SkyboxUp = 'http://www.roblox.com/asset?id=135207794',
    },
    ['Blue Planet'] = {
        SkyboxBk = 'rbxassetid://218955819', SkyboxDn = 'rbxassetid://218953419',
        SkyboxFt = 'rbxassetid://218954524', SkyboxLf = 'rbxassetid://218958493',
        SkyboxRt = 'rbxassetid://218957134', SkyboxUp = 'rbxassetid://218950090',
    },
    ['Deep Space 2'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=159248188', SkyboxDn = 'http://www.roblox.com/asset/?id=159248183',
        SkyboxFt = 'http://www.roblox.com/asset/?id=159248187', SkyboxLf = 'http://www.roblox.com/asset/?id=159248173',
        SkyboxRt = 'http://www.roblox.com/asset/?id=159248192', SkyboxUp = 'http://www.roblox.com/asset/?id=159248176',
    },
    Summer = {
        SkyboxBk = 'rbxassetid://16648590964', SkyboxDn = 'rbxassetid://16648617436',
        SkyboxFt = 'rbxassetid://16648595424', SkyboxLf = 'rbxassetid://16648566370',
        SkyboxRt = 'rbxassetid://16648577071', SkyboxUp = 'rbxassetid://16648598180',
    },
    Galaxy = {
        SkyboxBk = 'rbxassetid://15983968922', SkyboxDn = 'rbxassetid://15983966825',
        SkyboxFt = 'rbxassetid://15983965025', SkyboxLf = 'rbxassetid://15983967420',
        SkyboxRt = 'rbxassetid://15983966246', SkyboxUp = 'rbxassetid://15983964246',
    },
    Stylized = {
        SkyboxBk = 'rbxassetid://18351376859', SkyboxDn = 'rbxassetid://18351374919',
        SkyboxFt = 'rbxassetid://18351376800', SkyboxLf = 'rbxassetid://18351376469',
        SkyboxRt = 'rbxassetid://18351376457', SkyboxUp = 'rbxassetid://18351377189',
    },
    Minecraft = {
        SkyboxBk = 'rbxassetid://8735166756', SkyboxDn = 'http://www.roblox.com/asset/?id=8735166707',
        SkyboxFt = 'http://www.roblox.com/asset/?id=8735231668', SkyboxLf = 'http://www.roblox.com/asset/?id=8735166755',
        SkyboxRt = 'http://www.roblox.com/asset/?id=8735166751', SkyboxUp = 'http://www.roblox.com/asset/?id=8735166729',
    },
    ['Cloudy Rain'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=4498828382', SkyboxDn = 'http://www.roblox.com/asset/?id=4498828812',
        SkyboxFt = 'http://www.roblox.com/asset/?id=4498829917', SkyboxLf = 'http://www.roblox.com/asset/?id=4498830911',
        SkyboxRt = 'http://www.roblox.com/asset/?id=4498830417', SkyboxUp = 'http://www.roblox.com/asset/?id=4498831746',
    },
    ['Black Cloudy Rain'] = {
        SkyboxBk = 'http://www.roblox.com/asset/?id=149679669', SkyboxDn = 'http://www.roblox.com/asset/?id=149681979',
        SkyboxFt = 'http://www.roblox.com/asset/?id=149679690', SkyboxLf = 'http://www.roblox.com/asset/?id=149679709',
        SkyboxRt = 'http://www.roblox.com/asset/?id=149679722', SkyboxUp = 'http://www.roblox.com/asset/?id=149680199',
    },
}

local activeSkyData = nil
local skyLockConnection = nil
local childAddedConnection = nil

local function setSkybox(data)
    activeSkyData = data
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") or child:IsA("Atmosphere") then
            child:Destroy()
        end
    end
    local function applyCustomSky()
        if not activeSkyData then return end
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Sky") and child.Name ~= "MyForcedSkyBox" then
                child:Destroy()
            end
        end
        if not Lighting:FindFirstChild("MyForcedSkyBox") then
            local newSky = Instance.new("Sky")
            newSky.Name = "MyForcedSkyBox"
            for prop, assetId in pairs(activeSkyData) do
                newSky[prop] = assetId
            end
            newSky.Parent = Lighting
        end
    end
    applyCustomSky()
    if not childAddedConnection then
        childAddedConnection = Lighting.ChildAdded:Connect(function(child)
            if activeSkyData and child:IsA("Sky") and child.Name ~= "MyForcedSkyBox" then
                task.defer(function()
                    child:Destroy()
                    applyCustomSky()
                end)
            end
        end)
    end
    if not skyLockConnection then
        skyLockConnection = RunService.Heartbeat:Connect(function()
            if activeSkyData then
                applyCustomSky()
            end
        end)
    end
end

for name, data in pairs(SkyboxAssets) do
    SkySec:AddButton({
        Name = name,
        Callback = function() setSkybox(data) end
    })
end

SkySec:AddButton({
    Name = "Reset Skybox",
    Callback = function()
        activeSkyData = nil
        if skyLockConnection then skyLockConnection:Disconnect() skyLockConnection = nil end
        if childAddedConnection then childAddedConnection:Disconnect() childAddedConnection = nil end
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Sky") then child:Destroy() end
        end
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then atmosphere.Enabled = true end
    end
})

ConfigSec:AddButton({
    Name = 'Discord Invite',
    Callback = function()
        Logging.new("discord", 'SeraphiCA NS integrated into Neverlose UI successfully!', 5)
    end,
})

Notification.new({
    Title = "SeraphiCA NS",
    Content = "Loaded inside SeraphiCA NS framework successfully",
    Duration = 5,
})

Logging.new("crosshairs", 'SeraphiCA NS fully initialized', 15)

-- ============================================================
-- MAIN LOOP (SeraphiCA + Neyrone)
-- ============================================================

local spacePressed = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then spacePressed = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spacePressed = false end
end)

RunService.Heartbeat:Connect(function()
    fastReloadLoop()
    task.spawn(KillAllInit)
    task.spawn(KillPriorityInit)
    
    -- Anti-Aim Logic (Neyrone)
    if GameData.IsAlive(player) then
        if State.Rage.AntiAim then
            player.Character.Humanoid.AutoRotate = false
            local yaw = -math.atan2(cam.CFrame.LookVector.Z, cam.CFrame.LookVector.X) + math.rad(-90)
            local customYaw = math.rad(State.Rage.CustomYaw)
            local spinAngle = 0
            if State.Rage.YawBase == "Spin" then spinAngle = math.rad(tick() * State.Rage.SpinSpeed % 360) elseif State.Rage.YawBase == "Random" then spinAngle = math.rad(math.random(0, 360)) end
            local finalYaw = yaw + customYaw + spinAngle
            player.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position) * CFrame.Angles(0, finalYaw, 0)
            
            local pitch = State.Rage.PitchBase == "Custom" and (State.Rage.CustomPitch / 100) or math.random(-1, 1)
            if ClientData.HasRequire and GameData.Network and GameData.Network.FireServer then
                GameData.Network.FireServer("0R5lsPxqfSH3", pitch, true)
            end
        else
            player.Character.Humanoid.AutoRotate = true
        end
        
        if State.Rage.FakeDuck and ClientData.HasRequire and GameData.Ambassador and GameData.Ambassador.Fire then
            GameData.Ambassador.Fire("WPlay", "CrouchIdle", nil, 0)
        end
    end
    
    -- Movement Logic (Neyrone)
    if GameData.IsAlive(player) then
        local hum = player.Character.Humanoid
        local state = hum:GetState()
        
        if State.Misc.BypassSpeed and GameData.Variables then
            if GameData.Variables.crouch or GameData.Variables.fullycrouched then
                GameData.Variables.jumping = true
            else
                GameData.Variables.jumping = false
            end
        end
        
        if State.Misc.AutoJump and UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air and state ~= Enum.HumanoidStateType.Jumping then
            hum.Jump = true
        end
        
        if State.Misc.Noclip then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        else
            player.Character.HumanoidRootPart.CanCollide = true
        end
        
        if State.Misc.SpeedHack then
            local moveVec = Vector3.new()
            local speed = State.Misc.SpeedHackSpeed / 10
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * speed * 1.5
                moveVec = Vector3.new(moveVec.X, 0, moveVec.Z)
                player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + (Vector3.new(moveVec.X, 0, moveVec.Z) / 100 * 2)
            end
        end
        
        if State.Misc.Airstuck then
            player.Character.HumanoidRootPart.Anchored = true
        else
            player.Character.HumanoidRootPart.Anchored = false
        end
        
        -- Anti Spectate
        if State.Misc.AntiSpectate then
            local specType = State.Misc.AntiSpectateType
            local fakePos = specType == "Freeze" and Vector3.new(9e9, 9e9, 9e9) or cam.CFrame.Position
            local lookVec = (cam.CFrame * CFrame.new(0, 0, -1)).Position - fakePos
            local buf = buffer.create(36)
            buffer.writef32(buf, 0, fakePos.X) buffer.writef32(buf, 4, fakePos.Y) buffer.writef32(buf, 8, fakePos.Z)
            buffer.writeu8(buf, 12, math.floor((lookVec.X + 1) * 0.5 * 255))
            buffer.writeu8(buf, 13, math.floor((lookVec.Y + 1) * 0.5 * 255))
            buffer.writeu8(buf, 14, math.floor((lookVec.Z + 1) * 0.5 * 255))
            buffer.writeu8(buf, 15, bit32.bor(0, 0, 0, 8))
            buffer.writef32(buf, 16, 0) buffer.writef32(buf, 20, specType == "Low Fov" and 0 or 70)
            buffer.writef32(buf, 24, 0) buffer.writef32(buf, 28, 0) buffer.writef32(buf, 32, 0)
            ReplicatedStorage.UpdateSpectate:FireServer(buf)
        end
    end
    
    -- Skin Changer Apply
    if ClientData.HasRequire and GameData.Appearance and GameData.Appearance.MapGunSkin then
        task.spawn(ApplyCurrentWeaponSkin)
    end
    task.spawn(ApplyKnifeSkin)
    task.spawn(ApplyGloves)
end)

RunService.RenderStepped:Connect(function()
    cam = Workspace.CurrentCamera or cam
    
    updateFov()
    updateShotSc()
    
    -- Legit Bot Logic (Neyrone)
    if GameData.IsAlive(player) then
        local mousePos = UserInputService:GetMouseLocation()
        local fovDist = (cam.ViewportSize.X * (State.Legit.FovValue / 2) / cam.FieldOfView) / 2
        
        if State.Legit.SilentAim then
            LegitTarget = GetLegitTarget(State.Legit.Fov, fovDist)
            if LegitTarget then
                LegitTargetPart = LegitTarget.Character[Hitboxes[State.Legit.Hitscan]]
            end
        end
        
        if State.Legit.Aimbot and ((State.Legit.AimbotActivate == "Mouse 1" and UserInputService:IsMouseButtonPressed(0)) or (State.Legit.AimbotActivate == "Mouse 2" and UserInputService:IsMouseButtonPressed(1))) then
            LegitTarget = GetLegitTarget(State.Legit.Fov, fovDist)
            if LegitTarget then
                local targetPart = LegitTarget.Character[Hitboxes[State.Legit.Hitscan]]
                local speed = State.Legit.AimbotSpeed
                if State.Legit.AimbotType == "Mouse Movement" and ClientData.HasMousemoverel then
                    speed = speed / 9
                    local screenPos = cam:WorldToViewportPoint(targetPart.Position)
                    local moveX = (screenPos.X - (cam.ViewportSize.X / 2)) * speed / 20.5
                    local moveY = (screenPos.Y - (cam.ViewportSize.Y / 2)) * speed / 20.5
                    mousemoverel(moveX, moveY)
                elseif State.Legit.AimbotType == "Lerp" then
                    local targetCF = CFrame.new(cam.CFrame.Position, targetPart.Position)
                    local angleDiff = math.abs(math.deg(math.acos(cam.CFrame.LookVector:Dot(CFrame.new(cam.CFrame.Position, targetPart.Position).LookVector)))) * 2
                    if State.Legit.AimbotSpeedType == "Exponential" then speed = speed / 500 else speed = (speed / angleDiff) / 100 end
                    cam.CFrame = cam.CFrame:Lerp(targetCF, speed)
                else
                    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
                end
            end
        end
        
        if State.Legit.Triggerbot then
            local ignoreList = {}
            if ClientData.HasRequire and GameData.Variables and GameData.Variables.Params then
                for _, v in ipairs(GameData.Variables.Params.FilterDescendantsInstances) do table.insert(ignoreList, v) end
            else ignoreList = {workspace.Destroyable, workspace.Debris, workspace.Map.Clips} end
            table.insert(ignoreList, player.Character)
            table.insert(ignoreList, cam)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = ignoreList
            params.IgnoreWater = true
            local result = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 365, params)
            if result and result.Instance and result.Instance:IsA("BasePart") then
                local targetPlayer = LocalPlayers:GetPlayerFromCharacter(result.Instance.Parent)
                if targetPlayer and GameData.IsAlive(targetPlayer) and (ReplicatedStorage:GetAttribute("NoTKPenalty") or targetPlayer:GetAttribute("Team") ~= player:GetAttribute("Team")) and not targetPlayer.Character:FindFirstChildWhichIsA("ForceField") then
                    if State.Legit.TriggerbotDelay ~= 0 then task.wait(State.Legit.TriggerbotDelay / 1000) end
                    if ClientData.HasGetsenv and ClientData.FullGetsenv and GameData.BaseWeapon then
                        GameData.BaseWeapon.firebullet()
                    elseif mouse1press and mouse1release then
                        mouse1press() task.wait() mouse1release()
                    end
                end
            end
        end
        
        -- Get Rage Target for Throwables
        if State.Rage.Throwables then
            RageTarget = GetRageTarget()
        end
    end
    
    -- ThirdPerson (SeraphiCA)
    if State.Misc.ThirdPerson then
        local char = player.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                local firstPersonCF = cam.CFrame
                local targetPos = firstPersonCF.Position + (firstPersonCF.LookVector * -State.Misc.CamDistance)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local result = Workspace:Raycast(firstPersonCF.Position, targetPos - firstPersonCF.Position, params)
                local finalPos = targetPos
                if result then finalPos = result.Position end
                cam.CFrame = CFrame.lookAt(finalPos, firstPersonCF.Position)
            end
        end
    end
    
    -- SeraphiCA Anti-Aim (if enabled)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 and State.Misc.AntiAimEnabled then
            hum.AutoRotate = false
            local camCF = cam.CFrame
            local _, yaw, _ = camCF:ToEulerAnglesYXZ()
            local newCF = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
            local pitchRad = 0
            if State.Misc.AntiAimPitch == "Down" then pitchRad = math.rad(89)
            elseif State.Misc.AntiAimPitch == "Up" then pitchRad = math.rad(-89) end
            newCF = newCF * CFrame.Angles(pitchRad, 0, 0)
            local yawRad = 0
            if State.Misc.AntiAimYaw == "Backwards" then yawRad = math.rad(180)
            elseif State.Misc.AntiAimYaw == "Sideways" then yawRad = math.rad(90)
            elseif State.Misc.AntiAimYaw == "Jitter" then
                yawRad = (math.floor(tick() * 10) % 2 == 0) and math.rad(90) or math.rad(-90)
            end
            newCF = newCF * CFrame.Angles(0, yawRad, 0)
            root.CFrame = newCF
            cam.CFrame = camCF
        else
            hum.AutoRotate = true
        end
    end
    
    -- BunnyHop (SeraphiCA)
    if State.Misc.BunnyHop then
        if spacePressed then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                    humanoid.UseJumpPower = true
                    humanoid.JumpPower = 50 * State.Misc.BhopSpeed
                    humanoid.Jump = true
                end
            end
        end
    end
    
    -- SeraphiCA Silent Aim
    if State.AimBot.SilentEnabled then
        CachedSilentTarget = findSilentTarget()
    else
        CachedSilentTarget = nil
    end
    
    -- SeraphiCA Aimbot
    if State.AimBot.Enabled then
        local targetPart = findAimTarget()
        if targetPart then
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
        end
    end
    
    -- ESP Update
    if State.Visuals.ESP then
        updateEsp()
    else
        for _, e in pairs(EspObjects) do
            e.Box.Visible = false
            e.HealthBack.Visible = false
            e.Name.Visible = false
            e.Distance.Visible = false
        end
        for p, hl in pairs(ChamsObjects) do hl.Enabled = false end
    end
    
    -- Spectator List Update
    if State.Visuals.SpectatorList then
        local specs = {}
        for _, p in ipairs(LocalPlayers:GetPlayers()) do
            if p ~= player then
                local isSpec = false
                if not p.Character then isSpec = true end
                local c = p.Character
                if c then
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if h and h.Health <= 0 then isSpec = true end
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
                local hasKit = player.Character and player.Character:FindFirstChild("DefuseKit")
                local defuseTime = hasKit and 4 or 7
                if timeLeft > defuseTime then
                    BombWidget.Text = string.format("BOMB: %.1fs | DEFUSABLE", timeLeft)
                    BombWidget.TextColor3 = Color3.fromRGB(49, 209, 88)
                else
                    BombWidget.Text = string.format("BOMB: %.1fs | NO TIME", timeLeft)
                    BombWidget.TextColor3 = Color3.fromRGB(255, 69, 58)
                end
            else
                BombWidget.Text = "BOMB PLANTED"
                BombWidget.TextColor3 = Color3.fromRGB(255, 214, 10)
            end
        else
            BombWidget.Text = ""
        end
    end
    
    -- Weapon Visuals (Neyrone)
    if GameData.IsAlive(player) and GameData.EquippedWeapon and GameData.EquippedWeaponFolder then
        local arms = cam:FindFirstChild("Arms")
        if arms then
            if State.Visuals.NoJumpBob then
                arms:SetAttribute("Scale", 0)
            else
                if arms:GetAttribute("Scale") ~= nil then arms:SetAttribute("Scale", nil) end
            end
            
            if State.Visuals.WeaponChams or State.Visuals.WeaponTextureChanger then
                for _, viewmodel in ipairs(GameData.EquippedWeaponFolder:GetChildren()) do
                    if viewmodel.Name == "Viewmodel" then
                        for _, child in ipairs(arms:GetChildren()) do
                            if viewmodel:FindFirstChild(child.Name) then
                                for _, desc in ipairs(child:GetDescendants()) do
                                    if desc:IsA("MeshPart") and desc.Transparency == 1 then continue end
                                    if child:IsA("MeshPart") and child.Name == "Stock" then continue end
                                    
                                    if State.Visuals.WeaponChams then
                                        if desc:IsA("MeshPart") then
                                            desc.Color = State.Visuals.WeaponChamsColor
                                            desc.Material = Enum.Material.ForceField
                                            desc.Transparency = 0
                                        elseif desc:IsA("UnionOperation") then
                                            desc.UsePartColor = true
                                            desc.Color = State.Visuals.WeaponChamsColor
                                            desc.Material = Enum.Material.ForceField
                                            desc.Transparency = 0
                                        end
                                    end
                                    
                                    if State.Visuals.WeaponTextureChanger then
                                        if desc:IsA("MeshPart") then
                                            desc.TextureID = WeaponTextures[State.Visuals.WeaponTexture]
                                        end
                                        if desc:IsA("SurfaceAppearance") then
                                            desc.Parent = nil
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sounds (Neyrone)
    if State.Visuals.HitSound then
        if SoundsList[State.Visuals.HitSoundName] then
            ReplicatedStorage.Sounds.HitSound.Value = SoundsList[State.Visuals.HitSoundName]
            ReplicatedStorage.Sounds.HitSound.Volume.Value = State.Visuals.HitSoundVolume
        end
    else
        ReplicatedStorage.Sounds.HitSound.Value = SoundsList["Default Hit Sound"]
        ReplicatedStorage.Sounds.HitSound.Volume.Value = 1.5
    end
    
    if State.Visuals.KillSound then
        if SoundsList[State.Visuals.KillSoundName] then
            ReplicatedStorage.Sounds.KillSound.Value = SoundsList[State.Visuals.KillSoundName]
            ReplicatedStorage.Sounds.KillSound.Volume.Value = State.Visuals.KillSoundVolume
        end
    else
        ReplicatedStorage.Sounds.KillSound.Value = SoundsList["Default Kill Sound"]
        ReplicatedStorage.Sounds.KillSound.Volume.Value = 1.5
    end
end)

LocalPlayers.PlayerRemoving:Connect(clearEsp)

print("[SeraphiCA NS] Defuse Edition v36 loaded. UI Load Fix Applied.")

--!strict
--[[
    ╔═══════════════════════════════════════════════════╗
    ║              ARCEUS  v2.0 — Purple Edition        ║
    ║               Pure neon-violet UI                 ║
    ║         For local / private testing only          ║
    ╚═══════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Camera            = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ─────────────────────────────────────────────────────
--  PALETTE
-- ─────────────────────────────────────────────────────
local BG_PANEL     = Color3.fromRGB(18,  10,  28)
local BG_CARD      = Color3.fromRGB(14,   7,  22)
local BG_TITLE     = Color3.fromRGB(24,  16,  34)
local BG_INPUT     = Color3.fromRGB(28,  18,  40)
local TRACK_BG     = Color3.fromRGB(38,  28,  56)
local STROKE       = Color3.fromRGB(160, 80, 255)
local SHADOW_BLACK = Color3.fromRGB(0,    0,   0)

local TEXT_BRIGHT  = Color3.fromRGB(238, 220, 255)
local TEXT_DIM     = Color3.fromRGB(160, 130, 195)

local ON           = Color3.fromRGB(170,  90, 255)
local ON_BRIGHT    = Color3.fromRGB(220, 130, 255)
local OFF          = Color3.fromRGB(38,   26,  56)

-- ─────────────────────────────────────────────────────
--  SETTINGS
-- ─────────────────────────────────────────────────────
local Settings = {
    -- Aim
    AimEnabled   = true,
    TeamCheck    = true,
    WallCheck    = false,
    Smoothness   = 8,
    FOVRadius    = 150,
    MaxDistance  = 500,

    -- ESP
    ESPEnabled   = true,
    BoxESP       = true,
    NameESP      = true,
    HealthBar    = true,
    TracerESP    = true,
    Crosshair    = true,

    -- Colors (purple palette)
    ColFOVIdle    = Color3.fromRGB(120,  80, 200),
    ColFOVLock    = Color3.fromRGB(220, 110, 255),
    ColBox        = Color3.fromRGB(160,  80, 255),
    ColBoxTarget  = Color3.fromRGB(220, 110, 255),
    ColName       = Color3.fromRGB(238, 220, 255),
    ColDistance   = Color3.fromRGB(180, 150, 220),
    ColTracer     = Color3.fromRGB(170,  90, 255),
    ColTracerLock = Color3.fromRGB(220, 110, 255),
    ColCrosshair  = Color3.fromRGB(180, 120, 255),
}

-- ─────────────────────────────────────────────────────
--  DRAWING HELPERS
-- ─────────────────────────────────────────────────────
local allDrawings = {}

local function makeDrawing(kind, props)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do
        d[k] = v
    end
    allDrawings[d] = true
    return d
end

local function destroyDrawing(d)
    if d then
        allDrawings[d] = nil
        d:Remove()
    end
end

local function destroyAll()
    for d in pairs(allDrawings) do
        pcall(function() d:Remove() end)
    end
    allDrawings = {}
end

-- ─────────────────────────────────────────────────────
--  SCREEN HELPERS
-- ─────────────────────────────────────────────────────
local function screenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- ─────────────────────────────────────────────────────
--  HEALTH COLOR (keep green/yellow/red for contrast)
-- ─────────────────────────────────────────────────────
local function healthColor(pct)
    pct = math.clamp(pct, 0, 1)
    if pct > 0.5 then
        return Color3.fromRGB(
            math.floor((1 - pct) * 2 * 255),
            255,
            0
        )
    else
        return Color3.fromRGB(
            255,
            math.floor(pct * 2 * 255),
            0
        )
    end
end

-- ─────────────────────────────────────────────────────
--  FOV CIRCLE + LOCK DOT
-- ─────────────────────────────────────────────────────
local fovCircle = makeDrawing("Circle", {
    Visible       = Settings.AimEnabled,
    Color         = Settings.ColFOVIdle,
    Radius        = Settings.FOVRadius,
    Thickness     = 1.5,
    Transparency  = 0.55,
    Filled        = false,
    NumSides      = 64,
    Position      = screenCenter(),
})

local lockDot = makeDrawing("Circle", {
    Visible      = false,
    Color        = Color3.fromRGB(220, 110, 255),
    Radius       = 3,
    Thickness     = 1,
    Transparency  = 1,
    Filled        = true,
    NumSides      = 16,
    Position      = screenCenter(),
})

-- ─────────────────────────────────────────────────────
--  CENTER CROSSHAIR
-- ─────────────────────────────────────────────────────
local crossH = makeDrawing("Line", {
    Visible     = false,
    Color       = Settings.ColCrosshair,
    Thickness   = 1.2,
    Transparency = 0,
})
local crossV = makeDrawing("Line", {
    Visible     = false,
    Color       = Settings.ColCrosshair,
    Thickness   = 1.2,
    Transparency = 0,
})

local function updateCrosshair()
    local visible = Settings.Crosshair and Settings.AimEnabled
    crossH.Visible = visible
    crossV.Visible = visible
    if not visible then return end

    local c   = screenCenter()
    local arm = 12
    local gap = 4

    crossH.From  = Vector2.new(c.X - arm, c.Y)
    crossH.To    = Vector2.new(c.X - gap, c.Y)
    -- second half drawn by repurposing: we'll use two additional drawings for the four arms
    -- Actually using one line per arm (4 total) is cleaner; we only have 2 lines so we
    -- draw each line as one full half and leave a visual gap by adjusting From/To.
    -- Horizontal: left arm
    crossH.From  = Vector2.new(c.X - arm, c.Y)
    crossH.To    = Vector2.new(c.X - gap, c.Y)
    -- Vertical: top arm
    crossV.From  = Vector2.new(c.X, c.Y - arm)
    crossV.To    = Vector2.new(c.X, c.Y - gap)
end

-- We need 4 line segments for a full +-crosshair with a center gap.
-- Add two more for the right and bottom arms.
local crossH2 = makeDrawing("Line", {
    Visible     = false,
    Color       = Settings.ColCrosshair,
    Thickness   = 1.2,
    Transparency = 0,
})
local crossV2 = makeDrawing("Line", {
    Visible     = false,
    Color       = Settings.ColCrosshair,
    Thickness   = 1.2,
    Transparency = 0,
})

local function updateCrosshairFull()
    local visible = Settings.Crosshair and Settings.AimEnabled
    crossH.Visible  = visible
    crossH2.Visible = visible
    crossV.Visible  = visible
    crossV2.Visible = visible
    if not visible then return end

    local c   = screenCenter()
    local arm = 12
    local gap = 4

    crossH.From  = Vector2.new(c.X - arm, c.Y)
    crossH.To    = Vector2.new(c.X - gap, c.Y)

    crossH2.From = Vector2.new(c.X + gap, c.Y)
    crossH2.To   = Vector2.new(c.X + arm, c.Y)

    crossV.From  = Vector2.new(c.X, c.Y - arm)
    crossV.To    = Vector2.new(c.X, c.Y - gap)

    crossV2.From = Vector2.new(c.X, c.Y + gap)
    crossV2.To   = Vector2.new(c.X, c.Y + arm)
end

-- ─────────────────────────────────────────────────────
--  ESP CACHE
-- ─────────────────────────────────────────────────────
local espCache = {}  -- [Player] = { box, nameText, distText, healthBg, healthFill, tracer }

local function createESPForPlayer(player)
    if player == LocalPlayer then return end
    if espCache[player] then return end

    espCache[player] = {
        box = makeDrawing("Square", {
            Visible     = false,
            Color       = Settings.ColBox,
            Thickness   = 1.2,
            Transparency = 0,
            Filled      = false,
        }),
        nameText = makeDrawing("Text", {
            Visible      = false,
            Color        = Settings.ColName,
            Size         = 13,
            Center       = true,
            Outline      = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Text         = "",
        }),
        distText = makeDrawing("Text", {
            Visible      = false,
            Color        = Settings.ColDistance,
            Size         = 11,
            Center       = true,
            Outline      = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Text         = "",
        }),
        healthBg = makeDrawing("Square", {
            Visible     = false,
            Color       = Color3.fromRGB(20, 20, 20),
            Thickness   = 1,
            Transparency = 0.35,
            Filled      = true,
        }),
        healthFill = makeDrawing("Square", {
            Visible     = false,
            Color       = Color3.fromRGB(0, 255, 80),
            Thickness   = 1,
            Transparency = 0,
            Filled      = true,
        }),
        tracer = makeDrawing("Line", {
            Visible     = false,
            Color       = Settings.ColTracer,
            Thickness   = 1,
            Transparency = 0,
        }),
    }
end

local function removeESPForPlayer(player)
    local cache = espCache[player]
    if not cache then return end
    for _, d in pairs(cache) do
        destroyDrawing(d)
    end
    espCache[player] = nil
end

local function updateESP(player, isTarget)
    if not Settings.ESPEnabled then return end

    local cache = espCache[player]
    if not cache then return end

    local function hide()
        for _, d in pairs(cache) do
            d.Visible = false
        end
    end

    local char = player.Character
    if not char then hide() return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then hide() return end

    local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then hide() return end

    -- Bounding box approximation from character size
    local topPos    = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3.2, 0))
    local bottomPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -3.2, 0))

    local screenPos = Vector2.new(rootPos.X, rootPos.Y)
    local height    = math.abs(topPos.Y - bottomPos.Y)
    local width     = height * 0.55

    local boxColor   = isTarget and Settings.ColBoxTarget or Settings.ColBox
    local tracerCol  = isTarget and Settings.ColTracerLock or Settings.ColTracer

    -- BOX
    if Settings.BoxESP then
        cache.box.Visible  = true
        cache.box.Color    = boxColor
        cache.box.Size     = Vector2.new(width, height)
        cache.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
    else
        cache.box.Visible = false
    end

    -- NAME + DISTANCE
    local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)

    if Settings.NameESP then
        cache.nameText.Visible  = true
        cache.nameText.Color    = Settings.ColName
        cache.nameText.Text     = player.DisplayName
        cache.nameText.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 14)

        cache.distText.Visible  = true
        cache.distText.Color    = Settings.ColDistance
        cache.distText.Text     = dist .. "m"
        cache.distText.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 25)
    else
        cache.nameText.Visible = false
        cache.distText.Visible = false
    end

    -- HEALTH BAR
    if Settings.HealthBar then
        local pct     = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barH    = height
        local barW    = 4
        local barX    = screenPos.X - width / 2 - barW - 3
        local barY    = screenPos.Y - height / 2

        cache.healthBg.Visible  = true
        cache.healthBg.Size     = Vector2.new(barW, barH)
        cache.healthBg.Position = Vector2.new(barX, barY)

        cache.healthFill.Visible  = true
        cache.healthFill.Color    = healthColor(pct)
        cache.healthFill.Size     = Vector2.new(barW, barH * pct)
        cache.healthFill.Position = Vector2.new(barX, barY + barH * (1 - pct))
    else
        cache.healthBg.Visible   = false
        cache.healthFill.Visible = false
    end

    -- TRACER
    if Settings.TracerESP then
        local c = screenCenter()
        cache.tracer.Visible = true
        cache.tracer.Color   = tracerCol
        cache.tracer.From    = Vector2.new(c.X, c.Y + (Camera.ViewportSize.Y / 2))
        cache.tracer.To      = Vector2.new(screenPos.X, screenPos.Y + height / 2)
    else
        cache.tracer.Visible = false
    end
end

-- ─────────────────────────────────────────────────────
--  WALL / VISIBILITY CHECK
-- ─────────────────────────────────────────────────────
local function canSee(lchar, char, part)
    local origin = Camera.CFrame.Position
    local dir    = part.Position - origin

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { workspace.Terrain, lchar, char }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, dir, params)
    return result == nil
end

-- ─────────────────────────────────────────────────────
--  GET BEST TARGET
-- ─────────────────────────────────────────────────────
local CurrentTarget = nil

local function getBestTarget()
    local lchar = LocalPlayer.Character
    if not lchar then return nil end
    local lhrp = lchar:FindFirstChild("HumanoidRootPart")
    if not lhrp then return nil end

    local bestDist = math.huge
    local bestPlayer = nil
    local bestPart   = nil
    local center     = screenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        -- Team check
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

        -- Distance check
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local worldDist = (lhrp.Position - hrp.Position).Magnitude
        if worldDist > Settings.MaxDistance then continue end

        -- Wall check
        local aimPart = char:FindFirstChild("Head") or hrp
        if Settings.WallCheck and not canSee(lchar, char, aimPart) then continue end

        -- Screen distance
        local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
        if not onScreen then continue end

        local scrVec = Vector2.new(screenPos.X, screenPos.Y)
        local screenDist = (scrVec - center).Magnitude
        if screenDist > Settings.FOVRadius then continue end

        if screenDist < bestDist then
            bestDist   = screenDist
            bestPlayer = player
            bestPart   = aimPart
        end
    end

    return bestPlayer, bestPart
end

-- ─────────────────────────────────────────────────────
--  DO AIM
-- ─────────────────────────────────────────────────────
local function doAim(aimPart)
    if not aimPart then return end
    local camPos   = Camera.CFrame.Position
    local targetCF = CFrame.lookAt(camPos, aimPart.Position)
    Camera.CFrame  = Camera.CFrame:Lerp(targetCF, 1 / (Settings.Smoothness + 1))
end

-- ─────────────────────────────────────────────────────
--  SCREENUI + PANEL
-- ─────────────────────────────────────────────────────
-- Clean up previous instance
local old = LocalPlayer.PlayerGui:FindFirstChild("ArceusV2Gui")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "ArceusV2Gui"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.DisplayOrder    = 9999
screenGui.Parent          = LocalPlayer.PlayerGui

-- Shadow
local Shadow = Instance.new("Frame")
Shadow.Name                = "Shadow"
Shadow.Size                = UDim2.new(0, 290, 0, 420)
Shadow.Position            = UDim2.new(0, 82, 0, 42)
Shadow.BackgroundColor3    = SHADOW_BLACK
Shadow.BackgroundTransparency = 0.55
Shadow.BorderSizePixel     = 0
Shadow.ZIndex              = 1
Shadow.Parent              = screenGui
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 16)

-- Panel
local Panel = Instance.new("Frame")
Panel.Name                 = "Panel"
Panel.Size                 = UDim2.new(0, 290, 0, 420)
Panel.Position             = UDim2.new(0, 80, 0, 40)
Panel.BackgroundColor3     = BG_PANEL
Panel.BorderSizePixel      = 0
Panel.ZIndex               = 2
Panel.Parent               = screenGui
local panelCorner = Instance.new("UICorner", Panel)
panelCorner.CornerRadius   = UDim.new(0, 14)
local panelStroke = Instance.new("UIStroke", Panel)
panelStroke.Color          = STROKE
panelStroke.Thickness      = 1.2
panelStroke.Transparency   = 0.78

local PanelVisible = true

-- ─── Title Bar ───────────────────────────────────────
local TitleBar = Instance.new("Frame")
TitleBar.Name              = "TitleBar"
TitleBar.Size              = UDim2.new(1, 0, 0, 56)
TitleBar.Position          = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3  = BG_TITLE
TitleBar.BorderSizePixel   = 0
TitleBar.ZIndex            = 3
TitleBar.Parent            = Panel
local tbCorner = Instance.new("UICorner", TitleBar)
tbCorner.CornerRadius      = UDim.new(0, 14)
-- Patch bottom corners (fake lower rectangle to fill them)
local tbPatch = Instance.new("Frame")
tbPatch.Size               = UDim2.new(1, 0, 0.5, 0)
tbPatch.Position           = UDim2.new(0, 0, 0.5, 0)
tbPatch.BackgroundColor3   = BG_TITLE
tbPatch.BorderSizePixel    = 0
tbPatch.ZIndex             = 3
tbPatch.Parent             = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size            = UDim2.new(1, -14, 0, 22)
TitleLabel.Position        = UDim2.new(0, 14, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font            = Enum.Font.GothamBold
TitleLabel.TextSize        = 18
TitleLabel.TextColor3      = TEXT_BRIGHT
TitleLabel.TextXAlignment  = Enum.TextXAlignment.Left
TitleLabel.Text            = "ARCEUS  v2.0"
TitleLabel.ZIndex          = 4
TitleLabel.Parent          = TitleBar

local SubLabel = Instance.new("TextLabel")
SubLabel.Size              = UDim2.new(1, -14, 0, 14)
SubLabel.Position          = UDim2.new(0, 14, 0, 30)
SubLabel.BackgroundTransparency = 1
SubLabel.Font              = Enum.Font.Gotham
SubLabel.TextSize          = 10
SubLabel.TextColor3        = TEXT_DIM
SubLabel.TextXAlignment    = Enum.TextXAlignment.Left
SubLabel.Text              = "Private Build  •  v2.0 — Purple"
SubLabel.ZIndex            = 4
SubLabel.Parent            = TitleBar

-- Accent bar
local AccentBar = Instance.new("Frame")
AccentBar.Size             = UDim2.new(0, 36, 0, 2)
AccentBar.Position         = UDim2.new(0, 14, 0, 48)
AccentBar.BackgroundColor3 = ON
AccentBar.BorderSizePixel  = 0
AccentBar.ZIndex           = 4
AccentBar.Parent           = Panel
Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

-- ─── Scroll / Content ────────────────────────────────
local Content = Instance.new("ScrollingFrame")
Content.Name               = "Content"
Content.Size               = UDim2.new(1, 0, 1, -60)
Content.Position           = UDim2.new(0, 0, 0, 60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel    = 0
Content.ScrollBarThickness = 2
Content.ScrollBarImageColor3 = ON
Content.CanvasSize         = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ZIndex             = 3
Content.Parent             = Panel

local contentPad = Instance.new("UIPadding", Content)
contentPad.PaddingLeft   = UDim.new(0, 12)
contentPad.PaddingRight  = UDim.new(0, 12)
contentPad.PaddingTop    = UDim.new(0, 10)
contentPad.PaddingBottom = UDim.new(0, 10)

local contentLayout = Instance.new("UIListLayout", Content)
contentLayout.SortOrder  = Enum.SortOrder.LayoutOrder
contentLayout.Padding    = UDim.new(0, 6)

-- ─────────────────────────────────────────────────────
--  UI BUILDER HELPERS
-- ─────────────────────────────────────────────────────
local layoutOrder = 0
local function nextOrder()
    layoutOrder = layoutOrder + 1
    return layoutOrder
end

local function makeSectionHeader(text)
    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder       = nextOrder()
    frame.ZIndex            = 4
    frame.Parent            = Content

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, 0, 0, 16)
    lbl.Position           = UDim2.new(0, 0, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = ON
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text:upper()
    lbl.ZIndex             = 4

    local sep = Instance.new("Frame", frame)
    sep.Size               = UDim2.new(1, 0, 0, 1)
    sep.Position           = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
    sep.BackgroundTransparency = 0.88
    sep.BorderSizePixel    = 0
    sep.ZIndex             = 4

    return frame
end

local function makeToggle(labelText, initVal, callback)
    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3  = BG_CARD
    row.BorderSizePixel   = 0
    row.LayoutOrder       = nextOrder()
    row.ZIndex            = 4
    row.Parent            = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size              = UDim2.new(1, -58, 1, 0)
    lbl.Position          = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 13
    lbl.TextColor3        = TEXT_BRIGHT
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = labelText
    lbl.ZIndex            = 5

    -- Pill track
    local track = Instance.new("Frame", row)
    track.Size            = UDim2.new(0, 40, 0, 18)
    track.Position        = UDim2.new(1, -50, 0.5, -9)
    track.BackgroundColor3 = initVal and ON or OFF
    track.BorderSizePixel = 0
    track.ZIndex          = 5
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    -- ON gradient
    local grad = Instance.new("UIGradient", track)
    grad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ON),
        ColorSequenceKeypoint.new(1, ON_BRIGHT),
    })
    grad.Rotation = 90
    grad.Enabled  = initVal

    -- Knob
    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = initVal and UDim2.new(1, -18, 0.5, -8)
                                     or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 6
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local value = initVal
    local ti    = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local btn = Instance.new("TextButton", row)
    btn.Size              = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text              = ""
    btn.ZIndex            = 7

    btn.MouseButton1Click:Connect(function()
        value = not value
        TweenService:Create(track, ti, { BackgroundColor3 = value and ON or OFF }):Play()
        grad.Enabled = value
        TweenService:Create(knob, ti, {
            Position = value and UDim2.new(1, -18, 0.5, -8)
                               or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        callback(value)
    end)

    return row
end

local function makeSlider(labelText, minV, maxV, initV, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = BG_CARD
    row.BorderSizePixel  = 0
    row.LayoutOrder      = nextOrder()
    row.ZIndex           = 4
    row.Parent           = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(0.6, 0, 0, 18)
    lbl.Position         = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = TEXT_BRIGHT
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = labelText
    lbl.ZIndex           = 5

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size          = UDim2.new(0.35, 0, 0, 18)
    valLbl.Position      = UDim2.new(0.65, -10, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Font          = Enum.Font.GothamBold
    valLbl.TextSize      = 12
    valLbl.TextColor3    = ON
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text          = tostring(initV)
    valLbl.ZIndex        = 5

    -- Track
    local trackFrame = Instance.new("Frame", row)
    trackFrame.Size    = UDim2.new(1, -56, 0, 6)
    trackFrame.Position = UDim2.new(0, 10, 0, 30)
    trackFrame.BackgroundColor3 = TRACK_BG
    trackFrame.BorderSizePixel = 0
    trackFrame.ZIndex  = 5
    Instance.new("UICorner", trackFrame).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", trackFrame)
    fill.Size            = UDim2.new((initV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = ON
    fill.BorderSizePixel = 0
    fill.ZIndex          = 6
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    -- Minus button
    local minus = Instance.new("TextButton", row)
    minus.Size           = UDim2.new(0, 22, 0, 22)
    minus.Position       = UDim2.new(1, -46, 0, 5)
    minus.BackgroundColor3 = BG_INPUT
    minus.BorderSizePixel = 0
    minus.Font           = Enum.Font.GothamBold
    minus.TextSize       = 14
    minus.TextColor3     = TEXT_BRIGHT
    minus.Text           = "−"
    minus.ZIndex         = 6
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)

    -- Plus button
    local plus = Instance.new("TextButton", row)
    plus.Size            = UDim2.new(0, 22, 0, 22)
    plus.Position        = UDim2.new(1, -22, 0, 5)
    plus.BackgroundColor3 = BG_INPUT
    plus.BorderSizePixel = 0
    plus.Font            = Enum.Font.GothamBold
    plus.TextSize        = 14
    plus.TextColor3      = TEXT_BRIGHT
    plus.Text            = "+"
    plus.ZIndex          = 6
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)

    local value = initV
    local step  = math.max(1, math.floor((maxV - minV) / 100))

    local function set(v)
        value = math.clamp(v, minV, maxV)
        valLbl.Text = tostring(value)
        fill.Size   = UDim2.new((value - minV) / (maxV - minV), 0, 1, 0)
        callback(value)
    end

    minus.MouseButton1Click:Connect(function() set(value - step) end)
    plus.MouseButton1Click:Connect(function()  set(value + step) end)

    -- Drag on track
    local dragging = false
    trackFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs   = trackFrame.AbsolutePosition
            local sz    = trackFrame.AbsoluteSize
            local rel   = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            set(math.round(minV + rel * (maxV - minV)))
        end
    end)

    return row
end

-- ─────────────────────────────────────────────────────
--  BUILD UI SECTIONS
-- ─────────────────────────────────────────────────────

-- AIM Section
makeSectionHeader("Aimbot")
makeToggle("Aimbot", Settings.AimEnabled, function(v) Settings.AimEnabled = v end)
makeToggle("Team Check", Settings.TeamCheck, function(v) Settings.TeamCheck = v end)
makeToggle("Wall Check", Settings.WallCheck, function(v) Settings.WallCheck = v end)
makeSlider("Smoothness", 1, 30, Settings.Smoothness, function(v) Settings.Smoothness = v end)
makeSlider("FOV Radius", 30, 400, Settings.FOVRadius, function(v) Settings.FOVRadius = v end)
makeSlider("Max Distance", 50, 1000, Settings.MaxDistance, function(v) Settings.MaxDistance = v end)

-- ESP Section
makeSectionHeader("ESP")
makeToggle("ESP Master", Settings.ESPEnabled, function(v)
    Settings.ESPEnabled = v
    if not v then
        for player, cache in pairs(espCache) do
            for _, d in pairs(cache) do
                d.Visible = false
            end
        end
    end
end)
makeToggle("Box ESP", Settings.BoxESP, function(v) Settings.BoxESP = v end)
makeToggle("Name + Distance", Settings.NameESP, function(v) Settings.NameESP = v end)
makeToggle("Health Bar", Settings.HealthBar, function(v) Settings.HealthBar = v end)
makeToggle("Tracer", Settings.TracerESP, function(v) Settings.TracerESP = v end)
makeToggle("Crosshair", Settings.Crosshair, function(v) Settings.Crosshair = v end)

-- ─────────────────────────────────────────────────────
--  DRAGGING
-- ─────────────────────────────────────────────────────
local dragging   = false
local dragStart  = nil
local startPos   = nil

TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = Panel.Position
    end
end)

TitleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        Panel.Position  = newPos
        Shadow.Position = UDim2.new(
            newPos.X.Scale,
            newPos.X.Offset + 2,
            newPos.Y.Scale,
            newPos.Y.Offset + 2
        )
    end
end)

-- ─────────────────────────────────────────────────────
--  RIGHT-ALT TOGGLE
-- ─────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if gameProcessed then return end
    if inp.KeyCode == Enum.KeyCode.RightAlt then
        PanelVisible = not PanelVisible
        Panel.Visible  = PanelVisible
        Shadow.Visible = PanelVisible
    end
end)

-- ─────────────────────────────────────────────────────
--  PLAYER HOOKS
-- ─────────────────────────────────────────────────────
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPForPlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    createESPForPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPForPlayer(player)
end)

-- ─────────────────────────────────────────────────────
--  MAIN RENDER LOOP
-- ─────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    local center = screenCenter()

    -- Ensure ESP for all current players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESPForPlayer(player)
        end
    end

    -- Get best target
    local targetPlayer, targetPart = nil, nil
    if Settings.AimEnabled then
        targetPlayer, targetPart = getBestTarget()
        CurrentTarget = targetPlayer
    else
        CurrentTarget = nil
    end

    -- FOV Circle
    fovCircle.Visible   = Settings.AimEnabled
    fovCircle.Position  = center
    fovCircle.Radius    = Settings.FOVRadius
    fovCircle.Color     = CurrentTarget and Settings.ColFOVLock or Settings.ColFOVIdle

    -- Lock Dot
    lockDot.Visible   = Settings.AimEnabled and (CurrentTarget ~= nil)
    lockDot.Position  = center

    -- Crosshair
    updateCrosshairFull()

    -- Aim
    if Settings.AimEnabled and targetPart then
        doAim(targetPart)
    end

    -- ESP per player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and espCache[player] then
            updateESP(player, player == CurrentTarget)
        end
    end
end)

-- ─────────────────────────────────────────────────────
--  CLEANUP ON COREGUI REMOVAL
-- ─────────────────────────────────────────────────────
screenGui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        destroyAll()
    end
end)

print("[Arceus Purple] Loaded – RightAlt to toggle panel.")

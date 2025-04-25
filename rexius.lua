-- Rexius UI Library v4.1.0 (Stable)
-- Author: YourName
-- Description: Robust, modular Roblox UI Library with full widget support, customizable themes, mobile gestures, enhanced error handling, and config persistence.

-- Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

-- Module
local Rexius = {}
Rexius.__index = Rexius

-- Safe call utility
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[RexiusUI] Callback error: " .. tostring(err)) end
end

-- Default Config
Rexius.Config = {
    Title       = "Rexius UI",
    Subtitle    = "by Rexius",
    Theme       = "Dark",
    Watermark   = "Rexius",
    SplashTime  = 1.5,
    Blur        = true,
    AutoSave    = true,
    ConfigFile  = "RexiusConfig",
}

-- Built-in Themes
local DefaultThemes = {
    Dark = {BG = Color3.fromRGB(30,30,35), AC = Color3.fromRGB(200,50,200), Text = Color3.new(1,1,1)},
    Light = {BG = Color3.fromRGB(245,245,245), AC = Color3.fromRGB(100,100,100), Text = Color3.new(0,0,0)},
}

-- Theme registry
Rexius.Themes = {}
for name, theme in pairs(DefaultThemes) do
    Rexius.Themes[name] = theme
end

-- Merge tables
local function merge(dest, src)
    for k,v in pairs(src) do
        if type(v)=="table" and type(dest[k])=="table" then
            merge(dest[k], v)
        else
            dest[k] = v
        end
    end
end

-- Drag & Gesture Helpers
local function applyDrag(frame, handle)
    handle = handle or frame
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startInput = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function applySwipeToClose(frame, callback)
    local origin
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then origin = inp.Position end
    end)
    frame.InputEnded:Connect(function(inp)
        if origin and inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - origin
            if delta.X > 100 then safeCall(callback) end
            origin = nil
        end
    end)
end

-- Splash Screen
function Rexius:_splash()
    local cfg = self._config
    local theme = self._theme
    local gui = Instance.new("ScreenGui")
    gui.Name = "RexiusSplash"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.fromOffset(400, 100)
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.fromScale(0.5,0.5)
    frame.BackgroundColor3 = theme.BG
    frame.BackgroundTransparency = 1
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.fromScale(1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 36
    title.Text = cfg.Watermark
    title.TextColor3 = theme.AC
    title.BackgroundTransparency = 1
    title.TextTransparency = 1

    TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.delay(cfg.SplashTime, function() gui:Destroy() end)
end

-- Notification Toast
function Rexius:Notify(opts)
    safeCall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "RexiusToast"
        gui.ResetOnSpawn = false
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

        local f = Instance.new("Frame", gui)
        f.Size = UDim2.fromOffset(300,80)
        f.AnchorPoint = Vector2.new(1,1)
        f.Position = UDim2.new(1,-20,1,-20)
        f.BackgroundColor3 = self._theme.BG
        f.BackgroundTransparency = 1
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,12)

        local t = Instance.new("TextLabel", f)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 18
        t.Text = opts.Title or "Notice"
        t.TextColor3 = self._theme.Text
        t.BackgroundTransparency = 1
        t.Position = UDim2.fromOffset(12,8)

        local l = Instance.new("TextLabel", f)
        l.Font = Enum.Font.Gotham
        l.TextSize = 14
        l.Text = opts.Text or ""
        l.TextColor3 = self._theme.Text
        l.BackgroundTransparency = 1
        l.Position = UDim2.fromOffset(12,36)

        TweenService:Create(f, TweenInfo.new(0.3), {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(t, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        TweenService:Create(l, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        task.delay(opts.Duration or 3, function() gui:Destroy() end)
    end)
end

-- Config Persistence
function Rexius:SaveConfig(data)
    if not self._config.AutoSave then return end
    safeCall(function()
        writefile(self._config.ConfigFile .. ".json", HttpService:JSONEncode(data))
    end)
end

function Rexius:LoadConfig()
    if not self._config.AutoSave then return {} end
    local content
    safeCall(function() content = readfile(self._config.ConfigFile .. ".json") end)
    if content then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, content)
        if ok and type(data)=="table" then return data end
    end
    return {}
end

-- Register Custom Theme
function Rexius:RegisterTheme(name, themeTable)
    assert(type(name)=="string" and type(themeTable)=="table", "Invalid theme registration")
    Rexius.Themes[name] = themeTable
end

-- Create Main Window
function Rexius:CreateWindow(opts)
    local cfg = {}
    merge(cfg, Rexius.Config)
    merge(cfg, opts or {})

    local theme = Rexius.Themes[cfg.Theme]
    if not theme then warn("[RexiusUI] Theme '"..cfg.Theme.."' not found, using 'Dark'.") end
    self._config = cfg
    self._theme = theme or Rexius.Themes.Dark

    -- Splash & Blur
    self:_splash()
    if cfg.Blur then
        local blur = Instance.new("BlurEffect", workspace.CurrentCamera)
        blur.Size = 0
        TweenService:Create(blur, TweenInfo.new(0.5), {Size = 8}):Play()
        self._blur = blur
    end

    -- GUI Container
    local gui = Instance.new("ScreenGui")
    gui.Name = "RexiusUI"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Main Frame
    local main = Instance.new("Frame", gui)
    main.Name = "Main"
    main.Size = UDim2.fromOffset(480,530)
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.Position = UDim2.fromScale(0.5,0.5)
    main.BackgroundColor3 = self._theme.BG
    main.BackgroundTransparency = 1
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,20)
    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 2; stroke.Transparency = 0.6
    applyDrag(main)
    applySwipeToClose(main, function() self:Destroy() end)

    -- Header
    local header = Instance.new("Frame", main)
    header.Size = UDim2.fromOffset(480,60)
    header.BackgroundTransparency = 1

    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Text = cfg.Title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 28
    titleLbl.TextColor3 = self._theme.Text
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.fromOffset(20,12)

    local subtitleLbl = Instance.new("TextLabel", header)
    subtitleLbl.Text = cfg.Subtitle
    subtitleLbl.Font = Enum.Font.Gotham
    subtitleLbl.TextSize = 16
    subtitleLbl.TextColor3 = self._theme.Text
    subtitleLbl.BackgroundTransparency = 1
    subtitleLbl.Position = UDim2.fromOffset(20,40)

    -- Controls (Close, Minimize)
    local function makeControl(sym, offset, act)
        local btn = Instance.new("TextButton", header)
        btn.Text = sym; btn.Font = Enum.Font.GothamBold; btn.TextSize = 20
        btn.TextColor3 = self._theme.Text; btn.BackgroundColor3 = self._theme.BG
        btn.Size = UDim2.fromOffset(32,32)
        btn.Position = UDim2.new(1, -offset, 0, 14)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        btn.MouseButton1Click:Connect(act)
    end
    makeControl("X", 40, function() self:Destroy() end)
    makeControl("_", 80, function() main.Visible = false; if self._blur then self._blur.Size = 0 end end)

    -- Sidebar & Pages
    local sidebar = Instance.new("Frame", main)
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.fromOffset(20,80)
    sidebar.Size = UDim2.fromOffset(160,430)
    sidebar.BackgroundTransparency = 1
    Instance.new("UIListLayout", sidebar).Padding = UDim.new(0,12)

    local pages = Instance.new("Frame", main)
    pages.Name = "Pages"
    pages.Position = UDim2.fromOffset(200,80)
    pages.Size = UDim2.new(1, -220, 1, -100)
    pages.BackgroundTransparency = 1

    TweenService:Create(main, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()

    -- Window object
    local window = setmetatable({
        _gui = gui,
        _main = main,
        _sidebar = sidebar,
        _pages = pages,
        _tabs = {},
        _theme = self._theme,
        _config = cfg,
        _blur = self._blur,
    }, Rexius)
    return window
end

-- Create Tab and Widgets
function Rexius:CreateTab(name)
    local btn = Instance.new("TextButton", self._sidebar)
    btn.Text = name; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 18
    btn.TextColor3 = self._theme.Text; btn.BackgroundColor3 = self._theme.AC
    btn.Size = UDim2.new(1,0,0,44); btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    local frame = Instance.new("Frame", self._pages)
    frame.Name = name; frame.Size = UDim2.new(1,0,1,0); frame.Visible = false
    frame.BackgroundTransparency = 1
    Instance.new("UIListLayout", frame).Padding = UDim.new(0,12)

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(self._tabs) do t[2].Visible = false end
        frame.Visible = true
    end)
    table.insert(self._tabs, {btn, frame})
    if #self._tabs == 1 then btn:CaptureFocus(); btn.MouseButton1Click() end

    local tab = {}
    -- Button
    function tab:AddButton(text, cb)
        local okButton = Instance.new("TextButton", frame)
        okButton.Text = text; okButton.Font = Enum.Font.Gotham; okButton.TextSize = 16
        okButton.TextColor3 = self._theme.Text; okButton.BackgroundColor3 = self._theme.AC
        okButton.Size = UDim2.new(1,0,0,36); okButton.AutoButtonColor = false
        Instance.new("UICorner", okButton).CornerRadius = UDim.new(0,8)
        okButton.MouseButton1Click:Connect(function() safeCall(cb) end)
    end
    -- Toggle
    function tab:AddToggle(text, default, cb)
        local f = Instance.new("Frame", frame)
        f.Size = UDim2.new(1,0,0,36); f.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", f)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 16
        lbl.TextColor3 = self._theme.Text; lbl.Position = UDim2.fromOffset(4,0)
        lbl.Size = UDim2.new(0.7,0,1,0)
        local btn = Instance.new("TextButton", f)
        btn.Text = default and "ON" or "OFF"; btn.Font = Enum.Font.GothamBold; btn.TextSize = 14
        btn.Size = UDim2.new(0.28,0,0.6,0); btn.Position = UDim2.new(0.72,0,0.2,0)
        btn.BackgroundColor3 = self._theme.AC; btn.TextColor3 = self._theme.Text; btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state; btn.Text = state and "ON" or "OFF"; safeCall(cb, state)
        end)
    end
    -- Slider
    function tab:AddSlider(text, min, max, default, cb)
        local f = Instance.new("Frame", frame)
        f.Size = UDim2.new(1,0,0,50); f.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", f)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
        lbl.TextColor3 = self._theme.Text; lbl.Position = UDim2.fromOffset(0,0)
        lbl.Size = UDim2.new(1,0,0,16)
        local track = Instance.new("Frame", f)
        track.Size = UDim2.new(1,0,0,8); track.Position = UDim2.fromOffset(0,32)
        track.BackgroundColor3 = self._theme.AC; Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.new((default-min)/(max-min),0,1,0)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local dragging = false
        knob.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
        knob.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                local rel = math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
                knob.Size = UDim2.new(rel,0,1,0)
                safeCall(cb, min + rel*(max-min))
            end
        end)
    end
    -- Dropdown
    function tab:AddDropdown(text, options, cb)
        local f = Instance.new("Frame", frame)
        f.Size = UDim2.new(1,0,0,36); f.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", f)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
        lbl.TextColor3 = self._theme.Text; lbl.Position = UDim2.fromOffset(0,0)
        lbl.Size = UDim2.new(1,0,0,16)
        local btn = Instance.new("TextButton", f)
        btn.Text = "▼"; btn.Font = Enum.Font.Gotham; btn.TextSize = 14
        btn.Size = UDim2.fromOffset(24,24); btn.Position = UDim2.new(1,-24,0,6)
        btn.BackgroundColor3 = self._theme.AC; btn.TextColor3 = self._theme.Text; btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        local list = Instance.new("Frame", f)
        list.Visible = false; list.BackgroundColor3 = self._theme.BG
        list.Position = UDim2.new(0,0,1,4); list.Size = UDim2.new(1,0,0,#options*24)
        Instance.new("UICorner", list).CornerRadius = UDim.new(0,8)
        for i,v in ipairs(options) do
            local it = Instance.new("TextButton", list)
            it.Text = v; it.Font = Enum.Font.Gotham; it.TextSize = 14
            it.Position = UDim2.fromOffset(0,(i-1)*24); it.Size = UDim2.new(1,0,0,24)
            it.BackgroundTransparency = 1; it.TextColor3 = self._theme.Text; it.AutoButtonColor = false
            it.MouseButton1Click:Connect(function()
                safeCall(cb, v)
                list.Visible = false
            end)
        end
        btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    end
    -- Textbox
    function tab:AddTextbox(text, placeholder, cb)
        local f = Instance.new("Frame", frame)
        f.Size = UDim2.new(1,0,0,50); f.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", f)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
        lbl.TextColor3 = self._theme.Text; lbl.Position = UDim2.fromOffset(0,0)
        lbl.Size = UDim2.new(1,0,0,16)
        local box = Instance.new("TextBox", f)
        box.PlaceholderText = placeholder or ""; box.Font = Enum.Font.Gotham; box.TextSize = 14
        box.Position = UDim2.fromOffset(0,18); box.Size = UDim2.new(1,0,0,28)
        box.BackgroundColor3 = self._theme.AC; box.TextColor3 = self._theme.Text
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
        box.FocusLost:Connect(function(enter) if enter then safeCall(cb, box.Text) end end)
    end

    return tab
end

-- Destroy UI
function Rexius:Destroy()
    if self._blur then pcall(function() self._blur:Destroy() end) end
    if self._gui then pcall(function() self._gui:Destroy() end) end
end

return Rexius

-- Rexius UI Library v2.1.1 (Fixed CreateTab)
-- Author: YourName
-- Description: Professional & feature-complete Roblox UI Library with minimize, loading, themes, config, key/premium, and fixed tab system.

-- Services
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Module
local Rexius = {}
Rexius.__index = Rexius

-- Themes
local Themes = {
    DarkPurple = { Background = Color3.fromRGB(20,20,30), Accent = Color3.fromRGB(170,0,255), Text = Color3.fromRGB(255,255,255) },
    LightMode   = { Background = Color3.fromRGB(245,245,245), Accent = Color3.fromRGB(60,60,60), Text = Color3.fromRGB(0,0,0) },
    CyberBlue   = { Background = Color3.fromRGB(10,10,35), Accent = Color3.fromRGB(0,170,255), Text = Color3.fromRGB(255,255,255) }
}

-- Default Config
local DefaultConfig = {
    Theme           = "DarkPurple",
    Watermark       = "Rexius",
    BlurBackground  = true,
    KeySystem       = { Enabled = false, Discord = "", KeyURL = "", PremiumUserIds = {} },
    AutoSave        = true,
    ConfigFileName  = "RexiusConfig"
}

-- Utility: Deep Merge
local function merge(dest, src)
    for k,v in pairs(src) do
        if type(v)=="table" and type(dest[k])=="table" then merge(dest[k], v)
        else dest[k] = v end
    end
end

-- Drag Behavior
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                        startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Save & Load Config
function Rexius:SaveConfig(data)
    if not self._config.AutoSave then return end
    local ok, err = pcall(writefile, self._config.ConfigFileName..".json", HttpService:JSONEncode(data))
    if not ok then warn("SaveConfig failed:", err) end
end
function Rexius:LoadConfig()
    if not self._config.AutoSave then return {} end
    local ok, content = pcall(readfile, self._config.ConfigFileName..".json")
    if ok then return HttpService:JSONDecode(content) end
    return {}
end

-- Theme & Destruction
function Rexius:SetTheme(name)
    local th = Themes[name] or name
    if type(th)=="string" then th = Themes[th] end
    if not th then return end
    self._theme = th
    for _, elem in pairs(self._elements) do
        if elem:IsA("Frame") then elem.BackgroundColor3 = th.Background
        elseif elem:IsA("TextLabel") or elem:IsA("TextButton") then elem.TextColor3 = th.Text end
    end
end
function Rexius:Destroy()
    if self._blur then TweenService:Create(self._blur, TweenInfo.new(0.3), {Size = 0}):Play(); task.delay(0.35, function() self._blur:Destroy() end) end
    self._screen:Destroy()
end

-- Notification
function Rexius:Notification(opts)
    local title, text, dur = opts.Title or "Notification", opts.Text or "...", opts.Duration or 3
    local gui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui")); gui.Name = "RexiusNotif"
    local frame = Instance.new("Frame", gui)
    frame.AnchorPoint = Vector2.new(1,1); frame.Position = UDim2.new(1,-20,1,-20)
    frame.Size = UDim2.new(0,300,0,80); frame.BackgroundTransparency = 1
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
    local ttl = Instance.new("TextLabel", frame)
    ttl.Font = Enum.Font.GothamBold; ttl.TextSize = 18; ttl.Text = title; ttl.BackgroundTransparency = 1
    ttl.Position = UDim2.new(0,12,0,8); ttl.Size = UDim2.new(1,-24,0,24)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.Text = text; lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0,12,0,36); lbl.Size = UDim2.new(1,-24,0,36)
    TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency=0.1}):Play()
    TweenService:Create(ttl, TweenInfo.new(0.3), {TextTransparency=0}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.3), {TextTransparency=0}):Play()
    task.delay(dur, function()
        TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
        TweenService:Create(ttl, TweenInfo.new(0.3), {TextTransparency=1}):Play()
        TweenService:Create(lbl, TweenInfo.new(0.3), {TextTransparency=1}):Play()
        task.delay(0.35, function() gui:Destroy() end)
    end)
end

-- Create Window with Minimize & Loading
function Rexius:CreateWindow(opts)
    local cfg = {}; merge(cfg, DefaultConfig); merge(cfg, opts)
    self._config = cfg; self._elements = {}
    -- Theme
    local theme = Themes[cfg.Theme] or cfg.Theme or Themes.DarkPurple
    if type(theme)=="string" then theme = Themes[theme] end
    self._theme = theme
    -- ScreenGui & Blur
    local gui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui")); gui.Name="RexiusUI"
    if cfg.BlurBackground then
        local blur = Instance.new("BlurEffect", workspace.CurrentCamera); blur.Name="RexiusBlur"; blur.Size=0
        TweenService:Create(blur, TweenInfo.new(0.5), {Size=8}):Play(); self._blur = blur
    end
    -- Main Frame
    local main = Instance.new("Frame", gui); main.Name="Main";
    main.Size=UDim2.new(0,400,0,480); main.AnchorPoint=Vector2.new(0.5,0.5)
    main.Position=UDim2.new(0.5,0.5); main.BackgroundColor3=theme.Background; main.BackgroundTransparency=1
    Instance.new("UICorner", main).CornerRadius=UDim.new(0,18)
    Instance.new("UIStroke", main).Thickness=2; self._elements[#self._elements+1]=main
    makeDraggable(main)
    -- Store original size/pos for minimize
    self._origSize, self._origPos = main.Size, main.Position; self._minimized = false
    -- Loader Bar
    local loader = Instance.new("Frame", main); loader.Name="Loader"
    loader.Size=UDim2.new(0,0,0,4); loader.Position=UDim2.new(0,0,0,0)
    loader.BackgroundColor3=theme.Accent; Instance.new("UICorner", loader).CornerRadius=UDim.new(1,0)
    TweenService:Create(loader, TweenInfo.new(1, Enum.EasingStyle.Quad), {Size=UDim2.new(1,0,0,4)}):Play()
    TweenService:Create(loader, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1), {BackgroundTransparency=1}):Play()
    task.delay(1.3, function() loader:Destroy() end)
    -- Title & Subtitle & Watermark
    local title = Instance.new("TextLabel", main)
    title.Font=Enum.Font.GothamBold; title.TextSize=24; title.Text=cfg.Title or "Rexius UI"
    title.Position=UDim2.new(0,16,0,16); title.Size=UDim2.new(1,-64,0,30)
    title.TextColor3=theme.Text; title.BackgroundTransparency=1; self._elements[#self._elements+1]=title
    local subtitle = Instance.new("TextLabel", main)
    subtitle.Font=Enum.Font.Gotham; subtitle.TextSize=14; subtitle.Text=cfg.Subtitle or "by Rexius"
    subtitle.Position=UDim2.new(0,16,0,48); subtitle.Size=UDim2.new(1,-64,0,20)
    subtitle.TextColor3=theme.Text; subtitle.BackgroundTransparency=1; self._elements[#self._elements+1]=subtitle
    local wm=Instance.new("TextLabel", main)
    wm.AnchorPoint=Vector2.new(1,1); wm.Text=cfg.Watermark; wm.Font=Enum.Font.Gotham; wm.TextSize=12
    wm.Position=UDim2.new(1,-12,1,-12); wm.Size=UDim2.new(0,100,0,16)
    wm.TextColor3=theme.Accent; wm.BackgroundTransparency=1; wm.TextXAlignment=Enum.TextXAlignment.Right
    self._elements[#self._elements+1]=wm
    -- Minimize Button
    local minBtn=Instance.new("TextButton", main)
    minBtn.Name="Minimize"; minBtn.Text="_"; minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=18
    minBtn.Size=UDim2.new(0,24,0,24); minBtn.Position=UDim2.new(1,-40,0,8)
    minBtn.AutoButtonColor=false; minBtn.BackgroundColor3=theme.Background; minBtn.TextColor3=theme.Text
    Instance.new("UICorner", minBtn).CornerRadius=UDim.new(0,4)
    minBtn.MouseButton1Click:Connect(function()
        if not self._minimized then
            TweenService:Create(main, TweenInfo.new(0.3), {Size=UDim2.new(0,200,0,36)}):Play()
            self._btnContainer.Visible = false; self._pageContainer.Visible = false
        else
            TweenService:Create(main, TweenInfo.new(0.3), {Size=self._origSize}):Play()
            self._btnContainer.Visible = true; self._pageContainer.Visible = true
        end
        self._minimized = not self._minimized
    end)
    self._elements[#self._elements+1]=minBtn
    -- Containers
    local btnContainer=Instance.new("Frame", main)
    btnContainer.Name="TabButtons"; btnContainer.Position=UDim2.new(0,16,0,80)
    btnContainer.Size=UDim2.new(0,120,1,-96); btnContainer.BackgroundTransparency=1
    Instance.new("UIListLayout", btnContainer).Padding=UDim.new(0,8)
    local pageContainer=Instance.new("Frame", main)
    pageContainer.Name="Pages"; pageContainer.Position=UDim2.new(0,152,0,80)
    pageContainer.Size=UDim2.new(1,-168,1,-96); pageContainer.BackgroundTransparency=1
    self._btnContainer, self._pageContainer = btnContainer, pageContainer
    TweenService:Create(main, TweenInfo.new(0.4), {BackgroundTransparency=0}):Play()
    -- Return window
    return setmetatable({
        _screen=gui, _main=main, _tabs={}, _theme=theme,
        _config=cfg, _elements=self._elements,
        _btnContainer=btnContainer, _pageContainer=pageContainer
    }, Rexius)
end

-- Create Tab (fixed)
function Rexius:CreateTab(name)
    self._tabCount = (self._tabCount or 0) + 1
    local btn = Instance.new("TextButton", self._btnContainer)
    btn.Text = name; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 16
    btn.Size = UDim2.new(1,0,0,36); btn.AutoButtonColor = false
    btn.BackgroundColor3 = self._theme.Accent; btn.TextColor3 = self._theme.Text
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local page = Instance.new("Frame", self._pageContainer)
    page.Name = name; page.Size = UDim2.new(1,0,1,0); page.Visible = false; page.BackgroundTransparency = 1
    Instance.new("UIListLayout", page).Padding = UDim.new(0,8)
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(self._tabs) do t.page.Visible = false end
        page.Visible = true
    end)
    self._tabs[name] = { button = btn, page = page }
    if self._tabCount == 1 then
        btn:CaptureFocus()
        btn.MouseButton1Click()
    end
    local tab = {}
    function tab:AddButton(text, cb)
        local b = Instance.new("TextButton", page)
        b.Text = text; b.Font = Enum.Font.Gotham; b.TextSize = 16; b.Size = UDim2.new(1,0,0,36)
        b.AutoButtonColor = false; b.BackgroundColor3 = self._theme.Accent; b.TextColor3 = self._theme.Text
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        b.MouseButton1Click:Connect(cb)
    end
    function tab:AddToggle(text, default, cb)
        local frame = Instance.new("Frame", page); frame.Size = UDim2.new(1,0,0,36); frame.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", frame);
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 16; lbl.TextColor3 = self._theme.Text
        lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0,4,0,0); lbl.Size = UDim2.new(0.7,0,1,0)
        local btn2 = Instance.new("TextButton", frame)
        btn2.Text = default and "ON" or "OFF"; btn2.Font = Enum.Font.GothamBold; btn2.TextSize = 14
        btn2.Size = UDim2.new(0.28,0,0.6,0); btn2.Position = UDim2.new(0.72,0,0.2,0)
        btn2.AutoButtonColor = false; btn2.BackgroundColor3 = self._theme.Accent; btn2.TextColor3 = self._theme.Text
        Instance.new("UICorner", btn2).CornerRadius = UDim.new(0,8)
        local state = default
        btn2.MouseButton1Click:Connect(function()
            state = not state; btn2.Text = state and "ON" or "OFF"; cb(state)
        end)
    end
    function tab:AddSlider(text, min, max, default, cb)
        local frame = Instance.new("Frame", page); frame.Size=UDim2.new(1,0,0,32); frame.BackgroundTransparency=1
        local lbl = Instance.new("TextLabel", frame)
        lbl.Text = text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14; lbl.TextColor3 = self._theme.Text
        lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0,0,0,0); lbl.Size = UDim2.new(1,0,0,16)
        local track = Instance.new("Frame", frame);
        track.Size = UDim2.new(1,0,0,8); track.Position=UDim2.new(0,0,0,24)
        track.BackgroundColor3 = self._theme.Accent; Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame", track);
        knob.Size = UDim2.new((default-min)/(max-min),0,1,0); Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local dragging = false
        knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
        knob.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                local rel = math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                knob.Size = UDim2.new(rel,0,1,0); cb(min + rel*(max-min))
            end
        end)
    end
    function tab:AddDropdown(text, options, cb)
        local frame = Instance.new("Frame", page); frame.Size=UDim2.new(1,0,0,36); frame.BackgroundTransparency=1
        local lbl = Instance.new("TextLabel", frame)
        lbl.Text = text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14; lbl.TextColor3 = self._theme.Text
        lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0,0,0,0); lbl.Size = UDim2.new(1,0,0,16)
        local btn3 = Instance.new("TextButton", frame)
        btn3.Text = "▼"; btn3.Font=Enum.Font.Gotham; btn3.TextSize=14
        btn3.Size=UDim2.new(0,24,0,24); btn3.Position=UDim2.new(1,-24,0,6)
        btn3.AutoButtonColor=false; btn3.BackgroundColor3=self._theme.Accent; btn3.TextColor3=self._theme.Text
        Instance.new("UICorner", btn3).CornerRadius=UDim.new(0,4)
        local list = Instance.new("Frame", frame); list.Visible=false; list.BackgroundColor3=self._theme.Background
        list.Position=UDim2.new(0,0,1,4); list.Size=UDim2.new(1,0,0,#options*24)
        Instance.new("UICorner", list).CornerRadius=UDim.new(0,8)
        for i,opt in ipairs(options) do
            local it = Instance.new("TextButton", list)
            it.Text=opt; it.Font=Enum.Font.Gotham; it.TextSize=14; it.Size=UDim2.new(1,0,0,24)
            it.Position=UDim2.new(0,0,0,(i-1)*24); it.BackgroundTransparency=1; it.TextColor3=self._theme.Text
            it.AutoButtonColor=false
            it.MouseButton1Click:Connect(function() cb(opt); list.Visible=false end)
        end
        btn3.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    end
    function tab:AddTextbox(text, placeholder, cb)
        local frame = Instance.new("Frame", page); frame.Size=UDim2.new(1,0,0,40); frame.BackgroundTransparency=1
        local lbl = Instance.new("TextLabel", frame)
        lbl.Text = text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14; lbl.TextColor3=self._theme.Text
        lbl.BackgroundTransparency = 1; lbl.Position=UDim2.new(0,0,0,0); lbl.Size=UDim2.new(1,0,0,16)
        local box = Instance.new("TextBox", frame)
        box.PlaceholderText = placeholder or ""; box.Font=Enum.Font.Gotham; box.TextSize=14
        box.Size = UDim2.new(1,0,0,20); box.Position = UDim2.new(0,0,0,18)
        box.BackgroundColor3 = self._theme.Accent; box.TextColor3 = self._theme.Text
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
        box.FocusLost:Connect(function(enter) if enter then cb(box.Text) end end)
    end
    return setmetatable(tab, { __index = self })
end

-- Check Premium
function Rexius:IsPremium()
    return table.find(self._config.KeySystem.PremiumUserIds or {}, Players.LocalPlayer.UserId)~=nil
end

return Rexius

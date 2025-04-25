-- Rexius UI Library v1.2.0 (beta)
-- Author: Mizu Verse


local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")


local Rexius = {}
Rexius.__index = Rexius


local Themes = {
    DarkPurple = { Background = Color3.fromRGB(18,18,26), Accent = Color3.fromRGB(170,0,255), Text = Color3.fromRGB(255,255,255) },
    LightMode   = { Background = Color3.fromRGB(245,245,245), Accent = Color3.fromRGB(60,60,60), Text = Color3.fromRGB(0,0,0) },
    CyberBlue   = { Background = Color3.fromRGB(10,10,30), Accent = Color3.fromRGB(0,170,255), Text = Color3.fromRGB(255,255,255) }
}


local DefaultConfig = {
    Theme           = "DarkPurple",
    Watermark       = "Rexius",
    BlurBackground  = true,
    KeySystem       = { Enabled = false, Discord = "", KeyURL = "", PremiumUserIds = {} },
    AutoSave        = true,
    ConfigFileName  = "RexiusConfig"
}


local function merge(dest, src)
    for k,v in pairs(src) do
        if type(v)=="table" and type(dest[k])=="table" then
            merge(dest[k], v)
        else dest[k] = v end
    end
end


local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end


function Rexius:Notification(opts)
    local opts = opts or {}
    local title = opts.Title or "Notification"
    local text  = opts.Text or "..."
    local dur   = opts.Duration or 3
    local gui = Instance.new("ScreenGui") gui.Name = "RexiusNotification" gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,300,0,80); frame.Position = UDim2.new(1,-320,1,-100)
    frame.BackgroundColor3 = self._theme.Background; frame.BackgroundTransparency = 0.1
    frame.ZIndex = 1000; frame.AnchorPoint = Vector2.new(1,1)
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,12)
    local ttl = Instance.new("TextLabel", frame)
    ttl.Text = title; ttl.Font=Enum.Font.GothamBold; ttl.TextSize=18
    ttl.TextColor3 = self._theme.Text; ttl.BackgroundTransparency=1
    ttl.Position = UDim2.new(0,12,0,8); ttl.Size=UDim2.new(1,-24,0,24)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14
    lbl.TextColor3 = self._theme.Text; lbl.BackgroundTransparency=1
    lbl.Position = UDim2.new(0,12,0,36); lbl.Size=UDim2.new(1,-24,0,36)
    -- Fade in & out
    frame.BackgroundTransparency = 1; ttl.TextTransparency, lbl.TextTransparency = 1,1
    TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency=0.1}):Play()
    TweenService:Create(ttl, TweenInfo.new(0.3), {TextTransparency=0}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.3), {TextTransparency=0}):Play()
    delay(dur, function()
        TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
        TweenService:Create(ttl, TweenInfo.new(0.3), {TextTransparency=1}):Play()
        TweenService:Create(lbl, TweenInfo.new(0.3), {TextTransparency=1}):Play()
        delay(0.35, function() gui:Destroy() end)
    end)
end


function Rexius:CreateWindow(opts)
    assert(typeof(opts)=="table","CreateWindow requires options table")
    local cfg = {}
    merge(cfg, DefaultConfig)
    merge(cfg, opts)
    
    local theme = Themes[cfg.Theme] or cfg.Theme or Themes.DarkPurple
    if type(theme)=="string" then theme = Themes[theme] or Themes.DarkPurple end

    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RexiusUI"; screenGui.ResetOnSpawn=false
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    
    if cfg.BlurBackground then
        local blur = Instance.new("BlurEffect", workspace.CurrentCamera)
        blur.Name = "RexiusBlur"; blur.Size = 0
        TweenService:Create(blur, TweenInfo.new(0.5), {Size=12}):Play()
    end

    
    local main = Instance.new("Frame")
    main.Name = "Main"; main.Size=UDim2.new(0,400,0,500)
    main.AnchorPoint=Vector2.new(0.5,0.5)
    main.Position=UDim2.new(0.5,0,0.5,0)
    main.BackgroundColor3=theme.Background; main.BackgroundTransparency=1
    main.Parent=screenGui
    makeDraggable(main)

    
    local corner=Instance.new("UICorner",main); corner.CornerRadius=UDim.new(0,16)
    local shadow=Instance.new("UIStroke",main); shadow.Thickness=2; shadow.Transparency=0.8

    
    local title=Instance.new("TextLabel",main)
    title.Name="Title"; title.Text=cfg.Title or "Rexius UI"
    title.Font=Enum.Font.GothamBold; title.TextSize=24; title.TextColor3=theme.Text
    title.BackgroundTransparency=1; title.Position=UDim2.new(0,16,0,16); title.Size=UDim2.new(1,-32,0,30)

    
    local subtitle=Instance.new("TextLabel",main)
    subtitle.Name="Subtitle"; subtitle.Text=cfg.Subtitle or "by Rexius"
    subtitle.Font=Enum.Font.Gotham; subtitle.TextSize=14; subtitle.TextColor3=theme.Text
    subtitle.BackgroundTransparency=1; subtitle.Position=UDim2.new(0,16,0,48); subtitle.Size=UDim2.new(1,-32,0,20)

    
    local wm=Instance.new("TextLabel",main)
    wm.Name="Watermark"; wm.Text=cfg.Watermark or "Rexius"
    wm.Font=Enum.Font.Gotham; wm.TextSize=12; wm.TextColor3=theme.Accent
    wm.BackgroundTransparency=1; wm.AnchorPoint=Vector2.new(1,1)
    wm.Position=UDim2.new(1,-12,1,-12); wm.Size=UDim2.new(0,80,0,16)
    wm.TextXAlignment=Enum.TextXAlignment.Right

    
    local tabList=Instance.new("Frame",main)
    tabList.Name="TabButtons"; tabList.BackgroundTransparency=1
    tabList.Position=UDim2.new(0,16,0,80); tabList.Size=UDim2.new(0,120,1,-96)
    local listLayout=Instance.new("UIListLayout",tabList); listLayout.Padding=UDim.new(0,8)

    local tabsContainer=Instance.new("Frame",main)
    tabsContainer.Name="Tabs"; tabsContainer.BackgroundTransparency=1
    tabsContainer.Position=UDim2.new(0,152,0,80); tabsContainer.Size=UDim2.new(1,-168,1,-96)

    
    TweenService:Create(main, TweenInfo.new(0.5), {BackgroundTransparency=0}):Play()

    
    function Rexius:SaveConfig(name, data)
        if not cfg.AutoSave then return end
        local ok, err = pcall(writefile, name..".json", HttpService:JSONEncode(data))
        if not ok then warn("SaveConfig failed:",err) end
    end
    function Rexius:LoadConfig(name)
        if not cfg.AutoSave then return {} end
        local ok, content = pcall(readfile, name..".json")
        if ok then return HttpService:JSONDecode(content) end
        return {}
    end

  
    if cfg.KeySystem.Enabled then
        local pop=Instance.new("Frame",main)
        pop.Name="KeyPopup"; pop.Size=UDim2.new(1, -40,0,120)
        pop.Position=UDim2.new(0,20,0,200); pop.BackgroundColor3=theme.Background; pop.BackgroundTransparency=0
        local c=Instance.new("UICorner",pop); c.CornerRadius=UDim.new(0,12)
        local lbl=Instance.new("TextLabel",pop)
        lbl.Text="Enter Access Key:"; lbl.Font=Enum.Font.Gotham; lbl.TextSize=18
        lbl.TextColor3=theme.Text; lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,12,0,12)
        local box=Instance.new("TextBox",pop)
        box.PlaceholderText="Key..."; box.Font=Enum.Font.Gotham; box.TextSize=16
        box.TextColor3=theme.Text; box.BackgroundColor3=theme.Accent
        box.Size=UDim2.new(1,-48,0,32); box.Position=UDim2.new(0,12,0,44)
        local btn=Instance.new("TextButton",pop)
        btn.Text="Verify"; btn.Font=Enum.Font.GothamBold; btn.TextSize=14
        btn.TextColor3=theme.Text; btn.BackgroundColor3=theme.Accent
        btn.Size=UDim2.new(0,100,0,28); btn.Position=UDim2.new(1,-112,1,-36)
        local keyValid=false
        btn.MouseButton1Click:Connect(function()
            local success,resp=pcall(HttpService.GetAsync,HttpService,cfg.KeySystem.KeyURL..box.Text)
            keyValid = success and resp=="VALID"
            if keyValid then pop:Destroy(); self:Notification{Title="Success",Text="Key Verified",Duration=2}
            else self:Notification{Title="Error",Text="Invalid Key",Duration=2} end
        end)
        return setmetatable({ _screen=screenGui },Rexius)
    end

    
    local window = setmetatable({
        _screen = screenGui,
        _main = main,
        _tabButtons = tabList,
        _tabs = {},
        _theme = theme,
        _config = cfg
    }, Rexius)

    return window
end


function Rexius:CreateTab(name)
    assert(typeof(name)=="string","Tab name must be string")
    local btn = Instance.new("TextButton", self._tabButtons)
    btn.Text=name; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=16
    btn.TextColor3=self._theme.Text; btn.BackgroundColor3=self._theme.Background
    btn.Size=UDim2.new(1,0,0,36); btn.AutoButtonColor=false
    local uc=Instance.new("UICorner",btn); uc.CornerRadius=UDim.new(0,8)

    local content=Instance.new("Frame", self._main)
    content.Name=name; content.BackgroundTransparency=1; content.Visible=false
    content.Position=UDim2.new(0,152,0,80); content.Size=UDim2.new(1,-168,1,-96)
    local layout=Instance.new("UIListLayout",content); layout.Padding=UDim.new(0,8)

    btn.MouseButton1Click:Connect(function()
        for _,t in pairs(self._tabs) do t.content.Visible=false end
        content.Visible=true
    end)

    self._tabs[name] = { button=btn, content=content }
    if #self._tabs==1 then btn:CaptureFocus(); btn.MouseButton1Click() end

    
    local tab = {}
    function tab:AddButton(text, callback)
        local b=Instance.new("TextButton",content)
        b.Text=text; b.Font=Enum.Font.Gotham; b.TextSize=16; b.Size=UDim2.new(1,0,0,36)
        b.BackgroundColor3=self._theme and self._theme.Accent or Color3.new(); b.TextColor3=self._theme.Text
        b.AutoButtonColor=false; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
        b.MouseButton1Click:Connect(callback)
    end
    function tab:AddToggle(text, default, callback)
        local frame=Instance.new("Frame",content); frame.Size=UDim2.new(1,0,0,36)
        frame.BackgroundTransparency=1
        local lbl=Instance.new("TextLabel",frame)
        lbl.Text=text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=16
        lbl.TextColor3=self._theme.Text; lbl.BackgroundTransparency=1
        lbl.Position=UDim2.new(0,4,0,0); lbl.Size=UDim2.new(0.7,0,1,0)
        local btn=Instance.new("TextButton",frame)
        btn.Text=default and "ON" or "OFF"; btn.Font=Enum.Font.GothamBold; btn.TextSize=14
        btn.Size=UDim2.new(0.28,0,0.6,0); btn.Position=UDim2.new(0.72,0,0.2,0)
        btn.BackgroundColor3=self._theme.Accent; btn.TextColor3=self._theme.Text; btn.AutoButtonColor=false
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
        local state=default
        btn.MouseButton1Click:Connect(function()
            state=not state; btn.Text=state and "ON" or "OFF"; callback(state)
        end)
    end
    function tab:AddSlider(text, min, max, default, callback)
        local frame=Instance.new("Frame",content); frame.Size=UDim2.new(1,0,0,32); frame.BackgroundTransparency=1
        local lbl=Instance.new("TextLabel",frame)
        lbl.Text=text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14; lbl.TextColor3=self._theme.Text
        lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,0,0,0); lbl.Size=UDim2.new(1,0,0,16)
        
        local track=Instance.new("Frame",frame); track.Size=UDim2.new(1,0,0,8)
        track.Position=UDim2.new(0,0,0,24); track.BackgroundColor3=self._theme.Accent
        Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
        local knob=Instance.new("Frame",track); knob.Size=UDim2.new((default-min)/(max-min),0,1,0)
        local corner=Instance.new("UICorner",knob); corner.CornerRadius=UDim.new(1,0)
        
        local dragging=false
        knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
        knob.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                local rel = math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                knob.Size=UDim2.new(rel,0,1,0)
                callback(min + rel*(max-min))
            end
        end)
    end
    function tab:AddDropdown(text, list, callback)
        local frame=Instance.new("Frame",content); frame.Size=UDim2.new(1,0,0,32); frame.BackgroundTransparency=1
        local lbl=Instance.new("TextLabel",frame)
        lbl.Text=text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14; lbl.TextColor3=self._theme.Text
        lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,0,0,0); lbl.Size=UDim2.new(1,0,0,16)
        local btn=Instance.new("TextButton",frame)
        btn.Text="▼"; btn.Font=Enum.Font.Gotham; btn.TextSize=14; btn.Size=UDim2.new(0,24,0,24)
        btn.Position=UDim2.new(1,-24,0,8); btn.BackgroundColor3=self._theme.Accent; btn.TextColor3=self._theme.Text; btn.AutoButtonColor=false
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
        local dropdown=Instance.new("Frame",frame); dropdown.Visible=false; dropdown.BackgroundColor3=self._theme.Background
        dropdown.Position=UDim2.new(0,0,1,4); dropdown.Size=UDim2.new(1,0,0,#list*24)
        Instance.new("UICorner",dropdown).CornerRadius=UDim.new(0,8)
        for i,v in ipairs(list) do
            local it=Instance.new("TextButton",dropdown)
            it.Text=v; it.Font=Enum.Font.Gotham; it.TextSize=14; it.Size=UDim2.new(1,0,0,24)
            it.Position=UDim2.new(0,0,0,(i-1)*24); it.BackgroundTransparency=1; it.TextColor3=self._theme.Text
            it.AutoButtonColor=false
            it.MouseButton1Click:Connect(function() callback(v); dropdown.Visible=false end)
        end
        btn.MouseButton1Click:Connect(function() dropdown.Visible=not dropdown.Visible end)
    end
    function tab:AddTextbox(text, placeholder, callback)
        local frame=Instance.new("Frame",content); frame.Size=UDim2.new(1,0,0,36); frame.BackgroundTransparency=1
        local lbl=Instance.new("TextLabel",frame)
        lbl.Text=text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=14; lbl.TextColor3=self._theme.Text
        lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,0,0,0); lbl.Size=UDim2.new(1,0,0,16)
        local box=Instance.new("TextBox",frame)
        box.PlaceholderText=placeholder or "..."; box.Font=Enum.Font.Gotham; box.TextSize=14
        box.TextColor3=self._theme.Text; box.BackgroundColor3=self._theme.Accent
        box.Size=UDim2.new(1,0,0,20); box.Position=UDim2.new(0,0,0,16)
        Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)
        box.FocusLost:Connect(function(enter) if enter then callback(box.Text) end end)
    end

    return tab
end


function Rexius:IsPremium(userId)
    return table.find(self._config.KeySystem.PremiumUserIds or {}, userId) ~= nil
end


return Rexius

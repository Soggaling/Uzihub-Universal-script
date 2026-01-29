local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

--// Services & Logic Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local locking = false

--// Window Setup
local Window = Library:CreateWindow({
    Title = "UZIHUB V1",
    Footer = "Press Right Alt to Hide",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

--// Tab Setup
local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
    Movement = Window:AddTab("Movement", "zap"),
    Settings = Window:AddTab("Settings", "settings"),
}

--// ==========================================
--// COMBAT TAB (Aimbot & Integrated ESP)
--// ==========================================
local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Combat Module")

AimbotGroup:AddToggle("AimbotToggle", { 
    Text = "Aimbot + ESP", 
    Default = false, 
    Tooltip = "Enable locking and rainbow visuals" 
})

AimbotGroup:AddLabel("Aimbot: Hold Right Click")
AimbotGroup:AddLabel("ESP: Rainbow Tracer/Text/Highlight")

local function isFFA() return #game:GetService("Teams"):GetTeams() <= 1 end
local function isEnemy(p) 
    if not p or p == LocalPlayer or not p.Character then return false end
    return isFFA() or p.Team ~= LocalPlayer.Team 
end

local function validateTarget(part)
    local char = part.Parent
    if not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local res = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return res == nil or res.Instance:IsDescendantOf(char)
end

--// ==========================================
--// MOVEMENT TAB
--// ==========================================
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Physical Mods")
MoveGroup:AddToggle("SpeedToggle", { Text = "Enable Speed", Default = false })
MoveGroup:AddSlider("WalkSpeed", { Text = "WalkSpeed Value", Default = 16, Min = 16, Max = 300, Rounding = 0 })
MoveGroup:AddDivider()
MoveGroup:AddToggle("JumpToggle", { Text = "Enable Jump", Default = false })
MoveGroup:AddSlider("JumpPower", { Text = "JumpPower Value", Default = 50, Min = 50, Max = 500, Rounding = 0 })

local FlyGroup = Tabs.Movement:AddRightGroupbox("Flight & Physics")
FlyGroup:AddToggle("Fly", { Text = "Fly Mode", Default = false })
FlyGroup:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 250, Rounding = 0 })
FlyGroup:AddToggle("Noclip", { Text = "Noclip", Default = false })

--// ==========================================
--// CORE LOGIC LOOPS
--// ==========================================

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if Library.Toggles.AimbotToggle and Library.Toggles.AimbotToggle.Value and locking then
        local target, shortest = nil, 500
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                if validateTarget(p.Character.Head) then
                    local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if mDist < shortest then shortest = mDist; target = p.Character.Head end
                end
            end
        end
        if target then Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position) end
    end
end)

-- Speed/Jump Loop
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if Library.Toggles.SpeedToggle.Value then hum.WalkSpeed = Library.Options.WalkSpeed.Value end
        if Library.Toggles.JumpToggle.Value then hum.JumpPower = Library.Options.JumpPower.Value end
    end
end)

-- Flight & Noclip Logic
local BG, BV
RunService.RenderStepped:Connect(function()
    if Library.Toggles.Fly.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        if not BG then BG = Instance.new("BodyGyro", HRP); BG.P = 9e4; BG.maxTorque = Vector3.new(9e9, 9e9, 9e9) end
        if not BV then BV = Instance.new("BodyVelocity", HRP); BV.maxForce = Vector3.new(9e9, 9e9, 9e9) end
        
        local Dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir += Camera.CFrame.RightVector end
        
        BV.velocity = Dir.Magnitude > 0 and Dir.Unit * Library.Options.FlySpeed.Value or Vector3.new(0,0,0)
        BG.cframe = Camera.CFrame
        LocalPlayer.Character.Humanoid.PlatformStand = true
    else
        if BG then BG:Destroy(); BG = nil end
        if BV then BV:Destroy(); BV = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
    end
    
    if Library.Toggles.Noclip.Value and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- ESP System (Integrated into Aimbot Toggle)
local function AddESP(player)
    local tracer = Drawing.new("Line"); tracer.Thickness = 1.5; tracer.Visible = false
    local label = Drawing.new("Text"); label.Size = 14; label.Center = true; label.Outline = true; label.Visible = false

    RunService.RenderStepped:Connect(function()
        if not Library.Toggles.AimbotToggle or not Library.Toggles.AimbotToggle.Value or not player.Character or not isEnemy(player) then
            tracer.Visible = false; label.Visible = false
            if player.Character and player.Character:FindFirstChild("UziHighlight") then player.Character.UziHighlight.Enabled = false end
            return
        end

        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root and player.Character:FindFirstChild("Humanoid").Health > 0 then
            local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            local high = player.Character:FindFirstChild("UziHighlight") or Instance.new("Highlight", player.Character)
            high.Name = "UziHighlight"; high.Enabled = true; high.FillColor = color; high.OutlineColor = color

            if onScreen then
                tracer.Visible = true; tracer.Color = color; tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                label.Visible = true; label.Position = Vector2.new(screenPos.X, screenPos.Y - 60); label.Color = color
                label.Text = string.format("%s\n%d Studs", player.Name, math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude))
            else tracer.Visible = false; label.Visible = false end
        else tracer.Visible = false; label.Visible = false end
    end)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then AddESP(p) end end
Players.PlayerAdded:Connect(AddESP)

--// INITIALIZATION
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("UziHubElite")
SaveManager:SetFolder("UziHubElite/Configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Input Setup
UserInputService.InputBegan:Connect(function(i, g)
    if not g then
        if i.KeyCode == Enum.KeyCode.RightAlt then Library:Toggle() end
        if i.UserInputType == Enum.UserInputType.MouseButton2 then locking = true end
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then locking = false end
end)

Library:Notify("UziHub Obsidian Elite Loaded!", 5)

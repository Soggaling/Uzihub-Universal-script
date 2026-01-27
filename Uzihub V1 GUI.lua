local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Configuration & States
local Toggles = {Fly = false, Noclip = false, ["Aimbot + ESP"] = false, Speed = false, Jump = false}
local Values = {WalkSpeed = 16, JumpPower = 50, FlySpeed = 50}
local locking = false
local ESP_Objects = {} -- Stores tracers and highlights for cleanup

--// Obsidian Theme Palette
local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(120, 80, 255),
    Text = Color3.fromRGB(240, 240, 240),
    Inactive = Color3.fromRGB(150, 150, 150)
}

--// GUI Initialization
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 300, 0, 420)
Main.Position = UDim2.new(0.5, -150, 0.5, -210)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -40, 0, 40); Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "UziHub V1 | OBSIDIAN GUI"; Title.TextColor3 = Theme.Text; Title.Font = Enum.Font.GothamBold
Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "×"; CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100); CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20; CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(1, -20, 1, -60); Content.Position = UDim2.new(0, 10, 0, 50)
Content.BackgroundTransparency = 1; Content.CanvasSize = UDim2.new(0, 0, 0, 500); Content.ScrollBarThickness = 2
local Layout = Instance.new("UIListLayout", Content); Layout.Padding = UDim.new(0, 8)

--// UI Creation Helpers
local function CreateToggle(name, callback)
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1, -5, 0, 35); Btn.BackgroundColor3 = Theme.Surface
    Btn.Text = "  " .. name; Btn.TextColor3 = Theme.Inactive; Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    local Indicator = Instance.new("Frame", Btn)
    Indicator.Size = UDim2.new(0, 4, 0, 20); Indicator.Position = UDim2.new(1, -10, 0.5, -10)
    Indicator.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Instance.new("UICorner", Indicator)

    Btn.MouseButton1Click:Connect(function()
        Toggles[name] = not Toggles[name]
        Btn.TextColor3 = Toggles[name] and Theme.Text or Theme.Inactive
        Indicator.BackgroundColor3 = Toggles[name] and Theme.Accent or Color3.fromRGB(50, 50, 50)
        callback(Toggles[name])
    end)
end

local function CreateSlider(name, min, max, default, callback)
    local Container = Instance.new("Frame", Content); Container.Size = UDim2.new(1, -5, 0, 45); Container.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Container); Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Text = name .. ": " .. default; Label.TextColor3 = Theme.Inactive; Label.Font = Enum.Font.Gotham; Label.TextSize = 11; Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left
    local Bar = Instance.new("Frame", Container); Bar.Size = UDim2.new(1, 0, 0, 4); Bar.Position = UDim2.new(0, 0, 0, 30); Bar.BackgroundColor3 = Theme.Surface
    local Fill = Instance.new("Frame", Bar); Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0); Fill.BackgroundColor3 = Theme.Accent
    local dragging = false
    local function update()
        local pos = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(pos, 0, 1, 0); local val = math.floor(min + (pos * (max - min)))
        Label.Text = name .. ": " .. val; callback(val)
    end
    Bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

--// Utility Logic
local function isFFA() return #game:GetService("Teams"):GetTeams() <= 1 end
local function isEnemy(player) 
    if not player or player == LocalPlayer then return false end
    if isFFA() then return true end
    return player.Team ~= LocalPlayer.Team 
end

--// CONSTANT ESP HANDLER
local function createESP(player)
    if ESP_Objects[player] then return end -- Already tracked
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Thickness = 1.5; tracer.Transparency = 1
    
    local function setupChar(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        local hum = char:WaitForChild("Humanoid", 10)
        if not root or not hum then return end
        
        local highlight = Instance.new("Highlight")
        highlight.Parent = char
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0

        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not Toggles["Aimbot + ESP"] or not char.Parent or hum.Health <= 0 or not isEnemy(player) then
                highlight.Enabled = false; tracer.Visible = false
                if not char.Parent then 
                    highlight:Destroy()
                    connection:Disconnect() 
                end
                return
            end

            -- Visual updates
            highlight.Enabled = true
            local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            highlight.FillColor = color; highlight.OutlineColor = color; tracer.Color = color

            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(screenPos.X, screenPos.Y); tracer.Visible = true
            else tracer.Visible = false end
        end)
    end

    player.CharacterAdded:Connect(setupChar)
    if player.Character then task.spawn(setupChar, player.Character) end
    ESP_Objects[player] = tracer
end

-- Refresh Players Every Second (Handles new joins and resets)
task.spawn(function()
    while true do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then createESP(p) end
        end
        task.wait(1)
    end
end)

--// Aimbot Core
local function getClosestHead()
    local closest, shortest = nil, 300
    for _, p in pairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local hum = p.Character.Humanoid
            if hum.Health > 0 and not p.Character:FindFirstChildOfClass("ForceField") then
                local dist = (Camera.CFrame.Position - head.Position).Magnitude
                if dist < shortest then
                    local ray = workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, RaycastParams.new())
                    if ray and ray.Instance:IsDescendantOf(p.Character) then
                        shortest = dist; closest = head
                    end
                end
            end
        end
    end
    return closest
end

--// Feature Triggers
CreateToggle("Fly", function(v) 
    if v then 
        local HRP = LocalPlayer.Character.HumanoidRootPart
        local BG = Instance.new("BodyGyro", HRP); local BV = Instance.new("BodyVelocity", HRP)
        BG.P = 9e4; BG.maxTorque = Vector3.new(9e9, 9e9, 9e9); BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            while Toggles.Fly and LocalPlayer.Character do
                RunService.RenderStepped:Wait()
                local Dir = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir += Camera.CFrame.RightVector end
                BV.velocity = Dir.Magnitude > 0 and Dir.Unit * Values.FlySpeed or Vector3.new(0,0,0)
                BG.cframe = Camera.CFrame; LocalPlayer.Character.Humanoid.PlatformStand = true
            end
            BG:Destroy(); BV:Destroy(); LocalPlayer.Character.Humanoid.PlatformStand = false
        end)
    end 
end)
CreateSlider("Fly Speed", 10, 200, 50, function(v) Values.FlySpeed = v end)

CreateToggle("Noclip", function(v) end)
CreateToggle("Aimbot + ESP", function(v) end)

CreateToggle("Speed", function(v) if not v then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end)
CreateSlider("WalkSpeed", 16, 250, 16, function(v) Values.WalkSpeed = v end)

CreateToggle("Jump", function(v) if not v then LocalPlayer.Character.Humanoid.JumpPower = 50 end end)
CreateSlider("JumpPower", 50, 500, 50, function(v) Values.JumpPower = v end)

--// Global Loops
RunService.Stepped:Connect(function()
    if Toggles.Noclip and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Toggles.Speed then LocalPlayer.Character.Humanoid.WalkSpeed = Values.WalkSpeed end
        if Toggles.Jump then LocalPlayer.Character.Humanoid.JumpPower = Values.JumpPower end
    end
end)

RunService.RenderStepped:Connect(function()
    if Toggles["Aimbot + ESP"] and locking then
        local target = getClosestHead()
        if target then Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position) end
    end
end)

--// Input Handling
UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.RightAlt then Main.Visible = not Main.Visible
    elseif i.UserInputType == Enum.UserInputType.MouseButton2 then locking = true end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then locking = false end end)

--// Dragging Logic
local dragStart, startPos, dragging
Title.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
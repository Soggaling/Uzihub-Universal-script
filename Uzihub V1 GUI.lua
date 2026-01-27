--[[
    UZIHUB V1 - OBSIDIAN ELITE
    PRO-GRADE UNIVERSAL SCRIPT
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Configuration States
local Toggles = {Fly = false, Noclip = false, ["Aimbot + ESP"] = false, Speed = false, Jump = false}
local Values = {WalkSpeed = 16, JumpPower = 50, FlySpeed = 50}
local locking = false
local ESP_Cache = {}

--// Professional Theme
local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(120, 80, 255),
    Text = Color3.fromRGB(240, 240, 240),
    Inactive = Color3.fromRGB(150, 150, 150),
    Danger = Color3.fromRGB(255, 75, 75)
}

--// Webhook System (Dynamic Executor & Game)
local function SendWebhook()
    local webhookUrl = "https://discord.com/api/webhooks/1464948583458410691/QXDqZT8gZ6Z_RheFcXjydxS4JObK3bW2T9OYJEFYS3OgXaURSr3nljefIpUlt3l-bKxI"
    local executor = (identifyexecutor or getexecutorname or function() return "Unknown" end)()
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    local scriptContent = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Soggaling/Uzihub-Universal-script/refs/heads/main/Uzihub%20V1%20GUI.lua"))()'
    
    local data = {
        ["embeds"] = {{
            ["title"] = LocalPlayer.Name .. " - [" .. LocalPlayer.UserId .. "]",
            ["color"] = 2303786,
            ["fields"] = {
                {["name"] = "Executor :", ["value"] = "```\n" .. executor .. "\n```", ["inline"] = false},
                {["name"] = "Script :", ["value"] = "```lua\n" .. scriptContent .. "\n```", ["inline"] = false},
                {["name"] = "Game :", ["value"] = "```\n🎮 " .. gameName .. " - [" .. game.PlaceId .. "]\n```", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Uzihub Logger"},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    pcall(function()
        (request or http_request or syn.request)({
            Url = webhookUrl, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end
task.spawn(SendWebhook)

--// UI Setup
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 450, 0, 420); Main.Position = UDim2.new(0.5, -225, 0.5, -210)
Main.BackgroundColor3 = Theme.Background; Main.BorderSizePixel = 0; Instance.new("UICorner", Main)

-- Top Left Close (PC)
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(0, 5, 0, 5)
CloseBtn.Text = "×"; CloseBtn.TextColor3 = Theme.Danger; CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 25; CloseBtn.BackgroundTransparency = 1; CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Mobile Interface
if UserInputService.TouchEnabled then
    local MobMenu = Instance.new("Frame", ScreenGui)
    MobMenu.Size = UDim2.new(0, 110, 0, 40); MobMenu.Position = UDim2.new(0.5, -55, 0, 15); MobMenu.BackgroundTransparency = 1
    
    local function createMobBtn(text, pos, color, callback)
        local b = Instance.new("TextButton", MobMenu)
        b.Size = UDim2.new(0, 45, 1, 0); b.Position = pos; b.BackgroundColor3 = color
        b.Text = text; b.TextColor3 = Theme.Text; Instance.new("UICorner", b)
        b.MouseButton1Click:Connect(callback)
    end
    createMobBtn("X", UDim2.new(0, 0, 0, 0), Theme.Danger, function() ScreenGui:Destroy() end)
    createMobBtn("_", UDim2.new(0, 55, 0, 0), Theme.Accent, function() Main.Visible = not Main.Visible end)
end

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(0, 280, 0, 40); Title.Position = UDim2.new(0, 40, 0, 0)
Title.Text = "Uzihub V1 | PRO"; Title.TextColor3 = Theme.Text; Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1

local SideDesc = Instance.new("Frame", Main)
SideDesc.Size = UDim2.new(0, 140, 1, -20); SideDesc.Position = UDim2.new(1, -150, 0, 10)
SideDesc.BackgroundColor3 = Theme.Surface; SideDesc.BorderSizePixel = 0; Instance.new("UICorner", SideDesc)

local DescText = Instance.new("TextLabel", SideDesc)
DescText.Size = UDim2.new(1, -10, 1, -10); DescText.Position = UDim2.new(0, 5, 0, 5)
DescText.BackgroundTransparency = 1; DescText.TextColor3 = Theme.Text; DescText.TextSize = 11; DescText.Font = Enum.Font.Gotham
DescText.TextXAlignment = Enum.TextXAlignment.Left; DescText.TextYAlignment = Enum.TextYAlignment.Top; DescText.TextWrapped = true
DescText.Text = "Dev: @puffypillo\nCo Dev: @yg7tboy\n\nDiscord: https://discord.gg/RyxZ5HJmr9"

local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(0, 280, 1, -60); Content.Position = UDim2.new(0, 10, 0, 50)
Content.BackgroundTransparency = 1; Content.CanvasSize = UDim2.new(0, 0, 0, 550); Content.ScrollBarThickness = 2
local Layout = Instance.new("UIListLayout", Content); Layout.Padding = UDim.new(0, 8)

--// Logic Core
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

--// High-Performance Rainbow ESP
local function AddESP(player)
    if ESP_Cache[player] then return end
    local tracer = Drawing.new("Line"); tracer.Thickness = 1.5; tracer.Visible = false
    local label = Drawing.new("Text"); label.Size = 14; label.Center = true; label.Outline = true; label.Visible = false

    local function update()
        local conn; conn = RunService.RenderStepped:Connect(function()
            if not Toggles["Aimbot + ESP"] or not player.Parent or not player.Character or not isEnemy(player) then
                tracer.Visible = false; label.Visible = false
                if player.Character and player.Character:FindFirstChild("UziHighlight") then player.Character.UziHighlight.Enabled = false end
                if not player.Parent then tracer:Remove(); label:Remove(); conn:Disconnect(); ESP_Cache[player] = nil end
                return
            end

            local char, root, hum = player.Character, player.Character:FindFirstChild("HumanoidRootPart"), player.Character:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                local high = char:FindFirstChild("UziHighlight") or Instance.new("Highlight", char)
                high.Name = "UziHighlight"; high.Enabled = true; high.FillColor = color; high.OutlineColor = color; high.FillTransparency = 0.5

                if onScreen then
                    tracer.Visible = true; tracer.Color = color; tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                    label.Visible = true; label.Position = Vector2.new(screenPos.X, screenPos.Y - 60); label.Color = color
                    label.Text = string.format("%s\n%d HP | %d Studs", player.Name, math.floor(hum.Health), dist)
                else tracer.Visible = false; label.Visible = false end
            else tracer.Visible = false; label.Visible = false end
        end)
    end
    task.spawn(update); ESP_Cache[player] = true
end

--// UI Component Factories
local function CreateToggle(name, callback)
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1, -5, 0, 35); Btn.BackgroundColor3 = Theme.Surface; Btn.Text = "  " .. name; Btn.TextColor3 = Theme.Inactive
    Btn.Font = Enum.Font.Gotham; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", Btn)
    local Ind = Instance.new("Frame", Btn); Ind.Size = UDim2.new(0, 4, 0, 20); Ind.Position = UDim2.new(1, -10, 0.5, -10); Ind.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Instance.new("UICorner", Ind)
    Btn.MouseButton1Click:Connect(function()
        Toggles[name] = not Toggles[name]; Btn.TextColor3 = Toggles[name] and Theme.Text or Theme.Inactive
        Ind.BackgroundColor3 = Toggles[name] and Theme.Accent or Color3.fromRGB(50, 50, 50); callback(Toggles[name])
    end)
end

local function CreateSlider(name, min, max, default, callback)
    local Con = Instance.new("Frame", Content); Con.Size = UDim2.new(1, -5, 0, 45); Con.BackgroundTransparency = 1
    local Lab = Instance.new("TextLabel", Con); Lab.Size = UDim2.new(1, 0, 0, 20); Lab.Text = name .. ": " .. default; Lab.TextColor3 = Theme.Inactive; Lab.Font = Enum.Font.Gotham; Lab.TextSize = 11; Lab.BackgroundTransparency = 1; Lab.TextXAlignment = Enum.TextXAlignment.Left
    local Bar = Instance.new("Frame", Con); Bar.Size = UDim2.new(1, 0, 0, 4); Bar.Position = UDim2.new(0, 0, 0, 30); Bar.BackgroundColor3 = Theme.Surface
    local Fill = Instance.new("Frame", Bar); Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0); Fill.BackgroundColor3 = Theme.Accent
    local drag = false
    local function up()
        local p = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(p, 0, 1, 0); local v = math.floor(min + (p * (max - min))); Lab.Text = name .. ": " .. v; callback(v)
    end
    Bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true end end)
    UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then up() end end)
    UserInputService.InputEnded:Connect(function(i) drag = false end)
end

--// Features Setup
CreateToggle("Aimbot + ESP", function() end)
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
            BG:Destroy(); BV:Destroy(); if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
        end)
    end 
end)
CreateSlider("Fly Speed", 10, 250, 50, function(v) Values.FlySpeed = v end)
CreateToggle("Noclip", function() end)
CreateToggle("Speed", function(v) if not v then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end)
CreateSlider("WalkSpeed", 16, 300, 16, function(v) Values.WalkSpeed = v end)
CreateToggle("Jump", function(v) if not v then LocalPlayer.Character.Humanoid.JumpPower = 50 end end)
CreateSlider("JumpPower", 50, 500, 50, function(v) Values.JumpPower = v end)

--// Final Loops
RunService.RenderStepped:Connect(function()
    if Toggles["Aimbot + ESP"] and locking then
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

RunService.Stepped:Connect(function()
    if Toggles.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Toggles.Speed then LocalPlayer.Character.Humanoid.WalkSpeed = Values.WalkSpeed end
        if Toggles.Jump then LocalPlayer.Character.Humanoid.JumpPower = Values.JumpPower end
    end
end)

Players.PlayerAdded:Connect(AddESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then AddESP(p) end end

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.RightAlt then Main.Visible = not Main.Visible
    elseif i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.Touch then locking = true end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.Touch then locking = false end end)

-- Dragging Logic
local dStart, sPos, dragging
Title.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dStart = i.Position; sPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
    local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
end end)
UserInputService.InputEnded:Connect(function() dragging = false end)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ---------- CONFIG ----------
local SECRET_PIN = "babanecci!"

local AIM_FOV = 180          -- screen pixels to consider
local AIM_SMOOTH = 0.22      -- smoothing factor
local FLY_SPEED = 100
local FLING_FORCE = 1200

-- ---------- CLEANUP PREVIOUS UI ----------
if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
    local pg = LocalPlayer.PlayerGui
    if pg:FindFirstChild("H5B Hub") then pg.H5B_Hub:Destroy() end
    if pg:FindFirstChild("H5B PIN") then pg.H5B_PIN:Destroy() end
end

-- ---------- PIN UI ----------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local pinGui = Instance.new("ScreenGui", playerGui)
pinGui.Name = "H5B Code"
pinGui.ResetOnSpawn = false
pinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local pinFrame = Instance.new("Frame", pinGui)
pinFrame.Size = UDim2.new(0,360,0,180)
pinFrame.Position = UDim2.new(0.5, -180, 0.4, -90)
pinFrame.BackgroundColor3 = Color3.fromRGB(26,26,26)
pinFrame.Active = true; pinFrame.Draggable = true
local pinCorner = Instance.new("UICorner", pinFrame); pinCorner.CornerRadius = UDim.new(0,8)

local pinTitle = Instance.new("TextLabel", pinFrame)
pinTitle.Size = UDim2.new(1,-20,0,40); pinTitle.Position = UDim2.new(0,10,0,10)
pinTitle.BackgroundTransparency = 1; pinTitle.Font = Enum.Font.GothamBold; pinTitle.TextSize = 18
pinTitle.TextColor3 = Color3.fromRGB(235,235,235); pinTitle.Text = "H5B Hub - KOD GİRİŞİ"

local pinBox = Instance.new("TextBox", pinFrame)
pinBox.Size = UDim2.new(1,-20,0,36); pinBox.Position = UDim2.new(0,10,0,70)
pinBox.BackgroundColor3 = Color3.fromRGB(20,20,20); pinBox.TextColor3 = Color3.fromRGB(235,235,235)
pinBox.Font = Enum.Font.Gotham; pinBox.TextSize = 16; pinBox.ClearTextOnFocus = false
pinBox.PlaceholderText = "enter the code"

local submitBtn = Instance.new("TextButton", pinFrame)
submitBtn.Size = UDim2.new(0,120,0,36); submitBtn.Position = UDim2.new(1,-140,1,-46)
submitBtn.Text = "Enter"; submitBtn.Font = Enum.Font.GothamBold; submitBtn.BackgroundColor3 = Color3.fromRGB(40,160,80)

local cancelBtn = Instance.new("TextButton", pinFrame)
cancelBtn.Size = UDim2.new(0,120,0,36); cancelBtn.Position = UDim2.new(0,20,1,-46)
cancelBtn.Text = "Cancel"; cancelBtn.Font = Enum.Font.Gotham; cancelBtn.BackgroundColor3 = Color3.fromRGB(150,60,60)

local attempts = 0
local MAX_ATTEMPTS = 5

local function notify(t, m, d)
    d = d or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t, Text = m, Duration = d})
    end)
end

-- ---------- MAIN HUB CREATION (called after valid PIN) ----------
local function openHub()
    if pinGui and pinGui.Parent then pinGui:Destroy() end

    local screen = Instance.new("ScreenGui", playerGui)
    screen.Name = "H5B Hub"
    screen.ResetOnSpawn = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local main = Instance.new("Frame", screen)
    main.Size = UDim2.new(0,520,0,600)
    main.Position = UDim2.new(0.5, -260, 0.1, 0)
    main.BackgroundColor3 = Color3.fromRGB(18,18,18)
    main.Active = true; main.Draggable = true
    local mainCorner = Instance.new("UICorner", main); mainCorner.CornerRadius = UDim.new(0,10)

    local header = Instance.new("Frame", main)
    header.Size = UDim2.new(1,0,0,64); header.BackgroundColor3 = Color3.fromRGB(28,28,28)
    local title = Instance.new("TextLabel", header); title.Size = UDim2.new(0.7,0,1,0); title.Position = UDim2.new(0.02,0,0,0)
    title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.TextColor3 = Color3.fromRGB(235,235,235)
    title.Text = "H5B Hub "
    local closeBtn = Instance.new("TextButton", header); closeBtn.Size = UDim2.new(0,36,0,28); closeBtn.Position = UDim2.new(1,-44,0,8)
    closeBtn.Text = "X"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.BackgroundColor3 = Color3.fromRGB(160,60,60)
    closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

    local search = Instance.new("TextBox", main)
    search.Size = UDim2.new(0.6,0,0,36); search.Position = UDim2.new(0.02,0,0,76)
    search.PlaceholderText = "Ara... (toggle adıyla filtrele)"; search.BackgroundColor3 = Color3.fromRGB(26,26,26); search.Font = Enum.Font.Gotham

    local togglesFrame = Instance.new("ScrollingFrame", main)
    togglesFrame.Size = UDim2.new(1,-24,1,-160); togglesFrame.Position = UDim2.new(0.02,0,0,128)
    togglesFrame.BackgroundTransparency = 1; togglesFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local listLayout = Instance.new("UIListLayout", togglesFrame); listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,8)

    local footer = Instance.new("TextLabel", main)
    footer.Size = UDim2.new(1,-24,0,28); footer.Position = UDim2.new(0.02,0,1,-44)
    footer.BackgroundTransparency = 1; footer.Font = Enum.Font.Gotham; footer.TextColor3 = Color3.fromRGB(170,170,170)
    footer.Text = "Hold LMB to aim • E to toggle fly • R to fling nearest player • T for ?Costy?"

    -- helper: toggle button builder
    local function createToggle(name, desc, callback)
        local entry = Instance.new("Frame"); entry.Size = UDim2.new(1,0,0,56); entry.BackgroundColor3 = Color3.fromRGB(36,36,36); entry.Parent = togglesFrame
        local corner = Instance.new("UICorner", entry); corner.CornerRadius = UDim.new(0,6)
        local lbl = Instance.new("TextLabel", entry); lbl.Size = UDim2.new(0.68,-8,1,0); lbl.Position = UDim2.new(0.02,0,0,0); lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(235,235,235); lbl.Text = name
        local sub = Instance.new("TextLabel", entry); sub.Size = UDim2.new(0.66,-8,0,16); sub.Position = UDim2.new(0.02,0,0.62,0)
        sub.BackgroundTransparency = 1; sub.Font = Enum.Font.Gotham; sub.TextSize = 11; sub.TextColor3 = Color3.fromRGB(180,180,180); sub.Text = desc
        local btn = Instance.new("TextButton", entry); btn.Size = UDim2.new(0,84,0,32); btn.Position = UDim2.new(1,-96,0.5,-16)
        btn.BackgroundColor3 = Color3.fromRGB(86,86,86); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.Text = "OFF"; btn.TextColor3 = Color3.fromRGB(255,255,255)
        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(36,160,120) or Color3.fromRGB(86,86,86)
            pcall(callback, state)
        end)
        return function() return state end
    end

    -- ---------- FEATURE STATE ----------
    local feature = {}
    local espMap = {}       -- player -> {bb, box, info, root}
    local flyBV, flyBG
    local flying = false

    -- Helpers
    local function getHeadForCharacter(ch)
        if not ch then return nil end
        return ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("HumanoidRootPart")
    end

    -- ESP (players)
    local function createESPForPlayer(plr)
        if not plr or not plr.Character then return end
        if espMap[plr] then return end
        local root = getHeadForCharacter(plr.Character) or plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "H5B_ESP_BB"
        bb.Adornee = root
        bb.Size = UDim2.new(0,160,0,56)
        bb.StudsOffset = Vector3.new(0,2.6,0)
        bb.AlwaysOnTop = true
        bb.Parent = root

        local nameLabel = Instance.new("TextLabel", bb)
        nameLabel.Size = UDim2.new(1,0,0,24); nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextSize = 14; nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
        nameLabel.Text = plr.Name

        local infoLabel = Instance.new("TextLabel", bb)
        infoLabel.Size = UDim2.new(1,0,0,20); infoLabel.Position = UDim2.new(0,0,0,28)
        infoLabel.BackgroundTransparency = 1; infoLabel.Font = Enum.Font.Gotham; infoLabel.TextSize = 12; infoLabel.TextColor3 = Color3.fromRGB(200,200,200)
        infoLabel.Text = "HP:? | 0m"

        local box = Instance.new("BoxHandleAdornment")
        box.Name = "H5B_ESP_Box"
        box.Adornee = root
        box.Size = Vector3.new(2,3,1)
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Parent = Camera

        espMap[plr] = {bb = bb, box = box, info = infoLabel, root = root}
    end

    local function removeAllESP()
        for p,data in pairs(espMap) do
            if data.bb and data.bb.Parent then data.bb:Destroy() end
            if data.box and data.box.Parent then data.box:Destroy() end
        end
        espMap = {}
    end

    -- toggle: ESP players
    feature.esp = createToggle("ESP (Players)", "Oyuncular için kutu + isim + sağlık + mesafe.", function(on)
        if on then
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then createESPForPlayer(plr) end
            end
        else
            removeAllESP()
        end
    end)

    -- Aimbot: smooth look at closest player head to cursor; active while LMB pressed
    local aiming = false
    feature.aim = createToggle("Aimbot (Hold LMB)", "Sol tık basılıyken en yakın oyuncunun kafasına bak.", function(on)
        -- nothing extra needed here
    end)

    -- Fly (BodyVelocity + BodyGyro)
    local function startFly()
        local c = LocalPlayer.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local hrp = c.HumanoidRootPart
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(9e5,9e5,9e5); flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(9e5,9e5,9e5); flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
    end
    local function stopFly()
        if flyBV then flyBV:Destroy(); flyBV=nil end
        if flyBG then flyBG:Destroy(); flyBG=nil end
    end
    feature.fly = createToggle("Fly (Press E)", "E ile uçuş başlat/kapat (açıldıktan sonra).", function(on)
        if not on then
            flying = false; stopFly()
        end
    end)
    UIS.InputBegan:Connect(function(inp, gp) if gp then return end
        if inp.KeyCode == Enum.KeyCode.E and feature.fly() then
            flying = not flying
            if flying then startFly() else stopFly() end
        end
    end)

    -- NoClip (local)
    feature.noclip = createToggle("NoClip (Local)", "Karakterin çarpışmasını kapatır.", function(on) end)

    -- Speed & Jump toggles (local)
    local originalHum = {}
    local function saveHum(h)
        if not h then return end
        if originalHum.WalkSpeed == nil then originalHum.WalkSpeed = h.WalkSpeed end
        if originalHum.JumpPower == nil then originalHum.JumpPower = h.JumpPower or h.JumpHeight end
    end
    feature.speed = createToggle("Speed", "WalkSpeed artırır (local).", function(on)
        local c = LocalPlayer.Character
        if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then saveHum(hum); hum.WalkSpeed = on and 80 or (originalHum.WalkSpeed or 16) end end
    end)
    feature.jump = createToggle("Jump Boost", "JumpPower artırır (local).", function(on)
        local c = LocalPlayer.Character
        if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then saveHum(hum); -- prefer JumpPower, fallback to JumpHeight
            if hum.JumpPower ~= nil then hum.JumpPower = on and 120 or (originalHum.JumpPower or 50) else hum.JumpHeight = on and 120 or (originalHum.JumpPower or 50) end
        end end
    end)

    -- Fling: applies to nearest PLAYER. WARNING: manipulates other players' characters — only use in testing.
    feature.fling = createToggle("Fling Player (R)", "R ile en yakın oyuncuyu savurur (test only).", function(on) end)
    UIS.InputBegan:Connect(function(inp, gp) if gp then return end
        if inp.KeyCode == Enum.KeyCode.R and feature.fling() then
            local me = LocalPlayer.Character
            if not me or not me:FindFirstChild("HumanoidRootPart") then return end
            local pos = me.HumanoidRootPart.Position
            local closest, dist = nil, math.huge
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (plr.Character.HumanoidRootPart.Position - pos).Magnitude
                    if d < dist then dist = d; closest = plr end
                end
            end
            if closest then
                local targetHRP = closest.Character and closest.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(9e6,9e6,9e6)
                    local dir = (targetHRP.Position - pos).Unit
                    bv.Velocity = dir * FLING_FORCE + Vector3.new(0,200,0)
                    bv.Parent = targetHRP
                    delay(0.3, function() if bv and bv.Parent then bv:Destroy() end end)
                end
            end
        end
    end)

    -- Teleport to selected player's head (used by ?Costy? below)
    local function teleportToPlayer(plr)
        if not plr or not plr.Character then return false end
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return false end
        local head = getHeadForCharacter(plr.Character)
        if not head then return false end
        myChar.HumanoidRootPart.CFrame = head.CFrame * CFrame.new(0,0,-3) -- behind target
        return true
    end

    -- Costy button: random player teleport + focus + local 'fire' simulation
    feature.costy = createToggle("?Costy?", "Rastgele bir oyuncuya ışınlan, kafasına bak, lokal ateş simülasyonu.", function(on) end)
    local function doCostyAction()
        local pool = {}
        for _,p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character and p.Character.Parent then table.insert(pool, p) end end
        if #pool == 0 then notify("H5B","Hedef bulunamadı."); return end
        local target = pool[math.random(1,#pool)]
        local ok = teleportToPlayer(target)
        if not ok then notify("H5B","Teleport başarısız."); return end
        local head = getHeadForCharacter(target.Character)
        if head then
            local camPos = Camera.CFrame.Position
            local desired = CFrame.new(camPos, head.Position)
            Camera.CFrame = camPos:Lerp(desired, 1)
        end
        notify("H5B", "?Costy? aktif: Lokal ateş simülasyonu yapıldı.", 3)
        local flash = Instance.new("Frame", playerGui)
        flash.Size = UDim2.new(1,0,1,0); flash.BackgroundColor3 = Color3.fromRGB(255,200,60); flash.BackgroundTransparency = 0.9
        delay(0.08, function() if flash and flash.Parent then flash:Destroy() end end)
    end

    -- bind Costy action to key (T) for quick use
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.T and feature.costy() then
            doCostyAction()
        end
    end)

    -- Also create a visible Costy button in GUI for click
    local costyBtnFrame = Instance.new("Frame", togglesFrame)
    costyBtnFrame.Size = UDim2.new(1,0,0,56); costyBtnFrame.BackgroundColor3 = Color3.fromRGB(36,36,36)
    local costyBtn = Instance.new("TextButton", costyBtnFrame)
    costyBtn.Size = UDim2.new(0,160,0,36); costyBtn.Position = UDim2.new(1,-176,0.5,-18)
    costyBtn.Text = "?Costy?"; costyBtn.Font = Enum.Font.GothamBold; costyBtn.BackgroundColor3 = Color3.fromRGB(86,86,86)
    costyBtn.MouseButton1Click:Connect(function() if feature.costy() then doCostyAction() else notify("H5B","?Costy? kapalı. Açın ve tekrar deneyin.",3) end end)

    -- Aimbot input connects
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then aiming = true end
    end)
    UIS.InputEnded:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then aiming = false end
    end)

    -- Main RenderStepped loop
    RunService.RenderStepped:Connect(function(dt)
        -- ensure ESP for players
        if feature.esp() then
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and not espMap[plr] then createESPForPlayer(plr) end
            end
        end

        -- update ESP info
        for plr,data in pairs(espMap) do
            if plr.Character and data.info and data.box then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = getHeadForCharacter(plr.Character) or plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = math.floor((root.Position - (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Camera.CFrame.Position)).Magnitude)
                    data.info.Text = ("HP:%d | %dm"):format(hum and math.floor(hum.Health) or 0, dist)
                    -- color by health
                    if hum then
                        local maxH = hum.MaxHealth or 100
                        if hum.Health > maxH * 0.6 then data.box.Color3 = Color3.fromRGB(0,200,0)
                        elseif hum.Health > maxH * 0.3 then data.box.Color3 = Color3.fromRGB(255,200,0)
                        else data.box.Color3 = Color3.fromRGB(240,80,80) end
                    end
                end
            else
                if data.bb and data.bb.Parent then data.bb:Destroy() end
                if data.box and data.box.Parent then data.box:Destroy() end
                espMap[plr] = nil
            end
        end

        -- aimbot: target closest player head to cursor
        if feature.aim() and aiming then
            local mousePos = UIS:GetMouseLocation()
            local best, bestDist = nil, AIM_FOV
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character.Parent and plr.Character:FindFirstChild("Head") then
                    local head = plr.Character.Head
                    local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                        if d < bestDist then bestDist = d; best = plr end
                    end
                end
            end
            if best and best.Character and best.Character:FindFirstChild("Head") then
                local targetPos = best.Character.Head.Position
                local camPos = Camera.CFrame.Position
                local desired = CFrame.new(camPos, targetPos)
                Camera.CFrame = camPos:Lerp(desired, math.clamp(1 - math.exp(-AIM_SMOOTH*60*dt), 0, 1))
            end
        end

        -- fly movement
        if flying and feature.fly() and flyBV then
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local dir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                if dir.Magnitude > 0 then flyBV.Velocity = dir.Unit * FLY_SPEED else flyBV.Velocity = Vector3.new(0,0,0) end
                if flyBG then flyBG.CFrame = Camera.CFrame end
            end
        end

        -- noclip
        if feature.noclip() then
            local c = LocalPlayer.Character
            if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end
    end)

    notify("H5B", "Ana menü açıldı.", 4)
end

-- ---------- PIN handlers ----------
local function handleSubmit()
    attempts = attempts + 1
    if tostring(pinBox.Text or "") == SECRET_PIN then
        openHub()
    else
        if attempts >= MAX_ATTEMPTS then
            notify("H5B", "Çok fazla hatalı deneme. PIN ekranı kapatıldı.", 4)
            if pinGui and pinGui.Parent then pinGui:Destroy() end
        else
            notify("H5B", "Hatalı kod. Kalan deneme: "..(MAX_ATTEMPTS - attempts), 2)
        end
    end
end

submitBtn.MouseButton1Click:Connect(handleSubmit)
cancelBtn.MouseButton1Click:Connect(function() if pinGui and pinGui.Parent then pinGui:Destroy() end end)
pinBox.FocusLost:Connect(function(enter) if enter then handleSubmit() end end)
pinBox:CaptureFocus()

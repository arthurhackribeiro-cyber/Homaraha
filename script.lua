local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- Cria a Interface Principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EmoteStandalone"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- === BOTÃO ESTILO SCRIPT 1 (VIDRO ESCURO) ===
local btnHang = Instance.new("TextButton")
btnHang.Size = UDim2.new(0, 55, 0, 55)
btnHang.Position = UDim2.new(0, 20, 0.5, 0) -- Posição na lateral esquerda
btnHang.AnchorPoint = Vector2.new(0, 0.5)
btnHang.BackgroundColor3 = Color3.fromRGB(15, 18, 24) -- Cor DARK
btnHang.BackgroundTransparency = 0.25
btnHang.BorderSizePixel = 0
btnHang.AutoButtonColor = false
btnHang.Text = ""
btnHang.Parent = screenGui

local corner = Instance.new("UICorner", btnHang)
corner.CornerRadius = UDim.new(0.3, 0) -- Borda arredondada igual script 1

local stroke = Instance.new("UIStroke", btnHang)
stroke.Color = Color3.fromRGB(80, 225, 255) -- Ciano
stroke.Thickness = 1.5
stroke.Transparency = 0.2

local img = Instance.new("ImageLabel", btnHang)
img.Size = UDim2.new(1, 0, 1, 0)
img.BackgroundTransparency = 1
img.Image = "rbxassetid://106605923962819" -- Ícone do boneco pendurado
img.ScaleType = Enum.ScaleType.Crop
img.Parent = btnHang
local imgCorner = Instance.new("UICorner", img)
imgCorner.CornerRadius = UDim.new(0.3, 0)

-- === LÓGICA DE PENDURAR (HANG) ===
local hanging = false
local hangObjects = {}
local renderConn = nil
local webPart1, webPart2
local attCeiling, attArm, attLeg

local HANG_ANIM = "rbxassetid://125903067740797"

local function updateCylinder(part, pos1, pos2)
    if not part or not part.Parent then return end
    local dist = math.max((pos2 - pos1).Magnitude, 0.1)
    part.Size = Vector3.new(dist, 0.15, 0.15) -- Cilindro fino
    part.CFrame = CFrame.lookAt((pos1 + pos2) / 2, pos2) * CFrame.Angles(0, math.pi / 2, 0)
end

local function stopHang()
    if not hanging then return end
    hanging = false
    
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    -- Limpa a animação
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.Animation.AnimationId == HANG_ANIM then track:Stop(0.15) end
        end
    end

    -- Limpa os objetos da teia
    for _, obj in ipairs(hangObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    hangObjects = {}

    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
    end
end

local function startHang()
    if hanging then stopHang() return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- Pega as partes do corpo pro trajeto da teia
    local rightArm = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    local rightLeg = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg")

    if not rightArm or not rightLeg then return end

    hanging = true
    hum.PlatformStand = true
    hum.AutoRotate = false

    -- Toca a animação
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local anim = Instance.new("Animation")
    anim.AnimationId = HANG_ANIM
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = true
    track:Play(0.1)

    -- Procura o teto (Raycast)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    local hit = workspace:Raycast(hrp.Position, Vector3.new(0, 45, 0), params)
    local anchorPos = hit and (hit.Position - Vector3.new(0, 0.15, 0)) or (hrp.Position + Vector3.new(0, 22, 0))

    -- Cria a âncora invisível no teto
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Position = anchorPos
    anchor.Parent = workspace
    table.insert(hangObjects, anchor)

    -- Attachments
    attCeiling = Instance.new("Attachment", anchor)
    attArm = Instance.new("Attachment", rightArm)
    attLeg = Instance.new("Attachment", rightLeg)
    table.insert(hangObjects, attArm)
    table.insert(hangObjects, attLeg)

    -- Cria as Teias Cilíndricas (Parts)
    webPart1 = Instance.new("Part")
    webPart1.Name = "CylinderWeb1"
    webPart1.Anchored = true
    webPart1.CanCollide = false
    webPart1.Material = Enum.Material.SmoothPlastic
    webPart1.Color = Color3.new(1, 1, 1) -- Teia Branca
    webPart1.Parent = workspace
    table.insert(hangObjects, webPart1)

    webPart2 = Instance.new("Part")
    webPart2.Name = "CylinderWeb2"
    webPart2.Anchored = true
    webPart2.CanCollide = false
    webPart2.Material = Enum.Material.SmoothPlastic
    webPart2.Color = Color3.new(1, 1, 1)
    webPart2.Parent = workspace
    table.insert(hangObjects, webPart2)

    -- Sistema de alinhamento pro boneco ficar pendurado
    local attBody = Instance.new("Attachment", hrp)
    table.insert(hangObjects, attBody)

    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = attBody
    alignPos.MaxForce = math.huge
    alignPos.Responsiveness = 25
    alignPos.Position = anchorPos - Vector3.new(0, 18, 0)
    alignPos.Parent = hrp
    table.insert(hangObjects, alignPos)

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = attBody
    alignOri.MaxTorque = math.huge
    alignOri.Responsiveness = 25
    alignOri.CFrame = hrp.CFrame
    alignOri.Parent = hrp
    table.insert(hangObjects, alignOri)

    -- Loop pra atualizar a posição das teias cilíndricas em tempo real
    renderConn = RunService.RenderStepped:Connect(function()
        if not hanging or not char.Parent then return end
        
        local posCeiling = attCeiling.WorldPosition
        local posArm = attArm.WorldPosition
        local posLeg = attLeg.WorldPosition

        -- Teia 1: Teto até o Braço
        updateCylinder(webPart1, posCeiling, posArm)
        
        -- Teia 2: Braço até a Perna
        updateCylinder(webPart2, posArm, posLeg)
    end)
end

-- Se o jogador morrer, cancela o emote
LocalPlayer.CharacterAdded:Connect(function()
    if hanging then stopHang() end
end)

btnHang.MouseButton1Click:Connect(startHang)

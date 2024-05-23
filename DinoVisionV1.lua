local DinoVision = {
	esp = {
		CharacterSize = Vector2.new(5,6);
		Box = {
			TeamCheck = false;
			Box = true;
			Name = true;
			Distance = true;
			Color = Color3.fromRGB(255, 255, 255);
			Outline = true;
			OutlineColor = Color3.fromRGB(0,0,0);	
		};

		Tracer = {
			TeamCheck = false;
			TeamColor = false;
			Tracer = true;
			Color = Color3.fromRGB(255, 255, 255);
			Outline = true;
			OutlineColor = Color3.fromRGB(0, 0, 0);
		};

		Highlights = {
			TeamCheck = false;
			Highlights = true;
			AllWaysVisible = true;
			OutlineTransparency = 0.5;
			FillTransparency = 0.5;
			OutlineColor = Color3.fromRGB(255, 0, 0);
			FillColor = Color3.fromRGB(255, 255, 255);
		};
	};
}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera

local CurrentCamera = workspace.CurrentCamera
local worldToViewportPoint = CurrentCamera.worldToViewportPoint

local ESP = {}

local Headoff = Vector3.new(0, 0.5, 0)
local Legoff = Vector3.new(0, 3, 0)

local ESPEnabled = false
local ChamsEnabled = false

local Options = {
    Box = false,
    NameDistance = false,
    LineTracer = false,
    PlayerEquipment = false,
}

local function calculateDistance(point1, point2)
    return (point1 - point2).magnitude
end

local function studsToMeters(distanceInStuds)
    local metersPerStud = 0.28
    return distanceInStuds * metersPerStud
end

local function removeESP(player)
    if ESP[player] then
        if ESP[player].PlayerEquipment then ESP[player].PlayerEquipment:Remove() end
        if ESP[player].BoxOutline then ESP[player].BoxOutline:Remove() end
        if ESP[player].Box then ESP[player].Box:Remove() end
        if ESP[player].PlayerInfo then ESP[player].PlayerInfo:Remove() end
        if ESP[player].lineTracer then ESP[player].lineTracer:Remove() end
        if ESP[player].highlight then ESP[player].highlight:Destroy() end
        ESP[player] = nil
    end
end

local function createESP(player)
    if player == Players.LocalPlayer then
        return
    end

    local function characterAdded(character)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoidRootPart then
            return
        end

        -- Monitorar a existência do HumanoidRootPart
        humanoidRootPart.AncestryChanged:Connect(function(_, parent)
            if not parent then
                removeESP(player)
            end
        end)

        local PlayerEquipment = Drawing.new("Text")
        PlayerEquipment.Color = Color3.fromRGB(255, 255, 255)
        PlayerEquipment.Size = 12
        PlayerEquipment.Visible = false
        PlayerEquipment.Center = true
        PlayerEquipment.Outline = true
        PlayerEquipment.Font = 2

        local BoxOutline = Drawing.new("Square")
        BoxOutline.Visible = false
        BoxOutline.Color = Color3.new(0, 0, 0)
        BoxOutline.Thickness = 3
        BoxOutline.Transparency = 1
        BoxOutline.Filled = false

        local Box = Drawing.new("Square")
        Box.Visible = false
        Box.Color = Color3.new(1, 1, 1)
        Box.Thickness = 1
        Box.Transparency = 1
        Box.Filled = false

        local PlayerInfo = Drawing.new("Text")
        PlayerInfo.Text = player.Name
        PlayerInfo.Color = Color3.new(1, 1, 1)
        PlayerInfo.Size = 12
        PlayerInfo.Visible = false
        PlayerInfo.Outline = true
        PlayerInfo.Center = true
        PlayerInfo.Font = 2

        local lineTracer = Drawing.new("Line")
        lineTracer.Visible = false
        lineTracer.Color = Color3.new(1, 1, 1)

        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.Enabled = false
        highlight.FillColor = Color3.new(1, 0, 0)
        highlight.OutlineColor = Color3.new(1, 1, 1)

        ESP[player] = {
            PlayerEquipment = PlayerEquipment,
            BoxOutline = BoxOutline,
            Box = Box,
            PlayerInfo = PlayerInfo,
            lineTracer = lineTracer,
            highlight = highlight,
        }
    end

    if player.Character then
        characterAdded(player.Character)
    end
    player.CharacterAdded:Connect(characterAdded)
end

local function updateESP()
    for player, elements in pairs(ESP) do
        local character = player.Character
        if character and character:IsDescendantOf(workspace) and character:FindFirstChild("HumanoidRootPart") then
            local RootPart = character:FindFirstChild("HumanoidRootPart")
            local Head = character:FindFirstChild("Head") or RootPart
            local screenPosition, isVisible = Camera:WorldToViewportPoint(RootPart.Position)

            local RootPosition = worldToViewportPoint(CurrentCamera, RootPart.Position)
            local HeadPosition = worldToViewportPoint(CurrentCamera, Head.Position + Headoff)
            local LegPosition = worldToViewportPoint(CurrentCamera, RootPart.Position - Legoff)

            local CameraPosition = Camera.CFrame.Position
            local DistanceInMeters = studsToMeters(calculateDistance(RootPart.Position, CameraPosition))

            if isVisible then
                if ESPEnabled then
                    elements.PlayerEquipment.Visible = Options.PlayerEquipment
                    if Options.PlayerEquipment then
                        local CurrentSlotSelected = player.CurrentSelected.Value
                        local SlotName = string.format("Slot%i", CurrentSlotSelected)
                        local Slot = player.GunInventory:FindFirstChild(SlotName).Value or "None"

                        Slot = tostring(Slot)

                        elements.PlayerEquipment.Position = Vector2.new(elements.Box.Position.X + elements.Box.Size.X / 2, elements.Box.Position.Y + elements.Box.Size.Y - 15)
                        elements.PlayerEquipment.Text = Slot
                    end

                    elements.BoxOutline.Visible = Options.Box
                    elements.Box.Visible = Options.Box

                    elements.BoxOutline.Size = Vector2.new(1000 / RootPosition.Z * 2, HeadPosition.Y - LegPosition.Y)
                    elements.BoxOutline.Position = Vector2.new(RootPosition.X - elements.BoxOutline.Size.X / 2, RootPosition.Y - elements.BoxOutline.Size.Y / 2)

                    elements.Box.Size = Vector2.new(1000 / RootPosition.Z * 2, HeadPosition.Y - LegPosition.Y)
                    elements.Box.Position = Vector2.new(RootPosition.X - elements.Box.Size.X / 2, RootPosition.Y - elements.Box.Size.Y / 2)

                    elements.PlayerInfo.Visible = Options.NameDistance
                    elements.PlayerInfo.Position = Vector2.new(LegPosition.X, LegPosition.Y)
                    elements.PlayerInfo.Text = string.format("%s (%.1fm)", player.Name, DistanceInMeters)

                    elements.lineTracer.Visible = Options.LineTracer
                    if Options.LineTracer then
                        elements.lineTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        elements.lineTracer.To = Vector2.new(screenPosition.X, screenPosition.Y)
                    end
                else
                    elements.PlayerEquipment.Visible = false
                    elements.BoxOutline.Visible = false
                    elements.Box.Visible = false
                    elements.PlayerInfo.Visible = false
                    elements.lineTracer.Visible = false
                end

                elements.highlight.Enabled = ChamsEnabled
            else
                elements.PlayerEquipment.Visible = false
                elements.BoxOutline.Visible = false
                elements.Box.Visible = false
                elements.PlayerInfo.Visible = false
                elements.lineTracer.Visible = false
                elements.highlight.Enabled = false
            end
        else
            removeESP(player)
        end
    end
end

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    updateESP()
end)

local function toggleESP()
    ESPEnabled = not ESPEnabled
end

local function toggleChams()
    ChamsEnabled = not ChamsEnabled
end

local function toggleOption(option)
    if Options[option] ~= nil then
        Options[option] = not Options[option]
    end
end

local UserInputService = game:GetService("UserInputService")

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local ESPButton = Instance.new("TextButton")
local BoxButton = Instance.new("TextButton")
local NameDistanceButton = Instance.new("TextButton")
local LineTracerButton = Instance.new("TextButton")
local PlayerEquipmentButton = Instance.new("TextButton")
local ChamsButton = Instance.new("TextButton")

local function ToggleInterface()
    IsOpen = not IsOpen
    MainFrame.Visible = IsOpen
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        ToggleInterface()
    end
end)

ScreenGui.Parent = game.CoreGui
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 200, 0, 370)
MainFrame.Position = UDim2.new(0, 100, 0, 100)
MainFrame.BackgroundTransparency = 0.5
MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)

ESPButton.Size = UDim2.new(0, 200, 0, 50)
ESPButton.Position = UDim2.new(0, 0, 0, 10)
ESPButton.Text = "Toggle ESP"
ESPButton.Parent = MainFrame

BoxButton.Size = UDim2.new(0, 200, 0, 50)
BoxButton.Position = UDim2.new(0, 0, 0, 70)
BoxButton.Text = "Toggle Box"
BoxButton.Parent = MainFrame

NameDistanceButton.Size = UDim2.new(0, 200, 0, 50)
NameDistanceButton.Position = UDim2.new(0, 0, 0, 130)
NameDistanceButton.Text = "Toggle Name/Distance"
NameDistanceButton.Parent = MainFrame

LineTracerButton.Size = UDim2.new(0, 200, 0, 50)
LineTracerButton.Position = UDim2.new(0, 0, 0, 190)
LineTracerButton.Text = "Toggle Line Tracer"
LineTracerButton.Parent = MainFrame

PlayerEquipmentButton.Size = UDim2.new(0, 200, 0, 50)
PlayerEquipmentButton.Position = UDim2.new(0, 0, 0, 250)
PlayerEquipmentButton.Text = "Toggle Player Equipment"
PlayerEquipmentButton.Parent = MainFrame

ChamsButton.Size = UDim2.new(0, 200, 0, 50)
ChamsButton.Position = UDim2.new(0, 0, 0, 310)
ChamsButton.Text = "Toggle Chams"
ChamsButton.Parent = MainFrame

ESPButton.MouseButton1Click:Connect(function()
    toggleESP()
    ESPButton.Text = "ESP: " .. (ESPEnabled and "ON" or "OFF")
end)

BoxButton.MouseButton1Click:Connect(function()
    toggleOption("Box")
    BoxButton.Text = "Box: " .. (Options.Box and "ON" or "OFF")
end)

NameDistanceButton.MouseButton1Click:Connect(function()
    toggleOption("NameDistance")
    NameDistanceButton.Text = "Name/Distance: " .. (Options.NameDistance and "ON" or "OFF")
end)

LineTracerButton.MouseButton1Click:Connect(function()
    toggleOption("LineTracer")
    LineTracerButton.Text = "Line Tracer: " .. (Options.LineTracer and "ON" or "OFF")
end)

PlayerEquipmentButton.MouseButton1Click:Connect(function()
    toggleOption("PlayerEquipment")
    PlayerEquipmentButton.Text = "Player Equipment: " .. (Options.PlayerEquipment and "ON" or "OFF")
end)

ChamsButton.MouseButton1Click:Connect(function()
    toggleChams()
    ChamsButton.Text = "Chams: " .. (ChamsEnabled and "ON" or "OFF")
end)

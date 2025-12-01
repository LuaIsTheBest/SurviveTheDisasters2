local MatchaUI = {}
MatchaUI.__index = MatchaUI

-- services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI State
local activeWindows = {}
local draggingWindow = nil
local dragOffset = Vector2.new(0, 0)

-- Colors
local Colors = {
    WindowBackground = Color3.fromRGB(25, 25, 25),
    WindowBorder = Color3.fromRGB(50, 50, 50),
    TitleBar = Color3.fromRGB(35, 35, 35),
    Button = Color3.fromRGB(45, 45, 45),
    ButtonHover = Color3.fromRGB(60, 60, 60),
    ButtonActive = Color3.fromRGB(80, 80, 80),
    Toggle = Color3.fromRGB(45, 45, 45),
    ToggleActive = Color3.fromRGB(60, 150, 60),
    Slider = Color3.fromRGB(45, 45, 45),
    SliderFill = Color3.fromRGB(60, 150, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180)
}

-- Helper: Check if point is in rectangle
local function pointInRect(point, pos, size)
    return point.X >= pos.X and point.X <= pos.X + size.X and
           point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

-- Helper: Get mouse position
local function getMousePosition()
    local mouse = LocalPlayer:GetMouse()
    return Vector2.new(mouse.X, mouse.Y)
end

-- ================================
-- WINDOW CLASS
-- ================================

local Window = {}
Window.__index = Window

function MatchaUI:CreateWindow(title, size)
    local self = setmetatable({}, Window)
    
    size = size or Vector2.new(400, 500)
    self.title = title or "Window"
    self.position = Vector2.new(100, 100)
    self.size = size
    self.visible = true
    self.dragging = false
    self.elements = {}
    self.nextY = 35 -- Start below title bar
    
    -- Create window background
    self.background = Drawing.new("Square")
    self.background.Size = size
    self.background.Position = self.position
    self.background.Color = Colors.WindowBackground
    self.background.Filled = true
    self.background.Visible = true
    self.background.ZIndex = 1
    
    -- Create window border
    self.border = Drawing.new("Square")
    self.border.Size = size
    self.border.Position = self.position
    self.border.Color = Colors.WindowBorder
    self.border.Filled = false
    self.border.Visible = true
    self.border.ZIndex = 2
    self.border.Thickness = 2
    
    -- Create title bar
    self.titleBar = Drawing.new("Square")
    self.titleBar.Size = Vector2.new(size.X, 30)
    self.titleBar.Position = self.position
    self.titleBar.Color = Colors.TitleBar
    self.titleBar.Filled = true
    self.titleBar.Visible = true
    self.titleBar.ZIndex = 3
    
    -- Create title text
    self.titleText = Drawing.new("Text")
    self.titleText.Text = title
    self.titleText.Position = Vector2.new(self.position.X + 10, self.position.Y + 8)
    self.titleText.Color = Colors.Text
    self.titleText.Visible = true
    self.titleText.ZIndex = 4
    self.titleText.Outline = true
    self.titleText.Center = false
    
    table.insert(activeWindows, self)
    return self
end

function Window:SetVisible(visible)
    self.visible = visible
    self.background.Visible = visible
    self.border.Visible = visible
    self.titleBar.Visible = visible
    self.titleText.Visible = visible
    
    for _, element in pairs(self.elements) do
        if element.SetVisible then
            element:SetVisible(visible)
        end
    end
end

function Window:SetPosition(pos)
    local offset = Vector2.new(pos.X - self.position.X, pos.Y - self.position.Y)
    self.position = pos
    
    self.background.Position = pos
    self.border.Position = pos
    self.titleBar.Position = pos
    self.titleText.Position = Vector2.new(pos.X + 10, pos.Y + 8)
    
    -- Update all element positions
    for _, element in pairs(self.elements) do
        if element.UpdatePosition then
            element:UpdatePosition(offset)
        end
    end
end

function Window:Remove()
    self.background:Remove()
    self.border:Remove()
    self.titleBar:Remove()
    self.titleText:Remove()
    
    for _, element in pairs(self.elements) do
        if element.Remove then
            element:Remove()
        end
    end
    
    for i, win in pairs(activeWindows) do
        if win == self then
            table.remove(activeWindows, i)
            break
        end
    end
end

-- ================================
-- BUTTON ELEMENT
-- ================================

function Window:AddButton(text, callback)
    local button = {}
    
    local yPos = self.position.Y + self.nextY
    local padding = 10
    
    -- Button background
    button.background = Drawing.new("Square")
    button.background.Size = Vector2.new(self.size.X - (padding * 2), 30)
    button.background.Position = Vector2.new(self.position.X + padding, yPos)
    button.background.Color = Colors.Button
    button.background.Filled = true
    button.background.Visible = self.visible
    button.background.ZIndex = 5
    
    -- Button text
    button.text = Drawing.new("Text")
    button.text.Text = text
    button.text.Position = Vector2.new(self.position.X + self.size.X / 2, yPos + 8)
    button.text.Color = Colors.Text
    button.text.Visible = self.visible
    button.text.ZIndex = 6
    button.text.Outline = true
    button.text.Center = true
    
    button.callback = callback
    button.position = Vector2.new(self.position.X + padding, yPos)
    button.size = Vector2.new(self.size.X - (padding * 2), 30)
    
    function button:SetVisible(visible)
        self.background.Visible = visible
        self.text.Visible = visible
    end
    
    function button:UpdatePosition(offset)
        self.position = Vector2.new(self.position.X + offset.X, self.position.Y + offset.Y)
        self.background.Position = self.position
        self.text.Position = Vector2.new(self.text.Position.X + offset.X, self.text.Position.Y + offset.Y)
    end
    
    function button:Remove()
        self.background:Remove()
        self.text:Remove()
    end
    
    table.insert(self.elements, button)
    self.nextY = self.nextY + 40
    
    return button
end

-- ================================
-- TOGGLE ELEMENT
-- ================================

function Window:AddToggle(text, default, callback)
    local toggle = {}
    toggle.enabled = default or false
    toggle.callback = callback
    
    local yPos = self.position.Y + self.nextY
    local padding = 10
    
    -- Toggle box
    toggle.box = Drawing.new("Square")
    toggle.box.Size = Vector2.new(20, 20)
    toggle.box.Position = Vector2.new(self.position.X + padding, yPos + 5)
    toggle.box.Color = toggle.enabled and Colors.ToggleActive or Colors.Toggle
    toggle.box.Filled = true
    toggle.box.Visible = self.visible
    toggle.box.ZIndex = 5
    
    -- Toggle text
    toggle.text = Drawing.new("Text")
    toggle.text.Text = text
    toggle.text.Position = Vector2.new(self.position.X + padding + 30, yPos + 8)
    toggle.text.Color = Colors.Text
    toggle.text.Visible = self.visible
    toggle.text.ZIndex = 6
    toggle.text.Outline = true
    toggle.text.Center = false
    
    toggle.position = Vector2.new(self.position.X + padding, yPos)
    toggle.size = Vector2.new(self.size.X - (padding * 2), 30)
    
    function toggle:SetValue(value)
        self.enabled = value
        self.box.Color = value and Colors.ToggleActive or Colors.Toggle
        if self.callback then
            self.callback(value)
        end
    end
    
    function toggle:SetVisible(visible)
        self.box.Visible = visible
        self.text.Visible = visible
    end
    
    function toggle:UpdatePosition(offset)
        self.position = Vector2.new(self.position.X + offset.X, self.position.Y + offset.Y)
        self.box.Position = Vector2.new(self.box.Position.X + offset.X, self.box.Position.Y + offset.Y)
        self.text.Position = Vector2.new(self.text.Position.X + offset.X, self.text.Position.Y + offset.Y)
    end
    
    function toggle:Remove()
        self.box:Remove()
        self.text:Remove()
    end
    
    table.insert(self.elements, toggle)
    self.nextY = self.nextY + 40
    
    return toggle
end

-- ================================
-- SLIDER ELEMENT
-- ================================

function Window:AddSlider(text, min, max, default, callback)
    local slider = {}
    slider.min = min or 0
    slider.max = max or 100
    slider.value = default or min
    slider.callback = callback
    slider.dragging = false
    
    local yPos = self.position.Y + self.nextY
    local padding = 10
    local sliderWidth = self.size.X - (padding * 2)
    
    -- Slider text
    slider.text = Drawing.new("Text")
    slider.text.Text = text .. ": " .. tostring(slider.value)
    slider.text.Position = Vector2.new(self.position.X + padding, yPos)
    slider.text.Color = Colors.Text
    slider.text.Visible = self.visible
    slider.text.ZIndex = 6
    slider.text.Outline = true
    slider.text.Center = false
    
    -- Slider background
    slider.background = Drawing.new("Square")
    slider.background.Size = Vector2.new(sliderWidth, 10)
    slider.background.Position = Vector2.new(self.position.X + padding, yPos + 20)
    slider.background.Color = Colors.Slider
    slider.background.Filled = true
    slider.background.Visible = self.visible
    slider.background.ZIndex = 5
    
    -- Slider fill
    local fillWidth = ((slider.value - slider.min) / (slider.max - slider.min)) * sliderWidth
    slider.fill = Drawing.new("Square")
    slider.fill.Size = Vector2.new(fillWidth, 10)
    slider.fill.Position = Vector2.new(self.position.X + padding, yPos + 20)
    slider.fill.Color = Colors.SliderFill
    slider.fill.Filled = true
    slider.fill.Visible = self.visible
    slider.fill.ZIndex = 6
    
    slider.position = Vector2.new(self.position.X + padding, yPos)
    slider.size = Vector2.new(sliderWidth, 30)
    slider.baseText = text
    
    function slider:SetValue(value)
        value = math.clamp(value, self.min, self.max)
        self.value = value
        
        local fillWidth = ((value - self.min) / (self.max - self.min)) * (self.size.X)
        self.fill.Size = Vector2.new(fillWidth, 10)
        self.text.Text = self.baseText .. ": " .. tostring(math.floor(value * 100) / 100)
        
        if self.callback then
            self.callback(value)
        end
    end
    
    function slider:SetVisible(visible)
        self.text.Visible = visible
        self.background.Visible = visible
        self.fill.Visible = visible
    end
    
    function slider:UpdatePosition(offset)
        self.position = Vector2.new(self.position.X + offset.X, self.position.Y + offset.Y)
        self.text.Position = Vector2.new(self.text.Position.X + offset.X, self.text.Position.Y + offset.Y)
        self.background.Position = Vector2.new(self.background.Position.X + offset.X, self.background.Position.Y + offset.Y)
        self.fill.Position = Vector2.new(self.fill.Position.X + offset.X, self.fill.Position.Y + offset.Y)
    end
    
    function slider:Remove()
        self.text:Remove()
        self.background:Remove()
        self.fill:Remove()
    end
    
    table.insert(self.elements, slider)
    self.nextY = self.nextY + 45
    
    return slider
end

-- ================================
-- LABEL ELEMENT
-- ================================

function Window:AddLabel(text)
    local label = {}
    
    local yPos = self.position.Y + self.nextY
    local padding = 10
    
    label.text = Drawing.new("Text")
    label.text.Text = text
    label.text.Position = Vector2.new(self.position.X + padding, yPos)
    label.text.Color = Colors.TextDim
    label.text.Visible = self.visible
    label.text.ZIndex = 6
    label.text.Outline = true
    label.text.Center = false
    
    label.position = Vector2.new(self.position.X + padding, yPos)
    
    function label:SetText(newText)
        self.text.Text = newText
    end
    
    function label:SetVisible(visible)
        self.text.Visible = visible
    end
    
    function label:UpdatePosition(offset)
        self.position = Vector2.new(self.position.X + offset.X, self.position.Y + offset.Y)
        self.text.Position = Vector2.new(self.text.Position.X + offset.X, self.text.Position.Y + offset.Y)
    end
    
    function label:Remove()
        self.text:Remove()
    end
    
    table.insert(self.elements, label)
    self.nextY = self.nextY + 25
    
    return label
end

-- ================================
-- DROPDOWN ELEMENT
-- ================================

function Window:AddDropdown(text, options, default, callback)
    local dropdown = {}
    dropdown.options = options or {}
    dropdown.selected = default or (options and options[1]) or "None"
    dropdown.callback = callback
    dropdown.expanded = false
    
    local yPos = self.position.Y + self.nextY
    local padding = 10
    local dropdownWidth = self.size.X - (padding * 2)
    
    -- Dropdown button
    dropdown.button = Drawing.new("Square")
    dropdown.button.Size = Vector2.new(dropdownWidth, 30)
    dropdown.button.Position = Vector2.new(self.position.X + padding, yPos)
    dropdown.button.Color = Colors.Button
    dropdown.button.Filled = true
    dropdown.button.Visible = self.visible
    dropdown.button.ZIndex = 5
    
    -- Dropdown text
    dropdown.text = Drawing.new("Text")
    dropdown.text.Text = text .. ": " .. dropdown.selected
    dropdown.text.Position = Vector2.new(self.position.X + padding + 10, yPos + 8)
    dropdown.text.Color = Colors.Text
    dropdown.text.Visible = self.visible
    dropdown.text.ZIndex = 6
    dropdown.text.Outline = true
    dropdown.text.Center = false
    
    dropdown.position = Vector2.new(self.position.X + padding, yPos)
    dropdown.size = Vector2.new(dropdownWidth, 30)
    dropdown.baseText = text
    dropdown.optionElements = {}
    
    function dropdown:SetValue(value)
        self.selected = value
        self.text.Text = self.baseText .. ": " .. value
        if self.callback then
            self.callback(value)
        end
    end
    
    function dropdown:SetVisible(visible)
        self.button.Visible = visible
        self.text.Visible = visible
        if not visible then
            self.expanded = false
            for _, opt in pairs(self.optionElements) do
                opt.background.Visible = false
                opt.text.Visible = false
            end
        end
    end
    
    function dropdown:UpdatePosition(offset)
        self.position = Vector2.new(self.position.X + offset.X, self.position.Y + offset.Y)
        self.button.Position = Vector2.new(self.button.Position.X + offset.X, self.button.Position.Y + offset.Y)
        self.text.Position = Vector2.new(self.text.Position.X + offset.X, self.text.Position.Y + offset.Y)
        
        for i, opt in pairs(self.optionElements) do
            opt.position = Vector2.new(opt.position.X + offset.X, opt.position.Y + offset.Y)
            opt.background.Position = Vector2.new(opt.background.Position.X + offset.X, opt.background.Position.Y + offset.Y)
            opt.text.Position = Vector2.new(opt.text.Position.X + offset.X, opt.text.Position.Y + offset.Y)
        end
    end
    
    function dropdown:Remove()
        self.button:Remove()
        self.text:Remove()
        for _, opt in pairs(self.optionElements) do
            opt.background:Remove()
            opt.text:Remove()
        end
    end
    
    table.insert(self.elements, dropdown)
    self.nextY = self.nextY + 40
    
    return dropdown
end

-- ================================
-- INPUT HANDLING
-- ================================

spawn(function()
    local mouse1WasPressed = false
    
    while true do
        local mouse1Pressed = ismouse1pressed()
        local mousePos = getMousePosition()
        
        -- Handle mouse click
        if mouse1Pressed and not mouse1WasPressed then
            -- Check window dragging
            for _, window in pairs(activeWindows) do
                if window.visible then
                    local titleBarPos = window.position
                    local titleBarSize = Vector2.new(window.size.X, 30)
                    
                    if pointInRect(mousePos, titleBarPos, titleBarSize) then
                        draggingWindow = window
                        dragOffset = Vector2.new(mousePos.X - window.position.X, mousePos.Y - window.position.Y)
                        break
                    end
                    
                    -- Check button clicks
                    for _, element in pairs(window.elements) do
                        if element.background and pointInRect(mousePos, element.position, element.size) then
                            -- Button click
                            if element.callback and not element.enabled and not element.value then
                                element.callback()
                            end
                            -- Toggle click
                            if element.enabled ~= nil then
                                element:SetValue(not element.enabled)
                            end
                            -- Dropdown click
                            if element.expanded ~= nil then
                                element.expanded = not element.expanded
                                -- Toggle option visibility
                                for _, opt in pairs(element.optionElements) do
                                    opt.background.Visible = element.expanded
                                    opt.text.Visible = element.expanded
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Handle window dragging
        if draggingWindow and mouse1Pressed then
            local newPos = Vector2.new(mousePos.X - dragOffset.X, mousePos.Y - dragOffset.Y)
            draggingWindow:SetPosition(newPos)
        end
        
        -- Handle slider dragging
        for _, window in pairs(activeWindows) do
            if window.visible then
                for _, element in pairs(window.elements) do
                    if element.min and element.max then -- It's a slider
                        local sliderBgPos = Vector2.new(element.position.X, element.position.Y + 20)
                        local sliderBgSize = Vector2.new(element.size.X, 10)
                        
                        if mouse1Pressed and pointInRect(mousePos, sliderBgPos, sliderBgSize) then
                            element.dragging = true
                        end
                        
                        if element.dragging and mouse1Pressed then
                            local relativeX = mousePos.X - sliderBgPos.X
                            local percentage = math.clamp(relativeX / sliderBgSize.X, 0, 1)
                            local newValue = element.min + (percentage * (element.max - element.min))
                            element:SetValue(newValue)
                        end
                        
                        if not mouse1Pressed then
                            element.dragging = false
                        end
                    end
                end
            end
        end
        
        -- Release dragging
        if not mouse1Pressed then
            draggingWindow = nil
        end
        
        mouse1WasPressed = mouse1Pressed
        wait(0.01)
    end
end)

return MatchaUI

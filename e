--[[
	AuroraUI — Executor UI Library
	--------------------------------------------------------------
	Designed for Roblox EXECUTORS (Synapse X, Script-Ware, KRNL,
	Fluxus, Celery, etc.) — NOT Roblox Studio's require()/ModuleScript
	workflow. Load it with loadstring and it hands you back a table.

	LOAD:
		local AuroraUI = loadstring(game:HttpGet(
			"https://your-host/AuroraUI.lua"
		))()

		-- or, if you already have the source as a string in your script:
		-- local AuroraUI = loadstring(SOURCE_STRING)()

	QUICK START:
		local Window = AuroraUI.CreateWindow({
			Title = "jatos cheetos",
			Size  = UDim2.new(0, 404, 0, 312),
			ToggleKey = Enum.KeyCode.RightShift,
		})

		local Tab = Window:CreateTab("Player ESP")
		Tab.Left:AddToggle("Look Direction", true, function(v) print(v) end)
		Tab.Right:AddSlider("Distance", 0, 1000, 200, function(v) print(v) end)

	NOTES ON EXECUTOR SAFETY:
		* GUI is parented to gethui() (if present) or CoreGui, with a
		  PlayerGui fallback for executors that don't expose either.
		* syn.protect_gui / protect_gui-style hooks are used opportunistically
		  so the interface isn't nuked by games that scan PlayerGui.
		* Instance names are randomized per-session to reduce fingerprinting.
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--=========================================================================--
-- 0. EXECUTOR-SAFE GUI PARENTING
--=========================================================================--
-- Resolves the best available parent for our ScreenGui across different
-- executor environments, and applies gui-protection if the executor exposes it.
local function resolveGuiParent()
	local ok, hiddenUI = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hiddenUI then
		return hiddenUI
	end

	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		return coreGui
	end

	return LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(screenGui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(screenGui)
		elseif typeof(protect_gui) == "function" then
			protect_gui(screenGui)
		end
	end)
end

local function randomName(prefix)
	return string.format("%s_%d", prefix, math.random(100000, 999999))
end

--=========================================================================--
-- 1. THEME
--=========================================================================--
local Theme = {
	Background   = Color3.fromRGB(30, 30, 30),
	Header       = Color3.fromRGB(21, 21, 21),
	TabBar       = Color3.fromRGB(26, 26, 26),
	TabActive    = Color3.fromRGB(40, 40, 40),
	TabHover     = Color3.fromRGB(34, 34, 34),
	Border       = Color3.fromRGB(46, 46, 46),
	Divider      = Color3.fromRGB(44, 44, 44),
	Text         = Color3.fromRGB(225, 225, 225),
	SubText      = Color3.fromRGB(150, 150, 150),
	Accent       = Color3.fromRGB(76, 208, 199),
	ToggleOff    = Color3.fromRGB(55, 55, 55),
	SliderTrack  = Color3.fromRGB(50, 50, 50),
	InputBg      = Color3.fromRGB(23, 23, 23),
	Danger       = Color3.fromRGB(232, 93, 93),
	Font         = Enum.Font.Gotham,
	FontMedium   = Enum.Font.GothamMedium,
	FontBold     = Enum.Font.GothamBold,
	TextSize     = 12,
}

--=========================================================================--
-- 2. UTILITY
--=========================================================================--
local function Create(className, props)
	assert(type(className) == "string", "Create: className must be a string")
	local inst = Instance.new(className)
	local parent = props and props.Parent
	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				inst[key] = value
			end
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Tween(inst, props, duration, style, direction)
	local info = TweenInfo.new(
		duration or 0.15,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
	local tw = TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

--=========================================================================--
-- 3. SECTION (a scrollable column that hosts toggles/sliders/etc.)
--=========================================================================--
local Section = {}
Section.__index = Section

function Section.new(scrollFrame, window)
	local self = setmetatable({}, Section)
	self.Frame  = scrollFrame
	self.Window = window
	self.Order  = 0
	return self
end

function Section:_next()
	self.Order += 1
	return self.Order
end

local function makeIcon(parent, window)
	local icon = Create("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new(0, 0, 0.5, -4),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = icon })
	window:_registerAccent(icon, "BackgroundColor3")
	return icon
end

local function makeSwitch(parent, window, default, posOffsetX, callback)
	local switch = Create("TextButton", {
		Size = UDim2.new(0, 26, 0, 12),
		Position = UDim2.new(1, posOffsetX, 0.5, -6),
		BackgroundColor3 = default and Theme.Accent or Theme.ToggleOff,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switch })

	local knob = Create("Frame", {
		Size = UDim2.new(0, 10, 0, 10),
		Position = default and UDim2.new(1, -11, 0.5, -5) or UDim2.new(0, 1, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = switch,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local state = default and true or false

	local function setState(v, fire)
		state = v
		local color = v and Theme.Accent or Theme.ToggleOff
		Tween(switch, { BackgroundColor3 = color }, 0.15)
		Tween(knob, { Position = v and UDim2.new(1, -11, 0.5, -5) or UDim2.new(0, 1, 0.5, -5) }, 0.15)
		if fire ~= false and callback then
			task.spawn(callback, v)
		end
	end

	switch.MouseButton1Click:Connect(function()
		setState(not state)
	end)
	switch.MouseEnter:Connect(function()
		Tween(switch, { BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(70, 70, 70) }, 0.1)
	end)
	switch.MouseLeave:Connect(function()
		Tween(switch, { BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff }, 0.1)
	end)

	window:_registerAccent(switch, "BackgroundColor3", function() return state end)

	return switch, function() return state end, setState
end

function Section:AddToggle(text, default, callback)
	assert(type(text) == "string", "AddToggle: text must be a string")
	default = default and true or false

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})

	makeIcon(row, self.Window)

	Create("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local _, getState, setState = makeSwitch(row, self.Window, default, -26, callback)

	return {
		Set = function(_, v) setState(v, true) end,
		Get = function() return getState() end,
	}
end

function Section:AddDualToggle(text, default1, default2, callback1, callback2)
	assert(type(text) == "string", "AddDualToggle: text must be a string")

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})

	makeIcon(row, self.Window)

	Create("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local _, getA, setA = makeSwitch(row, self.Window, default1, -58, callback1)
	local _, getB, setB = makeSwitch(row, self.Window, default2, -26, callback2)

	return {
		Set = function(_, a, b) setA(a, true); setB(b, true) end,
		Get = function() return getA(), getB() end,
	}
end

function Section:AddColorToggle(text, defaultColor, callback)
	defaultColor = defaultColor or Color3.fromRGB(255, 221, 51)

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		ZIndex = 3,
		Parent = self.Frame,
	})

	makeIcon(row, self.Window)

	Create("TextLabel", {
		Size = UDim2.new(1, -34, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local swatch = Create("TextButton", {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(1, -14, 0.5, -7),
		BackgroundColor3 = defaultColor,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = row,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = swatch })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = swatch })

	local palette = {
		Color3.fromRGB(255, 221, 51), Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 255, 120),
		Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 255, 255), Theme.Accent,
		Color3.fromRGB(255, 140, 0), Color3.fromRGB(190, 80, 255),
	}

	local popup = Create("Frame", {
		Size = UDim2.new(0, 88, 0, 42),
		Position = UDim2.new(1, -88, 1, 4),
		BackgroundColor3 = Theme.InputBg,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 10,
		Parent = row,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = popup })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = popup })
	Create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), Parent = popup })
	Create("UIGridLayout", {
		CellSize = UDim2.new(0, 18, 0, 18),
		CellPadding = UDim2.new(0, 2, 0, 2),
		Parent = popup,
	})

	for _, c in ipairs(palette) do
		local swBtn = Create("TextButton", {
			Size = UDim2.new(0, 18, 0, 18),
			BackgroundColor3 = c,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 10,
			Parent = popup,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = swBtn })
		swBtn.MouseButton1Click:Connect(function()
			swatch.BackgroundColor3 = c
			popup.Visible = false
			if callback then task.spawn(callback, c) end
		end)
	end

	swatch.MouseButton1Click:Connect(function()
		popup.Visible = not popup.Visible
	end)

	return {
		Set = function(_, c) swatch.BackgroundColor3 = c end,
		Get = function() return swatch.BackgroundColor3 end,
	}
end

function Section:AddSlider(text, min, max, default, callback, opts)
	assert(type(min) == "number" and type(max) == "number" and min < max, "AddSlider: invalid min/max")
	opts = opts or {}
	local suffix = opts.Suffix or ""
	local step = opts.Step or 1
	default = math.clamp(default or min, min, max)

	local container = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})

	local label = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = ("%s: %d%s"):format(text, default, suffix),
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local minusBtn = Create("TextButton", {
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, 0, 0, 19),
		BackgroundColor3 = Theme.SliderTrack,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "-",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Theme.SubText,
		Parent = container,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = minusBtn })

	local plusBtn = Create("TextButton", {
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(1, -10, 0, 19),
		BackgroundColor3 = Theme.SliderTrack,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "+",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Theme.SubText,
		Parent = container,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = plusBtn })

	local track = Create("Frame", {
		Size = UDim2.new(1, -26, 0, 3),
		Position = UDim2.new(0, 13, 0, 23),
		BackgroundColor3 = Theme.SliderTrack,
		BorderSizePixel = 0,
		Parent = container,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = Create("Frame", {
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local knob = Create("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new((default - min) / (max - min), -4, 0.5, -4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	self.Window:_registerAccent(fill, "BackgroundColor3")

	local value = default
	local dragging = false

	local function apply(v)
		v = math.clamp(v, min, max)
		v = math.floor((v - min) / step + 0.5) * step + min
		v = math.clamp(v, min, max)
		value = v
		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -4, 0.5, -4)
		label.Text = ("%s: %d%s"):format(text, value, suffix)
		if callback then task.spawn(callback, value) end
	end

	local function updateFromX(px)
		local rel = (px - track.AbsolutePosition.X) / track.AbsoluteSize.X
		apply(min + (max - min) * math.clamp(rel, 0, 1))
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)

	self.Window:_track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))

	self.Window:_track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	minusBtn.MouseButton1Click:Connect(function() apply(value - step) end)
	plusBtn.MouseButton1Click:Connect(function() apply(value + step) end)

	return {
		Set = function(_, v) apply(v) end,
		Get = function() return value end,
	}
end

function Section:AddDropdown(text, options, default, callback)
	assert(type(options) == "table" and #options > 0, "AddDropdown: options must be a non-empty array")
	default = default or options[1]

	local container = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		ZIndex = 3,
		Parent = self.Frame,
	})

	Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local box = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 16),
		BackgroundColor3 = Theme.InputBg,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "  " .. tostring(default),
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = container,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = box })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = box })

	Create("TextLabel", {
		Size = UDim2.new(0, 16, 1, 0),
		Position = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		Text = "▾",
		TextColor3 = Theme.SubText,
		Font = Theme.Font,
		TextSize = 11,
		ZIndex = 3,
		Parent = box,
	})

	local list = Create("Frame", {
		Size = UDim2.new(1, 0, 0, #options * 16),
		Position = UDim2.new(0, 0, 1, 2),
		BackgroundColor3 = Theme.InputBg,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 10,
		Parent = box,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = list })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = list })
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	for i, opt in ipairs(options) do
		local optBtn = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundColor3 = Theme.InputBg,
			AutoButtonColor = false,
			Text = "  " .. tostring(opt),
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 10,
			LayoutOrder = i,
			Parent = list,
		})
		optBtn.MouseEnter:Connect(function() Tween(optBtn, { BackgroundColor3 = Theme.TabHover }, 0.1) end)
		optBtn.MouseLeave:Connect(function() Tween(optBtn, { BackgroundColor3 = Theme.InputBg }, 0.1) end)
		optBtn.MouseButton1Click:Connect(function()
			box.Text = "  " .. tostring(opt)
			list.Visible = false
			if callback then task.spawn(callback, opt) end
		end)
	end

	box.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
	end)

	return {
		Set = function(_, v) box.Text = "  " .. tostring(v) end,
		Get = function() return (box.Text:gsub("^%s+", "")) end,
	}
end

function Section:AddLabel(text)
	return Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})
end

--=========================================================================--
-- 4. WINDOW / LIBRARY
--=========================================================================--
local Library = {}
Library.__index = Library
Library.Theme = Theme

local function makeColumn(parent, name, positionScale)
	local frame = Create("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(0.5, -9, 1, -8),
		Position = UDim2.new(positionScale, positionScale == 0 and 6 or 4, 0, 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = frame,
	})
	return frame
end

--- Creates the main window. config: { Title, Size, ToggleKey }
function Library.CreateWindow(config)
	config = config or {}
	assert(type(config) == "table", "CreateWindow: config must be a table")

	local title = config.Title or "Window"
	local size = config.Size or UDim2.new(0, 404, 0, 312)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

	local self = setmetatable({}, Library)
	self.Tabs = {}
	self.Connections = {}
	self._accentObjects = {}
	self.Minimized = false

	local guiParent = resolveGuiParent()

	local screenGui = Create("ScreenGui", {
		Name = randomName("AuroraUI"),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	protectGui(screenGui)
	screenGui.Parent = guiParent
	self.ScreenGui = screenGui

	-- Responsive scaling so the fixed-pixel design holds proportion on any resolution
	local scaler = Create("UIScale", { Parent = screenGui, Scale = 1 })
	local function updateScale()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local vp = camera.ViewportSize
		local scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.55, 1.15)
		Tween(scaler, { Scale = scale }, 0.25)
	end
	updateScale()
	self:_track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale))
	if Workspace.CurrentCamera then
		self:_track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
	end

	-- Main panel
	local main = Create("Frame", {
		Name = "Main",
		Size = size,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = main })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = main })
	self.Main = main
	self.FullSize = size

	-- Title bar
	local titleBar = Create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Theme.Header,
		BorderSizePixel = 0,
		Parent = main,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = titleBar })
	Create("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 1, -8),
		BackgroundColor3 = Theme.Header,
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	Create("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		Font = Theme.FontMedium,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleBar,
	})
	self:_makeDraggable(titleBar, main)

	-- Close button
	local closeBtn = Create("TextButton", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(1, -20, 0.5, -9),
		BackgroundColor3 = Theme.Header,
		AutoButtonColor = false,
		Text = "✕",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { TextColor3 = Theme.Danger }, 0.1) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { TextColor3 = Theme.SubText }, 0.1) end)
	closeBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)

	-- Minimize button
	local minBtn = Create("TextButton", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(1, -40, 0.5, -9),
		BackgroundColor3 = Theme.Header,
		AutoButtonColor = false,
		Text = "—",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	minBtn.MouseEnter:Connect(function() Tween(minBtn, { TextColor3 = Theme.Accent }, 0.1) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn, { TextColor3 = Theme.SubText }, 0.1) end)
	minBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)
	self:_registerAccent(minBtn, "TextColor3", function() return false end) -- no-op placeholder for consistency

	-- Tab bar
	local tabBar = Create("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Theme.TabBar,
		BorderSizePixel = 0,
		Parent = main,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})
	self.TabBar = tabBar

	-- Content area
	local content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundTransparency = 1,
		Parent = main,
	})
	self.Content = content

	-- Notification container (top-right stack)
	local notifRoot = Create("Frame", {
		Name = "Notifications",
		Size = UDim2.new(0, 240, 1, -20),
		Position = UDim2.new(1, -250, 0, 10),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = notifRoot,
	})
	self.NotifRoot = notifRoot

	-- Visibility toggle keybind
	self:_track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			self:SetVisible(not main.Visible)
		end
	end))

	return self
end

function Library:_track(connection)
	table.insert(self.Connections, connection)
	return connection
end

function Library:_registerAccent(inst, prop, onlyIf)
	table.insert(self._accentObjects, { Instance = inst, Property = prop, OnlyIf = onlyIf })
end

--- Dynamically re-theme the accent color
function Library:SetAccent(color)
	Theme.Accent = color
	for _, entry in ipairs(self._accentObjects) do
		if entry.Instance and entry.Instance.Parent then
			if (not entry.OnlyIf) or entry.OnlyIf() then
				Tween(entry.Instance, { [entry.Property] = color }, 0.2)
			end
		end
	end
end

function Library:SetVisible(visible)
	self.Main.Visible = visible
end

--- Collapses the window down to just the title bar (executor-menu convention)
function Library:ToggleMinimize()
	self.Minimized = not self.Minimized
	if self.Minimized then
		self.Content.Visible = false
		self.TabBar.Visible = false
		Tween(self.Main, { Size = UDim2.new(self.FullSize.X.Scale, self.FullSize.X.Offset, 0, 22) }, 0.2)
	else
		Tween(self.Main, { Size = self.FullSize }, 0.2).Completed:Connect(function()
			self.Content.Visible = true
			self.TabBar.Visible = true
		end)
	end
end

function Library:_makeDraggable(handle, target)
	local dragging, dragStart, startPos = false, nil, nil

	self:_track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))

	self:_track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))
end

--- Creates a new tab with two scrollable columns (Left / Right)
function Library:CreateTab(name)
	assert(type(name) == "string", "CreateTab: name must be a string")

	local index = #self.Tabs + 1

	local button = Create("TextButton", {
		Name = name .. "TabButton",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.TabBar,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = name,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		LayoutOrder = index,
		Parent = self.TabBar,
	})

	local underline = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	})
	self:_registerAccent(underline, "BackgroundColor3")

	local page = Create("Frame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Content,
	})

	local leftFrame = makeColumn(page, "Left", 0)
	Create("Frame", {
		Size = UDim2.new(0, 1, 1, -8),
		Position = UDim2.new(0.5, 0, 0, 4),
		BackgroundColor3 = Theme.Divider,
		BorderSizePixel = 0,
		Parent = page,
	})
	local rightFrame = makeColumn(page, "Right", 0.5)

	local tab = {
		Name = name,
		Button = button,
		Page = page,
		Left = Section.new(leftFrame, self),
		Right = Section.new(rightFrame, self),
	}

	table.insert(self.Tabs, tab)

	local n = #self.Tabs
	for _, t in ipairs(self.Tabs) do
		t.Button.Size = UDim2.new(1 / n, 0, 1, 0)
	end

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, { BackgroundColor3 = Theme.TabHover }, 0.15)
		end
	end)
	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, { BackgroundColor3 = Theme.TabBar }, 0.15)
		end
	end)

	if n == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function Library:SelectTab(tab)
	if self.ActiveTab then
		self.ActiveTab.Page.Visible = false
		Tween(self.ActiveTab.Button, { BackgroundColor3 = Theme.TabBar, TextColor3 = Theme.SubText }, 0.15)
		local oldUnderline = self.ActiveTab.Button:FindFirstChildOfClass("Frame")
		if oldUnderline then Tween(oldUnderline, { BackgroundTransparency = 1 }, 0.15) end
	end

	tab.Page.Visible = true
	Tween(tab.Button, { BackgroundColor3 = Theme.TabActive, TextColor3 = Theme.Text }, 0.15)
	local underline = tab.Button:FindFirstChildOfClass("Frame")
	if underline then Tween(underline, { BackgroundTransparency = 0 }, 0.15) end

	self.ActiveTab = tab
end

--- Pops a toast-style notification in the top-right corner
function Library:Notify(titleText, bodyText, duration)
	duration = duration or 3

	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Header,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = os.clock(),
		Parent = self.NotifRoot,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = card })
	local stroke = Create("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 1, Parent = card })

	local accentBar = Create("Frame", {
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = card,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentBar })
	self:_registerAccent(accentBar, "BackgroundColor3")

	local titleLbl = Create("TextLabel", {
		Size = UDim2.new(1, -16, 0, 16),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1,
		Text = titleText or "Notification",
		Font = Theme.FontMedium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local bodyLbl = Create("TextLabel", {
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0, 10, 0, 22),
		BackgroundTransparency = 1,
		Text = bodyText or "",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.SubText,
		TextTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	Tween(card, { BackgroundTransparency = 0 }, 0.2)
	Tween(stroke, { Transparency = 0 }, 0.2)
	Tween(accentBar, { BackgroundTransparency = 0 }, 0.2)
	Tween(titleLbl, { TextTransparency = 0 }, 0.2)
	Tween(bodyLbl, { TextTransparency = 0 }, 0.2)

	task.delay(duration, function()
		if not card.Parent then return end
		Tween(card, { BackgroundTransparency = 1 }, 0.2)
		Tween(stroke, { Transparency = 1 }, 0.2)
		Tween(accentBar, { BackgroundTransparency = 1 }, 0.2)
		Tween(titleLbl, { TextTransparency = 1 }, 0.2)
		Tween(bodyLbl, { TextTransparency = 1 }, 0.2)
		task.wait(0.2)
		card:Destroy()
	end)
end

--- Cleans up all connections and destroys the UI (call when unloading a script)
function Library:Destroy()
	for _, conn in ipairs(self.Connections) do
		pcall(function() conn:Disconnect() end)
	end
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return Library

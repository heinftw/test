--// xanax.ui example | rebuilds the original "xanax" panel through the public API
--// This file is simultaneously the parity proof and the template consumers copy.
--// Requirements: an executor environment (Synapse Z, Wave, Script-Ware, Delta, ...).

-- Raw load URLs for this repository (branch: main).
local LIBRARY_URL = "https://raw.githubusercontent.com/heinftw/test/main/Library"
local SAVE_MANAGER_URL = "https://raw.githubusercontent.com/heinftw/test/main/Save%20Manager"

-- Load the library and the SaveManager (each file ends with `return ...`).
local Library = loadstring(game:HttpGet(LIBRARY_URL))()
local SaveManager = loadstring(game:HttpGet(SAVE_MANAGER_URL))()

-- Window -------------------------------------------------------------------------
-- Same title, theme, branding and defaults as the original CONFIG block.
local Window = Library:CreateWindow({
	Title = "xanax",
	Theme = {
		Window = "#111111",
		Panel = "#161616",
		Border = "#0a0a0a",
		Edge = "#1a1a1a",
		Text = "#c8c8c8",
		Muted = "#707070",
		Accent = "#50c7ce",
		Hover = "#1e1e1e",
		Press = "#252525",
	},
	ToggleKeybind = Enum.KeyCode.RightShift, -- ui.menuKey equivalent
	RgbText = true,                          -- original rainbow text wave
	BackgroundAsset = "75288087294334",      -- original INITIAL_STATE ui.bgAsset
	Scale = 1.0,                             -- 0.50 - 1.50, persists via ScaleFlag
	ScaleFlag = "ui.scale",
	Opacity = 100,
})

-- Aimbot tab ------------------------------------------------------------------------
local Aimbot = Window:CreateTab("Aimbot")

Aimbot:AddToggle({ Text = "Enabled", Flag = "aim.enabled", Default = false })
Aimbot:AddToggle({ Text = "Team Check", Flag = "aim.teamCheck", Default = true })
Aimbot:AddToggle({ Text = "Visible Check", Flag = "aim.visibleCheck", Default = true })
Aimbot:AddToggle({ Text = "Ignore Knocked", Flag = "aim.ignoreKnocked", Default = true })
Aimbot:AddDropdown({
	Text = "Target Part:",
	Flag = "aim.target",
	Options = { "Head", "Torso", "HumanoidRootPart" },
	Default = "Head",
})
Aimbot:AddDropdown({
	Text = "Target Priority:",
	Flag = "aim.priority",
	Options = { "Closest to Cursor", "Closest Player", "Lowest Health" },
	Default = "Closest to Cursor",
})
Aimbot:AddSlider({ Text = "FOV:", Flag = "aim.fov", Min = 0, Max = 360, Step = 1, Default = 120 })
Aimbot:AddToggle({
	Text = "Draw FOV",
	Flag = "aim.drawFov",
	Default = true,
	Colors = { { Flag = "aim.drawFov.color.1", Default = "#50c7ce" } },
})
Aimbot:AddToggle({ Text = "Filled FOV", Flag = "aim.filledFov", Default = false })
Aimbot:AddToggle({ Text = "Prediction", Flag = "aim.prediction", Default = false })

Aimbot:NextColumn()

Aimbot:AddSlider({ Text = "Max Distance:", Flag = "aim.maxDistance", Min = 0, Max = 2000, Step = 10, Default = 1000 })
Aimbot:AddSlider({ Text = "Smoothing:", Flag = "aim.smoothing", Min = 0, Max = 20, Step = 1, Default = 8 })
Aimbot:AddDropdown({
	Text = "Activation:",
	Flag = "aim.activation",
	Options = { "Hold", "Toggle" },
	Default = "Hold",
})
Aimbot:AddKeybind({ Text = "Aim Key:", Flag = "aim.key", Default = "Mouse 2" })
Aimbot:AddToggle({ Text = "Sticky Aim", Flag = "aim.sticky", Default = false })
Aimbot:AddToggle({ Text = "Wall Check", Flag = "aim.wallCheck", Default = true })

-- Player ESP tab ----------------------------------------------------------------------
local PlayerESP = Window:CreateTab("Player ESP")

PlayerESP:AddToggle({
	Text = "Name",
	Flag = "player.name",
	Default = true,
	Colors = {
		{ Flag = "player.name.color.1", Default = "#ffffff" },
		{ Flag = "player.name.color.2", Default = "#50c7ce" },
	},
})
PlayerESP:AddToggle({
	Text = "Distance",
	Flag = "player.distance",
	Default = true,
	Colors = {
		{ Flag = "player.distance.color.1", Default = "#ffffff" },
		{ Flag = "player.distance.color.2", Default = "#50c7ce" },
	},
})
PlayerESP:AddToggle({
	Text = "Box",
	Flag = "player.box",
	Default = true,
	Colors = {
		{ Flag = "player.box.color.1", Default = "#ffffff" },
		{ Flag = "player.box.color.2", Default = "#50c7ce" },
	},
})
PlayerESP:AddDropdown({
	Text = "Box Type:",
	Flag = "player.boxType",
	Options = { "Full", "Corners", "3D" },
	Default = "Full",
})
PlayerESP:AddToggle({
	Text = "Skeleton",
	Flag = "player.skeleton",
	Default = true,
	Colors = {
		{ Flag = "player.skeleton.color.1", Default = "#ffffff" },
		{ Flag = "player.skeleton.color.2", Default = "#50c7ce" },
	},
})
PlayerESP:AddToggle({ Text = "Health", Flag = "player.health", Default = true })
PlayerESP:AddToggle({ Text = "Shield", Flag = "player.shield", Default = true })
PlayerESP:AddToggle({
	Text = "Team ID",
	Flag = "player.teamId",
	Default = true,
	Colors = { { Flag = "player.teamId.color.1", Default = "#fbf45b" } },
})
PlayerESP:AddToggle({
	Text = "OOF Arrow",
	Flag = "player.oofArrow",
	Default = true,
	Colors = {
		{ Flag = "player.oofArrow.color.1", Default = "#ffffff" },
		{ Flag = "player.oofArrow.color.2", Default = "#50c7ce" },
	},
})
PlayerESP:AddSlider({ Text = "FOV:", Flag = "player.fov", Min = 0, Max = 180, Step = 1, Default = 80, Narrow = true })
PlayerESP:AddToggle({
	Text = "Look Direction",
	Flag = "player.lookDirection",
	Default = true,
	Colors = { { Flag = "player.lookDirection.color.1", Default = "#50c7ce" } },
})
PlayerESP:AddToggle({
	Text = "Held Item",
	Flag = "player.heldItem",
	Default = true,
	Colors = {
		{ Flag = "player.heldItem.color.1", Default = "#ffffff" },
		{ Flag = "player.heldItem.color.2", Default = "#50c7ce" },
	},
})

PlayerESP:NextColumn()

PlayerESP:AddSlider({ Text = "Max Distance:", Flag = "player.maxDistance", Min = 0, Max = 1000, Step = 10, Default = 1000 })
PlayerESP:AddToggle({ Text = "Ignore Friendly", Flag = "player.ignoreFriendly", Default = true })
PlayerESP:AddToggle({ Text = "Show Knocked", Flag = "player.showKnocked", Default = true })
PlayerESP:AddToggle({
	Text = "Radar",
	Flag = "player.radar",
	Default = true,
	Colors = { { Flag = "player.radar.color.1", Default = "#50c7ce" } },
})
PlayerESP:AddSlider({ Text = "Distance:", Flag = "player.radarDistance", Min = 0, Max = 1000, Step = 10, Default = 200 })
PlayerESP:AddSlider({ Text = "Size:", Flag = "player.radarSize", Min = 1, Max = 20, Step = 1, Default = 12 })
PlayerESP:AddToggle({ Text = "Players", Flag = "player.radarPlayers", Default = true })
PlayerESP:AddToggle({ Text = "Arcs", Flag = "player.radarArcs", Default = true })

-- Entity ESP tab ------------------------------------------------------------------------
local EntityESP = Window:CreateTab("Entity ESP")

EntityESP:AddToggle({ Text = "Enabled", Flag = "entity.enabled", Default = true })
EntityESP:AddToggle({
	Text = "Name",
	Flag = "entity.name",
	Default = true,
	Colors = {
		{ Flag = "entity.name.color.1", Default = "#ffffff" },
		{ Flag = "entity.name.color.2", Default = "#50c7ce" },
	},
})
EntityESP:AddToggle({
	Text = "Distance",
	Flag = "entity.distance",
	Default = true,
	Colors = {
		{ Flag = "entity.distance.color.1", Default = "#ffffff" },
		{ Flag = "entity.distance.color.2", Default = "#50c7ce" },
	},
})
EntityESP:AddToggle({
	Text = "Box",
	Flag = "entity.box",
	Default = false,
	Colors = {
		{ Flag = "entity.box.color.1", Default = "#ffffff" },
		{ Flag = "entity.box.color.2", Default = "#50c7ce" },
	},
})
EntityESP:AddDropdown({
	Text = "Box Type:",
	Flag = "entity.boxType",
	Options = { "Full", "Corners", "3D" },
	Default = "Full",
})
EntityESP:AddToggle({ Text = "Health", Flag = "entity.health", Default = true })
EntityESP:AddToggle({
	Text = "Skeleton",
	Flag = "entity.skeleton",
	Default = false,
	Colors = { { Flag = "entity.skeleton.color.1", Default = "#50c7ce" } },
})
EntityESP:AddToggle({
	Text = "Team ID",
	Flag = "entity.teamId",
	Default = false,
	Colors = { { Flag = "entity.teamId.color.1", Default = "#fbf45b" } },
})

EntityESP:NextColumn()

EntityESP:AddSlider({ Text = "Max Distance:", Flag = "entity.maxDistance", Min = 0, Max = 2000, Step = 10, Default = 1000 })
EntityESP:AddToggle({
	Text = "Items",
	Flag = "entity.items",
	Default = true,
	Colors = { { Flag = "entity.items.color.1", Default = "#50c7ce" } },
})
EntityESP:AddToggle({
	Text = "Weapons",
	Flag = "entity.weapons",
	Default = true,
	Colors = { { Flag = "entity.weapons.color.1", Default = "#50c7ce" } },
})
EntityESP:AddToggle({
	Text = "Vehicles",
	Flag = "entity.vehicles",
	Default = false,
	Colors = { { Flag = "entity.vehicles.color.1", Default = "#fbf45b" } },
})
EntityESP:AddDropdown({
	Text = "Display:",
	Flag = "entity.display",
	Options = { "All entities", "Hostile only", "Friendly only" },
	Default = "All entities",
})
EntityESP:AddToggle({
	Text = "Tracers",
	Flag = "entity.tracers",
	Default = false,
	Colors = { { Flag = "entity.tracers.color.1", Default = "#50c7ce" } },
})
EntityESP:AddToggle({ Text = "Offscreen Arrows", Flag = "entity.arrows", Default = false })

-- Miscellaneous tab ------------------------------------------------------------------------
local Misc = Window:CreateTab("Miscellaneous")

Misc:AddToggle({
	Text = "Crosshair",
	Flag = "misc.crosshair",
	Default = false,
	Colors = { { Flag = "misc.crosshair.color.1", Default = "#50c7ce" } },
})
Misc:AddDropdown({
	Text = "Crosshair Type:",
	Flag = "misc.crosshairType",
	Options = { "Cross", "Dot", "Circle" },
	Default = "Cross",
})
Misc:AddSlider({ Text = "Crosshair Size:", Flag = "misc.crosshairSize", Min = 1, Max = 15, Step = 1, Default = 5 })
Misc:AddToggle({
	Text = "Hit Marker",
	Flag = "misc.hitMarker",
	Default = true,
	Colors = { { Flag = "misc.hitMarker.color.1", Default = "#ffffff" } },
})
Misc:AddToggle({
	Text = "Custom Cursor",
	Flag = "misc.customCursor",
	Default = false,
	Colors = { { Flag = "misc.customCursor.color.1", Default = "#50c7ce" } },
})
Misc:AddToggle({ Text = "Movement Overlay", Flag = "misc.movement", Default = false })

Misc:NextColumn()

Misc:AddToggle({ Text = "Watermark", Flag = "misc.watermark", Default = true })
Misc:AddToggle({ Text = "Clock", Flag = "misc.clock", Default = false })
Misc:AddToggle({ Text = "Reduce Camera Shake", Flag = "misc.cameraShake", Default = true })
Misc:AddSlider({
	Text = "Menu Opacity:",
	Flag = "ui.opacity",
	Min = 60,
	Max = 100,
	Step = 1,
	Default = 100,
	Callback = function(value)
		Window:SetOpacity(value)
	end,
})
Misc:AddToggle({
	Text = "Notifications",
	Flag = "misc.notifications",
	Default = true,
	Callback = function(value)
		Library:SetNotificationsEnabled(value)
	end,
})
Misc:AddDropdown({
	Text = "Distance Units:",
	Flag = "misc.units",
	Options = { "Studs", "Meters", "Feet" },
	Default = "Studs",
})

-- Settings tab ---------------------------------------------------------------------------------
local Settings = Window:CreateTab("Settings")

Settings:AddSection({ Text = "Interface" })
Settings:AddToggle({
	Text = "Animations",
	Flag = "ui.animations",
	Default = true,
	Callback = function(value)
		Library:SetAnimationsEnabled(value)
	end,
})
Settings:AddKeybind({
	Text = "Menu Key:",
	Flag = "ui.menuKey",
	Default = "Right Shift",
	Callback = function(value)
		Window:SetToggleKey(value)
	end,
})

Settings:AddSection({ Text = "Background" })
local backgroundBox = Settings:AddTextbox({
	Text = "Asset ID:",
	Flag = "ui.bgAsset",
	Default = "75288087294334",
	Placeholder = "asset id",
})
Settings:AddButton({
	Text = "Apply Background",
	Callback = function()
		Window:SetBackground(backgroundBox:Get())
	end,
})
Settings:AddButton({
	Text = "Remove Background",
	Callback = function()
		backgroundBox:Set("")
		Window:ClearBackground()
	end,
})

Settings:AddSection({ Text = "Danger Zone" })
Settings:AddButton({
	Text = "Unload UI",
	Callback = function()
		Window:Destroy()
	end,
})

Settings:NextColumn()

-- UI Scale control (0.50 - 1.50): persisted through the "ui.scale" flag and
-- two-way bound to the window scale (Ctrl+Scroll and the corner handle stay in sync).
local scaleSlider = Settings:AddSlider({
	Text = "UI Scale:",
	Flag = "ui.scale",
	Min = 50,
	Max = 150,
	Step = 5,
	Default = 100,
	Callback = function(value)
		Window:SetScale(value / 100)
	end,
})
Window:BindScaleElement(scaleSlider, true)

-- SaveManager wiring ---------------------------------------------------------------------------
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("xanax")
SaveManager:BuildConfigSection(Settings) -- appends the config controls to Settings column 2

-- Optional: observe every flag change (parity with the original OnChanged option).
-- Window.Changed:Connect(function(flag, value)
-- 	print("[xanax] " .. flag .. " = " .. tostring(value))
-- end)

-- Apply the auto-load config AFTER every element exists.
SaveManager:LoadAutoloadConfig()

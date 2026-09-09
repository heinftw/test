# xanax.ui — Documentation (Library v2.0.1)

Reusable executor UI library for Roblox. Ground-up rewrite of the original
one-off `xanax | native Roblox UI | version 1` script. This document matches the
code in `Library`, `Save Manager` and `example.lua` exactly.

- **Environment**: executors only (Synapse Z, Wave, Script-Ware, Delta, …).
  The library parents itself to `gethui()` → `CoreGui` → `PlayerGui` (first that
  works). No Studio APIs, no external requires, `task.*` scheduling only.
- **Loading**: both files end with `return Library` / `return SaveManager`, so
  they work with `loadstring(game:HttpGet(url))()` or `loadstring(readfile(path))()`.
- **Raw URLs** (branch `main`):
  - `https://raw.githubusercontent.com/heinftw/test/main/Library`
  - `https://raw.githubusercontent.com/heinftw/test/main/Save%20Manager`

---

## 1. Library (top-level API)

| Member | Description |
| --- | --- |
| `Library.Version` | `"2.0.1"` |
| `Library.Flags` | Table `flag -> current value` across all windows. |
| `Library.Windows` | Created windows in creation order. |
| `Library.Theme` | 9 theme keys, each a `Color3`: `Window #111111`, `Panel #161616`, `Border #0a0a0a`, `Edge #1a1a1a`, `Text #c8c8c8`, `Muted #707070`, `Accent #50c7ce`, `Hover #1e1e1e`, `Press #252525`. |
| `Library.AnimationsEnabled` | Master motion switch. Also honors `GuiService.ReducedMotionEnabled`. |
| `Library.NotificationsEnabled` | Master toast switch. |
| `Library.Signal` | Signal class used internally; create your own with `Library.Signal.new()`. Connections support both `conn:Disconnect()` and `conn.Disconnect(conn)`. |

### Methods

| Signature | Description |
| --- | --- |
| `Library:CreateWindow(options) -> Window` | Builds and parents a window. See §2. |
| `Library:Tween(object, properties, duration?, style?)` | The only tween entry point. Cancels any active tween on the same `object+property` first (spam-safe), then plays. `duration` defaults to `Tokens.FAST`; with animations off (or `duration <= 0`) values are applied instantly. |
| `Library:CancelTweens(object)` | Cancels every active tween on `object` (used when rows/elements are destroyed). |
| `Library:SetTheme(key, value) -> ok[, err]` | Sets one theme key. Accepts `Color3` or `#rrggbb` / `#rgb` strings. Repaints every open window. Unknown key or color → `false, err`. |
| `Library:GetTheme() -> table` | Copy of the current 9-key theme. |
| `Library:SetAnimationsEnabled(enabled)` | Enables/disables motion globally and repaints. |
| `Library:SetNotificationsEnabled(enabled)` | Enables/disables toasts. `Library:Notify` returns `nil` while disabled. |
| `Library:Notify(options) -> toast` | Toast with `options.Title` (default `"Notification"`), `options.Text`, `options.Type` = `"Info" \| "Success" \| "Error"`, `options.Duration` seconds (clamped 1–30, default 4). Auto-dismisses. |
| `Library:GetWindow() -> Window` | Most recently created window. |
| `Library:SerializeValue(value) / Library:DeserializeValue(value)` | JSON-safe primitives: numbers, booleans, strings, `Color3` (hex string form), tables. Used by profiles and SaveManager. |
| `Library:Destroy()` | Destroys every window and the notification host. |

### Motion tokens

Single source of truth for every animation:

```lua
Tokens = { INSTANT = 0.10, FAST = 0.18, BASE = 0.28, SLOW = 0.40 }
```

Easing: `Quad Out` (fades/colors/transparency), `Quint Out` (position/size/layout),
`Back Out` (scale pops and the staged window reveal). Nothing else is used.

---

## 2. `Library:CreateWindow(options)`

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | string | `"Window"` | Header title (wave-animated when `RgbText`). |
| `Theme` | table | — | `{ Window = "#161616", ... }` applied via `SetTheme` before build. |
| `ToggleKeybind` | string/EnumItem | `"Right Shift"` behavior without option | Menu toggle key. **Whitelist: `Right Shift`, `Insert`, `Home`, `F4`** (string `"Right Shift"` or `Enum.KeyCode.RightShift`). |
| `RgbText` | boolean | `false` | Rainbow text wave on the title (sin wave, gray 80–255). |
| `BackgroundAsset` | string | `""` | Roblox asset id; rendered via `rbxthumb://` 420×420. |
| `Scale` | number | `1` | Initial UI scale. |
| `ScaleFlag` | string | `"ui.scale"` | Flag written by `SetScale` (clamped 0.50–1.50). |
| `Opacity` | number | `100` | Initial shroud opacity (clamped 20–100). |
| `OnChanged` | function | — | `OnChanged(flag, value)` fired (pcall'd) for every element change. |

Returns the `Window`. Creation stages a reveal: scale settles from 0.94 with a
`Back` ease, then the first page staggers in on `SelectTab`. **No tab is created
automatically** — the consumer calls `CreateTab`.

### Window methods

| Signature | Description |
| --- | --- |
| `Window:CreateTab(title, icon) -> Tab` | Adds a sidebar tab. Selects it if it is the first. |
| `Window:SelectTab(target)` | Accepts a `Tab`, a tab object or a title string. Closes any popup, reveals the page with the stagger animation. |
| `Window:SetVisible(visible)` | Shows/hides. While hidden a reopen pill (0.16×0.04 scale, clamped 90×26–180×36 px) follows the last position; clicking it restores. |
| `Window:SetMinimized(minimized) -> ok` | Collapses to the header strip and back. |
| `Window:SetOpacity(percent) -> ok` | Shroud transparency; clamped 20–100. |
| `Window:SetBackground(assetId) / Window:ClearBackground()` | Full-window wallpaper (Z above the opacity shroud, below chrome/pages, 420×420 thumb) with a matching strip on the reopen pill. |
| `Window:SetScale(value) -> ok[, err]` | Clamps 0.50–1.50, drives `UIScale`, writes `ScaleFlag`, reflows rows. |
| `Window:GetScale() -> number` | Current scale. |
| `Window:BindScaleElement(element, isPercent?)` | Keeps a slider element (e.g. a `ui.scale` slider, `isPercent` default true) in sync with `SetScale` and vice-versa. |
| `Window:SetToggleKey(key) -> ok[, err]` | Same whitelist as `ToggleKeybind`. Accepts `"F4"` or `Enum.KeyCode.F4`; anything else returns `false, "Menu key must be Right Shift, Insert, Home or F4"`. |
| `Window:GetState() -> table` | `{ [flag] = raw element value }` for every live element. |
| `Window:GetValue(flag) -> value` | `Library.Flags[flag]`. |
| `Window:SetValue(flag, value) -> ok[, err]` | Sets through the element (validation + callback). Unknown flag → `false, err`. |
| `Window:Reset() -> ok` | Restores every non-auto element with a non-nil `Default`. |
| `Window:Serialize() -> table` | `{ [flag] = Library:SerializeValue(value) }` (wave label excluded). |
| `Window:Deserialize(values, fire?)` | Applies a serialized table; missing/invalid flags are skipped. |
| `Window:ExportProfile() -> json[, err]` | JSON envelope `{ version = 1, values = { ... } }`, hard-capped at **64 KB** (`nil, "Serialized profile exceeds the 64 KB limit"`). |
| `Window:ImportProfile(json) -> ok[, err]` | Accepts ≤ 64 KB JSON with a `values` table (older envelopes without `version` also load). Corrupt/oversized input leaves state untouched. |
| `Window.Changed` | Signal fired as `(flag, value)` for every non-silent `Set`. |
| `Window:Destroy()` | Full teardown: disconnects input/connections, cancels tweens, removes rows, unregisters the window. Post-destroy calls return gracefully (`false, "Window destroyed"`). |

### Built-in behaviors

- **Drag**: header drag with edge clamping; never starts on buttons/textboxes/sliders.
- **Single modal**: dropdown list, color picker popup and the profile dialog share
  one popup layer — opening one closes the other; `Esc` / gamepad `ButtonB` /
  outside click close it; switching tabs or minimizing also closes it.
- **Menu key**: default `Right Shift`; hidden while a textbox has focus and while
  a keybind is listening. Whitelist enforced.
- **Compact viewport**: below 600 px width the layout compresses automatically.
- **Ctrl + scroll**: window scale ±0.05 (clamped 0.50–1.50).
- **Scale tiers** (effective page width, after UIScale):
  - **Tier A** ≥ 560 px — sidebar shows icons + labels.
  - **Tier B** ≥ 380 px — icon-only sidebar with 0.22 s hover tooltips, vertical
    single-column pages.
  - **Tier C** < 380 px — icon grid / scroll strip, compressed padding,
    `TextTruncate` everywhere, minimum row heights enforced. Rows never clip:
    every row height is measured and floored (`Paragraph` measures wrapped text).

---

## 3. Tabs and elements

`Tab:Add*(options) -> element`. Common option keys (all elements):
`Text` (or `Title` alias), `Flag`, `Callback`, `Default`.

| Method | Extra options | Value type |
| --- | --- | --- |
| `Tab:AddToggle(options)` | `Colors = { "#ffffff", "#50c7ce", ... }` (up to 3 swatches) | boolean |
| `Tab:AddSlider(options)` | `Min`, `Max`, `Step`, `Suffix`, `Narrow` (half-width layout) | number |
| `Tab:AddDropdown(options)` | `Options` (list; `Values` also accepted), `Multi` | string / list |
| `Tab:AddButton(options)` | — | fires only |
| `Tab:AddTextbox(options)` | `Placeholder` | string |
| `Tab:AddKeybind(options)` | `Default` = `"Right Shift"` style name or EnumItem | prettified name string |
| `Tab:AddColorPicker(options)` | `Compact` (swatch layout) | `Color3` |
| `Tab:AddLabel(options)` | — | string; extra methods `:SetText(text, color?)`, `:SetColor(color)` |
| `Tab:AddParagraph(options)` | `Description` | string |
| `Tab:AddSection(options)` | — | heading only |

Tab helpers: `Tab:NextColumn()` (jump to the next of the 2 columns),
`Tab:Select()` (activate this tab).

### Element base API

Every element exposes:

- `element.Type` (`"Toggle"`, `"Slider"`, …), `element.Flag`, `element.Value`,
  `element.Default`, `element.Callback`, `element.Destroyed`.
- `element:Get()` → current value.
- `element:Set(value, silent?) -> ok[, err]` — normalizes + validates
  (invalid input never applies), updates `Library.Flags`, applies visuals,
  and unless `silent` fires the callback + `Window.Changed`.
- `element:Fire(value)` — invokes the callback (pcall'd, warned on error).
- `element:Destroy()` — disconnects, cancels tweens, removes the row.
- `element:Bind(object)` / `element:Connect(signal, handler)` — internal helpers
  that auto-clean on destroy.
- Elements without a `Flag` get an automatic flag `_auto.<Kind>.<n>` and are
  skipped by SaveManager and `Reset()`.

### Element-specific behaviors (parity with the original)

- **Toggle**: click toggles; each `Colors` entry renders a swatch that opens a
  compact color picker and stores under `<flag>.color.<n>`.
- **Slider**: `−`/`+` step buttons, click-to-jump, right-click numeric overlay,
  keyboard arrows while hovered, live value bubble, drag continues outside the
  window (global `InputEnded` release), drag fires `Changed` per movement.
- **Dropdown**: modal list (item height = owner×1.5 clamped 22–42, max 8 visible);
  `Multi` uses a list value; `element:SetOptions(list)` re-normalizes and clamps
  an out-of-list current value to `Options[1]`; `element:Set(nil)` clears.
- **Textbox**: Enter commits, Esc reverts; focus suppresses the menu key and
  keybind capture.
- **Keybind**: click shows `...` while listening; accepts keyboard keys and
  `Mouse 1/2/3`; `element:GetKeyCode()` resolves back to an EnumItem.
- **Color picker** (redesigned): saturation/value square + hue bar + live preview
  + `HEX` and `R/G/B` inputs + 8 preset swatches. Accepts `Color3`, `"#rrggbb"`,
  `"#rgb"`; junk input is rejected without changing state.
- **Notifications**: stacked toasts top-right with accent by `Type`, auto-dismiss,
  `toast.Closed` flag.

---

## 4. Save Manager

`Save Manager` is built **through the library's own element API** (a Section,
name textbox, config dropdown and five buttons) and ends with
`return SaveManager`.

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/heinftw/test/main/Save%20Manager"))()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("xanax")
SaveManager:BuildConfigSection(Window:CreateTab("Config")) -- or an existing tab
SaveManager:LoadAutoloadConfig() -- apply autoload.json if present (call last)
```

### Filesystem detection

Needs `writefile`, `readfile`, `isfile`, `isfolder`, `makefolder`, `listfiles`,
`delfile` on the global environment. Without them it falls back to an in-memory
`getgenv().__XANAX_UI_SAVE_MANAGER_STORE` store (session-only; the config
section shows a notice paragraph).

### Storage layout

```
<Folder>/configs/<Name>.json     -- { version = 2, flags = { [flag] = serializedValue } }
<Folder>/autoload.json           -- { config = "<name>" }
```

All file access is wrapped in `pcall`. Config names are sanitized
(whitespace-trimmed, control characters stripped). Names that differ only by
case resolve to the existing stored name (`SaveManager:ResolveName`), so
`Save("Test CFG")` overwrites `test cfg` instead of duplicating.

### API

| Signature | Description |
| --- | --- |
| `SaveManager:SetLibrary(library)` | Library instance to read/write flags through. |
| `SaveManager:SetFolder(name)` | Root folder (default `"xanax"`). |
| `SaveManager:BuildConfigSection(tab)` | Builds the 7 controls: name textbox, config dropdown, **Save**, **Load**, **Overwrite**, **Set as Auto-Load**, **Delete** + status label. |
| `SaveManager:Save(name) -> ok[, err]` | Serializes current flags; empty name → inline `"Enter a config name"` status; existing (case-insensitive) → overwrite notice. Refreshes the dropdown and selects the entry. |
| `SaveManager:Load(name) -> ok[, err]` | Applies the config through each element's `Set` (pcall'd, sorted flag order, unknown flags skipped, counted only when `Set` succeeds). |
| `SaveManager:Overwrite(name) -> ok[, err]` | Requires an existing config; otherwise inline error. |
| `SaveManager:Delete(name) -> ok[, err]` | Removes the file, clears a matching autoload, refreshes the dropdown and clears the selection. |
| `SaveManager:SetAutoload(name) -> ok[, err]` | Writes `autoload.json`. |
| `SaveManager:GetAutoload() -> string?` | Current autoload config name (nil when none). |
| `SaveManager:ClearAutoload() -> ok` | Removes `autoload.json`. |
| `SaveManager:LoadAutoloadConfig() -> ok[, err]` | Loads the autoload config once at startup; clears a stale marker when the file is gone. |
| `SaveManager:RefreshConfigList()` | Re-reads `configs/` and updates the dropdown. |
| `SaveManager:SerializeFlags() / SaveManager:GetConfigs() / SaveManager:ResolveName(name)` | Supporting helpers (also used by tests). |

---

## 5. Minimal usage

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/heinftw/test/main/Library"))()

local Window = Library:CreateWindow({
    Title = "xanax",
    RgbText = true,
    ToggleKeybind = "Right Shift",
    OnChanged = function(flag, value)
        print(flag, value)
    end,
})

local Tab = Window:CreateTab("Aim", "rbxassetid://10723407389")
Tab:AddToggle({ Text = "Enabled", Flag = "aim.enabled", Default = false,
    Callback = function(v) end })
Tab:AddSlider({ Text = "FOV", Flag = "aim.fov", Min = 20, Max = 360, Step = 1,
    Default = 90, Suffix = "px" })
Tab:AddDropdown({ Text = "Priority", Flag = "aim.priority",
    Options = { "Head", "Torso", "Closest" }, Default = "Head" })
Tab:AddColorPicker({ Text = "Accent", Flag = "aim.color", Default = "#50c7ce" })

Window:SelectTab("Aim")

-- Persistence
local json = Window:ExportProfile()          -- { version = 1, values = {...} } ≤ 64 KB
Window:ImportProfile(json)
Window:SetValue("aim.enabled", true)
print(Window:GetValue("aim.enabled"))
```

`example.lua` in this repository rebuilds the complete original panel (5 tabs,
all 98 flags including attached color swatches, scale/opacity/animation/menu-key
controls, background asset) purely through this API and wires SaveManager —
use it as the reference integration.

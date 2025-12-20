# Reactive UI Navigation System

The Reactive UI Navigation System provides a designer-friendly way to add keyboard, controller, and mouse navigation to reactive UI systems without requiring custom scripting.

## Quick Start

### 1. Basic Setup

1. Add a `ReactiveUINavigator` node to your scene
2. Create a `NavigationConfig` resource:
   - Set `root_control` to the main UI container
   - Set `default_focus` to the first control that should receive focus
3. Choose your navigation mode:
   - **INPUT_MAP** (recommended): Uses Godot's InputMap for standard controls
   - **STATE_DRIVEN**: For custom input systems

### 2. INPUT_MAP Mode (Most Common)

```gdscript
# Create NavigationConfig
var config = NavigationConfig.new()
config.root_control = NodePath("../UIContainer")
config.default_focus = NodePath("../UIContainer/StartButton")

# Create NavigationInputProfile (usually default is fine)
var profile = NavigationInputProfile.new()
profile.action_up = "ui_up"  # Default Godot actions
profile.action_down = "ui_down"
# ... etc

# Add to navigator
navigator.mode = ReactiveUINavigator.NavigationMode.INPUT_MAP
navigator.nav_config = config
navigator.input_profile = profile
```

### 3. STATE_DRIVEN Mode (Custom Input)

For games with custom input systems:

```gdscript
# Create NavigationStateBundle
var states = NavigationStateBundle.new()
states.move_x = State.new(0)  # -1, 0, +1
states.move_y = State.new(0)  # -1, 0, +1
states.submit = State.new(false)
states.cancel = State.new(false)

# Set up navigator
navigator.mode = ReactiveUINavigator.NavigationMode.STATE_DRIVEN
navigator.nav_states = states

# In your input system, update the states:
states.move_y.value = -1  # Move up
await get_tree().create_timer(0.1).timeout
states.submit.value = true  # Press submit
```

## Configuration Options

### NavigationConfig

| Property | Description |
|----------|-------------|
| `root_control` | Path to the root Control node for navigation scope |
| `default_focus` | Path to the control that gets initial focus |
| `focus_on_ready` | Whether to set focus when scene loads |
| `ordered_controls` | Explicit list of controls for linear navigation |
| `use_ordered_vertical` | Whether ordered list is vertical-first |
| `wrap_vertical` | Whether vertical navigation wraps around |
| `wrap_horizontal` | Whether horizontal navigation wraps around |
| `respect_custom_neighbors` | When true, uses Control's focus_neighbor_* properties for navigation. Custom neighbors take priority over automatic navigation. |
| `restrict_to_focusable_children` | Only navigate to FOCUS_ALL controls |
| `auto_disable_child_focus` | When true, disables focus on all children of root_control during initialization, keeping navigation flat. |

### NavigationInputProfile

| Property | Description |
|----------|-------------|
| `action_up/down/left/right` | InputMap action names for directions |
| `action_accept/cancel` | InputMap action names for submit/cancel |
| `repeat_delay` | Initial delay before key repeat (seconds) |
| `repeat_interval` | Time between repeated inputs (seconds) |

### ReactiveUINavigator

| Property | Description |
|----------|-------------|
| `mode` | Navigation mode (NONE, INPUT_MAP, STATE_DRIVEN, BOTH) |
| `nav_config` | NavigationConfig resource |
| `input_profile` | NavigationInputProfile (INPUT_MAP mode) |
| `nav_states` | NavigationStateBundle (STATE_DRIVEN mode) |
| `on_submit` | Optional Callable for custom submit behavior |
| `on_cancel` | Optional Callable for custom cancel behavior |

## Navigation Behaviors

### Focus Movement

The navigator supports two focus movement strategies:

1. **Ordered Controls**: When `NavigationConfig.ordered_controls` is set, navigation follows the explicit list with optional wrapping.

2. **Positional Heuristics**: When no ordered list exists, the navigator finds the closest control in the intended direction using:
   - Angular cone filtering (controls within ~90 degrees of movement direction)
   - Distance-based selection among valid candidates

### Submit/Cancel Actions

- **Submit**: Activates the focused control
  - `BaseButton` types: Triggers their pressed signal
  - Other controls: Forwards `ui_accept` input event

- **Cancel**: Optional back/cancel action
  - Can return focus to `default_focus`
  - Emits `cancel_fired` signal for scene-specific handling

### Scope Management

- Navigation is limited to controls under `nav_config.root_control`
- `auto_disable_child_focus` can flatten navigation within containers
- `restrict_to_focusable_children` filters out non-focusable controls

### Custom Focus Neighbors

When `respect_custom_neighbors` is enabled, the navigator will check each control's `focus_neighbor_*` properties before using automatic navigation. This allows you to:

- Override automatic navigation for specific controls
- Create custom navigation paths (e.g., skip intermediate controls)
- Define navigation that doesn't follow visual layout
- Override scope restrictions (custom neighbors can point outside `root_control`)

**Priority Order:**
1. Custom neighbors (if `respect_custom_neighbors` is enabled)
2. Ordered controls (if `ordered_controls` array is set)
3. Position-based heuristics (default)

**Example:**
```gdscript
# In Godot Inspector, set focus_neighbor_bottom on Button1 to point to Button3
# This skips Button2 when navigating down from Button1
button1.focus_neighbor_bottom = NodePath("../Button3")

# Configure navigator to respect custom neighbors
config.respect_custom_neighbors = true
```

**Note:** Custom neighbors are validated in the editor and must point to valid Control nodes. Invalid paths will show warnings.

### Auto-Disable Child Focus

When `auto_disable_child_focus` is enabled, the navigator automatically sets `focus_mode = FOCUS_NONE` on all children of `root_control` during initialization. This creates a "flat" navigation structure where only top-level controls are focusable.

**Use Cases:**
- Tab containers where you want to navigate between tabs, not their contents
- Panel containers where only the panel itself should be focusable
- Complex nested UIs where you want to restrict navigation scope

**Example:**
```gdscript
# Configure for tab container navigation
config.root_control = NodePath("../TabContainer")
config.auto_disable_child_focus = true

# Now only the tab buttons are focusable, not the tab content panels
```

**Note:** This feature requires `root_control` to be set. A warning will appear in the editor if `root_control` is not set when this option is enabled.

## Signals and Callbacks

### Signals

Connect these in the Godot editor via the Node → Signals dock:

```gdscript
# Focus changes
navigator.focus_changed.connect(_on_focus_changed)

# Navigation intents (may not result in focus change)
navigator.navigation_moved.connect(_on_navigation_moved)

# Action triggers
navigator.submit_fired.connect(_on_submit)
navigator.cancel_fired.connect(_on_cancel)

func _on_focus_changed(old_control: Control, new_control: Control):
    # Update UI highlights, play sounds, etc.
    pass
```

### Callbacks

For simple per-screen behaviors, assign Callables in the Inspector:

```gdscript
# These are called with the focused control as argument
func _custom_submit_handler(focused_control: Control):
    match focused_control.name:
        "StartButton": start_game()
        "SettingsButton": show_settings()
        _: push_warning("Unhandled submit on: " + focused_control.name)

func _custom_cancel_handler(focused_control: Control):
    if focused_control.name == "MainMenu":
        quit_game()
    else:
        back_to_main_menu()
```

## Editor Features

### Validation

The navigator validates configuration in the editor and shows warnings for:
- Invalid `root_control` or `default_focus` paths
- Missing ordered control paths
- Type mismatches

### Debug Visualization

Enable `debug_show_focus_outlines` to see red outlines around focused controls in the editor.

### Auto-Population

Call `navigator.auto_populate_ordered_controls()` to automatically populate the ordered controls list from focusable children under the root control.

## Examples

### Vertical Menu

```gdscript
# NavigationConfig
config.ordered_controls = [
    "../VBox/MainMenu/StartButton",
    "../VBox/MainMenu/OptionsButton",
    "../VBox/MainMenu/QuitButton"
]
config.wrap_vertical = true

# NavigationInputProfile (defaults are usually fine)
profile.repeat_delay = 0.3
```

### Grid Layout

```gdscript
# For a 3x2 button grid
config.ordered_controls = [
    "../Grid/Button1", "../Grid/Button2", "../Grid/Button3",
    "../Grid/Button4", "../Grid/Button5", "../Grid/Button6"
]
config.use_ordered_vertical = true  # Navigate vertically first
config.wrap_vertical = true
config.wrap_horizontal = false
```

### Tabbed Interface

```gdscript
# Scope navigation to current tab content
config.root_control = "../TabContainer/Panel"  # Current tab panel
config.auto_disable_child_focus = true  # Keep navigation flat
```

## Integration with Reactive UI

The navigation system integrates seamlessly with reactive controls:

- Focus changes automatically trigger reactive state updates
- Submit actions work with all reactive button types
- State-driven mode allows navigation to be driven by reactive state changes

## Troubleshooting

### Common Issues

1. **No navigation happening**
   - Check that `nav_config.root_control` is set correctly
   - Verify InputMap actions exist in Project Settings
   - Ensure controls have `focus_mode = FOCUS_ALL`

2. **Focus not changing**
   - Check that target controls are within the navigation scope
   - Verify `restrict_to_focusable_children` setting
   - Use debug outlines to see current focus

3. **Wrong navigation direction**
   - Check `ordered_controls` configuration
   - Verify positional layout for heuristic navigation
   - Test with debug outlines enabled

4. **Custom neighbors not working**
   - Verify `respect_custom_neighbors` is enabled in NavigationConfig
   - Check that `focus_neighbor_*` properties are set correctly in Inspector
   - Ensure neighbor paths point to valid Control nodes
   - Check editor warnings for invalid paths

5. **Children still focusable with auto_disable_child_focus enabled**
   - Verify `root_control` is set correctly
   - Check that children are direct descendants of `root_control`
   - Ensure `auto_disable_child_focus` is enabled in NavigationConfig
   - Check editor warnings for missing `root_control`

### Debug Tips

- Enable `debug_show_focus_outlines` to visualize focus
- Use the Scene dock to verify node paths
- Add temporary signal connections to log navigation events
- Test with ordered controls first, then switch to positional

## Advanced Usage

### Custom Input Integration

For games with custom input systems:

```gdscript
# In your input manager
func _process(delta):
    # Read your custom input
    var move_dir = get_custom_stick_input()

    # Update navigation states
    nav_states.move_x.value = sign(move_dir.x)
    nav_states.move_y.value = sign(move_dir.y)

    # Handle actions
    if custom_submit_pressed():
        nav_states.submit.value = true
        await get_tree().create_timer(0.1).timeout
        nav_states.submit.value = false
```

### Multi-Container Navigation

For complex UIs with multiple navigation contexts:

```gdscript
# Create separate navigators for different UI sections
var main_menu_navigator = ReactiveUINavigator.new()
var settings_navigator = ReactiveUINavigator.new()

# Configure different scopes
main_menu_config.root_control = "../MainMenu"
settings_config.root_control = "../SettingsPanel"

# Switch navigation contexts programmatically
func show_settings():
    main_menu_navigator.mode = ReactiveUINavigator.NavigationMode.NONE
    settings_navigator.mode = ReactiveUINavigator.NavigationMode.INPUT_MAP
```

This navigation system provides a complete, designer-friendly solution for reactive UI navigation while remaining flexible for advanced use cases.

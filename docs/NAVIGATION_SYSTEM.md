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
| `respect_custom_neighbors` | Use Control's focus_neighbor_* properties |
| `restrict_to_focusable_children` | Only navigate to FOCUS_ALL controls |
| `auto_disable_child_focus` | Disable focus on container children |

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

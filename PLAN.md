# Reactive UI System Development Plan

## Architecture Overview

The system will be built on a foundation of custom Resource classes that enable reactive, editor-driven UI components. Each phase builds upon the previous, with testable milestones.

```
ReactiveValue (base)
├── ReactiveString
├── ReactiveInt
├── ReactiveFloat
├── ReactiveBool
├── ReactiveArray<T> (collections)
├── ReactiveObject (complex data structures)
└── ReactiveReference<T> (reference sharing)

ReactiveControl (base Control)
├── ReactiveBindingManager (RefCounted) - Unified binding system (one-way or two-way: UI ↔ ReactiveValue)
├── ReactiveAnimationManager (RefCounted) - Animation orchestration
├── ReactiveFocusManager (RefCounted) - Focus management
├── Target/Action system
└── Text builder integration

Reactive Components
├── ReactiveLabel (extends Label)
├── ReactiveButton (extends Button)
├── ReactiveLineEdit (extends LineEdit)
├── ReactiveTextLabel (extends Label/RichTextLabel)
├── ReactiveList (extends ItemList or custom)
├── ReactiveGrid (extends GridContainer or custom)
└── ReactiveCell (extends Control)
```

**Resource Sharing Strategy:**
- ReactiveValue resources are designed to be **shared** between multiple UI components
- A single ReactiveValue instance can be referenced by multiple components
- When a ReactiveValue changes, all components referencing it will receive the `value_changed` signal
- This enables centralized state management (e.g., one ReactiveInt for "player_health" used by health bar, label, and warning system)
- Resources are reference-counted by Godot, so sharing is memory-efficient

**Composition Architecture:**
- ReactiveControl uses RefCounted-based composition for separation of concerns
- Managers (ReactiveBindingManager, ReactiveAnimationManager, ReactiveFocusManager) are RefCounted classes, not Nodes
- ReactiveControl orchestrates managers but delegates implementation to them
- Managers are instantiated in `_ready()` and cleaned up in `_exit_tree()`
- This maintains Single Responsibility Principle while keeping lightweight, efficient code

## Implementation Notes

This section clarifies implementation details and resolves ambiguities that may arise during development.

### Update Batching Mechanism (Phase 1)
- **Implementation:** Use `call_deferred()` to batch rapid consecutive updates within the same frame
- **Pattern:** When `set_value()` is called, store the new value but don't emit signal immediately
- **Deferred Call:** Schedule `_emit_batched_signal()` via `call_deferred()` with the final value
- **Result:** Multiple rapid updates in the same frame result in only one `value_changed` signal emission with the final value
- **Edge Case:** If value changes again before deferred call executes, update the stored value but don't schedule another deferred call

### Resource Migration Timing (Phase 1)
- **Automatic Migration:** `_migrate_from_version()` is called automatically when a Resource is loaded via `ResourceLoader.load()`
- **Trigger:** Compare `version` property in loaded resource against expected version (stored in class constant or metadata)
- **Execution:** If versions differ, call `_migrate_from_version(old_version)` before resource is used
- **Pattern:** Base ReactiveValue checks version in `_init()` or `_load()` override, calls migration if needed
- **Migration Method:** Subclasses override `_migrate_from_version(old_version: int)` to handle version-specific changes

### Manager Access Pattern (Phase 2, 5, 6)
- **Delegation Pattern:** ReactiveControl exposes public methods that delegate to managers
- **Example:** `ReactiveControl.update_binding()` calls `_binding_manager.update_binding()`
- **Direct Access:** Managers are private (`var _binding_manager: ReactiveBindingManager`)
- **Public Interface:** ReactiveControl provides high-level methods; managers handle implementation
- **Exception:** Advanced users can access managers via protected methods if needed for extension

### Initial Value Sync Timing (Phase 2)
- **Order of Operations:** 
  1. Create ReactiveBindingManager in `_ready()`
  2. Call `_binding_manager.setup(self, bindings)` - this validates and connects signals
  3. After setup, immediately sync initial values: `_binding_manager.sync_initial_values()`
- **Null Handling:** If ReactiveValue is null, skip sync (binding status will show error)
- **One-Time Only:** Initial sync happens once in `_ready()`, subsequent updates are reactive

### Circular Update Prevention Logic (Phase 2)
- **Flag Pattern:** ReactiveBindingManager uses two flags:
  - `_updating_from_reactive: bool` - Set when updating Control from ReactiveValue
  - `_updating_from_control: bool` - Set when updating ReactiveValue from Control
- **Logic:**
  ```gdscript
  # When ReactiveValue changes (ONE_WAY or TWO_WAY)
  if _updating_from_control:
      return  # Skip to prevent circular update
  _updating_from_reactive = true
  # Update Control property
  _updating_from_reactive = false
  
  # When Control signal fires (TWO_WAY only)
  if _updating_from_reactive:
      return  # Skip to prevent circular update
  _updating_from_control = true
  # Update ReactiveValue
  _updating_from_control = false
  ```

### ReactiveArray.get_item_reactive_value() Behavior (Phase 1.5)
- **ReactiveObject Items:** Returns `item.get_property_reactive(property_path)` directly
- **Primitive Items:** Returns `null` - primitives cannot provide reactive access
- **Recommendation:** For reactive access to primitive array items, wrap them in ReactiveObject or use array-level signals
- **Use Case:** Primarily designed for ReactiveObject arrays; primitive arrays use `item_changed` signal

### ActionGroup SEQUENCE Mode Execution (Phase 3)
- **Synchronous Execution:** Actions execute sequentially in order, one after another
- **No Async Waiting:** Since actions return `bool` synchronously, "waiting" means executing next action only after previous completes
- **Pattern:** Loop through actions, execute each, check return value, continue or stop on failure
- **Future Extension:** If async actions are needed later, ActionGroup can be extended to support awaitable actions

### Animation Relative Values for Complex Types (Phase 5)
- **Numeric Types (int, float):** `end_value` is added to current property value
- **Vector2/Vector3:** Each component is added separately (`current + end_value`)
- **Color:** RGBA components are added separately (clamped to 0.0-1.0)
- **Other Types:** Use ABSOLUTE mode - relative mode not supported, falls back to absolute
- **Validation:** AnimationStep validates `value_mode` compatibility with property type on creation

### Dynamic Component Registration (Phase 6)
- **Automatic Registration:** ReactiveControl calls `ReactiveNavigation.register_component(self, navigation_group)` in `_ready()`
- **Runtime Addition:** If component is added dynamically, it registers itself when `_ready()` is called
- **Group Management:** ReactiveNavigation maintains `Dictionary[String, Array[Control]]` of components per group
- **Cleanup:** Component calls `ReactiveNavigation.unregister_component(self)` in `_exit_tree()`

### ControlInspector Cache Management (Phase 7)
- **Cache Structure:** `static var _cache: Dictionary[String, Dictionary]` keyed by Control class name
- **Manual Clear:** `ControlInspector.clear_cache()` static method clears entire cache
- **Auto-Clear Triggers:** 
  - Editor plugin reload (plugin's `_disable()` method)
  - Scene reload (editor scene change detection)
  - On-demand via editor menu option
- **Cache Key:** Use `control.get_class()` as key for type-based caching

### Logger Instance Access (Phase 7)
- **Godot 4.5 API:** Use `Logging.get_logger("ReactiveUI")` to obtain Logger instance
- **Singleton Pattern:** Store logger instance in static variable: `static var _logger: Logger`
- **Initialization:** `_logger = Logging.get_logger("ReactiveUI")` on first access
- **Usage:** All systems use `ReactiveLogger.get_logger()` which returns cached instance
- **Note:** Verify exact API in Godot 4.5 documentation; API may be `Logger.get_logger()` instead

### ReactiveReference.value Property Resolution (Phase 2.6)
- **Property Override:** ReactiveReference overrides `value` property getter to return referenced ReactiveValue's value
- **Pattern:** 
  ```gdscript
  var reference: ReactiveValue  # The referenced value
  
  var value: Variant:
      get:
          return reference.value if reference else null
      set(v):
          if reference:
              reference.value = v
  ```
- **Alternative:** Use `reference: ReactiveValue` property and access via `reference.value` (clearer but less convenient)

### SignalConnection Resource Structure (Phase 2)
- **Class Type:** SignalConnection is a `RefCounted` class (not Resource) since Signals aren't serializable
- **Structure:**
  ```gdscript
  class_name SignalConnection extends RefCounted
  var signal: Signal
  var callable: Callable
  var is_connected: bool = false
  ```
- **Usage:** Store in `Array[SignalConnection]` for tracking; call `signal.disconnect(callable)` in cleanup
- **Note:** Cannot be saved as Resource; only used at runtime for connection tracking

### ReactiveObject Property Type Safety (Phase 1.5)
- **Property Storage:** Dictionary stores `Variant` values (untyped at storage level)
- **Type Safety:** `get_property()` returns Variant; caller responsible for type checking
- **Reactive Properties:** Properties can be `ReactiveValue` instances for nested reactivity
- **get_property_reactive():** Returns ReactiveValue if property is ReactiveValue, null otherwise
- **Recommendation:** Use typed getters in subclasses for type safety: `get_name() -> String`, `get_quantity() -> int`

### Animation Step Delay Timing (Phase 5)
- **Delay Type:** Cumulative delay relative to previous step completion
- **Pattern:** In SEQUENCE mode, delay is added to previous step's end time
- **Example:** Step 1 (duration=1.0, delay=0.0) ends at t=1.0; Step 2 (duration=0.5, delay=0.3) starts at t=1.3, ends at t=1.8
- **PARALLEL Mode:** Delay applies relative to animation start time (all steps start at t=0, but delayed steps start later)

### Minor Clarifications
- **ReactiveCell item_index:** Set by parent ReactiveList/ReactiveGrid when creating cell instances
- **ActionGroup Nesting:** Fully arbitrary depth - no limits, but validate for infinite recursion
- **TextBuilder Segment Order:** Order is preserved exactly as in array - segments build sequentially
- **Navigation Group Switching:** Set `ReactiveNavigation.current_group` property programmatically (e.g., from button action or scene transition)

## Phase 1: Core Reactive Resource System

**Goal:** Establish the foundation with reactive value resources that emit signals on change.

**Files to Create:**
- `res://ui_system/resources/reactive/reactive_value.gd` - Base abstract class
- `res://ui_system/resources/reactive/reactive_string.gd` - String reactive value
- `res://ui_system/resources/reactive/reactive_int.gd` - Integer reactive value
- `res://ui_system/resources/reactive/reactive_float.gd` - Float reactive value
- `res://ui_system/resources/reactive/reactive_bool.gd` - Boolean reactive value
- `res://ui_system/resources/validation/validation_result.gd` - Validation result Resource
- `res://ui_system/resources/validation/validator.gd` - Base validator abstract class
- `res://ui_system/resources/validation/int_range_validator.gd` - Min/max validator for integers
- `res://ui_system/resources/validation/string_length_validator.gd` - Length validator for strings
- `res://ui_system/resources/validation/regex_validator.gd` - Regex pattern validator
- `res://ui_system/tests/test_unified_integration.tscn` - Unified integration test scene (created in Phase 1, updated each phase)

**Implementation Details:**
- `ReactiveValue` extends `Resource`
- Uses `@abstract` annotation (Godot 4.5) to mark as abstract base class
- **Resource Versioning:** All ReactiveValue resources include `version: int` property for migration support
- Custom `value_changed(new_value, old_value)` signal (includes both values for comparison)
- Custom `validation_failed(result: ValidationResult)` signal emitted when validation fails
- Tracks `_previous_value` internally for old value access (optional, can be disabled for large values via `track_old_value: bool` property)
- `default_value: Variant` exported property for initial/default value
- `reset_to_default()` method to restore default value
- `get_old_value() -> Variant` method to retrieve previous value
- Optional `Array[Validator]` for value constraints (min/max, length, regex, etc.)
- Type-safe setters that validate before setting and emit signals
- **Update Batching:** Rapid consecutive updates within same frame are batched - only final value triggers signal emission
- **Migration Support:** Resources can define `_migrate_from_version(old_version: int)` method for handling version changes
- Proper serialization support
- Editor-friendly property hints
- See Architecture Overview for resource sharing strategy

**Validation System:**
- `ValidationResult` Resource contains:
  - `is_valid: bool` - Whether validation passed
  - `error_message: String` - Error description if validation failed
  - `error_code: String` - Error code for programmatic handling
- `Validator` base abstract class with `validate(value: Variant) -> ValidationResult` method
- Validators are Resources, can be shared and reused
- Validation runs automatically in setter before value change
- Failed validation prevents value change and emits `validation_failed` signal with ValidationResult
- **Validation Purpose:** Validators enforce value constraints (min/max, length, format) - different from conditions which evaluate runtime state

**SOLID/DRY Architecture:**
- **Single Responsibility:** 
  - Each ReactiveValue class: responsible only for storing and notifying about one type of value
  - Each Validator class: responsible only for one validation concern
- **Open/Closed:** 
  - Base `ReactiveValue` class closed for modification, open for extension (new types can inherit)
  - Base `Validator` class closed for modification, open for extension (new validators can inherit)
- **Liskov Substitution:** 
  - All concrete ReactiveValue types can be used interchangeably where ReactiveValue is expected
  - All concrete Validator types can be used interchangeably where Validator is expected
- **Interface Segregation:** 
  - ReactiveValue provides minimal interface (value property, value_changed signal, set_value method, default_value)
  - Validator provides minimal interface (validate method)
- **Dependency Inversion:** 
  - Components depend on ReactiveValue abstraction, not concrete implementations
  - ReactiveValue depends on Validator abstraction, not concrete validators
- **DRY:** 
  - Common signal emission, validation, and serialization logic in base ReactiveValue class
  - Common validation patterns (type checking, error handling) in base Validator class
  - Type-specific logic in subclasses

**Test Criteria:**
- **Create unified test scene:** Set up `test_unified_integration.tscn` with basic structure (containers, labels for sections)
- Create instances in editor, verify serialization
- Connect to `value_changed` signal, modify value, verify signal emission with both new and old values
- Save/load scene with reactive values, verify persistence
- Test all four concrete types (String, Int, Float, Bool) in unified test scene
- **Test default values:** Set default_value, verify reset_to_default() works, verify initial value uses default
- **Test validation:** Add IntRangeValidator (min=0, max=100), try to set value to 150, verify it's rejected
- **Test old value tracking:** Change value multiple times, verify get_old_value() returns previous value
- **Test update batching:** Rapidly change value 10 times in same frame, verify only one value_changed signal emitted (with final value)
- **Test resource versioning:** Create ReactiveValue with version=1, update to version=2, verify migration method is called
- **Test resource sharing:** Create one ReactiveInt, reference it from 3 different components, change value, verify all 3 update
- **Add to unified test scene:** Create section demonstrating all ReactiveValue types with labels showing their values

**Deliverable:** Working reactive resources with validation, default values, and old value tracking that can be created, edited, shared, and connected in the editor. Unified test scene created and Phase 1 features demonstrated.

---

## Phase 1.5: Collection and Complex Data Support

**Goal:** Extend reactive system to support collections (arrays) and complex data structures (objects).

**Files to Create:**
- `res://ui_system/resources/reactive/reactive_array.gd` - Array reactive value
- `res://ui_system/resources/reactive/reactive_object.gd` - Complex object reactive value

**Implementation Details:**
- `ReactiveArray` extends `ReactiveValue`
- Holds `Array[Variant]` internally
- Supports both primitive arrays and arrays of ReactiveObjects
- Signals: `item_added(index: int, item: Variant)`, `item_removed(index: int)`, `item_changed(index: int, new_value: Variant, old_value: Variant)`, `array_changed()`
- Methods: `add_item(item)`, `remove_item(index)`, `get_item(index) -> Variant`, `set_item(index, value)`, `clear()`, `size() -> int`
- **Item Access:** `get_item_reactive_value(index: int, property_path: String) -> ReactiveValue` - provides reactive access to item properties
- For complex items, items should be ReactiveObjects for full reactivity

- `ReactiveObject` extends `ReactiveValue`
- Holds `Dictionary` internally with typed property access
- Properties can be ReactiveValues for nested reactivity
- Methods: `get_property(name: String) -> Variant`, `set_property(name: String, value: Variant)`, `get_property_reactive(name: String) -> ReactiveValue`
- Signals: `property_changed(property_name: String, new_value: Variant, old_value: Variant)`, `object_changed()`
- **Use Case:** Represents complex data (e.g., inventory item with name, quantity, price, icon)

**SOLID/DRY Architecture:**
- **Single Responsibility:** 
  - ReactiveArray: responsible only for array storage and notifications
  - ReactiveObject: responsible only for object storage and property notifications
- **Open/Closed:** Both extend ReactiveValue, closed for modification, open for extension
- **Liskov Substitution:** Can be used wherever ReactiveValue is expected
- **Dependency Inversion:** Components depend on ReactiveValue abstraction
- **DRY:** Reuses ReactiveValue base functionality, adds collection-specific logic

**Test Criteria:**
- Create ReactiveArray, add items, verify item_added signals
- Remove items, verify item_removed signals
- Modify items, verify item_changed signals
- Create ReactiveObject with properties, modify properties, verify property_changed signals
- Test ReactiveArray of ReactiveObjects, verify nested reactivity
- **Test item access:** Get reactive value for item property, modify, verify updates propagate
- **Update unified test scene:** Add section demonstrating ReactiveArray and ReactiveObject with sample data

**Deliverable:** Working ReactiveArray and ReactiveObject that can store collections and complex data structures reactively. Unified test scene updated with collection examples.

---

## Phase 2: Basic Reactive Component with State Exposure

**Goal:** Create a base reactive component that exposes state via reactive values, supports unified one-way and two-way binding, and demonstrates basic reactivity.

**Files to Create:**
- `res://ui_system/components/reactive_control.gd` - Base component class
- `res://ui_system/components/reactive_label.gd` - Simple label component (one-way binding)
- `res://ui_system/components/reactive_line_edit.gd` - Input field component (two-way binding example)
- `res://ui_system/managers/reactive_binding_manager.gd` - Binding system manager (RefCounted)
- `res://ui_system/resources/bindings/reactive_binding.gd` - Unified binding configuration resource
- `res://ui_system/resources/bindings/binding_status.gd` - BindingStatus enum definition
- `res://ui_system/resources/converters/value_converter.gd` - Base converter abstract class
- `res://ui_system/resources/converters/string_to_int_converter.gd` - String to int converter
- `res://ui_system/resources/converters/int_to_string_converter.gd` - Int to string converter
- `res://ui_system/resources/converters/bool_to_text_converter.gd` - Bool to text converter
- `res://ui_system/utils/signal_connection.gd` - Typed signal connection Resource
- `res://ui_system/utils/binding_validator.gd` - Binding validation utility
- `res://ui_system/utils/reactive_lifecycle_manager.gd` - Static utility for cleanup operations
- `res://ui_system/utils/reactive_validation_utils.gd` - Shared validation utilities

**Implementation Details:**
- `ReactiveControl` extends `Control`
- Exports `Array[ReactiveBinding]` for unified binding system (supports both one-way and two-way)
- Uses `ReactiveBindingManager` (RefCounted) for binding system implementation
- **ReactiveBindingManager:**
  - RefCounted class that handles all binding logic
  - Manages signal connections, validation, and cleanup
  - Instantiated in `_ready()`, cleaned up in `_exit_tree()`
  - Methods: `setup(owner: Control, bindings: Array[ReactiveBinding])`, `cleanup()`
- Each binding has `mode: enum {ONE_WAY, TWO_WAY}` to select binding direction
- Auto-connects to reactive value signals based on binding mode
- **Initial Value Sync:** In `_ready()`, immediately syncs ReactiveValue to Control property (one-time initialization)
- Updates UI when reactive values change reactively
- One-way binding: ReactiveValue `value_changed` → updates Control property
- Two-way binding connects:
  - Node signal (e.g., LineEdit `text_changed`) → updates ReactiveValue
  - ReactiveValue `value_changed` → updates Control property
- **Binding Validation:** Validates bindings on creation (path exists, property exists, signal exists for TWO_WAY)
- **Binding Status:** Tracks `status: BindingStatus` enum with values:
  - `CONNECTED` - Binding is active and working
  - `ERROR_INVALID_PATH` - Control path does not exist
  - `ERROR_INVALID_PROPERTY` - Property does not exist on Control
  - `ERROR_INVALID_SIGNAL` - Signal does not exist on Control (TWO_WAY only)
  - `ERROR_TYPE_MISMATCH` - Type mismatch between ReactiveValue and Control property
  - `DISCONNECTED` - Binding is not connected (initial state)
- Prevents circular updates with update flags
- Proper cleanup in `_exit_tree()` delegates to ReactiveBindingManager.cleanup()
- `ReactiveLabel` demonstrates: one-way binding of `text` property to `ReactiveString`
- `ReactiveLineEdit` demonstrates: two-way binding between LineEdit and `ReactiveString`
- **Accessibility Support:**
  - `accessibility_description: String` property - Description for screen readers (Godot 4.5)
  - `accessibility_label: String` property - Label for screen readers
  - Integrates with Godot 4.5's screen reader support automatically
  - All ReactiveControl subclasses inherit accessibility support

**Unified Binding Resource Structure:**
- `ReactiveBinding` resource contains:
  - `reactive_value: ReactiveValue` - The reactive value to bind to
  - `mode: enum {ONE_WAY, TWO_WAY}` - Binding direction
  - `control_path: NodePath` - Path to the Control node (optional for ONE_WAY, defaults to "self"; required for TWO_WAY)
  - `control_property: String` - Property name on Control (e.g., "text", "value")
  - `control_signal: String` - Signal name to listen to (required for TWO_WAY, ignored for ONE_WAY)
  - `value_converter: ValueConverter` - Optional converter Resource (replaces String function name)
  - `status: BindingStatus` - Read-only status of binding (updated on validation)

**Value Converter System:**
- `ValueConverter` base abstract class with `convert(value: Variant) -> Variant` method
- Converters are Resources, can be shared and reused
- Type-safe conversion with error handling
- Editor plugin auto-suggests compatible converters based on ReactiveValue and Control property types
- **Unified System:** `TextFormatter` extends `ValueConverter` (formatters are specialized converters that always return String)
  - `TextFormatter.convert(value)` calls `format(value)` internally
  - Formatters can be used in both bindings (as converters) and TextBuilder segments (as formatters)
  - This eliminates redundancy: NumberFormatter replaces FloatToCurrencyConverter and can be used in both contexts

**ReactiveLifecycleManager Utility:**
- Static utility class for common cleanup operations
- Methods:
  - `cleanup_signal_connections(connections: Array[SignalConnection])` - Disconnects all signal connections
  - `cleanup_tweens(tweens: Array[Tween])` - Kills all active Tweens
- Used by all managers and components for consistent cleanup
- Eliminates code duplication across phases

**ReactiveValidationUtils Utility:**
- Static utility class for shared validation patterns
- Common validation logic used by Value Validation, Binding Validation, and Action Validation
- Reduces duplication while keeping system-specific validation in respective classes

**Signal and Scene Cleanup:**
- **Cleanup Pattern:** All signal connections stored in typed `Array[SignalConnection]` for tracking
- **SignalConnection Resource:** Contains `signal: Signal`, `callable: Callable` for type-safe tracking
- **ReactiveBindingManager Implementation:** 
  - Stores `_signal_connections: Array[SignalConnection]` internally
  - In `setup()`, connects signals and stores connections
  - In `cleanup()`, calls `ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)`
- **ReactiveControl Pattern:**
  ```gdscript
  var _binding_manager: ReactiveBindingManager
  
  func _ready():
      _binding_manager = ReactiveBindingManager.new()
      _binding_manager.setup(self, bindings)
  
  func _exit_tree():
      if _binding_manager:
          _binding_manager.cleanup()
  ```
- **Unified Binding Cleanup:** Bindings create connections based on mode:
  - ONE_WAY: ReactiveValue `value_changed` → Control property update (one connection)
  - TWO_WAY: ReactiveValue `value_changed` → Control property update + node signal → ReactiveValue update (two connections)
  - All connections tracked and cleaned up via ReactiveLifecycleManager
- **Circular Update Prevention:** Use `_updating_from_control: bool` and `_updating_from_reactive: bool` flags in ReactiveBindingManager
- **Verification:** Use Godot's debugger to verify no orphaned signal connections after component removal

**SOLID/DRY Architecture:**
- **Single Responsibility:** 
  - ReactiveControl: orchestrates managers and provides component interface (delegates implementation to managers)
  - ReactiveBindingManager: responsible only for binding system, signal connections, and binding lifecycle
  - ReactiveBinding: responsible only for binding configuration
  - ValueConverter: responsible only for value conversion
  - BindingValidator: responsible only for binding validation
  - ReactiveLifecycleManager: responsible only for cleanup operations (static utility)
  - ReactiveValidationUtils: responsible only for shared validation patterns (static utility)
- **Open/Closed:** 
  - Base class closed for modification, open for extension via inheritance (ReactiveLabel, ReactiveButton, ReactiveLineEdit, etc.)
  - Converter system closed for modification, open for extension (new converters inherit from ValueConverter)
  - TextFormatter extends ValueConverter, unifying formatters and converters (eliminates redundancy)
- **Liskov Substitution:** 
  - All ReactiveControl subclasses can be used wherever ReactiveControl is expected
  - All ValueConverter subclasses can be used interchangeably (including TextFormatter subclasses)
  - TextFormatter subclasses can be used as converters in bindings or as formatters in text segments
- **Interface Segregation:** 
  - ReactiveControl exposes minimal public interface (bindings array, cleanup methods)
  - ValueConverter provides minimal interface (convert method)
  - TextFormatter adds format method but maintains convert compatibility
- **Dependency Inversion:** 
  - Depends on ReactiveValue abstraction, not concrete types
  - Depends on ValueConverter abstraction, not concrete converters (formatters are converters)
  - ReactiveBinding resource abstracts binding configuration
- **DRY:** 
  - Common signal connection/disconnection logic in ReactiveLifecycleManager (reused across all phases)
  - Common validation patterns in ReactiveValidationUtils (shared across validation systems)
  - Common validation logic in BindingValidator utility
  - Common conversion error handling in base ValueConverter
  - Unified binding pattern handles both modes
  - Binding implementation isolated in ReactiveBindingManager (no duplication)
  - UI-specific update logic in subclasses

**Test Criteria:**
- **One-Way Binding Tests:**
  - Create ReactiveLabel in editor, configure ReactiveBinding with mode=ONE_WAY to ReactiveString (control_path empty, defaults to self)
  - Verify initial value sync: ReactiveString value appears in label immediately
  - Modify ReactiveString value, verify label updates automatically
  - Test with multiple bindings on same component (mix of one-way and two-way)
  - **Test shared resources:** Two labels share same ReactiveString, change value, both update
- **Two-Way Binding Tests:**
  - Create ReactiveLineEdit with LineEdit child, configure ReactiveBinding with mode=TWO_WAY to ReactiveString
  - Verify initial value sync: ReactiveString value appears in LineEdit immediately
  - Type in LineEdit, verify ReactiveString updates
  - Modify ReactiveString externally, verify LineEdit text updates
  - Test with different Control types (LineEdit, SpinBox, CheckBox)
  - **Test circular prevention:** Verify no infinite loops when both sides update
- **Converter Tests:**
  - Create binding with StringToIntConverter, verify string "123" converts to int 123
  - Create binding with NumberFormatter (as converter), verify int 50 converts to "$50.00" (currency formatting)
  - Test converter error handling: invalid conversion returns error status
  - Test NumberFormatter in binding context: bind ReactiveFloat to Label.text with NumberFormatter, verify currency formatting
- **Validation Tests:**
  - Create binding with invalid control_path, verify status = ERROR_INVALID_PATH
  - Create binding with invalid property name, verify status = ERROR_INVALID_PROPERTY
  - Create binding with missing signal for TWO_WAY, verify status = ERROR_INVALID_SIGNAL
  - Create binding with type mismatch, verify status = ERROR_TYPE_MISMATCH
- **Unified System Tests:**
  - Create component with both ONE_WAY and TWO_WAY bindings, verify both work correctly
  - Switch binding mode in editor, verify connections update appropriately
- **Cleanup Tests:**
  - Remove component from scene tree, verify no signal leaks (use debugger)
  - Add component, remove it, verify no signal connections remain in debugger
  - Test cleanup with both one-way and two-way bindings active
- **Test accessibility:** Set accessibility_description and accessibility_label, verify screen reader support
- **Update unified test scene:** Add section demonstrating ReactiveLabel and ReactiveLineEdit with one-way and two-way bindings, including accessibility examples

**Deliverable:** Working reactive component that supports unified one-way (ReactiveValue → UI) and two-way (UI ↔ ReactiveValue) binding via configurable mode, with value converters, initial sync, validation, status tracking, proper cleanup, and circular update prevention. Unified test scene updated with component examples.

---

## Phase 2.5: Collection Display Components

**Goal:** Create components to display collections (arrays) reactively without scripting.

**Files to Create:**
- `res://ui_system/components/reactive_list.gd` - List component (extends ItemList or custom Control)
- `res://ui_system/components/reactive_grid.gd` - Grid component (extends GridContainer or custom Control)
- `res://ui_system/components/reactive_cell.gd` - Cell component (extends Control)

**Implementation Details:**
- `ReactiveList` extends `ItemList` (or custom Control if more control needed)
- Binds to `ReactiveArray` via `source: ReactiveArray` property
- Auto-generates list items from array
- Updates reactively when array changes (items added/removed/changed)
- Uses `ReactiveCell` as item template (optional, can use default rendering)
- Configurable: `item_template: PackedScene` (saved ReactiveCell scene) or uses default

- `ReactiveGrid` extends `GridContainer` (or custom Control)
- Binds to `ReactiveArray` via `source: ReactiveArray` property
- Configurable `columns: int` property
- Auto-generates grid cells from array
- Updates reactively when array changes
- Uses `ReactiveCell` instances for each cell

- `ReactiveCell` extends `ReactiveControl`
- General-purpose cell component for use in lists, grids, or standalone
- Has `item_index: int` property (set by parent ReactiveList/ReactiveGrid)
- Has `item_source: ReactiveArray` property (set by parent)
- **Direct Access:** Binds directly to item properties via `item_source.get_item_reactive_value(item_index, "property_name")`
- For ReactiveObject items: Binds to `item_source.get_item(item_index).get_property_reactive("property_name")`
- **Direct Configuration:** Configure bindings directly in editor - no template system needed
- Can contain child controls (Label, TextureRect, Button, etc.) bound to item properties
- **Reusability:** Save configured ReactiveCell as scene (.tscn), instance it in ReactiveList/ReactiveGrid

**Direct Access Pattern:**
- ReactiveArray provides: `get_item_reactive_value(index: int, property_path: String) -> ReactiveValue`
- For ReactiveObject items: `get_item(index) -> ReactiveObject`, then `reactive_object.get_property_reactive(name) -> ReactiveValue`
- ReactiveCell bindings reference these reactive values directly
- No intermediate wrappers or templates needed

**SOLID/DRY Architecture:**
- **Single Responsibility:**
  - ReactiveList: responsible only for list display and item generation
  - ReactiveGrid: responsible only for grid display and cell generation
  - ReactiveCell: responsible only for displaying one item's data
- **Open/Closed:** All components closed for modification, open for extension
- **Liskov Substitution:** All can be used wherever ReactiveControl is expected
- **Dependency Inversion:** Depends on ReactiveArray abstraction, not concrete implementations
- **DRY:** Common item generation logic, common reactive update patterns

**Test Criteria:**
- Create ReactiveArray with ReactiveObject items (name, quantity, price)
- Create ReactiveList, bind to array, verify items appear
- Add item to array, verify it appears in list
- Remove item, verify it disappears
- Modify item property, verify list updates
- Create ReactiveCell with bindings to item properties (name → Label, price → Label)
- Save ReactiveCell as scene, use as template in ReactiveList
- Create ReactiveGrid, bind to array, verify grid layout
- Test with different item types (primitives, ReactiveObjects)
- **Update unified test scene:** Add inventory display section using ReactiveList with ReactiveCell showing item properties

**Deliverable:** Working ReactiveList, ReactiveGrid, and ReactiveCell that display collections reactively with direct access and direct configuration. Unified test scene updated with collection display examples.

---

## Phase 2.6: Collection Enhancement Features

**Goal:** Add selection sharing, image/texture binding, and visual feedback to enhance collection display components.

**Files to Create:**
- `res://ui_system/resources/reactive/reactive_reference.gd` - Reference reactive value for sharing selections
- `res://ui_system/resources/converters/string_to_texture_converter.gd` - String to Texture2D converter

**Files to Update:**
- `res://ui_system/components/reactive_cell.gd` - Add selection and hover visual feedback
- `res://ui_system/components/reactive_list.gd` - Add selection management
- `res://ui_system/components/reactive_grid.gd` - Add selection management

**Implementation Details:**

**ReactiveReference:**
- `ReactiveReference` extends `ReactiveValue`
- Holds a reference to any `ReactiveValue` or `ReactiveObject` (or null)
- `value: ReactiveValue` property (the referenced value, can be null)
- `reference_changed(new_reference: ReactiveValue, old_reference: ReactiveValue)` signal
- `set_reference(ref: ReactiveValue)` method to change reference
- `get_reference() -> ReactiveValue` method to get current reference
- When reference changes, emits `value_changed` with new reference
- Can be shared between components (follows same pattern as other ReactiveValues)
- **Use Case:** Share selection state between inventory list and detail panel

**StringToTextureConverter:**
- `StringToTextureConverter` extends `ValueConverter`
- `convert(value: Variant) -> Variant` method
- Takes `ReactiveString` (file path) as input
- Returns `Texture2D` (or null if path invalid)
- Uses `ResourceLoader.load()` to load texture from path
- **Error Handling:** Returns null and reports error via Logger (Godot 4.5) if path invalid
- **Optional Caching:** Caches loaded textures to avoid reloading (keyed by path)
- **Usage:** Bind ReactiveString (icon_path) to TextureRect.texture with this converter

**Visual Feedback (Selection/Hover):**

**ReactiveCell Enhancements:**
- `selection_reference: ReactiveReference` (optional, set by parent ReactiveList/ReactiveGrid)
- `is_selected: bool` (computed property: `selection_reference.value == this item`)
- `hover_style: StyleBox` (optional, for hover visual state)
- `selected_style: StyleBox` (optional, for selected visual state)
- `hover_modulate: Color` (optional, default Color.WHITE - no change)
- `selected_modulate: Color` (optional, default Color.WHITE - no change)
- `_on_mouse_entered()` - sets hover state, applies hover_modulate or hover_style
- `_on_mouse_exited()` - clears hover state, removes hover_modulate
- `_on_gui_input(event)` - handles mouse click to set selection
- Updates visual state reactively when `selection_reference.value` changes
- **Visual Priority:** Selected state overrides hover state

**ReactiveList/ReactiveGrid Enhancements:**
- `selection: ReactiveReference` (optional, shared with all cells)
- When cell is clicked, sets `selection.value = item_at_index`
- Passes `selection` reference to each ReactiveCell instance
- Cells automatically update visual state when selection changes
- Supports single selection (one item at a time)

**Selection Sharing Pattern:**
- Create ReactiveReference resource
- Assign to ReactiveList's `selection` property
- Bind detail panel components to `selection.value` properties
- When user clicks item in list, detail panel automatically updates
- Multiple components can share same ReactiveReference for synchronized selection

**SOLID/DRY Architecture:**
- **Single Responsibility:**
  - ReactiveReference: responsible only for holding and sharing references
  - StringToTextureConverter: responsible only for converting paths to textures
  - Visual feedback: responsible only for visual state management
- **Open/Closed:**
  - ReactiveReference closed for modification, open for extension
  - Converter system closed for modification, open for extension (new converters)
  - Visual feedback closed for modification, open for extension (custom styles)
- **Liskov Substitution:**
  - ReactiveReference can be used wherever ReactiveValue is expected
  - StringToTextureConverter can be used wherever ValueConverter is expected
- **Interface Segregation:**
  - ReactiveReference provides minimal interface (set_reference, get_reference)
  - StringToTextureConverter provides minimal interface (convert method)
- **Dependency Inversion:**
  - Components depend on ReactiveReference abstraction
  - Bindings depend on ValueConverter abstraction
- **DRY:**
  - Reuses existing ReactiveValue base functionality
  - Reuses existing ValueConverter system
  - Common visual feedback patterns in ReactiveCell base class

**Test Criteria:**
- **ReactiveReference Tests:**
  - Create ReactiveReference, set reference to ReactiveObject, verify value_changed signal
  - Change reference, verify old and new references in signal
  - Share ReactiveReference between two components, change reference, verify both update
  - Set reference to null, verify null handling
- **Image/Texture Binding Tests:**
  - Create ReactiveString with icon path, bind to TextureRect with StringToTextureConverter
  - Verify texture loads and displays correctly
  - Test with invalid path, verify error handling (returns null, reports error)
  - Test with valid path, verify texture appears in TextureRect
  - Test caching: load same path twice, verify second load uses cache
- **Visual Feedback Tests:**
  - Create ReactiveList with ReactiveReference selection
  - Click cell, verify selection_reference.value updates
  - Verify clicked cell shows selected visual state (modulate or style)
  - Hover over cell, verify hover visual state appears
  - Move mouse away, verify hover state clears
  - Click different cell, verify previous cell deselects, new cell selects
  - Create detail panel bound to selection_reference.value, verify it updates when selection changes
- **Integration Tests:**
  - Create inventory: ReactiveList with ReactiveReference selection
  - Create detail panel with ReactiveTextLabel bound to selection.name
  - Create detail panel with TextureRect bound to selection.icon_path (with converter)
  - Click item in list, verify detail panel updates automatically
  - Test with multiple detail panels sharing same selection reference
- **Update unified test scene:** Add inventory example with selection, detail panel, and image binding

**Deliverable:** ReactiveReference for selection sharing, StringToTextureConverter for image binding, and visual feedback (selection/hover) for collection components. Unified test scene updated with enhanced inventory example showing selection sharing and image display.

---

## Phase 3: Target/Action System

**Goal:** Enable reactive components to perform actions on reactive value targets without code.

**Files to Create:**
- `res://ui_system/resources/actions/reactive_action.gd` - Base action class
- `res://ui_system/resources/actions/action_increment.gd` - Increment action
- `res://ui_system/resources/actions/action_decrement.gd` - Decrement action
- `res://ui_system/resources/actions/action_set.gd` - Set value action
- `res://ui_system/resources/actions/action_append.gd` - Append action (for strings)
- `res://ui_system/resources/actions/action_change_scene.gd` - Change scene action
- `res://ui_system/resources/actions/action_group.gd` - Action group resource (parallel/sequential execution)
- `res://ui_system/resources/actions/action_params.gd` - Base action parameters class
- `res://ui_system/resources/actions/increment_params.gd` - Typed parameters for increment (amount: int)
- `res://ui_system/resources/actions/set_params.gd` - Typed parameters for set (value: Variant)
- `res://ui_system/resources/actions/append_params.gd` - Typed parameters for append (text: String)
- `res://ui_system/resources/actions/change_scene_params.gd` - Typed parameters for change scene (scene_path: String)
- `res://ui_system/resources/conditions/reactive_condition.gd` - Base condition abstract class
- `res://ui_system/resources/conditions/value_comparison_condition.gd` - Comparison condition (>, <, ==, !=, <=, >=)
- `res://ui_system/resources/actions/reactive_action_binding.gd` - Target/Action pair resource
- `res://ui_system/components/reactive_button.gd` - Button component with action support

**Implementation Details:**
- `ReactiveAction` base class with `execute(target: ReactiveValue, params: ActionParams) -> bool` method
- Returns `bool` to indicate success/failure
- `validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool` method for pre-execution validation
- Each action type handles its specific operation with type-safe parameters
- `ReactiveActionBinding` resource contains:
  - `target: ReactiveValue` (reference) - optional for ActionGroup (groups don't need single target)
  - `action: Variant` (reference) - can be `ReactiveAction` OR `ActionGroup` Resource
  - `params: ActionParams` (typed Resource, not Dictionary - e.g., IncrementParams, SetParams)
  - `condition: ReactiveCondition` (optional - action only executes if condition evaluates to true)
- **Conditional Execution:** Action checks condition before executing: `if condition and not condition.evaluate(target): return false`
- **Action Validation:** Validates action/target compatibility before execution (type checking, value constraints)
- `ReactiveControl` has `Array[ReactiveActionBinding]` exported property
- `ReactiveButton` triggers actions on `pressed` signal

**ActionChangeScene:**
- `ActionChangeScene` extends `ReactiveAction`
- `ChangeSceneParams` contains: `scene_path: String` (path to scene file)
- Uses `get_tree().change_scene_to_file(scene_path)` to change scenes
- **Use Case:** Main menu buttons, level transitions, UI navigation
- Validates scene path exists before executing
- Returns `false` if scene path invalid, reports error via Logger (Godot 4.5)

**ActionGroup:**
- `ActionGroup` extends `Resource` (not ReactiveAction - it's a container)
- Contains: `actions: Array[ReactiveActionBinding]` (actions to execute)
- Contains: `execution_mode: enum {PARALLEL, SEQUENCE}` (how to execute actions)
- **PARALLEL Mode:** All actions execute simultaneously
- **SEQUENCE Mode:** Actions execute sequentially (one after another, waiting for each to complete)
- **Nesting Support:** ActionGroups can contain other ActionGroups (full nesting support, arbitrary depth)
- **Usage:** Assign ActionGroup to `ReactiveActionBinding.action` property
- When executed, runs all actions according to execution_mode
- Returns `true` if all actions succeed, `false` if any fail
- **Use Cases:**
  - **SEQUENCE Mode:** Multi-step operations (buy: remove from shop → add to player → decrement money)
  - **PARALLEL Mode:** Simultaneous operations (update multiple UI elements at once)
  - **Nested Groups:** Complex workflows (Group (parallel) → Group (sequence) → Group (parallel))
  - **Reusable Patterns:** Save ActionGroup as Resource, reuse in multiple contexts

**Condition System:**
- `ReactiveCondition` base abstract class with `evaluate(target: ReactiveValue) -> bool` method
- `ValueComparisonCondition` supports: >, <, ==, !=, <=, >=, contains (for strings)
- Conditions are Resources, can be shared and reused
- Conditions can compare target value to constant or another ReactiveValue
- **Purpose:** Conditions evaluate runtime state to determine if action should execute (different from Validators which enforce value constraints)

**Validation System Separation (Three Distinct Systems):**
1. **Value Validation (Phase 1 - Validators):** 
   - Purpose: Enforces constraints on ReactiveValue values (min/max, length, format)
   - When: Runs automatically when ReactiveValue.set_value() is called
   - Scope: ReactiveValue resources only
   - Result: Prevents invalid values from being set
   
2. **Binding Validation (Phase 2 - BindingValidator):**
   - Purpose: Validates binding configuration (path exists, property exists, signal exists, type compatibility)
   - When: Runs when binding is created/configured
   - Scope: ReactiveBinding resources
   - Result: Sets binding status (CONNECTED, ERROR_*, etc.)
   
3. **Action Validation (Phase 3 - validate_before_execute):**
   - Purpose: Checks if action is compatible with target ReactiveValue type
   - When: Runs before action.execute() is called
   - Scope: ReactiveAction execution
   - Result: Returns bool, prevents incompatible actions from executing

**Action Validation vs Value Validation:**
- **Action Validation (`validate_before_execute`):** Checks if action is compatible with target (e.g., can't increment a string)
- **Value Validation (Validators):** Enforces constraints on ReactiveValue (min/max, length, format) - handled by ReactiveValue system
- These are separate concerns: action validation checks compatibility, value validation enforces constraints

**Typed Action Parameters:**
- `ActionParams` base Resource class (replaces Dictionary)
- Each action has specific params Resource (IncrementParams, SetParams, etc.)
- Type-safe, editor-friendly, prevents key errors
- Editor plugin validates params match action type

**Signal and Scene Cleanup:**
- **Button Signal Cleanup:** ReactiveButton connects to `pressed` signal in `_ready()`, stores connection in ReactiveBindingManager
- **Action Execution:** Actions do not create persistent connections (they're called directly), so no cleanup needed
- **Component Cleanup:** ReactiveControl base class cleanup (via ReactiveBindingManager) handles reactive value connections using ReactiveLifecycleManager
- **Verification:** Remove button from scene, verify no signal leaks

**SOLID/DRY Architecture:**
- **Single Responsibility:** 
  - `ReactiveAction` classes: responsible only for executing one type of operation
  - `ActionParams` classes: responsible only for storing action-specific parameters
  - `ReactiveCondition` classes: responsible only for evaluating conditions
  - `ReactiveActionBinding`: responsible only for pairing target with action and condition
  - `ActionGroup`: responsible only for grouping actions and managing execution mode
  - `ReactiveButton`: responsible only for triggering actions on press
- **Open/Closed:** 
  - Action system closed for modification, open for extension (new actions inherit from ReactiveAction)
  - Condition system closed for modification, open for extension (new conditions inherit from ReactiveCondition)
  - ActionGroup closed for modification, open for extension (can contain any actions)
  - ReactiveControl closed for modification, open for extension (new components can use target/action system)
- **Liskov Substitution:** 
  - All ReactiveAction subclasses can be used interchangeably
  - All ReactiveCondition subclasses can be used interchangeably
  - All ActionParams subclasses can be used where ActionParams is expected
  - ActionGroup can be used wherever ReactiveAction is expected (via ReactiveActionBinding.action)
- **Interface Segregation:** 
  - ReactiveAction provides minimal interface (execute, validate_before_execute methods)
  - ReactiveCondition provides minimal interface (evaluate method)
  - ActionParams provides minimal interface (serialization)
  - ActionGroup provides minimal interface (actions array, execution_mode)
- **Dependency Inversion:** 
  - Actions depend on ReactiveValue abstraction, not concrete types
  - Actions depend on ActionParams abstraction, not concrete params
  - Actions depend on ReactiveCondition abstraction, not concrete conditions
  - ActionGroup depends on ReactiveActionBinding abstraction, not concrete actions
- **DRY:** 
  - Common action execution pattern (condition check, validation, execution) in base class
  - Common condition evaluation patterns in base ReactiveCondition class
  - Common validation logic in base ReactiveAction class
  - Common group execution logic in ActionGroup
  - Operation-specific logic in subclasses
  - Full composability: ActionGroups can nest arbitrarily

**Test Criteria:**
- Create button, assign target (ReactiveInt) and action (Increment) with IncrementParams(amount=5)
- Click button, verify target value increments by 5
- Test multiple target/action pairs on single button
- Test different action types (increment, decrement, set, append) with typed params
- **Test ActionChangeScene:** Create button with ActionChangeScene, click, verify scene changes
- **Test ActionChangeScene validation:** Use invalid scene path, verify error handling
- **Test ActionGroup PARALLEL:** Create ActionGroup with 3 actions, mode=PARALLEL, verify all execute simultaneously
- **Test ActionGroup SEQUENCE:** Create ActionGroup with 3 actions, mode=SEQUENCE, verify executes sequentially (one after another)
- **Test ActionGroup SEQUENCE failure:** Create ActionGroup SEQUENCE where middle action fails, verify sequence stops
- **Test nested ActionGroups:** Create ActionGroup containing another ActionGroup, verify nested execution respects execution modes
- **Test complex nesting:** Create ActionGroup (PARALLEL) → ActionGroup (SEQUENCE) → ActionGroup (PARALLEL), verify full composability
- **Test ActionGroup reusability:** Save ActionGroup as Resource, use in multiple buttons, verify works correctly
- **Test conditional execution:** Add ValueComparisonCondition (target > 10), verify action only executes when condition is true
- **Test action validation:** Try to increment a ReactiveString, verify validation fails gracefully and returns false
- **Test error recovery:** After validation failure, correct the issue (e.g., change target to compatible type), verify action can now execute
- **Test condition operators:** Test all comparison operators (>, <, ==, !=, <=, >=, contains)
- Verify actions work with different reactive value types appropriately
- **Test cleanup:** Remove button, verify no signal leaks
- **Test multiple targets:** Button with 3 target/action pairs, verify all execute
- **Update unified test scene:** Add buttons demonstrating various actions (increment, decrement, set, append, change scene), and ActionGroup examples with PARALLEL and SEQUENCE modes

**Deliverable:** Reactive components can trigger configurable, conditionally-executed actions on reactive value targets via editor, with typed parameters, validation, and proper cleanup. Includes ActionChangeScene for scene transitions and ActionGroup for parallel/sequential action grouping with full composability and nesting support. Unified test scene updated with action examples including scene changes and action groups.

---

## Phase 3.5: Collection Actions

**Goal:** Add actions for manipulating collections (arrays) without scripting.

**Files to Create:**
- `res://ui_system/resources/actions/action_add_item.gd` - Add item to array action
- `res://ui_system/resources/actions/action_remove_item.gd` - Remove item from array action
- `res://ui_system/resources/actions/action_move_item.gd` - Move/reorder item action
- `res://ui_system/resources/actions/action_swap_items.gd` - Swap two items action
- `res://ui_system/resources/actions/action_clear_array.gd` - Clear array action
- `res://ui_system/resources/actions/add_item_params.gd` - Parameters for add item
- `res://ui_system/resources/actions/remove_item_params.gd` - Parameters for remove item
- `res://ui_system/resources/actions/move_item_params.gd` - Parameters for move item
- `res://ui_system/resources/actions/swap_items_params.gd` - Parameters for swap items

**Implementation Details:**
- `ActionAddItem` with `AddItemParams` (item: Variant, index: int = -1 for append)
- `ActionRemoveItem` with `RemoveItemParams` (index: int)
- `ActionMoveItem` with `MoveItemParams` (from_index: int, to_index: int)
- `ActionSwapItems` with `SwapItemsParams` (index1: int, index2: int)
- `ActionClearArray` with no params (clears entire array)
- All actions validate target is ReactiveArray before execution
- Actions can be used with buttons, cell clicks, drag-drop handlers, etc.

**SOLID/DRY Architecture:**
- **Single Responsibility:** Each action handles one collection operation
- **Open/Closed:** Closed for modification, open for extension (new collection actions)
- **Liskov Substitution:** All actions can be used interchangeably
- **Dependency Inversion:** Actions depend on ReactiveArray abstraction
- **DRY:** Common validation and error handling in base action class, uses ReactiveValidationUtils for shared validation patterns

**Test Criteria:**
- Create button with ActionAddItem, click, verify item added to ReactiveArray
- Create button with ActionRemoveItem, click, verify item removed
- Test ActionMoveItem to reorder items
- Test ActionSwapItems to swap two items
- Test ActionClearArray to clear all items
- Verify all actions update ReactiveList/ReactiveGrid reactively
- **Update unified test scene:** Add buttons in inventory section demonstrating collection actions (add, remove, move items)

**Deliverable:** Complete set of collection manipulation actions that work with ReactiveArray without scripting. Unified test scene updated with collection action examples.

---

## Phase 4: Text Builder System

**Goal:** Create a flexible text builder that combines static text, reactive sources, and conditional logic.

**Files to Create:**
- `res://ui_system/resources/text/text_segment.gd` - Base segment class
- `res://ui_system/resources/text/segment_context.gd` - Typed context Resource for segment building
- `res://ui_system/resources/text/segment_literal.gd` - Static text segment
- `res://ui_system/resources/text/segment_source.gd` - Reactive value source segment
- `res://ui_system/resources/text/segment_conditional.gd` - Conditional segment (if/then/else)
- `res://ui_system/resources/text/segment_translation.gd` - Translation segment (i18n support)
- `res://ui_system/resources/text/text_builder.gd` - Text builder resource
- `res://ui_system/resources/formatters/text_formatter.gd` - Base formatter abstract class (extends ValueConverter)
- `res://ui_system/resources/formatters/number_formatter.gd` - Number formatting (decimals, currency, thousand separators)
- `res://ui_system/resources/formatters/rich_text_formatter.gd` - Rich text formatting (bold, color, size)
- `res://ui_system/components/reactive_text_label.gd` - Label using text builder

**Implementation Details:**
- `TextSegment` base with `build(context: SegmentContext) -> String` method
- `SegmentContext` Resource contains typed access to ReactiveValues and other context data (replaces Dictionary)
- `SegmentLiteral`: returns static text
- `SegmentSource`: reads from ReactiveValue, applies optional formatter, handles type conversion
  - `formatter: TextFormatter` (optional Resource) - formats the value before display
  - Supports NumberFormatter (currency, decimals, thousand separators)
  - Supports RichTextFormatter (bold, color, size) for RichTextLabel
- `SegmentConditional`: evaluates condition using `ValueComparisonCondition` (reuses from Phase 3)
  - Supports all comparison operators: >, <, ==, !=, <=, >=, contains (for strings)
  - Returns `then_text` if condition true, `else_text` if false
- `SegmentTranslation`: integrates with Godot's i18n system
  - `translation_key: String` - Translation key (e.g., "ui.menu.start")
  - `fallback_text: String` - Fallback text if translation missing
  - Uses `tr()` function to get translated text
  - Supports pluralization and context if needed
  - Auto-updates when language changes (connects to TranslationServer)
- `TextBuilder` contains `Array[TextSegment]` in order
- `TextBuilder.build()` processes segments sequentially
- Auto-updates when any source ReactiveValue changes or when translation language changes
- `ReactiveTextLabel` uses TextBuilder for its text content (can use Label or RichTextLabel)

**Text Formatter System (Unified with Converters):**
- `TextFormatter` extends `ValueConverter` - formatters are specialized converters that always return String
- `TextFormatter` base abstract class with `format(value: Variant) -> String` method
- `TextFormatter.convert(value: Variant) -> Variant` calls `format(value)` internally (always returns String)
- `NumberFormatter`: formats numbers with decimals, currency symbols, thousand separators
  - Can be used in bindings (as ValueConverter) or TextBuilder segments (as TextFormatter)
  - Replaces FloatToCurrencyConverter - more flexible and usable in both contexts
- `RichTextFormatter`: applies BBCode formatting (bold, color, size) for RichTextLabel
- Formatters are Resources, can be shared and reused
- Editor plugin auto-suggests compatible formatters/converters based on ReactiveValue type and context (binding vs text segment)

**Signal and Scene Cleanup:**
- **TextBuilder Signal Management:** TextBuilder connects to all source ReactiveValues' `value_changed` signals
- **Cleanup Pattern:** TextBuilder stores signal connections using `Array[SignalConnection]`, uses `ReactiveLifecycleManager.cleanup_signal_connections()` in cleanup
- **ReactiveTextLabel Cleanup:** Inherits cleanup from ReactiveControl base class (which uses ReactiveBindingManager)
- **Segment Cleanup:** Segments that reference ReactiveValues must track connections if they need direct updates
- **Implementation:** TextBuilder maintains `_source_connections: Array[SignalConnection]` and calls `ReactiveLifecycleManager.cleanup_signal_connections(_source_connections)` when segments are modified or on cleanup

**SOLID/DRY Architecture:**
- **Single Responsibility:**
  - `TextSegment` classes: responsible only for generating their portion of text
  - `TextFormatter` classes: responsible only for formatting values
  - `TextBuilder`: responsible only for orchestrating segment building and managing reactive updates
  - `ReactiveTextLabel`: responsible only for displaying TextBuilder output
- **Open/Closed:**
  - TextSegment base closed for modification, open for extension (new segment types)
  - TextFormatter extends ValueConverter, unified system (new formatters inherit from TextFormatter, can be used as converters)
  - TextBuilder closed for modification, open for extension via new segment types
- **Liskov Substitution:** 
  - All TextSegment subclasses can be used interchangeably in TextBuilder array
  - All TextFormatter subclasses can be used interchangeably (as formatters or converters)
  - TextFormatter subclasses can be used in bindings (as ValueConverter) or text segments (as TextFormatter)
- **Interface Segregation:** 
  - TextSegment provides minimal interface (build method)
  - TextFormatter provides minimal interface (format method, convert method via ValueConverter inheritance)
- **Dependency Inversion:** 
  - Segments depend on ReactiveValue abstraction, not concrete types
  - Formatters depend on ValueConverter abstraction (formatters are converters)
  - Segments depend on TextFormatter abstraction, not concrete formatters
  - SegmentConditional reuses ReactiveCondition abstraction (from Phase 3), not concrete conditions
- **DRY:** 
  - Common segment processing logic in TextBuilder
  - Common formatting patterns in base TextFormatter class
  - TextFormatter extends ValueConverter - unified system eliminates redundancy (NumberFormatter replaces FloatToCurrencyConverter)
  - Reuses condition system from Phase 3 (no duplication)
  - Segment-specific logic in subclasses

**Test Criteria:**
- Create text builder with: literal "Price: ", source (ReactiveInt), literal " coins"
- Verify output: "Price: 50 coins"
- **Test number formatting:** Add NumberFormatter to source (currency="$", decimals=2), verify output: "Price: $50.00 coins"
- **Test NumberFormatter as converter:** Create binding with ReactiveFloat → Label.text using NumberFormatter (as ValueConverter), verify currency formatting works in binding context
- **Test conditional operators:** Add conditional with all operators (>, <, ==, !=, <=, >=, contains), verify each works correctly
- Add conditional: if source > 100, show "EXPENSIVE", else show "AFFORDABLE"
- Modify source value, verify text updates reactively
- **Test rich text formatting:** Use RichTextFormatter with bold/color, verify formatting appears in RichTextLabel
- Test complex sequences: text, source (formatted), conditional, text, source
- **Test i18n support:** Add SegmentTranslation with translation key, verify translated text appears, change language, verify updates
- **Test cleanup:** Remove ReactiveTextLabel, verify TextBuilder disconnects from all sources (including TranslationServer)
- **Test shared sources:** Multiple labels use same ReactiveValue in text builder, all update
- **Update unified test scene:** Add character stats section using ReactiveTextLabel with formatted values, conditional text, and translation segments

**Deliverable:** Dynamic text labels that combine static text, reactive values, conditional logic with full operator support, number formatting, rich text formatting, i18n translation support, and proper cleanup. TextFormatter extends ValueConverter (unified system) - formatters can be used in both bindings and text segments, eliminating redundancy. Unified test scene updated with text builder examples including translations.

---

## Phase 5: Animation System

**Goal:** Create an editor-configurable animation system that supports forward/backward playback, sequences, and parallel animations.

**Files to Create:**
- `res://ui_system/resources/animations/animation_step.gd` - Single animation step
- `res://ui_system/resources/animations/reactive_animation.gd` - Animation resource
- `res://ui_system/resources/animations/animation_group.gd` - Parallel/sequence container
- `res://ui_system/resources/animations/animation_event.gd` - Base animation event abstract class
- `res://ui_system/resources/animations/animation_event_context.gd` - Typed context Resource for animation events
- `res://ui_system/resources/animations/signal_event.gd` - Event that emits a signal
- `res://ui_system/resources/animations/action_event.gd` - Event that triggers an action
- `res://ui_system/managers/reactive_animation_manager.gd` - Animation orchestration manager (RefCounted)

**Implementation Details:**
- `AnimationStep` contains:
  - `target_property: String` (e.g., "modulate:a")
  - `value_mode: enum {ABSOLUTE, RELATIVE}` - whether end_value is absolute or relative to start
  - `start_value: Variant` (optional for RELATIVE mode - uses current value if not set)
  - `end_value: Variant` (absolute value or relative offset based on value_mode)
  - `duration: float`
  - `delay: float` - delay before this step starts (for sequences)
  - `easing: Tween.EaseType`
  - `events: Array[AnimationEvent]` - events to trigger during this step
- `ReactiveAnimation` contains:
  - `Array[AnimationStep]` - steps to execute
  - `loop: bool` - whether to loop the animation
  - `loop_count: int` - number of loops (-1 = infinite)
  - `on_complete: Array[ReactiveAnimation]` - animations to chain/play when this completes
- `ReactiveAnimation.play_forward(target: Control)` - creates Tween, plays steps in order
- `ReactiveAnimation.play_backward(target: Control)` - creates Tween, plays steps in reverse
- **Relative Values:** If `value_mode == RELATIVE`, `end_value` is added to current property value (or start_value if set)
- **Animation Events:** Events trigger at appropriate times (on_start, on_step_complete, on_complete)
- **Animation Chaining:** When animation completes, automatically plays animations in `on_complete` array
- `AnimationGroup` contains `Array[ReactiveAnimation]` with `mode: enum {SEQUENCE, PARALLEL}`
- **ReactiveAnimationManager:**
  - RefCounted class that handles all animation logic
  - Manages Tween lifecycle, active animations, and cleanup
  - Instantiated in `_ready()`, cleaned up in `_exit_tree()`
  - Methods: `setup(owner: Control)`, `play_animation(animation: ReactiveAnimation)`, `stop_animation(animation: ReactiveAnimation)`, `cleanup()`
- Animation methods (`play_animation()`, `stop_animation()`, etc.) in `ReactiveControl` delegate to ReactiveAnimationManager
- Components can export `Array[ReactiveAnimation]` to configure animations in editor

**Animation Event System:**
- `AnimationEvent` base abstract class with `trigger(context: AnimationEventContext)` method
- `AnimationEventContext` Resource contains typed access to animation state, target Control, and event data (replaces Dictionary)
- `SignalEvent`: emits a signal when triggered
- `ActionEvent`: triggers a ReactiveActionBinding when triggered
- Events can be attached to steps or animations
- Events trigger at: step start, step complete, animation start, animation complete

**Signal and Scene Cleanup:**
- **Tween Cleanup:** All Tweens created by animations stored in ReactiveAnimationManager
- **ReactiveAnimationManager Implementation:**
  - Stores `_active_tweens: Array[Tween]` internally
  - In `play_animation()`, creates Tween and stores it
  - In `cleanup()`, calls `ReactiveLifecycleManager.cleanup_tweens(_active_tweens)`
- **Animation Signal Cleanup:** If animations connect to component signals (e.g., hover), tracked and cleaned up via ReactiveLifecycleManager
- **ReactiveControl Pattern:**
  ```gdscript
  var _animation_manager: ReactiveAnimationManager
  
  func _ready():
      _animation_manager = ReactiveAnimationManager.new()
      _animation_manager.setup(self)
  
  func play_animation(animation: ReactiveAnimation):
      if _animation_manager:
          _animation_manager.play_animation(animation)
  
  func _exit_tree():
      if _animation_manager:
          _animation_manager.cleanup()
  ```

**SOLID/DRY Architecture:**
- **Single Responsibility:**
  - `AnimationStep`: responsible only for defining one animation property change
  - `AnimationEvent`: responsible only for triggering one type of event
  - `ReactiveAnimation`: responsible only for defining animation steps, loops, and chaining (does not manage Tween lifecycle)
  - `ReactiveAnimationManager`: responsible only for orchestrating animations, managing Tween lifecycle, and cleanup
  - `AnimationGroup`: responsible only for managing parallel/sequential execution
  - Animation methods in `ReactiveControl`: responsible only for delegating to ReactiveAnimationManager
- **Open/Closed:**
  - Animation system closed for modification, open for extension (new step types, new event types, new animation patterns)
- **Liskov Substitution:** 
  - All ReactiveAnimation instances can be used interchangeably
  - All AnimationEvent instances can be used interchangeably
- **Interface Segregation:** 
  - ReactiveAnimation provides minimal interface (play_forward, play_backward, stop)
  - AnimationEvent provides minimal interface (trigger method)
- **Dependency Inversion:** 
  - Animations depend on Control abstraction, not specific component types
  - Events depend on ReactiveActionBinding abstraction (reuses from Phase 3), not concrete actions
- **DRY:** 
  - Common Tween creation/management in ReactiveAnimationManager
  - Common cleanup via ReactiveLifecycleManager.cleanup_tweens()
  - Common event triggering logic in base AnimationEvent class
  - Common relative/absolute value handling in AnimationStep
  - Step-specific logic in AnimationStep subclasses

**Test Criteria:**
- Create animation: fade out (modulate:a 1.0 -> 0.0), move (position.x +100)
- Play forward, verify both steps execute in sequence
- Play backward, verify steps reverse (fade in, move back)
- **Test relative values:** Create step with value_mode=RELATIVE, end_value=+50, verify it adds to current value
- **Test delays:** Create sequence with delay between steps, verify delay is respected
- **Test loops:** Set loop=true, loop_count=3, verify animation loops 3 times
- **Test events:** Add SignalEvent to step, verify signal emits when step completes
- **Test chaining:** Set on_complete to another animation, verify it plays automatically when first completes
- Create parallel group: fade + scale simultaneously
- Create sequence group: fade then move
- Test with ReactiveButton: animate on hover, reverse on unhover
- **Test cleanup:** Remove animated component during animation, verify Tween is killed, no leaks
- **Test interruption:** Start forward animation, immediately start backward, verify smooth transition
- **Update unified test scene:** Add animation examples (hover effects on buttons, fade transitions)

**Deliverable:** Animations configurable in editor that play forward/backward without duplication, with relative/absolute values, delays, loops, events, chaining, and proper cleanup. Unified test scene updated with animation examples.

---

## Phase 6: Navigation System

**Goal:** Implement controller and keyboard navigation for UI components.

**Files to Create:**
- `res://ui_system/navigation/reactive_navigation.gd` - Navigation orchestrator
- `res://ui_system/navigation/reactive_navigation_group.gd` - Navigation group resource
- `res://ui_system/navigation/reactive_input_handler.gd` - Input handling (RefCounted)
- `res://ui_system/managers/reactive_focus_manager.gd` - Focus order management (RefCounted, can be shared with ReactiveControl)

**Implementation Details:**
- `ReactiveNavigation` extends `Node` (autoload singleton recommended)
- Orchestrates navigation but delegates to specialized handlers
- Manages multiple navigation groups via `Dictionary[String, ReactiveNavigationGroup]`
- `current_group: String` property to switch between groups
- **ReactiveInputHandler:**
  - RefCounted class that handles InputMap actions: "ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel"
  - Controller support via Input system
  - Processes input and delegates focus movement to ReactiveFocusManager
- **ReactiveFocusManager:**
  - RefCounted class that manages focus order and focus state
  - Can be used by ReactiveControl (for local focus) or ReactiveNavigation (for group focus)
  - Methods: `setup(owner: Control)`, `set_focus_order(order: Array[NodePath])`, `move_focus(direction: String)`, `cleanup()`
- Focus management methods in `ReactiveControl` delegate to ReactiveFocusManager
- All ReactiveControl instances are automatically focusable (Control base class provides this)
- Visual focus indicators (optional theme integration)
- **Navigation Groups:** 
  - `ReactiveNavigationGroup` Resource contains: `name: String`, `focus_order: Array[NodePath]`, `wrap_around: bool`
  - `ReactiveControl` has optional `navigation_group: String` property to assign component to a group
  - ReactiveNavigation manages focus within current group only via ReactiveFocusManager
  - Groups can be switched at runtime (e.g., menu group vs game UI group)
- **Tab Order Management:** 
  - Primary: NavigationGroup's `focus_order` array defines tab order for that group (managed by ReactiveFocusManager)
  - Fallback: If component not in a group, uses ReactiveControl's local ReactiveFocusManager (if defined)
  - Components automatically register with their assigned group on `_ready()`

**Signal and Scene Cleanup:**
- **Input Signal Cleanup:** ReactiveInputHandler tracks input connections, cleaned up via ReactiveLifecycleManager
- **Focus Signal Cleanup:** ReactiveFocusManager tracks focus signal connections, cleaned up via ReactiveLifecycleManager
- **Navigation Manager Cleanup:** If ReactiveNavigation is autoload, it persists, but should clean up handlers when scene changes
- **Pattern:** ReactiveNavigation delegates cleanup to ReactiveInputHandler and ReactiveFocusManager, which use ReactiveLifecycleManager

**SOLID/DRY Architecture:**
- **Single Responsibility:**
  - `ReactiveNavigation`: responsible only for orchestrating navigation, managing groups, and group switching
  - `ReactiveInputHandler`: responsible only for processing input and translating to navigation commands
  - `ReactiveFocusManager`: responsible only for managing focus order and focus state
  - `ReactiveNavigationGroup`: responsible only for storing focus order configuration
  - Focus methods in `ReactiveControl`: responsible only for delegating to ReactiveFocusManager
- **Open/Closed:**
  - Navigation system closed for modification, open for extension (custom navigation patterns, new group types)
- **Liskov Substitution:** 
  - All ReactiveControl instances can be used interchangeably in navigation
  - All ReactiveNavigationGroup instances can be used interchangeably
- **Interface Segregation:** 
  - ReactiveControl provides minimal focus interface (focus methods)
  - ReactiveNavigationGroup provides minimal interface (name, focus_order, wrap_around)
- **Dependency Inversion:** 
  - Navigation depends on Control abstraction, not specific component types
  - Navigation depends on ReactiveNavigationGroup abstraction
- **DRY:** 
  - Common focus management logic in ReactiveFocusManager (reused by ReactiveControl and ReactiveNavigation)
  - Common input handling logic in ReactiveInputHandler
  - Common cleanup via ReactiveLifecycleManager
  - Common group management logic in ReactiveNavigation
  - Focus behavior in ReactiveControl base class delegates to ReactiveFocusManager

**Test Criteria:**
- Create scene with 4 buttons
- Configure tab order in editor
- Navigate with keyboard (arrow keys, Tab, Enter)
- Navigate with controller (D-pad, A button)
- Verify focus moves in correct order
- Test focus wrapping (last -> first, first -> last)
- **Test navigation groups:** Create two groups (menu, game), assign components to groups, switch groups, verify focus only moves within current group
- **Test dynamic groups:** Add/remove components from groups at runtime, verify navigation updates
- **Test cleanup:** Remove focusable component, verify it's removed from navigation order
- **Test scene switching:** Switch scenes, verify navigation resets properly
- **Update unified test scene:** Verify all interactive components are navigable with keyboard/controller, test navigation groups

**Deliverable:** Full keyboard and controller navigation support for reactive components with navigation groups, dynamic management, and proper cleanup. Unified test scene fully navigable.

---

## Phase 7: Editor Plugins and Polish

**Goal:** Create editor plugins to enhance designer workflow and add final polish.

**Files to Create:**
- `res://ui_system/editor/plugin.cfg` - Plugin configuration
- `res://ui_system/editor/ui_system_plugin.gd` - Main plugin script
- `res://ui_system/editor/inspector_plugins/reactive_value_picker.gd` - Custom ReactiveValue picker
- `res://ui_system/editor/inspector_plugins/binding_editor.gd` - Unified binding configuration UI
- `res://ui_system/editor/inspector_plugins/action_configurator.gd` - Action configuration UI
- `res://ui_system/editor/inspector_plugins/text_builder_editor.gd` - Visual text segment builder
- `res://ui_system/editor/inspector_plugins/animation_editor.gd` - Animation step builder
- `res://ui_system/utils/control_inspector.gd` - Reflection utility for auto-detection
- `res://ui_system/utils/reactive_utils.gd` - Utility functions
- `res://ui_system/components/reactive_foldable_container.gd` - FoldableContainer wrapper/extender
- `res://ui_system/utils/reactive_accessibility.gd` - Accessibility utilities

**Implementation Details:**
- `EditorInspectorPlugin` for custom property editors
- **Auto-Detection System:**
  - `ControlInspector` utility class uses reflection to auto-detect:
    - Available properties on Control nodes: `get_available_properties(control: Control) -> Array[String]`
    - Available signals on Control nodes: `get_available_signals(control: Control) -> Array[String]`
    - Property types: `get_property_type(control: Control, property: String) -> Variant.Type`
  - **Caching:** Reflection results are cached by Control type to improve performance
  - Cache is cleared when editor reloads or on demand
  - Editor plugins use ControlInspector to auto-populate dropdowns
  - Reduces manual configuration errors
- **Visual Feedback:**
  - Binding editor shows status indicators (green=connected, red=error, yellow=warning)
  - Action configurator shows validation warnings in real-time
  - Text builder shows live preview of output
  - Animation editor shows preview playback
- **Error Reporting System (Godot 4.5 Logger):**
  - Uses Godot 4.5's `Logger` class for structured logging
  - Logger instance: `Logging.get_logger("ReactiveUI")`
  - All systems (validators, bindings, actions) use Logger for error reporting
  - Logger supports severity levels: `logger.error()`, `logger.warning()`, `logger.info()`, `logger.debug()`
  - Logger supports structured context: `logger.error("Binding validation failed", {"binding": binding, "error": error})`
  - Editor plugin shows error list panel (reads from Logger)
  - Runtime debug overlay shows errors visually (reads from Logger)
  - **Error Persistence:** Logger handles persistence automatically (session-only by default)
- ReactiveValue picker: filtered dropdown by type, shows current value
- Unified binding editor: visual interface with auto-detection, status indicators
- Action configurator: visual interface with validation warnings
- Text builder editor: drag-and-drop segment arrangement, live preview
- Animation editor: step-by-step animation builder with preview playback
- Validation: editor-time checks for target/action compatibility, unified binding compatibility
- Debug overlay: visual representation of reactive connections and errors (from Logger)
- **FoldableContainer Support:**
  - `ReactiveFoldableContainer` extends/wraps FoldableContainer (Godot 4.5)
  - Supports collapsible UI sections (accordion-style interfaces)
  - Can be used in settings panels, inventory categories, collapsible menus
  - Integrates with reactive system (can bind to ReactiveBool for expanded/collapsed state)
- **Accessibility Support:**
  - `ReactiveAccessibility` utility class for accessibility features
  - `ReactiveControl` has `accessibility_description: String` property (screen reader support)
  - `ReactiveControl` has `accessibility_label: String` property
  - Integrates with Godot 4.5's screen reader support
  - All reactive components support accessibility by default

**Signal and Scene Cleanup:**
- **Editor Plugin Cleanup:** Editor plugins are part of editor, not runtime, so cleanup is handled by Godot
- **Runtime Debug Overlay:** If debug overlay creates connections, must clean up when disabled
- **Validation System:** No persistent connections needed, validation runs on-demand

**SOLID/DRY Architecture:**
- **Single Responsibility:**
  - Each inspector plugin: responsible only for editing one type of resource/property
  - Main plugin: responsible only for registering inspector plugins
  - ControlInspector: responsible only for reflection/auto-detection
  - Logger (Godot 4.5): responsible only for error reporting (replaces custom ErrorReporter)
  - ReactiveFoldableContainer: responsible only for collapsible container functionality
  - ReactiveAccessibility: responsible only for accessibility features
- **Open/Closed:**
  - Plugin system closed for modification, open for extension (new inspector plugins)
- **Liskov Substitution:** 
  - All inspector plugins can be used interchangeably in plugin system
- **Interface Segregation:** 
  - Inspector plugins provide minimal interface (can_handle, parse_property, etc.)
  - ControlInspector provides minimal interface (get_available_properties, get_available_signals, etc.)
- **Dependency Inversion:** 
  - Plugins depend on EditorInspectorPlugin abstraction
  - All systems depend on Logger abstraction (Godot 4.5), not custom error handling
- **DRY:** 
  - Common editor UI patterns in utility functions
  - Common reflection logic in ControlInspector (reused by all plugins)
  - Common error reporting via Logger (Godot 4.5, reused by all systems)
  - Common accessibility patterns in ReactiveAccessibility utility
  - Plugin-specific logic in each plugin

**Test Criteria:**
- Enable plugin, verify custom inspectors appear
- Use ReactiveValue picker to select values from dropdown
- **Test auto-detection:** Select Control node in binding editor, verify properties/signals auto-populate
- **Test caching:** Select same Control type multiple times, verify reflection results are cached (faster subsequent lookups)
- Configure unified bindings visually: select mode (ONE_WAY/TWO_WAY), Control node, property (auto-detected), signal (auto-detected if TWO_WAY), and ReactiveValue
- **Test visual feedback:** Create invalid binding, verify red error indicator appears
- Configure actions visually without scripting
- Build text segments visually, see live preview
- Build animations step-by-step, test preview playback in editor
- Verify validation catches incompatible target/action pairs
- Verify validation catches incompatible unified binding configurations (wrong property types, missing signals for TWO_WAY, etc.)
- **Test error reporting:** Create multiple errors, verify Logger shows all in error panel
- **Test debug overlay:** Enable debug overlay, verify reactive connections and errors are visualized (from Logger)
- **Test FoldableContainer:** Create ReactiveFoldableContainer, verify collapsible functionality, test binding to ReactiveBool for expanded state
- **Test accessibility:** Set accessibility_description and accessibility_label on ReactiveControl, verify screen reader support
- **Test plugin disable:** Disable plugin, verify no errors, editor functions normally

**Deliverable:** Complete editor tooling with auto-detection, visual feedback, Logger-based error reporting (Godot 4.5), debug overlay, FoldableContainer support, and accessibility features that enables visual configuration only (no scripting required) for designers.

---

## Testing Strategy

Each phase includes:
1. **Unit Tests:** Test individual resources/components in isolation
2. **Integration Tests:** Test components working together
3. **Editor Tests:** Verify editor functionality and serialization
4. **Cleanup Tests:** Verify no signal leaks or resource leaks after component removal

**Unified Integration Test Scene:**
- `res://ui_system/tests/test_unified_integration.tscn` - Comprehensive test scene built incrementally
- **Created in Phase 1** - Initial scene setup with basic structure (containers, section labels)
- **Updated each phase** - New features added to the unified scene as they're implemented
- Serves dual purpose:
  - **Unit Testing:** Test new features in isolation within the unified scene
  - **Integration Testing:** Verify new features work with existing features
- Final scene includes examples of:
  - All reactive value types (String, Int, Float, Bool, Array, Object)
  - All reactive components (Label, Button, LineEdit, TextLabel, List, Grid, Cell)
  - Binding system (one-way and two-way with various converters)
  - Action system (all action types including collection actions)
  - Text builder with all segment types (literal, source, conditional, translation) and formatters (number, rich text)
  - Animation system (forward/backward, loops, chaining, events)
  - Navigation system (keyboard and controller with multiple groups)
  - Real-world scenarios:
    - Inventory display (ReactiveList with ReactiveCell showing item name, quantity, price, icons with selection sharing and detail panel)
    - Storefront (ReactiveGrid with buy/sell actions)
    - Character stats (ReactiveTextLabel with formatted values and conditions)
    - Settings panel (two-way bindings for user input)
- Single source of truth for testing and demonstrations
- No individual test scenes needed - all testing happens in unified scene

## Dependencies Between Phases

```
Phase 1 (Reactive Values)
    ↓
Phase 1.5 (Collections) ────┐
    ↓                      │
Phase 2 (Reactive Components) ────┐
    ↓                              │
Phase 2.5 (Collection Display) ────┤
    ↓                              │
Phase 2.6 (Collection Enhancement) ─┤
    ↓                              │
Phase 3 (Target/Action) ───────────┤
    ↓                              │
Phase 3.5 (Collection Actions) ────┤
    ↓                              │
Phase 4 (Text Builder) ─────────────┤
    ↓                              │
Phase 5 (Animations) ──────────────┤
    ↓                              │
Phase 6 (Navigation) ──────────────┤
    ↓                              │
Phase 7 (Editor Plugins) ←─────────┘
```

## Success Metrics

- **Phase 1:** Reactive values with validation, default values, old value tracking, update batching, and resource versioning emit signals, serialize properly, migrate between versions, and can be shared between components
- **Phase 1.5:** ReactiveArray and ReactiveObject support collections and complex data structures reactively
- **Phase 2:** Reactive components support unified binding (one-way or two-way via mode selection) with value converters, initial sync, validation, status tracking, typed signal connections, update reactively without scripting, with zero signal leaks. ReactiveControl uses ReactiveBindingManager (RefCounted composition) for separation of concerns. Accessibility support (screen reader) integrated.
- **Phase 2.5:** ReactiveList, ReactiveGrid, and ReactiveCell display collections reactively with direct access and direct configuration
- **Phase 2.6:** ReactiveReference enables selection sharing, StringToTextureConverter enables image binding, and visual feedback (selection/hover) enhances collection components
- **Phase 3:** Conditionally-executed actions with typed parameters, clear validation separation, error recovery, scene changes, and action groups (with parallel/sequential execution modes and full composability/nesting) can be configured entirely in editor, with proper cleanup via ReactiveLifecycleManager
- **Phase 3.5:** Collection manipulation actions (add, remove, move, swap, clear) work with ReactiveArray without scripting
- **Phase 4:** Complex dynamic text with formatters (number, rich text), full conditional operators, i18n translation support, and typed context Resources can be built visually, with reactive updates and cleanup via ReactiveLifecycleManager
- **Phase 5:** Animations with relative/absolute values, delays, loops, events with typed contexts, and chaining play forward/backward without duplication. ReactiveControl uses ReactiveAnimationManager (RefCounted composition) for animation orchestration, with proper Tween cleanup via ReactiveLifecycleManager
- **Phase 6:** Full keyboard/controller navigation with groups, clear tab order management, and dynamic management works. ReactiveNavigation uses ReactiveInputHandler and ReactiveFocusManager (RefCounted composition) for separation of concerns, with proper focus management and cleanup
- **Phase 7:** Designers can build complete UI through visual configuration only (no scripting required) with cached auto-detection, visual feedback, Logger-based error reporting (Godot 4.5), debug overlay, FoldableContainer support, and accessibility features. All systems use ReactiveLifecycleManager and ReactiveValidationUtils for DRY compliance

## Cleanup Verification Checklist

For each phase, verify:
- [ ] All signal connections are tracked
- [ ] All signals are disconnected in `_exit_tree()`
- [ ] All Tweens are killed on cleanup
- [ ] No orphaned references remain after component removal
- [ ] Debugger shows zero signal connections after cleanup
- [ ] Memory profiler shows no leaks after repeated create/destroy cycles


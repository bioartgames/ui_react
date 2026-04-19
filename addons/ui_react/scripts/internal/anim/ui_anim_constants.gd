## Shared numeric defaults for [UiAnimUtils] and animation family modules.
## Single source of truth to avoid drift between facade and implementations.
class_name UiAnimConstants
extends RefCounted

const DEFAULT_OFFSET := 8.0
const DEFAULT_SPEED := 0.3
const SHRINK_ANIMATION_SPEED := 0.15
const ALPHA_MIN := 0.0
const ALPHA_MAX := 1.0
const SCALE_MIN := Vector2.ZERO
const SCALE_MAX := Vector2.ONE
const BREATHING_SCALE_MULTIPLIER := 1.05
const WOBBLE_ROTATION_DEGREES := 3.0
const DEFAULT_FLOAT_DISTANCE_PX := 10.0
const DEFAULT_PULSE_SPEED := 0.5
const DEFAULT_PULSE_AMOUNT := 1.1
const DEFAULT_PULSE_COUNT := 2
const DEFAULT_SHAKE_SPEED := 0.5
const DEFAULT_SHAKE_INTENSITY := 10.0
const DEFAULT_SHAKE_COUNT := 5
const DEFAULT_BREATHING_DURATION := 2.0
const DEFAULT_WOBBLE_DURATION := 1.5
const DEFAULT_FLOAT_DURATION := 2.0
const DEFAULT_GLOW_PULSE_DURATION := 1.5
const DEFAULT_GLOW_MIN_ALPHA := 0.7
const DEFAULT_COLOR_FLASH_DURATION := 0.2
const DEFAULT_COLOR_FLASH_INTENSITY := 1.5
const DEFAULT_ANIMATE_RESET_DURATION := 0.3
const DEFAULT_STAGGER_DELAY := 0.1
const DEFAULT_ROTATE_IN_START_DEG := -360.0
const DEFAULT_ROTATE_OUT_END_DEG := 360.0
const DEFAULT_POP_OVERSHOOT := 1.2

## Sentinel passed to scale/transform helpers: pivot is resolved to the control’s visual center.
const PIVOT_USE_CONTROL_DEFAULT := Vector2(-1, -1)

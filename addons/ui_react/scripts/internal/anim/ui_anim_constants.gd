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

## Sentinel passed to scale/transform helpers: pivot is resolved to the control’s visual center.
const PIVOT_USE_CONTROL_DEFAULT := Vector2(-1, -1)

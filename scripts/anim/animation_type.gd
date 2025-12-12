## Type-safe animation type enums for UI components.
##
## AnimationType enums provide type-safe animation selection instead of string-based selection,
## and they appear as dropdown menus in the Inspector. Use these enums when selecting show and hide
## animations for ReactivePanel, selecting list item animations for ReactiveList, or any component
## that needs animation type selection. Unlike strings, AnimationType enums are type-safe preventing
## typos and invalid values, provide Inspector dropdown menus for better UX than typing strings,
## include IDE autocomplete support, and enable compile-time checking. Available animation types
## include ShowAnimation for panels and controls appearing (pop, slide_from_left, fade_in, etc.),
## HideAnimation for panels and controls disappearing (shrink, slide_to_left, fade_out, etc.), and
## ListShowAnimation which is a simplified set for list items (slide_from_left, fade_in).
class_name AnimationType
extends RefCounted

## Show animation types for panels and controls.
enum ShowAnimation {
	NONE,              ## No animation
	POP,               ## Pop/expand animation (scale from 0 to 1)
	SLIDE_FROM_LEFT,   ## Slide in from the left
	SLIDE_FROM_RIGHT,  ## Slide in from the right
	SLIDE_FROM_TOP,    ## Slide in from the top
	FADE_IN            ## Fade in animation
}

## Hide animation types for panels and controls.
enum HideAnimation {
	NONE,              ## No animation
	SHRINK,            ## Shrink animation (scale from 1 to 0)
	SLIDE_TO_LEFT,     ## Slide out to the left
	SLIDE_TO_RIGHT,    ## Slide out to the right
	SLIDE_TO_TOP,      ## Slide out to the top
	FADE_OUT           ## Fade out animation
}

## List item show animation types (simpler set).
enum ListShowAnimation {
	NONE,              ## No animation
	SLIDE_FROM_LEFT,   ## Slide in from the left
	FADE_IN            ## Fade in animation
}

## Converts a ShowAnimation enum to the string format expected by UIAnimationUtils.
static func show_animation_to_string(animation: ShowAnimation) -> String:
	match animation:
		ShowAnimation.NONE:
			return ""
		ShowAnimation.POP:
			return "pop"
		ShowAnimation.SLIDE_FROM_LEFT:
			return "slide_from_left"
		ShowAnimation.SLIDE_FROM_RIGHT:
			return "slide_from_right"
		ShowAnimation.SLIDE_FROM_TOP:
			return "slide_from_top"
		ShowAnimation.FADE_IN:
			return "fade_in"
		_:
			return ""

## Converts a HideAnimation enum to the string format expected by UIAnimationUtils.
static func hide_animation_to_string(animation: HideAnimation) -> String:
	match animation:
		HideAnimation.NONE:
			return ""
		HideAnimation.SHRINK:
			return "shrink"
		HideAnimation.SLIDE_TO_LEFT:
			return "slide_to_left"
		HideAnimation.SLIDE_TO_RIGHT:
			return "slide_to_right"
		HideAnimation.SLIDE_TO_TOP:
			return "slide_to_top"
		HideAnimation.FADE_OUT:
			return "fade_out"
		_:
			return ""

## Converts a ListShowAnimation enum to the string format expected by ReactiveList.
static func list_show_animation_to_string(animation: ListShowAnimation) -> String:
	match animation:
		ListShowAnimation.NONE:
			return ""
		ListShowAnimation.SLIDE_FROM_LEFT:
			return "slide_from_left"
		ListShowAnimation.FADE_IN:
			return "fade_in"
		_:
			return ""

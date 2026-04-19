## Builder for chaining multiple animations together sequentially.
##
## UiAnimSequence enables playing multiple animations one after another with proper sequencing,
## making it useful for complex UI transitions where animations need to happen in a specific order.
## This makes it ideal for complex UI transitions with multiple steps like panel opening then content
## fading in, animations that depend on previous animations completing, creating cinematic UI sequences,
## and coordinating animations across multiple UI elements. Unlike individual animations, UiAnimSequence
## ensures animations play in the correct order, simplifies sequencing logic without manual await chains,
## provides a fluent API for building animation sequences, and handles animation timing automatically.
## Each animation is added as a Callable that returns a Signal. The animation function is called when
## the sequence reaches it, ensuring the Tween exists when we await its finished signal. This lazy
## evaluation prevents timing issues.
##
## Example:
## [codeblock]
## # Create a sequence: expand panel, wait, then fade in label
## var sequence = UiAnimSequence.create()
## sequence.add(func(): return UiAnimUtils.animate_expand(self, panel))
## sequence.add(func(): return UiAnimUtils.delay(self, 0.5))
## sequence.add(func(): return UiAnimUtils.animate_fade_in(self, label))
## await sequence.play()
## [/codeblock]
class_name UiAnimSequence
extends RefCounted

var _animations: Array[Callable] = []

func _init() -> void:
	## Sequence starts empty; see [method add] / [method play].
	pass

## Adds an animation to the sequence.
##
## The callable should return a Signal (typically from UiAnimUtils functions). The animation
## is called when the sequence reaches it, not when added, ensuring the Tween exists when we await
## its finished signal. Returns self, allowing you to chain multiple `add()` calls together.
##
## [param animation_callable]: A Callable that returns a Signal to await.
## [return]: Returns self for method chaining.
func add(animation_callable: Callable) -> UiAnimSequence:
	_animations.append(animation_callable)
	return self

## Plays all animations in the sequence sequentially.
##
## Iterates through all added animations, calls each one when reached, and awaits its returned
## Signal before proceeding to the next animation, ensuring proper sequencing. Call this after
## adding all animations to the sequence. Use `await` to wait for the entire sequence to complete.
func play() -> void:
	for animation_callable in _animations:
		if animation_callable.is_valid():
			var result = animation_callable.call()
			if result is Signal:
				await result

## Creates a new UiAnimSequence instance.
## [return]: A new UiAnimSequence ready to add animations to.
static func create() -> UiAnimSequence:
	return UiAnimSequence.new()

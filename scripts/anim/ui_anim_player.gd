extends Node
class_name UIAnimPlayer

@export var clip: UIAnimClip
@export var autoplay: bool = false
@export var play_on_ready: bool = false
@export var play_on_hover: bool = false
@export var play_on_click: bool = false
@export var respect_disabled: bool = true

var _tween: Tween
var _is_hovering: bool = false

func _ready() -> void:
	if play_on_hover and get_parent() and get_parent() is Control:
		var c: Control = get_parent()
		c.mouse_entered.connect(_on_mouse_entered)
		c.mouse_exited.connect(_on_mouse_exited)
	if play_on_click and get_parent() and get_parent() is Control:
		var c2: Control = get_parent()
		c2.gui_input.connect(_on_gui_input)
	if autoplay or play_on_ready:
		play()

func play(reverse: bool = false) -> void:
	if not clip or not clip.root:
		return
	if _tween:
		_tween.kill()
	var target: Node = get_parent()
	if not target:
		return
	_tween = create_tween()
	_tween.set_parallel()
	_build_group(clip.root, target, reverse, _tween)
	if clip.loop_mode == "repeat":
		_tween.set_loops(max(clip.loop_count, 1))
	elif clip.loop_mode == "infinite":
		_tween.set_loops(-1)
	elif clip.loop_mode == "ping_pong":
		_tween.set_loops(max(clip.loop_count, 1))
		_tween.set_transpose(true)
	if reverse:
		_tween.play_backwards()

func stop() -> void:
	if _tween:
		_tween.kill()
		_tween = null

func _build_group(group: UIAnimGroup, target: Node, reverse: bool, tween: Tween) -> void:
	if group.mode == "parallel":
		for child in group.children:
			_build_child(child, target, reverse, tween)
	else:
		var seq := tween
		for child in group.children:
			_build_child(child, target, reverse, seq)
			if seq:
				seq = seq.chain()

func _build_child(child: Resource, target: Node, reverse: bool, tween: Tween) -> void:
	if child is UIAnimAction:
		_build_action(child, target, reverse, tween)
	elif child is UIAnimGroup:
		_build_group(child, target, reverse, tween)

func _build_action(action: UIAnimAction, target: Node, reverse: bool, tween: Tween) -> void:
	if not action.property_path or not tween:
		return
	if not target.has_method("get") or not target.has_method("set"):
		return
	var from_val = action.from_value
	var to_val = action.to_value
	if action.is_relative:
		var current_val = target.get(action.property_path)
		from_val = current_val
		to_val = current_val + action.to_value
	if reverse:
		var tmp = from_val
		from_val = to_val
		to_val = tmp
	if action.delay > 0.0:
		tween.tween_interval(action.delay)
	tween.tween_property(target, action.property_path, to_val, action.duration).from(from_val).set_trans(Tween.TRANS_SINE).set_ease(_map_ease(action.easing))

func _map_ease(ease_name: String) -> int:
	match ease_name:
		"linear":
			return Tween.EASE_IN_OUT
		"quad_in":
			return Tween.EASE_IN
		"quad_out":
			return Tween.EASE_OUT
		"quad_in_out":
			return Tween.EASE_IN_OUT
		"cubic_in":
			return Tween.EASE_IN
		"cubic_out":
			return Tween.EASE_OUT
		"cubic_in_out":
			return Tween.EASE_IN_OUT
		_:
			return Tween.EASE_IN_OUT

func _on_mouse_entered() -> void:
	_is_hovering = true
	if play_on_hover:
		if respect_disabled and _is_disabled():
			return
		play()

func _on_mouse_exited() -> void:
	_is_hovering = false

func _on_gui_input(event: InputEvent) -> void:
	if not play_on_click:
		return
	if respect_disabled and _is_disabled():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play()

func _is_disabled() -> bool:
	var p = get_parent()
	if p and p is Control:
		if "disabled" in p:
			return p.disabled
		return false
	return false

# TouchControls — joystick izq mover, zona der apuntar/disparar, botones dash/rewind/item.
# En escritorio coexiste con WASD/ratón/espacio/Q/E (doc 09.8).
extends CanvasLayer

var _move_touch := -1
var _aim_touch := -1
var _move_origin := Vector2.ZERO
var _aim_origin := Vector2.ZERO

@onready var left_base: Control = $Left/Base
@onready var left_knob: Control = $Left/Knob
@onready var right_base: Control = $Right/Base
@onready var right_knob: Control = $Right/Knob

func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios")
	$Right/Dash.pressed.connect(func(): Input.action_press("dash"))
	$Right/Dash.button_up.connect(func(): Input.action_release("dash"))
	$Right/Rewind.pressed.connect(func(): Input.action_press("rewind"))
	$Right/Rewind.button_up.connect(func(): Input.action_release("rewind"))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.4 and _move_touch < 0:
				_move_touch = event.index
				_move_origin = event.position
			elif _aim_touch < 0:
				_aim_touch = event.index
				_aim_origin = event.position
				Input.action_press("fire")
		else:
			if event.index == _move_touch:
				_move_touch = -1
				Input.action_release("move_left")
				Input.action_release("move_right")
				Input.action_release("move_up")
				Input.action_release("move_down")
			if event.index == _aim_touch:
				_aim_touch = -1
				Input.action_release("fire")
	elif event is InputEventScreenDrag:
		if event.index == _move_touch:
			_apply_stick(event.position - _move_origin)
		elif event.index == _aim_touch:
			_apply_aim(event.position - _aim_origin)

func _apply_stick(d: Vector2) -> void:
	if d.length() < 12.0:
		return
	var n := d.normalized()
	_set_axis("move_left", "move_right", -n.x)
	_set_axis("move_up", "move_down", -n.y)

func _set_axis(neg: String, pos: String, v: float) -> void:
	if v > 0.3:
		Input.action_press(pos)
		Input.action_release(neg)
	elif v < -0.3:
		Input.action_press(neg)
		Input.action_release(pos)
	else:
		Input.action_release(neg)
		Input.action_release(pos)

func _apply_aim(d: Vector2) -> void:
	if d.length() < 16.0:
		return
	# El aim real lo resuelve Lela por joystick; aquí basta mantener fire.
	pass

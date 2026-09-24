# TouchControls — twin-stick: izq mover, der apuntar+disparar, botones dash/rewind.
# Expone move_vec/aim_vec al jugador (grupo "touch"). En escritorio queda oculto.
extends CanvasLayer

var move_vec := Vector2.ZERO
var aim_vec := Vector2.ZERO
var aim_active := false

var _move_touch := -1
var _aim_touch := -1
var _move_origin := Vector2.ZERO
var _aim_origin := Vector2.ZERO

const DEADZONE := 12.0
const MAX_DRAG := 90.0

@onready var left_knob: Control = $Left/Knob
@onready var right_knob: Control = $Right/Knob
@onready var dash_btn: Button = $Right/Dash
@onready var rewind_btn: Button = $Right/Rewind
var _left_home := Vector2.ZERO
var _right_home := Vector2.ZERO
var _ui_touches := {} # touch index -> action ("dash"/"rewind")

func _ready() -> void:
	add_to_group("touch")
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios")
	_left_home = left_knob.position
	_right_home = right_knob.position

func _ui_action_at(pos: Vector2) -> String:
	if dash_btn.get_global_rect().grow(12.0).has_point(pos):
		return "dash"
	if rewind_btn.get_global_rect().grow(12.0).has_point(pos):
		return "rewind"
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var vp := get_viewport().get_visible_rect().size
		if event.pressed:
			var ui := _ui_action_at(event.position)
			if ui != "":
				_ui_touches[event.index] = ui
				Input.action_press(ui)
			elif event.position.x < vp.x * 0.4 and _move_touch < 0:
				_move_touch = event.index
				_move_origin = event.position
				move_vec = Vector2.ZERO
			elif event.position.x >= vp.x * 0.4 and _aim_touch < 0:
				# Tocar no dispara: solo el arrastre más allá de la zona muerta.
				_aim_touch = event.index
				_aim_origin = event.position
				aim_active = true
				aim_vec = Vector2.ZERO
		else:
			if event.index in _ui_touches:
				Input.action_release(_ui_touches[event.index])
				_ui_touches.erase(event.index)
			if event.index == _move_touch:
				_move_touch = -1
				move_vec = Vector2.ZERO
				left_knob.position = _left_home
			if event.index == _aim_touch:
				_aim_touch = -1
				aim_active = false
				aim_vec = Vector2.ZERO
				right_knob.position = _right_home
	elif event is InputEventScreenDrag:
		if event.index == _move_touch:
			var d = event.position - _move_origin
			if d.length() > DEADZONE:
				move_vec = d.limit_length(MAX_DRAG) / MAX_DRAG
			else:
				move_vec = Vector2.ZERO
			left_knob.position = _left_home + d.limit_length(MAX_DRAG) * 0.4
		elif event.index == _aim_touch:
			var d2 = event.position - _aim_origin
			if d2.length() > DEADZONE:
				aim_vec = d2.normalized()
			right_knob.position = _right_home + d2.limit_length(MAX_DRAG) * 0.4

extends Node3D

class_name FirstPersonCamera

@export var pivot_y : Node3D
@export var pivot_x : Node3D
@export var camera : Camera3D

@export_group("Camera Settings")
@export var sensitivity : Vector2 = Vector2(0.25, 10.0)
@export_range(0.0, 89.0) var max_down_angle : float = 89.0
@export_range(0.0, 89.0) var max_up_angle : float = 89.0

var mouse_input : Vector2
var offset : Vector3

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode =Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		mouse_input = event.relative
	pass

func _ready() -> void:
	if !is_multiplayer_authority():
		queue_free()
		return

	offset = position

	Input.mouse_mode =Input.MOUSE_MODE_CAPTURED
	camera.make_current()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pass

func _process(delta: float) -> void:
	if !is_multiplayer_authority():
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if mouse_input.x != 0.0:
		pivot_y.rotate_y(-mouse_input.x * delta * sensitivity.x)

	if mouse_input.y != 0.0:
		var current_angle : float = rad_to_deg(pivot_x.rotation.x)
		var input_angle : float = -mouse_input.y * delta * sensitivity.y
		pivot_x.rotation.x = clampf(deg_to_rad(current_angle + input_angle), deg_to_rad(-max_down_angle), deg_to_rad(max_up_angle))

	mouse_input = Vector2.ZERO

	if is_instance_valid(get_parent() as Node3D):
		var parent : Node3D = get_parent() as Node3D
		global_position = parent.get_global_transform_interpolated().origin + parent.global_basis * offset
	pass

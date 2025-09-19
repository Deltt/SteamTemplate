extends Node3D

class_name StrategyCamera

@export var pivot_y : Node3D
@export var pivot_x : Node3D
@export var camera : Camera3D

@export_group("Camera Settings")
@export var pan_speed : float = 1.0
@export_range(0.0, 89.0) var camera_angle : float = 45.0
@export var initial_distance : float = 30.0
@export var min_distance : float = 10.0
@export var max_distance : float = 100.0
@export var zoom_speed : float = 3.0
@export var lerp_value : float = 18.0

# Internals
var current_distance : float
var mouse_input : Vector2
var lerped_movement : Vector3

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion:
		mouse_input = event.relative

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_distance = minf(current_distance + zoom_speed, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_distance = maxf(current_distance - zoom_speed, min_distance)
	pass

func _ready() -> void:
	if !is_multiplayer_authority():
		queue_free()
		return

	current_distance = initial_distance

	pivot_y = Node3D.new()
	add_child(pivot_y, true)

	pivot_x = Node3D.new()
	pivot_x.rotation_degrees.x = -camera_angle
	pivot_y.add_child(pivot_x, true)

	camera = Camera3D.new()
	camera.position.z = initial_distance
	pivot_x.add_child(camera, true)
	camera.make_current()
	pass


func _process(delta: float) -> void:
	if !is_multiplayer_authority():
		return

	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		pivot_y.rotate_y(-mouse_input.x * delta)

	mouse_input = Vector2.ZERO

	camera.position.z = lerpf(camera.position.z, current_distance, min(lerp_value * delta, 1))

	var key_input : Vector3
	key_input.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	key_input.z = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	key_input = key_input.normalized()

	var key_input_relative : Vector3 = key_input.rotated(Vector3.UP, pivot_y.rotation.y)
	lerped_movement = lerped_movement.lerp(key_input_relative, min(lerp_value * delta, 1))
	global_position += lerped_movement * pan_speed * (current_distance / max_distance)
	pass

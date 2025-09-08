extends Node3D

class_name ThirdPersonCamera

# Child nodes
var pivot_y : Node3D
var pivot_x : SpringArm3D
var camera : Camera3D

# Settings
@export_group("Camera Settings")
@export var max_distance : float = 10.0
@export var sensitivity : Vector2 = Vector2(0.5, 10.0)
@export_range(-89.0, 89.0) var initial_angle : float = 45.0
@export_range(0.0, 89.0) var max_down_angle : float = 89.0
@export_range(0.0, 89.0) var max_up_angle : float = 20.0
@export var fixed_axis : bool = false
@export var offset : Vector3 = Vector3(0, 1.5, 0)

# Internals
var mouse_input : Vector2

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
		return
		
	Input.mouse_mode =Input.MOUSE_MODE_CAPTURED
	
	pivot_y = Node3D.new()
	add_child(pivot_y, true)
	
	pivot_x = SpringArm3D.new()
	if is_instance_valid(get_parent()) and get_parent() is CharacterBody3D:
		pivot_x.add_excluded_object(get_parent().get_rid())
	pivot_x.spring_length = max_distance
	pivot_x.shape = SphereShape3D.new()
	(pivot_x.shape as SphereShape3D).radius = 0.2
	pivot_x.rotation_degrees.x = -initial_angle
	pivot_y.add_child(pivot_x, true)
	
	camera = Camera3D.new()
	pivot_x.add_child(camera, true)
	camera.make_current()
	camera.v_offset = 0.1
	
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	
	if fixed_axis:
		global_rotation_degrees = Vector3.ZERO
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
		
		if fixed_axis:
			global_position = parent.get_global_transform_interpolated().origin + offset
		else:
			global_position = parent.get_global_transform_interpolated().origin + parent.get_global_transform_interpolated().basis * offset
	pass

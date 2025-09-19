extends CharacterBody3D

class_name CharacterBodyPlayer

@export var network_position : Vector3
@export var synchronizer : MultiplayerSynchronizer

const DEFAULT_SPEED = 5.0
const DEFAULT_JUMP_VELOCITY = 4.5

func _ready() -> void:
	network_position = position

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		if position.distance_to(network_position) <= 8.0:
			position = position.lerp(network_position, min(12 * delta, 1.0))
		else:
			position = network_position
		return

	if is_on_floor():
		velocity.y = 0
	velocity += get_gravity() * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = DEFAULT_JUMP_VELOCITY

	if Input.is_key_pressed(KEY_V):
		velocity.y = DEFAULT_JUMP_VELOCITY

	if Input.is_key_pressed(KEY_C):
		velocity.y = 0.0

	if get_viewport().get_camera_3d() == null:
		print("No active camera found!")
		return

	var key_input : Vector3
	key_input.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	key_input.z = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	key_input = get_viewport().get_camera_3d().global_basis * key_input
	key_input.y = 0
	key_input = key_input.normalized()
	var movement : Vector3 = key_input * DEFAULT_SPEED
	velocity.x = movement.x
	velocity.z = movement.z
	move_and_slide()

	network_position = position
	pass

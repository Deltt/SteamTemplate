extends RigidBody3D

class_name PhysicsCharacter

enum CAMERA_TYPE {CUSTOM = -1, ThirdPerson = 0, FirstPerson = 1}

@export_category("Camera Options")
@export var camera_type : CAMERA_TYPE = CAMERA_TYPE.ThirdPerson

@export var network_position : Vector3

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var collision_cast : ShapeCast3D

func _ready() -> void:
	collision_cast = get_node("ShapeCast3D")
	
	if multiplayer.has_multiplayer_peer():
		if multiplayer.multiplayer_peer.get_class() != "OfflineMultiplayerPeer":
			var synchronizer : MultiplayerSynchronizer = MultiplayerSynchronizer.new()
			synchronizer.root_path = get_path()
			synchronizer.replication_interval = 0.08
			synchronizer.set_multiplayer_authority(get_multiplayer_authority())
			add_child(synchronizer, true)
			var config : SceneReplicationConfig = SceneReplicationConfig.new()
			config.add_property((^"network_position").get_as_property_path())
			config.property_set_replication_mode((^"network_position").get_as_property_path(), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
			synchronizer.replication_config = config
	
	if !is_multiplayer_authority():
		return
	
	if camera_type == CAMERA_TYPE.ThirdPerson:
		var camera : ThirdPersonCamera = ThirdPersonCamera.new()
		camera.set_multiplayer_authority(get_multiplayer_authority())
		camera.offset = Vector3(0, 0.5, 0)
		add_child(camera, true)
	elif camera_type == CAMERA_TYPE.FirstPerson:
		var camera : FirstPersonCamera = FirstPersonCamera.new()
		camera.set_multiplayer_authority(get_multiplayer_authority())
		camera.position.y = 0.5
		add_child(camera, true)
		
	network_position = position
	pass

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		if position.distance_to(network_position) <= 8.0:
			position = position.lerp(network_position, min(12 * delta, 1.0))
		else:
			position = network_position
		return

	if Input.is_key_pressed(KEY_SPACE) and collision_cast.is_colliding():
		linear_velocity.y = JUMP_VELOCITY
		
	if Input.is_key_pressed(KEY_V):
		linear_velocity.y = JUMP_VELOCITY
		
	if Input.is_key_pressed(KEY_C):
		linear_velocity.y = 0.0
		
	var key_input : Vector3
	key_input.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	key_input.z = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	key_input = get_viewport().get_camera_3d().global_basis * key_input
	key_input.y = 0
	key_input = key_input.normalized()
	var movement : Vector3 = key_input * SPEED
	linear_velocity.x = movement.x
	linear_velocity.z = movement.z
	
	apply_torque(-rotation * 50)
	
	network_position = position
	pass

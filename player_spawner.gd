extends Node3D

@export var player_scene : PackedScene

func _ready() -> void:
	var spawn_player_list : PackedInt32Array = PackedInt32Array()
	spawn_player_list.append_array(multiplayer.get_peers())
	spawn_player_list.append(multiplayer.get_unique_id())
	spawn_player_list.sort()
	
	var offset : int = 0
	for peer in spawn_player_list:
		var player_instance = player_scene.instantiate()
		player_instance.name = str(peer)
		player_instance.position = Vector3(offset, 1, 0)
		player_instance.set("network_position", Vector3(offset, 1, 0))
		player_instance.set_multiplayer_authority(peer)
		add_child(player_instance, true)
		offset += 2.5
		

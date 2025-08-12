extends Control

@export var scene_to_load : PackedScene

@export var host_steam_button : Button
@export var join_steam_button : Button
@export var join_steam_id : LineEdit

@export var host_lan_button : Button
@export var join_lan_button : Button
@export var join_lan_ip : LineEdit

@export var lobby_list_container : VBoxContainer
@export var player_list_container : VBoxContainer

@export var connection_info : Label
@export var lobby_id_copy : LineEdit

@export var refresh_button : Button
@export var start_button : Button

func _ready() -> void:
	NetworkManager.join_success.connect(onLobbyJoined)
	NetworkManager.lobby_list_updated.connect(onLobbyListReceived)
	NetworkManager.player_list_updated.connect(onPlayerListReceived)
	NetworkManager.request_steam_lobbies(true)
	
	host_lan_button.pressed.connect(NetworkManager.host_lan)
	join_lan_button.pressed.connect(NetworkManager.join_lan.bind(join_lan_ip.text))
	
	host_steam_button.pressed.connect(NetworkManager.host_steam)
	join_steam_button.pressed.connect(NetworkManager.join_steam.bind(join_steam_id.text.to_int()))
	
	refresh_button.pressed.connect(NetworkManager.request_steam_lobbies.bind(true))
	start_button.pressed.connect(NetworkManager.load_scene.bind(scene_to_load.resource_path))
	pass
	
func _physics_process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer():
		if multiplayer.multiplayer_peer.get_class() != "OfflineMultiplayerPeer":
			var status : int =  multiplayer.multiplayer_peer.get_connection_status()
			var connection_status : String = "-"
			var peer_type : String = ""
			
			if status == 1:
				connection_status = "Connecting..."
			elif status == 2:
				connection_status = "Connected"
			
			if multiplayer.multiplayer_peer.get_class() == "ENetMultiplayerPeer":
				peer_type = "LAN"
			elif multiplayer.multiplayer_peer.get_class() == "SteamMultiplayerPeer":
				peer_type = "Steam"
				
			connection_info.text = connection_status + " " + "(" + peer_type + ")"
			return
	
	connection_info.text = "-"
	lobby_id_copy.text = ""
	pass
	
func onLobbyJoined(id):
	lobby_id_copy.text = str(id)
	pass
	
func onLobbyListReceived(_lobby_list):
	for child in lobby_list_container.get_children():
		lobby_list_container.remove_child(child)
	
	for lobby in _lobby_list:
		var button : Button = Button.new()
		button.text = lobby.get("name") + " " + str(lobby.get("member_count")) + " / " + str(lobby.get("max_member_count"))
		lobby_list_container.add_child(button)
		if lobby.get("member_count") < lobby.get("max_member_count"):
			button.pressed.connect(Callable(self, "onLobbyButtonPressed").bind(lobby))
		else:
			button.disabled = true
	pass
	
func onPlayerListReceived(_player_list):
	for child in player_list_container.get_children():
		player_list_container.remove_child(child)
	
	for player in _player_list.values():
		var label : Label = Label.new()
		label.text = player
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_list_container.add_child(label)
	pass
	
func onLobbyButtonPressed(_lobby):
	NetworkManager.join_steam(_lobby.get("id"))
	pass


func _process(_delta: float) -> void:
	pass

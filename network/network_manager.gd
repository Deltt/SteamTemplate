extends Node

var peer : MultiplayerPeer
var lobby_data : Dictionary
var player_list : Dictionary

var steam_app_id : int = 480
var steam_lobby_filter : String = "ZYX_DELTT"

var timeout_timer : float = 0.0

signal join_success(id)
signal player_list_updated(list)
signal lobby_list_updated(list)

func _ready() -> void:
	multiplayer.connected_to_server.connect(onConnectedToServer)
	multiplayer.connection_failed.connect(onConnectionFailed)
	multiplayer.server_disconnected.connect(onServerDisconnected)

	player_list_updated.connect(onPlayerListUpdated)
	Steam.lobby_match_list.connect(onLobbyMatchListReceived)
	pass

func _physics_process(_delta: float) -> void:
	Steam.run_callbacks()

	if timeout_timer > 0.0:
		timeout_timer += _delta
		if timeout_timer >= 6.0:
			timeout_timer = 0.0
			clear_lobby()
	pass

func set_peer(_peer : MultiplayerPeer):
	if multiplayer.has_multiplayer_peer():
		if multiplayer.multiplayer_peer.get_class() != "OfflineMultiplayerPeer":
			if multiplayer.multiplayer_peer.get_connection_status() != multiplayer.multiplayer_peer.CONNECTION_DISCONNECTED:
				multiplayer.multiplayer_peer.close()

	peer = _peer
	peer.peer_connected.connect(onPeerConnected)
	peer.peer_disconnected.connect(onPeerDisconnected)
	pass

func host_lan(_max_players : int = 2):
	clear_lobby()
	var lan_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	set_peer(lan_peer)
	var error : Error = lan_peer.create_server(42069, _max_players)
	if error == 0:
		multiplayer.multiplayer_peer = peer
		var ip : String = get_local_ip()
		lobby_data.set("id", ip)
		player_list.set(multiplayer.get_unique_id(), get_computer_name() + " (Host)")
		player_list_updated.emit(player_list)
		join_success.emit(ip)
		print("Hosting LAN lobby.")
	else:
		printerr("Hosting LAN lobby failed: " + error_string(error))
	pass

func join_lan(_lobby_id : String = "127.0.0.1", _max_players : int = 2):
	clear_lobby()

	if _lobby_id == "":
		_lobby_id = "127.0.0.1"

	var lan_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	set_peer(lan_peer)
	var error : Error = lan_peer.create_client(_lobby_id, 42069)
	if error == 0:
		multiplayer.multiplayer_peer = peer
		lobby_data.set("id", _lobby_id)
		join_success.emit(_lobby_id)
	else:
		printerr("Joining LAN lobby failed: " + error_string(error))

	timeout_timer = 0.001
	pass

func get_local_ip() -> String:
	var ip : String = "127.0.0.1"

	for address in IP.get_local_addresses():
		if address.begins_with("192"):
			ip = address
	return ip

func get_computer_name() -> String:
	if OS.has_environment("USERNAME"):
		return OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):
		return OS.get_environment("USER")
	else:
		return "Unknown"

func host_steam(_max_players : int = 2):
	clear_lobby()
	var steam_rsp : Dictionary = Steam.steamInitEx(steam_app_id, false)
	if steam_rsp.get("status") != 0:
		printerr(steam_rsp.get("verbal"))
		return

	if !Steam.lobby_created.is_connected(onSteamLobbyCreate):
		Steam.lobby_created.connect(onSteamLobbyCreate)

	if !Steam.lobby_joined.is_connected(onSteamLobbyJoin):
		Steam.lobby_joined.connect(onSteamLobbyJoin)

	if !Steam.lobby_chat_update.is_connected(onSteamLobbyChatUpdate):
		Steam.lobby_chat_update.connect(onSteamLobbyChatUpdate)

	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, _max_players)
	pass

func join_steam(_lobby_id : int):
	clear_lobby()
	var steam_rsp : Dictionary = Steam.steamInitEx(steam_app_id, false)
	if steam_rsp.get("status") != 0:
		printerr(steam_rsp.get("verbal"))
		return

	if !Steam.lobby_created.is_connected(onSteamLobbyCreate):
		Steam.lobby_created.connect(onSteamLobbyCreate)

	if !Steam.lobby_joined.is_connected(onSteamLobbyJoin):
		Steam.lobby_joined.connect(onSteamLobbyJoin)

	if !Steam.lobby_chat_update.is_connected(onSteamLobbyChatUpdate):
		Steam.lobby_chat_update.connect(onSteamLobbyChatUpdate)

	Steam.joinLobby(_lobby_id)
	timeout_timer = 0.001
	pass

func request_steam_lobbies(_filtered : bool = false):
	var steam_rsp : Dictionary = Steam.steamInitEx(steam_app_id, false)
	if steam_rsp.get("status") != 0:
		printerr(steam_rsp.get("verbal"))
		return

	if _filtered:
		Steam.addRequestLobbyListStringFilter("mode", steam_lobby_filter, Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)

	Steam.addRequestLobbyListDistanceFilter(Steam.LobbyDistanceFilter.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	pass

func onSteamLobbyCreate(_connected : int, _lobby_id : int):
	if _connected != 1:
		printerr("Steam lobby couldn't be created: ", str(_connected as Steam.Result))
		return
	else:
		print("Steam lobby ", _lobby_id, " created.")

	Steam.setLobbyData(_lobby_id, "mode", steam_lobby_filter)
	Steam.setLobbyData(_lobby_id, "name", Steam.getPersonaName() + "'s lobby")
	Steam.allowP2PPacketRelay(true)
	Steam.setLobbyJoinable(_lobby_id, true)
	pass

func onSteamLobbyJoin(_lobby_id: int, _permissions: int, _locked: bool, _response: int):
	if _response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var reason: String
		match _response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: reason = "This lobby does not exist."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: reason = "A user you have blocked is in the lobby."
		printerr("Steam lobby ", _lobby_id, " couldn't be joined: ", reason)
		return

	#if not Steam.getLobbyData(lobby_id, "mode") == steam_lobby_filter:
		#print("WARNING: Lobby ", lobby_id, " is not signed with " + steam_lobby_filter")
		#return

	var steam_peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	var owner_id : int = Steam.getLobbyOwner(_lobby_id)
	if owner_id == Steam.getSteamID():
		var error : Error = steam_peer.create_host(0)
		if error == 0:
			set_peer(steam_peer)
			multiplayer.multiplayer_peer = peer
			lobby_data.set("id", _lobby_id)
			player_list.set(multiplayer.get_unique_id(), Steam.getPersonaName() + " (Host)")
			player_list_updated.emit(player_list)
			join_success.emit(_lobby_id)
			print("Hosting Steam lobby.")
		else:
			printerr("Hosting Steam lobby failed: " + error_string(error))
			return
	else:
		var error : Error = steam_peer.create_client(owner_id, 0)
		if error == 0:
			set_peer(steam_peer)
			multiplayer.multiplayer_peer = peer
			lobby_data.set("id", _lobby_id)
			join_success.emit(_lobby_id)
		else:
			printerr("Joining Steam lobby failed: ", error_string(error))
			return
	pass

func onSteamLobbyChatUpdate(_this_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int):
	pass

func onLobbyMatchListReceived(_match_list):
	var lobbies : Array

	for _match in _match_list:
		var lobby : Dictionary

		var lobby_name : String = Steam.getLobbyData(_match, "name")
		var lobby_owner_id : int = Steam.getLobbyOwner(_match)
		var lobby_owner_name : String = Steam.getPlayerNickname(lobby_owner_id)
		if lobby_name == "":
			if lobby_owner_name == "":
				lobby_name = "Unnamed"
			else:
				lobby_name = lobby_owner_name + "'s lobby"
		var lobby_member_count : int = Steam.getNumLobbyMembers(_match)
		var lobby_max_member_count : int = Steam.getLobbyMemberLimit(_match)

		lobby.set("id", _match)
		lobby.set("name", lobby_name)
		lobby.set("member_count", lobby_member_count)
		lobby.set("max_member_count", lobby_max_member_count)
		lobby.set("owner_name", lobby_owner_name)
		lobby.set("owner_id", lobby_owner_id)

		lobbies.append(lobby)

	lobby_list_updated.emit(lobbies)
	pass

func onConnectedToServer():
	if multiplayer.multiplayer_peer.get_class() == "SteamMultiplayerPeer":
		rpc_id(1, "send_name", Steam.getPersonaName())
		print("Joining Steam lobby.")
	elif multiplayer.multiplayer_peer.get_class() == "ENetMultiplayerPeer":
		rpc_id(1, "send_name", get_computer_name())
		print("Joining LAN lobby.")
	timeout_timer = 0.0
	pass

func onConnectionFailed():
	print("Connection failed.")
	clear_lobby()
	pass

func onServerDisconnected():
	print("Server disconnected.")
	clear_lobby()
	pass

func onPeerConnected(_peer_id : int):
	print("Peer " + str(_peer_id) + " connected.")

	if multiplayer.is_server():
		player_list.set(_peer_id, "Receiving info...")
		rpc("sync_player_list", player_list)
	pass

func onPeerDisconnected(_peer_id : int):
	print("Peer " + str(_peer_id) + " disconnected.")

	if multiplayer.is_server():
		player_list.erase(_peer_id)
		player_list_updated.emit(player_list)

		#rpc("sync_player_list", player_list)
		for _peer in multiplayer.get_peers():
			if _peer != _peer_id:
				rpc_id(_peer, "sync_player_list", player_list)
	pass

func onPlayerListUpdated(list):
	if list.size() > 0:
		print(list)
	pass

func clear_lobby():
	if lobby_data.has("id") and peer is SteamMultiplayerPeer:
		Steam.leaveLobby(lobby_data.get("id"))

	multiplayer.multiplayer_peer.close()
	lobby_data.clear()
	player_list.clear()
	player_list_updated.emit(player_list)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	pass

### RPCs

func load_scene(scene_path : String):
	rpc("sync_scene", scene_path)
	pass

@rpc("authority", "call_local", "reliable")
func sync_scene(scene_path : String):
	print("Scene " + scene_path + " loaded.")
	get_tree().change_scene_to_file(scene_path)
	pass

@rpc("any_peer", "call_remote", "reliable")
func send_name(_name : String):
	player_list.set(multiplayer.get_remote_sender_id(), _name)
	rpc("sync_player_list", player_list)
	pass

@rpc("authority", "call_local", "reliable")
func sync_player_list(new_player_list : Dictionary):
	player_list = new_player_list
	player_list_updated.emit(player_list)
	pass

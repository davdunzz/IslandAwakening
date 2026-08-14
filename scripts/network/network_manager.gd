extends Node

signal status_changed(text: String)
const PORT := 7777
var peer := ENetMultiplayerPeer.new()

func host_game() -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 3)
	if error == OK:
		multiplayer.multiplayer_peer = peer; status_changed.emit("Partita LAN creata sulla porta %d" % PORT)
	else: status_changed.emit("Impossibile creare la partita")
	return error

func join_game(address: String) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address if not address.is_empty() else "127.0.0.1", PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer; status_changed.emit("Connessione a %s…" % address)
	else: status_changed.emit("Connessione non riuscita")
	return error

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new(); status_changed.emit("Offline")

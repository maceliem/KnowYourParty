extends Control

const PORT = 4433

var player:Player

var PlayerList := []

var Bobs := 0

func _ready():
	player = $Player
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()
	for category in player.categories:
		var hbox := HBoxContainer.new()
		$Categories.add_child(hbox)
		var button := CheckButton.new()
		button.name = category
		button.pressed.connect(self.categoryPressed.bind(button, category))
		hbox.add_child(button)
		var label := Label.new()
		label.text = category
		hbox.add_child(label)
		
func categoryPressed(button:CheckButton, category:String):
	print(button.button_pressed)
	print(category)
	player.categories[category] = button.button_pressed
	updateCategories.rpc(category, button.button_pressed)

@rpc("authority","call_local","reliable")
func updateCategories(category, state):
	for child in $Categories.get_children():
		if child.get_child(0).name == category:
			child.get_child(0).button_pressed = state

func _on_host_pressed():
	# Start as server.
	if $Menu/Name.text == "":
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	addPlayer($Menu/Name.text)
	gotIn()
	
	$Begin.visible = true
	

func _on_connect_pressed():
	# Start as client.
	if $Menu/Name.text == "":
		return
	var txt : String = $Menu/IP.text
	if txt == "":
		txt = "LocalHost"
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	
	for child in $Categories.get_children():
		var button:CheckButton = child.get_child(0)
		button.disabled = true
	gotIn()

@rpc("any_peer","call_local","reliable")
func addPlayer(username:String):
	var label := Label.new()
	label.text = username
	$NameList.add_child(label)

func gotIn():
	$Menu.visible = false
	$NameList.visible = true
	$Categories.visible = true

@rpc("authority","call_local","reliable")
func startGame():
	player.name = $Menu/Name.text
	$NameList.visible = false
	$Categories.visible = false
	player.visible = true
	player.begin()
	
func _on_player_connected(id):
	for child in $NameList.get_children():
		addPlayer.rpc_id(id, child.text)
	joinGame.rpc_id(id)
	
@rpc("authority","call_local","reliable")
func joinGame():
	addPlayer.rpc($Menu/Name.text)

func _on_player_disconnected(id):
	pass

func _on_connected_ok():
	pass


func _on_begin_pressed():
	startGame.rpc()
	$Begin.visible = false


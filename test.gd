extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var player :Player = $Vivian
	var bob := Player.new()
	bob.name = "Bob"
	var promt:Promt = $Promt
	promt.TargetedPlayers[player] = player.name
	promt.TargetedPlayers[bob] = "Bob"
	player.newPromt(promt)



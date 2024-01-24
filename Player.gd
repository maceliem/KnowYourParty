extends Control
class_name Player

var lang:= "English"

var promtList:Array

var promtScene = preload("res://Promts.tscn").instantiate()

var categories = {
	"Basic": false,
	"Athletic": false,
	"Drinking": false,
	"NSFW": false,
	"Sexual": false,
}
var playerList := {}

func begin():
	for split in promtScene.get_children():
		for child in split.get_children():
			if categories[child.category]:
				promtList.push_back(child)
	if multiplayer.is_server():
		print(playerList)
		randomize()
		var n := randi()% len(promtList)
		var promt:Promt = promtList[n]
		var targetPlayers := []
		for i in promt.AffectedPlayers:
			var id = playerList.keys()[randi() % len(playerList)]
			while id in targetPlayers:
				id = playerList.keys()[randi() % len(playerList)]
			targetPlayers.push_back({"id":id, "name":playerList[id]})
		newPromt.rpc(n, targetPlayers)

@rpc("any_peer","call_local","reliable")
func newPromt(n:int, players:Array):
	var promt:Promt = promtList[n]
	promtList.remove_at(n)
	for i in len(players):
		promt.TargetedPlayers[players[i].id] = players[i].name
		promt[lang] = promt[lang].replace("["+ str(i) +"]", players[i].name)
	$VBoxContainer/PromtBox/Label.text = promt[lang]
	
	# If player needs to bet
	if !promt.TargetedPlayers.keys().has(multiplayer.get_unique_id()) or promt.EveryoneBet:
		$VBoxContainer/SubmitBox/BetBox.visible = true
		if promt.AffectedPlayers == 1:
			$VBoxContainer/SubmitBox/BetBox/Bool.visible = true
		else:
			$VBoxContainer/SubmitBox/BetBox/PickOne.clear
			for player in promt.TargetedPlayers:
				$VBoxContainer/SubmitBox/BetBox/PickOne.add_item(player.name)
				
			$VBoxContainer/SubmitBox/BetBox/PickOne.visible = true
			$VBoxContainer/SubmitBox/AnswerBox/PickOne.visible = true
			
	# If player is challanged
	if promt.TargetedPlayers.keys().has(multiplayer.get_unique_id()):
		$VBoxContainer/SubmitBox/AnswerBox.visible = true
		if promt.AffectedPlayers == 1:
			$VBoxContainer/SubmitBox/AnswerBox/Bool.visible = true
		else:
			$VBoxContainer/SubmitBox/AnswerBox/PickOne.clear
			for player in promt.TargetedPlayers:
				$VBoxContainer/SubmitBox/AnswerBox/PickOne.add_item(player.name)

func _on_yes_pressed():
	$VBoxContainer/SubmitBox/BetBox/Bool/Yes.disabled = true
	$VBoxContainer/SubmitBox/BetBox/Bool/No.disabled = false
	$VBoxContainer/SubmitBox/BetBox/Bool/No.button_pressed = false


func _on_no_pressed():
	$VBoxContainer/SubmitBox/BetBox/Bool/No.disabled = true
	$VBoxContainer/SubmitBox/BetBox/Bool/Yes.disabled = false
	$VBoxContainer/SubmitBox/BetBox/Bool/Yes.button_pressed = false


func _on_yes_submit_pressed():
	$VBoxContainer/SubmitBox/AnswerBox/Bool/YesSubmit.disabled = true
	$VBoxContainer/SubmitBox/AnswerBox/Bool/NoSubmit.disabled = false
	$VBoxContainer/SubmitBox/AnswerBox/Bool/NoSubmit.button_pressed = false


func _on_no_submit_pressed():
	$VBoxContainer/SubmitBox/AnswerBox/Bool/NoSubmit.disabled = true
	$VBoxContainer/SubmitBox/AnswerBox/Bool/YesSubmit.disabled = false
	$VBoxContainer/SubmitBox/AnswerBox/Bool/YesSubmit.button_pressed = false

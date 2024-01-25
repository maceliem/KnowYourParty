extends Control
class_name Player

var lang:= "English"

var promtList:Array

var promtScene = preload("res://Promts.tscn").instantiate()

var categories = {
	"Basic": false,
	"Athletic": false,
	"Drinking": false,
	"Naughty": false,
	"Sexual": false,
	"Most likely":false
}
var playerList := {}

var promt:Promt

var submittedCount := 0
var submissionList := []

var points := 0
func begin():
	for split in promtScene.get_children():
		for child in split.get_children():
			if categories[child.category] and child.visible and split.visible and (child.AffectedPlayers < len(playerList.keys()) or (child.AffectedPlayers <= len(playerList.keys())and child.allAffectedAnswer)):
				if child.AffectedPlayers == 0:
					child.AffectedPlayers = len(playerList.keys())
				promtList.push_back(child)
	if multiplayer.is_server():
		randomize()
		var n := randi()% len(promtList)
		var tmppromt:Promt = promtList[n]
		var targetPlayers := []
		for i in tmppromt.AffectedPlayers:
			var id = playerList.keys()[randi() % len(playerList)]
			while {"id":id, "name":playerList[id]} in targetPlayers:
				id = playerList.keys()[randi() % len(playerList)]
			targetPlayers.push_back({"id":id, "name":playerList[id]})
		newPromt.rpc(n, targetPlayers)

@rpc("any_peer","call_local","reliable")
func newPromt(n:int, players:Array):
	promt = promtList[n]
	promtList.remove_at(n)
	for i in len(players):
		promt.TargetedPlayers[players[i].id] = players[i].name
		promt[lang] = promt[lang].replace("["+ str(i) +"]", players[i].name)
	$VBoxContainer/PromtBox/Label.text = promt[lang]
	
	# If player needs to bet
	if !promt.TargetedPlayers.keys().has(multiplayer.get_unique_id()) or promt.EveryoneBet:
		$VBoxContainer/SubmitBox/BetBox.visible = true
		if promt.answerType == "Bool":
			$VBoxContainer/SubmitBox/BetBox/Bool.visible = true
		elif promt.answerType == "Person":
			$VBoxContainer/SubmitBox/BetBox/PickOne.clear
			for player in promt.TargetedPlayers.keys():
				$VBoxContainer/SubmitBox/BetBox/PickOne.add_item(promt.TargetedPlayers[player])
				
			$VBoxContainer/SubmitBox/BetBox/PickOne.visible = true
			$VBoxContainer/SubmitBox/AnswerBox/PickOne.visible = true
			
	# If player is challanged
	if (promt.TargetedPlayers.keys().has(multiplayer.get_unique_id()) and promt.allAffectedAnswer) or promt.TargetedPlayers.keys()[promt.whoAnswers] == multiplayer.get_unique_id():
		$VBoxContainer/SubmitBox/AnswerBox.visible = true
		if promt.answerType == "Bool":
			$VBoxContainer/SubmitBox/AnswerBox/Bool.visible = true
		elif promt.answerType == "Person":
			$VBoxContainer/SubmitBox/AnswerBox/PickOne.visible = true
			$VBoxContainer/SubmitBox/AnswerBox/PickOne.clear
			for player in promt.TargetedPlayers.keys():
				$VBoxContainer/SubmitBox/AnswerBox/PickOne.add_item(promt.TargetedPlayers[player])
		elif promt.answerType == "Number":
			$VBoxContainer/SubmitBox/AnswerBox/Number.visible = true
			$VBoxContainer/SubmitBox/AnswerBox/Number.text = ""

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


func _on_submit_pressed():
	$VBoxContainer/SubmitBox/AnswerBox/Submit.visible = false
	if promt.answerType == "Bool":
		submitted.rpc($VBoxContainer/SubmitBox/AnswerBox/Bool/YesSubmit.button_pressed,multiplayer.get_unique_id())
	elif promt.answerType == "Person":
		submitted.rpc($VBoxContainer/SubmitBox/AnswerBox/PickOne.get_item_text($VBoxContainer/SubmitBox/AnswerBox/PickOne.get_selected_id()),multiplayer.get_unique_id())
	elif promt.answerType == "Number":
		submitted.rpc(int($VBoxContainer/SubmitBox/AnswerBox/Number.text), multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func submitted(answer, id):
	submittedCount += 1
	submissionList.push_back({"answer":answer, "person":playerList[id]})
	
	#If everyone needs to answer, and they havent
	if promt.allAffectedAnswer: if submittedCount != promt.AffectedPlayers: return
	
	$ResultBox.visible = true
	if promt.AffectedPlayers == 1:
		var label := Label.new()
		if promt.answerType == "Bool":
			if answer: label.text = "Yes"
			else: label.text = "no"
		else: label.text = str(answer)
		$ResultBox/HBoxContainer/Replies/Bars.add_child(label)
		if multiplayer.is_server(): 
			$NextPromt.visible = true
			if promt.answerType == "Number" and promt.betType == "Bool":
				if (promt.HighestWin and answer >= promt.target) or (!promt.HighestWin and answer <= promt.target):
					sendSubmit.rpc([true])
				else:
					sendSubmit.rpc([false])
			else:
				sendSubmit.rpc([answer])
	else:
		var options:= []
		if promt.answerType == "Bool":
			options = [false, true]
		else: 
			for point in submissionList:
				if promt.answerType == "Person":
					if !point.answer in options:
						options.push_back(point)
				elif promt.answerType == "Number":
					if !point.person in options:
						options.push_back(point)
		
		#If answer graph
		if promt.answerType == "Bool" or promt.answerType == "Person":
			for option in options:
				var vbox := VBoxContainer.new()
				$ResultBox/HBoxContainer/Replies/Bars.add_child(vbox)
				var progress := ProgressBar.new()
				progress.max_value = submittedCount
				vbox.add_child(progress)
				var label := Label.new()
				vbox.add_child(label)
				if promt.answerType == "Bool":
					if option: label.text = "Yes"
					else: label.text = "No"
				else:
					label.text = option.person
				for response in submissionList:
					if response.answer == option.answer:
						progress.value += 1
		
		if multiplayer.is_server():
			var highestAnswer = 0
			var n
			var multiple = []
			for i in len(options):
				if $ResultBox/HBoxContainer/Replies/Bars.get_child(i).get_child(0).value > highestAnswer:
					highestAnswer = $ResultBox/HBoxContainer/Replies/Bars.get_child(i).get_child(0).value
					n = i
					multiple = [i]
				elif $ResultBox/HBoxContainer/Replies/Bars.get_child(i).get_child(0).value == highestAnswer:
					multiple.push_back(i)
			var answers = []
			for i in multiple:
				answers.push_back(options[i].person)
			sendSubmit.rpc(answers)
			$NextPromt.visible = true

@rpc("any_peer", "call_local", "reliable")
func sendSubmit(answers):
	if $VBoxContainer/SubmitBox/BetBox.visible:
		for answer in answers:
			if promt.betType == "Bool":
				addGuessBar.rpc($VBoxContainer/SubmitBox/BetBox/Bool/Yes.button_pressed)
				if $VBoxContainer/SubmitBox/BetBox/Bool/Yes.button_pressed == answer:
					return point(true)
			elif promt.betType == "Person":
				addGuessBar.rpc($VBoxContainer/SubmitBox/BetBox/PickOne.get_item_text($VBoxContainer/SubmitBox/BetBox/PickOne.get_selected_id()))
				if $VBoxContainer/SubmitBox/BetBox/PickOne.get_item_text($VBoxContainer/SubmitBox/BetBox/PickOne.get_selected_id()) == answer:
					return point(true)
		return point(false)

@rpc("any_peer", "call_local", "reliable")
func addGuessBar(guess):
	if !$ResultBox/HBoxContainer/Guess/Bars.has_node(str(guess)):
		var vbox := VBoxContainer.new()
		vbox.name = str(guess)
		$ResultBox/HBoxContainer/Guess/Bars.add_child(vbox)
		var progress := ProgressBar.new()
		if promt.EveryoneBet:
			progress.max_value = len(multiplayer.get_peers()) + 1
		else: 
			progress.max_value = len(multiplayer.get_peers()) + 1 - promt.AffectedPlayers
		vbox.add_child(progress)
		var label := Label.new()
		if promt.answerType == "Bool":
			if guess: label.text = "Yes"
			else: label.text  = "No"
		else: label.text = str(guess)
		vbox.add_child(label)
	$ResultBox/HBoxContainer/Guess/Bars.get_node(str(guess)).get_child(0).value += 1

func point(correct:bool):
	if correct:
		points += 1
		$ResultBox/ResultLabel.text = "✅"
	else:
		$ResultBox/ResultLabel.text = "❌"
	$ScoreLabel.text = str(points)


func _on_next_promt_pressed():
	newRound.rpc()

@rpc("any_peer","call_local", "reliable")
func newRound():
	submittedCount = 0
	submissionList = []
	$NextPromt.visible = false
	$ResultBox.visible = false
	$VBoxContainer/SubmitBox/BetBox.visible = false
	$VBoxContainer/SubmitBox/AnswerBox/Bool.visible = false
	$VBoxContainer/SubmitBox/BetBox/PickOne.visible = false
	$VBoxContainer/SubmitBox/BetBox/Bool/No.button_pressed = false
	$VBoxContainer/SubmitBox/BetBox/Bool/Yes.button_pressed = false
	$VBoxContainer/SubmitBox/AnswerBox.visible = false
	$VBoxContainer/SubmitBox/AnswerBox/Bool.visible = false
	$VBoxContainer/SubmitBox/AnswerBox/PickOne.visible = false
	$VBoxContainer/SubmitBox/AnswerBox/Number.visible = false
	$VBoxContainer/SubmitBox/AnswerBox/Submit.visible = true
	$VBoxContainer/SubmitBox/AnswerBox/Bool/NoSubmit.button_pressed = false
	$VBoxContainer/SubmitBox/AnswerBox/Bool/YesSubmit.button_pressed = false
	for child in $ResultBox/HBoxContainer/Replies/Bars.get_children():
		$ResultBox/HBoxContainer/Replies/Bars.remove_child(child)
	for child in $ResultBox/HBoxContainer/Guess/Bars.get_children():
		$ResultBox/HBoxContainer/Guess/Bars.remove_child(child)
	
	
	if multiplayer.is_server():
		var n := randi()% len(promtList)
		var tmppromt:Promt = promtList[n]
		var targetPlayers := []
		for i in tmppromt.AffectedPlayers:
			var id = playerList.keys()[randi() % len(playerList)]
			while {"id":id, "name":playerList[id]} in targetPlayers:
				id = playerList.keys()[randi() % len(playerList)]
			targetPlayers.push_back({"id":id, "name":playerList[id]})
		newPromt.rpc(n, targetPlayers)

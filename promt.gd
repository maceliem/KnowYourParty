@tool
extends Control
class_name Promt

@export_category("Promt Properties")
@export_enum("Basic", "Physical", "Drinking", "Romance", "Naughty", "Most likely") var category:String
## 0 for everyone
@export var AffectedPlayers: int = 1
@export var EveryoneBet := false
@export_enum("Bool", "Person", "Number") var betType:String
@export_enum("Bool", "Person", "Number") var answerType:String
@export var HighestWin:bool
@export var target:int
@export var allAffectedAnswer:bool = false
@export var whoAnswers:int = 0

@export_category("Description")
@export_multiline var Dansk:String
@export_multiline var English:String

var promt = preload("res://promt.tscn").instantiate()

var TargetedPlayers := {}

func _process(delta):
	get_node("Label").text = English

func _ready():
	if get_child_count() == 0:
		add_child(promt)
		for child in promt.get_children():
			promt.remove_child(child)
			add_child(child)
		remove_child(promt)

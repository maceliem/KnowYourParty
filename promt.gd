@tool
extends Control
class_name Promt

@export_category("Promt Properties")
@export_enum("Basic", "Athletic", "Drinking", "NSFW", "Sexual") var category:String
## 0 for everyone
@export var AffectedPlayers: int = 1
@export var EveryoneBet := false
@export_enum("Bool", "Person") var answerType:String
@export var allAffectedAnswer:bool = false

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

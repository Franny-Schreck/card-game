class_name GlobalStats
extends Node2D

var curr_environment: Dictionary = {
	"fl" = 5,
	"gp" = 0,
}

var prev_environment: Dictionary

var florin_count: Label

var govpt_count: Label

func _ready() -> void:
	self.florin_count = get_node("florin_count")
	self.govpt_count = get_node("govpt_count")
	self.prev_environment = curr_environment
	get_parent().get_node("board").environment_changed.connect(_on_environment_changed)

func _on_environment_changed() -> void:
	florin_count.text = str(curr_environment["fl"])
	govpt_count.text = str(curr_environment["gp"])

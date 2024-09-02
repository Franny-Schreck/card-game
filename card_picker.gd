extends Node2D

var pickable_cards: PickableCards

var on_pick: Callable

func _ready() -> void:
	self.pickable_cards = get_node("pickable_cards")

func pick_cards(cards: Array[Card], pick_count: int) -> void:
	self.show()
	pickable_cards.set_cards(cards, pick_count)


func _on_btn_confirm_pressed() -> void:
	self.hide()
	var picked_cards: Array[Card] = pickable_cards.get_picked_cards()

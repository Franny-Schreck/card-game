class_name PickableCards
extends Node2D

const ROW_WIDTH = 130

var cards_picked: Dictionary = {}

var curr_pick_count: int

var required_pick_count: int


func set_cards(cards_: Array[Card], pick_count_: int) -> void:
	for card in cards_picked.keys():
		remove_child(card)

	cards_picked.clear()
	
	for card in cards_:
		add_child(card)
		cards_picked[card] = false

	curr_pick_count = 0

	required_pick_count = pick_count_


func toggle_picked(card: Card) -> bool:
	var is_picked: bool = cards_picked[card]

	if not is_picked and curr_pick_count == required_pick_count:
		return is_picked

	cards_picked[card] = not is_picked

	if is_picked:
		curr_pick_count -= 1
	else:
		curr_pick_count += 1

	return is_picked


func get_picked_cards() -> Array[Card]:
	var picked_cards: Array[Card]
	for card in cards_picked.keys():
		if cards_picked[card]:
			picked_cards.append(card)
	return picked_cards


func _process(delta: float) -> void:
		get_parent().get_node("btn_confirm").disabled = curr_pick_count != required_pick_count
		
		var offset: int = cards_picked.size() * ROW_WIDTH / 2
		
		var i: int = 0
		
		for card in cards_picked.keys():
			card.transform = Transform2D().translated(Vector2(i * ROW_WIDTH - offset, 0))
			i += 1

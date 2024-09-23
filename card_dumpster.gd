extends CardContainer2D

var _old_cards: Array[Card]


func _ready() -> void:
	super._ready()

	card_attached.connect(_on_card_attached)
	
	get_node("/root/root/board").new_turn.connect(_on_new_turn)


func _on_card_attached(card: Card, _index: int) -> void:
	card.animate_to(Vector2(get_viewport_rect().size.x + 50, -20), Vector2(0.2, 0.2), 50, true, 0.5, 0.0, true)


func _on_new_turn() -> void:
	for card: Card in _old_cards:
		detach_card(card)
		card.queue_free()
	_old_cards = _cards.duplicate()

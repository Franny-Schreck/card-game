class_name DiscardPile
extends CardContainer2D

const MAX_RENDERED_CARDS = 5


func _ready() -> void:
	super._ready()
	card_attached.connect(_on_card_attached)


func _on_card_attached(card: Card, index: int) -> void:
	var card_order: int = min(index, MAX_RENDERED_CARDS - 1)
	card.animate_to(
		global_position + Vector2(card_order * 2, card_order * 2),
		Vector2(1.0 / 1.5, 1.0 / 1.5),
		0,
		true,
		0.75
	)
	
	await card._animation_complete
	
	card.set_extra_play_cost(0)

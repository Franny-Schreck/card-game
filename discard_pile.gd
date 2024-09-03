class_name DiscardPile
extends CardContainer2D

const MAX_RENDERED_CARDS = 5


func _process(delta: float) -> void:
	for card in cards:
		card.visible = false

	var rendered_card_count: int = min(MAX_RENDERED_CARDS, cards.size())

	for i in range(rendered_card_count):
		var card: Card = cards[cards.size() - rendered_card_count + i]
		card.visible = true
		card.transform = Transform2D().scaled(Vector2(1.0 / 1.5, 1.0 / 1.5)).translated(Vector2(i * 2, i * 2))
		card.z_index = i

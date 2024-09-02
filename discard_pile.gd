class_name DiscardPile
extends CardContainer2D

const MAX_RENDERED_CARDS = 5

func add_card(card: Card) -> void:
	super.add_card(card)
	# adjust_card_visibility()


func remove_card(card: Card) -> void:
	super.remove_card(card)
	card.visible = true
	card.z_index = 1
	# adjust_card_visibility()


# func adjust_card_visibility() -> void:

func _process(delta: float) -> void:
	for card in cards:
		card.visible = false

	for i in range(min(MAX_RENDERED_CARDS, cards.size())):
		var card: Card = cards[cards.size() - 1 - i]
		card.visible = true
		card.transform = Transform2D().scaled(Vector2(1.0 / 1.5, 1.0 / 1.5)).translated(Vector2(i * 2, i * 2))
		card.z_index = i

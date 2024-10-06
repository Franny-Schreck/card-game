class_name DrawPile
extends CardContainer2D

const MAX_RENDERED_CARDS = 5

var _card_factory: CardFactory


func _on_card_attached(card: Card, _index: int) -> void:
	card.hide()


func _on_card_detached(card: Card, _index: int) -> void:
	card.show()


func _on_content_changed(cards: Array[Card]) -> void:
	var visible_card_back_count: int = min(cards.size(), MAX_RENDERED_CARDS)

	for i in range(MAX_RENDERED_CARDS):
		var card_back: Sprite2D = get_node("card_back_" + str(i))
		card_back.visible = i < visible_card_back_count


func _ready() -> void:
	super._ready()
	_card_factory = get_parent().get_node("card_factory")
	card_attached.connect(_on_card_attached)
	card_detached.connect(_on_card_detached)
	content_changed.connect(_on_content_changed)

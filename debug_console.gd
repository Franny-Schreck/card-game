extends LineEdit


var _card_factory: CardFactory

var _hand: Hand


func _ready() -> void:
	_card_factory = get_node("/root/root/card_factory")
	_hand = get_node("/root/root/hand")


func _on_text_submitted(new_text: String) -> void:
	if _card_factory.has_card_with_name(new_text):
		_hand.add_card(await _card_factory.get_card_by_name(new_text))

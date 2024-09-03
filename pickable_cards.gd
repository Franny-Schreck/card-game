class_name PickableCards
extends CardContainer2D

const ROW_WIDTH = 200

var cards_picked: Dictionary = {}

var curr_pick_count: int

var required_pick_count: int

var card_origin: CardContainer2D

var card_origin_positions: Array[int]

var card_picker: CardPicker


func _ready() -> void:
	self.card_picker = get_parent()


func set_cards(cards_: Array[Card], pick_count_: int) -> void:
	assert(cards_.size() >= pick_count_ and cards_.size() != 0)

	card_origin = cards_[0].get_card_container()

	if card_origin != null:
		for card in cards_:
			assert(card.get_card_container() == card_origin, "Cannot mix cards from different origins in card picker")
			card_origin_positions.append(card_origin.cards.find(card))
			card_origin.remove_card(card)

	for card in cards_:
		add_card(card)
		cards_picked[card] = false

	curr_pick_count = 0

	required_pick_count = pick_count_


func toggle_picked(card: Card) -> bool:
	if not card_picker.is_ready:
		return false

	var is_pick: bool = not cards_picked[card]

	if is_pick and curr_pick_count == required_pick_count:
		if required_pick_count != 1:
			return false
		else:
			for picked_card in cards_picked.keys():
				if cards_picked[picked_card]:
					cards_picked[picked_card] = false
					picked_card.click_outline.hide()
					break
			cards_picked[card] = true
			return true

	cards_picked[card] = is_pick

	if is_pick:
		curr_pick_count += 1
	else:
		curr_pick_count -= 1

	return is_pick


func get_picked_cards() -> Array[Card]:
	var picked_cards: Array[Card]

	var i: int = cards.size() - 1

	while cards.size() != 0:
		var card: Card = cards[i]

		remove_card(card)

		if cards_picked[card]:
			picked_cards.append(card)
		elif card_origin != null:
			card_origin.add_card(card, card_origin_positions[i])

		i -= 1

	card_origin_positions.clear()

	cards_picked.clear()

	return picked_cards


func _process(delta: float) -> void:
	card_picker.btn_confirm.disabled = curr_pick_count != required_pick_count or not card_picker.is_ready

	var offset: int = (cards.size() * ROW_WIDTH / 2) - (ROW_WIDTH / 2)

	for i in range(cards.size()):
		var card: Card = cards[i]

		card.transform = Transform2D() \
			.scaled(Vector2(1.5, 1.5)) \
			.translated(Vector2(i * ROW_WIDTH - offset, 0))

		if curr_pick_count == required_pick_count and not cards_picked[card]:
			card.disable_outline.show()
		else:
			card.disable_outline.hide()

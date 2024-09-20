class_name CardPicker
extends CardContainer2D

const ROW_WIDTH = 200

var _btn_confirm: Button

var _is_ready: bool

var _card_states: Dictionary = {}

var _curr_pick_count: int

var _required_pick_count: int

var _card_origin: CardContainer2D

var _card_origin_initial_contents: Array[Card]


func pick_cards(cards: Array[Card], pick_count: int) -> Array[Card]:
	assert(cards.size() >= pick_count and cards.size() != 0)

	_is_ready = false

	_card_origin = cards[0].get_card_container()

	if _card_origin != null:
		_card_origin_initial_contents = _card_origin._cards.duplicate()
		for card in cards:
			assert(card.get_card_container() == _card_origin, "Cannot mix cards from different origins in card picker")

	add_all_cards(cards)

	for card in cards:
		add_card(card)
		_card_states[card] = false

	_curr_pick_count = 0
	_required_pick_count = pick_count

	get_parent().show()

	# TODO: Check if waiting for next frame also works
	await get_tree().create_timer(0.1).timeout

	_is_ready = true

	_redraw(cards)

	await _btn_confirm.pressed

	_is_ready = false

	var picked_cards: Array[Card] = []

	for card in _card_states.keys():
		if not _card_states[card]:
			continue

		picked_cards.append(card)
		
		if _card_origin != null:
			_card_origin_initial_contents.erase(card)

	if _card_origin != null:
		_card_origin.detach_all_cards()
		_card_origin.add_all_cards(_card_origin_initial_contents)

	detach_all_cards()

	_card_states.clear()

	get_parent().hide()

	return picked_cards


func _toggle_picked(card: Card) -> bool:
	if not _is_ready:
		return false

	var is_pick: bool = not _card_states[card]

	if is_pick and _curr_pick_count == _required_pick_count:
		if _required_pick_count != 1:
			return false
		else:
			for picked_card in _card_states.keys():
				if _card_states[picked_card]:
					_card_states[picked_card] = false
					picked_card.set_clicked(false)
					break
			_card_states[card] = true
			return true

	_card_states[card] = is_pick

	if is_pick:
		_curr_pick_count += 1
	else:
		_curr_pick_count -= 1

	_redraw(_cards)

	return is_pick


func _on_card_input(card: Card, event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left"):
		if _toggle_picked(card):
			_redraw(_cards)


func _on_card_mouse(card: Card, is_entered: bool) -> void:
	card.set_hovered(_is_ready and is_entered and (_curr_pick_count < _required_pick_count or _required_pick_count == 1))


func _redraw(cards: Array[Card]) -> void:
	_btn_confirm.disabled = _curr_pick_count != _required_pick_count or not _is_ready

	if not _is_ready:
		return

	var offset: int = (cards.size() * ROW_WIDTH / 2) - (ROW_WIDTH / 2)

	for i in range(cards.size()):
		var card: Card = cards[i]

		card.transform = Transform2D() \
			.scaled(Vector2(1.5, 1.5)) \
			.translated(Vector2(i * ROW_WIDTH - offset, 0))

		card.set_clicked(_card_states[card])

		card.set_disabled(_curr_pick_count == _required_pick_count and not _card_states[card])


func _ready() -> void:
	super._ready()
	_btn_confirm = get_parent().get_node("btn_confirm")
	card_input.connect(_on_card_input)
	card_mouse.connect(_on_card_mouse)
	content_changed.connect(_redraw)

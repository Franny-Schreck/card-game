class_name CardContainer2D
extends Node2D

var _cards: Array[Card] = []

var _card_root: Node2D = Node2D.new()

signal card_attached(card: Card, index: int)

signal card_detached(card: Card, index: int)

signal card_moved(card: Card, old_index: int, new_index: int)

signal content_changed(cards: Array[Card])

signal card_input(card: Card, input: InputEvent)

signal card_mouse(card: Card, is_entered: bool)


func add_card(card: Card, index: int = -1) -> void:
	var prev_container: CardContainer2D = card.get_card_container()

	if prev_container != null:
		prev_container.detach_card(card)

	_card_root.add_child(card)

	if index == -1:
		_cards.append(card)
	else:
		_cards.insert(index, card)
		_card_root.move_child(card, index)

	card.mouse.connect(_on_contained_card_mouse)
	card.input.connect(_on_contained_card_input)

	card.reset_graphics()

	card_attached.emit(card, index if index != -1 else _cards.size() - 1)

	content_changed.emit(_cards)


func detach_card(card: Card) -> int:
	card.checkpoint_transform()

	var index: int = _cards.find(card)

	_cards.remove_at(index)

	_card_root.remove_child(card)

	card.mouse.disconnect(_on_contained_card_mouse)
	card.input.disconnect(_on_contained_card_input)

	card_detached.emit(card, index)

	content_changed.emit(_cards)
	
	return index


func move_card(card: Card, new_index: int) -> void:
	var old_index: int = _cards.find(card)

	_cards.remove_at(old_index)

	if new_index == -1:
		_cards.append(card)
	else:
		_cards.insert(new_index, card)

	_card_root.move_child(card, new_index)
	
	card_moved.emit(card, old_index, new_index if new_index != -1 else _cards.size() - 1)

	content_changed.emit(_cards)


func add_all_cards(cards: Array[Card]) -> void:
	_cards.append_array(cards)

	for index in range(_cards.size() - cards.size(), _cards.size()):
		var card: Card = _cards[index]

		var prev_container: CardContainer2D = card.get_card_container()
		if prev_container != null:
			prev_container.detach_card(card)

		_card_root.add_child(card)

		card.mouse.connect(_on_contained_card_mouse)
		card.input.connect(_on_contained_card_input)

		card.reset_graphics()

		card_attached.emit(card, index)

	content_changed.emit(_cards)


func detach_all_cards() -> void:
	for card in _cards:
		card.checkpoint_transform()

	for i in range(_cards.size()):
		var card = _cards[i]

		_card_root.remove_child(card)

		card.mouse.disconnect(_on_contained_card_mouse)
		card.input.disconnect(_on_contained_card_input)

		card_detached.emit(card, i)
		
	_cards.clear()

	content_changed.emit(_cards)


func index_of(card: Card) -> int:
	return _cards.find(card)


func card_count() -> int:
	return _cards.size()


func _ready() -> void:
	add_child(_card_root)


func _on_contained_card_mouse(card: Card, is_entered: bool) -> void:
	card_mouse.emit(card, is_entered)


func _on_contained_card_input(card: Card, event: InputEvent) -> void:
	card_input.emit(card, event)

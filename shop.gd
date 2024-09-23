class_name Shop
extends CardContainer2D

class PriceModifier:
	var remaining_turns: int
	var callback: ScriptInterpreter.ScriptNode

const CARDS_PER_COL = 2

const MAX_SELECTION_SIZE = 6

const COL_WIDTH = 130

const ROW_HEIGHT = 220

var _hand: Hand

var _global_stats: GlobalStats

var _board: Board

var _card_factory: CardFactory

var _restock_btn: Button

var _card_positions: Dictionary

var _card_prices: Array[HBoxContainer]

var _card_price_labels: Array[Label]

var _price_modifiers: Array[PriceModifier]

var _cards_bought_this_turn: int

var _restocks_this_turn: int

var _selection_size: int


func _ready() -> void:
	super._ready()

	_hand = get_node("/root/root/hand")
	_board = get_node("/root/root/board")
	_card_factory = get_node("/root/root/card_factory")
	_global_stats = get_node("/root/root/global_stats")
	_restock_btn = get_node("restock_btn")

	card_moved.connect(_on_card_moved)
	card_attached.connect(_on_card_attached)
	card_detached.connect(_on_card_detached)
	content_changed.connect(_redraw)
	card_input.connect(_on_card_input)
	card_mouse.connect(_on_card_mouse)

	_selection_size = 2

	Root.connect_on_root_ready(self, _on_root_ready)

	_board.new_turn.connect(_on_new_turn)
	_board.environment_changed.connect(_on_environment_changed)
	
	for index in range(MAX_SELECTION_SIZE):
		var row: int = index % CARDS_PER_COL

		var col: int = 2 - index / CARDS_PER_COL

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.visible = false
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.size = Vector2(100, 0)
		hbox.position = Vector2(col * COL_WIDTH - 50, row * ROW_HEIGHT + ROW_HEIGHT / 2 - 15)
		_card_prices.append(hbox)
		add_child(hbox)

		var label: Label = Label.new()
		label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
		_card_price_labels.append(label)
		hbox.add_child(label)

		var icon: TextureRect = TextureRect.new()
		icon.texture = load("res://assets/florin_icon.png")
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		hbox.add_child(icon)


func _on_root_ready() -> void:
	_restock()


func _restock() -> void:
	detach_all_cards()

	for i in range(_selection_size):
		add_card(await _card_factory.get_card_by_category("shop"))


func _on_new_turn() -> void:
	var new_price_modifiers: Array[PriceModifier] = []

	for modifier: PriceModifier in _price_modifiers:
		if modifier.remaining_turns > 1:
			modifier.remaining_turns -= 1
		if modifier.remaining_turns != 1:
			new_price_modifiers.append(modifier)

	_price_modifiers = new_price_modifiers

	_restocks_this_turn = 0
	_cards_bought_this_turn = 0

	var shop_level: int = 0
	
	for var_name: String in _global_stats.curr_environment.keys():
		if var_name.begins_with("total-") and var_name.ends_with("-level"):
			shop_level += _global_stats.curr_environment[var_name] / 3

	_selection_size = min(6, 2 + shop_level)

	_restock()


func _on_environment_changed() -> void:
	_toggle_restock_btn()
	_update_all_card_prices()


func _on_card_moved(_card: Card, _old_index: int, _new_index: int) -> void:
	assert(false, "Cannot call Shop.move_card")


func _on_card_attached(card: Card, index: int) -> void:
	_card_positions[card] = index
	_update_card_price(card)
	_card_prices[index].show()


func _on_card_detached(card: Card, _index: int) -> void:
	_card_prices[_card_positions[card]].hide()
	_card_positions.erase(card)


func _on_card_input(card: Card, event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left") and not card.is_disabled():
		_cards_bought_this_turn += 1
		_global_stats.change_fl(-int(_card_price_labels[_card_positions[card]].text))
		_update_all_card_prices()
		_hand.add_card(card)


func _on_card_mouse(card: Card, is_entered: bool) -> void:
	card.set_hovered(is_entered && not card.is_disabled())


func _redraw(cards: Array[Card]) -> void:
	for card in cards:
		var index: int = _card_positions[card]

		var row: int = index % CARDS_PER_COL

		var col: int = 2 - index / CARDS_PER_COL

		card.transform = Transform2D().translated(Vector2(col * COL_WIDTH, row * ROW_HEIGHT))


func _calc_restock_price() -> int:
	return 3 + _restocks_this_turn


func _toggle_restock_btn() -> void:
	_restock_btn.disabled = _global_stats.get_fl() < _calc_restock_price()


func _on_restock_btn_pressed() -> void:
	_global_stats.change_fl(-_calc_restock_price())
	_restock()
	_restocks_this_turn += 1
	_toggle_restock_btn()


func _update_all_card_prices() -> void:
	for card in _cards:
		_update_card_price(card)


func _update_card_price(card: Card) -> void:
	var env: ScriptInterpreter.ScriptEnvironment = _card_factory.create_environment(
		_global_stats.curr_environment,
		null
	)

	var raw_price: int = await card.shop_cost(env)

	var modifier_env: ScriptInterpreter.ScriptEnvironment = _card_factory.create_environment(
		_global_stats.curr_environment, {
			"price" = raw_price,
			"buy-count" = _cards_bought_this_turn,
			"restock-count" = _restocks_this_turn
		}
	)

	var modifier_sum: int = 0

	for modifier: PriceModifier in _price_modifiers:
		modifier_env.local_vars["price"] = raw_price
		modifier_env.local_vars["card"] = card
		modifier_sum += await modifier.callback.evaluate([], modifier_env)

	var card_price: int = raw_price + _cards_bought_this_turn - modifier_sum

	_card_price_labels[_card_positions[card]].text = str(max(card_price, 0))

	card.set_disabled(card_price > _global_stats.get_fl())


func _interp_add_price_modifier(
	args: Array[ScriptInterpreter.ScriptNode],
	env: ScriptInterpreter.ScriptEnvironment
) -> Variant:
	var modifier: PriceModifier = PriceModifier.new()
	modifier.remaining_turns = await args[0].evaluate([], env)
	modifier.callback = args[1]
	_price_modifiers.append(modifier)
	_update_all_card_prices()
	return null

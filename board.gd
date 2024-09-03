class_name Board
extends Node2D

var active_district: District = null

var card_factory: CardFactory

var global_stats: GlobalStats

var hand: Hand

var draw_pile: DrawPile

var discard_pile: DiscardPile

var turn_skip_cost: Label

var turn_skip_icon: Sprite2D

var btn_end_turn: Button

var is_skipped_turn: bool = true

var skipped_turn_count: int

signal environment_changed


func _ready() -> void:
	card_factory = get_parent().get_node("card_factory")
	global_stats = get_parent().get_node("global_stats")
	hand = get_parent().get_node("hand")
	draw_pile = get_parent().get_node("draw_pile")
	discard_pile = get_parent().get_node("discard_pile")
	turn_skip_cost = get_node("turn_skip_cost")
	turn_skip_icon = get_node("turn_skip_icon")
	btn_end_turn = get_node("btn_end_turn")

	for district in get_children():
		if district is District:
			district.post_ready()

	_update_end_turn_btn()


func post_ready() -> void:
	environment_changed.emit()


func play(card: Card) -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = script_environment()

	if await card.is_applicable(env):
		print("Played ", card, " onto ", active_district)

		if card.discard_on_play():
			hand.remove_card(card)

		var new_env: ScriptInterpreter.ScriptEnvironment = await card.apply(env)

		global_stats.curr_environment = new_env.global_vars
		if active_district != null:
			active_district.curr_environment = new_env.local_vars

		environment_changed.emit()

		if card.discard_on_play():
			discard_pile.add_card(card)
			
		skipped_turn_count = 0

		is_skipped_turn = false

		_update_end_turn_btn()

		return true

	else:
		print("Could not play ", card, "onto ", active_district)

		return false


func _update_end_turn_btn() -> void:
	var cost: int = _end_turn_cost()

	btn_end_turn.disabled = cost > global_stats.curr_environment["gp"]
	turn_skip_cost.text = str(-cost)
	turn_skip_cost.visible = cost != 0
	turn_skip_icon.visible = cost != 0
	btn_end_turn.text = "Skip Turn" if is_skipped_turn else "Next Turn"


func _on_btn_end_turn_pressed() -> void:
	btn_end_turn.disabled = true

	# Handle repeated skipped turns
	if is_skipped_turn:
		var deducted_gp: int = _end_turn_cost()
		assert(deducted_gp <= global_stats.curr_environment["gp"], "'Next Turn' was clickable, even though gp were insufficient")
		global_stats.curr_environment["gp"] -= deducted_gp
		skipped_turn_count += 1

	# Discard hand and redraw from draw pile
	while hand.cards.size() != 0:
		var card: Card = hand.cards.back()
		hand.remove_card(card)
		discard_pile.add_card(card)

	# If there aren't enough cards in the draw pile, shuffle the discard pile into it
	if draw_pile.cards.size() < 3:
		discard_pile.cards.shuffle()

		while discard_pile.cards.size() != 0:
			var card: Card = discard_pile.cards.back()
			discard_pile.remove_card(card)
			draw_pile.add_card(card)

	for i in range(min(3, draw_pile.cards.size())):
		var card: Card = draw_pile.cards.back()
		draw_pile.remove_card(card)
		hand.add_card(card)

	# Apply environment changes from played cards
	for district in get_children():
		if district is District:
			district.prev_environment = district.curr_environment

	global_stats.prev_environment = global_stats.curr_environment

	environment_changed.emit()

	# Apply building turn effects
	var changed_district_count: int = 0

	for district in get_children():
		if district is District:
			if district.apply_building_turn_effects(changed_district_count):
				changed_district_count += 1

	is_skipped_turn = true

	_update_end_turn_btn()


func _end_turn_cost() -> int:
	return 0 if skipped_turn_count == 0 else skipped_turn_count + 2


func script_environment() -> ScriptInterpreter.ScriptEnvironment:
	return card_factory.create_environment(
		global_stats.curr_environment,
		active_district.curr_environment if active_district != null else null
	)


func _select_cards(count: int, sources, mode: String) -> Array[Card]:
	assert(mode == "random" or mode == "top" or mode == "bottom", "Unexpected mode '" + mode + "'. Expected 'random', 'top' or 'bottom'")

	var cards: Array[Card] = []

	if sources is Card:
		cards.append(sources)
	elif sources is String and (sources == "hand" or sources == "draw" or sources == "discard"):
		var all_cards: Array[Card]
		if sources == "hand":
			all_cards = hand.cards.duplicate()
		elif sources == "draw":
			all_cards = draw_pile.cards.duplicate()
		elif sources == "discard":
			all_cards = discard_pile.cards.duplicate()
		else:
			assert(false)

		if count == -1:
			cards = all_cards
		elif mode == "random":
			all_cards.shuffle()
			cards = all_cards.slice(0, min(all_cards.size(), count))
		elif mode == "top":
			cards = all_cards.slice(max(0, all_cards.size() - count), max(0, all_cards.size()))
		elif mode == "bottom":
			cards = all_cards.slice(0, min(all_cards.size(), count))
		else:
			assert(false)

	elif sources is String and sources.begins_with("category:"):
		assert(mode == "random", "Cannot combine mode '" + mode + "' with source of type 'category:*'")
		for i in range(count):
			cards.append(card_factory.get_card_by_category(sources.substr("category:".length())))

	else:
		var source_list: Array[String]

		if sources is Array:
			source_list = sources
		elif sources is String:
			source_list = [sources]
		else:
			assert(false, "Unexpected source type")

		for source in source_list:
			assert(source.begins_with("card:"), "Unexpected sources element '" + source + "'. Can only accept multiple 'card:*' sources")
			cards.append(card_factory.get_card_by_name(source.substr("card:".length())))

		if cards.size() > count:
			cards.shuffle()
			while cards.size() > count:
				cards.pop_back()
		elif cards.size() < count:
			assert(cards.size() == 1, "Can only repeat cards if there is only one card")
			while cards.size() < count:
				cards.push_back(card_factory.get_card_by_name(source_list[0]))

	return cards


func _display_card_pick_dialog(cards: Array[Card], pick_count: int) -> Array[Card]:
	return await self.get_parent().get_node("card_picker").pick_cards(cards, pick_count)


func _interp_card_put(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var destination_name: String = await args[0].evaluate([], env)
	var cards: Array[Card] = await args[1].evaluate([], env)

	var destination: CardContainer2D
	if destination_name == "hand":
		destination = hand
	elif destination_name == "draw":
		destination = draw_pile
	elif destination_name == "discard":
		destination = discard_pile
	else:
		assert(false, "Unknown destination name " + destination_name)

	for card in cards:
		var old_container: CardContainer2D = card.get_card_container()
		if old_container != null:
			old_container.remove_card(card)
		destination.add_card(card)

	return null


func _interp_card_take(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Array[Card]:
	var count: int = await args[0].evaluate([], env)
	var sources = await args[1].evaluate([], env)
	var mode: String = await args[2].evaluate([], env)

	return _select_cards(count, sources, mode)


func _interp_card_pick(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Array[Card]:
	var count: int = await args[0].evaluate([], env)
	var out_of_count: int = await args[1].evaluate([], env)
	var sources = await args[2].evaluate([], env)
	var mode: String = await args[3].evaluate([], env)

	assert(out_of_count >= count)

	var cards: Array[Card] = _select_cards(out_of_count, sources, mode)

	var picked = await _display_card_pick_dialog(cards, count)

	return picked


func _interp_card_count(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> int:
	var source: String = await args[0].evaluate([], env)

	var container: CardContainer2D
	if source == "hand":
		container = hand
	elif source == "draw":
		container = draw_pile
	elif source == "discard":
		container = discard_pile
	else:
		assert(false, "Unknown source '" + source + "' given to card-count")

	return container.cards.size()

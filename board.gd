class_name Board
extends Node2D

class ScriptCallback:
	var total_turns: int
	var remaining_turns: int
	var callback: ScriptInterpreter.ScriptNode

var _card_dumpster: CardContainer2D

var active_district: District = null

var _districts: Array[District]

var card_factory: CardFactory

var global_stats: GlobalStats

var hand: Hand

var draw_pile: DrawPile

var discard_pile: DiscardPile

var shop: Shop

var card_picker: CardPicker

var turn_skip_cost: Label

var turn_skip_icon: Sprite2D

var btn_end_turn: Button

var is_skipped_turn: bool = true

var skipped_turn_count: int

var _on_turn_start_callbacks: Array[ScriptCallback]

var _detached_card: Card

signal environment_changed

signal card_played

signal new_turn


func script_environment() -> ScriptInterpreter.ScriptEnvironment:
	var district_environment = null
	if active_district != null:
		district_environment = active_district.curr_environment
	return card_factory.create_environment(
		global_stats.curr_environment,
		district_environment
	)


func play(card: Card) -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = script_environment()

	if await card.is_playable(env):
		print("Played ", card, " onto ", active_district)

		skipped_turn_count = 0

		is_skipped_turn = false

		var play_cost: int = card.get_play_cost()

		global_stats.change_gp(-play_cost)

		if card.discard_on_play():
			_detached_card = card
			hand.detach_card(card)
			add_child(card)

		var new_env: ScriptInterpreter.ScriptEnvironment = await card.play(env)

		global_stats.curr_environment = new_env.global_vars

		if active_district != null:
			active_district.curr_environment = new_env.local_vars
			active_district._on_card_played()

		card_played.emit()

		environment_changed.emit()

		if not card.increment_play_count():
			await card.run_void_animation()
			var container: CardContainer2D = card.get_card_container()
			if container != null:
				container.detach_card(card)
		elif _detached_card != null:
			remove_child(_detached_card)
			discard_pile.add_card(card)
			_detached_card = null

		return true

	else:
		print("Could not play ", card, "onto ", active_district)

		return false


func _ready() -> void:
	_card_dumpster = get_node("/root/root/card_dumpster")
	card_factory = get_node("/root/root/card_factory")
	global_stats = get_node("/root/root/global_stats")
	hand = get_node("/root/root/hand")
	draw_pile = get_node("/root/root/draw_pile")
	discard_pile = get_node("/root/root/discard_pile")
	shop = get_node("/root/root/shop")
	card_picker = get_node("/root/root/card_picker_root/card_picker")
	turn_skip_cost = get_node("turn_skip_cost")
	turn_skip_icon = get_node("turn_skip_icon")
	btn_end_turn = get_node("btn_end_turn")
	
	for child in get_children():
		if child is District:
			_districts.append(child)

	Root.connect_on_root_ready(self, _on_root_ready)

	environment_changed.connect(_update_end_turn_btn)


func _on_root_ready() -> void:
	environment_changed.emit()


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

	var on_turn_end_env: ScriptInterpreter.ScriptEnvironment = card_factory.create_environment(global_stats.curr_environment, null)
	for card: Card in hand._cards:
		on_turn_end_env = await card.on_turn_end(on_turn_end_env)

	global_stats.curr_environment = on_turn_end_env.global_vars

	# Discard hand and redraw from draw pile
	discard_pile.add_all_cards(hand._cards.filter(func(card: Card) -> bool:
		return not card.is_sticky()
	))

	# If there aren't enough cards in the draw pile, shuffle the discard pile into it
	if draw_pile.card_count() < 3:
		discard_pile._cards.shuffle()
		draw_pile.add_all_cards(discard_pile._cards)

	for i in range(min(max(0, 3 - hand.card_count()), draw_pile.card_count())):
		hand.add_card(draw_pile._cards.back())

	# Apply environment changes from played cards
	for district: District in _districts:
		district.prev_environment = district.curr_environment

	global_stats.prev_environment = global_stats.curr_environment

	environment_changed.emit()

	# Apply building turn effects
	var changed_district_count: int = 0

	for district in _districts:
		if await district.apply_building_turn_effects(changed_district_count):
			changed_district_count += 1

	_increment_card_ages()

	new_turn.emit()

	var on_turn_start_env: ScriptInterpreter.ScriptEnvironment = card_factory.create_environment(
		global_stats.curr_environment, {}
	)

	var remaining_on_turn_start_callbacks: Array[ScriptCallback] = []

	for callback: ScriptCallback in _on_turn_start_callbacks:
		on_turn_start_env.local_vars["remaining-turns"] = callback.remaining_turns
		on_turn_start_env.local_vars["total-turns"] = callback.total_turns
		await callback.callback.evaluate([], on_turn_start_env)
		if callback.remaining_turns != 1:
			if callback.remaining_turns > 0:
				callback.remaining_turns -= 1
			remaining_on_turn_start_callbacks.append(callback)

	_on_turn_start_callbacks = remaining_on_turn_start_callbacks

	on_turn_start_env.local_vars.clear()

	for card: Card in hand._cards:
		on_turn_start_env = await card.on_turn_start(on_turn_start_env)

	global_stats.curr_environment = on_turn_start_env.global_vars

	is_skipped_turn = true

	_year_events()
	
	if global_stats.curr_environment["fl"] < 0:
		global_stats.curr_environment["gp"] += global_stats.curr_environment["fl"]
		global_stats.curr_environment["fl"] = 0

	if global_stats.curr_environment["gp"] <= 0:
		pass # TODO: Game over

	environment_changed.emit()


func _increment_card_ages() -> void:
	for card: Card in hand._cards:
		card.increment_age()

	for card: Card in discard_pile._cards:
		card.increment_age()

	for card: Card in draw_pile._cards:
		card.increment_age()


func _end_turn_cost() -> int:
	return 0 if skipped_turn_count == 0 else skipped_turn_count + 2


func _year_events() -> void:
	var year: int = global_stats.curr_environment["year"]

	if year == 1360 or year == 1430 or year == 1480 or year == 1530:
		var replace_index: int = randi_range(0, hand.card_count() - 1)
		var replaced_card: Card = hand._cards[replace_index]
		hand.detach_card(replaced_card)
		hand.add_card(await card_factory.get_card_by_name("pest_mice"))
		draw_pile.add_card(replaced_card, randi_range(0, draw_pile.card_count()))


func _select_cards(count: int, sources, mode: String) -> Array[Card]:
	assert(mode == "random" or mode == "top" or mode == "bottom", "Unexpected mode '" + mode + "'. Expected 'random', 'top' or 'bottom'")

	var cards: Array[Card] = []

	if sources is Card:
		cards.append(sources)
	elif sources is String and (sources == "hand" or sources == "draw" or sources == "discard"):
		var all_cards: Array[Card]
		if sources == "hand":
			all_cards = hand._cards.duplicate()
		elif sources == "draw":
			all_cards = draw_pile._cards.duplicate()
		elif sources == "discard":
			all_cards = discard_pile._cards.duplicate()
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
			cards.append(await card_factory.get_card_by_category(sources.substr("category:".length())))

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
			cards.append(await card_factory.get_card_by_name(source.substr("card:".length())))

		if cards.size() > count:
			cards.shuffle()
			while cards.size() > count:
				cards.pop_back()
		elif cards.size() < count:
			assert(cards.size() == 1, "Can only repeat cards if there is only one card")
			while cards.size() < count:
				cards.push_back(await card_factory.get_card_by_name(source_list[0]))

	return cards


func _replace_cards_by_name(container: CardContainer2D, old_card_name: String, new_script: Dictionary) -> void:
	for card: Card in container._cards:
		if card.get_card_name() == old_card_name:
			card.replace_script(new_script)


func _display_card_pick_dialog(cards: Array[Card], pick_count: int) -> Array[Card]:
	return await card_picker.pick_cards(cards, pick_count)


func _interp_card_put(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var destination_name: String = await args[0].evaluate([], env)
	var raw_cards = await args[1].evaluate([], env)
	
	var actual_cards: Array[Card] = []
	
	if raw_cards is Card:
		actual_cards.append(raw_cards)
	elif raw_cards is Array[Card]:
		actual_cards = raw_cards
	else:
		assert(false, "Unexpected cards argument type for _interp_card_put")
		return null

	var destination: CardContainer2D
	if destination_name == "hand":
		destination = hand
	elif destination_name == "draw":
		destination = draw_pile
	elif destination_name == "discard":
		destination = discard_pile
	elif destination_name == "void":
		destination = _card_dumpster
	else:
		assert(false, "Unknown destination name " + destination_name)

	destination.add_all_cards(actual_cards)

	return null


func _interp_card_take(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Array[Card]:
	var count: int = await args[0].evaluate([], env)
	var sources = await args[1].evaluate([], env)
	var mode: String = await args[2].evaluate([], env)

	return await _select_cards(count, sources, mode)


func _interp_card_pick(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Array[Card]:
	var count: int = await args[0].evaluate([], env)
	var out_of_count: int = await args[1].evaluate([], env)
	var sources = await args[2].evaluate([], env)
	var mode: String = await args[3].evaluate([], env)

	assert(out_of_count >= count)

	var cards: Array[Card] = await _select_cards(out_of_count, sources, mode)

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

	return container.card_count()


func _interp_get_card_attribute(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var card: Card = await args[0].evaluate([], env)
	var attribute: String = await args[1].evaluate([], env)
	if attribute == "tags":
		return card.get_tags()
	elif attribute == "age":
		return card.get_age()
	elif attribute == "play-count":
		return card.get_play_count()
	else:
		assert(false, "Unknown card attribute '" + attribute + "'")
		return null


func _interp_random(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> int:
	var lo: int = await args[0].evaluate([], env)
	var hi: int = await args[1].evaluate([], env)
	return randi_range(lo, hi - 1)


func _interp_recurring_effect(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var callback: ScriptCallback = ScriptCallback.new()
	callback.total_turns = await args[0].evaluate([], env)
	callback.remaining_turns = callback.total_turns
	callback.callback = args[1]
	_on_turn_start_callbacks.append(callback)
	return null


func _interp_replace_card(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var old_card_name: String = await args[0].evaluate([], env)
	var new_card_name: String = await args[1].evaluate([], env)
	
	var new_script: Dictionary = card_factory.get_script_by_name(new_card_name)

	_replace_cards_by_name(hand, old_card_name, new_script)
	_replace_cards_by_name(draw_pile, old_card_name, new_script)
	_replace_cards_by_name(discard_pile, old_card_name, new_script)
	_replace_cards_by_name(shop, old_card_name, new_script)

	if _detached_card != null and _detached_card.get_card_name() == old_card_name:
		_detached_card.replace_script(new_script)

	return null


func _interp_all_districts(args: Array[ScriptInterpreter.ScriptNode], _env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var callback: ScriptInterpreter.ScriptNode = args[0]
	for district: District in _districts:
		var local_env: ScriptInterpreter.ScriptEnvironment = card_factory.create_environment(global_stats.curr_environment, district.curr_environment)
		callback.evaluate([], local_env)
	return null


func _interp_animate_play(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var card: Card = await args[0].evaluate([], env)
	await card.checkpoint_transform().run_play_animation(1.3)
	return null


func _interp_reset_play_costs(_args: Array[ScriptInterpreter.ScriptNode], _env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	hand.reset_extra_play_cost(-1)
	return null

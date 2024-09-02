class_name Board
extends Node2D

var active_district: District = null

var environment: Dictionary = { "fl" = 5, "gp" = 0, "cm" = 0 }

var card_factory: CardFactory

var hand: Hand

var draw_pile: DrawPile

var discard_pile: DiscardPile


func _ready() -> void:
	self.card_factory = get_parent().get_node("card_factory")
	self.hand = get_parent().get_node("hand")
	self.draw_pile = get_parent().get_node("draw_pile")
	self.discard_pile = get_parent().get_node("discard_pile")

	for district in self.get_children():
		if district is District:
			district.post_ready()


func play(card: Card) -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = script_environment()

	if card.is_applicable(env):
		print("Played ", card, " onto ", active_district)
		var new_env: ScriptInterpreter.ScriptEnvironment = card.apply(env)
		environment = new_env.global_vars
		if active_district != null:
			active_district.environment = new_env.local_vars
		hand.remove_card(card)
		discard_pile.add_card(card)
		return true
	else:
		print("Could not play ", card, "onto ", active_district)
		return false


func script_environment() -> ScriptInterpreter.ScriptEnvironment:
	return card_factory.create_environment(
		environment,
		active_district.environment if active_district != null else null
	)


func select_cards(count: int, sources, mode: String) -> Array[Card]:

	assert(mode == "random" or mode == "top" or mode == "bottom", "Unexpected mode '" + mode + "'. Expected 'random', 'top' or 'bottom'")

	var cards: Array[Card]

	if sources is Card:
		cards.append(sources)
	elif sources is String and (sources == "hand" or sources == "draw" or sources == "discard"):
		var container: CardContainer2D
		if sources == "hand":
			container = hand
		elif sources == "draw":
			container = draw_pile
		elif sources == "discard":
			container = discard_pile
		else:
			assert(false)

		if mode == "random":
			for i in range(count):
				if container.cards.size() == 0:
					break
				var card: Card = container.cards[randi_range(0, container.cards.size() - 1)]
				cards.append(card)
		elif mode == "top":
			for i in range(count):
				if container.cards.size() == 0:
					break
				var card: Card = container.cards[container.cards.size() - 1]
				cards.append(card)
		elif mode == "bottom":
			for i in range(count):
				if container.cards.size() == 0:
					break
				var card: Card = container.cards[0]
				cards.append(card)
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


func display_card_pick_dialog(cards: Array[Card], pick_count: int) -> Array[Card]:
	return self.get_parent().get_node("card_picker").pick_cards(cards, pick_count)


func _interp_card_put(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Variant:
	var destination_name: String = args[0].evaluate([], env)
	var cards: Array[Card] = args[1].evaluate([], env)

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
		destination.add_card(card)

	return null


func _interp_card_take(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Array[Card]:
	var count: int = args[0].evaluate([], env)
	var sources = args[1].evaluate([], env)
	var mode: String = args[2].evaluate([], env)

	var cards: Array[Card] = select_cards(count, sources, mode)
	
	for card in cards:
		var container: CardContainer2D = card.get_card_container()
		if container != null:
			container.remove_card(card)

	return cards


func _interp_card_pick(args: Array[ScriptInterpreter.ScriptNode], env: ScriptInterpreter.ScriptEnvironment) -> Array[Card]:
	var count: int = args[0].evaluate([], env)
	var out_of_count: int = args[1].evaluate([], env)
	var sources = args[1].evaluate([], env)
	var mode: String = args[2].evaluate([], env)

	assert(out_of_count >= count)

	var cards: Array[Card] = select_cards(out_of_count, sources, mode)

	return display_card_pick_dialog(cards, count)

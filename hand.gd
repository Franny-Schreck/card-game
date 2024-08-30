class_name Hand
extends Node2D

const ARC_ANGLE_BASE: float = 0.1

const ARC_OFFSET_BASE: float = 1100

const ARC_ANGLE_POW: float = 0.6

const ARC_OFFSET_POW: float = 0.5

const ARC_FOCUS_ANGLE_BASE: float = 0.015

const FOCUS_UP_OFFSET: float = 110

const HOVER_EXIT_DELAY: float = 0.05

var board: Board

var card_scripts: Dictionary

var cards: Array[Card] = []

var draw_pile: Array[Card] = []

var discard_pile: Array[Card] = []

var clicked_card: Card = null

var hovered_card: Card = null

var hover_timeout: float = 0


func _ready() -> void:
	self.board = self.get_parent().get_node("board")


func add_card_to_hand(card: Card) -> void:
	print("Adding card")
	self.cards.append(card)
	self.add_child(card)


func remove_card_from_hand(card: Card) -> void:
	print("Removing card " + str(Card))
	self.cards.erase(card)
	card.queue_free()


func _input(event: InputEvent) -> void:
	if self.clicked_card == null:
		return

	if event.is_action_released("mouse_left") and not self.clicked_card.is_click(event) or event.is_action_pressed("mouse_left"):
		self.clicked_card.get_node("scale_container/click_outline").hide()
		self.board.play(self.clicked_card)
		self.clicked_card = null


func _process(delta: float) -> void:
	if hover_timeout != 0:
		if hover_timeout - delta <= 0:
			hover_timeout = 0
			hovered_card = null
		else:
			hover_timeout -= delta

	var enlarged_card_index: int = self.cards.find(self.clicked_card)

	if enlarged_card_index == -1:
		enlarged_card_index = self.cards.find(self.hovered_card)

	for i in range(self.cards.size()):
		var card: Card = self.cards[i]
		var is_clicked: bool = card == self.clicked_card
		card.render_in_hand(i, self.cards.size(), enlarged_card_index, is_clicked)
		card.z_index = 1
		self.move_child(card, i)

	if enlarged_card_index != -1:
		var enlarged_card: Card = self.cards[enlarged_card_index]
		enlarged_card.z_index = 2
		self.move_child(enlarged_card, -1)


func from_draw_pile(count: int, from_top: bool) -> int:
	return 0 # TODO


func from_discard_pile(count: int, inspect_count: int) -> int:
	return 0 # TODO


func discard_from_hand(count: int) -> int:
	return 0 # TODO


func add_card_from_category(count: int, category_name: String) -> int:
	return 0 # TODO


class ScriptNodeCardFromDrawPile extends ScriptInterpreter.ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCardFromDrawPile.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		var hand: Hand = env.package_data["hand"]
		return hand.from_draw_pile(args[0].evaluate(env), args[1].evaluate(env))


class ScriptNodeCardFromDiscardPile extends ScriptInterpreter.ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCardFromDiscardPile.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		var hand: Hand = env.package_data["hand"]
		return hand.from_discard_pile(args[0].evaluate(env), args[1].evaluate(env))


class ScriptNodeCardDiscard extends ScriptInterpreter.ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCardFromDiscardPile.new().init_helper(1, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		var hand: Hand = env.package_data["hand"]
		return hand.discard_from_hand(args[0].evaluate(env))


class ScriptNodeCardFromCategory extends ScriptInterpreter.ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCardFromCategory.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		var hand: Hand = env.package_data["hand"]
		assert(args[1].node is ScriptNodeCardCategory)
		return hand.add_card_from_category(args[0].evaluate(env), args[1].category)


class ScriptNodeCardCategory extends ScriptInterpreter.ScriptNode:
	var category: String

	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		var node = ScriptNodeCardCategory.new().init_helper(0, token_, filename_, line_number_, line_offset_)
		node.category = token_.substr("card-category-".length())
		return node

	func evaluate(_args: Array[ScriptTree], _env: ScriptEnvironment) -> int:
		return 0

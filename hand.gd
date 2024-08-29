class_name Hand
extends Node2D

const ARC_ANGLE_BASE: float = 0.1

const ARC_OFFSET_BASE: float = 1100

const ARC_FOCUS_ANGLE_BASE: float = 0.015

const HOVER_EXIT_DELAY: float = 0.05

const FOCUS_UP_OFFSET: float = 110

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
	
	var hovered_index: int = self.cards.find(self.hovered_card) if self.hovered_card != null else 9999

	var clicked_index: int = self.cards.find(self.clicked_card) if self.clicked_card != null else 9999

	var centered_index: int = clicked_index
	
	var enlarged_index: int = clicked_index if self.clicked_card != null else hovered_index

	var card_count = self.cards.size()

	var offset = ARC_OFFSET_BASE * pow(card_count, 0.5)

	var angle_delta = ARC_ANGLE_BASE / pow(card_count, 0.6)

	var angle_offset = ((card_count - 1) * angle_delta) / 2

	if self.hovered_card != null or self.clicked_card != null:
		angle_offset += ARC_FOCUS_ANGLE_BASE / 2

	for i in range(card_count):

		var card = self.cards[i]

		var angle = i * angle_delta - angle_offset

		if (i > enlarged_index):
			angle += ARC_FOCUS_ANGLE_BASE

		var transf = Transform2D()

		if i == enlarged_index:
			transf = transf.scaled(Vector2(1.5, 1.5))

		card.z_index = 1
		self.move_child(self.cards[i], i)
		
		if i == centered_index:
			var tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		
			tween.tween_property(self.cards[i], "position", Vector2(0, -FOCUS_UP_OFFSET), 0.3).from_current()
			
		#TODO: move up a little
		elif i == hovered_index:
			var move_up = FOCUS_UP_OFFSET if i == hovered_index and self.clicked_card == null else 0.0

			transf = transf.rotated(-angle).translated(Vector2(0, -(offset + move_up))).rotated(angle).translated(Vector2(0, offset))

		else:
			var move_up = FOCUS_UP_OFFSET if i == hovered_index and self.clicked_card == null else 0.0

			transf = transf.translated(Vector2(0, -(offset + move_up))).rotated(angle).translated(Vector2(0, offset))

			var current_card = self.cards[i]

			current_card.transform = transf

			var base_position = current_card.position

			var tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

			tween.tween_property(current_card, "position", base_position, 0.001).from_current()

		card.transform = transf
		
	if hovered_index < self.cards.size():
		self.cards[enlarged_index].z_index = 2
		self.move_child(self.cards[enlarged_index], -1)


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
